define [
  'BaseView'
  'Messenger'
  'modules/Search/SearchPolicyCollection'
  'text!modules/Search/templates/tpl_search_container.html'
  'text!modules/Search/templates/tpl_search_policy_row.html'
  'text!modules/Search/templates/tpl_search_pagination.html'
], (BaseView, Messenger, SearchPolicyCollection, tpl_search_container, tpl_search_policy_row, tpl_search_pagination) ->

  class SearchView extends BaseView

    baseTemplate : _.template(tpl_search_container)

    policyRowTemplate : _.template(tpl_search_policy_row)

    paginationTemplate : _.template(tpl_search_pagination)

    perPageOpts : [15, 25, 50, 75, 100]

    events :
      'change input[name=search-query]'   : 'onQueryChange'
      'change .search-pagination-page'    : 'onPageChange'
      'change .search-pagination-perpage' : 'onPerPageChange'
      'change .search-by'                 : 'onSearchByChange'
      'change .policy-state-input'        : 'onPolicyStateChange'
      'submit .filters form'              : 'search'
      'click  .search-sort-link'          : 'searchSorted'
      'click  .abort'                     : 'abortRequest'

    initialize : (options) ->
      _.bindAll(this
        'callbackRequest'
        'callbackSuccess'
        'callbackError'
        'callbackInvalid'
        )

      @module                   = options.module
      @controller               = options.controller
      @collection               = new SearchPolicyCollection()
      @collection.url           = @controller.services.pxcentral + 'policies'
      @collection.controller    = @controller
      @shouldShowEnhancedSearch = @controller.current_state?.business is 'cru'
      @policyState =
        'policy' : true
        'quote'  : true

      @setupCollectionEventHandlers()

      # Load any passed parameters into view
      @params = @module.app.params ? {}
      @mainTemplate = _.template(tpl_search_container)

      # Special param to enable fetching of all policies requiring renewal underwriting
      if @params.renewalreviewrequired
        @collection.renewalreviewrequired = true
      else
        if @shouldShowEnhancedSearch
          # For regular search, default to quote-policy number
          @collection.setParam 'searchBy', 'quote-policy-number'

      @render()

    setupCollectionEventHandlers : ->
      @collection.on 'request', @callbackRequest
      @collection.on 'reset',   @callbackSuccess
      @collection.on 'error',   @callbackError
      @collection.on 'invalid', @callbackInvalid

    cacheElements : ->
      @$searchHeader       = @$('header.module-search')
      @$searchFiltersEl    = @$('.module-search.filters')
      @$searchInput        = @$searchFiltersEl.find 'input[type=search]'
      @$paginationEl       = @$('.search-pagination')
      @$searchResultsTable = @$('.div-table.module-search')
      @$searchResultsThead = @$searchResultsTable.find '.thead'
      @$searchResultsTbody = @$searchResultsTable.find '.tbody'

    render : ->
      @$el.html(@baseTemplate({
        cid                      : @cid
        pagination               : @paginationTemplate @determinePagination()
        isRenewalUnderwriting    : @params.renewalreviewrequired
        shouldShowEnhancedSearch : @shouldShowEnhancedSearch
      }))
      @cacheElements() # Cache useful DOM elements for later
      @setTbodyMaxHeight()
      @attachWindowResizeHandler()
      @messenger = new Messenger @, @cid # Register flash message pubsub for this view

    renderPolicies : (collection) ->
      rows = collection.map (model) =>
        @policyRowTemplate model.toJSON()
      @$searchResultsTbody.html rows.join('\n')

      if collection.length is 1
        href = collection.at(0).get('href')
        @controller.Router.navigate href, { trigger : true }

    attachWindowResizeHandler : ->
      lazyResize = _.debounce _.bind(@setTbodyMaxHeight, this), 500
      $(window).on 'resize', lazyResize

    setTbodyMaxHeight : ->
      workspaceHeight    = @controller.$workspace_el.height()
      headerHeight       = @$searchHeader.outerHeight()
      searchFilterHeight = @$searchFiltersEl.outerHeight()
      searchHeaderHeight = @$searchResultsThead.outerHeight()
      tbodyMaxHeight     = workspaceHeight - (headerHeight + searchFilterHeight + searchHeaderHeight)
      @$searchResultsTbody.css 'max-height', tbodyMaxHeight

    search : (e) ->
      e.preventDefault() if _.isObject e
      @collection.fetch()

    abortRequest : ->
      if jqXHR = @collection.jqXHR
        jqXHR.abort()

    searchSorted : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)
      $sortIcon = $el.find '.glyphicon'
      sortProp = $el.attr 'href'

      @collection.sortBy sortProp
      @search()

      @removeIndicators()
      if @collection.sortDir is 'asc'
        $sortIcon.addClass 'glyphicon-chevron-up'
      else
        $sortIcon.addClass 'glyphicon-chevron-down'

    onPageChange : (e) ->
      @updatePage +e.currentTarget.value

    updatePage : (page) ->
      if page > 0
        @collection.setParam 'page', page
        @search()

    onPerPageChange : (e) ->
      @updatePerPage +e.currentTarget.value

    updatePerPage : (perPage) ->
      if perPage > 0
        @collection.setParam 'perPage', perPage
        @collection.setParam 'page', 1
        @search()

    onQueryChange : (e) ->
      @updateQuery "#{e.currentTarget.value}"

    updateQuery : (query) ->
      @collection.setParam 'q', query
      @collection.setParam 'page', 1

    onSearchByChange : (e) ->
      @updateSearchBy "#{e.currentTarget.value}"

    updateSearchBy : (value) ->
      @$searchInput.attr 'placeholder', @getSearchPlaceholder value
      @collection.setParam 'searchBy', value
      @collection.setParam 'page', 1

    onPolicyStateChange : (e) ->
      @updatePolicyState $(e.currentTarget)

    updatePolicyState : ($input) ->
      @policyState[$input.attr('name')] = $input.prop 'checked'
      @collection.setParam 'policyState', @determinePolicyState()
      @collection.setParam 'page', 1

    getSearchPlaceholder : (value) ->
      if value is 'property-address'
        'Enter street number and name'
      else if value is 'quote-policy-number'
        'Enter Quote or Policy number'
      else
        'Enter search terms'

    determinePolicyState : ->
      p = @policyState.policy
      q = @policyState.quote
      if p and not q
        'policy'
      else if q and not p
        'quote'
      else
        'default'

    determinePagination : ->
      params      = @collection.getParams()
      currentPage = params.page
      perPage     = params.perPage
      totalItems  = @collection.totalItems or 0

      if totalItems > 0
        pages = [1..Math.ceil(totalItems / perPage)]
      else
        pages = [1]

      if totalItems is 0
        start = 0
        end = 0
      else if perPage > totalItems
        end   = totalItems
        start = 1
      else
        end   = currentPage * perPage
        start = end - perPage + 1

      start = 0 if start < 1
      end = totalItems if end > totalItems
      pagination =
        currentPage : currentPage
        perPage     : perPage
        perPageOpts : @perPageOpts
        totalItems  : totalItems
        pages       : pages
        start       : start
        end         : end

    renderPagination : ->
      html = @paginationTemplate @determinePagination()
      @$paginationEl.html html

    callbackRequest : (collection) ->
      @toggleLoader true

    callbackSuccess : (collection) ->
      @toggleLoader false
      if collection.length is 0
        @Amplify.publish @cid, 'notice', "No results found when searching for \"#{collection.q}\"", 3000
        return
      @renderPolicies collection
      @renderPagination()
      @module.trigger 'workspace.rendered'

    # Error callback handles aborted requests, in addition to errors
    callbackError : (collection, response) ->
      @toggleLoader false
      response = response or {}
      if response.statusText is 'abort'
        @Amplify.publish @cid, 'notice', "Request canceled.", 3000
      else if response.statusText is 'timeout'
        @logMusculaError collection, response
        @Amplify.publish(@cid
          'warning'
          'Your search has timed out waiting for service. Please try again later.'
          5000
          )
      else
        @logMusculaError collection, response
        @Amplify.publish(@cid
          'warning'
          "There was a problem with this request: #{response.status} - #{response.statusText}"
          5000
          )

    logMusculaError : (collection, response) ->
      # Throw a hopefully useful ajax error for Muscula to pick up
      if _.isObject Muscula
        eid = "#{@Helpers.formatDate(new Date(), 'YYYY-MM-DD')}"
        try
          Muscula.info = {}
          Muscula.info["RequestURL #{eid}"] = collection.url
          Muscula.info["SearchParams #{eid}"] = $.param collection.getParams()
          Muscula.info["Status #{eid}"]     = response.status
          Muscula.info["StatusText #{eid}"] = response.statusText
          Muscula.info["ResponseHeaders #{eid}"] = response.getAllResponseHeaders()
          throw new Error "Search XMLHTTPResponse Error (#{response.status}) #{response.statusText}"
        catch ex
          Muscula.errors.push ex

          # delete the info object so we don't muddy up the other errors too much
          setTimeout((->
            if Muscula.info?.eid is eid
              delete Muscula.info
          ), 2000)

    callbackInvalid : (collection, msg) ->
      @toggleLoader false
      @Amplify.publish @cid, 'notice', msg, 30000

    # Place a loading animation on top of the content
    toggleLoader : (bool) ->
      if bool and !@loader?
        @loader = @Helpers.loader("search-spinner-#{@cid}", 100, '#ffffff')
        @loader.setDensity 70
        @loader.setFPS 48
        $("#search-loader-#{@cid}").show()
        @favicon.start()
      else
        if @loader?
          @loader.kill()
          @loader = null
        $("#search-loader-#{@cid}").hide()
        @favicon.stop()

    # clear all sorting indicators
    removeIndicators : ->
      @$('.search-sort-link').each ->
        $icon = $(this).find '.glyphicon'
        $icon.removeClass 'glyphicon-chevron-up'
        $icon.removeClass 'glyphicon-chevron-down'


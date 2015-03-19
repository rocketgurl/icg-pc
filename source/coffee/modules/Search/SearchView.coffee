define [
  'BaseView'
  'Messenger'
  'modules/Search/SearchPolicyView'
  'modules/Search/SearchPolicyCollection'
  'text!modules/Search/templates/tpl_search_container.html'
  'text!modules/Search/templates/tpl_renewal_review_container.html'
], (BaseView, Messenger, SearchPolicyView, SearchPolicyCollection, tpl_search_container, tpl_renewal_review_container) ->

  class SearchView extends BaseView

    events :
      'change input[name=search-query]'   : 'updateQuery'
      'change .search-pagination-page'    : 'updatePage'
      'change .search-pagination-perpage' : 'updatePerPage'
      'change .search-pagination-perpage' : 'updatePerPage'
      'change .search-by'                 : 'updateSearchBy'
      'change .policy-state-input'        : 'updatePolicyState'
      'submit .filters form'              : 'search'
      'click  .search-sort-link'          : 'searchSorted'
      'click  .abort'                     : 'abortRequest'

    policyState :
      'policy' : true
      'quote'  : true

    initialize : (options) ->
      _.bindAll(this
        'callbackRequest'
        'callbackSuccess'
        'callbackError'
        'callbackInvalid'
        )

      @module                = options.module
      @controller            = options.controller
      @collection            = new SearchPolicyCollection()
      @collection.url        = @controller.services.pxcentral + 'policies'
      @collection.controller = @controller

      @setupCollectionEventHandlers()

      # Load any passed parameters into view
      @params = @module.app.params ? {}

      # Special param to enable fetching of all policies requiring renewal underwriting
      if @params.renewalreviewrequired
        @collection.renewalreviewrequired = true

      # NOT DEFAULTING TO QUOTE_POLICY_NUMBER UNTIL SEARCH IS FIXED IN PROD
      # else
      #   # For regular search, default to quote-policy number
      #   @collection.setParam 'searchBy', 'quote-policy-number'

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
      @$paginationEl       = @$('.module-search.pagination')
      @$itemsEl            = @$('.pagination-a span')
      @$pageEl             = @$('.search-pagination-page')
      @$perPageEl          = @$('.search-pagination-perpage')
      @$searchResultsTable = @$('.div-table.module-search')
      @$searchResultsThead = @$searchResultsTable.find '.thead'
      @$searchResultsTbody = @$searchResultsTable.find '.tbody'

    render : ->
      template = if @params.renewalreviewrequired then tpl_renewal_review_container else tpl_search_container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render template, { cid : @cid, pagination: @collection.pagination }
      @$el.html html
      
      # Cache useful DOM elements for later
      @cacheElements()

      @setTbodyMaxHeight()
      @attachWindowResizeHandler()

      # Register flash message pubsub for this view
      @messenger = new Messenger @, @cid

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

    renderPolicies : (collection) ->
      @$searchResultsTbody.empty()
      @searchPolicyViews = collection.map (model) =>
        new SearchPolicyView
          model       : model
          controller  : @controller
          $target_el  : @$searchResultsTbody

      if collection.length is 1
        @searchPolicyViews[0].open_policy()

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

    updatePage : (e) ->
      page = +e.currentTarget.value
      if page > 0
        @collection.setParam 'page', page
        @search()

    updatePerPage : (e) ->
      perPage = +e.currentTarget.value
      if perPage > 0
        @collection.setParam 'perPage', perPage
        @search()

    updateQuery : (e) ->
      @collection.setParam 'q', e.currentTarget.value

    updateSearchBy : (e) ->
      value = e.currentTarget.value
      @$searchInput.attr 'placeholder', @getSearchPlaceholder value
      @collection.setParam 'searchBy', value

    updatePolicyState : (e) ->
      $input = $(e.currentTarget)
      @policyState[$input.attr('name')] = $input.prop 'checked'
      @collection.setParam 'policyState', @determinePolicyState()

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

    renderPagination : (collection) ->
      currentPage = collection.page
      perPage     = collection.perPage
      totalItems  = collection.totalItems
      pages       = [1..Math.ceil(totalItems / perPage)]

      if perPage > totalItems
        end   = totalItems
        start = 1
      else
        end   = currentPage * perPage
        start = end - perPage + 1

      start = 1 if start < 1
      end = totalItems if end > totalItems

      @$itemsEl.html "Items #{start} - #{end} of #{totalItems}"

      # Jump to page options
      @$pageEl.html _.map pages, (page) ->
        if page is currentPage
          "<option value=\"#{page}\" selected>#{page}</option>"
        else
          "<option value=\"#{page}\">#{page}</option>"

    callbackRequest : (collection) ->
      @toggleLoader true

    callbackSuccess : (collection) ->
      @toggleLoader false

      # check for empty response
      if collection.length is 0
        @Amplify.publish @cid, 'notice', "No results found when searching for \"#{collection.q}\"", 3000
        return

      @renderPolicies collection
      @renderPagination collection
      @module.trigger 'workspace.rendered'

    # Error callback handles aborted requests, in addition to errors
    callbackError : (collection, response) ->
      @toggleLoader false
      response = response or {}
      if response.statusText is 'abort'
        @Amplify.publish @cid, 'notice', "Request canceled.", 3000
      else if response.statusText is 'timeout'
        @Amplify.publish(@cid
          'warning'
          'Your search has timed out waiting for service. Please try again later.'
          5000
          )
      else
        @Amplify.publish(@cid
          'warning'
          "There was a problem with this request: #{response.status} - #{response.statusText}"
          5000
          )

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


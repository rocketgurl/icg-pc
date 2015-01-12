define [
  'BaseView'
  'Messenger'
  'modules/Search/SearchPolicyView'
  'modules/Search/SearchPolicyCollection'
  'text!modules/Search/templates/tpl_search_container.html'
  'text!modules/Search/templates/tpl_renewal_review_container.html'
], (BaseView, Messenger, SearchPolicyView, SearchPolicyCollection, tpl_search_container, tpl_renewal_review_container) ->

  class SearchView extends BaseView

    sort_cache : {} # Store sorting states

    events :
      'change input[name=search-query]'   : 'updateQuery'
      'change .search-pagination-page'    : 'updatePage'
      'change .search-pagination-perpage' : 'updatePerPage'
      'change .search-pagination-perpage' : 'updatePerPage'
      'change .query-type'                : 'updatePolicyState'
      'submit .filters form'              : 'search'
      'click .search-sort-link'           : 'sortBy'

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

      @render()

    setupCollectionEventHandlers : ->
      @collection.on 'request', @callbackRequest
      @collection.on 'reset',   @callbackSuccess
      @collection.on 'error',   @callbackError
      @collection.on 'invalid', @callbackInvalid

    cacheElements : ->
      @$itemsEl   = @$('.pagination-a span')
      @$pageEl    = @$('.search-pagination-page')
      @$perPageEl = @$('.search-pagination-perpage')
      @$searchResultsTable = @$('table.module-search tbody')

    render : ->
      template = if @params.renewalreviewrequired then tpl_renewal_review_container else tpl_search_container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render template, { cid : @cid, pagination: @collection.pagination }
      @$el.html html
      
      # Cache useful DOM elements for later
      @cacheElements()

      # Register flash message pubsub for this view
      @messenger = new Messenger @, @cid

    renderPolicies : (collection) ->
      @$searchResultsTable.empty()
      @searchPolicyViews = collection.map (model) =>
        new SearchPolicyView
          model       : model
          controller  : @controller
          $target_el  : @$searchResultsTable

      if collection.length is 1
        @searchPolicyViews[0].open_policy()

    search : (e) ->
      e.preventDefault() if _.isObject e
      @collection.fetch()

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

    updatePolicyState : (e) ->
      @collection.setParam 'policystate', e.currentTarget.value

    updateQuery : (e) ->
      @collection.setParam 'q', e.currentTarget.value

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

    # Assemble search options from various inputs and explicitly
    # passed values (options) to return as an object for @fetch
    #
    get_search_options : (options) ->
      perpage               = @$el.find('.search-pagination-perpage').val() ? 15
      page                  = @$el.find('.search-pagination-page').val() ? 1
      policystate           = @$el.find('.query-type').val() ? ''
      q                     = @$el.find('input[type=search]').val() ? ''

      query =
        q           : _.trim q
        perpage     : perpage
        page        : page
        policystate : policystate

      if @renewal_review?
        if query.q? && query.q != ''
          delete query.renewalreviewrequired
        else
          query.renewalreviewrequired = true

      # Combine any sorting directives with the query
      if !_.isEmpty(@sort_cache)
        query[key] = value for key, value of @sort_cache

      # We have to be explicit to save IE from itself
      if options?
        query[key] = value for key, value of options

      # Make sure we keep track of all params
      @params[key] = value for key, value of query

      query

    callbackRequest : (collection) ->
      @loader_ui true

    callbackSuccess : (collection) ->
      @loader_ui false

      # check for empty response
      if collection.length is 0
        @Amplify.publish @cid, 'notice', "No policies found when searching for #{collection.q}", 3000
        return

      @renderPolicies collection
      @renderPagination collection
      @module.trigger 'workspace.rendered'

    callbackError : (collection, resp) ->
      @loader_ui false
      @Amplify.publish @cid, 'warning', "There was a problem with this request: #{resp.status} - #{resp.statusText}"

    callbackInvalid : (collection, msg) ->
      @loader_ui false
      @Amplify.publish @cid, 'notice', msg, 30000

    # Place a loading animation on top of the content
    loader_ui : (bool) ->
      if bool and !@loader?
        if $('html').hasClass('lt-ie9') is false
          @loader = @Helpers.loader("search-spinner-#{@cid}", 100, '#ffffff')
          @loader.setDensity(70)
          @loader.setFPS(48)
        $("#search-loader-#{@cid}").show()
        @favicon.start()
      else
        if @loader? and $('html').hasClass('lt-ie9') is false
          @loader.kill()
          @loader = null
        $("#search-loader-#{@cid}").hide()
        @favicon.stop()

    # Handling sorting state on columns
    #
    # @param _options_ Object : setting silent prevent fetch()
    #
    sortBy : (e, options) ->

      options ?= {}

      e.preventDefault()
      $el = $(e.currentTarget)
      
      @sort_cache =
        'sort'    : $el.attr('href')
        'sortdir' : $el.data('dir')

      if !_.has(options, 'silent')
        @fetch(@get_search_options(@sort_cache))

      @remove_indicators() # clear the decks!

      if $el.data('dir') is 'asc'
        $el.data('dir', 'desc')
        @swap_indicator $el, '&#9650;'
      else
        $el.data('dir', 'asc')
        @swap_indicator $el, '&#9660;'

    # Switch sorting indicator symbol
    swap_indicator : (el, char) ->
      text = el.html()
      reg = /▲|▼/gi
      if text.match('▲') or text.match('▼')
        text = text.replace(reg, char)
        el.html(text)
      else
        el.html(text + " #{char}")

    # clear all sorting indicators
    remove_indicators : ->
      $('.search-sort-link').each (index, el) ->
        el = $(el)
        reg = /▲|▼/gi
        el.html(el.html().replace(reg, ''))



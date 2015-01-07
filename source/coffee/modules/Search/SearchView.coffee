define [
  'BaseView'
  'Helpers'
  'Messenger'
  'modules/Search/SearchPolicyCollection'
  'text!modules/Search/templates/tpl_search_container.html'
  'text!modules/Search/templates/tpl_renewal_review_container.html'
  'text!modules/Search/templates/tpl_search_menu_save.html'
  'text!modules/Search/templates/tpl_search_menu_views.html'
  'text!modules/Search/templates/tpl_search_menu_share.html'
], (BaseView, Helpers, Messenger, SearchPolicyCollection, tpl_search_container, tpl_renewal_review_container, tpl_search_menu_save, tpl_search_menu_views, tpl_search_menu_share) ->

  SearchView = BaseView.extend

    menu_cache : {} # Store search menus
    sort_cache : {} # Store sorting states

    events :
      "submit .filters form"              : "search"
      "change .search-pagination-perpage" : "search"
      "change .search-pagination-page"    : "search"
      
      "click .search-control-context > a" : (e) -> @control_context(@process_event e)
      "click .search-control-save > a"    : (e) -> @control_save(@process_event e)
      "click .search-control-share > a"   : (e) -> @control_share(@process_event e)
      "click .search-control-pin > a"     : (e) -> @control_pin(e)
      "click .search-control-refresh"     : (e) -> @control_refresh(e)
      "submit .search-menu-save form"     : (e) -> @save_search(e)

      "click .search-sort-link" : "sort_by"

      "click .icon-remove-circle" : (e) -> 
        @clear_menus()
        @controls.removeClass('active')

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el                 = options.view.el
      @$el                = options.view.$el
      @controller         = options.view.options.controller
      @module             = options.module
      @policies           = new SearchPolicyCollection()
      @policies.url       = @controller.services.pxcentral + 'policies'
      @policies.container = @

      # Use this to breakout of loops
      @fetch_count = 0

      # Load any passed parameters into view
      @params = @module.app.params ? {}

      @menu_cache[@cid] = {} # We need to namespace the cache with CID

      if @params.renewalreviewrequired?
        @renewal_review = true;

    render : ->
      # Switch template based on module type
      template = if @renewal_review then tpl_renewal_review_container else tpl_search_container

      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render template, { cid : @cid, pagination: @policies.pagination }
      @$el.html html
      @controls = @$el.find('.search-controls')

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      # If we have params we need to go ahead and do the search query
      if @params?
        if @params.q? || @params.renewalreviewrequired?
          @setContextLabel()
          @set_search_options @params
          @fetch(@get_search_options(@params))

    setContextLabel : ->
      if @params.q? && @params.q != ''
        label = @params.q
      else if @params.renewalreviewrequired? && @params.renewalreviewrequired != ''
        label = 'Renewal Underwriting'

      @$el.find('.search-control-context strong').html(label)

    # Assemble search params and hit pxCentral
    search : (e) ->
      if e?
        e.preventDefault()
      @fetch(@get_search_options())
    
    # Set different form fields to the updated values based on @params
    set_search_options : (options) ->
      # Load form/page elements
      elements =
        'q'       : 'input[type=search]'
        'state'   : '.query-type'
        'perpage' : '.search-pagination-perpage'
        'page'    : '.search-pagination-page'

      for key, val of elements
        if _.has(options, key)
          @$el.find(val).val(options[key])

      # Load the sort cache
      sorts = ['sort', 'sortdir']
      for sort in sorts
        if _.has(options, sort)
          @sort_cache[sort] = options[sort]

      # Ensure out sort indicators are on if present
      if !_.isEmpty(@sort_cache)
        @$el.find("a[href=#{@sort_cache['sort']}]")
            .data('dir', @sort_cache['sortdir'])
            .trigger('click', {silent : true})

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

    # Tell the collection to fetch some policies and
    # handle UI issues, etc.
    fetch : (query) ->
      # Drop the loading UI in place
      @loader_ui(true)
      @favicon.start() if @fetch_count > 0
      @policies.reset() # wipe out the collection models

      # If we can't get the user's credentials we try up to 10
      # times before we bail out with a warning.
      digest = @controller.user.get('digest')

      # Set Basic Auth headers to request and attempt to
      # get some policies
      @policies.fetch(
        data    : query
        headers :
          'Authorization'   : "Basic #{digest}"
        success : (collection, resp) =>
          #check for empty requests
          if collection.length is 0
            @loader_ui false
            @favicon.stop()
            @Amplify.publish @cid, 'notice', "No policies found when searching for #{query.q}", 3000
            return

          collection.render()

          # Remove loader UI
          @loader_ui(false)
          @favicon.stop()

          # Set the URL params
          @params = 
            q : query.q

          # ***TARGETING THE FOLLOWING LINES TO KILL***
          # 
          # @params = _.extend @params, @get_search_options()
          # @module.app.params = @params
          # @controller.set_active_url @module.app.app # Ensure the correct URL
          # @setContextLabel()

          # Need to let the footer know that we changed height
          @module.trigger 'workspace.rendered'
          @fetch_count += 1
        
        error : (collection, resp) =>
          @Amplify.publish @cid, 'warning', "There was a problem with this request: #{resp.status} - #{resp.statusText}"
          @loader_ui(false)
          @favicon.stop()
          @fetch_count += 1
      )

    # Reset active state on elements
    toggle_controls : (id) ->
      $el = @$el.find(".#{id}")
      # if this control is already active, them deactivate it and everyone
      if $el.hasClass('active')
        @controls.removeClass('active')
      else
        @controls.removeClass('active')
        $el.addClass('active')

    # Pre-process a control button event to squash
    # default behaviors and toggle active state
    process_event : (e) ->
      e.preventDefault()
      @clear_menus()
      $el = $(e.currentTarget).parent()
      id = $el.attr('class').split ' '
      @toggle_controls id[1]
      $el

    # Remove menus
    clear_menus : ->
      _.each @menu_cache[@cid], (menu, id) ->
        menu.fadeOut(100)

      if @search_context_menu?
        @search_context_menu.fadeOut(100)     

    # Attach menu to control item
    attach_menu : (e, template, view_data) ->
      # Default view object
      view_data = view_data ? {}

      # make cache key from event classname
      cache_key = e.attr('class').split(' ')[1]

      if @menu_cache[@cid][cache_key] != undefined
        @menu_cache[@cid][cache_key].fadeIn(100)
        return @menu_cache[@cid][cache_key]
      else
        el_width = e.css('width')
        e.append(@Mustache.render template, view_data)
        @menu_cache[@cid][cache_key] = e.find("div")
        @menu_cache[@cid][cache_key].fadeIn(100)
        return @menu_cache[@cid][cache_key]

    # Search context control
    control_context : (e) ->
      if e.hasClass 'active'
        @search_context_menu = @controller.SEARCH.saved_searches.getMenu(this)
        e.append(@search_context_menu)
        e.find('div').fadeIn(100)

    # Search save control
    control_save : (e) ->
      if e.hasClass 'active'
        @attach_menu e, tpl_search_menu_save
        # reset state
        $('#search_save_label')
          .val('')
          .removeAttr('disabled')
        # Enable button
        $('.search-menu-save input[type=submit]')
          .removeAttr('disabled')
          .removeClass('button-disabled')
          .addClass('button-green')
          .val('Save view')

    # Search share control
    control_share : (e) ->
      if e.hasClass 'active'
        @attach_menu e, tpl_search_menu_share, { url : window.location.href }

    # Search pin control
    control_pin : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()
      @controller.Router.navigate_to_module 'search', @get_search_options()

    control_refresh : (e) -> 
      e.preventDefault()
      options =
        'cache-control' : 'no-cache'
      @fetch(@get_search_options(options))

    save_search : (e) ->
      e.preventDefault()
      val = $('#search_save_label').val()
      
      # No value, no save
      if val is ''
        return false

      saved = @controller.SEARCH.saved_searches.create {
        label  : val
        params : @params
      }

      if saved
        $('#search_save_label').attr('disabled', 'disabled')
        # disable button
        $('.search-menu-save input[type=submit]')
          .attr('disabled', 'disabled')
          .addClass('button-disabled')
          .removeClass('button-green')
          .val('Saved!')

    # Place a loading animation on top of the content
    loader_ui : (bool) ->
      if bool and !@loader?
        if $('html').hasClass('lt-ie9') is false
          @loader = Helpers.loader("search-spinner-#{@cid}", 100, '#ffffff')
          @loader.setDensity(70)
          @loader.setFPS(48)
        $("#search-loader-#{@cid}").show()
      else
        if @loader? and $('html').hasClass('lt-ie9') is false
          @loader.kill()
          @loader = null
        $("#search-loader-#{@cid}").hide()

    # Handling sorting state on columns
    #
    # @param _options_ Object : setting silent prevent fetch()
    #
    sort_by : (e, options) ->

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
        @swap_indicator $el, '&#9660;'
      else
        $el.data('dir', 'asc')
        @swap_indicator $el, '&#9650;'

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



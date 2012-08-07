define [
  'BaseView',
  'Messenger',
  'modules/SearchPolicyCollection',
  'text!templates/tpl_search_container.html',
  'text!templates/tpl_search_menu_save.html',
  'text!templates/tpl_search_menu_views.html',
  'text!templates/tpl_search_menu_share.html'
], (BaseView, Messenger, SearchPolicyCollection, tpl_search_container, tpl_search_menu_save, tpl_search_menu_views, tpl_search_menu_share) ->

  SearchView = BaseView.extend

    menu_cache : {} # Store search menus

    events :
      "submit .filters form"          : "search"

      "click .search-control-context > a" : (e) -> @control_context(@process_event e)
      "click .search-control-save > a"    : (e) -> @control_save(@process_event e)
      "click .search-control-share > a"   : (e) -> @control_share(@process_event e)
      "click .search-control-pin > a"     : (e) -> @control_pin(e)
      "click .search-control-refresh"   : (e) -> @control_refresh(e)
      "submit .search-menu-save form"   : (e) -> @save_search(e)

      "click .icon-remove-circle" : (e) -> 
        @clear_menus()
        @controls.removeClass('active')

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el         = options.view.el
      @$el        = options.view.$el
      @controller = options.view.options.controller
      @module     = options.module
      @policies   = new SearchPolicyCollection()
      #@policies.url       = @controller.services.pxcentral + 'policies?modified-after=2012-01-01&modified-before=2012-07-01'
      # Use mocks for demo
      @policies.url = '/mocks/search_response_v2.json'
      @policies.container = @

      # Load any passed parameters into view
      if @module.app.params?
        @params = @module.app.params

      @menu_cache[@cid] = {} # We need to namespace the cache with CID


    render : () ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_search_container, { cid : @cid }
      @$el.html html
      @controls = @$el.find('.search-controls')

      # @controls.each (i, control) ->
      #   target = $(control).attr('class').split(' ')[1]


      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

      # If we have params we need to go ahead and do the search query
      if @params?
        @$el.find('input[type=search]').val(@params.query)
        @search()

    # Assemble search params and hit pxCentral
    search : (e) ->
      if e?
        e.preventDefault()

      search_val = @$el.find('input[type=search]').val()

      @policies.reset() # wipe out the collection models

      # Set Basic Auth headers to request and attempt to
      # get some policies
      @policies.fetch(
        headers :
          'X-Authorization' : "Basic #{@controller.user.get('digest')}"
          'Authorization'   : "Basic #{@controller.user.get('digest')}"
        success : (collection, resp) =>
          collection.render()
          @params = 
            url   : search_val
            query : search_val
          @controller.Router.append_module 'search', @params
        error : (collection, resp) =>
          @Amplify.publish @cid, 'warning', "There was a problem with this request: #{resp.status} - #{resp.statusText}"
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
      @clear_menus()
      e.preventDefault()
      $el = $(e.currentTarget).parent()
      id = $el.attr('class').split ' '
      @toggle_controls id[1]
      $el

    # Remove menus
    clear_menus : ->
      _.each @menu_cache[@cid], (menu, id) ->
        menu.fadeOut(100)        

    # Attach menu to control item
    attach_menu : (e, template, view_data) ->
      # Default view object
      if !view_data?
        view_data = {}

      # make cache key from event classname
      cache_key = e.attr('class').split(' ')[1]

      if @menu_cache[@cid][cache_key] != undefined
        @menu_cache[@cid][cache_key].fadeIn(100)
        return false
      else
        el_width = e.css('width')
        e.append(@Mustache.render template, view_data)
        @menu_cache[@cid][cache_key] = e.find("div")
        @menu_cache[@cid][cache_key].fadeIn(100)
        return @menu_cache[@cid][cache_key]

    # Search context control
    control_context : (e) ->
      if e.hasClass 'active'
        menu = @attach_menu e, tpl_search_menu_views
        if menu
          @controller.SEARCH.saved_searches.populate(menu)

    # Search save control
    control_save : (e) ->
      if e.hasClass 'active'
        @attach_menu e, tpl_search_menu_save

    # Search share control
    control_share : (e) ->
      if e.hasClass 'active'
        @attach_menu e, tpl_search_menu_share

    # Search pin control
    control_pin : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()
      params = 
        url   : search_val
        query : search_val
      @controller.launch_module 'search', params
      @controller.Router.append_module 'search', params

    control_refresh : (e) -> 
      e.preventDefault()
      @search()

    save_search : (e) ->
      e.preventDefault()
      val = $('#search_save_label').val()
      @controller.SEARCH.saved_searches.create {
        label  : val
        params : @params
      }
      #@controller.SEARCH.saved_searches.reset @controller.SEARCH.saved_searches.models
      # @controller.SEARCH.saved_searches.save()
      # for model in @controller.SEARCH.saved_searches.models
      #   model.save()

define [
  'BaseView',
  'Messenger',
  'modules/SearchPolicyCollection',
  'text!templates/tpl_search_container.html'
], (BaseView, Messenger, SearchPolicyCollection, tpl_search_container) ->

  SearchView = BaseView.extend

    menu_cache : {} # Store search menus

    events :
      "submit .filters form"          : "search"

      "click #search-control-context" : (e) -> @control_context(@process_event e)
      "click #search-control-save"    : (e) -> @control_save(@process_event e)
      "click #search-control-share"   : (e) -> @control_share(@process_event e)
      "click #search-control-pin"     : (e) -> @control_pin(@process_event e)

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @el                 = options.view.el
      @$el                = options.view.$el
      @controller         = options.view.options.controller
      @policies           = new SearchPolicyCollection()
      @policies.url       = @controller.services.pxcentral + 'policies?modified-after=2012-01-01&modified-before=2012-07-01'
      @policies.container = @

    render : () ->
      # Setup flash module & search container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_search_container, { cid : @cid }
      @$el.html html
      @controls = $('.search-controls')

      # Register flash message pubsub for this view
      @messenger = new Messenger(@options.view, @cid)

    # Assemble search params and hit pxCentral
    search : (e) ->
      e.preventDefault()
      search_val = @$el.find('input[type=search]').val()

      # Set Basic Auth headers to request and attempt to
      # get some policies
      @policies.fetch(
        headers :
          'X-Authorization' : "Basic #{@controller.user.get('digest')}"
          'Authorization'   : "Basic #{@controller.user.get('digest')}"
        success : (collection, resp) =>
          collection.render()
          @controller.Router.append_search search_val
        error : (collection, resp) =>
          @Amplify.publish @cid, 'warning', "There was a problem with this request: #{resp.status} - #{resp.statusText}"
      )

    # Reset active state on elements
    toggle_controls : (id) ->
      $el = $("##{id}")
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
      $el = $(e.currentTarget)
      @toggle_controls $el.attr('id')
      $el

    # Remove menus
    clear_menus : ->
      _.each @menu_cache, (menu, id) ->
        menu.fadeOut(100)        

    # Attach menu to control item
    attach_menu : (e, template) ->
      if @menu_cache[template] != undefined
        @menu_cache[template].fadeIn(100)
      else
        el_width = e.css('width')
        tpl      = @$el.find("##{template}").html()
        tpl_id   = $(tpl).attr('id')
        e.append(tpl)
        $tpl = $("##{tpl_id}");
        $tpl.fadeIn(100);
        @menu_cache[template] = $tpl

    # Search context control
    control_context : (e) ->
      if e.hasClass 'active'
        @attach_menu e, 'tpl-context-menu'

    # Search save control
    control_save : (e) ->
      if e.hasClass 'active'
        @attach_menu e, 'tpl-save-menu'

    # Search share control
    control_share : (e) ->
      if e.hasClass 'active'
        @attach_menu e, 'tpl-share-menu'

    # Search pin control
    control_pin : (e) ->
      console.log e.attr('id')

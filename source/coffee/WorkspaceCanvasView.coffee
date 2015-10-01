define [
  'BaseView',
  'mustache',
  'Helpers',
  'text!templates/tpl_module_loader.html'
], (BaseView, Mustache, Helpers, tpl_module_loader) ->

  WorkspaceCanvasView = BaseView.extend

    tabTemplate : """
    <span class="glyphicon glyphicon-remove-circle" title="Close this tab" data-view="{{app}}"></span>
    <a href="{{href}}">{{{app_label}}}</a>
    """

    $target     : $('#target')
    $flash_tpl  : $('#tpl-flash-message').html()
    tagName     : 'section'
    className   : 'workspace-canvas'
    isActive    : false

    initialize : (options) ->
      _.bindAll this, 'destroyTab', 'updateTabLabel'

      controller     = @controller = options.controller
      @$tabNav       = controller.$workspace_tabs
      @template      = options.template if options.template?
      @params        = options.params ? null
      @reactivate    = false

      # Create a new tab element with each
      # new workspace canvas view instance
      @$tabEl = $('<li/>')

      # Handle tab close
      @$tabEl.on 'click', '.glyphicon-remove-circle', @destroyTab

      # No app, throw a big error
      if !options.app?
        return @Amplify.publish 'flash', 'warning', 'There was a problem locating that workspace.'

      @app   = options.app
      @el.id = @app.app # Set container id to app name

      # Find navbar anchor and parent element corresponding to app
      routeName = @Helpers.prettyMap(@app.app, {
        'renewalreview'  : 'underwriting/renewals'
        'referral_queue' : 'underwriting/referrals'
        })
      @$navbarItem = $(".pc-nav [data-route=\"#{routeName}\"]").parent()

      # Add to the stack
      controller.trigger 'stack_add', @

      # Initialize module
      require ["modules/#{@options.module_type}"], (Module) =>
        @module = new Module(@, @app)
        @module.load() if _.has(Module.prototype, 'load')
        if _.isObject @module.policy_model
          @listenTo @module.policy_model, 'change:insightId', @updateTabLabel

      @render()

    # Render Canvas
    #
    # 1. Place loading image
    # 2. Load external JS modules to setup app
    # 3. Hide the canvas so our tabs "stack"
    # 4. Inject all of this into DOM and add Tab
    # 5. Tell the controller we're here.
    #
    render : ->
      # Drop loader image into place until our Module is good and ready
      @$el.html Mustache.render tpl_module_loader, {module_name : @app.app_label, app : @app.app}

      # Only policies get tabs
      if /policyview/.test @app.app
        data =
          app       : @app.app
          app_label : @app.app_label
          href      : @constructHref()
        @renderTab data
        @$tabNav.append @$tabEl
      @$target.append @$el

      # Loading image
      @loader = Helpers.loader("loader-#{@app.app}", 60, '#696969')
      @loader.setFPS(48)

      # Alert the controller
      #
      # There should prolly be some checking to make sure the app has
      # loaded before telling the controller we're here?
      #
      @options.controller.trigger 'new_tab', @app

    renderTab : (data) ->
      @$tabEl.html Mustache.render @tabTemplate, data

    updateTabLabel : (policy) ->
      label = policy.getTabLabel()
      if label and label isnt @app.app_label
        data =
          app       : @app.app
          app_label : label
          href      : @constructHref()
        @controller.state_update data
        @renderTab data

    constructHref : ->
      href = ''
      if @app.params
        href += "##{@controller.baseRoute}/policy/#{@app.params.url}"
      href

    # Put tab into active state
    activate : ->
      @$tabEl.addClass('selected') if @$tabEl
      @$el.removeClass 'inactive'
      @$navbarItem.addClass 'active'
      @app.isActive = true
      if @module
        @module.trigger 'activate'

    # Put tab into inactive state
    deactivate : ->
      @$tabEl.removeClass('selected') if @$tabEl
      @$el.addClass 'inactive'
      @$navbarItem.removeClass 'active'
      @app.isActive = false
      if @module
        @module.trigger 'deactivate'

    destroyTab : ->
      @destroy()
      @options.controller.setActiveRoute()

    # Remove tab and view
    destroy : ->
      # pause the carousel on home view
      if @app.app is 'home' and typeof $.fn.carousel is 'function'
        @$('#home-carousel').carousel 'pause'

      # Remove tab & nullify so GC can get it (?)
      if @$tabEl?
        @$navbarItem.removeClass 'active'
        @$tabEl.remove()
        @$tabEl = null

      # Remove content
      @$el.empty().remove()

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @

    # Remove loader image and tell module to render
    remove_loader : (render) ->
      @$el.find('.module-loader').fadeOut('fast', =>
        if render?
          @module.render()
        )

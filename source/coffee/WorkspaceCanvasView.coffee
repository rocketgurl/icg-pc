define [
  'BaseView',
  'mustache',
  'Helpers',
  'text!templates/tpl_module_loader.html'
], (BaseView, Mustache, Helpers, tpl_module_loader) ->

  WorkspaceCanvasView = BaseView.extend

    $target    : $('#target')
    $flash_tpl : $('#tpl-flash-message').html()
    tagName    : 'section'
    className  : 'workspace-canvas'
    tab        : null

    initialize : (options) ->
      controller    = @controller = options.controller
      @$tab_el      = controller.$workspace_tabs
      @template     = options.template if options.template?
      @template_tab = if options.template_tab? then options.template_tab else $('#tpl-workspace-tab').html()
      @params       = options.params ? null
      @reactivate   = false

      # No app, throw a big error
      if !options.app?
        return @Amplify.publish 'flash', 'warning', 'There was a problem locating that workspace.'

      @app   = options.app
      @el.id = @app.app # Set container id to app name

      # Find navbar anchor and parent element corresponding to app
      @$navbar_item = $(".pc-nav [data-app=#{@app.app}]").parent()

      # Add to the stack
      controller.trigger 'stack_add', @

      # Initialize module
      require ["modules/#{@options.module_type}"], (Module) =>
        @module = new Module(@, @app)
        @module.load() if _.has(Module.prototype, 'load')

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

      @$target.append(@$el)
      @render_tab(@template_tab)

      # Loading image
      @loader = Helpers.loader("loader-#{@app.app}", 60, '#696969')
      @loader.setFPS(48)

      # Alert the controller
      #
      # There should prolly be some checking to make sure the app has
      # loaded before telling the controller we're here?
      #
      @options.controller.trigger 'new_tab', @app.app

    # Create tab for this view
    render_tab : (template) ->
      data =
        tab_class : ''
        tab_view  : Helpers.id_safe(decodeURIComponent(@app.app))
        tab_url   : @constructHref()
        tab_label : @app.app_label
      @tab = $(Mustache.render(template, data))
      @$tab_el.append @tab

    constructHref : ->
      href = ''
      if @app.params
        href += "##{@controller.baseRoute}/policy"
        href += "/#{@app.params.url}/#{encodeURIComponent(@app.app_label)}"
      href

    # Put tab into active state
    activate : ->
      @tab.addClass 'selected'
      @$el.removeClass 'inactive'
      @$navbar_item.addClass 'active'
      if @module
        @module.trigger 'activate'

    # Put tab into inactive state
    deactivate : ->
      @tab.removeClass 'selected'
      @$el.addClass 'inactive'
      @$navbar_item.removeClass 'active'
      if @module
        @module.trigger 'deactivate'

    # Is this view activated? (boolean)
    is_active : ->
      @tab.hasClass('selected')

    # Remove tab and view
    destroy : ->
      # Remove tab & nullify so GC can get it (?)
      if @tab?
        @$navbar_item.removeClass 'active'
        @tab.remove()
        @tab = null

      # Remove content
      @$el.html('').remove()

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @

    # Remove loader image and tell module to render
    remove_loader : (render) ->
      @$el.find('.module-loader').fadeOut('fast', =>
        if render?
          @module.render()
        )

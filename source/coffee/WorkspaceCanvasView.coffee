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
    className  : 'canvas'
    tab        : null

    initialize : (options) ->
      @$tab_el      = options.controller.$workspace_tabs
      @template     = options.template if options.template?
      @template_tab = if options.template_tab? then options.template_tab else $('#tpl-workspace-tab').html()

      # No app, throw a big error
      if !options.app?
        return @Amplify.publish 'flash', 'warning', 'There was a problem locating that workspace.'

      @app   = options.app
      @el.id = @app.app # Set container id to app name

      # Add to the stack
      @options.controller.trigger 'stack_add', @

      @render()


    # Render Canvas
    #
    # 1. Place loading image
    # 2. Load external JS modules to setup app
    # 3. Hide the canvas so our tabs "stack"
    # 4. Inject all of this into DOM and add Tab
    # 5. Tell the controller we're here.
    #
    render : () ->

      # Drop loader image into place until our Module is good and ready
      @$el.html Mustache.render tpl_module_loader, {module_name : @app.app_label, app : @app.app}

      # Initialize module
      require ["modules/#{@options.module_type}"], (Module) =>
        @module = new Module(@, @app)

      @$el.hide(); # We initially keep our contents hidden
      @$target.append(@$el)
      @render_tab(@template_tab)

      # Alert the controller
      #
      # There should prolly be some checking to make sure the app has
      # loaded before telling the controller we're here?
      #
      @options.controller.trigger 'new_tab', @app.app

    # Create tab for this view
    render_tab : (template) ->
      @tab = $(Mustache.render template, { tab_class : '', tab_url : Helpers.id_safe(decodeURI(@el.id)), tab_label : @app.app_label })
      @$tab_el.append(@tab)

    # Put tab into active state 
    activate : ->
      @tab.addClass('selected')
      @$el.show();

    # Put tab into inactive state
    deactivate : ->
      @tab.removeClass('selected')
      @$el.hide();

    # Is this view activated? (boolean) 
    is_active : ->
      @tab.hasClass('selected')

    # Remove tab and view
    destroy : () ->
      # Remove tab & nullify so GC can get it (?)
      if @$tab_el?
        @tab = null
        @$tab_el.find("li a[href=#{@app.app}]").parent().remove()
        @$tab_el = null

      # Remove content
      @$el.html('').remove()   

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @

    # Remove loader image and tell module to render
    remove_loader : () ->
      @$el.find('.module-loader').fadeOut('fast', =>
        @module.render()
        )

    # Launch a new app (tab) within the current workspace context
    # Checks to make sure the app isn't already loaded first.
    #
    # @param `app` _Object_ application config object  
    #
    launch_child_app : (app) ->
      # If it's already in the saved state stack, we don't
      # add it again
      if @options.controller.state_exists(app)?
        @options.controller.toggle_apps app.app
      else
        @options.controller.launch_app app
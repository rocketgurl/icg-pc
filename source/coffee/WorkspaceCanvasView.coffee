define [
  'BaseView',
  'mustache',
  'text!templates/tpl_module_loader.html'
], (BaseView, Mustache, tpl_module_loader) ->

  WorkspaceCanvasView = BaseView.extend

    $target   : $('#target')
    tagName   : 'section'
    className : 'canvas'
    tab       : null

    initialize : (options) ->
      @$tab_el      = options.controller.$workspace_tabs
      @template     = options.template if options.template?
      @template_tab = if options.template_tab? then options.template_tab else $('#tpl-workspace-tab').html()

      if !options.app?
        return @Amplify.publish 'flash', 'warning', 'There was a problem locating that workspace.'

      @app = options.app
      @el.id = @app.app # Set container id to app name

      # Add to the stack
      @options.controller.trigger 'stack_add', @

      @render()


    # Render Canvas
    render : () ->

      # Drop loader image into place until our Module is good and ready
      @$el.html Mustache.render tpl_module_loader, {module_name : @app.app_label}

      # Initialize module
      require ["modules/#{@options.module_type}"], (Module) =>
        @module = Module
        @module.init @, @app

      @$el.hide(); # We initially keep our contents hidden
      @$target.append(@$el)
      @render_tab(@template_tab)

      # Alert the controller
      @options.controller.trigger 'new_tab', @app.app

    # Create tab for this view
    render_tab : (template) ->
      @tab = $(Mustache.render template, { tab_class : '', tab_url : @el.id, tab_label : @app.app_label })
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
      # Remove tab
      if @$tab_el?
        @tab = null
        delete @tab
        @$tab_el.find("li a[href=#{@app.app}]").parent().remove()
        @$tab_el = null

      # Remove content
      @$el.html('')     

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @

    # Remove loader image and tell module to render
    remove_loader : () ->
      console.log @
      @$el.find('#module-loader').fadeOut('fast', =>
        @module.render()
        )
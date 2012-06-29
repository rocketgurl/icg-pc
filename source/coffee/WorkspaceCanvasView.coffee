define [
  'BaseView',
  'mustache'
], (BaseView, Mustache) ->

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

    # Render login form
    render : () ->
      require ['modules/TestModule'], (TestModule) => 
        TestModule.init @$el, @app

      @$el.hide();
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
        delete @tab
        @$tab_el.find("li a[href=#{@app.app}]").parent().remove()

      # Remove content
      @$el.html('')     

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @

      # Clear memory
      delete @
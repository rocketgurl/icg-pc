define [
  'BaseView',
  'mustache'
], (BaseView, mustache) ->

  WorkspaceCanvasView = BaseView.extend

    $target    : $('#target')
    tagName   : 'section'
    className : 'canvas'
    tab       : null

    initialize : (options) ->
      @$tab_el      = options.controller.$workspace_tabs
      @template     = options.template if options.template?
      @template_tab = options.template_tab if options.template_tab?

      if !options.app?
        return @Amplify.publish 'flash', 'warning', 'There was a problem locating that workspace.'

      @app = options.app
      @el.id = @app.app # Set container id to app name

      # Add to the stack
      @options.controller.trigger 'stack_add', @


    # Render login form
    render : () ->
      # html = Mustache.render @template, 
      @$target.append(@$el.html(@template.html()))
      @render_tab(@template_tab)

    #### Render Tab
    #
    # Create tab for this view
    #
    render_tab : (template) ->
      @tab = Mustache.render template, { tab_class : ' class="selected"', tab_url : '#login', tab_label : 'Login' }
      @$tab_el.append(@tab)


    #### Destroy
    #
    # Remove tab and view
    #
    destroy : () ->
      if @$tab?
        delete @tab
      @$el.html('')

      # Remove from the stack
      @options.controller.trigger 'stack_remove', @
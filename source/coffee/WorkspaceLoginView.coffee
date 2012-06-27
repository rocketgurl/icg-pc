define [
  'BaseView',
  'WorkspaceCanvasView'
], (BaseView, WorkspaceCanvasView) ->

  WorkspaceLoginView = BaseView.extend

    events :
      "submit form" : "get_credentials"

    initialize : (options) ->
      # Mixin Canvas View methods
      @include WorkspaceLoginView, WorkspaceCanvasView
      
      @template = options.template if options.template?
      @render_tab(options.template_tab) if options.template_tab?

    # Render login form
    render : () ->
      @$el.html @template.html()

    # Get creds from form and pass to controller
    get_credentials : (event) ->
      event.preventDefault()
      username = @$el.find('input:text').val()
      password = @$el.find('input:password').val()
      @options.controller.check_credentials(username, password)

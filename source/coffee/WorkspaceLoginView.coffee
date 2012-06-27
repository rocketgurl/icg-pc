define [
  'BaseView'
], (BaseView) ->

  WorkspaceLoginView = BaseView.extend

    el  : '#target'
    tab : null

    events :
      "submit form" : "get_credentials"

    initialize : (options) ->
      @template = options.template if options.template?


    # Render login form
    render : () ->
      @$el.html @template.html()

    # Destroy
    destroy : () ->
      @$el.html('')

    # Get creds from form and pass to controller
    get_credentials : (event) ->
      event.preventDefault()
      username = @$el.find('input:text').val()
      password = @$el.find('input:password').val()
      @options.controller.check_credentials(username, password)

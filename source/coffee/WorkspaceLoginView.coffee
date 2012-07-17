define [
  'BaseView',
  'Messenger',
  'mustache'
], (BaseView, Messenger, Mustache) ->

  WorkspaceLoginView = BaseView.extend

    el  : '#target'
    tab : null

    events :
      "submit form" : "get_credentials"

    initialize : (options) ->
      @template = options.template if options.template?

    # Render login form
    render : () ->
      html = Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @template.html()
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@, @cid)

    # Destroy
    destroy : () ->
      @$el.html('')

    # Get creds from form and pass to controller
    get_credentials : (event) ->
      event.preventDefault()
      username = @$el.find('input:text').val()
      password = @$el.find('input:password').val()
      @options.controller.check_credentials(username, password)

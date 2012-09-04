define [
  'BaseView',
  'Messenger',
  'mustache',
  'text!templates/tpl_login.html'
], (BaseView, Messenger, Mustache, tpl_login) ->

  WorkspaceLoginView = BaseView.extend

    el  : '#target'
    tab : null

    events :
      "submit #form-login form" : "get_credentials"

    # Render login form
    render : ->
      html = Mustache.render tpl_login, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@, @cid)

    # Destroy
    destroy : ->
      @$el.find('#form-login').remove()
      @off() # remove events

    # Get creds from form and pass to controller
    get_credentials : (event) ->
      event.preventDefault()
      username = @$el.find('input:text').val()
      password = @$el.find('input:password').val()
      @options.controller.check_credentials(username, password)

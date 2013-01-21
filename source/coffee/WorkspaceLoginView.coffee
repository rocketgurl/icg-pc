define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_login.html'
], (BaseView, Messenger, tpl_login) ->

  WorkspaceLoginView = BaseView.extend

    el  : '#login-container'
    tab : null

    events :
      "submit #form-login form" : "get_credentials"

    # Render login form
    render : ->
      # @removeLoader() # if we're being re-rendered then make sure loader is gone
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_login, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(this, @cid)

    displayMessage : (type, msg, timeout) ->
      @Amplify.publish @cid, type, msg

    # Destroy
    destroy : ->
      @removeLoader()
      @$el.find('#form-login').remove()
      @off() # remove events

    # Get creds from form and pass to controller
    get_credentials : (event) ->
      event.preventDefault()
      @displayLoader()
      username = @$el.find('input:text').val()
      password = @$el.find('input:password').val()

      if username == null || username == ''
        @removeLoader()
        @displayMessage 'warning', "Sorry, your password or username was incorrect"
        return false;

      if password == null || password == ''
        @removeLoader()
        @displayMessage 'warning', "Sorry, your password or username was incorrect"
        return false;

      @options.controller.check_credentials(username, password)

    displayLoader : ->
      if $('#canvasLoader').length < 1
        @loader = @Helpers.loader("search-spinner-#{@cid}", 100, '#ffffff')
        @loader.setDensity(70)
        @loader.setFPS(48)
        $("#search-loader-#{@cid}").show()

    removeLoader : ->
      if @loader?
        @loader.kill()
      @loader = null
      $('#canvasLoader').remove();
      $("#search-loader-#{@cid}").hide()


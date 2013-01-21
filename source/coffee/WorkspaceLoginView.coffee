define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_login.html'
], (BaseView, Messenger, tpl_login) ->

  WorkspaceLoginView = BaseView.extend

    el  : '#target'
    tab : null

    events :
      "submit #form-login form" : "get_credentials"

    # Render login form
    render : ->
      @removeLoader() # if we're being re-rendered then make sure loader is gone
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_login, { cid : @cid }
      @$el.html html

      # Register flash message pubsub for this view
      @messenger = new Messenger(@, @cid)

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
      @options.controller.check_credentials(username, password, this)

    displayLoader : ->
      @loader = @Helpers.loader("search-spinner-#{@cid}", 100, '#ffffff')
      @loader.setDensity(70)
      @loader.setFPS(48)
      $("#search-loader-#{@cid}").show()

    removeLoader : ->
      if @loader?
        @loader.kill()
        @loader = null
        $("#search-loader-#{@cid}").hide()

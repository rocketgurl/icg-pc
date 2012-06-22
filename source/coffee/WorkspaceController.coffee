define [
  'jquery', 
  'underscore',
  'backbone',
  'UserModel',
  'ConfigModel',
  'WorkspaceLoginView',
  'WorkspaceRouter',
  'base64',
  'MenuHelper',
  'amplify_core',
  'amplify_store',
  'cookie'
], ($, _, Backbone, UserModel, ConfigModel, WorkspaceLoginView, WorkspaceRouter,  Base64, MenuHelper, amplify) ->

  #### Global ENV Setting
  #
  window.ICS360_ENV = 'staging'

  # Global log object for debugging
  #
  amplify.subscribe 'log', (msg) ->
    console.log msg

  #### Flash Message handling
  #  
  $flash = $('#flash-message')
  amplify.subscribe 'flash', (type, msg) ->
    # set className
    if type?
      $flash.attr 'class', type
    if msg?
      msg += ' <i class="icon-remove-sign"></i>'
      $flash.html(msg).fadeIn('fast')

  $flash.on 'click', 'i', (event) ->
    event.preventDefault()
    $flash.fadeOut 'fast'

  #### Services
  #
  # Insight 360 Service URLs
  #
  ics360 =
    services :
      ixdirectory : './ixdirectory/api/rest/v2/'
      pxcentral   : './pxcentral/api/rest/v1/'
      ixlibrary   : './ixlibrary/api/sdo/rest/v1/'
      ixdoc       : './ixdoc/api/rest/v2/'
      ixadmin     : './config/ics/staging/ixadmin' # TESTING ONLY

  #### Orchestrate the Workspace 
  #
  # This controller wires together different views/models
  # to handle Workspace events and in general act like
  # a switchboard operator.
  #
  WorkspaceController =
    Amplify               : amplify
    $workspace_button     : $('#button-workspace')
    $workspace_breadcrumb : $('#breadcrump')
    $workspace_admin      : $('#header-admin')
    $workspace_canvas     : $('#canvas')
    Router                : new WorkspaceRouter()
    COOKIE_NAME           : 'ics360.PolicyCentral' 
    
    # Simple logger
    logger : (msg) ->
      @Amplify.publish 'log', msg

    flash : (type, msg) ->
      @Amplify.publish 'flash', type, msg

    # Check for an identity cookie and check server for
    # validity. If no cookie present then just build the
    # login form as usual. 
    #
    check_cookie_identity : () ->
      if cookie = $.cookie(@COOKIE_NAME)
        cookie = Base64.decode(cookie).split(':')
        @check_credentials cookie[0], cookie[1]
      else
        @Router.navigate('login', { trigger : true })

    # Drop an identity cookie in the browser.
    # This is in the form of a username:password digest
    # Honestly, this is pretty insecure - should really
    # be using a token generated by the server and stored
    # in the User table. We expire this cookie after 7 days.
    #
    # @param **digest** _String_ Base64.encode username:password
    #
    set_cookie_identity : (digest) ->
      $.cookie(@COOKIE_NAME, digest, { expires : 7 })

    # Render the login form
    build_login : () ->
      @login_view = new WorkspaceLoginView({
          controller : @
          el         : '#target'
          template   : $('#tpl-ics-login')
        })
      @login_view.render()

    # Instantiate a new user and check ixDirectory
    # for valid credentials
    check_credentials : (username, password) ->
      @user = new UserModel
          urlRoot    : ics360.services.ixdirectory + 'identities'
          'username' : username
          'password' : password

      # retrieve an identity document or fail
      @user.fetch(
          success : (model, resp) =>
            # The model has to figure out what the
            # response state was
            @user.response_state()
            switch @user.get('fetch_state').code
              when "200" then @login_success(model, resp)
              else @login_fail(model, resp, @user.get('fetch_state'))
          error : (model, resp) =>
            @response_fail model, resp
        )

    # Need to throw a nice error message
    response_fail : (model, resp) ->
      @logger "PHALE!"

    # On a successfull login have @user set some variables
    # and set an identity cookie to smooth logging in later.
    #
    # @param **model** _Object_ User model
    # @param **resp** _Object_ Response from server
    #
    login_success : (model, resp) ->
      @get_configs()
      @user.parse_identity() # Additional setup on model
      @set_cookie_identity(@user.get('digest')) # set cookie
      @flash 'success', "HELLO THERE #{@user.get('name')}"

    # On unsuccessful login render the login form again
    # along with a Flash message indicating issue
    #
    # @param **model** _Object_ User model
    # @param **resp** _Object_ Response from server
    # @param **state** _Object_ Error code/text from server
    #
    login_fail : (model, resp, state) ->
      @Router.navigate('login', { trigger : true })
      @flash 'warning', "SOWWEE you no enter cause #{state.text}"

    # Delete the identity cookie and nullify User
    logout : () ->
      $.cookie(@COOKIE_NAME, null)
      @user = null

    # Grab ixAdmin information and load in ConfigModel
    get_configs : () ->
      @config = new ConfigModel
        urlRoot : ics360.services.ixadmin
      @config.fetch(
        success : (model, resp) =>
          #MenuHelper.build_menu @user.get('document'), model.get('document')
        error : (model, resp) =>
          @flash 'warning', "There was a problem retreiving the configuration file. Please contact support."
        )

    # Kick off the show
    init : () ->
      @Router.controller = @
      Backbone.history.start()
      @check_cookie_identity()


  _.extend WorkspaceController, Backbone.Events

  WorkspaceController.on "log", (msg) ->
    @logger msg

  
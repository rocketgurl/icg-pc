define [
  'jquery', 
  'underscore',
  'backbone',
  'UserModel',
  'WorkspaceLoginView',
  'WorkspaceRouter',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, UserModel, WorkspaceLoginView, WorkspaceRouter,  amplify) ->

  # Global log object for debugging
  #
  amplify.subscribe 'log', (msg) ->
    console.log msg

  # Global Flash Message handling
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

  #### Orchestrate the Workspace 
  #
  # This controller wires together different views/models
  # to handle Workspace events and in general act like
  # a switchboard operator.
  #
  WorkspaceController =
    Amplify              : amplify
    workspace_button     : $('#button-workspace')
    workspace_breadcrumb : $('#breadcrump')
    workspace_admin      : $('#header-admin')
    workspace_canvas     : $('#canvas')
    router               : new WorkspaceRouter()
    
    # Simple logger
    logger               : (msg) ->
      @Amplify.publish 'log', msg

    flash : (type, msg) ->
      @Amplify.publish 'flash', type, msg

    # Stub for login form. This should be expanded to handle
    # checking for Auth in cookies, etc.
    build_login : () ->
      @user = new UserModel()
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
          urlRoot  : ics360.services.ixdirectory + 'identities'
          'username' : username
          'password' : password

      # retrieve an identity document or fail
      @user.fetch(
          success : (model, resp) =>
            # The model has to figure out what the
            # response state was
            @user.response_state()
            switch @user.get('fetch_state').code
              when "200" then @login_success model, resp
              else @login_fail model, resp, @user.get('fetch_state')
          error : (model, resp) =>
            @response_fail model, resp
        )

    # Need to throw a nice error message
    response_fail : (model, resp) ->
      @logger "PHALE!"

    login_success : (model, resp) ->
      @user.parse_identity() # Additional setup on model
      @flash 'success', "HELLO THERE #{@user.get('name')}"
      console.log @user

    login_fail : (model, resp, state) ->
      @flash 'warning', "SOWWEE you no enter cause #{state.text}"

    # Kick off the show
    init : () ->
      @build_login()


  _.extend WorkspaceController, Backbone.Events

  WorkspaceController.on "log", (msg) ->
    @logger msg

  
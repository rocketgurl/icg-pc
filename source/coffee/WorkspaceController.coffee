define [
  'jquery', 
  'underscore',
  'backbone',
  'UserModel',
  'ConfigModel',
  'WorkspaceLoginView',
  'WorkspaceCanvasView',
  'WorkspaceNavView',
  'WorkspaceRouter',
  'base64',
  'MenuHelper',
  'amplify_core',
  'amplify_store',
  'cookie',
  'xml2json'
], ($, _, Backbone, UserModel, ConfigModel, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter,  Base64, MenuHelper, amplify) ->

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
    $workspace_header     : $('#header')
    $workspace_button     : $('#button-workspace')
    $workspace_breadcrumb : $('#breadcrumb')
    $workspace_admin      : $('#header-admin')
    $workspace_canvas     : $('#canvas')
    $workspace_tabs       : $('#workspace nav ul')
    Router                : new WorkspaceRouter()
    COOKIE_NAME           : 'ics360.PolicyCentral'

    # Keep tabs on what's in our Workspace.
    # This should contain WorkspaceCanvasView-enabled objects
    workspace_stack : []

    # Add a view to the stack, but check for duplicates first
    stack_add : (view) ->
      exists = _.find @workspace_stack, (item) ->
        return item.options.app == view.options.app
      if !exists?
        @workspace_stack.push view

    # Remove a view from the stack
    stack_remove : (view) ->
      for index, obj of @workspace_stack
        if view.options.app == obj.options.app
          @workspace_stack.splice index
    
    # Simple logger
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Display a flash message in the browser
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
    # @param `digest` _String_ Base64.encode username:password
    #
    set_cookie_identity : (digest) ->
      $.cookie(@COOKIE_NAME, digest, { expires : 7 })

    # Render the login form
    build_login : () ->
      @login_view = new WorkspaceLoginView({
          controller   : @
          template     : $('#tpl-ics-login')
          template_tab : $('#tpl-workspace-tab').html()
          tab_label : 'Login'
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
      @flash 'warning', "There was a problem retreiving the configuration file. Please contact support. Error: #{resp.status} - #{resp.statusText}"
      @logger "PHALE!"

    # On a successfull login have @user set some variables
    # and set an identity cookie to smooth logging in later.
    #
    # @param `model` _Object_ User model  
    # @param `resp` _Object_ Response from server  
    #
    login_success : (model, resp) ->
      @get_configs()
      @user.parse_identity() # Additional setup on model
      @set_cookie_identity(@user.get('digest')) # set cookie
      @set_admin_links() # Change admin links to name & logout
      if @login_view?
        @login_view.destroy()

    # On unsuccessful login render the login form again
    # along with a Flash message indicating issue
    #
    # @param `model` _Object_ User model
    # @param `resp` _Object_ Response from server
    # @param `state` _Object_ Error code/text from server
    #
    login_fail : (model, resp, state) ->
      @Router.navigate('login', { trigger : true })
      @flash 'warning', "SOWWEE you no enter cause #{state.text}"

    # Delete the identity cookie and nullify User
    logout : () ->
      $.cookie(@COOKIE_NAME, null)
      @user = null
      @reset_admin_links()

    # Grab ixAdmin information and load in ConfigModel
    get_configs : () ->
      @config = new ConfigModel
        urlRoot : ics360.services.ixadmin
      @config.fetch(
        success : (model, resp) =>
          @config.set 'menu', MenuHelper.build_menu(@user.get('document'), model.get('document'))
          @config.set 'menu_html', MenuHelper.generate_menu(@config.get 'menu')
          @navigation_view = new WorkspaceNavView({
              router     : @Router
              controller : @
              el         : '#header-workspace-nav'
              sub_el     : '#workspace-subnav'
              main_nav   : @config.get('menu_html').main_nav
              sub_nav    : @config.get('menu_html').sub_nav
            })
          @navigation_view.render()
          console.log @config.get 'menu'

        error : (model, resp) =>
          @flash 'warning', "There was a problem retreiving the configuration file. Please contact support."
        )

    # Simple delay to wait until assets load
    callback_delay : (ms, func) =>
      setTimeout func, ms

    #### Launch Workspace
    #
    # Attempt to setup and launch workspace based on info in the menu Obj
    #
    launch_workspace : () ->

      menu = @config.get 'menu'

      group_label = apps = menu[@current_state.business].contexts[@current_state.context].label
      apps = menu[@current_state.business].contexts[@current_state.context].apps
      app = _.find apps, (app) =>
        app.app is @current_state.app

      # Clear the stack
      @workspace_stack = []

      # Here is where you would launch the app
      @launch_app app

      # Set breadcrumb
      @$workspace_breadcrumb.html("""
        <li><em>#{@current_state.business}</em></li>
        <li><em>#{group_label}</em></li>
        <li><em>#{app.app_label}</em></li>
      """)

    #### Launch App
    #
    # Attempt to setup and launch app
    #
    launch_app : (app) ->
      newapp = new WorkspaceCanvasView({
        controller : @
        'app' : app
        })
      # @stack_add newapp
      # @stack_remove newapp
      console.log @workspace_stack

    #### Set Admin Links
    #
    # Set Admin links to user profile and logout
    #
    set_admin_links : () ->
      # Save original state
      if !@$workspace_admin_initial?
        @$workspace_admin_initial = @$workspace_admin.find('ul').html()

      @$workspace_admin.find('ul').html("""
        <li>Welcome back &nbsp;<a href="#profile">#{@user.get('name')}</a></li>
        <li><a href="#logout">Logout</a></li>
      """)

    #### Reset Admin Links
    #
    # Set Admin links back to original state
    #
    reset_admin_links : () ->
      @$workspace_admin.find('ul').html(@$workspace_admin_initial)

    # Kick off the show
    init : () ->
      @Router.controller = @
      Backbone.history.start()
      @check_cookie_identity()


  _.extend WorkspaceController, Backbone.Events


  # Events for Controller
  #
  WorkspaceController.on "log", (msg) ->
    @logger msg

  WorkspaceController.on "launch", () ->
    @launch_workspace()

  WorkspaceController.on "stack_add", (view) ->
    @stack_add(view)

  WorkspaceController.on "stack_remove", (view) ->
    @stack_remove(view)

  
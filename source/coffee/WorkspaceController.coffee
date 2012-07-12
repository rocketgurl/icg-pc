define [
  'jquery', 
  'underscore',
  'backbone',
  'UserModel',
  'ConfigModel',
  'WorkspaceStateModel',
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
], ($, _, Backbone, UserModel, ConfigModel, WorkspaceStateModel, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter,  Base64, MenuHelper, amplify) ->

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

    # Simple logger
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Display a flash message in the browser
    flash : (type, msg) ->
      @Amplify.publish 'flash', type, msg    

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
      _.each @workspace_stack, (obj, index) =>
        if view.app.app == obj.app.app
          @workspace_stack.splice index, 1

    # Remove all views from stack
    stack_clear : () ->
      @workspace_stack = []
      @workspace_state.set 'apps', [] # maintain in state

    # Find a view in the stack and return it
    stack_get : (app) ->
      for index, obj of @workspace_stack
        if app == obj.app.app
          return obj

    # If app is not saved in @workspace_state and is not the 
    # workspace defined app then we need to add it to our
    # stack of saved apps
    #
    # @param `app` _Object_ application config object
    #
    state_add : (app) ->
      # No workspace default apps allowed
      if app.app is @current_state.app
        return

      saved_apps = @workspace_state.get 'apps'

      if saved_apps?
        # Check to see if this app is already in the array.
        # If its not, add it.
        exists = @state_exists app
        if !exists?
            saved_apps.push app
      else
        # Otherwise create a new array of apps if this app
        # is not the workspace defined default
        if app.app != @current_state.app
          saved_apps = [app]

      @workspace_state.set 'apps', saved_apps
      @workspace_state.save()

    # Remove app from saved workspace state
    #
    # @param `app` _Object_ application config object
    #
    state_remove : (app) ->
      saved_apps = @workspace_state.get 'apps'
      _.each saved_apps, (obj, index) =>
        if app.app == obj.app
          saved_apps.splice index, 1
      @workspace_state.set 'apps', saved_apps
      @workspace_state.save()
    
    # Check to see if an app already exists in saved state
    #
    # @param `app` _Object_ application config object
    #
    state_exists : (app) ->
      saved_apps = @workspace_state.get 'apps'
      _.find saved_apps, (saved) =>
        saved.app is app.app
 

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
    build_login : ->
      @login_view = new WorkspaceLoginView({
          controller   : @
          template     : $('#tpl-ics-login')
          template_tab : $('#tpl-workspace-tab').html()
          tab_label : 'Login'
        })
      @login_view.render()
      if @navigation_view?
        @navigation_view.destroy()

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
    # TODO: Need to teardown the main nav
    logout : ->
      $.cookie(@COOKIE_NAME, null)
      @user = null
      @reset_admin_links()
      @navigation_view.destroy()
      @teardown_workspace()

    #### Get Configuration Files
    #
    # Grab ixAdmin information and load in `ConfigModel`
    # Once its loaded pass it to `MenuHelper` to generate
    # the tree for `WorkspaceNavView`
    #
    get_configs : ->
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
          
          # If our current_state is set then we should go ahead and launch.
          # We do this here to ensure we have @config set before attempting to
          # launch, which would be... bad.
          #
          # If current_state is not set, then we check localStorage to see if
          # there was a previous state saved, and try to use that one.
          #
          @check_workspace_state() # Check for localStorage state
          if @current_state?
            @trigger 'launch'
          # else
          #   @check_workspace_state() # Check for localStorage state

        # Try to throw a useful error message when possible.
        error : (model, resp) =>
          @flash 'warning', "There was a problem retreiving the configuration file. Please contact support."
        )

    # Simple delay fund if we need it.
    callback_delay : (ms, func) =>
      setTimeout func, ms

    #### Check Workplace State
    #
    # Attempt to setup and launch workspace based on localStorage
    #
    check_workspace_state : ->
      # Hit localStorage directly with Amplify
      if !_.isFunction(@Amplify.store)
        @check_workspace_state()
      raw_storage = @Amplify.store()

      # If already a PC2 object then create model with its ID and fetch()
      # otherwise create a new model (which will get a new GUID)
      if raw_storage['ics_policy_central']?
        raw_storage = raw_storage['ics_policy_central']
        raw_id = _.keys(raw_storage)[0]
        if raw_id?
          @workspace_state = new WorkspaceStateModel(
              id : raw_id
            )
          @workspace_state.fetch(
              success : (model, resp) =>
                @current_state = model.get 'workspace'
                # Make sure our address bar properly populated
                @Router.navigate "workspace/#{@current_state.env}/#{@current_state.business}/#{@current_state.context}/#{@current_state.app}"
              error : (model, resp) =>
                # Make a new WorkspaceState as we had a problem.
                @flash 'notice', "We had an issue with your saved state. Not major, but we're starting from scratch."
                @workspace_state = new WorkspaceStateModel()
            )
          
      else
        @workspace_state = new WorkspaceStateModel()

    #### Launch Workspace
    #
    # Attempt to setup and launch workspace based on info in the menu Obj
    #
    launch_workspace : ->

      menu = @config.get 'menu'

      group_label = apps = menu[@current_state.business].contexts[@current_state.context].label
      apps = menu[@current_state.business].contexts[@current_state.context].apps
      app = _.find apps, (app) =>
        app.app is @current_state.app

      # We need to destroy any existing tabs in the workspace
      # before loading a new one. We do this recursively to prevent
      # race conditions (new tabs pushing onto the stack as old ones pop off)
      #
      if @workspace_stack.length > 0
        @teardown_workspace()
        @launch_workspace() # recur
      else
        @launch_app app
        @check_persisted_apps()

      # Set breadcrumb
      @$workspace_breadcrumb.html("""
        <li><em>#{@current_state.business}</em></li>
        <li><em>#{MenuHelper.check_length group_label}</em></li>
        <li><em>#{app.app_label}</em></li>
      """)

      # Store our workplace information in localStorage
      @workspace_state.set 'workspace', {
        env      : @current_state.env
        business : @current_state.business
        context  : @current_state.context
        app      : @current_state.app
      }
      @workspace_state.save()

    #### Launch App
    #
    # Attempt to setup and launch app. Apps are added
    # to the stack from the `WorkspaceCanvasView` itself
    # using events so that if for some reason the view
    # doesn't load, we don't have to add it to the stack.
    #
    # @param `app` _Object_ application config object
    #
    launch_app : (app) ->
      # If app is not saved in @workspace_state and is not the 
      # workspace defined app then we need to add it to our
      # stack of saved apps
      @state_add app

      # Determine which Module to load into the view
      default_module = 'TestModule'
      if app.params?
        default_module = app.params.pcModule or 'TestModule'

      # Open workspace defined default application
      @create_workspace default_module, app

    # Instantiate a new WorkspaceCanvasView
    #
    # @param `module` _String_ name of module to load  
    # @param `app` _Object_ application config object  
    #
    create_workspace : (module, app) ->
      new WorkspaceCanvasView({
            controller : @
            module_type : module
            'app' : app
            })

    # If there are other apps persisted in localStorage we need
    # to launch those as well
    check_persisted_apps : ->
      saved_apps = @workspace_state.get 'apps'
      if saved_apps?
        for app in saved_apps
          console.log app
          @launch_app app

    #### Set Admin Links
    #
    # Set Admin links to user profile and logout
    #
    set_admin_links : ->
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
    reset_admin_links : ->
      @$workspace_admin.find('ul').html(@$workspace_admin_initial)

    attach_tab_handlers : ->
      # Tabs
      @$workspace_tabs.on 'click', 'li a', (e) =>
        e.preventDefault()
        app_name = $(e.target).attr('href')
        @toggle_apps app_name

      # Tab close icon
      @$workspace_tabs.on 'click', 'li i', (e) =>
        e.preventDefault()
        @stack_get($(e.target).prev().attr('href')).destroy()
        @reassess_apps()

    # Loop through app stack and switch app states
    toggle_apps : (app_name) ->
      for view in @workspace_stack
        if app_name == view.app.app
          view.activate()
        else
          view.deactivate()

    # Look for active views in the stack, if there are none
    # then activate the last one in the stack.
    reassess_apps : ->
      # No stack, no need
      if @workspace_stack.length == 0
        return false

      active = _.filter @workspace_stack, (view) ->
        return view.is_active()

      if active.length == 0
        last_view = _.last @workspace_stack
        @toggle_apps last_view.app.app

    # Tell every app in the stack to commit seppuku
    teardown_workspace : ->
      _.each @workspace_stack, (view, index) =>
        view.destroy()


    # Kick off the show
    init : () ->
      @Router.controller = @
      Backbone.history.start()
      @check_cookie_identity()
      @attach_tab_handlers()


  _.extend WorkspaceController, Backbone.Events


  # Events for Controller
  #
  WorkspaceController.on "log", (msg) ->
    @logger msg

  WorkspaceController.on "login", ->
    @build_login()

  WorkspaceController.on "logout", ->
    @logout()

  WorkspaceController.on "launch", ->
    @launch_workspace()

  WorkspaceController.on "stack_add", (view) ->
    @stack_add view

  WorkspaceController.on "stack_remove", (view) ->
    @stack_remove(view)
    @state_remove(view.app)

  WorkspaceController.on "new_tab", (app_name) ->
    @toggle_apps app_name

  
define [
  'UserModel'
  'ConfigModel'
  'WorkspaceStack'
  'WorkspaceStateModel'
  'WorkspaceStateCollection'
  'WorkspaceLoginView'
  'WorkspaceCanvasView'
  'WorkspaceNavView'
  'PolicyHistoryView'
  'WorkspaceRouter'
  'modules/Search/SearchContextCollection'
  'modules/ReferralQueue/AssigneeListView'
  'Messenger'
  'base64'
  'MenuHelper'
  'AppRules'
  'Helpers'
  'Cookie'
  'herald'
  'marked'
], (UserModel, ConfigModel, WorkspaceStack, WorkspaceStateModel, WorkspaceStateCollection, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, PolicyHistoryView, WorkspaceRouter, SearchContextCollection, AssigneeListView, Messenger, Base64, MenuHelper, AppRules, Helpers, Cookie, Herald, marked, xml2json) ->

  # Global log object for debugging
  #
  amplify.subscribe 'log', (msg) ->
    console.log msg

  # Services
  # ----
  # pxCentral and ixLibrary are base urls that are modified later in
  # launch_workspace()
  #
  ics360 =
    services :
      ixdirectory    : './ixdirectory/api/rest/v2/'
      pxcentral_base : 'pxcentral/api/rest/v1/'
      mxserver_base  : 'mxserver/api/rest/v1/'
      pxserver_base  : 'pxserver/policies'
      ixdoc          : './ixdoc/api/rest/v2/'
      ixadmin        : "./config/ics/#{window.ICS360_ENV}/policycentral"
      ixvocab        : './ixvocab/api/rest/v1/'
      zendesk        : './zendesk'
      pxclient       : '../swf/PolicySummary.swf'
      agentportal    : './agentportal/api/rest/v2/'

  # Method Combinator (Decorator)
  # https://github.com/raganwald/method-combinators
  #
  # Ensure that workspace_state is valid
  # We make sure @workspace_state is valid before operating
  # on it, or return false
  valid_workspace = (methodBody) ->
    ->
      if @workspace_state? and !_.isEmpty(@workspace_state)
        methodBody.apply(this, arguments)
      else
        false

  #### Orchestrate the Workspace
  #
  # This controller wires together different views/models
  # to handle Workspace events and in general act like
  # a switchboard operator.
  #
  WorkspaceController =
    Amplify                  : amplify
    $workspace_header        : $('#header')
    $workspace_el            : $('#workspace')
    $workspace_footer        : $('#footer-main')
    $workspace_button        : $('#button-workspace')
    $workspace_breadcrumb    : $('#breadcrumb')
    $workspace_admin         : $('#header-admin')
    $workspace_main_navbar   : $('#header-navbar')
    $workspace_canvas        : $('#canvas')
    $workspace_nav           : $('#workspace nav')
    $workspace_tabs          : $('#workspace #open-policy-tabs')
    $no_policy_flag          : $('#workspace .no-policies')
    Router                   : new WorkspaceRouter()
    Cookie                   : new Cookie()
    COOKIE_NAME              : 'ics360_PolicyCentral'
    services                 : ics360.services
    global_flash             : new Messenger($('#canvas'), 'controller')
    workspaceStateCollection : new WorkspaceStateCollection()
    workspace_zindex         : 30000
    workspace_stack          : {} # store a ref to WorkspaceStack here
    policyHistoryViews       : {}
    APP_PC_AUTH              : 'Y29tLmljcy5hcHBzLnBvbGljeWNlbnRyYWw6N2FjZmU5NTAxNDlkYWQ4M2ZlNDdhZTdjZDdkODA2Mzg='
    IXVOCAB_AUTH             : 'Y29tLmljcy5hcHBzLmluc2lnaHRjZW50cmFsOjVhNWE3NGNjODBjMzUyZWVkZDVmODA4MjkzZWFjMTNk'

    # function to support document opening from pxClient flash module
    launchAttachmentWindow : (url, params) ->
      document.getElementById('urlfield').value = url
      document.getElementById('paramsfield').value = params
      document.getElementById('ieform').submit()

    # Simple logger
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # If app is not saved in @workspace_state and is not the
    # workspace defined app then we need to add it to our
    # stack of saved apps
    #
    # @param `app` _Object_ application config object
    #
    state_add : (app) ->
      # No workspace default apps allowed
      if app.app is @current_state.app
        return false

      saved_apps = @workspace_state.get 'apps'

      if saved_apps?
        # Check to see if this app is already in the array.
        # If its not, add it.
        exists = @state_exists app
        if !exists?
          saved_apps.push app
        else
          return false
      else
        # Otherwise create a new array of apps if this app
        # is not the workspace defined default
        if app.app != @current_state.app
          saved_apps = [app]

      # If app is a policy, add it to our history stack
      if /policyview_/.test app.app
        @workspace_state.updateHistoryStack app

      @workspace_state.set 'apps', saved_apps
      @workspace_state.save()
      return true

    # Remove app from saved workspace state
    #
    # @param `app` _Object_ application config object
    #
    state_remove :
      valid_workspace \
      (app) ->
        saved_apps = @workspace_state.get 'apps'
        _.each saved_apps, (obj, index) =>
          if app.app is obj.app
            saved_apps.splice index, 1
            if app.app is @current_state.module
              @current_state.module = null
        @workspace_state.set 'apps', saved_apps
        @workspace_state.set 'workspace', @current_state
        @workspace_state.save()

    # Check to see if an app already exists in saved state
    #
    # @param `app` _Object_ application config object
    #
    state_exists :
      valid_workspace \
      (app) ->
        if _.isObject app
          saved_apps = @workspace_state.get 'apps'
          _.find saved_apps, (saved) =>
            saved.app is app.app

    setBaseRoute : ->
      {env, business, context, app} = @current_state
      @baseRoute = "workspace/#{env}/#{business}/#{context}/#{app}"
      unless location.hash
        @Router.navigate @baseRoute

    # Try and keep the localStorage version of app state
    # persisted across requests
    setWorkspaceState : ->
      if @current_state? and @workspace_state?
        # If this is a string, then deserialize it
        params = @current_state.params
        if _.isString(params)
          @current_state.params = Helpers.unserialize params

        # Get the current workspace, if not present, then
        # we need to create a new workspace for the current_state
        @workspace_state = @workspaceStateCollection.retrieve @current_state
        if _.isEmpty @workspace_state
          @workspace_state = @workspaceStateCollection.create
            workspace : @current_state
        @workspace_state.save()
        @navigation_view.setState()

    # Check for an identity cookie and check server for
    # validity. If no cookie present then just build the
    # login form as usual.
    #
    check_cookie_identity : ->
      cookie = @Cookie.get(@COOKIE_NAME)
      if cookie?
        cookie = Base64.decode(cookie).split(':')
        if @check_credentials(cookie[0], cookie[1])
          true
      else
        @Router.navigate('login', { trigger : true })
        false

    # Drop an identity cookie in the browser.
    # This is in the form of a username:password digest
    # Honestly, this is pretty insecure - should really
    # be using a token generated by the server and stored
    # in the User table. We expire this cookie after 7 days.
    #
    # @param `digest` _String_ Base64.encode username:password
    #
    set_cookie_identity : (digest) ->
      @Cookie.set(@COOKIE_NAME, digest, { expires : 7, secure : true })

    # Render the login form
    build_login : ->
      # Shim in a container for the login form
      if $('#login-container').length == 0
        $('#target').prepend('<div id="login-container" />')

      @login_view = new WorkspaceLoginView({
          controller : this
        })
      @login_view.render()

      if @navigation_view?
        @navigation_view.destroy()
        @navigation_view = null

      $('body').removeClass()
      $('body').addClass('logo-background')

      @resize_workspace()
      @login_view

    # Instantiate a new user and check ixDirectory
    # for valid credentials
    check_credentials : (username, password) ->
      unless @user?
        @user = new UserModel
          urlRoot  : @services.ixdirectory + 'identities'
          username : username
          password : password

        # retrieve an identity document or fail
        @user.fetch
          success : (model, resp) =>
            # The model has to figure out
            # what the response state was
            model.response_state()
            status = model.get 'fetch_state'
            if _.isObject(status) and status.code is '200'
              @login_success model, resp
            else
              @login_fail model, resp, status.code
          error : (model, resp) =>
            @response_fail model, resp

      @user

    # Need to throw a nice error message
    response_fail : (model, resp) ->
      errMsg = ''
      if @login_view?
        @login_view.removeLoader()
        @login_view.displayMessage 'warning', "Sorry, your password or username was incorrect"
      else
        errMsg += '@login_view not defined; '
      if Muscula?.errors?
        errMsg += "Response fail: #{resp.status} : #{resp.statusText} - #{resp.responseText}"
        err = new Error errMsg
        Muscula.errors.push err

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
      @show_workspace_button()

      if @login_view?
        @login_view.destroy()
        @login_view.remove()
        delete @login_view
        $('body').removeClass('logo-background')

      Herald.execute()


    # On unsuccessful login render the login form again
    # along with a Flash message indicating issue
    #
    # @param `model` _Object_ User model
    # @param `resp` _Object_ Response from server
    # @param `state` _Object_ Error code/text from server
    #
    login_fail : (model, resp, state) ->
      if @login_view?
        @login_view.removeLoader()

      # @Router.navigate('login', { trigger : true })

      msg = "There was an error parsing your identity record: #{state}"
      if state == "401"
        msg = "Your username/password was incorrect. Please try again"

      @login_view.displayMessage 'warning', msg

    # Delete the identity cookie and nullify User
    # TODO: Need to teardown the main nav
    logout : ->
      @Cookie.remove(@COOKIE_NAME)
      @user = null
      @reset_admin_links()
      @set_breadcrumb()
      @close_policy_nav()
      @hide_workspace_button()
      @hide_navigation()

      if @navigation_view?
        @navigation_view.destroy()
        @navigation_view = null
      @teardownWorkspace()
      @destroyWorkspaceStates()

    destroyWorkspaceStates : ->
      if @workspace_state?
        @workspace_state.destroy?()
        delete @workspace_state
        delete @current_state
      @workspaceStateCollection?.reset()
      @Amplify.store 'ics_policy_central', null

    handlePolicyHistory : ->
      if id = @workspace_state?.id

        # Instantiate a new view for each workspace_state model
        unless _.isObject @policyHistoryViews[id]
          @policyHistoryViews[id] = new PolicyHistoryView
            controller     : this
            workspaceState : @workspaceStateCollection.get id
            el             : '#policy-history'

        @policyHistoryViews[id].render()

    #### Get Configuration Files
    #
    # Grab ixAdmin information and load in `ConfigModel`
    # Once its loaded pass it to `MenuHelper` to generate
    # the tree for `WorkspaceNavView`
    #
    get_configs : ->
      @config = new ConfigModel
        urlRoot : @services.ixadmin

      @config.fetch(
        success : (model, resp) =>
          menu = MenuHelper.build_menu(@user.get('document'), model.get('document'))
          if menu is false
            @Amplify.publish 'controller', 'warning', "Sorry, you do not have access to any items in this environment."
            return
          else
            @config.set 'menu', menu
            @config.set 'menu_html', MenuHelper.generate_menu(menu)
            @show_navigation()

            # Instantiate our SearchContextCollection
            @navigation_view = new WorkspaceNavView({
                controller : @
                el         : '#header-workspace-nav'
                sub_el     : '#workspace-subnav'
                main_nav   : @config.get('menu_html').main_nav
                sub_nav    : @config.get('menu_html').sub_nav
              })

            @setupWorkspaceState()
            @determineNavState menu

            unless _.isEmpty @current_state
              @launch_workspace()

        # Try to throw a useful error message when possible.
        error : (model, resp) =>
          @Amplify.publish 'controller', 'warning', "There was a problem retreiving the configuration file. Please contact support."
        )

    # Simple delay func if we need it.
    callback_delay : (ms, func) =>
      setTimeout func, ms

    determineNavState : (menu) ->
      @navigation_view.setState()
      unless @workspaceStateCollection.length
        # attempt to launch the workspace immediately if user has access to
        # only 1 context, as is the case for the vast majority of users
        workspaceRoutes = MenuHelper.getWorkspaceRoutes menu
        if workspaceRoutes.length is 1
          @Router.navigate(workspaceRoutes[0], { trigger : true })

        # Otherwise, toggle the workspace nav
        else if _.isEmpty @current_state
          @navigation_view.show_nav() # open main nav

    #### Check Workplace State
    #
    # Attempt to setup and launch workspace based on localStorage
    setupWorkspaceState : (menu) ->
      rawStorage = @Amplify.store 'ics_policy_central'
      storage    = @workspaceStateCollection.reset _.values(rawStorage)
      @current_state = @current_state or {}
      if storage.length
        @workspace_state = storage.retrieve @current_state
        unless _.isObject @workspace_state
          @workspace_state = storage.first()
          @current_state = @workspace_state.get 'workspace'
      else
        @workspace_state = {}

    #### Check logged in state
    isLoggedIn : ->
      if !@user?
        @Amplify.publish 'controller',
                         'notice',
                         "Please login to Policy Central to continue."
        @build_login()
        return false
      return true

    #### Launch Workspace
    #
    # Attempt to setup and launch workspace based on info in the menu Obj
    #
    launch_workspace : ->
      if @isLoggedIn()
        menu = @config.get 'menu'
        if menu == false
          @Amplify.publish 'controller',
                           'warning',
                           "Sorry, you do not have access to any items in this environment."
          return

        @setBaseRoute()

        group_label = menu[@current_state.business].contexts[@current_state.context].label
        apps = menu[@current_state.business].contexts[@current_state.context].apps

        app = _.find apps, (app) =>
          app.app is @current_state.app

        # We need to destroy any existing tabs in the workspace
        # before loading a new one. We do this recursively to prevent
        # race conditions (new tabs pushing onto the stack as old ones pop off)
        @teardownWorkspace()

        @launch_app app
        @initAssigneeListView()

        if @check_persisted_apps()
          if @current_state.module
            @launch_module()
          else
            @reassess_apps()

        data =
          business : @current_state.business
          group    : MenuHelper.check_length(group_label)
          app      : app.app_label

        # Set breadcrumb
        @set_breadcrumb(data)

        @set_business_namespace()

        # Store our workplace information in localStorage
        @setWorkspaceState()

        # Initialize Policy History (Recently Viewed) handling
        @handlePolicyHistory()

        # Setup service URLs
        @configureServices()

    # Scan config model and dynamically update services object
    # to use the correct URLs
    #
    configureServices : ->
      # Set the path to pxCentral & ixLibrary to the correct instance
      @services.ixlibrary = @config.get_ixLibrary(@workspace_state)

      if url = @config.get_pxCentral(@workspace_state)
        @services.pxcentral = "#{url}#{@services.pxcentral_base}"
        @services.mxserver  = "#{url}#{@services.mxserver_base}"
        @services.pxserver  = "#{url}#{@services.pxserver_base}"

      # Some ixVocab actions need to happen through the services router
      if !window.USE_PROXY
        @services.ixvocab = @config.get_universal_service(@workspace_state, 'ixvocab')

      # Loop through additional services & gather config
      # ICS-1451: removed ixdirectory from list since it doesn't take
      # non-auth OPTIONS requests currently
      for node in ['cxserver', 'ixprofiler', 'ixrelay', 'zendesk']
        @services[node] = @config.get_universal_service(@workspace_state, node)

      # Retrieve pxClient location from ixConfig
      @services.pxclient = @config.get_pxClient(@workspace_state)

      # Retrieve the base Agent Support View url
      @services.agentSupport = @config.get_agent_support(@workspace_state)

      @services.agentPortalNotices = @config.get_agent_portal_notices(@workspace_state)

    # Build the breadcrumb in the top nav
    #
    # @param `data` _Object_ env labels
    #
    set_breadcrumb : (data) ->
      if data?
        @$workspace_breadcrumb.html("""
          <li><em>#{data.business}</em></li>
          <li><em>#{data.group}</em></li>
          <li><em>#{data.app}</em></li>
        """)
      else
         @$workspace_breadcrumb.html('')

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
      if _.isUndefined app
        return false
      else if @state_exists(app)?
        @toggle_apps app.app
      else
        @state_add app

      # Determine which Module to load into the view
      rules = rules or new AppRules app
      default_workspace = rules.default_workspace

      # Open modules defined in workspace set
      for workspace in default_workspace
        @create_workspace workspace.module, workspace.app

    #### Launch A Module App w/ params
    #
    # @param `params` _Object_ query params
    #
    launch_module : ->
      if @isLoggedIn()
        params = @current_state.params or {}
        module = @current_state.module
        safe_app_name = "#{Helpers.id_safe(module)}"
        if params.url
          safe_app_name += "_#{Helpers.id_safe(params.url)}"

        if @workspace_stack.has safe_app_name
          @toggle_apps safe_app_name
        else
          label = params.label or "#{Helpers.uc_first(module)}: #{params.url}"
          @launch_app
            app       : safe_app_name
            app_label : label
            params    : params

    # Instantiate a new WorkspaceCanvasView
    #
    # @param `module` _String_ name of module to load
    # @param `app` _Object_ application config object
    #
    create_workspace : (module, app) ->
      options =
        controller  : @
        module_type : module
        app         : app

      if app.tab?
        options.template_tab = $(app.tab).html()

      new WorkspaceCanvasView(options)

    # If there are other apps persisted in localStorage we need
    # to launch those as well
    check_persisted_apps : ->
      unless _.isEmpty @workspace_state
        _.each @workspace_state.get('apps'), (app) =>
          @launch_app app
        return true
      false

    # Add helpful body class for CSS purposes
    set_business_namespace : ->
      if business = @current_state?.business
        $('body').removeClass().addClass("is-#{business}")

    initAssigneeListView : ->
      @assigneeListView = new AssigneeListView
        controller : this
        el         : '#assignee-list-modal'

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
        <li><a href="#" data-toggle="modal" data-target="#help-modal" data-workspace="saguresure">Help</a></li>
        <li><a href="#logout">Logout</a></li>
        """)

    #### Reset Admin Links
    #
    # Set Admin links back to original state
    #
    reset_admin_links : ->
      @$workspace_admin.find('ul').html(@$workspace_admin_initial)

    # Display workspace button and breadcrumb
    show_workspace_button : ->
      @$workspace_button.fadeIn(400)
      $('#header-controls span').fadeIn(400)
      @$workspace_breadcrumb.fadeIn(400)

    # Display workspace button and breadcrumb
    hide_workspace_button : ->
      @$workspace_button.fadeOut(400)
      $('#header-controls span').fadeOut(400)
      @$workspace_breadcrumb.fadeOut(400)

    show_navigation : ->
      @$workspace_main_navbar.show()
      @$workspace_nav.show()
      @resize_workspace()

    hide_navigation : ->
      @$workspace_main_navbar.hide()
      @$workspace_nav.hide()
      @resize_workspace()

    # Tab close icon
    attach_tab_handlers : ->
      @$workspace_tabs.on 'click', 'li .glyphicon-remove-circle', (e) =>
        e.preventDefault()
        view = $(e.currentTarget).data 'view'
        @workspace_stack.get(view).destroy()
        @reassess_apps()

    # HACK: Because we don't want to re-render the navbar for each
    # separate workspace, we handle the routing programatically here.
    attach_navbar_handlers : ->
      @$workspace_main_navbar.on 'click', 'li > a', (e) =>
        $el = $(e.currentTarget)

        # Allow the default behavior if [target="_blank"] is present
        if $el.is '[target="_blank"]'
          return true

        # Launch module if [data-app="<app>"] is present
        if route = $el.data 'route'
          @Router.navigate "#{@baseRoute}/#{route}", { trigger : true }

        e.preventDefault()

    attach_window_resize_handler : ->
      lazyResize = _.debounce _.bind(@resize_workspace, this), 500
      $(window).on 'resize', lazyResize

    resize_workspace : ->
      headerHeight    = @$workspace_header.height()
      footerHeight    = @$workspace_footer.height()
      windowHeight    = window.innerHeight
      workspaceHeight = windowHeight - headerHeight - footerHeight - 1
      @$workspace_el.height workspaceHeight

    open_policy_nav : ->
      @$workspace_el.removeClass 'out'

    close_policy_nav : ->
      @$workspace_el.addClass 'out'

    toggle_policy_nav : ->
      if @$workspace_el.is('.out')
        @open_policy_nav()
      else
        @close_policy_nav()

    attach_policy_nav_handler : ->
      $('.nav-toggle').on 'click', (e) =>
        @toggle_policy_nav()
        e.preventDefault()

    handle_policy_count : ->
      @$no_policy_flag[if @workspace_stack.policyCount > 0 then 'hide' else 'show']()

    # Loop through app stack and switch app states
    toggle_apps : (app_name) ->
      for view in @workspace_stack.stack
        if app_name == view.app.app
          @active_view = view
          view.activate()
          true
        else
          view.deactivate()

    # Look for active views in the stack, if there are none
    # then activate the last one in the stack.
    reassess_apps : ->
      if @workspace_stack.stack.length
        active = _.find @workspace_stack.stack, (view) ->
          view.is_active()
        unless active
          if @workspace_stack.stack.length > 2
            view = _.last @workspace_stack.stack
          else # Activate first app in the stack
            view = @workspace_stack.stack[0]
          @toggle_apps view.app.app

    # Tell every app in the stack to commit seppuku
    teardownWorkspace : ->
      @set_breadcrumb()
      @assigneeListView.dispose() if @assigneeListView
      @workspace_stack.clear()
      @$workspace_tabs.html('')
      $('#target').empty()

    # Configure Herald to display updates
    # and notifications to users after login
    setupHerald : ->
      herald_config =
        h_path        : '/js/lib/herald/'
        change_path   : '/'
        change_file   : 'CHANGES.md'
        version       : $('#version-number').text()
        inject_point  : 'body'
        textProcessor : marked
      Herald.init herald_config

    # Kick off the show
    init : ->
      @setupHerald()
      @callback_delay 100, =>
        @Router.controller = this
        Backbone.history.start()
        @check_cookie_identity()
        @attach_tab_handlers()
        @attach_navbar_handlers()
        @attach_policy_nav_handler()
        @attach_window_resize_handler()

  _.extend WorkspaceController, Backbone.Events

  # Maintain an array of WorkspaceCanvasView objects (all of our
  # tabs)
  WorkspaceController.workspace_stack = new WorkspaceStack(WorkspaceController)

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
    @workspace_stack.add view
    @handle_policy_count()

  WorkspaceController.on "stack_remove", (view) ->
    @workspace_stack.remove(view)
    @state_remove(view.app)
    @handle_policy_count()

  WorkspaceController.on "new_tab", (app_name) ->
    @toggle_apps app_name

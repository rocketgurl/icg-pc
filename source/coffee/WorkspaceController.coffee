define [
  'jquery',
  'underscore',
  'backbone',
  'UserModel',
  'ConfigModel',
  'WorkspaceStateModel',
  'WorkspaceStateCollection',
  'WorkspaceLoginView',
  'WorkspaceCanvasView',
  'WorkspaceNavView',
  'WorkspaceRouter',
  'modules/Search/SearchContextCollection',
  'Messenger',
  'base64',
  'MenuHelper',
  'AppRules',
  'Helpers',
  'Cookie'
], ($, _, Backbone, UserModel, ConfigModel, WorkspaceStateModel, WorkspaceStateCollection, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter, SearchContextCollection, Messenger, Base64, MenuHelper, AppRules, Helpers, Cookie, xml2json) ->

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
      ixlibrary_base : 'ixlibrary/api/sdo/rest/v1/'
      ixdoc          : './ixdoc/api/rest/v2/'
      ixadmin        : './config/ics/staging/ixadmin' # TESTING ONLY
      zendesk        : 'https://staging-services.icg360.org/zendesk'

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
    Amplify               : amplify
    $workspace_header     : $('#header')
    $workspace_button     : $('#button-workspace')
    $workspace_breadcrumb : $('#breadcrumb')
    $workspace_admin      : $('#header-admin')
    $workspace_canvas     : $('#canvas')
    $workspace_tabs       : $('#workspace nav ul')
    Router                : new WorkspaceRouter()
    Cookie                : new Cookie()
    COOKIE_NAME           : 'ics360_PolicyCentral'
    services              : ics360.services
    global_flash          : new Messenger($('#canvas'), 'controller')
    Workspaces            : new WorkspaceStateCollection()

    # Simple logger
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Display a flash message in the browser
    flash : (type, msg) ->
      @Amplify.publish @login_view.cid, type, msg    

    # Keep tabs on what's in our Workspace.
    # This should contain WorkspaceCanvasView-enabled objects
    workspace_stack : []

    # Add a view to the stack, but check for duplicates first
    stack_add : (view) ->
      exists = _.find @workspace_stack, (item) ->
        return item.app.app == view.app.app
      if !exists?
        @workspace_stack.push view

    # Remove a view from the stack
    stack_remove : (view) ->
      _.each @workspace_stack, (obj, index) =>
        if view.app.app == obj.app.app
          @workspace_stack.splice index, 1
          # Remove params from stack if present
          if view.app.params?
            @current_state.params = null
            @set_nav_state()
            @update_address()

    # Remove all views from stack
    stack_clear : () ->
      @workspace_stack = []
      #@workspace_state.set 'apps', [] # maintain in state

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
          if app.app == obj.app
            saved_apps.splice index, 1
        @workspace_state.set 'apps', saved_apps
        @workspace_state.save()
    
    # Check to see if an app already exists in saved state
    #
    # @param `app` _Object_ application config object
    #
    state_exists :
      valid_workspace \
      (app) ->
        saved_apps = @workspace_state.get 'apps'
        _.find saved_apps, (saved) =>
          saved.app is app.app
 

    # Try and keep the localStorage version of app state
    # persisted across requests
    set_nav_state : ->
      if @current_state? and @workspace_state?

        if @current_state is undefined
          return false

        # If this is a string, then deserialize it
        params = @current_state.params ? null
        if _.isString(params)
          params = Helpers.unserialize params

        # Get the current workspace, if not present, then
        # we need to create a new workspace for the current_state
        @workspace_state = @Workspaces.retrieve @current_state

        if @workspace_state is undefined or _.isEmpty(@workspace_state)
          @workspace_state = @Workspaces.create({ workspace : @current_state })

        if _.isArray @workspace_state
          @workspace_state = @workspace_state[0]

        @workspace_state.set 'workspace', {
          env      : @current_state.env
          business : @current_state.business
          context  : @current_state.context
          app      : @current_state.app
          module   : @current_state.module ? null
          params   : params
        }
        @workspace_state.save()

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
      if @login_view?
        @login_view.destroy()

      @login_view = new WorkspaceLoginView({
          controller   : @
          template     : $('#tpl-ics-login')
          template_tab : $('#tpl-workspace-tab').html()
          tab_label    : 'Login'
        })
      @login_view.render()

      # Set a flash message listener on the login form
      login_flash = new Messenger(@login_view, @login_view.cid)

      if @navigation_view?
        @navigation_view.destroy()

      $('#header').css('height', '65px')
      $('body').addClass('logo-background')

      @login_view

    # Instantiate a new user and check ixDirectory
    # for valid credentials
    check_credentials : (username, password, view) ->
      @user = new UserModel
        urlRoot    : @services.ixdirectory + 'identities'
        'username' : username
        'password' : password

      # retrieve an identity document or fail
      @user.fetch(
          success : (model, resp) =>
            # The model has to figure out what the
            # response state was
            model.response_state()

            fetch_state = @user.get('fetch_state')

            if fetch_state?
              fetch_state = if _.has(fetch_state, 'code') then fetch_state.code else null            

            switch fetch_state
              when "200" then @login_success(model, resp)
              else @login_fail(model, resp, fetch_state)

          error : (model, resp) =>
            @response_fail model, resp
        )

      @user

    # Need to throw a nice error message
    response_fail : (model, resp) ->
      @Amplify.publish @login_view.cid, 'warning', "Sorry, your password or username was incorrect"
      @logger "Response fail: #{resp.status} : #{resp.statusText} - #{resp.responseText}"

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
        $('body').removeClass('logo-background')

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

      @Router.navigate('login', { trigger : true })

      msg = "There was an error parsing your identity record: #{state}"
      if state == "401"
        msg = "Your username/password was incorrect. Please try again"

      @Amplify.publish @login_view.cid, 'warning', msg

    # Delete the identity cookie and nullify User
    # TODO: Need to teardown the main nav
    logout : ->
      @Cookie.remove(@COOKIE_NAME)
      @user = null
      @reset_admin_links()
      @set_breadcrumb()
      @hide_workspace_button()

      if @navigation_view?
        @navigation_view.destroy()
        @teardown_workspace()

      @destroy_workspace_model()

    destroy_workspace_model :
      valid_workspace \
      ->
        @workspace_state.destroy() 
        @workspace_state = null
        @Amplify.store('ics_policy_central', null)

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

            # Instantiate our SearchContextCollection
            # @setup_search_storage()

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
            if @check_workspace_state() is false # Check for localStorage state
              @navigation_view.toggle_nav_slide() # open main nav        
              @navigation_view.$el.find('li a span').first().trigger('click') # select first item

            if @current_state?
              @trigger 'launch'

        # Try to throw a useful error message when possible.
        error : (model, resp) =>
          @Amplify.publish 'controller', 'warning', "There was a problem retreiving the configuration file. Please contact support."
        )

    # Simple delay func if we need it.
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
      raw_storage = @Amplify.store('ics_policy_central')
      # If already a PC2 object then add a model with its ID and fetch()
      # otherwise create a new model (which will get a new GUID)
      if raw_storage?
        raw_id = _.keys(raw_storage)[0]
        if raw_id?
          workspaces = @Workspaces.add(
              id : raw_id 
            )
          @workspace_state = workspaces.get(raw_id)
          @workspace_state.fetch(
              success : (model, resp) =>
                @current_state = model.get 'workspace'
                model.build_name()
                @update_address()
                true
              error : (model, resp) =>
                # Make a new WorkspaceState as we had a problem.
                @Amplify.publish 'controller', 'notice', "We had an issue with your saved state. Not major, but we're starting from scratch."
                @workspace_state = @Workspaces.create()
                true
            )
          true          
      else
        # If no localStorage data then make a stub object
        @workspace_state = {}
        false


    #### Setup Search Storage
    #
    # Setup collection to save search views in local storage. We
    # need to attach this to the controller to ensure
    # that models are passed around to many instances of 
    # SearchModule. It's a hack, but it works for now.
    setup_search_storage : ->

      if @SEARCH == null || @SEARCH == undefined
        return

      if !_.has(@SEARCH, 'saved_searches')
        return

      @SEARCH =
        saved_searches : new SearchContextCollection()  
            
      @SEARCH.saved_searches.controller = @ # so we can phone home
      @SEARCH.saved_searches.fetch()
      @SEARCH.saved_searches

    #### Check logged in state
    is_loggedin : ->
      if !@user?
        @Amplify.publish 'controller', 'notice', "Please login to Policy Central to continue."
        @build_login()
        return false
      return true

    #### Launch Workspace
    #
    # Attempt to setup and launch workspace based on info in the menu Obj
    #
    launch_workspace : ->
      # If not logged in then back to login
      if @is_loggedin == false
        return

      menu = @config.get 'menu'
      if menu == false
        @Amplify.publish 'controller', 'warning', "Sorry, you do not have access to any items in this environment."
        return

      group_label = apps = menu[@current_state.business].contexts[@current_state.context].label
      apps = menu[@current_state.business].contexts[@current_state.context].apps

      app = _.find apps, (app) =>
        app.app is @current_state.app

      # We need to destroy any existing tabs in the workspace
      # before loading a new one. We do this recursively to prevent
      # race conditions (new tabs pushing onto the stack as old ones pop off)
      @teardown_workspace()
      
      if $('#header').height() < 95
        $('#header').css('height', '95px')

      # Set the path to pxCentral & ixLibrary to the correct instance
      if url = @config.get_pxCentral(@workspace_state)
        @services.pxcentral = "#{url}#{@services.pxcentral_base}"
        @services.ixlibrary = "#{url}#{@services.ixlibrary_base}"

      for node in ['cxserver', 'ixdirectory', 'ixprofiler', 'ixrelay', 'ixvocab']
        @services[node] = @config.get_universal_service(@workspace_state, node)

      @launch_app app

      if @check_persisted_apps()
        # Is this a search? attempt to launch it
        if @current_state.module?
          @launch_module(@current_state.module, @current_state.params)
        @reassess_apps()

      data =
        business : @current_state.business
        group    : MenuHelper.check_length(group_label)
        'app'    : app.app_label

      # Set breadcrumb
      @set_breadcrumb(data)

      # Store our workplace information in localStorage
      @set_nav_state()


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
      if @state_exists(app)?
        @toggle_apps app.app
      else
        @state_add app

      # Determine which Module to load into the view
      rules = new AppRules(app)
      default_workspace = rules.default_workspace

      # Open modules defined in workspace set
      for workspace in default_workspace
        @create_workspace workspace.module, workspace.app

    #### Launch Search App w/ params
    #
    # We need to launch a Search Module preloaded with
    # query params.
    #
    # @param `params` _Object_ query params
    #
    launch_module : (module, params) ->
      # We need to sanitize this a little
      params ?= {}

      if !params.q and params.url?
        url = params.url

      url = params.q if params.q?

      safe_app_name = "#{Helpers.id_safe(module)}"
      safe_app_name += "_#{Helpers.id_safe(url)}" if url?

      # Setup the app object to launch policy view with
      app =
        app       : safe_app_name
        app_label : "#{Helpers.uc_first(module)}: #{url}"
        params    : params

      app.app.params = params

      # If doesn't already exist launch it
      stack_check = @stack_get safe_app_name
      if !stack_check?
        @launch_app app
      else
        @toggle_apps safe_app_name

    # Instantiate a new WorkspaceCanvasView
    #
    # @param `module` _String_ name of module to load  
    # @param `app` _Object_ application config object  
    #
    create_workspace : (module, app) ->
      options =
        controller  : @
        module_type : module
        'app'       : app

      if app.tab?
        options.template_tab = $(app.tab).html()

      new WorkspaceCanvasView(options)

    # If there are other apps persisted in localStorage we need
    # to launch those as well
    check_persisted_apps : ->
      if !@workspace_state?
        return false
      saved_apps = @workspace_state.get 'apps'
      if saved_apps?
        for app in saved_apps
          @launch_app app
      return true

    #### Update Address
    #
    # Set URL to whatever @current_state says it should be. Yo.
    #
    update_address : ->
      if @current_state?
        url = "workspace/#{@current_state.env}/#{@current_state.business}/#{@current_state.context}/#{@current_state.app}"
        if @current_state.params? and @current_state.module?
          url += "/#{@current_state.module}/#{Helpers.serialize(@current_state.params)}"
        @Router.navigate url

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

    #### Drop a click listener on all tabs
    #
    attach_tab_handlers : ->
      # Tabs
      @$workspace_tabs.on 'click', 'li a', (e) =>
        e.preventDefault()
        app_name = $(e.target).attr('href')

        # When a user clicks on a tab, that tabs URL
        # should be rendered in the address bar
        @set_active_url app_name

        # Fallback for search tabs
        if app_name is undefined
          app_name = $(e.target).parent().attr('href')

        @toggle_apps app_name

      # Tab close icon
      @$workspace_tabs.on 'click', 'li i.icon-remove-sign', (e) =>
        e.preventDefault()
        @stack_get($(e.target).prev().attr('href')).destroy()
        @reassess_apps()

    #### Set Active Url
    #
    # When a tab is clicked, use the app_name to find
    # the active tab and dig into it to get the module
    # name and params of that tab module. Then use this
    # to switch the url to what it should be.
    #
    # @param `app_name` _String_ app_name from tab href
    #
    set_active_url : (app_name) ->
      for view in @workspace_stack
        if app_name == view.app.app
          module = view.module
          if module? and module.app? and module.app.params?
            module_name = new AppRules(module.app).app_name
            @Router.append_module module_name, module.app.params
          else
            @Router.remove_module()

        #  Failsafe for default search tab with no name
        if app_name is undefined
          @Router.remove_module()

    # Loop through app stack and switch app states
    toggle_apps : (app_name) ->
      for view in @workspace_stack
        if app_name == view.app.app
          view.activate()
          @active_view = view
          @set_active_url app_name
          true
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
      @set_breadcrumb()
      _.each @workspace_stack, (view, index) =>
        view.destroy()
        view = null
      if @workspace_stack.length > 0
        @stack_clear()
        @$workspace_tabs.html('')
        $('#target').empty()
        true
      else
        false


    # Kick off the show
    init : () ->
      @callback_delay 100, =>
        @Router.controller = this
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

  WorkspaceController.on "search", (module, params) ->
    @launch_module(module, params)

  WorkspaceController.on "stack_add", (view) ->
    @stack_add view

  WorkspaceController.on "stack_remove", (view) ->
    @stack_remove(view)
    @state_remove(view.app)

  WorkspaceController.on "new_tab", (app_name) ->
    @toggle_apps app_name


  
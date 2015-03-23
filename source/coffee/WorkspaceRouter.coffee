define [
  'BaseRouter',
  'Helpers'
], (BaseRouter, Helpers) ->

  #### Routes, just the routes ma'am.
  #
  # Really, this should just handle routes and call methods 
  # back in WorkspaceController which is stored in 
  # @controller
  #
  WorkspaceRouter = BaseRouter.extend

    routes :
      'login'  : 'login'
      'logout' : 'logout'
      'workspace/:env/:business/:context/:app/policy/:quotenum/:label' : 'policyView'
      'workspace/:env/:business/:context/:app/:module/*params' : 'module'
      'workspace/:env/:business/:context/:app' : 'workspace'

    initialize : (options) ->
      @on 'all', -> console.log arguments

    # Render login form
    login : ->
      @controller.trigger 'login'

    # Delete any cookies and render login form
    logout : ->
      @controller.trigger 'logout'
      @navigate('login', { trigger : true })

    policyView : (env, business, context, app, quotenum, label) ->
      module = 'policyview'
      launchMethod = 'launch_module'
      if app isnt @controller.current_state?.app
        launchMethod = 'launch_workspace'
      params = { url : quotenum, label : decodeURIComponent(label) }
      @controller.set_current_state(env, business, context, app, module, params)
      if @controller.config?
        @controller.set_workspace_state()
        @controller[launchMethod](module, params)

    # If a module is in the current workspace,
    # simply launch the module. Otherwise, launch
    # the new workspace
    module : (env, business, context, app, module, params) ->
      launchMethod = 'launch_module'
      if app isnt @controller.current_state?.app
        launchMethod = 'launch_workspace'
      params = Helpers.unserialize params
      @controller.set_current_state(env, business, context, app, module, params)
      if @controller.config?
        @controller.set_workspace_state()
        @controller[launchMethod](module, params)

    # Parse workspace
    workspace : (env, business, context, app) ->
      @controller.set_current_state(env, business, context, app)
      if @controller.config?
        @controller.set_workspace_state()
        @controller.launch_workspace()

    # Build a path for modules (search, policyview) with the correct
    # named parameters, etc.
    #
    # @param `module` _String_ module name
    # @param `params` _Object_ app parameters. Will be serialized for url.
    #
    build_module_path : (module, params) ->
      [@controller.current_state.module, @controller.current_state.params] = [module, params]
      {env, business, context, app} = @controller.current_state

      # Seriailze params
      serialized = Helpers.serialize params

      "workspace/#{env}/#{business}/#{context}/#{app}/#{module}#{serialized}"

    # Take current workspace url and append search params to it
    #
    # @param `module` _String_ module name
    # @param `params` _Object_ app parameters. Will be serialized for url.
    #
    append_module : (module, params) ->
      @navigate @build_module_path(module, params)

    # Do the same as append_module but trigger the route
    #
    # @param `module` _String_ module name
    # @param `params` _Object_ app parameters. Will be serialized for url.
    #
    navigate_to_module : (module, params) ->
      @navigate @build_module_path(module, params), {trigger : true}

    # remove module info from url
    remove_module : ->
      {env, business, context, app} = @controller.current_state
      @navigate "workspace/#{env}/#{business}/#{context}/#{app}"




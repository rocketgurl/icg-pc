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
      'workspace/:env/:business/:context/:app/:module/*params' : 'module'
      'workspace/:env/:business/:context/:app' : 'workspace'

    initialize : (options) ->

    # Render login form
    login : () ->
      @controller.trigger 'login'

    # Delete any cookies and render login form
    logout : () ->
      @controller.trigger 'logout'
      @navigate('login', { trigger : true })

    # Search parameters
    module : (env, business, context, app, module, params) ->
      @set_controller_state(env, business, context, app, module, params)
      if @controller.config?
        # Parameter parsing
        params = Helpers.unserialize params
        @controller.launch_module module, params

    # Parse workspace
    workspace : (env, business, context, app) ->
      @set_controller_state(env, business, context, app)

      # If we already have a configuration file then we should be ready to go
      if @controller.config?
        @controller.trigger 'launch'

    # Set our workspace state in the controller
    set_controller_state : (env, business, context, app, module, params) ->
      @controller.current_state =
        'env'      : env
        'business' : business
        'context'  : context
        'app'      : app
        'module'   : module ? null
        'params'   : params ? null
      @controller.set_nav_state()


    # Build a default workspace path without any module information.
    # Based on @current_state in controller
    build_path : ->
      {env, business, context, app} = @controller.current_state
      @navigate "workspace/#{env}/#{business}/#{context}/#{app}"

    # Build a path for modules (search, policyview) with the correct
    # named parameters, etc.
    #
    # @param `module` _String_ module name
    # @param `params` _Object_ app parameters. Will be serialized for url.
    #
    build_module_path : (module, params) ->
      [@controller.current_state.module, @controller.current_state.params] = [module, params]
      @controller.set_nav_state() # save updated state
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




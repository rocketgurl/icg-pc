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
      'workspace/:env/:business/:context/:app/search/*params' : 'search'
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
    search : (env, business, context, app, params) ->
      @set_controller_state(env, business, context, app, params)
      if @controller.config?
        @controller.trigger 'launch'

    # Parse workspace
    workspace : (env, business, context, app) ->
      @set_controller_state(env, business, context, app)

      # If we already have a configuration file then we should be ready to go
      if @controller.config?
        @controller.trigger 'launch'

    # Set our workspace state in the controller
    set_controller_state : (env, business, context, app, params) ->
      if params != 'undefined'
        params = Helpers.id_safe(decodeURI(params))
      @controller.current_state =
        'env'      : env
        'business' : business
        'context'  : context
        'app'      : app
        'params'   : params ? null
      @controller.set_nav_state()

    # Take current workspace url and append search params to it
    append_search : (params) ->
      @controller.current_state.params = params
      @controller.set_nav_state() # save updated state
      {env, business, context, app} = @controller.current_state
      path = "workspace/#{env}/#{business}/#{context}/#{app}/search/#{params}"
      @navigate path

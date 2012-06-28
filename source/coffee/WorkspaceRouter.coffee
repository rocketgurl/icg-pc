define [
  'BaseRouter'
], (BaseRouter) ->

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
      'workspace/:env/:business/:context/:app' : 'workspace'

    initialize : (options) ->

    # Render login form
    login : () ->
      @controller.build_login()

    # Delete any cookies and render login form
    logout : () ->
      @controller.logout()
      @navigate('login', { trigger : true })

    # Parse workspace
    workspace : (env, business, context, app) ->
      @controller.current_state =
        'env'      : env
        'business' : business
        'context'  : context
        'app'      : app

      # If we already have a configuration file then we should be ready to go
      if @controller.config?
        @controller.trigger 'launch'


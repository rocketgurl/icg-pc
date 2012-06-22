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

    initialize : (options) ->

    # Render login form
    login : () ->
      @controller.build_login()

    # Delete any cookies and render login form
    logout : () ->
      @controller.logout()
      @navigate('login', { trigger : true })
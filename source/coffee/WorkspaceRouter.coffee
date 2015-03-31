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
      'workspace/:env/:business/:context/:app'                            : 'workspace'
      'workspace/:env/:business/:context/:app/home'                       : 'homeView'
      'workspace/:env/:business/:context/:app/search'                     : 'searchView'
      'workspace/:env/:business/:context/:app/underwriting/referrals'     : 'underwritingReferralsView'
      'workspace/:env/:business/:context/:app/underwriting/renewalreview' : 'underwritingRenewalsView'
      'workspace/:env/:business/:context/:app/policy/:quotenum'           : 'policyView'

    noop : -> # i do nothing; i harm no one

    initialize : ->
      @on 'all', @sendGAPageview

    sendGAPageview : (route) ->
      ga = if _.isFunction(window.ga) then window.ga else @noop
      ga('send', 'pageview', {
        page  : location.href
        title : route
        })

    login : ->
      if @controller.baseRoute
        @navigate @controller.baseRoute
      else
        @controller.trigger 'login'

    logout : ->
      @controller.trigger 'logout'

      # Deferring the login so the routes
      # are fired in the correct order
      _.defer @navigate, 'login', { trigger : true }

    workspace : (env, business, context, app) ->
      @launch env, business, context, app

    homeView : (env, business, context, app) ->
      @launch env, business, context, app, 'home'

    searchView : (env, business, context, app) ->
      @launch env, business, context, app, 'search'

    underwritingReferralsView : (env, business, context, app) ->
      @launch env, business, context, app, 'referral_queue'

    underwritingRenewalsView : (env, business, context, app) ->
      @launch env, business, context, app, 'renewalreview'

    policyView : (env, business, context, app, quotenum) ->
      params =
        url   : quotenum
      @launch env, business, context, app, 'policyview', params

    launch : (env, business, context, app, module, params) ->
      launchMethod = 'launch_workspace'
      if module and app is @controller.current_state?.app
        launchMethod = 'launch_module'
      @controller.current_state =
        'env'      : env
        'business' : business
        'context'  : context
        'app'      : app
        'module'   : module ? null
        'params'   : params ? null
      if @controller.config?
        @controller.setWorkspaceState()
        @controller[launchMethod]()

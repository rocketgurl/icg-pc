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
      'workspace/:env/:business/:context/:app/policy/:quotenum/:label'    : 'policyView'

    initialize : ->
      @on 'all', -> console.log arguments

    # Render login form
    login : ->
      @controller.trigger 'login'

    # Delete any cookies and render login form
    logout : ->
      @controller.trigger 'logout'
      @navigate('login', { trigger : true })

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

    policyView : (env, business, context, app, quotenum, label) ->
      params =
        url   : quotenum
        label : decodeURIComponent(label)
      @launch env, business, context, app, 'policyview', params

    launch : (env, business, context, app, module, params) ->
      launchMethod = 'launch_module'
      if app isnt @controller.current_state?.app
        launchMethod = 'launch_workspace'
      @controller.current_state =
        'env'      : env
        'business' : business
        'context'  : context
        'app'      : app
        'module'   : module ? null
        'params'   : params ? null
      if @controller.config?
        @controller.setWorkspaceState()
        @controller[launchMethod](module, params)

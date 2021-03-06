define [
  'underscore'
], (_) ->

  # Sets up rules for which modules to load for a given app.
  # Also handles any additional modules which should accompany that app
  # such as a default search tab for all policies.
  class AppRules

    default_workspace : null

    constructor : (@app) ->
      if @app.app?
        @app_name          = @get_app_name @app.app
        @default_workspace = @validate_app(@app_name)
      @

    # Filter the workspace to see if it has any required fields/params
    # and return the workspace set ready to go.
    validate_app : (app_name) ->
      modules = @get_modules(@app_name)
      validates = _.filter(modules, (module) =>
          @test_module module
        )
      validates
                   
    # Check for a required field and if present validate
    # said fields on the app definition. Returns a boolean
    # to be used in validate_app
    test_module : (module) ->
      test = false
      if module['required'] and _.isArray(module['required'])
        for r in module['required']
          if _.isEmpty(module.app[r]) or module.app[r] is undefined
            test = false
          else
            test = true
      else
        test = true

      test

    # Derive app name
    get_app_name : (app_name) ->
      if app_name.indexOf '_' > -1
        app_name.split('_')[0]
      else
        app_name

    # Determine which module definitions to return
    get_modules : (app_name) ->
      switch app_name
        when 'policies'
          [@policy_search, @renewalreview, @referral_queue, @home]
        when 'renewalreview'
          [@renewalreview]
        when 'rulesets'
          [@policy_search, @add_app(@rulesets)]
        when 'policyview'
          [@add_app(@policy_view)]
        else
          [@add_app(@default)]

    # Add the current app onto a rule definition
    add_app : (definition) ->
      definition.app = @app
      if definition.params?
        definition.app.params = definition.params
      definition

    # RULEZ Definitions
    policy_search :
      required : false
      module   : 'Search/SearchModule'
      app : 
        app       : 'search'
        app_label : 'Search'
        params    : null

    renewalreview :
      required  : false
      module    : 'Search/SearchModule'
      app :
        app       : 'renewalreview'
        app_label : 'Renewal Underwriting'
        params    :
          renewalreviewrequired : true

    home :
      required : false
      module   : 'Home/HomeModule'
      app :
        app       : 'home'
        app_label : 'Home'
    
    policy_view : 
      required : ['params']
      module   : 'Policy/PolicyModule'

    referral_queue :
      required : false
      module : 'ReferralQueue/ReferralQueueModule'
      app :
        app       : 'referral_queue'
        app_label : 'Referrals'

    default :
      required : false
      module   : 'Home/HomeModule'
      app :
        app       : 'home'
        app_label : 'Home'









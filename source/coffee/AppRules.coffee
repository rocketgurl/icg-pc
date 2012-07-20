define [
  'jquery', 
  'underscore'
], ($, _) ->

  # Sets up rules for which modules to load for a given app.
  # Also handles any additional modules which should accompany that app
  # such as a default search tab for all policies.
  class AppRules

    default_workspace : null

    constructor : (@app) ->
      if @app.app?
        app_name           = @get_app_name @app.app
        @default_workspace = @get_modules app_name

    # Derive app name
    get_app_name : (app_name) ->
      if app_name.indexOf '_' >= 0
        app_name.split('_')[0]
      else
        app_name

    # Determine which module definitions to return
    get_modules : (app_name) ->
      switch app_name
        when 'policies'
          [@policy_search]
        when 'rulesets'
          [@policy_search, @add_app(@rulesets)]
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
      module : 'SearchModule'
      app : 
        app       : 'search'
        app_label : 'search'
        tab       : '#tpl-workspace-tab-search'
        query     : 'stuff'
        other     : 'stuff'
        params    : null        

    rulesets :
      module : 'TestModule'
      params : null

    default :
      module : 'TestModule'
      params : null









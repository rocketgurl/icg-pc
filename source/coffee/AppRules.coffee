define [
  'jquery', 
  'underscore'
], ($, _) ->

  # Sets up rules for which modules to load for a given app.
  # Also handles any additional modules which should accompany that app
  # such as a default search tab for all policies.
  class AppRules

    default_module : 'TestModule'

    constructor : (@app) ->
      if @app.params?
        @default_module = app.params.pcModule or 'TestModule'
        @check_rules(@app)
      else
        @default_module = @which_module(@app)
        console.log @default_module

    # Determine which module we should load for a given app type
    which_module : (app) ->
      if app.app?
        app_name = @get_app_name app.app
      else
        app_name = @default_module

      # Check the app_name against predetermined types
      # Could do this by convention ({App_name}Module)
      # or make it a tad more flexible this way.
      switch app_name
        when "policies"
          'SearchModule'
        when "rulesets"
          'Rulesets'
        else
          'TestModule'

    # Derive app name
    get_app_name : (app_name) ->
      if app_name.indexOf '_' >= 0
        app_name.split('_')[0]
      else
        app_name

    check_rules : (app) ->

    rules_parse : (app_name) ->








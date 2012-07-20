// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore'], function($, _) {
    var AppRules;
    return AppRules = (function() {

      AppRules.prototype.default_workspace = null;

      function AppRules(app) {
        var app_name;
        this.app = app;
        if (this.app.app != null) {
          app_name = this.get_app_name(this.app.app);
          this.default_workspace = this.get_modules(app_name);
        }
      }

      AppRules.prototype.get_app_name = function(app_name) {
        if (app_name.indexOf('_' >= 0)) {
          return app_name.split('_')[0];
        } else {
          return app_name;
        }
      };

      AppRules.prototype.get_modules = function(app_name) {
        switch (app_name) {
          case 'policies':
            return [this.policy_search];
          case 'rulesets':
            return [this.policy_search, this.add_app(this.rulesets)];
          default:
            return [this["default"]];
        }
      };

      AppRules.prototype.add_app = function(definition) {
        definition.app = this.app;
        if (definition.params != null) {
          definition.app.params = definition.params;
        }
        return definition;
      };

      AppRules.prototype.policy_search = {
        module: 'SearchModule',
        app: {
          app: 'search',
          app_label: 'search',
          query: 'stuff',
          other: 'stuff',
          params: null
        }
      };

      AppRules.prototype.rulesets = {
        module: 'TestModule',
        params: null
      };

      AppRules.prototype["default"] = {
        module: 'TestModule',
        params: null
      };

      return AppRules;

    })();
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseRouter', 'Helpers'], function(BaseRouter, Helpers) {
    var WorkspaceRouter;
    return WorkspaceRouter = BaseRouter.extend({
      routes: {
        'login': 'login',
        'logout': 'logout',
        'workspace/:env/:business/:context/:app/:module/*params': 'module',
        'workspace/:env/:business/:context/:app': 'workspace'
      },
      initialize: function(options) {},
      login: function() {
        return this.controller.trigger('login');
      },
      logout: function() {
        this.controller.trigger('logout');
        return this.navigate('login', {
          trigger: true
        });
      },
      module: function(env, business, context, app, module, params) {
        this.set_controller_state(env, business, context, app, module, params);
        if (this.controller.config != null) {
          params = Helpers.unserialize(params);
          return this.controller.launch_module(module, params);
        }
      },
      workspace: function(env, business, context, app) {
        this.set_controller_state(env, business, context, app);
        if (this.controller.config != null) {
          return this.controller.trigger('launch');
        }
      },
      set_controller_state: function(env, business, context, app, module, params) {
        this.controller.current_state = {
          'env': env,
          'business': business,
          'context': context,
          'app': app,
          'module': module != null ? module : null,
          'params': params != null ? params : null
        };
        return this.controller.set_nav_state();
      },
      build_path: function() {
        var app, business, context, env, _ref;
        _ref = this.controller.current_state, env = _ref.env, business = _ref.business, context = _ref.context, app = _ref.app;
        return this.navigate("workspace/" + env + "/" + business + "/" + context + "/" + app);
      },
      build_module_path: function(module, params) {
        var app, business, context, env, serialized, _ref, _ref1;
        _ref = [module, params], this.controller.current_state.module = _ref[0], this.controller.current_state.params = _ref[1];
        this.controller.set_nav_state();
        _ref1 = this.controller.current_state, env = _ref1.env, business = _ref1.business, context = _ref1.context, app = _ref1.app;
        serialized = Helpers.serialize(params);
        return "workspace/" + env + "/" + business + "/" + context + "/" + app + "/" + module + serialized;
      },
      append_module: function(module, params) {
        return this.navigate(this.build_module_path(module, params));
      },
      navigate_to_module: function(module, params) {
        return this.navigate(this.build_module_path(module, params), {
          trigger: true
        });
      },
      remove_module: function() {
        var app, business, context, env, _ref;
        _ref = this.controller.current_state, env = _ref.env, business = _ref.business, context = _ref.context, app = _ref.app;
        return this.navigate("workspace/" + env + "/" + business + "/" + context + "/" + app);
      }
    });
  });

}).call(this);

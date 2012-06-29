// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseRouter'], function(BaseRouter) {
    var WorkspaceRouter;
    return WorkspaceRouter = BaseRouter.extend({
      routes: {
        'login': 'login',
        'logout': 'logout',
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
      workspace: function(env, business, context, app) {
        this.controller.current_state = {
          'env': env,
          'business': business,
          'context': context,
          'app': app
        };
        if (this.controller.config != null) {
          return this.controller.trigger('launch');
        }
      }
    });
  });

}).call(this);

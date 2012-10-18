// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'mustache', 'modules/Policy/PolicyView', 'modules/Policy/PolicyModel', 'Messenger', 'loader'], function($, _, Backbone, Mustache, PolicyView, PolicyModel, Messenger, CanvasLoader) {
    var PolicyModule;
    return PolicyModule = (function() {

      PolicyModule.prototype.Amplify = amplify;

      function PolicyModule(view, app, params) {
        this.view = view;
        this.app = app;
        this.params = params;
        if (this.app.params != null) {
          this.params = this.app.params;
        }
        _.extend(this, Backbone.Events);
      }

      PolicyModule.prototype.load = function() {
        var digest, id,
          _this = this;
        if (this.params.id != null) {
          id = this.params.id;
        }
        if (this.params.url != null) {
          if (id == null) {
            id = this.params.url;
          }
        }
        this.policy_model = new PolicyModel({
          id: id,
          urlRoot: this.view.options.controller.services.pxcentral,
          digest: this.view.options.controller.user.get('digest')
        });
        this.policy_view = new PolicyView({
          view: this.view,
          module: this,
          model: this.policy_model
        });
        this.messenger = new Messenger(this.policy_view, this.policy_view.cid);
        digest = this.view.options.controller.user.get('digest');
        window.pol = this.policy_model;
        this.policy_model.fetch({
          headers: {
            'Authorization': "Basic " + digest,
            'X-Authorization': "Basic " + digest
          },
          success: function(model, resp) {
            model.response_state();
            switch (model.get('fetch_state').code) {
              case "200":
                model.get_pxServerIndex();
                return _this.render();
              default:
                _this.view.remove_loader();
                _this.render({
                  flash_only: true
                });
                return _this.Amplify.publish(_this.policy_view.cid, 'warning', "" + (model.get('fetch_state').text) + " - " + ($(resp).find('p').text()) + " Sorry.");
            }
          },
          error: function(model, resp) {
            var response;
            _this.render({
              flash_only: true
            });
            _this.view.remove_loader();
            if (resp.statusText === "error") {
              response = "There was a problem retrieving this policy.";
            } else {
              response = resp.responseText;
            }
            return _this.Amplify.publish(_this.policy_view.cid, 'warning', "" + response + " Sorry.");
          }
        });
        return this.on('activate', function() {
          return this.policy_view.trigger('activate');
        });
      };

      PolicyModule.prototype.render = function(options) {
        this.view.remove_loader(true);
        if (this.policy_view.render_state === false) {
          return this.policy_view.render(options);
        }
      };

      PolicyModule.prototype.callback_delay = function(ms, func) {
        return setTimeout(func, ms);
      };

      return PolicyModule;

    })();
  });

}).call(this);
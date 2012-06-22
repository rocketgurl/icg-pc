// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'UserModel', 'ConfigModel', 'WorkspaceLoginView', 'WorkspaceRouter', 'base64', 'MenuHelper', 'amplify_core', 'amplify_store', 'cookie'], function($, _, Backbone, UserModel, ConfigModel, WorkspaceLoginView, WorkspaceRouter, Base64, MenuHelper, amplify) {
    var $flash, WorkspaceController, ics360;
    window.ICS360_ENV = 'staging';
    amplify.subscribe('log', function(msg) {
      return console.log(msg);
    });
    $flash = $('#flash-message');
    amplify.subscribe('flash', function(type, msg) {
      if (type != null) {
        $flash.attr('class', type);
      }
      if (msg != null) {
        msg += ' <i class="icon-remove-sign"></i>';
        return $flash.html(msg).fadeIn('fast');
      }
    });
    $flash.on('click', 'i', function(event) {
      event.preventDefault();
      return $flash.fadeOut('fast');
    });
    ics360 = {
      services: {
        ixdirectory: './ixdirectory/api/rest/v2/',
        pxcentral: './pxcentral/api/rest/v1/',
        ixlibrary: './ixlibrary/api/sdo/rest/v1/',
        ixdoc: './ixdoc/api/rest/v2/',
        ixadmin: './config/ics/staging/ixadmin'
      }
    };
    WorkspaceController = {
      Amplify: amplify,
      $workspace_button: $('#button-workspace'),
      $workspace_breadcrumb: $('#breadcrump'),
      $workspace_admin: $('#header-admin'),
      $workspace_canvas: $('#canvas'),
      Router: new WorkspaceRouter(),
      COOKIE_NAME: 'ics360.PolicyCentral',
      logger: function(msg) {
        return this.Amplify.publish('log', msg);
      },
      flash: function(type, msg) {
        return this.Amplify.publish('flash', type, msg);
      },
      check_cookie_identity: function() {
        var cookie;
        if (cookie = $.cookie(this.COOKIE_NAME)) {
          cookie = Base64.decode(cookie).split(':');
          return this.check_credentials(cookie[0], cookie[1]);
        } else {
          return this.Router.navigate('login', {
            trigger: true
          });
        }
      },
      set_cookie_identity: function(digest) {
        return $.cookie(this.COOKIE_NAME, digest, {
          expires: 7
        });
      },
      build_login: function() {
        this.login_view = new WorkspaceLoginView({
          controller: this,
          el: '#target',
          template: $('#tpl-ics-login')
        });
        return this.login_view.render();
      },
      check_credentials: function(username, password) {
        var _this = this;
        this.user = new UserModel({
          urlRoot: ics360.services.ixdirectory + 'identities',
          'username': username,
          'password': password
        });
        return this.user.fetch({
          success: function(model, resp) {
            _this.user.response_state();
            switch (_this.user.get('fetch_state').code) {
              case "200":
                return _this.login_success(model, resp);
              default:
                return _this.login_fail(model, resp, _this.user.get('fetch_state'));
            }
          },
          error: function(model, resp) {
            return _this.response_fail(model, resp);
          }
        });
      },
      response_fail: function(model, resp) {
        return this.logger("PHALE!");
      },
      login_success: function(model, resp) {
        this.get_configs();
        this.user.parse_identity();
        this.set_cookie_identity(this.user.get('digest'));
        return this.flash('success', "HELLO THERE " + (this.user.get('name')));
      },
      login_fail: function(model, resp, state) {
        this.Router.navigate('login', {
          trigger: true
        });
        return this.flash('warning', "SOWWEE you no enter cause " + state.text);
      },
      logout: function() {
        $.cookie(this.COOKIE_NAME, null);
        return this.user = null;
      },
      get_configs: function() {
        var _this = this;
        this.config = new ConfigModel({
          urlRoot: ics360.services.ixadmin
        });
        return this.config.fetch({
          success: function(model, resp) {
            return MenuHelper.build_menu(_this.user.get('document'), model.get('document'));
          },
          error: function(model, resp) {
            return _this.flash('warning', "There was a problem retreiving the configuration file. Please contact support.");
          }
        });
      },
      init: function() {
        this.Router.controller = this;
        Backbone.history.start();
        return this.check_cookie_identity();
      }
    };
    _.extend(WorkspaceController, Backbone.Events);
    return WorkspaceController.on("log", function(msg) {
      return this.logger(msg);
    });
  });

}).call(this);

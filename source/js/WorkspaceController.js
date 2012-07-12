// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'UserModel', 'ConfigModel', 'WorkspaceStateModel', 'WorkspaceLoginView', 'WorkspaceCanvasView', 'WorkspaceNavView', 'WorkspaceRouter', 'base64', 'MenuHelper', 'amplify_core', 'amplify_store', 'cookie', 'xml2json'], function($, _, Backbone, UserModel, ConfigModel, WorkspaceStateModel, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter, Base64, MenuHelper, amplify) {
    var $flash, WorkspaceController, ics360,
      _this = this;
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
      $workspace_header: $('#header'),
      $workspace_button: $('#button-workspace'),
      $workspace_breadcrumb: $('#breadcrumb'),
      $workspace_admin: $('#header-admin'),
      $workspace_canvas: $('#canvas'),
      $workspace_tabs: $('#workspace nav ul'),
      Router: new WorkspaceRouter(),
      COOKIE_NAME: 'ics360.PolicyCentral',
      logger: function(msg) {
        return this.Amplify.publish('log', msg);
      },
      flash: function(type, msg) {
        return this.Amplify.publish('flash', type, msg);
      },
      workspace_stack: [],
      stack_add: function(view) {
        var exists;
        exists = _.find(this.workspace_stack, function(item) {
          return item.options.app === view.options.app;
        });
        if (!(exists != null)) {
          return this.workspace_stack.push(view);
        }
      },
      stack_remove: function(view) {
        var _this = this;
        return _.each(this.workspace_stack, function(obj, index) {
          if (view.app.app === obj.app.app) {
            return _this.workspace_stack.splice(index, 1);
          }
        });
      },
      stack_clear: function() {
        this.workspace_stack = [];
        return this.workspace_state.set('apps', []);
      },
      stack_get: function(app) {
        var index, obj, _ref;
        _ref = this.workspace_stack;
        for (index in _ref) {
          obj = _ref[index];
          if (app === obj.app.app) {
            return obj;
          }
        }
      },
      state_add: function(app) {
        var exists, saved_apps;
        if (app.app === this.current_state.app) {
          return;
        }
        saved_apps = this.workspace_state.get('apps');
        if (saved_apps != null) {
          exists = this.state_exists(app);
          if (!(exists != null)) {
            saved_apps.push(app);
          }
        } else {
          if (app.app !== this.current_state.app) {
            saved_apps = [app];
          }
        }
        this.workspace_state.set('apps', saved_apps);
        return this.workspace_state.save();
      },
      state_remove: function(app) {
        var saved_apps,
          _this = this;
        saved_apps = this.workspace_state.get('apps');
        _.each(saved_apps, function(obj, index) {
          if (app.app === obj.app) {
            return saved_apps.splice(index, 1);
          }
        });
        this.workspace_state.set('apps', saved_apps);
        return this.workspace_state.save();
      },
      state_exists: function(app) {
        var saved_apps,
          _this = this;
        saved_apps = this.workspace_state.get('apps');
        return _.find(saved_apps, function(saved) {
          return saved.app === app.app;
        });
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
          template: $('#tpl-ics-login'),
          template_tab: $('#tpl-workspace-tab').html(),
          tab_label: 'Login'
        });
        this.login_view.render();
        if (this.navigation_view != null) {
          return this.navigation_view.destroy();
        }
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
        this.flash('warning', "There was a problem retreiving the configuration file. Please contact support. Error: " + resp.status + " - " + resp.statusText);
        return this.logger("PHALE!");
      },
      login_success: function(model, resp) {
        this.get_configs();
        this.user.parse_identity();
        this.set_cookie_identity(this.user.get('digest'));
        this.set_admin_links();
        if (this.login_view != null) {
          return this.login_view.destroy();
        }
      },
      login_fail: function(model, resp, state) {
        this.Router.navigate('login', {
          trigger: true
        });
        return this.flash('warning', "SOWWEE you no enter cause " + state.text);
      },
      logout: function() {
        $.cookie(this.COOKIE_NAME, null);
        this.user = null;
        this.reset_admin_links();
        this.navigation_view.destroy();
        return this.teardown_workspace();
      },
      get_configs: function() {
        var _this = this;
        this.config = new ConfigModel({
          urlRoot: ics360.services.ixadmin
        });
        return this.config.fetch({
          success: function(model, resp) {
            _this.config.set('menu', MenuHelper.build_menu(_this.user.get('document'), model.get('document')));
            _this.config.set('menu_html', MenuHelper.generate_menu(_this.config.get('menu')));
            _this.navigation_view = new WorkspaceNavView({
              router: _this.Router,
              controller: _this,
              el: '#header-workspace-nav',
              sub_el: '#workspace-subnav',
              main_nav: _this.config.get('menu_html').main_nav,
              sub_nav: _this.config.get('menu_html').sub_nav
            });
            _this.navigation_view.render();
            _this.check_workspace_state();
            if (_this.current_state != null) {
              return _this.trigger('launch');
            }
          },
          error: function(model, resp) {
            return _this.flash('warning', "There was a problem retreiving the configuration file. Please contact support.");
          }
        });
      },
      callback_delay: function(ms, func) {
        return setTimeout(func, ms);
      },
      check_workspace_state: function() {
        var raw_id, raw_storage,
          _this = this;
        if (!_.isFunction(this.Amplify.store)) {
          this.check_workspace_state();
        }
        raw_storage = this.Amplify.store();
        if (raw_storage['ics_policy_central'] != null) {
          raw_storage = raw_storage['ics_policy_central'];
          raw_id = _.keys(raw_storage)[0];
          if (raw_id != null) {
            this.workspace_state = new WorkspaceStateModel({
              id: raw_id
            });
            return this.workspace_state.fetch({
              success: function(model, resp) {
                _this.current_state = model.get('workspace');
                return _this.Router.navigate("workspace/" + _this.current_state.env + "/" + _this.current_state.business + "/" + _this.current_state.context + "/" + _this.current_state.app);
              },
              error: function(model, resp) {
                _this.flash('notice', "We had an issue with your saved state. Not major, but we're starting from scratch.");
                return _this.workspace_state = new WorkspaceStateModel();
              }
            });
          }
        } else {
          return this.workspace_state = new WorkspaceStateModel();
        }
      },
      launch_workspace: function() {
        var app, apps, group_label, menu,
          _this = this;
        menu = this.config.get('menu');
        group_label = apps = menu[this.current_state.business].contexts[this.current_state.context].label;
        apps = menu[this.current_state.business].contexts[this.current_state.context].apps;
        app = _.find(apps, function(app) {
          return app.app === _this.current_state.app;
        });
        if (this.workspace_stack.length > 0) {
          this.teardown_workspace();
          this.launch_workspace();
        } else {
          this.launch_app(app);
          this.check_persisted_apps();
        }
        this.$workspace_breadcrumb.html("<li><em>" + this.current_state.business + "</em></li>\n<li><em>" + (MenuHelper.check_length(group_label)) + "</em></li>\n<li><em>" + app.app_label + "</em></li>");
        this.workspace_state.set('workspace', {
          env: this.current_state.env,
          business: this.current_state.business,
          context: this.current_state.context,
          app: this.current_state.app
        });
        return this.workspace_state.save();
      },
      launch_app: function(app) {
        var default_module;
        this.state_add(app);
        default_module = 'TestModule';
        if (app.params != null) {
          default_module = app.params.pcModule || 'TestModule';
        }
        return this.create_workspace(default_module, app);
      },
      create_workspace: function(module, app) {
        return new WorkspaceCanvasView({
          controller: this,
          module_type: module,
          'app': app
        });
      },
      check_persisted_apps: function() {
        var app, saved_apps, _i, _len, _results;
        saved_apps = this.workspace_state.get('apps');
        if (saved_apps != null) {
          _results = [];
          for (_i = 0, _len = saved_apps.length; _i < _len; _i++) {
            app = saved_apps[_i];
            console.log(app);
            _results.push(this.launch_app(app));
          }
          return _results;
        }
      },
      set_admin_links: function() {
        if (!(this.$workspace_admin_initial != null)) {
          this.$workspace_admin_initial = this.$workspace_admin.find('ul').html();
        }
        return this.$workspace_admin.find('ul').html("<li>Welcome back &nbsp;<a href=\"#profile\">" + (this.user.get('name')) + "</a></li>\n<li><a href=\"#logout\">Logout</a></li>");
      },
      reset_admin_links: function() {
        return this.$workspace_admin.find('ul').html(this.$workspace_admin_initial);
      },
      attach_tab_handlers: function() {
        var _this = this;
        this.$workspace_tabs.on('click', 'li a', function(e) {
          var app_name;
          e.preventDefault();
          app_name = $(e.target).attr('href');
          return _this.toggle_apps(app_name);
        });
        return this.$workspace_tabs.on('click', 'li i', function(e) {
          e.preventDefault();
          _this.stack_get($(e.target).prev().attr('href')).destroy();
          return _this.reassess_apps();
        });
      },
      toggle_apps: function(app_name) {
        var view, _i, _len, _ref, _results;
        _ref = this.workspace_stack;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          if (app_name === view.app.app) {
            _results.push(view.activate());
          } else {
            _results.push(view.deactivate());
          }
        }
        return _results;
      },
      reassess_apps: function() {
        var active, last_view;
        if (this.workspace_stack.length === 0) {
          return false;
        }
        active = _.filter(this.workspace_stack, function(view) {
          return view.is_active();
        });
        if (active.length === 0) {
          last_view = _.last(this.workspace_stack);
          return this.toggle_apps(last_view.app.app);
        }
      },
      teardown_workspace: function() {
        var _this = this;
        return _.each(this.workspace_stack, function(view, index) {
          return view.destroy();
        });
      },
      init: function() {
        this.Router.controller = this;
        Backbone.history.start();
        this.check_cookie_identity();
        return this.attach_tab_handlers();
      }
    };
    _.extend(WorkspaceController, Backbone.Events);
    WorkspaceController.on("log", function(msg) {
      return this.logger(msg);
    });
    WorkspaceController.on("login", function() {
      return this.build_login();
    });
    WorkspaceController.on("logout", function() {
      return this.logout();
    });
    WorkspaceController.on("launch", function() {
      return this.launch_workspace();
    });
    WorkspaceController.on("stack_add", function(view) {
      return this.stack_add(view);
    });
    WorkspaceController.on("stack_remove", function(view) {
      this.stack_remove(view);
      return this.state_remove(view.app);
    });
    return WorkspaceController.on("new_tab", function(app_name) {
      return this.toggle_apps(app_name);
    });
  });

}).call(this);

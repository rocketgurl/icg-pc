// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'json', 'UserModel', 'ConfigModel', 'WorkspaceStateModel', 'WorkspaceLoginView', 'WorkspaceCanvasView', 'WorkspaceNavView', 'WorkspaceRouter', 'Messenger', 'base64', 'MenuHelper', 'AppRules', 'Helpers', 'amplify', 'cookie', 'xml2json', 'modules/SearchContextCollection'], function($, _, Backbone, JSON, UserModel, ConfigModel, WorkspaceStateModel, WorkspaceLoginView, WorkspaceCanvasView, WorkspaceNavView, WorkspaceRouter, Messenger, Base64, MenuHelper, AppRules, Helpers, amplify, jcookie, xml2json, SearchContextCollection) {
    var WorkspaceController, ics360,
      _this = this;
    window.ICS360_ENV = 'staging';
    amplify.subscribe('log', function(msg) {
      return console.log(msg);
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
      services: ics360.services,
      global_flash: new Messenger($('#canvas'), 'controller'),
      SEARCH: {},
      logger: function(msg) {
        return this.Amplify.publish('log', msg);
      },
      flash: function(type, msg) {
        return this.Amplify.publish(this.login_view.cid, type, msg);
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
            _this.workspace_stack.splice(index, 1);
            if (view.app.params != null) {
              _this.current_state.params = null;
              _this.set_nav_state();
              return _this.update_address();
            }
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
          return false;
        }
        saved_apps = this.workspace_state.get('apps');
        if (saved_apps != null) {
          exists = this.state_exists(app);
          if (!(exists != null)) {
            saved_apps.push(app);
          } else {
            return false;
          }
        } else {
          if (app.app !== this.current_state.app) {
            saved_apps = [app];
          }
        }
        this.workspace_state.set('apps', saved_apps);
        this.workspace_state.save();
        return true;
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
      set_nav_state: function() {
        var _ref, _ref1;
        if ((this.current_state != null) && (this.workspace_state != null)) {
          this.workspace_state.set('workspace', {
            env: this.current_state.env,
            business: this.current_state.business,
            context: this.current_state.context,
            app: this.current_state.app,
            module: (_ref = this.current_state.module) != null ? _ref : null,
            params: (_ref1 = this.current_state.params) != null ? _ref1 : null
          });
          return this.workspace_state.save();
        }
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
        var login_flash;
        this.login_view = new WorkspaceLoginView({
          controller: this,
          template: $('#tpl-ics-login'),
          template_tab: $('#tpl-workspace-tab').html(),
          tab_label: 'Login'
        });
        this.login_view.render();
        login_flash = new Messenger(this.login_view, this.login_view.cid);
        if (this.navigation_view != null) {
          this.navigation_view.destroy();
        }
        return $('#header').css('height', '65px');
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
        this.Amplify.publish(this.login_view.cid, 'warning', "Sorry, your password or username was incorrect");
        return this.logger("PHALE!");
      },
      login_success: function(model, resp) {
        this.get_configs();
        this.user.parse_identity();
        this.set_cookie_identity(this.user.get('digest'));
        this.set_admin_links();
        this.show_workspace_button();
        if (this.login_view != null) {
          return this.login_view.destroy();
        }
      },
      login_fail: function(model, resp, state) {
        this.Router.navigate('login', {
          trigger: true
        });
        return this.Amplify.publish(this.login_view.cid, 'warning', "SOWWEE you no enter cause " + state.text);
      },
      logout: function() {
        $.cookie(this.COOKIE_NAME, null);
        this.user = null;
        this.reset_admin_links();
        this.set_breadcrumb();
        this.hide_workspace_button();
        if (this.navigation_view != null) {
          this.navigation_view.destroy();
          return this.teardown_workspace();
        }
      },
      get_configs: function() {
        var _this = this;
        this.config = new ConfigModel({
          urlRoot: ics360.services.ixadmin
        });
        return this.config.fetch({
          success: function(model, resp) {
            var menu;
            menu = MenuHelper.build_menu(_this.user.get('document'), model.get('document'));
            if (menu === false) {
              _this.Amplify.publish('controller', 'warning', "Sorry, you do not have access to any items in this environment.");
            } else {
              _this.config.set('menu', menu);
              _this.config.set('menu_html', MenuHelper.generate_menu(menu));
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
            }
          },
          error: function(model, resp) {
            return _this.Amplify.publish('controller', 'warning', "There was a problem retreiving the configuration file. Please contact support.");
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
        this.SEARCH.saved_searches = new SearchContextCollection();
        this.SEARCH.saved_searches.controller = this;
        this.SEARCH.saved_searches.fetch();
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
                return _this.update_address();
              },
              error: function(model, resp) {
                _this.Amplify.publish('controller', 'notice', "We had an issue with your saved state. Not major, but we're starting from scratch.");
                return _this.workspace_state = new WorkspaceStateModel();
              }
            });
          }
        } else {
          return this.workspace_state = new WorkspaceStateModel();
        }
      },
      is_loggedin: function() {
        if (!(this.user != null)) {
          this.Amplify.publish('controller', 'notice', "Please login to Policy Central to continue.");
          this.build_login();
          return false;
        }
        return true;
      },
      launch_workspace: function() {
        var app, apps, data, group_label, menu,
          _this = this;
        if (this.is_loggedin === false) {
          return;
        }
        menu = this.config.get('menu');
        if (menu === false) {
          this.Amplify.publish('controller', 'warning', "Sorry, you do not have access to any items in this environment.");
          return;
        }
        group_label = apps = menu[this.current_state.business].contexts[this.current_state.context].label;
        apps = menu[this.current_state.business].contexts[this.current_state.context].apps;
        app = _.find(apps, function(app) {
          return app.app === _this.current_state.app;
        });
        if (this.workspace_stack.length > 0) {
          this.teardown_workspace();
          this.launch_workspace();
        } else {
          if ($('#header').height() < 95) {
            $('#header').css('height', '95px');
          }
          this.launch_app(app);
          if (this.check_persisted_apps()) {
            if (this.current_state.module != null) {
              this.launch_module(this.current_state.module, this.current_state.params);
            }
          }
        }
        data = {
          business: this.current_state.business,
          group: MenuHelper.check_length(group_label),
          'app': app.app_label
        };
        this.set_breadcrumb(data);
        return this.set_nav_state();
      },
      set_breadcrumb: function(data) {
        if (data != null) {
          return this.$workspace_breadcrumb.html("<li><em>" + data.business + "</em></li>\n<li><em>" + data.group + "</em></li>\n<li><em>" + data.app + "</em></li>");
        } else {
          return this.$workspace_breadcrumb.html('');
        }
      },
      launch_app: function(app) {
        var default_workspace, rules, workspace, _i, _len, _results;
        this.state_add(app);
        rules = new AppRules(app);
        default_workspace = rules.default_workspace;
        _results = [];
        for (_i = 0, _len = default_workspace.length; _i < _len; _i++) {
          workspace = default_workspace[_i];
          _results.push(this.create_workspace(workspace.module, workspace.app));
        }
        return _results;
      },
      launch_module: function(module, params) {
        var app, safe_app_name, stack_check;
        if (params == null) {
          params = {};
        }
        safe_app_name = "" + (Helpers.id_safe(module));
        if (params.url != null) {
          safe_app_name += "_" + (Helpers.id_safe(params.url));
        }
        app = {
          app: safe_app_name,
          app_label: "" + (Helpers.uc_first(module)) + ": " + params.url,
          params: params
        };
        app.app.params = params;
        stack_check = this.stack_get(safe_app_name);
        if (!(stack_check != null)) {
          return this.launch_app(app);
        } else {
          return this.toggle_apps(safe_app_name);
        }
      },
      create_workspace: function(module, app) {
        var options;
        options = {
          controller: this,
          module_type: module,
          'app': app
        };
        if (app.tab != null) {
          options.template_tab = $(app.tab).html();
        }
        return new WorkspaceCanvasView(options);
      },
      check_persisted_apps: function() {
        var app, saved_apps, _i, _len;
        saved_apps = this.workspace_state.get('apps');
        if (saved_apps != null) {
          for (_i = 0, _len = saved_apps.length; _i < _len; _i++) {
            app = saved_apps[_i];
            this.launch_app(app);
          }
        }
        return true;
      },
      update_address: function() {
        var url;
        if (this.current_state != null) {
          url = "workspace/" + this.current_state.env + "/" + this.current_state.business + "/" + this.current_state.context + "/" + this.current_state.app;
          if ((this.current_state.params != null) && (this.current_state.module != null)) {
            url += "/" + this.current_state.module + "/" + (Helpers.serialize(this.current_state.params));
          }
          return this.Router.navigate(url);
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
      show_workspace_button: function() {
        this.$workspace_button.fadeIn(400);
        $('#header-controls span').fadeIn(400);
        return this.$workspace_breadcrumb.fadeIn(400);
      },
      hide_workspace_button: function() {
        this.$workspace_button.fadeOut(400);
        $('#header-controls span').fadeOut(400);
        return this.$workspace_breadcrumb.fadeOut(400);
      },
      attach_tab_handlers: function() {
        var _this = this;
        this.$workspace_tabs.on('click', 'li a', function(e) {
          var app_name;
          e.preventDefault();
          app_name = $(e.target).attr('href');
          _this.set_active_url(app_name);
          if (app_name === void 0) {
            app_name = $(e.target).parent().attr('href');
          }
          return _this.toggle_apps(app_name);
        });
        return this.$workspace_tabs.on('click', 'li i.icon-remove-sign', function(e) {
          e.preventDefault();
          _this.stack_get($(e.target).prev().attr('href')).destroy();
          return _this.reassess_apps();
        });
      },
      set_active_url: function(app_name) {
        var module, module_name, view, _i, _len, _ref, _results;
        _ref = this.workspace_stack;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          view = _ref[_i];
          if (app_name === view.app.app) {
            module = view.module;
            if ((module.app != null) && (module.app.params != null)) {
              module_name = new AppRules(module.app).app_name;
              this.Router.append_module(module_name, module.app.params);
            } else {
              this.Router.remove_module();
            }
          }
          if (app_name === void 0) {
            _results.push(this.Router.remove_module());
          } else {
            _results.push(void 0);
          }
        }
        return _results;
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
        this.set_breadcrumb();
        _.each(this.workspace_stack, function(view, index) {
          return view.destroy();
        });
        if (this.workspace_stack.length > 0) {
          this.workspace_stack = [];
          this.$workspace_tabs.html('');
          return $('#target').empty();
        }
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
    WorkspaceController.on("search", function(module, params) {
      return this.launch_module(module, params);
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

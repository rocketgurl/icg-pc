// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'mustache', 'Helpers', 'text!templates/tpl_module_loader.html'], function(BaseView, Mustache, Helpers, tpl_module_loader) {
    var WorkspaceCanvasView;
    return WorkspaceCanvasView = BaseView.extend({
      $target: $('#target'),
      $flash_tpl: $('#tpl-flash-message').html(),
      tagName: 'section',
      className: 'workspace-canvas',
      tab: null,
      initialize: function(options) {
        var _ref,
          _this = this;
        this.$tab_el = options.controller.$workspace_tabs;
        if (options.template != null) {
          this.template = options.template;
        }
        this.template_tab = options.template_tab != null ? options.template_tab : $('#tpl-workspace-tab').html();
        this.params = (_ref = options.params) != null ? _ref : null;
        this.reactivate = false;
        if (!(options.app != null)) {
          return this.Amplify.publish('flash', 'warning', 'There was a problem locating that workspace.');
        }
        this.app = options.app;
        this.el.id = this.app.app;
        this.options.controller.trigger('stack_add', this);
        require(["modules/" + this.options.module_type], function(Module) {
          _this.module = new Module(_this, _this.app);
          _this.module.on('workspace.rendered', function() {
            return _this.positionFooter();
          });
          if (_.has(Module.prototype, 'load')) {
            return _this.module.load();
          }
        });
        return this.render();
      },
      render: function() {
        this.$el.html(Mustache.render(tpl_module_loader, {
          module_name: this.app.app_label,
          app: this.app.app
        }));
        this.options.controller.workspace_zindex++;
        this.$el.css({
          'visibility': 'hidden',
          'zIndex': this.options.controller.workspace_zindex
        });
        this.$target.append(this.$el);
        this.render_tab(this.template_tab);
        this.loader = Helpers.loader("loader-" + this.app.app, 60, '#696969');
        this.loader.setFPS(48);
        return this.options.controller.trigger('new_tab', this.app.app);
      },
      render_tab: function(template) {
        this.tab = $(Mustache.render(template, {
          tab_class: '',
          tab_url: Helpers.id_safe(decodeURI(this.el.id)),
          tab_label: this.app.app_label
        }));
        return this.$tab_el.append(this.tab);
      },
      activate: function() {
        this.tab.addClass('selected');
        this.$el.css('visibility', 'visible');
        this.positionFooter();
        if (this.module) {
          return this.module.trigger('activate');
        }
      },
      deactivate: function() {
        this.tab.removeClass('selected');
        this.$el.css('visibility', 'hidden');
        if (this.module) {
          return this.module.trigger('deactivate');
        }
      },
      is_active: function() {
        return this.tab.hasClass('selected');
      },
      destroy: function() {
        if (this.$tab_el != null) {
          this.tab.remove();
          this.tab = null;
          this.$tab_el.find("li a[href=" + this.app.app + "]").parent().remove();
          this.$tab_el = null;
        }
        this.$el.html('').remove();
        return this.options.controller.trigger('stack_remove', this);
      },
      remove_loader: function(render) {
        var _this = this;
        return this.$el.find('.module-loader').fadeOut('fast', function() {
          if (render != null) {
            return _this.module.render();
          }
        });
      },
      launch_child_app: function(module, app) {
        this.options.controller.Router.append_module(module, app.params.url);
        return this.options.controller.launch_module(module, app);
      },
      positionFooter: function() {
        return $('#footer-main').css({
          'marginTop': this.$el.height() + 20
        });
      }
    });
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'mustache'], function(BaseView, Mustache) {
    var WorkspaceCanvasView;
    return WorkspaceCanvasView = BaseView.extend({
      $target: $('#target'),
      tagName: 'section',
      className: 'canvas',
      tab: null,
      initialize: function(options) {
        this.$tab_el = options.controller.$workspace_tabs;
        if (options.template != null) {
          this.template = options.template;
        }
        this.template_tab = options.template_tab != null ? options.template_tab : $('#tpl-workspace-tab').html();
        if (!(options.app != null)) {
          return this.Amplify.publish('flash', 'warning', 'There was a problem locating that workspace.');
        }
        this.app = options.app;
        this.el.id = this.app.app;
        this.options.controller.trigger('stack_add', this);
        return this.render();
      },
      render: function() {
        var _this = this;
        require(['modules/TestModule'], function(TestModule) {
          return TestModule.init(_this.$el);
        });
        this.$target.append(this.$el);
        return this.render_tab(this.template_tab);
      },
      render_tab: function(template) {
        this.tab = Mustache.render(template, {
          tab_class: ' class="selected"',
          tab_url: this.el.id,
          tab_label: this.app.app_label
        });
        return this.$tab_el.append(this.tab);
      },
      destroy: function() {
        if (this.$tab_el != null) {
          delete this.tab;
          this.$tab_el.find("li a[href=" + this.app.app + "]").parent().remove();
        }
        this.$el.html('');
        this.options.controller.trigger('stack_remove', this);
        return delete this;
      }
    });
  });

}).call(this);
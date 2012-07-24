// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'text!templates/tpl_search_policy_row.html'], function(BaseView, tpl_search_policy_row) {
    var SearchPolicyView;
    return SearchPolicyView = BaseView.extend({
      tagName: 'tr',
      events: {
        "click": "open_policy"
      },
      initialize: function(options) {
        this.data = options.model.attributes;
        this.parent = options.container.$el;
        this.target = this.parent.find('table.module-search tbody');
        this.module = options.model.collection.container.module;
        return this.render();
      },
      render: function() {
        this.$el.attr({
          id: this.data.id
        });
        this.$el.html(this.Mustache.render(tpl_search_policy_row, this.data));
        return this.target.append(this.$el);
      },
      destroy: function() {
        this.$el.remove();
        this.model = null;
        return this.el = null;
      },
      open_policy: function(e) {
        var $el, app, identifiers;
        e.preventDefault();
        $el = $(e.currentTarget);
        identifiers = this.model.get('identifiers');
        app = {
          app: 'policyview',
          app_label: identifiers.QuoteNumber,
          params: {
            id: $el.attr('id')
          }
        };
        return this.module.view.launch_child_app(app);
      }
    });
  });

}).call(this);

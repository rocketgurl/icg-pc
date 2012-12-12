// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'Messenger', 'text!modules/Search/templates/tpl_search_menu_views_row.html', 'Helpers'], function(BaseView, Messenger, tpl_search_menu_views_row, Helpers) {
    var SearchContextView;
    return SearchContextView = BaseView.extend({
      tagName: 'tr',
      events: {
        "click .search-views-row > a": "launch_search",
        "click .admin-icon-trash": "destroy"
      },
      initialize: function(options) {
        this.parent = options.parent;
        this.target = this.parent.find('table tbody');
        this.data = options.data;
        return this.render();
      },
      render: function() {
        this.$el.append(this.Mustache.render(tpl_search_menu_views_row, this.data));
        return this.target.append(this.$el);
      },
      launch_search: function(e) {
        var params;
        e.preventDefault();
        params = Helpers.unserialize($(e.currentTarget).attr('href'));
        this.options.controller.launch_module('search', params);
        return this.options.controller.Router.append_module('search', params);
      },
      destroy: function(e) {
        var id;
        e.preventDefault();
        id = $(e.currentTarget).attr('href').substr(7);
        this.options.collection.destroy(id);
        return this.$el.fadeOut('fast', function(id) {
          return $('.row-' + id).html('').remove();
        });
      }
    });
  });

}).call(this);

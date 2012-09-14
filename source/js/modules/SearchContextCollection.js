// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseCollection', 'modules/SearchContextModel', 'modules/SearchContextView', 'base64', 'Store', 'LocalStorageSync', 'Helpers'], function(BaseCollection, SearchContextModel, SearchContextView, Base64, Store, LocalStorageSync, Helpers) {
    var SearchContextCollection;
    return SearchContextCollection = BaseCollection.extend({
      model: SearchContextModel,
      views: [],
      localStorage: new Store('ics_saved_searches'),
      sync: LocalStorageSync,
      rendered: false,
      initialize: function() {
        this.bind('add', this.add_one, this);
        return this.bind('reset', this.add_many, this);
      },
      add_one: function(model) {
        return this.render(model);
      },
      add_many: function(collection) {
        var _this = this;
        return collection.each(function(model) {
          return _this.render(model);
        });
      },
      render: function(model, parent) {
        var data;
        this.parent = parent || $('.search-menu-context');
        data = model.attributes;
        if (_.isObject(data.params)) {
          data.params = Helpers.serialize(data.params);
        }
        return model.view = new SearchContextView({
          parent: this.parent,
          data: data,
          controller: this.controller,
          collection: this
        });
      },
      populate: function(html) {
        var _this = this;
        return this.each(function(model) {
          return _this.render(model, html);
        });
      },
      destroy: function(id) {
        var model;
        model = this.get(id);
        if (model.destroy()) {
          return this.remove(model);
        }
      }
    });
  });

}).call(this);

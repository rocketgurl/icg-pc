// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'amplify'], function($, _, amplify) {
    var Store;
    Store = function(name) {
      var store;
      this.name = name;
      store = amplify.store(this.name);
      this.data = store || {};
      return this;
    };
    _.extend(Store.prototype, {
      s4: function() {
        return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1);
      },
      guid: function() {
        return this.s4() + this.s4() + "-" + this.s4() + "-" + this.s4() + "-" + this.s4() + "-" + this.s4() + this.s4() + this.s4();
      },
      save: function() {
        return amplify.store(this.name, this.data);
      },
      create: function(model) {
        if (!model.id) {
          model.set(model.idAttribute, this.guid());
        }
        this.data[model.id] = model;
        this.save();
        return model;
      },
      update: function(model) {
        this.data[model.id] = model;
        this.save();
        return model;
      },
      find: function(model) {
        return this.data[model.id];
      },
      findAll: function() {
        return _.values(this.data);
      },
      destroy: function(model) {
        delete this.data[model.id];
        this.save();
        return model;
      }
    });
    return Store;
  });

}).call(this);

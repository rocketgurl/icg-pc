// Generated by CoffeeScript 1.4.0
(function() {

  define(['jquery', 'underscore', 'backbone', 'mustache', 'amplify', 'Helpers', 'ModalHelper'], function($, _, Backbone, Mustache, amplify, Helpers, ModalHelper) {
    var BaseView;
    return BaseView = Backbone.View.extend({
      extend: function(obj, mixin) {
        var method, name, _results;
        _results = [];
        for (name in mixin) {
          method = mixin[name];
          _results.push(obj[name] = method);
        }
        return _results;
      },
      include: function(klass, mixin) {
        return this.extend(klass.prototype, mixin);
      },
      Amplify: amplify,
      Mustache: Mustache,
      Helpers: Helpers,
      Modal: new ModalHelper(),
      logger: function(msg) {
        return this.Amplify.publish('log', msg);
      },
      dispose: function() {
        if (Backbone.View.dispose != null) {
          return Backbone.View.dispose;
        } else {
          this.undelegateEvents();
          if (this.model && this.model.off) {
            this.model.off(null, null, this);
          }
          if (this.collection && this.collection.off) {
            this.collection.off(null, null, this);
          }
          return this;
        }
      }
    });
  });

}).call(this);

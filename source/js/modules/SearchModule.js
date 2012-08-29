// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'mustache', 'modules/SearchView', 'loader'], function($, _, Backbone, Mustache, SearchView, CanvasLoader) {
    var SearchModule;
    return SearchModule = (function() {

      function SearchModule(view, app, params) {
        this.view = view;
        this.app = app;
        this.params = params;
        console.log(this.app);
        this.load();
      }

      SearchModule.prototype.load = function() {
        var _this = this;
        return this.callback_delay(500, function() {
          return _this.view.remove_loader(true);
        });
      };

      SearchModule.prototype.render = function() {
        this.search_view = new SearchView({
          view: this.view,
          module: this
        });
        return this.search_view.render();
      };

      SearchModule.prototype.callback_delay = function(ms, func) {
        return setTimeout(func, ms);
      };

      return SearchModule;

    })();
  });

}).call(this);

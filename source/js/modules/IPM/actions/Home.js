// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['modules/IPM/IPMActionView', 'text!modules/IPM/templates/tpl_home_action.html'], function(IPMActionView, tpl_home_action) {
    var HomeAction;
    return HomeAction = (function(_super) {

      __extends(HomeAction, _super);

      function HomeAction() {
        return HomeAction.__super__.constructor.apply(this, arguments);
      }

      HomeAction.prototype.events = {
        "click .ipm-home-action-view a": "dispatch"
      };

      HomeAction.prototype.initialize = function() {
        return HomeAction.__super__.initialize.apply(this, arguments);
      };

      HomeAction.prototype.dispatch = function(e) {
        var view;
        e.preventDefault();
        view = $(e.currentTarget).attr('href');
        return this.MODULE.VIEW.route(view);
      };

      HomeAction.prototype.render = function() {
        var actions;
        actions = this.MODULE.CONFIG.ACTIONS;
        return this.MODULE.VIEW.Mustache.render(tpl_home_action, this.MODULE.CONFIG);
      };

      return HomeAction;

    })(IPMActionView);
  });

}).call(this);

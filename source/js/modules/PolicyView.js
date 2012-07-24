// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'text!templates/tpl_policy_container.html'], function(BaseView, Messenger, tpl_policy_container) {
    var PolicyView;
    return PolicyView = BaseView.extend({
      initialize: function(options) {
        this.el = options.view.el;
        this.$el = options.view.$el;
        return this.controller = options.view.options.controller;
      },
      render: function() {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        html += this.Mustache.render(tpl_policy_container, {
          cid: this.cid
        });
        this.$el.html(html);
        return this.messenger = new Messenger(this.options.view, this.cid);
      }
    });
  });

}).call(this);

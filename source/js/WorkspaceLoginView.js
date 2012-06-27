// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView'], function(BaseView) {
    var WorkspaceLoginView;
    return WorkspaceLoginView = BaseView.extend({
      el: '#target',
      tab: null,
      events: {
        "submit form": "get_credentials"
      },
      initialize: function(options) {
        if (options.template != null) {
          return this.template = options.template;
        }
      },
      render: function() {
        return this.$el.html(this.template.html());
      },
      destroy: function() {
        return this.$el.html('');
      },
      get_credentials: function(event) {
        var password, username;
        event.preventDefault();
        username = this.$el.find('input:text').val();
        password = this.$el.find('input:password').val();
        return this.options.controller.check_credentials(username, password);
      }
    });
  });

}).call(this);

// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'Messenger', 'text!templates/tpl_login.html'], function(BaseView, Messenger, tpl_login) {
    var WorkspaceLoginView;
    return WorkspaceLoginView = BaseView.extend({
      el: '#login-container',
      tab: null,
      events: {
        "submit #form-login form": "get_credentials"
      },
      render: function() {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        html += this.Mustache.render(tpl_login, {
          cid: this.cid
        });
        this.$el.html(html);
        return this.messenger = new Messenger(this, this.cid);
      },
      displayMessage: function(type, msg, timeout) {
        return this.Amplify.publish(this.cid, type, msg);
      },
      destroy: function() {
        this.removeLoader();
        this.$el.find('#form-login').remove();
        return this.off();
      },
      get_credentials: function(event) {
        var password, username;
        event.preventDefault();
        this.displayLoader();
        username = this.$el.find('input:text').val();
        password = this.$el.find('input:password').val();
        if (username === null || username === '') {
          this.removeLoader();
          this.displayMessage('warning', "Sorry, your password or username was incorrect");
          return false;
        }
        if (password === null || password === '') {
          this.removeLoader();
          this.displayMessage('warning', "Sorry, your password or username was incorrect");
          return false;
        }
        return this.options.controller.check_credentials(username, password);
      },
      displayLoader: function() {
        if ($('#canvasLoader').length < 1) {
          this.loader = this.Helpers.loader("search-spinner-" + this.cid, 100, '#ffffff');
          this.loader.setDensity(70);
          this.loader.setFPS(48);
          return $("#search-loader-" + this.cid).show();
        }
      },
      removeLoader: function() {
        if (this.loader != null) {
          this.loader.kill();
        }
        this.loader = null;
        $('#canvasLoader').remove();
        return $("#search-loader-" + this.cid).hide();
      }
    });
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'text!templates/tpl_policy_container.html', 'text!templates/tpl_ipm_header.html'], function(BaseView, Messenger, tpl_policy_container, tpl_ipm_header) {
    var PolicyView;
    PolicyView = BaseView.extend({
      events: {
        "click .policy-nav a": "dispatch"
      },
      initialize: function(options) {
        this.el = options.view.el;
        this.$el = options.view.$el;
        return this.controller = options.view.options.controller;
      },
      render: function(options) {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        if (!(options != null)) {
          html += this.Mustache.render(tpl_policy_container, {
            auth_digest: this.model.get('digest'),
            policy_id: this.model.get('pxServerIndex'),
            cid: this.cid
          });
        }
        this.$el.html(html);
        this.iframe_id = "#policy-iframe-" + this.cid;
        this.iframe = this.$el.find(this.iframe_id);
        this.policy_header = this.$el.find("#policy-header-" + this.cid);
        this.policy_nav_links = this.$el.find("#policy-nav-" + this.cid + " a");
        this.messenger = new Messenger(this.options.view, this.cid);
        return this.show_overview();
      },
      toggle_nav_state: function(el) {
        this.policy_nav_links.removeClass('select');
        return el.addClass('select');
      },
      dispatch: function(e) {
        var $e, func;
        e.preventDefault();
        $e = $(e.currentTarget);
        this.toggle_nav_state($e);
        func = this["show_" + ($e.attr('href'))];
        if (_.isFunction(func)) {
          return func.apply(this);
        }
      },
      resize_iframe: function(iframe, offset) {
        var iframe_height;
        offset = offset || 0;
        iframe_height = Math.floor((($(window).height() - (220 + offset)) / $(window).height()) * 100) + "%";
        return this.iframe.css('min-height', iframe_height);
      },
      show_overview: function() {
        this.iframe.attr('src', 'http://fc06.deviantart.net/fs46/f/2009/169/f/4/Unicorn_Pukes_Rainbow_by_Angel35W.jpg');
        return this.resize_iframe(this.iframe);
      },
      show_ipmchanges: function() {
        var header;
        header = this.Mustache.render(tpl_ipm_header, this.model.get_ipm_header());
        this.policy_header.html(header);
        this.iframe.attr('src', '/mxadmin/index.html');
        return this.resize_iframe(this.iframe, this.policy_header.height());
      }
    });
    return PolicyView;
  });

}).call(this);

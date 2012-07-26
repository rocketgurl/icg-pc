// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'text!templates/tpl_policy_container.html', 'text!templates/tpl_ipm_header.html'], function(BaseView, Messenger, tpl_policy_container, tpl_ipm_header) {
    var PolicyView;
    PolicyView = BaseView.extend({
      events: {
        "click #policy-nav a": "dispatch"
      },
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
          auth_digest: this.model.get('digest'),
          policy_id: this.model.get('pxServerIndex')
        });
        this.$el.html(html);
        return this.messenger = new Messenger(this.options.view, this.cid);
      },
      toggle_nav_state: function(el) {
        $('#policy-nav a').removeClass('select');
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
      show_overview: function() {
        return this.Amplify.publish(this.cid, 'success', 'You be overviewin!');
      },
      show_ipmchanges: function() {
        var header, iframe, iframe_height;
        header = this.Mustache.render(tpl_ipm_header, this.model.get_ipm_header());
        $('#policy-header').html(header);
        iframe = this.$el.find('#policy-iframe');
        iframe.attr('src', '/mxadmin/index.html');
        iframe_height = Math.floor((($(window).height() - (220 + $('#policy-header').height())) / $(window).height()) * 100) + "%";
        return iframe.css('min-height', iframe_height);
      }
    });
    return PolicyView;
  });

}).call(this);

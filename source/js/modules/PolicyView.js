// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'base64', 'text!templates/tpl_policy_container.html', 'text!templates/tpl_ipm_header.html', 'swfobject'], function(BaseView, Messenger, Base64, tpl_policy_container, tpl_ipm_header, swfobject) {
    var PolicyView;
    PolicyView = BaseView.extend({
      events: {
        "click .policy-nav a": "dispatch"
      },
      initialize: function(options) {
        var _this = this;
        this.el = options.view.el;
        this.$el = options.view.$el;
        this.controller = options.view.options.controller;
        return window.policyViewInitSWF = function() {
          return _this.initialize_swf();
        };
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
        this.policy_summary = this.$el.find("#policy-summary-" + this.cid);
        this.messenger = new Messenger(this.options.view, this.cid);
        console.log('render');
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
      resize_element: function(el, offset) {
        var el_height;
        offset = offset || 0;
        el_height = Math.floor((($(window).height() - (220 + offset)) / $(window).height()) * 100) + "%";
        return el.css({
          'min-height': el_height,
          'height': $(window).height() - (220 + offset)
        });
      },
      show_overview: function() {
        this.policy_header.hide();
        this.iframe.hide();
        this.resize_element(this.policy_summary);
        if (this.$el.find("#policy-summary-" + this.cid).length === 0) {
          this.$el.find("#policy-header-" + this.cid).after(this.policy_summary);
        }
        if (this.$el.find("#policy-summary-" + this.cid).length > 0) {
          this.policy_summary.show();
          return swfobject.embedSWF("../swf/PolicySummary.swf", "policy-summary-" + this.cid, "100%", this.policy_summary.height(), "9.0.0", null, null, {
            allowScriptAccess: 'always'
          });
        }
      },
      initialize_swf: function() {
        var config, context, digest, doc, obj, serializer, settings, _ref;
        if (this.options.module.app != null) {
          context = this.options.module.app.context;
        }
        if ((_ref = context.parent_app) == null) {
          context.parent_app = this.options.module.app.app;
        }
        doc = this.controller.config.get('document');
        config = doc.find("ConfigItem[name=" + context.parent_app + "] ConfigItem[name=businesses] ConfigItem[name=" + context.businesses.name + "] ConfigItem[name=production]");
        serializer = new XMLSerializer();
        obj = swfobject.getObjectById("policy-summary-" + this.cid);
        digest = Base64.decode(this.model.get('digest')).split(':');
        settings = {
          "parentAuthtoken": "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
          "policyId": this.model.id
        };
        console.log(digest);
        console.log(settings);
        console.log(serializer.serializeToString(config[0]));
        if ((digest[0] != null) && (digest[1] != null)) {
          return obj.init(digest[0], digest[1], serializer.serializeToString(config[0]), settings);
        }
      },
      show_ipmchanges: function() {
        var header;
        header = this.Mustache.render(tpl_ipm_header, this.model.get_ipm_header());
        this.policy_header.html(header);
        this.policy_header.show();
        this.policy_summary.hide();
        swfobject.removeSWF("policy-summary-" + this.cid);
        this.iframe.show();
        this.iframe.attr('src', '/mxadmin/index.html');
        return this.resize_element(this.iframe, this.policy_header.height());
      }
    });
    return PolicyView;
  });

}).call(this);

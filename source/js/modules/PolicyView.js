// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'base64', 'text!templates/tpl_policy_container.html', 'text!templates/tpl_ipm_header.html', 'swfobject'], function(BaseView, Messenger, Base64, tpl_policy_container, tpl_ipm_header, swfobject) {
    var PolicyView;
    PolicyView = BaseView.extend({
      events: {
        "click .policy-nav a": "dispatch"
      },
      render_state: false,
      initialize: function(options) {
        this.el = options.view.el;
        this.$el = options.view.$el;
        this.controller = options.view.options.controller;
        this.flash_loaded = false;
        return this.on('activate', function() {
          if (this.flash_loaded === false) {
            this.show_overview();
            return this.teardown_ipmchanges();
          }
        });
      },
      render: function(options) {
        var html, props,
          _this = this;
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
        if (this.render_state === false) {
          this.render_state = true;
        }
        this.cache_elements();
        this.actions = this.policy_nav_links.map(function(idx, item) {
          return $(this).attr('href');
        });
        props = {
          policy_id: this.model.get('pxServerIndex'),
          ipm_auth: this.model.get('digest'),
          routes: this.controller.services
        };
        this.iframe.attr('src', '/mxadmin/index.html');
        this.iframe.bind('load', function() {
          _this.iframe[0].contentWindow.inject_properties(props);
          return _this.iframe[0].contentWindow.load_mxAdmin();
        });
        this.$el.hide();
        this.messenger = new Messenger(this.options.view, this.cid);
        if (this.controller.active_view.cid === this.options.view.cid) {
          this.show_overview();
          return this.teardown_ipmchanges();
        }
      },
      toggle_nav_state: function(el) {
        this.policy_nav_links.removeClass('select');
        return el.addClass('select');
      },
      dispatch: function(e) {
        var $e, action, func;
        e.preventDefault();
        $e = $(e.currentTarget);
        action = $e.attr('href');
        this.teardown_actions(_.filter(this.actions, function(item) {
          return item !== action;
        }));
        this.toggle_nav_state($e);
        func = this["show_" + action];
        if (_.isFunction(func)) {
          return func.apply(this);
        }
      },
      teardown_actions: function(actions) {
        var action, func, _i, _len, _results;
        if (actions === void 0 || actions === null) {
          return false;
        }
        if (!_.isArray(actions)) {
          actions = [actions];
        }
        _results = [];
        for (_i = 0, _len = actions.length; _i < _len; _i++) {
          action = actions[_i];
          func = this["teardown_" + action];
          if (_.isFunction(func)) {
            _results.push(func.apply(this));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      },
      cache_elements: function() {
        this.iframe_id = "#policy-iframe-" + this.cid;
        this.iframe = this.$el.find(this.iframe_id);
        this.policy_header = this.$el.find("#policy-header-" + this.cid);
        this.policy_nav_links = this.$el.find("#policy-nav-" + this.cid + " a");
        return this.policy_summary = this.$el.find("#policy-summary-" + this.cid);
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
        var flash_obj,
          _this = this;
        this.$el.show();
        if (this.$el.find("#policy-summary-" + this.cid).length === 0) {
          this.$el.find("#policy-header-" + this.cid).after(this.policy_summary);
          this.policy_summary = this.$el.find("#policy-summary-" + this.cid);
        }
        if (this.policy_summary.length > 0) {
          this.resize_element(this.policy_summary);
          flash_obj = $(swfobject.getObjectById("policy-summary-" + this.cid));
          if (_.isEmpty(flash_obj)) {
            flash_obj = $("#policy-summary-" + this.cid);
          }
          flash_obj.show();
        }
        if (this.flash_loaded === false) {
          return swfobject.embedSWF("../swf/PolicySummary.swf", "policy-summary-" + this.cid, "100%", this.policy_summary.height(), "9.0.0", null, null, {
            allowScriptAccess: 'always'
          }, null, function(e) {
            return _this.flash_callback(e);
          });
        }
      },
      teardown_overview: function() {
        this.policy_summary.hide();
        return $("#policy-summary-" + this.cid).hide();
      },
      flash_callback: function(e) {
        var _this = this;
        if (!e.success || e.success === !true) {
          this.Amplify.publish(this.cid, 'warning', "We could not launch the Flash player to load the summary. Sorry.");
          return false;
        }
        return window.policyViewInitSWF = function() {
          return _this.initialize_swf();
        };
      },
      initialize_swf: function() {
        var config, digest, obj, settings;
        if (this.flash_loaded === true) {
          return true;
        }
        config = this.controller.config.get_config(this.controller.workspace_state);
        if (!(config != null)) {
          this.Amplify.publish(this.cid, 'warning', "There was a problem with the configuration for this policy. Sorry.");
        }
        obj = swfobject.getObjectById("policy-summary-" + this.cid);
        digest = Base64.decode(this.model.get('digest')).split(':');
        settings = {
          "parentAuthtoken": "Y29tLmljczM2MC5hcHBzLmluc2lnaHRjZW50cmFsOjg4NTllY2IzNmU1ZWIyY2VkZTkzZTlmYTc1YzYxZDRl",
          "policyId": this.model.id
        };
        if ((digest[0] != null) && (digest[1] != null)) {
          obj.init(digest[0], digest[1], config, settings);
        } else {
          this.Amplify.publish(this.cid, 'warning', "There was a problem with your credentials for this policy. Sorry.");
        }
        return this.flash_loaded = true;
      },
      show_ipmchanges: function() {
        var header;
        header = this.Mustache.render(tpl_ipm_header, this.model.get_ipm_header());
        this.policy_header.html(header);
        this.policy_header.show();
        this.iframe.show();
        this.iframe.attr('src', '/mxadmin/index.html');
        return this.resize_element(this.iframe, this.policy_header.height());
      },
      teardown_ipmchanges: function() {
        if (this.policy_header) {
          this.policy_header.hide();
          this.$el.find("#policy-header-" + this.cid).hide();
          return this.iframe.hide();
        }
      }
    });
    return PolicyView;
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'base64', 'modules/RenewalUnderwriting/RenewalUnderwritingView', 'swfobject', 'text!modules/Policy/templates/tpl_policy_container.html', 'text!modules/Policy/templates/tpl_ipm_header.html', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_wrapper.html', 'modules/IPM/IPMModule', 'modules/ZenDesk/ZenDeskView'], function(BaseView, Messenger, Base64, RenewalUnderwritingView, swfobject, tpl_policy_container, tpl_ipm_header, tpl_ru_wrapper, IPMModule, ZenDeskView) {
    var PolicyView;
    PolicyView = BaseView.extend({
      events: {
        "click .policy-nav a": "dispatch"
      },
      initialize: function(options) {
        this.el = options.view.el;
        this.$el = options.view.$el;
        this.controller = options.view.options.controller;
        this.services = this.controller.services;
        this.flash_loaded = false;
        this.render_state = false;
        this.loaded_state = false;
        this.on('activate', function() {
          if (this.loaded_state) {
            if (this.render()) {
              this.show_overview();
              return this.teardown_ipmchanges();
            }
          }
        });
        this.on('deactivate', function() {
          return this.destroy_overview_swf();
        });
        return this.on('loaded', function() {
          this.loaded_state = true;
          if (this.controller.active_view.cid === this.options.view.cid) {
            return this.trigger('activate');
          }
        });
      },
      render: function(options) {
        var html;
        if (this.render_state === true) {
          true;
        }
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
        if (this.model.isIPM() === false) {
          this.$el.find('.policy-nav a[href=ipmchanges]').parent('li').hide();
        } else {
          this.IPM = new IPMModule(this.model, $("#policy-ipm-" + this.cid), this.controller.user);
        }
        this.cache_elements();
        this.actions = this.policy_nav_links.map(function(idx, item) {
          return $(this).attr('href');
        });
        this.build_and_load_swf_iframe();
        this.$el.hide();
        this.messenger = new Messenger(this.options.view, this.cid);
        return true;
      },
      build_and_load_swf_iframe: function() {},
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
      build_policy_header: function() {
        if (this.policy_header.html() === "") {
          this.policy_header.html(this.Mustache.render(tpl_ipm_header, this.model.get_ipm_header()));
        }
        return this.policy_header.show();
      },
      show_overview: function() {
        var flash_obj, resize, resizer,
          _this = this;
        this.$el.show();
        if (this.$el.find("#policy-summary-" + this.cid).length === 0) {
          this.$el.find("#policy-header-" + this.cid).after(this.policy_summary);
          this.policy_summary = this.$el.find("#policy-workspace-" + this.cid);
        }
        if (this.policy_summary.length > 0) {
          this.Helpers.resize_element(this.$el.find("#policy-workspace-" + this.cid));
          resizer = _.bind(function() {
            return this.Helpers.resize_element(this.$el.find("#policy-workspace-" + this.cid));
          }, this);
          resize = _.debounce(resizer, 300);
          $(window).resize(resize);
          flash_obj = $(swfobject.getObjectById("policy-summary-" + this.cid));
          if (_.isEmpty(flash_obj)) {
            flash_obj = $("#policy-summary-" + this.cid);
          }
          flash_obj.css('visibility', 'visible').height('100%');
        }
        if (this.flash_loaded === false) {
          return swfobject.embedSWF("../swf/PolicySummary.swf", "policy-summary-" + this.cid, "100%", "100%", "9.0.0", null, null, {
            allowScriptAccess: 'always'
          }, null, function(e) {
            return _this.flash_callback(e);
          });
        }
      },
      teardown_overview: function() {
        return $("#policy-summary-" + this.cid).css('visibility', 'hidden').height(0);
      },
      destroy_overview_swf: function() {
        swfobject.removeSWF("policy-summary-" + this.cid);
        return this.flash_loaded = false;
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
          "policyId": this.model.id,
          "applicationid": "ixadmin",
          "organizationid": "ics",
          "masterEnvironment": window.ICS360_ENV
        };
        if ((digest[0] != null) && (digest[1] != null)) {
          obj.init(digest[0], digest[1], config, settings);
        } else {
          this.Amplify.publish(this.cid, 'warning', "There was a problem with your credentials for this policy. Sorry.");
        }
        return this.flash_loaded = true;
      },
      show_ipmchanges: function() {
        var ipm_container;
        this.build_policy_header();
        this.policy_header.show();
        ipm_container = this.$el.find("#policy-ipm-" + this.cid);
        ipm_container.show();
        return this.Helpers.resize_element(ipm_container, this.policy_header.height());
      },
      teardown_ipmchanges: function() {
        var ipm_container;
        if (this.policy_header) {
          this.policy_header.hide();
          this.$el.find("#policy-header-" + this.cid).hide();
          ipm_container = this.$el.find("#policy-ipm-" + this.cid);
          return ipm_container.hide();
        }
      },
      show_renewalunderwriting: function() {
        var $ru_el;
        $ru_el = $("#renewal-underwriting-" + this.cid);
        if ($ru_el.length === 0) {
          $("#policy-workspace-" + this.cid).append(this.Mustache.render(tpl_ru_wrapper, {
            cid: this.cid
          }));
          $ru_el = $("#renewal-underwriting-" + this.cid);
        }
        if (this.ru_container === null || this.ru_container === void 0) {
          this.ru_container = new RenewalUnderwritingView({
            $el: $ru_el,
            policy: this.model,
            policy_view: this
          }).render();
        } else {
          this.ru_container.show();
        }
        return this.build_policy_header();
      },
      teardown_renewalunderwriting: function() {
        var $ru_el;
        $ru_el = $("#renewal-underwriting-" + this.cid);
        if ($ru_el.length > 0) {
          this.ru_container.hide();
        }
        if (this.policy_header) {
          this.policy_header.hide();
          return this.$el.find("#policy-header-" + this.cid).hide();
        }
      },
      show_servicerequests: function() {
        var $zd_el;
        $zd_el = $("#zendesk-" + this.cid);
        if ($zd_el.length === 0) {
          $("#policy-workspace-" + this.cid).append("<div id=\"zendesk-" + this.cid + "\" class=\"zd-container\"></div>");
          $zd_el = $("#zendesk-" + this.cid);
        }
        this.Helpers.resize_element(this.$el.find("#policy-workspace-" + this.cid));
        if (this.zd_container === null || this.zd_container === void 0) {
          this.zd_container = new ZenDeskView({
            $el: $zd_el,
            policy: this.model,
            policy_view: this
          }).fetch();
        } else {
          this.zd_container.show();
        }
        return this.build_policy_header();
      },
      teardown_servicerequests: function() {
        var $zd_el;
        $zd_el = $("#zendesk-" + this.cid);
        if ($zd_el.length > 0) {
          this.zd_container.hide();
        }
        if (this.policy_header) {
          this.policy_header.hide();
          return this.$el.find("#policy-header-" + this.cid).hide();
        }
      }
    });
    return PolicyView;
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['modules/IPM/IPMActionView'], function(IPMActionView) {
    var MakePaymentAction;
    return MakePaymentAction = (function(_super) {

      __extends(MakePaymentAction, _super);

      function MakePaymentAction() {
        this.processView = __bind(this.processView, this);
        return MakePaymentAction.__super__.constructor.apply(this, arguments);
      }

      MakePaymentAction.prototype.initialize = function() {
        return MakePaymentAction.__super__.initialize.apply(this, arguments);
      };

      MakePaymentAction.prototype.ready = function() {
        MakePaymentAction.__super__.ready.apply(this, arguments);
        return this.fetchTemplates(this.MODULE.POLICY, 'make-payment', this.processView);
      };

      MakePaymentAction.prototype.processView = function(vocabTerms, view) {
        var viewData;
        MakePaymentAction.__super__.processView.call(this, vocabTerms, view);
        viewData = this.MODULE.POLICY.getTermDataItemValues(vocabTerms);
        viewData = this.MODULE.POLICY.getEnumerations(viewData, vocabTerms);
        viewData = _.extend(viewData, this.MODULE.POLICY.getPolicyOverview(), {
          policyOverview: true,
          policyId: this.MODULE.POLICY.get_pxServerIndex()
        });
        this.viewData = viewData;
        this.view = view;
        return this.trigger("loaded", this);
      };

      MakePaymentAction.prototype.render = function(viewData, view) {
        MakePaymentAction.__super__.render.apply(this, arguments);
        viewData = viewData || this.viewData;
        view = view || this.view;
        return this.$el.html(this.MODULE.VIEW.Mustache.render(view, viewData));
      };

      MakePaymentAction.prototype.submit = function(e) {
        MakePaymentAction.__super__.submit.call(this, e);
        this.VALUES.formValues.positivePaymentAmount = Math.abs(this.VALUES.formValues.paymentAmount || 0);
        this.VALUES.formValues.paymentAmount = -1 * this.VALUES.formValues.positivePaymentAmount;
        return this.CHANGE_SET.commitChange(this.CHANGE_SET.getPolicyChangeSet(this.VALUES), this.callbackSuccess, this.callbackError);
      };

      return MakePaymentAction;

    })(IPMActionView);
  });

}).call(this);

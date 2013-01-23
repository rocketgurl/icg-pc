// Generated by CoffeeScript 1.4.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['modules/IPM/IPMActionView'], function(IPMActionView) {
    var WriteOffAction;
    return WriteOffAction = (function(_super) {

      __extends(WriteOffAction, _super);

      function WriteOffAction() {
        this.processView = __bind(this.processView, this);

        this.processViewData = __bind(this.processViewData, this);
        return WriteOffAction.__super__.constructor.apply(this, arguments);
      }

      WriteOffAction.prototype.initialize = function() {
        return WriteOffAction.__super__.initialize.apply(this, arguments);
      };

      WriteOffAction.prototype.ready = function() {
        WriteOffAction.__super__.ready.apply(this, arguments);
        return this.fetchTemplates(this.MODULE.POLICY, 'write-off', this.processView);
      };

      WriteOffAction.prototype.processViewData = function(vocabTerms, view) {
        return WriteOffAction.__super__.processViewData.call(this, vocabTerms, view);
      };

      WriteOffAction.prototype.processView = function(vocabTerms, view) {
        this.processViewData(vocabTerms, view);
        this.FormValidation.validators = {
          'amount': 'money'
        };
        return this.trigger("loaded", this, this.postProcessView);
      };

      WriteOffAction.prototype.submit = function(e) {
        var _ref, _ref1;
        WriteOffAction.__super__.submit.call(this, e);
        this.VALUES.formValues.amount = (_ref = this.Helpers.formatMoney(this.VALUES.formValues.amount)) != null ? _ref : null;
        this.VALUES.formValues.reasonCodeLabel = (_ref1 = $('#id_reasonCode option[value=' + this.VALUES.formValues.reasonCode + ']').html()) != null ? _ref1 : null;
        return this.ChangeSet.commitChange(this.ChangeSet.getPolicyChangeSet(this.VALUES), this.callbackSuccess, this.callbackError);
      };

      return WriteOffAction;

    })(IPMActionView);
  });

}).call(this);

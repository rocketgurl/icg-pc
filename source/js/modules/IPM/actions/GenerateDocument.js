// Generated by CoffeeScript 1.4.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['modules/IPM/IPMActionView'], function(IPMActionView) {
    var GenerateDocumentAction;
    return GenerateDocumentAction = (function(_super) {

      __extends(GenerateDocumentAction, _super);

      function GenerateDocumentAction() {
        this.processView = __bind(this.processView, this);

        this.processViewData = __bind(this.processViewData, this);
        return GenerateDocumentAction.__super__.constructor.apply(this, arguments);
      }

      GenerateDocumentAction.prototype.initialize = function() {
        GenerateDocumentAction.__super__.initialize.apply(this, arguments);
        this.CURRENT_ACTION = null;
        return this.events = {
          "click .ipm-action-links li a": "triggerDocumentAction"
        };
      };

      GenerateDocumentAction.prototype.ready = function() {
        GenerateDocumentAction.__super__.ready.apply(this, arguments);
        return this.fetchTemplates(this.MODULE.POLICY, 'generate-document', this.processView);
      };

      GenerateDocumentAction.prototype.processViewData = function(vocabTerms, view) {
        return GenerateDocumentAction.__super__.processViewData.call(this, vocabTerms, view);
      };

      GenerateDocumentAction.prototype.processView = function(vocabTerms, view) {
        this.processViewData(vocabTerms, view);
        this.viewData.documentGroups = vocabTerms.terms;
        return this.trigger("loaded", this, this.postProcessView);
      };

      GenerateDocumentAction.prototype.triggerDocumentAction = function(e) {
        var msg, _ref, _ref1;
        e.preventDefault();
        if (e.currentTarget.className !== 'disabled') {
          this.CURRENT_ACTION = {
            type: (_ref = $(e.currentTarget).attr('href')) != null ? _ref : false,
            label: (_ref1 = $(e.currentTarget).html()) != null ? _ref1 : false
          };
          if (this.CURRENT_ACTION.type != null) {
            return this.submit();
          } else {
            msg = "Could not load that document action. Contact support.";
            return this.PARENT_VIEW.displayMessage('error', msg, 12000);
          }
        }
      };

      GenerateDocumentAction.prototype.submit = function(e) {
        var idStamp, labelStamp, specialDocs, templateName, timestamp;
        GenerateDocumentAction.__super__.submit.call(this, e);
        timestamp = this.Helpers.makeTimestamp();
        idStamp = timestamp.replace(/:|\.\d{3}/g, '');
        labelStamp = this.Helpers.formatDate(timestamp);
        specialDocs = ['ReissueDeclarationPackage', 'Invoice'];
        templateName = "generate_document-" + (this.MODULE.POLICY.get('productName'));
        this.VALUES.formValues.generating = true;
        this.VALUES.formValues.policyId = this.MODULE.POLICY.get('insight_id');
        this.VALUES.formValues.documentId = "" + this.CURRENT_ACTION.type + "-" + idStamp;
        this.VALUES.formValues.documentType = this.CURRENT_ACTION.type;
        this.VALUES.formValues.documentLabel = this.CURRENT_ACTION.label;
        if (_.indexOf(specialDocs, this.CURRENT_ACTION.label) !== -1) {
          this.VALUES.formValues.documentLabel = "" + this.VALUES.formValues.documentLabel + " " + labelStamp;
        }
        return this.ChangeSet.commitChange(this.ChangeSet.getPolicyChangeSet(this.VALUES), this.callbackSuccess, this.callbackError);
      };

      return GenerateDocumentAction;

    })(IPMActionView);
  });

}).call(this);
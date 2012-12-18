// Generated by CoffeeScript 1.4.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['BaseView', 'Messenger', 'modules/IPM/IPMChangeSet', 'modules/IPM/IPMFormValidation'], function(BaseView, Messenger, IPMChangeSet, IPMFormValidation) {
    var IPMActionView;
    return IPMActionView = (function(_super) {

      __extends(IPMActionView, _super);

      function IPMActionView() {
        this.submit = __bind(this.submit, this);

        this.callbackPreview = __bind(this.callbackPreview, this);

        this.callbackError = __bind(this.callbackError, this);

        this.callbackSuccess = __bind(this.callbackSuccess, this);
        return IPMActionView.__super__.constructor.apply(this, arguments);
      }

      IPMActionView.prototype.tagName = 'div';

      IPMActionView.prototype.events = {
        "click fieldset h3": "toggleFieldset"
      };

      IPMActionView.prototype.initialize = function(options) {
        var _this = this;
        this.PARENT_VIEW = options.PARENT_VIEW || {};
        this.MODULE = options.MODULE || {};
        this.ChangeSet = new IPMChangeSet(this.MODULE.POLICY, this.PARENT_VIEW.VIEW_STATE, this.MODULE.USER);
        this.FormValidation = new IPMFormValidation();
        this.VALUES = {};
        this.TPL_CACHE = {};
        this.ERRORS = {};
        this.options = null;
        this.on('ready', this.ready, this);
        if (_.isFunction(this.submit)) {
          return this.submit = _.wrap(this.submit, function(submit) {
            var args;
            args = _.toArray(arguments);
            if (_this.validate()) {
              return submit(args[1]);
            }
          });
        }
      };

      IPMActionView.prototype.fetchTemplates = function(policy, action, callback) {
        var model, path, view;
        if (!(policy != null) || !(action != null)) {
          return false;
        }
        path = "/js/" + this.MODULE.CONFIG.PRODUCTS_PATH + (policy.get('productName')) + "/forms/" + (_.slugify(action));
        if (!_.has(this.TPL_CACHE, action)) {
          model = $.getJSON("" + path + "/model.json").pipe(function(resp) {
            return resp;
          });
          view = $.get("" + path + "/view.html", null, null, "text").pipe(function(resp) {
            return resp;
          });
          return $.when(model, view).then(callback, this.PARENT_VIEW.actionError);
        } else {
          return callback(this.TPL_CACHE[action].model, this.TPL_CACHE[action].view);
        }
      };

      IPMActionView.prototype.goHome = function(e) {
        e.preventDefault();
        return this.PARENT_VIEW.route('Home');
      };

      IPMActionView.prototype.toggleFieldset = function(e) {
        var a, a_html, container, h3;
        e.preventDefault();
        h3 = $(e.currentTarget);
        a = h3.find('a');
        container = h3.parent().find('.collapsibleFieldContainer');
        if (container.css('display') === 'none') {
          container.css('display', 'block');
        } else {
          container.css('display', 'none');
        }
        a_html = a.html();
        return a.html(a.data('altText')).data('altText', a_html);
      };

      IPMActionView.prototype.postProcessView = function() {
        var date_options,
          _this = this;
        this.$el.find('.form_actions a').on('click', function(e) {
          return _this.goHome(e);
        });
        $('select[data-value]').val(function() {
          return $(this).attr('data-value');
        });
        date_options = {
          dateFormat: 'yy-mm-dd'
        };
        if ($.datepicker) {
          $('.datepicker').datepicker(date_options);
        }
        return this.$el.find('form input.button[type=submit]').on('click', function(e) {
          return _this.submit(e);
        });
      };

      IPMActionView.prototype.postProcessPreview = function() {
        var _this = this;
        delete this.viewData.preview;
        this.$el.find('.form_actions a').on('click', function(e) {
          e.preventDefault();
          return _this.processView(_this.TPL_CACHE[_this.PARENT_VIEW.VIEW_STATE].model, _this.TPL_CACHE[_this.PARENT_VIEW.VIEW_STATE].view);
        });
        if (this.$el.find('.data_table').length > 0) {
          return this.processPreviewForm(this.$el.find('.data_table'));
        }
      };

      IPMActionView.prototype.getFormValues = function(form) {
        var formValues, item, _i, _len, _ref;
        formValues = {};
        _ref = form.serializeArray();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          formValues[item.name] = item.value;
        }
        return formValues;
      };

      IPMActionView.prototype.getChangedValues = function(form) {
        var changed;
        changed = [];
        form.find(':input').each(function(i, element) {
          var el, name, val;
          el = $(element);
          val = el.val();
          name = el.attr('name');
          if (el.is('select')) {
            if (el.data('value') != val) {
              return changed.push(name);
            }
          } else if (el.is('textarea')) {
            if (val.trim() !== '') {
              changed.push(name);
            }
            if (val.trim() === '' && el.data('hadValue')) {
              return changed.push(name);
            }
          } else {
            if (val !== element.getAttribute('value')) {
              return changed.push(name);
            }
          }
        });
        return changed;
      };

      IPMActionView.prototype.processViewData = function(vocabTerms, view) {
        var viewData;
        this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE] = {
          model: vocabTerms,
          view: view
        };
        viewData = {};
        if (vocabTerms != null) {
          viewData = this.MODULE.POLICY.getTermDataItemValues(vocabTerms);
          viewData = this.MODULE.POLICY.getEnumerations(viewData, vocabTerms);
        }
        viewData = _.extend(viewData, this.MODULE.POLICY.getPolicyOverview(), {
          policyOverview: true,
          policyId: this.MODULE.POLICY.get_pxServerIndex()
        });
        this.viewData = viewData;
        this.view = view;
        return [viewData, view];
      };

      IPMActionView.prototype.processPreviewForm = function(table) {
        var update_button,
          _this = this;
        update_button = this.$el.find('#updatePreview');
        update_button.attr('disabled', true);
        table.find('tr.calc_row input').each(function(i, val) {
          var $input, adjustedElem, parentRow, subTotalElem, unadjustedVal;
          $input = $(this);
          parentRow = $input.closest('tr.calc_row');
          unadjustedVal = parseInt($input.parent().prev().text(), 10) || 0;
          adjustedElem = $input.parent().next();
          subTotalElem = parentRow.find('td.subtotal');
          return $input.on('keyup', function(e) {
            var adjustmentVal, subTotalView;
            adjustmentVal = ~~this.value;
            subTotalView = ~~(subTotalElem.text());
            adjustedElem.text(unadjustedVal + adjustmentVal);
            subTotalElem.trigger('adjust');
            return update_button.attr('disabled', false);
          });
        });
        table.find('tr.calc_row').each(function(i, val) {
          var $tr, calculatedVals, fees, feesElem, originSubtotal, originTotal, subtotalElem, totalElem;
          $tr = $(this);
          calculatedVals = $tr.find('td.calculated_value');
          subtotalElem = $tr.find('td.subtotal');
          feesElem = $tr.find('td.fees');
          totalElem = $tr.find('td.total');
          originSubtotal = parseInt(subtotalElem.text(), 10) || 0;
          fees = parseInt(feesElem.text(), 10) || 0;
          originTotal = parseInt(totalElem.text(), 10) || 0;
          return subtotalElem.on('adjust', function() {
            var newSubtotal, newTotal;
            newSubtotal = 0;
            newTotal = 0;
            calculatedVals.each(function(i, val) {
              var amt;
              amt = parseInt($(this).text(), 10) || 0;
              return newSubtotal = newSubtotal + amt;
            });
            subtotalElem.text(newSubtotal);
            return totalElem.text(newSubtotal + fees);
          });
        });
        if (!table.data('initialized')) {
          table.data('initialized', true);
          update_button.on('click', function() {
            _this.$el.find('form').append('<input type="hidden" id="id_preview" name="preview" value="re-preview">');
            return _this.submit();
          });
        }
        return this.$el.find('form input[type=submit]').on('click', function(e) {
          _this.$el.find('form input[name=preview]').attr('value', 'confirm');
          return _this.submit(e);
        });
      };

      IPMActionView.prototype.callbackSuccess = function(data, status, jqXHR) {
        var msg;
        msg = "" + this.PARENT_VIEW.VIEW_STATE + " completed successfully";
        this.PARENT_VIEW.displayMessage('success', msg, 12000).remove_loader();
        this.resetPolicyModel(data, jqXHR);
        return this.PARENT_VIEW.route('Home');
      };

      IPMActionView.prototype.callbackError = function(jqXHR, status, error) {
        var json, regex;
        if (!jqXHR) {
          this.PARENT_VIEW.displayError('warning', 'Fatal: Error received with no response from server').remove_loader();
          return false;
        }
        if (jqXHR.responseText != null) {
          regex = /\[(.*?)\]/g;
          json = regex.exec(jqXHR.responseText);
          if ((json != null) && this.PARENT_VIEW.VIEW_STATE === 'Endorse') {
            this.ERRORS = this.errorParseJSON(jqXHR, json);
          } else {
            this.ERRORS = this.errorParseHTML(jqXHR);
          }
        }
        return this.displayError('warning', this.ERRORS);
      };

      IPMActionView.prototype.callbackPreview = function(data, status, jqXHR) {
        this.resetPolicyModel(data, jqXHR);
        this.processPreview(this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE].model, this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE].view);
        return this.PARENT_VIEW.remove_loader();
      };

      IPMActionView.prototype.resetPolicyModel = function(data, jqXHR) {
        var key, new_attributes, val;
        new_attributes = this.MODULE.POLICY.parse(data, jqXHR);
        new_attributes.prev_document = this.MODULE.POLICY.get('document');
        for (key in new_attributes) {
          val = new_attributes[key];
          this.MODULE.POLICY.attributes[key] = val;
        }
        this.MODULE.POLICY.trigger('change', this.MODULE.POLICY);
        return this.MODULE.POLICY;
      };

      IPMActionView.prototype.render = function(viewData, view) {
        IPMActionView.__super__.render.apply(this, arguments);
        viewData = viewData || this.viewData;
        view = view || this.view;
        return this.$el.html(this.MODULE.VIEW.Mustache.render(view, viewData));
      };

      IPMActionView.prototype.validate = function() {
        var errors, required_fields;
        required_fields = this.$el.find('input[required], select[required]');
        errors = this.FormValidation.validateFields(required_fields);
        if (_.isEmpty(errors)) {
          return true;
        } else {
          this.PARENT_VIEW.displayMessage('warning', this.FormValidation.displayErrorMsg(errors));
          return false;
        }
      };

      IPMActionView.prototype.submit = function(e) {
        var form;
        if (e != null) {
          e.preventDefault();
        }
        this.PARENT_VIEW.insert_loader('Processing policy');
        form = this.$el.find('form');
        if (form.length > 0) {
          this.VALUES.formValues = this.getFormValues(form);
          this.VALUES.changedValues = this.getChangedValues(form);
          if (_.has(this.VALUES, 'previousValues')) {
            this.VALUES.formValues = _.extend(this.VALUES.previousValues.formValues, this.VALUES.formValues);
            this.VALUES.changedValues = _.uniq(this.VALUES.changedValues.concat(this.VALUES.previousValues.changedValues));
          }
          if (_.has(this.VALUES.formValues, 'preview') && this.VALUES.formValues.preview !== 'confirm') {
            this.VALUES.previousValues = {
              formValues: _.clone(this.VALUES.formValues),
              changedValues: _.clone(this.VALUES.changedValues)
            };
            return delete this.VALUES.previousValues.formValues.preview;
          }
        }
      };

      IPMActionView.prototype.errorParseHTML = function(jqXHR) {
        var status_code, tmp, true_status_code, _ref;
        status_code = jqXHR.status;
        true_status_code = (_ref = jqXHR.getResponseHeader('X-True-Statuscode')) != null ? _ref : null;
        tmp = $('<div />').html(jqXHR.responseText);
        this.ERRORS.title = tmp.find('h1:first').text();
        this.ERRORS.desc = tmp.find('p:first').text();
        this.ERRORS.details = tmp.find('ol:first');
        if (this.ERRORS.details.length === 0) {
          this.ERRORS.details = tmp.find('ul:first');
          if (this.ERRORS.details.length === 0) {
            this.ERRORS.details = null;
          }
        }
        tmp = null;
        if (!(true_status_code != null)) {
          this.ERRORS.title = "" + status_code + " " + this.ERRORS.tile;
        }
        return this.ERRORS;
      };

      IPMActionView.prototype.errorParseJSON = function(jqXHR, json) {
        var response, _ref, _ref1, _ref2;
        if ((json != null) && (json[0] != null)) {
          response = (_ref = JSON.parse(json[0])) != null ? _ref : null;
        }
        if (response[0] != null) {
          this.ERRORS.title = (_ref1 = response[0].message) != null ? _ref1 : null;
          this.ERRORS.desc = (_ref2 = response[0].detail) != null ? _ref2 : null;
          this.ERRORS.details = null;
        }
        if (this.ERRORS.title === 'Rate Validation Failed') {
          this.$el.find('#rate_validation_override').fadeIn('fast');
        }
        return this.ERRORS;
      };

      IPMActionView.prototype.displayError = function(type, error) {
        var msg;
        msg = "<h3>" + error.title + "</h3><p>" + error.desc + "</p>";
        if (error.details != null) {
          msg = "" + msg + "\n<div class=\"error_details\">\n  <a href=\"#\"><i class=\"icon-plus-sign\"></i> Show error details</a>\n  " + error.details + "\n</div>";
        }
        this.PARENT_VIEW.displayMessage(type, msg);
        return msg;
      };

      IPMActionView.prototype.ready = function() {};

      IPMActionView.prototype.preview = function() {};

      return IPMActionView;

    })(BaseView);
  });

}).call(this);
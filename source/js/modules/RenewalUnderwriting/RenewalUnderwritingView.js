// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'Messenger', 'modules/RenewalUnderwriting/RenewalUnderwritingModel', 'modules/RenewalUnderwriting/RenewalVocabModel', 'modules/ReferralQueue/ReferralAssigneesModel', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_container.html', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_assignee.html', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_disposition.html', 'jqueryui'], function(BaseView, Messenger, RenewalUnderwritingModel, RenewalVocabModel, ReferralAssigneesModel, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) {
    var RenewalUnderwritingView;
    return RenewalUnderwritingView = BaseView.extend({
      changeset: {},
      datepicker: '',
      events: {
        'click a[href=assigned_to]': function(e) {
          return this.changeAssignment(this.process_event(e));
        },
        'click a[href=current_disposition]': function(e) {
          return this.changeDisposition(this.process_event(e));
        },
        'click a[href=review_period]': function(e) {
          return this.reviewPeriod(this.process_event(e));
        },
        'click a[href=review_deadline]': function(e) {
          return this.reviewDeadline(this.process_event(e));
        },
        'click .menu-close': function(e) {
          return this.Modal.clearMenu(e);
        },
        'click .ru-assignees-row a': function(e) {
          this.selectAssignee(this.process_event(e));
          return this.$el.find('.menu-close').trigger('click');
        },
        'click .ru-disposition-row a': function(e) {
          this.selectDisposition(this.process_event(e));
          return this.$el.find('.menu-close').trigger('click');
        },
        'click .cancel': function(e) {
          e.preventDefault();
          return this.$el.find('.menu-close').trigger('click');
        },
        'click .confirm': function(e) {
          return this.confirmDisposition(this.process_event(e));
        },
        'change #disposition': function(e) {
          return this.inspectDispositionOption(this.process_event(e));
        }
      },
      initialize: function(options) {
        var ixlibrary, key, val, vocabs, _results;
        this.$el = options.$el;
        this.Policy = options.policy;
        this.PolicyView = options.policy_view;
        this.User = this.PolicyView.controller.user;
        this.non_renew_mode = false;
        this.RenewalModel = new RenewalUnderwritingModel({
          id: this.Policy.id,
          urlRoot: this.Policy.get('urlRoot'),
          digest: this.Policy.get('digest'),
          user: this.User.id
        });
        this.RenewalModel.on('renewal:success', this.renewalSuccess, this);
        this.RenewalModel.on('renewal:update', this.renewalUpdate, this);
        this.RenewalModel.on('renewal:error', this.renewalError, this);
        this.putSuccess = _.bind(this.putSuccess, this);
        this.putError = _.bind(this.putError, this);
        ixlibrary = "" + this.PolicyView.controller.services.ixlibrary + "buckets/underwriting/objects/assignee_list.xml";
        this.AssigneeList = new ReferralAssigneesModel({
          digest: this.Policy.get('digest')
        });
        this.AssigneeList.url = ixlibrary;
        this.assigneesFetchError = _.bind(this.assigneesFetchError, this);
        this.assigneesFetchSuccess = _.bind(this.assigneesFetchSuccess, this);
        this.AssigneeList.fetch({
          success: this.assigneesFetchSuccess,
          error: this.assigneesFetchError
        });
        vocabs = {
          RenewalVocabDispositions: 'Disposition',
          RenewalVocabReasons: 'NonRenewalReasonCode'
        };
        _results = [];
        for (key in vocabs) {
          val = vocabs[key];
          this[key] = new RenewalVocabModel({
            id: val,
            url_root: this.PolicyView.controller.services.ixvocab
          });
          _results.push(this[key].checkCache());
        }
        return _results;
      },
      assigneesFetchSuccess: function(model, response, options) {
        this.assignees_list = model.getRenewals();
        if (this.assignees_list.length > 0) {
          return this.assignees_list = _.map(this.assignees_list, function(assignee) {
            return _.extend(assignee, {
              id: _.uniqueId()
            });
          });
        }
      },
      assigneesFetchError: function(model, xhr, options) {
        return this.Amplify.publish(this.PolicyView.cid, 'warning', "Could not fetch assignees list from server : " + xhr.status + " - " + xhr.statusText, 2000);
      },
      render: function() {
        this.show();
        if ($("#ru-spinner-" + this.PolicyView.cid).length > 0) {
          $("#ru-loader-" + this.PolicyView.cid).show();
          this.loader = this.Helpers.loader("ru-spinner-" + this.PolicyView.cid, 80, '#696969');
          this.loader.setFPS(48);
        }
        this.RenewalModel.fetch({
          success: function(model, resp) {
            return model.trigger('renewal:success', resp);
          },
          error: function(model, resp) {
            return model.trigger('renewal:error', resp);
          }
        });
        return this;
      },
      removeLoader: function() {
        if (this.loader != null) {
          this.loader.kill();
          return $("#ru-loader-" + this.cid).hide();
        }
      },
      show: function() {
        return this.$el.fadeIn('fast');
      },
      hide: function() {
        return this.$el.hide();
      },
      process_event: function(e) {
        e.preventDefault();
        return $(e.currentTarget);
      },
      changeAssignment: function(el) {
        var data;
        data = {
          cid: this.cid,
          assignees: this.assignees_list
        };
        return this.Modal.attach_menu(el, '.ru-menus', tpl_ru_assignees, data);
      },
      selectAssignee: function(el) {
        return this.processChange('renewal.assignedTo', $(el).html());
      },
      selectDisposition: function(el) {
        return this.processChange('insuranceScore.disposition', $(el).html());
      },
      changeDisposition: function(el) {
        var data, input, r, _i, _len, _ref;
        r = this.RenewalModel.attributes;
        data = {
          cid: this.cid,
          dispositions: [
            {
              id: 'new',
              name: 'New'
            }, {
              id: 'pending',
              name: 'Pending'
            }, {
              id: 'renew no-action',
              name: 'Renew with no action'
            }, {
              id: 'non-renew',
              name: 'Non-renew'
            }, {
              id: 'withdrawn',
              name: 'Withdrawn'
            }, {
              id: 'conditional renew',
              name: 'Conditional renew'
            }
          ],
          reasons: [
            {
              id: "1",
              name: "Insured request"
            }, {
              id: "2",
              name: "Nonpayment of premium"
            }, {
              id: "3",
              name: "Insured convicted of crime"
            }, {
              id: "4",
              name: "Discovery of fraud or material misrepresentation"
            }, {
              id: "5",
              name: "Discovery of willful or reckless acts of omissions"
            }, {
              id: "6",
              name: "Physical changes in the property "
            }, {
              id: "7",
              name: "Increase in liability hazards beyond what is normally accepted"
            }, {
              id: "8",
              name: "Increase in property hazards beyond what is normally accepted"
            }, {
              id: "9",
              name: "Overexposed in area where risk is located"
            }, {
              id: "10",
              name: "Change in occupancy status"
            }, {
              id: "11",
              name: "Other underwriting reasons"
            }, {
              id: "12",
              name: "Cancel/rewrite"
            }, {
              id: "13",
              name: "Change in ownership"
            }, {
              id: "14",
              name: "Missing required documentation"
            }, {
              id: "15",
              name: "Insured Request - Short Rate"
            }, {
              id: "16",
              name: "Nonpayment of Premium - Flat"
            }
          ],
          disposition: r.insuranceScore.disposition,
          nonRenewalReasonCode: r.renewal.nonRenewalReasonCode,
          nonRenewalReason: r.renewal.nonRenewalReason,
          comment: r.renewal.comment
        };
        this.Modal.attach_menu(el, '.ru-menus', tpl_ru_disposition, data);
        _ref = ['nonRenewalReasonCode', 'disposition'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          input = _ref[_i];
          if (data[input] != null) {
            this.$el.find("#" + input).val(data[input]);
          }
        }
        this.$el.find('.nonrenewal-reasons-block').hide();
        return this.inspectDispositionOption(this.$el.find('#disposition'));
      },
      inspectDispositionOption: function(el) {
        this.$el.find('.nonrenewal-reasons-block').hide();
        this.non_renew_mode = false;
        if (el.val() === 'non-renew') {
          this.non_renew_mode = true;
          return this.$el.find('.nonrenewal-reasons-block').show();
        }
      },
      confirmDisposition: function(el) {
        var $field, changes, error, field, field_map, fields, non_renew_fields, send_fields, _i, _j, _len, _len1;
        this.$el.find('.confirm').attr('disabled', true);
        error = false;
        field_map = {
          'disposition': 'insuranceScore',
          'comment': 'renewal',
          'nonRenewalReasonCode': 'renewal',
          'nonRenewalReason': 'renewal'
        };
        fields = _.keys(field_map);
        if (this.non_renew_mode) {
          non_renew_fields = fields.slice(2);
          send_fields = fields;
          for (_i = 0, _len = non_renew_fields.length; _i < _len; _i++) {
            field = non_renew_fields[_i];
            $field = this.$el.find("#" + field);
            if ($field.val() === '' || $field.val() === '- Select one -') {
              error = true;
              $field.parent().find('label').addClass('error');
            } else {
              $field.parent().find('label').removeClass('error');
            }
          }
          if (error) {
            this.$el.find('.confirm').attr('disabled', false);
            return null;
          }
        } else {
          send_fields = fields.slice(0, 2);
        }
        changes = false;
        for (_j = 0, _len1 = send_fields.length; _j < _len1; _j++) {
          field = send_fields[_j];
          if (this.updateChangeset("" + field_map[field] + "." + field, this.$el.find("#" + field).val())) {
            changes = true;
          }
        }
        if (changes) {
          this.RenewalModel.putFragment(this.putSuccess, this.putError, this.changeset);
          return true;
        } else {
          this.$el.find('.confirm').attr('disabled', false);
          this.Amplify.publish(this.PolicyView.cid, 'notice', "No changes made", 2000);
          return false;
        }
      },
      reviewPeriod: function(el) {
        return this.$el.find('input[name=reviewPeriod]').datepicker("show");
      },
      reviewDeadline: function(el) {
        return this.$el.find('input[name=reviewDeadline]').datepicker("show");
      },
      attachDatepickers: function() {
        var options;
        this.dateChanged = _.bind(this.dateChanged, this);
        this.setDatepicker = _.bind(this.setDatepicker, this);
        options = {
          dateFormat: 'yy-mm-dd',
          onClose: this.dateChanged,
          beforeShow: this.setDatepicker
        };
        this.$el.find('input[name=reviewPeriod]').datepicker(options);
        return this.$el.find('input[name=reviewDeadline]').datepicker(options);
      },
      dateChanged: function(date) {
        var field;
        field = "renewal." + ($(this.datepicker).attr('name'));
        return this.processChange(field, date);
      },
      processResponseFields: function(resp) {
        var field, _i, _j, _len, _len1, _ref, _ref1;
        resp.reviewStatusFlag = resp.renewal.renewalReviewRequired;
        resp.lossHistoryFlag = true;
        if (_.isEmpty(resp.lossHistory)) {
          resp.lossHistoryFlag = false;
        }
        _ref = ['renewalReviewRequired'];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          field = _ref[_i];
          if (resp.renewal[field] === true) {
            resp.renewal[field] = 'Yes';
          } else {
            resp.renewal[field] = 'No';
          }
        }
        if (resp.renewal.inspectionOrdered === false) {
          delete resp.renewal.inspectionOrdered;
        }
        _ref1 = ['newInsuranceScore', 'oldInsuranceScore'];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          field = _ref1[_j];
          resp.insuranceScore[field] = resp.insuranceScore[field].replace(/'|"/g, '');
        }
        return resp;
      },
      updateChangeset: function(field, val) {
        var old_val;
        old_val = '';
        field = field.indexOf('.') > -1 ? field.split('.') : field;
        if (_.isArray(field)) {
          old_val = this.changeset[field[0]][field[1]];
        } else {
          old_val = field;
        }
        this.changed_field = field;
        if (old_val !== val) {
          if (_.isArray(field)) {
            this.changeset[field[0]][field[1]] = val;
            this.RenewalModel.set(field[0], this.changeset[field[0]]);
          } else {
            this.RenewalModel.set(field, val);
          }
          return true;
        } else {
          return false;
        }
      },
      processChange: function(field, val) {
        if (this.updateChangeset(field, val)) {
          this.updateElement('loading');
          this.RenewalModel.putFragment(this.putSuccess, this.putError, this.changeset);
          return true;
        } else {
          this.Amplify.publish(this.PolicyView.cid, 'notice', "No changes made", 2000);
          return false;
        }
      },
      updateElement: function(new_class) {
        var $el, elements, new_value, target_el;
        elements = {
          assignedTo: 'a[href=assigned_to]',
          disposition: 'a[href=current_disposition]',
          reviewDeadline: 'input[name=reviewDeadline]',
          reviewPeriod: 'input[name=reviewPeriod]',
          reason: 'textarea[name=reason]'
        };
        if (this.changed_field != null) {
          target_el = elements[this.changed_field[1]];
          new_value = this.changeset[this.changed_field[0]][this.changed_field[1]];
        }
        $el = this.$el.find(target_el);
        $el.removeClass().addClass(new_class);
        if ($el.is('a')) {
          $el.html("" + new_value + "&nbsp;<i class=\"icon-pencil\"></i>");
        }
        if ($el.is('textarea') && new_class === 'complete') {
          this.resetRenewalReason($el);
        }
        if ($el.is('textarea') && new_class === 'incomplete') {
          $el.attr('disabled', false);
          return $el.parent().find('.confirm').attr('disabled', false);
        }
      },
      setDatepicker: function(el) {
        return this.datepicker = el;
      },
      putSuccess: function(model, response, options) {
        this.$el.find('.confirm').attr('disabled', false);
        this.Amplify.publish(this.PolicyView.cid, 'success', "Saved changes!", 2000);
        this.AssigneeList.fetch({
          success: this.assigneesFetchSuccess,
          error: this.assigneesFetchError
        });
        this.RenewalModel.fetch({
          success: function(model, resp) {
            return model.trigger('renewal:update', resp);
          },
          error: function(model, resp) {
            return model.trigger('renewal:error', resp);
          }
        });
        return model;
      },
      putError: function(model, xhr, options) {
        this.$el.find('.confirm').attr('disabled', false);
        return this.Amplify.publish(this.PolicyView.cid, 'warning', "Could not save!", 2000);
      },
      processRenewalResponse: function(resp) {
        resp.cid = this.cid;
        if (resp.insuranceScore.currentDisposition === '') {
          resp.insuranceScore.currentDisposition = 'New';
        }
        resp = this.processResponseFields(resp);
        this.changeset = {
          renewal: _.omit(resp.renewal, ["inspectionOrdered", "renewalReviewRequired"]),
          insuranceScore: {
            currentDisposition: resp.insuranceScore.currentDisposition
          }
        };
        return resp;
      },
      renewalSuccess: function(resp) {
        if (resp != null) {
          if (_.isEmpty(resp)) {
            this.renewalError({
              statusText: 'Dataset empty',
              status: 'pxCentral'
            });
            return false;
          }
          resp = this.processRenewalResponse(resp);
          this.$el.html(this.Mustache.render(tpl_ru_container, resp));
          this.removeLoader();
          this.show();
          this.PolicyView.resize_workspace(this.$el, null);
          return this.attachDatepickers();
        } else {
          return this.renewalError({
            statusText: 'Dataset empty',
            status: 'Backbone'
          });
        }
      },
      renewalUpdate: function(resp) {
        if (resp === null || _.isEmpty(resp)) {
          this.renewalError({
            statusText: 'Dataset empty',
            status: 'pxCentral'
          });
          return false;
        }
        resp = this.processRenewalResponse(resp);
        this.undelegateEvents();
        this.$el.find('input[name=reviewPeriod]').datepicker("destroy");
        this.$el.find('input[name=reviewDeadline]').datepicker("destroy");
        this.$el.html(this.Mustache.render(tpl_ru_container, resp));
        this.delegateEvents();
        return this.attachDatepickers();
      },
      renewalError: function(resp) {
        this.removeLoader();
        return this.Amplify.publish(this.PolicyView.cid, 'warning', "Could not retrieve renewal underwriting information: " + resp.statusText + " (" + resp.status + ")");
      }
    });
  });

}).call(this);

// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'Messenger', 'modules/RenewalUnderwriting/RenewalUnderwritingModel', 'modules/ReferralQueue/ReferralAssigneesModel', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_container.html', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_assignee.html', 'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_disposition.html', 'jqueryui'], function(BaseView, Messenger, RenewalUnderwritingModel, ReferralAssigneesModel, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) {
    var RenewalUnderwritingView;
    return RenewalUnderwritingView = BaseView.extend({
      CHANGESET: {},
      DATEPICKER: '',
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
        'click .renewal_reason': function(e) {
          return this.editRenewalReason(this.process_event(e));
        },
        'click .cancel': function(e) {
          return this.cancelRenewalReason(this.process_event(e));
        },
        'click .confirm': function(e) {
          return this.persistRenewalReason(this.process_event(e));
        }
      },
      initialize: function(options) {
        var ixlibrary;
        this.$el = options.$el;
        this.policy = options.policy;
        this.policy_view = options.policy_view;
        this.RenewalModel = new RenewalUnderwritingModel({
          id: this.policy.id,
          urlRoot: this.policy.get('urlRoot'),
          digest: this.policy.get('digest')
        });
        this.RenewalModel.on('renewal:success', this.renewalSuccess, this);
        this.RenewalModel.on('renewal:error', this.renewalError, this);
        this.putSuccess = _.bind(this.putSuccess, this);
        this.putError = _.bind(this.putError, this);
        ixlibrary = "" + this.policy_view.controller.services.ixlibrary + "buckets/underwriting/objects/assignee_list.xml";
        this.AssigneeList = new ReferralAssigneesModel({
          digest: this.policy.get('digest')
        });
        this.AssigneeList.url = ixlibrary;
        this.assigneesFetchError = _.bind(this.assigneesFetchError, this);
        this.assigneesFetchSuccess = _.bind(this.assigneesFetchSuccess, this);
        return this.AssigneeList.fetch({
          success: this.assigneesFetchSuccess,
          error: this.assigneesFetchError
        });
      },
      assigneesFetchSuccess: function(model, response, options) {
        this.ASSIGNEES_LIST = model.getRenewals();
        if (this.ASSIGNEES_LIST.length > 0) {
          return this.ASSIGNEES_LIST = _.map(this.ASSIGNEES_LIST, function(assignee) {
            return _.extend(assignee, {
              id: _.uniqueId()
            });
          });
        }
      },
      assigneesFetchError: function(model, xhr, options) {
        return this.Amplify.publish(this.policy_view.cid, 'warning', "Could not fetch assignees list from server : " + xhr.status + " - " + xhr.statusText, 2000);
      },
      render: function() {
        this.show();
        $("#ru-loader-" + this.policy_view.cid).show();
        this.loader = this.Helpers.loader("ru-spinner-" + this.policy_view.cid, 80, '#696969');
        this.loader.setFPS(48);
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
        this.loader.kill();
        return $("#ru-loader-" + this.cid).hide();
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
          assignees: this.ASSIGNEES_LIST
        };
        return this.Modal.attach_menu(el, '.ru-menus', tpl_ru_assignees, data);
      },
      selectAssignee: function(el) {
        return this.processChange('renewal.assignedTo', $(el).html());
      },
      selectDisposition: function(el) {
        return this.processChange('insuranceScore.currentDisposition', $(el).html());
      },
      changeDisposition: function(el) {
        var data;
        data = {
          cid: this.cid,
          dispositions: [
            {
              id: 1,
              name: 'Pending'
            }, {
              id: 2,
              name: 'Dead'
            }, {
              id: 3,
              name: 'Vaporized'
            }
          ]
        };
        return this.Modal.attach_menu(el, '.ru-menus', tpl_ru_disposition, data);
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
        field = "renewal." + ($(this.DATEPICKER).attr('name'));
        return this.processChange(field, date);
      },
      editRenewalReason: function($el) {
        var $parent, content;
        content = $el.html();
        $parent = $el.parent();
        $el.hide();
        $parent.find('textarea').show();
        return $parent.find('.buttons').show();
      },
      cancelRenewalReason: function($el) {
        var $parent;
        $parent = $el.parent().parent();
        $parent.find('.renewal_reason').show();
        $parent.find('textarea').hide();
        return $parent.find('.buttons').hide();
      },
      persistRenewalReason: function($el) {
        var $parent;
        $parent = $el.parent().parent();
        $el.attr('disabled', true);
        $parent.find('textarea').attr('disabled', true);
        return this.processChange('renewal.reason', $parent.find('textarea').val());
      },
      resetRenewalReason: function($el) {
        var $parent;
        $el.attr('disabled', false);
        $parent = $el.parent();
        $parent.find('.confirm').attr('disabled', false);
        $parent.find('.renewal_reason').html($el.val()).show();
        $parent.find('.buttons').hide();
        return $el.hide();
      },
      processChange: function(field, val) {
        var old_val;
        old_val = '';
        field = field.indexOf('.') > -1 ? field.split('.') : fiel;
        if (_.isArray(field)) {
          old_val = this.CHANGESET[field[0]][field[1]];
        } else {
          old_val = field;
        }
        this.CHANGED_FIELD = field;
        if (old_val !== val) {
          if (_.isArray(field)) {
            this.CHANGESET[field[0]][field[1]] = val;
            this.RenewalModel.set(field[0], this.CHANGESET[field[0]]);
          } else {
            this.RenewalModel.set(field, val);
          }
          this.updateElement('loading');
          return this.RenewalModel.putFragment(this.putSuccess, this.putError, this.CHANGESET);
        } else {
          this.Amplify.publish(this.policy_view.cid, 'notice', "No changes made", 2000);
          return false;
        }
      },
      updateElement: function(new_class) {
        var $el, elements, new_value, target_el;
        elements = {
          assignedTo: 'a[href=assigned_to]',
          currentDisposition: 'a[href=current_disposition]',
          reviewDeadline: 'input[name=reviewDeadline]',
          reviewPeriod: 'input[name=reviewPeriod]',
          reason: 'textarea[name=reason]'
        };
        if (this.CHANGED_FIELD != null) {
          target_el = elements[this.CHANGED_FIELD[1]];
          new_value = this.CHANGESET[this.CHANGED_FIELD[0]][this.CHANGED_FIELD[1]];
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
        return this.DATEPICKER = el;
      },
      putSuccess: function(model, response, options) {
        this.updateElement('complete');
        this.Amplify.publish(this.policy_view.cid, 'success', "Saved changes!", 2000);
        return this.AssigneeList.fetch({
          success: this.assigneesFetchSuccess,
          error: this.assigneesFetchError
        });
      },
      putError: function() {
        this.updateElement('incomplete');
        return this.Amplify.publish(this.policy_view.cid, 'warning', "Could not save!", 2000);
      },
      renewalSuccess: function(resp) {
        if (resp != null) {
          resp.cid = this.cid;
          this.CHANGESET = {
            renewal: _.omit(resp.renewal, ["inspectionOrdered", "renewalReviewRequired"]),
            insuranceScore: {
              currentDisposition: resp.insuranceScore.currentDisposition
            }
          };
          this.$el.html(this.Mustache.render(tpl_ru_container, resp));
          this.removeLoader();
          this.show();
          return this.attachDatepickers();
        }
      },
      renewalError: function(resp) {
        return this.Amplify.publish(this.policy_view.cid, 'warning', "Could not retrieve renewal underwriting information: " + resp.statusText + " (" + resp.status + ")");
      }
    });
  });

}).call(this);

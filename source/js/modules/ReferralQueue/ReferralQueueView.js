// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Helpers', 'Messenger', 'modules/ReferralQueue/ReferralTaskView', 'modules/ReferralQueue/ReferralAssigneesModel', 'text!modules/ReferralQueue/templates/tpl_referral_container.html', 'text!modules/ReferralQueue/templates/tpl_manage_assignees.html'], function(BaseView, Helpers, Messenger, ReferralTaskView, ReferralAssigneesModel, tpl_container, tpl_menu_assignees) {
    var ReferralQueueView;
    return ReferralQueueView = BaseView.extend({
      PAGINATION_EL: {},
      SORT_CACHE: {},
      OWNER_STATE: '',
      events: {
        "change .referrals-pagination-page": function() {
          return this.paginateTasks(this.COLLECTION, this.PAGINATION_EL);
        },
        "change .referrals-pagination-perpage": function() {
          return this.paginateTasks(this.COLLECTION, this.PAGINATION_EL);
        },
        "click .referrals-sort-link": function(e) {
          return this.sortTasks(e, this.COLLECTION);
        },
        "click .referrals-switch li": function(e) {
          return this.toggleOwner(e, this.COLLECTION, this.PAGINATION_EL);
        },
        "click .button-manage-assignees": function(e) {
          return this.toggleManageAssignees(e);
        },
        "click .menu-confirm": function(e) {
          return this.saveAssignees(e);
        },
        "change input[type=checkbox]": function(e) {
          return this.toggleCheckbox(e);
        },
        "click .menu-cancel": function(e) {
          return this.clearAssignees(e);
        }
      },
      initialize: function(options) {
        var digest, errorCallback, ixlibrary;
        this.MODULE = options.module || false;
        this.COLLECTION = options.collection || false;
        this.PARENT_VIEW = options.view || false;
        ixlibrary = options.ixlibrary || false;
        this.COLLECTION.bind('reset', this.renderTasks, this);
        this.COLLECTION.bind('error', this.tasksError, this);
        this.el = this.PARENT_VIEW.el;
        this.$el = this.PARENT_VIEW.$el;
        if (this.MODULE !== false) {
          digest = this.MODULE.controller.user.get('digest');
          ixlibrary = "" + this.MODULE.controller.services.ixlibrary + "buckets/underwriting/objects/assignee_list.xml";
        }
        this.AssigneeList = new ReferralAssigneesModel({
          digest: digest
        });
        this.AssigneeList.url = ixlibrary;
        errorCallback = _.bind(this.renderAssigneesError, this);
        this.AssigneeList.fetch({
          error: errorCallback
        });
        this.AssigneeList.on('change', this.assigneeSuccess, this);
        return this.AssigneeList.on('fail', this.assigneeError, this);
      },
      render: function() {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        html += this.Mustache.render(tpl_container, {
          cid: this.cid,
          pagination: {}
        });
        this.$el.html(html);
        this.messenger = new Messenger(this.PARENT_VIEW, this.cid);
        this.CONTAINER = this.$el.find('table.module-referrals tbody');
        this.PAGINATION_EL = this.cachePaginationElements();
        this.toggleLoader(true);
        return this;
      },
      renderTasks: function(collection) {
        var task, _i, _len, _ref,
          _this = this;
        this.TASK_VIEWS = collection.map(function(model) {
          return new ReferralTaskView({
            model: model,
            parent_view: _this
          });
        });
        this.CONTAINER.html('');
        _ref = this.TASK_VIEWS;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          task = _ref[_i];
          this.CONTAINER.append(task.render());
        }
        this.toggleLoader();
        return this.updatePagination(collection, this.PAGINATION_EL);
      },
      tasksError: function(collection, response) {
        this.toggleLoader();
        this.Amplify.publish(this.cid, 'warning', "Could not load referrals: " + response.status + " - " + response.statusText);
        return console.log(["tasksError", collection, response]);
      },
      toggleOwner: function(e, collection, elements) {
        var $el, query;
        e.preventDefault();
        $el = $(e.currentTarget);
        query = {
          perPage: elements.per_page.val() || 25,
          page: elements.jump_to.val() || 1
        };
        if ($el.hasClass('active')) {

        } else {
          $('.referrals-switch').find('li').removeClass('active');
          $el.addClass('active');
          if ($el.find('a').attr('href') === 'allreferrals') {
            query.OwningUnderwriter = this.OWNER_STATE = '';
          } else {
            this.OWNER_STATE = this.options.owner;
          }
          this.toggleLoader(true);
          return collection.getReferrals(query);
        }
      },
      paginateTasks: function(collection, elements) {
        var query;
        query = {
          perPage: elements.per_page.val() || 25,
          page: elements.jump_to.val() || 1,
          OwningUnderwriter: this.OWNER_STATE
        };
        this.toggleLoader(true);
        return collection.getReferrals(query);
      },
      cachePaginationElements: function() {
        return {
          items: this.$el.find('.pagination-a'),
          jump_to: this.$el.find('.referrals-pagination-page'),
          per_page: this.$el.find('.referrals-pagination-perpage')
        };
      },
      updatePagination: function(collection, elements) {
        var current_page, end_position, pages, per_page, start_position, values;
        per_page = elements.per_page.val();
        if (collection.totalItems < per_page) {
          end_position = collection.totalItems;
          start_position = 1;
        } else {
          end_position = collection.page * per_page;
          start_position = end_position - per_page;
        }
        start_position = start_position === 0 ? 1 : start_position;
        elements.items.find('span').html("Items " + start_position + " - " + end_position + " of " + collection.totalItems);
        pages = _.range(1, Math.round(collection.totalItems / elements.per_page.val()));
        current_page = parseInt(collection.page, 10);
        values = _.map(pages, function(page) {
          if (page === current_page) {
            return $("<option value=\"" + page + "\" selected>" + page + "</option>");
          } else {
            return $("<option value=\"" + page + "\">" + page + "</option>");
          }
        });
        return elements.jump_to.html(values);
      },
      toggleLoader: function(bool) {
        if ($("#referrals-spinner-" + this.cid).length < 1) {
          return false;
        }
        if (bool && !(this.loader != null)) {
          if ($('html').hasClass('lt-ie9') === false) {
            this.loader = Helpers.loader("referrals-spinner-" + this.cid, 100, '#ffffff');
            this.loader.setDensity(70);
            this.loader.setFPS(48);
          }
          return $("#referrals-loader-" + this.cid).show();
        } else {
          if ((this.loader != null) && $('html').hasClass('lt-ie9') === false) {
            this.loader.kill();
            this.loader = null;
          }
          return $("#referrals-loader-" + this.cid).hide();
        }
      },
      sortTasks: function(e, collection) {
        var $el;
        e.preventDefault();
        $el = $(e.currentTarget);
        this.SORT_CACHE = {
          'sort': $el.attr('href'),
          'sortdir': $el.data('dir')
        };
        this.remove_indicators();
        collection.sortTasks(this.SORT_CACHE.sort, this.SORT_CACHE.sortdir);
        if ($el.data('dir') === 'asc') {
          $el.data('dir', 'desc');
          return this.swap_indicator($el, '&#9660;');
        } else {
          $el.data('dir', 'asc');
          return this.swap_indicator($el, '&#9650;');
        }
      },
      swap_indicator: function(el, char) {
        var reg, text;
        text = el.html();
        reg = /▲|▼/gi;
        if (text.match('▲') || text.match('▼')) {
          text = text.replace(reg, char);
          return el.html(text);
        } else {
          return el.html(text + (" " + char));
        }
      },
      remove_indicators: function() {
        return $('.referrals-sort-link').each(function(index, el) {
          var reg;
          el = $(el);
          reg = /▲|▼/gi;
          return el.html(el.html().replace(reg, ''));
        });
      },
      toggleManageAssignees: function(e) {
        var assignees;
        e.preventDefault();
        assignees = this.AssigneeList.parseBooleans(this.AssigneeList.get('json').Assignee);
        return this.Modal.attach_menu($(e.currentTarget), '.rq-menus', tpl_menu_assignees, {
          assignees: assignees
        });
      },
      renderAssigneesError: function(model, xhr, options) {
        return this.Amplify.publish(this.cid, 'warning', "Could not load assignees: " + xhr.status + " - " + xhr.statusText);
      },
      saveAssignees: function(e) {
        var json, merged, values;
        e.preventDefault();
        this.assigneeLoader();
        values = [];
        json = this.AssigneeList.get('json').Assignee;
        this.$el.find('input[type=checkbox]').each(function(index, val) {
          var name;
          name = $(val).attr('name');
          if (name.indexOf('newbiz_') > -1) {
            return values.push({
              identity: name.replace(/newbiz_/gi, ''),
              new_business: $(val).val()
            });
          } else {
            return values.push({
              identity: name.replace(/renewal_/gi, ''),
              renewals: $(val).val()
            });
          }
        });
        merged = _.map(json, function(assignee) {
          var items;
          items = _.where(values, {
            identity: assignee.identity
          });
          if (items.length > 1) {
            return _.extend(assignee, items[0], items[1]);
          } else {
            return _.extend(assignee, items[0]);
          }
        });
        this.AssigneeList.set('json', {
          Assignee: merged
        });
        return this.AssigneeList.putList();
      },
      clearAssignees: function(e) {
        e.preventDefault();
        return this.Modal.removeMenu();
      },
      assigneeLoader: function() {
        return this.$el.find('.menu-status').show().html('<strong class="menu-loading">Saving changes&hellip;</strong>');
      },
      assigneeSuccess: function(model) {
        return this.$el.find('.menu-status').show().html('<strong class="menu-success">Assignee List saved!</strong>').delay(2000).fadeOut('slow');
      },
      assigneeError: function(msg) {
        return this.$el.find('.menu-status').show().html("<strong class=\"menu-error\">Error saving: " + msg + "</strong>").delay(3000).fadeOut('slow');
      },
      toggleCheckbox: function(e) {
        var $cb;
        $cb = $(e.currentTarget);
        if ($cb.attr('checked')) {
          $cb.val('true');
        } else {
          $cb.val('false');
        }
        return $cb;
      }
    });
  });

}).call(this);

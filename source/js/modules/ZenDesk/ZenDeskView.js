// Generated by CoffeeScript 1.7.1
(function() {
  define(['BaseView', 'Messenger', 'text!modules/ZenDesk/templates/tpl_zendesk_container.html'], function(BaseView, Messenger, tpl_zd_container) {
    var ZenDeskView;
    return ZenDeskView = BaseView.extend({
      initialize: function(options) {
        _.bindAll(this, 'fetchSuccess');
        this.policy = options.policy;
        this.policy_view = options.policy_view;
        this.shim = $("<div id=\"zd_shim_" + this.cid + "\" class=\"zd-shim\">\n  <div id=\"zd_loader_" + this.cid + "\" class=\"zd-loader\"></div>\n</div>");
        this.$el.append(this.shim);
        this.attach_loader();
        return this;
      },
      fetch: function() {
        var policyQuery;
        policyQuery = this.policy.getPolicyId();
        policyQuery = policyQuery.substring(0, policyQuery.length - 2);
        return this.fetch_tickets(policyQuery);
      },
      render: function() {
        this.remove_loader();
        return this.shim.html(this.Mustache.render(tpl_zd_container, {
          results: this.tickets.results
        }));
      },
      attach_loader: function() {
        if ($("#zd_loader_" + this.cid).length > 0) {
          this.loader = this.Helpers.loader("zd_loader_" + this.cid, 80, '#696969');
          return this.loader.setFPS(48);
        }
      },
      remove_loader: function() {
        if (this.loader != null) {
          this.loader.kill();
          return $("#zd_loader_" + this.cid).hide();
        }
      },
      fetch_tickets: function(query, onSuccess, onError) {
        onSuccess = onSuccess != null ? onSuccess : this.fetchSuccess;
        onError = onError != null ? onError : this.fetchError;
        if (_.isEmpty(query)) {
          this.Amplify.publish(this.policy_view.cid, 'warning', "This policy is unable to search the ZenDesk API at this time. Sorry.");
          return false;
        } else {
          $.ajax({
            url: this.policy_view.services.zendesk,
            type: 'GET',
            contentType: 'application/json',
            data: {
              query: query,
              sort_order: 'desc',
              sort_by: 'created_at'
            },
            dataType: 'json',
            success: onSuccess,
            error: onError
          });
        }
        return this;
      },
      fetchSuccess: function(data, textStatus, jqXHR) {
        this.tickets = this.processResults(data);
        this.render();
        this.policy_view.resize_view(this.$el);
        return this.tickets;
      },
      fetchError: function(jqXHR, textStatus, errorThrown) {
        this.Amplify.publish(this.policy_view.cid, 'warning', "This policy is unable to access the ZenDesk API at this time. Message: " + textStatus);
        this.remove_loader();
        return false;
      },
      processResults: function(tickets) {
        var object;
        if ((tickets != null) && _.has(tickets, 'results')) {
          object = $.extend(true, {}, tickets);
          object.results = _.map(object.results, function(result) {
            _.each(['created_at', 'updated_at'], function(field) {
              return result[field] = moment(result[field]).format('YYYY-MM-DD HH:mm');
            });
            return result;
          });
          return object;
        } else {
          return tickets;
        }
      }
    });
  });

}).call(this);

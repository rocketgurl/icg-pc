// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel'], function(BaseModel) {
    var ReferralAssigneesModel;
    return ReferralAssigneesModel = BaseModel.extend({
      initialize: function() {
        return this.use_cripple();
      },
      getRenewals: function() {
        var json;
        json = this.parseBooleans(this.get('json').Assignee);
        return _.where(json, {
          renewals: true
        });
      },
      getNewBusiness: function() {
        var json;
        json = this.parseBooleans(this.get('json').Assignee);
        return _.where(json, {
          new_business: true
        });
      },
      putList: function(success, error) {
        var xml,
          _this = this;
        xml = this.json2xml();
        if (success == null) {
          success = this.putSuccess;
        }
        if (error == null) {
          error = this.putError;
        }
        if (typeof xml !== 'string') {
          xml = this.Helpers.XMLToString(xml);
        }
        return $.ajax({
          url: this.url,
          type: 'PUT',
          dataType: 'xml',
          contentType: 'application/xml',
          data: xml,
          headers: {
            'Authorization': "Basic " + (this.get('digest')),
            'X-Authorization': "Basic " + (this.get('digest')),
            'X-Crippled-Client': "yes",
            'X-Rest-Method': "PUT"
          },
          success: function(data, textStatus, jqXHR) {
            if (success != null) {
              return success.apply(_this, [_this, data, textStatus, jqXHR]);
            }
          },
          error: function(jqXHR, textStatus, errorThrown) {
            if (error != null) {
              return error.apply(_this, [_this, jqXHR, textStatus, errorThrown]);
            }
          }
        });
      },
      putSuccess: function(model, data, textStatus, xhr) {
        var key, parsed_data, val;
        if (xhr.getResponseHeader('X-True-Status-Code') !== '200') {
          model.trigger('fail', xhr.getResponseHeader('X-True-Status-Text'));
          return model;
        }
        parsed_data = model.parse(data, xhr);
        for (key in parsed_data) {
          val = parsed_data[key];
          model.attributes[key] = val;
        }
        model.trigger('change', model);
        return model;
      },
      putError: function(model, xhr, textStatus, errorThrown) {
        return model.trigger('fail', errorThrown);
      },
      parseBooleans: function(arr) {
        return arr = _.map(arr, function(item) {
          var new_business, renewals;
          new_business = renewals = false;
          if (_.has(item, 'new_business')) {
            new_business = JSON.parse(item.new_business);
          }
          if (_.has(item, 'renewals')) {
            renewals = JSON.parse(item.renewals);
          }
          return {
            identity: item.identity,
            active: JSON.parse(item.active),
            new_business: new_business,
            renewals: renewals
          };
        });
      },
      json2xml: function() {
        var assignee, json, nodes, _i, _len, _ref, _ref1, _ref2;
        json = this.get('json');
        nodes = "";
        _ref = json.Assignee;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          assignee = _ref[_i];
          if ((_ref1 = assignee.new_business) == null) {
            assignee.new_business = false;
          }
          if ((_ref2 = assignee.renewals) == null) {
            assignee.renewals = false;
          }
          nodes += "<Assignee identity=\"" + assignee.identity + "\" active=\"" + assignee.active + "\" new_business=\"" + assignee.new_business + "\" renewals=\"" + assignee.renewals + "\" />";
        }
        return "<AssigneeList>" + nodes + "</AssigneeList>";
      }
    });
  });

}).call(this);

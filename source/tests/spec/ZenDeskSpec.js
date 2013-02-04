define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "modules/ZenDesk/ZenDeskView",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    SearchContextCollection,
    PolicyModel,
    ZenDeskView,
    amplify, 
    CanvasLoader
) {

describe('ZenDesk Module', function () {

  var policy = new PolicyModel({
    id      : '71049-active.xml',
    urlRoot : 'mocks/',
    digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
  });

  var options = {
    $el         : $('<div />'),
    policy      : policy,
    policy_view : {
      controller : {
        services : {
          pxcentral : 'https://test.policycentral.dev/pxcentral/api/rest/v1/',
          ixlibrary : 'https://test.policycentral.dev/ixlibrary/api/sdo/rest/v1/',
          zendesk   : 'https://test.policycentral.dev/zendesk'
        }
      }
    }
  }

  options.policy_view.services = options.policy_view.controller.services;

  var view = new ZenDeskView(options);

  var fetch_result;

  // DRY waitsFor function to fetch some results from mocks
  var getResults = function(){
    var _this = this;
    var success = function(data, textStatus, jqXHR) {
      _this.fetch_result = data;
    };
    var fail = function(jqXHR, textStatus, errorThrown) {
      console.log([jqXHR, textStatus, errorThrown]);
      return false;
    }

    view.fetch_tickets('4727', success, fail);

    if (_this.fetch_result) { 
      fetch_result = _this.fetch_result; 
      return true; 
    }
  }

  it ('ZenDesk is a Backbone.View object', function() {
    expect(view).toEqual(jasmine.any(Object));
    expect(view instanceof Backbone.View).toBe(true);
  });

  it ('ZenDesk.fetch_tickets returns false if not a string', function() {
    var result = view.fetch_tickets(1123123);
    expect(result).toBe(false);
  });

  it ('ZenDesk.fetch_tickets returns false if empty', function() {
    var result = view.fetch_tickets();
    expect(result).toBe(false);
  });

  it ('ZenDesk.fetch_tickets returns json', function() {
    waitsFor(getResults, "ZenDesk should receive results", 1000);
    runs(function(){
      expect(fetch_result).toEqual(jasmine.any(Object));
    });
  });

  it ('ZenDesk can process dates in retured JSON', function() {
    waitsFor(getResults, "ZenDesk should receive results", 1000);
    runs(function(){
      var processed = view.processResults(fetch_result);
      var raw = ['2012-10-04T19:57:43Z','2012-10-09T22:42:59Z'];
      var pro = ['2012-10-04 15:57', '2012-10-09 18:42']
      _.each(['created_at','updated_at'], function(field, index) {
        expect(fetch_result.results[0][field]).toEqual(raw[index]);
        expect(processed.results[0][field]).toEqual(pro[index]);
      })
    });
  });

});
});
define([
  "jquery",
  "underscore",
  "WorkspaceController",
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "modules/RenewalUnderwriting/RenewalUnderwritingModel",
  "modules/RenewalUnderwriting/RenewalUnderwritingView",
  "amplify",
  "loader"],
  function(
    $,
    _,
    WorkspaceController,
    SearchContextCollection,
    PolicyModel,
    RenewalUnderwritingModel,
    RenewalUnderwritingView,
    amplify,
    CanvasLoader
) {


  // POLICY MODEL
  describe('Renewal Underwriting Module', function () {

    var endorse_json = {}

    var view;

    var policy_A = new PolicyModel({
      id      : '71049-active.xml',
      urlRoot : 'mocks/',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    });

    var policy_B = new PolicyModel({
      id      : '29-pending.xml',
      urlRoot : 'mocks/',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    });

    var policy_C = new PolicyModel({
      id      : '30-cancelled.xml',
      urlRoot : 'mocks/',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    });

    var options = {
        $el         : $('<div />'),
        policy      : policy_A,
        policy_view : {
          resize_workspace : function() { return null },
          controller : {
              services : {
                pxcentral : 'https://test.policycentral.dev/pxcentral/api/rest/v1/',
                ixlibrary : 'https://test.policycentral.dev/ixlibrary/api/sdo/rest/v1/'
              },
              user : {
                id : 'thurston.howell@arc90.com'
              }
          }
        }
      }

    // Handy list of policy objects
    var policies = [policy_A, policy_B, policy_C];

    var ajax_count = 0;

    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        _.each(policies, function(policy){
          policy.fetch({
            success : callback
          });
        });
        waitsFor(function() {
          view = new RenewalUnderwritingView(options);
          view.RenewalModel.set('urlRoot', options.policy_view.controller.services.pxcentral);
          view.RenewalModel.id = '71049';
          view.render();
          return callback.callCount > 2;
        }, "Timeout BOOM!", 1000)
      }
      ajax_count++;
    });

    // Policies are objects and Backbone Models
    it ('RenewalUnderwritingModels have a url', function () {
      _.each(policies, function(policy, index){
        var model = new RenewalUnderwritingModel({
          id      : policy.id,
          urlRoot : policy.get('urlRoot'),
          digest  : policy.get('digest')
        });
        var ids = ['71049-active.xml', '29-pending.xml', '30-cancelled.xml'];
        var urls = [
          'mocks/policies/71049-active.xml/renewalunderwriting',
          'mocks/policies/29-pending.xml/renewalunderwriting',
          'mocks/policies/30-cancelled.xml/renewalunderwriting'
        ];
        expect(model).toEqual(jasmine.any(Object));
        expect(model instanceof Backbone.Model).toBe(true);
        expect(model.id).toEqual(ids[index]);
        expect(model.url()).toEqual(urls[index]);
      })
    });

    it ('RenewalUnderwritingViews can be instantiated', function() {
      expect(view).toEqual(jasmine.any(Object));
      expect(view instanceof Backbone.View).toBe(true);
    });

    it ('RenewalUnderwritingViews has an AssigneeList model', function() {
      expect(view.AssigneeList).toEqual(jasmine.any(Object));
      expect(view.AssigneeList instanceof Backbone.Model).toBe(true);
    });

    it ('RenewalUnderwritingViews has a RenewalUnderwritingModel', function() {
      expect(view.RenewalModel).toEqual(jasmine.any(Object));
      expect(view.RenewalModel instanceof Backbone.Model).toBe(true);
    });

    it ('RenewalUnderwritingViews can select assignee and put a fragment to the server', function() {
      var _success, _error, _changeset;
      waitsFor(function() {
        if (_.isEmpty(view.changeset) === false) {
          _success = function(model, response, options) {
            console.log(model, response)
            if (response.status === 'OK') {
              _changeset = model;
            }
          }
          _error = function(model, xhr, options) {
            console.log(['ERROR', xhr]);
          }
          _success        = _.bind(_success, this);
          _error          = _.bind(_error, this);
          view.putSuccess = _success
          view.putError   = _error

          console.log(view.processChange('renewal.assignedTo', 'art.greitzer@cru360.com'));

          if (_changeset) {
            return true;
          }
        }
      }, "view should have a changeset", 1000);

      runs(function(){
        expect(view.changeset.renewal.assignedTo).toBe('art.greitzer@cru360.com');
        expect(_changeset.get('renewal').assignedTo).toBe('art.greitzer@cru360.com');
      });
    });

    it ('RenewalUnderwritingViews can select change reviewPeriod and put a fragment to the server', function() {
      var _success, _error, _changeset;
      waitsFor(function() {
        if (!_.isEmpty(view.changeset)) {
          _success = function(model, response, options) {
            if (response.status === 'OK') {
              _changeset = model;
            }
          }
          _error = function(model, xhr, options) {
            console.log(['ERROR', xhr]);
          }
          _success        = _.bind(_success, this);
          _error          = _.bind(_error, this);
          view.putSuccess = _success
          view.putError   = _error

          view.processChange('renewal.reviewPeriod', '10-15-2013');

          if (_changeset) {
            return true;
          }
        }
      }, "view should have a changeset", 1000);

      runs(function(){
        expect(view.changeset.renewal.reviewPeriod).toBe('10-15-2013');
        expect(_changeset.get('renewal').reviewPeriod).toBe('10-15-2013');
      });
    });

    it ('RenewalUnderwritingViews can select change reviewDeadline and put a fragment to the server', function() {
      var _success, _error, _changeset;
      waitsFor(function() {
        if (!_.isEmpty(view.changeset)) {
          _success = function(model, response, options) {
            if (response.status === 'OK') {
              _changeset = model;
            }
          }
          _error = function(model, xhr, options) {
            console.log(['ERROR', xhr]);
          }
          _success        = _.bind(_success, this);
          _error          = _.bind(_error, this);
          view.putSuccess = _success
          view.putError   = _error

          view.processChange('renewal.reviewDeadline', '10-15-2013');

          if (_changeset) {
            return true;
          }
        }
      }, "view should have a changeset", 1000);

      runs(function(){
        expect(view.changeset.renewal.reviewDeadline).toBe('10-15-2013');
        expect(_changeset.get('renewal').reviewDeadline).toBe('10-15-2013');
      });
    });

    it ('RenewalUnderwritingViews can change renewal.reason and put a fragment to the server', function() {
      var _success, _error, _changeset;
      waitsFor(function() {
        if (!_.isEmpty(view.changeset)) {
          _success = function(model, response, options) {
            if (response.status === 'OK') {
              _changeset = model;
            }
          }
          _error = function(model, xhr, options) {
            console.log(['ERROR', xhr]);
          }
          _success        = _.bind(_success, this);
          _error          = _.bind(_error, this);
          view.putSuccess = _success
          view.putError   = _error

          view.processChange('renewal.reason', 'I got a letter from the government the other day, opened and read it, said they were suckers');

          if (_changeset) {
            return true;
          }
        }
      }, "view should have a changeset", 1000);

      runs(function(){
        expect(view.changeset.renewal.reason).toBe('I got a letter from the government the other day, opened and read it, said they were suckers');
        expect(_changeset.get('renewal').reason).toBe('I got a letter from the government the other day, opened and read it, said they were suckers');
      });
    });

  });
});
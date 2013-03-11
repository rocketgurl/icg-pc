define([
  "jquery",
  "underscore",
  "WorkspaceController",
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "modules/RenewalUnderwriting/RenewalUnderwritingModel",
  "modules/RenewalUnderwriting/RenewalUnderwritingView",
  "modules/RenewalUnderwriting/RenewalVocabModel",
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
    RenewalVocabModel,
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
                pxcentral : '/pxcentral/api/rest/v1/',
                ixlibrary : '/ixlibrary/api/sdo/rest/v1/',
                ixvocab   : '/ixvocab/api/rest/v1/'
              },
              user : {
                id : 'thurston.howell@arc90.com'
              }
          }
        }
      }

    // LocalStorage cache for Vocab terms
    var VocabDispositions = new RenewalVocabModel({
      id       : 'Disposition',
      url_root : '/ixvocab/api/rest/v1/'
    });
    var VocabReasons = new RenewalVocabModel({
      id       : 'NonRenewalReasonCode',
      url_root : '/ixvocab/api/rest/v1/'
    });
    var VocabData = {
          dispositions: [
            {
              value: 'new',
              label: 'New'
            }, {
              value: 'pending',
              label: 'Pending'
            }, {
              value: 'renew no-action',
              label: 'Renew with no action'
            }, {
              value: 'non-renew',
              label: 'Non-renew'
            }, {
              value: 'withdrawn',
              label: 'Withdrawn'
            }, {
              value: 'conditional renew',
              label: 'Conditional renew'
            }
          ],
          reasons: [
            {
              value: "1",
              label: "Insured request"
            }, {
              value: "2",
              label: "Nonpayment of premium"
            }, {
              value: "3",
              label: "Insured convicted of crime"
            }, {
              value: "4",
              label: "Discovery of fraud or material misrepresentation"
            }, {
              value: "5",
              label: "Discovery of willful or reckless acts of omissions"
            }, {
              value: "6",
              label: "Physical changes in the property "
            }, {
              value: "7",
              label: "Increase in liability hazards beyond what is normally accepted"
            }, {
              value: "8",
              label: "Increase in property hazards beyond what is normally accepted"
            }, {
              value: "9",
              label: "Overexposed in area where risk is located"
            }, {
              value: "10",
              label: "Change in occupancy status"
            }, {
              value: "11",
              label: "Other underwriting reasons"
            }, {
              value: "12",
              label: "Cancel/rewrite"
            }, {
              value: "13",
              label: "Change in ownership"
            }, {
              value: "14",
              label: "Missing required documentation"
            }, {
              value: "15",
              label: "Insured Request - Short Rate"
            }, {
              value: "16",
              label: "Nonpayment of Premium - Flat"
            }
          ]
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

    it ('RenewalVocabModel is a Backbone.Model', function() {
      expect(VocabDispositions).toEqual(jasmine.any(Object));
      expect(VocabDispositions instanceof Backbone.Model).toBe(true);
    });

    it ('RenewalVocabModels have ids', function() {
      expect(VocabDispositions.id).toEqual('Disposition');
      expect(VocabReasons.id).toEqual('NonRenewalReasonCode');
    });

    it ('RenewalVocabModels can save data', function() {
      VocabDispositions.set('data', VocabData.dispositions).save()
      expect(VocabDispositions.get('data')).toEqual(VocabData.dispositions);
    });

    it ('RenewalVocabModels can retrieve data from localStorage', function() {
      test = new RenewalVocabModel({ id : 'Disposition' })
      test.fetch()
      expect(test.get('data')).toEqual(VocabData.dispositions);
    });

    it ('RenewalVocabModels have URLs', function() {
      var disposition_url = VocabDispositions.url()
      var reason_url = VocabReasons.url()
      expect(disposition_url).toEqual('/ixvocab/api/rest/v1/Term/Disposition');
      expect(reason_url).toEqual('/ixvocab/api/rest/v1/Term/NonRenewalReasonCode');
    });

    it ('RenewalVocabModels can fetch XML from ixVocab', function() {
      // VocabDispositions.fetchIxVocab()
      // var reason_url = VocabReasons.url()
      // expect(disposition_url).toEqual('./ixvocab/api/rest/v1/Term/Disposition');
      // expect(reason_url).toEqual('./ixvocab/api/rest/v1/Term/NonRenewalReasonCode');
    });

  });
});
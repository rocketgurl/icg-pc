define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    SearchContextCollection,
    PolicyModel,
    amplify, 
    CanvasLoader
) {


  // POLICY MODEL
  describe('PolicyModel', function () {

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
          return callback.callCount > 2;
        }, "Timeout BOOM!", 1000)
      }
      ajax_count++;
    })

    // Policies are objects and Backbone Models
    it ('is an object', function () {
      _.each(policies, function(policy){
        expect(policy).toEqual(jasmine.any(Object));
        expect(policy instanceof Backbone.Model).toBe(true);
      })
    });

    // Policies have XML and JSON documents
    it ('has a policy document', function () {
      runs(function(){
        _.each(policies, function(policy){
          // has an XML document
          expect(policy.get('document')).not.toBeNull();
          expect(policy.get('document')).toEqual(jasmine.any(Object));

          // has as JSON document
          expect(policy.get('json')).not.toBeNull();
          expect(policy.get('json')).toEqual(jasmine.any(Object));
          expect(policy.get('json').schemaVersion).toEqual("2.6");
          expect(policy.get('raw_xml')).toEqual(jasmine.any(String));
        })
      });
    });

    it ('has a pxServerIndex', function () {
      runs(function(){
        var nums = ['71049', '29', '30']
        _.each(policies, function(policy, index){
          expect(policy.get_pxServerIndex()).toBe(nums[index]);
        })
      });
    });

    it ('has a policy holder', function () {
      runs(function(){
        var names = ['TEST, DOCUMENT','Abrams, John','Abrams, John']
        _.each(policies, function(policy, index){
          expect(policy.get_policy_holder()).toBe(names[index]);
        })
      });
    });

    // Check the policy period dates of the policies
    it ('has a policy period', function () {
      runs(function(){

        var dates = [
          '2012-06-28 - 2013-06-28',
          '2010-10-29 - 2011-10-29',
          '2010-10-29 - 2011-10-29'
        ]

        _.each(policies, function(policy, index){
          expect(policy.get_policy_period()).toBe(dates[index]);
        });
      });
    });

    it ('has an IPM header', function () {
      runs(function(){

        var headers = [
          { id : 'SCS007104900', product : 'HO3', holder : 'TEST, DOCUMENT', state : 'ACTIVEPOLICY', period : '2012-06-28 - 2013-06-28', carrier : 'Acceptance Casualty Insurance Company' },
          { carrier: "Smart Insurance Company", holder: "Abrams, John", id: "NYH000002900", period: "2010-10-29 - 2011-10-29", product: "HO3", state: "ACTIVEPOLICY" },
          { carrier: "Smart Insurance Company", holder: "Abrams, John", id: "NYH000002900", period: "2010-10-29 - 2011-10-29", product: "HO3", state: "CANCELLEDPOLICY" },
        ];

        _.each(policies, function(policy, index){
          expect(policy.get_ipm_header()).toEqual(jasmine.any(Object));
          expect(policy.get_ipm_header()).toEqual(headers[index]);
        });

      });
    });

    it ('has a system of record', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          expect(policy.getSystemOfRecord()).toBe('mxServer');
        });
      });
    });

    it ('is an IPM policy', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          expect(policy.isIPM()).toBe(true);
        });        
      });
    });


    it ('can get a policy state : getState()', function () {

      var states = ['ACTIVEPOLICY','ACTIVEPOLICY',{ effectiveDate : '2011-01-15T00:00:00-04:00', reasonCode : '5', text : 'CANCELLEDPOLICY' }];
      
      runs(function(){
        _.each(policies, function(policy, index){
          expect(policy.getState()).toEqual(states[index]);
        });        
      });

      runs(function(){
        expect(policy_C.getState().effectiveDate).toEqual('2011-01-15T00:00:00-04:00');
      });
    });


    it ('can see if a policy is cancelled : isCancelled()', function () {
      runs(function(){
        expect(policy_A.isCancelled()).toBe(false);
      });
      runs(function(){
        expect(policy_B.isCancelled()).toBe(false);
      });
      runs(function(){
        expect(policy_C.isCancelled()).toBe(true);
      });
    });



  });

});
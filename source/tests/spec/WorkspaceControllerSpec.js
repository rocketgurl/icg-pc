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
  
  // WORKSPACE CONTROLLER
  describe('WorkspaceController', function () {

    // Setup ENV
    beforeEach(function(){
      WorkspaceController.services = {
        ixdirectory: 'http://policycentral.dev/ixdirectory/api/rest/v2/',
        pxcentral: 'http://policycentral.dev/pxcentral/api/rest/v1/',
        ixlibrary: 'http://policycentral.dev/ixlibrary/api/sdo/rest/v1/',
        ixdoc: 'http://policycentral.dev/ixdoc/api/rest/v2/',
        ixadmin: 'http://policycentral.dev/config/ics/staging/ixadmin'
      };
    });

    it ('is an object', function () {
      expect(WorkspaceController).toEqual(jasmine.any(Object));
    });

    // STACK FUNCTIONS
    describe('WorkspaceController maintains a stack of apps', function () {
      var app_a = {
        app : {
          app : 'AppA'
        }
      };
      var app_b = {
        app : {
          app : 'AppB'
        }
      }

      it ('Adds apps to the stack', function () {
        var add = WorkspaceController.stack_add(app_a);
        expect(add).toBe(1);
        var add2 = WorkspaceController.stack_add(app_b);
        expect(add2).toBe(2);
      });

      it ("Won't add duplicate AppA to the stack", function () {
        var add = WorkspaceController.stack_add(app_a);
        expect(add).toBe(undefined);
        expect(WorkspaceController.workspace_stack.length).toBe(2);
        expect(WorkspaceController.workspace_stack[1]).toBe(app_b);
      });

      it ("Can get AppB from the stack", function () {
        var B = WorkspaceController.stack_get(app_b.app.app);
        expect(B).toBe(app_b);
      });

      it ('Can remove an AppA from the stack', function () {
        var remove = WorkspaceController.stack_remove(app_a);
        expect(remove).toBe(undefined);
        expect(WorkspaceController.workspace_stack.length).toBe(1);
        expect(WorkspaceController.workspace_stack[0]).toBe(app_b);
      });

      it ('Can clear the whole stack in one go', function () {
        WorkspaceController.stack_add(app_a);
        WorkspaceController.check_workspace_state();
        var clear = WorkspaceController.stack_clear();
        expect(clear).toEqual(jasmine.any(Array));
        expect(clear.length).toBe(0);
        expect(WorkspaceController.workspace_stack.length).toBe(0);
      });      

    });

    describe('WorkspaceController uses localStorage and WorkspaceStateModels', function () {

      var data = {
        "0d03dd5e-481a-79e7-15a4-c577ae11214d": {
            "workspace": {
                "env": "staging",
                "business": "cru",
                "context": "crunyho",
                "app": "policies_crunyho",
                "module": null,
                "params": null
            },
            "id": "0d03dd5e-481a-79e7-15a4-c577ae11214d"
        }
      }

      it ('check_workspace_state checks localStorage: no previous data', function () {
        // clear localStorage
        amplify.store('ics_policy_central', null);
        // check state
        var state = WorkspaceController.check_workspace_state();
        expect(state).toBe(false);
      });

      it ('check_workspace_state checks localStorage: has previous data', function () {
        // load localStorage
        amplify.store('ics_policy_central', data);
        // check state
        var state = WorkspaceController.check_workspace_state();
        expect(state).toBe(true);
        expect(WorkspaceController.workspace_state.id).toBe('0d03dd5e-481a-79e7-15a4-c577ae11214d');
      });

      it ('previous data is id# 0d03dd5e-481a-79e7-15a4-c577ae11214d', function () {
        // load localStorage
        amplify.store('ics_policy_central', data);
        // check id
        var state = WorkspaceController.check_workspace_state();
        expect(WorkspaceController.workspace_state.id).toBe('0d03dd5e-481a-79e7-15a4-c577ae11214d');
      });

    });

    describe('WorkspaceController can check cookies', function () {

      it ('has a cookie', function () {
        var cookie = WorkspaceController.check_cookie_identity();
        expect(cookie).toBe(true);
      });     

    });

    describe('WorkspaceController saves searches in localStorage', function () {

      // it ('has a saved search', function () {
      //   console.log(WorkspaceController);
      //   var collection = WorkspaceController.setup_search_storage();
      //   expect(collection).toEqual(jasmine.any(Object));
      //   expect(collection.controller).toBe(WorkspaceController);
      //   console.log(collection)
      // });     

    });

  });

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
        policy_A.fetch({
          success : callback
        });
        policy_B.fetch({
          success : callback
        });
        policy_C.fetch({
          success : callback
        });
        waitsFor(function() {
          ajax_count++;
          return callback.callCount > 2;
        }, "Timeout BOOM!", 1000)
      }
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
        expect(policy_A.get_pxServerIndex()).toBe('71049');
        expect(policy_B.get_pxServerIndex()).toBe('29');
        expect(policy_C.get_pxServerIndex()).toBe('30');
      });
    });

    it ('has a policy holder', function () {
      runs(function(){
        expect(policy_A.get_policy_holder()).toBe('TEST, DOCUMENT');
        expect(policy_B.get_policy_holder()).toBe('Abrams, John');
        expect(policy_C.get_policy_holder()).toBe('Abrams, John');
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

    it ('is not an IPM policy', function () {
      runs(function(){

        _.each(policies, function(policy, index){
          expect(policy.isIPM()).toBe(true);
        });

        
      });
    });

  });

})
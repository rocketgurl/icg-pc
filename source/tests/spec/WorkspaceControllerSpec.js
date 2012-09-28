define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/SearchContextCollection",
  "modules/PolicyModel",
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
        ixdirectory: 'http://policycentral.src/ixdirectory/api/rest/v2/',
        pxcentral: 'http://policycentral.src/pxcentral/api/rest/v1/',
        ixlibrary: 'http://policycentral.src/ixlibrary/api/sdo/rest/v1/',
        ixdoc: 'http://policycentral.src/ixdoc/api/rest/v2/',
        ixadmin: 'http://policycentral.src/config/ics/staging/ixadmin'
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

    var policy = new PolicyModel({
      id      : 'CRU4Q-71064',
      urlRoot : 'https://policycentral.src/pxcentral/api/rest/v1/',
      digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
    });

    var ajax_count = 0;

    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        policy.fetch({
          success : callback
        });
        waitsFor(function() {
          ajax_count++;
          return callback.callCount > 0;
        }, "Timeout BOOM!", 10000)
      }
    })

    it ('is an object', function () {
      expect(policy).toEqual(jasmine.any(Object));
    });

    it ('has a URL', function () {
      runs(function(){
        expect(policy.url()).toBe('https://policycentral.src/pxcentral/api/rest/v1/policies/CRU4Q-71064');
      });
    });

    it ('has a policy document', function () {
      runs(function(){
        expect(policy.get('document')).not.toBeNull();
        expect(policy.get('document')).toEqual(jasmine.any(Object));
      });
    });

    it ('has a pxServerIndex', function () {
      runs(function(){
        expect(policy.get_pxServerIndex()).toBe('71064');
      });
    });

    it ('has a poliy holder', function () {
      runs(function(){
        expect(policy.get_policy_holder()).toBe('TEST, CHRIS');
      });
    });

    it ('has a poliy period', function () {
      runs(function(){
        expect(policy.get_policy_period()).toBe('2012-06-04 - 2013-06-04');
      });
    });

    it ('has an ipm header', function () {
      runs(function(){
        console.log(policy.get_ipm_header());
        var ipm_header = {
          carrier : "Acceptance Casualty Insurance Company",
          holder  : "TEST, CHRIS",
          id      : "SCH007106400",
          period  : "2012-06-04 - 2013-06-04",
          product : "HO3",
          state   : "ACTIVEPOLICY"
        }
        expect(policy.get_ipm_header()).toEqual(jasmine.any(Object));
        expect(policy.get_ipm_header()).toEqual(ipm_header);
      });
    });

    it ('has a system of record', function () {
      runs(function(){
        expect(policy.getSystemOfRecord()).toBe('pxServer');
      });
    });

    it ('is not an IPM policy', function () {
      runs(function(){
        expect(policy.isIPM()).toBe(false);
      });
    });

  });

})
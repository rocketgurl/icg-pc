define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/Search/SearchContextCollection",
  "modules/Policy/PolicyModel",
  "modules/ReferralQueue/ReferralTaskCollection",
  "modules/ReferralQueue/ReferralQueueView",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    SearchContextCollection,
    PolicyModel,
    ReferralTaskCollection,
    ReferralQueueView,
    amplify, 
    CanvasLoader
) {
  
  // WORKSPACE CONTROLLER
  describe('WorkspaceController', function () {

    // Setup ENV
    beforeEach(function(){
      WorkspaceController.services = {
        ixdirectory: 'https://policycentral.dev/ixdirectory/api/rest/v2/',
        pxcentral: 'https://policycentral.dev/pxcentral/api/rest/v1/',
        ixlibrary: 'https://policycentral.dev/ixlibrary/api/sdo/rest/v1/',
        ixdoc: 'https://policycentral.dev/ixdoc/api/rest/v2/',
        ixadmin: 'https://policycentral.dev/config/ics/staging/ixadmin'
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


})
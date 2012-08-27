define(["jquery", "underscore", "WorkspaceController", "amplify", "loader"], function($, _, WorkspaceController, amplify, CanvasLoader) {
  
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

      it ('Can remove an AppA from the stack', function () {
        var remove = WorkspaceController.stack_remove(app_a);
        expect(remove).toBe(undefined);
        expect(WorkspaceController.workspace_stack.length).toBe(1);
        expect(WorkspaceController.workspace_stack[0]).toBe(app_b);
      });

      it ('Can clear the whole stack in one go and save it on the model', function () {
        WorkspaceController.stack_add(app_a);
        WorkspaceController.check_workspace_state();
        var clear = WorkspaceController.stack_clear();
        expect(clear).toEqual(jasmine.any(Object));
        expect(clear.attributes.apps.length).toBe(0);
        expect(WorkspaceController.workspace_stack.length).toBe(0);
      });      

    });

  });

})
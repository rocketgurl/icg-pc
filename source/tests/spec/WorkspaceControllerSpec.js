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

    it ('can check cookies', function () {
      console.log(WorkspaceController.check_cookie_identity());
    });

  });

})
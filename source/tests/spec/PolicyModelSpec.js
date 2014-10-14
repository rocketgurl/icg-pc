define([
  'modules/Policy/PolicyModel'
], function (PolicyModel) {

  // POLICY MODEL
  describe('PolicyModel', function () {

    // Policies are objects and Backbone Models
    it ('should be a Constructor', function () {
      expect(PolicyModel).toEqual(jasmine.any(Function));
    });

  });

});
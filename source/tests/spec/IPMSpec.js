define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/IPM/IPMModule",
  "modules/IPM/IPMView",
  "modules/IPM/IPMActionView",
  "modules/Policy/PolicyModel",
  "amplify",
  "loader"], 
  function(
    $, 
    _, 
    WorkspaceController, 
    IPMModule,
    IPMView,
    IPMActionView,
    PolicyModel,
    amplify, 
    CanvasLoader
) {

// Load up a Policy and then an IPMModule
var policy = new PolicyModel({
  id      : '71049-active.xml',
  urlRoot : 'mocks/',
  digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
});

var ipm = window.ipm = new IPMModule(policy, $('<div />'));

describe('IPM Module', function (){

  describe('Create an IPM Module', function (){

    var ajax_count = 0;


    beforeEach(function(){
      if (ajax_count < 1) {
        var callback = jasmine.createSpy();
        policy.fetch({
            success : callback
          });
        
        waitsFor(function() {
          return callback.callCount > 0;
        }, "Timeout BOOM!", 2000)
      }
      ajax_count++;
    })

    // IPM Module is an object
    it ('is an object', function () {
      expect(ipm).toEqual(jasmine.any(Object));
    });

    // IPM Module has a config
    it ('has a CONFIG hash', function () {
      expect(ipm.CONFIG).not.toBe(null);
      expect(ipm.CONFIG).toEqual(jasmine.any(Object));
    });

    // IPM Module has a policy
    it ('has a Policy', function () {
      expect(ipm.POLICY).not.toBe(null);
      expect(ipm.POLICY).toEqual(jasmine.any(Object));
      expect(ipm.POLICY instanceof Backbone.Model).toBe(true);
    });

  });

  describe('Create an IPMView', function (){

    // var ipmview = new IPMView({
    //     'MODULE' : ipm,
    //     'DEBUG'  : true
    //   });

    // var action = new IPMActionView()

    it ('is an object and Backbone.View', function () {
      expect(ipm.VIEW).toEqual(jasmine.any(Object));
      expect(ipm.VIEW instanceof Backbone.View).toBe(true);
    });

    // it ('IPMActionView is an object and Backbone.View', function () {
    //   console.log(action)
    //   expect(action).toEqual(jasmine.any(Object));
    //   expect(action instanceof Backbone.View).toBe(true);
    // });

    // it ('IPMActionView has a flash view', function () {
    //   console.log(action)
    //   expect(action).toEqual(jasmine.any(Object));
    //   expect(action instanceof Backbone.View).toBe(true);
    // });

  })

});


});
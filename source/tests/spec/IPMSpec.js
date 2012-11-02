define([
  "jquery", 
  "underscore", 
  "WorkspaceController", 
  "modules/IPM/IPMModule",
  "modules/IPM/IPMView",
  "modules/IPM/IPMActionView",
  "modules/Policy/PolicyModel",
  "modules/IPM/IPMChangeSet",
  "UserModel",
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
    IPMChangeSet,
    UserModel,
    amplify, 
    CanvasLoader
) {

// Load up a Policy and then an IPMModule
var policy = new PolicyModel({
  id      : '71049-active.xml',
  urlRoot : 'mocks/',
  digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
});



var ipm = window.ipm = new IPMModule(policy, $('<div></div>'));

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
      console.log(ipm);
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

    var action = new IPMActionView({
      PARENT_VIEW : ipm.VIEW,
      MODULE : ipm
    })
    console.log(action)

    it ('IPMView is an object and Backbone.View', function () {
      expect(ipm.VIEW).toEqual(jasmine.any(Object));
      expect(ipm.VIEW instanceof Backbone.View).toBe(true);
    });

    it ('IPMView can route actions', function () {
      // expect(ipm.VIEW).toEqual(jasmine.any(Object));
      // expect(ipm.VIEW instanceof Backbone.View).toBe(true);
    });

    it ('IPMActionView is an object and Backbone.View', function () {
      expect(action).toEqual(jasmine.any(Object));
      expect(action instanceof Backbone.View).toBe(true);
    });

  })

  describe('IPMChangeSet', function(){

    var user = {}

    user = new UserModel({
      urlRoot  : 'mocks/',
      username : 'cru4t@cru360.com',
      password : 'abc123'
    });

    var VALUES = {
      changedValues : ['appliedDate','paymentAmount','paymentMethod'],
      formValues : {
        appliedDate           : "2011-15-01",
        paymentAmount         : -124,
        paymentBatch          : "",
        paymentMethod         : "300",
        paymentReference      : "",
        positivePaymentAmount : 124,
        postmarkDate          : ""
      }
    };

    var ChangeSet = new IPMChangeSet(ipm.POLICY, 'MakePayment', VALUES, user);

    it ('IPMChangeSet is an object and a change set', function () {
      expect(ChangeSet).toEqual(jasmine.any(Object));
      expect(ChangeSet instanceof IPMChangeSet).toBe(true);
    });

    it ('IPMChangeSet has a policy', function () {
      expect(ChangeSet.POLICY).toEqual(jasmine.any(Object));
      expect(ChangeSet.POLICY instanceof Backbone.Model).toBe(true);
    });

    it ('IPMChangeSet has a user', function () {
      var callback = jasmine.createSpy();
      user.fetch({
        success : callback
      })            
      waitsFor(function() {
        if (callback.mostRecentCall.args !== undefined) {
          callback.mostRecentCall.args[0].parse_identity();
        }
        return callback.callCount > 0
      }, "Timeout BOOM!", 2000);
      runs(function(){
        expect(ChangeSet.USER).toEqual(jasmine.any(Object));
        expect(ChangeSet.USER instanceof Backbone.Model).toBe(true);
      });
    });

    it ('IPMChangeSet has an action', function () {
      expect(ChangeSet.ACTION).toEqual(jasmine.any(String));
      expect(ChangeSet.ACTION).toBe('MakePayment');
    });

    it ('IPMChangeSet has form values', function () {
      expect(ChangeSet.VALUES).toEqual(jasmine.any(Object));
      expect(ChangeSet.VALUES.changedValues).toEqual(jasmine.any(Array));
      expect(ChangeSet.VALUES.formValues).toEqual(jasmine.any(Object));
    });

    it ('IPMChangeSet can make a PolicyChangeSet document', function () {
      console.log(ChangeSet.getPolicyChangeSet());
      console.log(user);
      // expect(ChangeSet.POLICY).toEqual(jasmine.any(Object));
    });

  });

});


});
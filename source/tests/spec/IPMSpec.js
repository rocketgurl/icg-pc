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
  "loader",
  "xml2json"], 
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

 var user = {}

user = new UserModel({
  urlRoot  : 'mocks/',
  username : 'cru4t@cru360.com',
  password : 'abc123'
});

// Load up a Policy and then an IPMModule
var policy = new PolicyModel({
  id      : '71049-active.xml',
  urlRoot : 'mocks/',
  digest  : 'Y3J1NHRAY3J1MzYwLmNvbTphYmMxMjM='
});



var ipm = window.ipm = new IPMModule(policy, $('<div></div>'), user);

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
    console.log(['VIEW',ipm.VIEW])
    var action = new IPMActionView({
      MODULE : ipm,
      PARENT_VIEW : ipm.VIEW
    })

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
        appliedDate           : "2011-01-15",
        paymentAmount         : -124,
        paymentBatch          : "",
        paymentMethod         : "300",
        paymentReference      : "",
        positivePaymentAmount : 124,
        postmarkDate          : ""
      }
    };

    var ChangeSet = new IPMChangeSet(ipm.POLICY, 'MakePayment', user);

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

    it ('IPMChangeSet can make a Policy Context object', function () {
      var context = {
        id            : "d1716d6e86334c4db583278d5889deb4",
        user          : "cru4t@cru360.com",
        version       : "4",
        timestamp     : moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        datestamp     : moment(new Date()).format("YYYY-MM-DD"),
        effectiveDate : moment("2012-11-05").format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        appliedDate   : moment("2011-01-15").format('YYYY-MM-DDTHH:mm:ss.sssZ'),
        comment       : "posted by Policy Central IPM Module"
      }
      VALUES.formValues.effectiveDate = "2012-11-05";
      expect(ChangeSet.getPolicyContext(policy, user, VALUES)).toEqual(jasmine.any(Object));
      expect(ChangeSet.getPolicyContext(policy, user, VALUES)).toEqual(context);
    });

    it ('IPMChangeSet can make a Policy Change Set XML Document', function () {

      var xml = '<PolicyChangeSet schemaVersion="3.1"><Initiation><Initiator type="user">cru4t@cru360.com</Initiator></Initiation><Target><Identifiers><Identifier name="InsightPolicyId" value="d1716d6e86334c4db583278d5889deb4" /></Identifiers><SourceVersion>4</SourceVersion></Target><EffectiveDate>2012-11-05T00:00:00.000-05:00</EffectiveDate><AppliedDate>2011-01-15T00:00:00.000-05:00</AppliedDate><Comment>posted by Policy Central IPM Module</Comment><Ledger><LineItem value="-124" type="PAYMENT" ><Memo></Memo><DataItem name="Reference" value="" /><DataItem name="PaymentMethod" value="300" /></LineItem></Ledger><EventHistory><Event type="Payment"><DataItem name="PaymentAmount" value="124" /><DataItem name="PaymentMethod" value="300" /><DataItem name="PaymentReference" value="" /><DataItem name="PaymentBatch" value="" /><DataItem name="PostmarkDate" value="" /><DataItem name="AppliedDate" value="2011-01-15T00:00:00.000-05:00" /></Event></EventHistory></PolicyChangeSet>';

      // Timestamps will never match so remove them
      var changeSet = ChangeSet.getPolicyChangeSet(VALUES).replace(/timestamp="([\w\d-:.]*)"/g, '');

      expect(changeSet).toEqual(jasmine.any(String));
      expect(changeSet).beEquivalentTo(xml);

    });

    it ('IPMChangeSet can getPayloadType from ChangeSet XML', function () {
      var xml = ChangeSet.getPolicyChangeSet(VALUES)
      expect(ChangeSet.getPayloadType($.parseXML(xml))).toEqual('policychangeset');
    });

    it ('IPMChangeSet can getSchemaVersion from ChangeSet XML', function () {
      var xml = ChangeSet.getPolicyChangeSet(VALUES)
      expect(ChangeSet.getSchemaVersion($.parseXML(xml))).toEqual('3.1');
    });

  });

});


});
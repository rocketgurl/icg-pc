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

    var endorse_json = {}

    // Load up some JSON for testing our IPM methods
    $.getJSON('mocks/endorse.json', function(data){
      endorse_json = data;
    })

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

    it ('A policy knows what its TermDataItems are', function () {
      runs(function(){
        var latestTerm = policy_A.getLastTerm();
        var termDataItems = latestTerm.DataItem;
        dataItemValues = policy_A.getTermDataItemValues(endorse_json);
        var terms = {
          AllOtherPerilsDeductible: "10",
          AnimalLiability: "200",
          AutoPolicyCarrier: "",
          AutoPolicyNumber: "",
          BurglarAlarm: "1",
          ChangeCoveragesReason: false,
          ConstructionYearRoof: "2012",
          CoverageA: "195000",
          CoverageB: "1950",
          CoverageC: "136500",
          CoverageD: "58500",
          CoverageE: "100000",
          CoverageF: "1000",
          CreditCardFraudCoverage: "5000",
          CurrencySpecialLimits: "200",
          FireAlarm: "1",
          FirearmsSpecialLimits: "2500",
          FursSpecialLimits: "0",
          GoldSpecialLimits: "2500",
          HandrailWalkwayLiability: "200",
          HurricaneDeductible: "500",
          HurricanePremiumDollarAdjustmentFRC: false,
          IdentityFraudCoverage: "25000",
          IncreasedOrdinanceLimit: "2500",
          InspectionFee: "30",
          JewelrySpecialLimits: "1500",
          LossAssessmentCoverage: "2000",
          MultiPolicy: "200",
          NonHurricanePremiumDollarAdjustmentFRC: false,
          OpeningProtectionType: "1",
          OptionCoverageB: "100",
          OptionCoverageC: "7000",
          OptionCoverageD: "3000",
          PersonalInjuryCoverage: "100",
          PersonalPropertyReplacementCost: "100",
          PrimeTimeDiscount: "200",
          ReplacementCostBuilding: "194317",
          RoofCoveringType: "500",
          RoofDeckAttachmentType: "0",
          RoofGeometryType: "100",
          RoofWallConnectionType: "0",
          SecuritiesSpecialLimits: "1500",
          WaterBackupCoverage: "5000"
        }
        expect(dataItemValues).toEqual(jasmine.any(Object));
        expect(dataItemValues).toEqual(terms);
      });
    });

    it ('A policy knows what its enumerations are', function () {
      runs(function(){
        var latestTerm = policy_A.getLastTerm();
        var termDataItems = latestTerm.DataItem;
        dataItemValues = policy_A.getDataItemValues(termDataItems, endorse_json);
        enumerations = policy_A.getEnumerations(dataItemValues, endorse_json);
        expect(enumerations).toEqual(jasmine.any(Object));
      });
    });

    it ('A policy can generate overivew data from itself', function () {
      runs(function(){

        var test = {
          InsuredFirstName: "DOCUMENT",
          InsuredLastName: "TEST",
          InsuredMailingAddressCity: "HILTON HEAD",
          InsuredMailingAddressLine1: "41 PURPLE MARTIN LN",
          InsuredMailingAddressLine2: "",
          InsuredMailingAddressState: "SC",
          InsuredMailingAddressZip: "29926",
          InsuredMiddleName: ""
        }
        var overview = policy_A.getPolicyOverview();
        expect(overview).toEqual(test);
      });
    });

    it ('knows its pendingCancel state', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          var res = policy.isPendingCancel()
          var o = {
            reasonCode: "5",
            cancellationEffectiveDate: "2011-06-15T00:00:00-04:00"
          }
          if (_.isObject(res)) {
            expect(res).toEqual(o);
          } else {
            expect(res).toEqual(false);
          }
        });
      });
    });

    it ('knows if its a quote or not', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          expect(policy.isQuote()).toBe(false);
        });        
      });
    });

    it ('has a set of Terms', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          var terms = policy.getTerms()
          expect(terms).toEqual(jasmine.any(Array));
          expect(terms[0]).toEqual(jasmine.any(Object));
          _.each(['DataItem','EffectiveDate','Intervals','ProductRef'], function(key){
            expect(_.has(terms[0], key)).toBe(true)
          })
          expect(terms[0].DataItem).toEqual(jasmine.any(Array));
          expect(terms[0].Intervals).toEqual(jasmine.any(Object));
        });        
      });
    });

    it ('knows what its last term is', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          var lastTerm = policy.getLastTerm();
          expect(lastTerm).toEqual(jasmine.any(Object));
          _.each(['DataItem','EffectiveDate','Intervals','ProductRef'], function(key){
            expect(_.has(lastTerm, key)).toBe(true)
          })
        });        
      });
    });

    it ('knows what the intervals of a term object are', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          var lastTerm = policy.getLastTerm();
          var intervals = policy.getIntervalsOfTerm(lastTerm);
          expect(intervals).toEqual(jasmine.any(Array));
          _.each(intervals, function(interval){
            _.each(['DataItem','EndDate','StartDate'], function(key){
              expect(_.has(interval, key)).toBe(true)
            })
          })
        });        
      });
    });

    it ('knows what the last interval of the last term is', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          var lastInterval = policy.getLastInterval();
          expect(lastInterval).toEqual(jasmine.any(Object));
          _.each(['DataItem','EndDate','StartDate'], function(key){
            expect(_.has(lastInterval, key)).toBe(true)
          })
        });        
      });
    });

    it ('knows what its product name is', function () {
      runs(function(){
        var names = ['acic-ho3-sc', 'wic-ho3-al', 'wic-ho3-al']
        _.each(policies, function(policy, index){
          expect(policy.getProductName()).toBe(names[index]);
        });        
      });
    });

    it ('can get an identifier by name', function () {
      runs(function(){
        var names = ['CRU4Q-71049', 'SIC1Q-29', 'SIC1Q-30']
        _.each(policies, function(policy, index){
          expect(policy.getIdentifier('QuoteNumber')).toBe(names[index]);
        });        
      });
    });

    it ('knows if its issued or not', function () {
      runs(function(){
        _.each(policies, function(policy, index){
          expect(policy.isIssued()).toBe(true);
        });        
      });
    });

    it ('can strip times from dates', function () {
      runs(function(){
        var dates = [
          '2011-01-15T23:00:00-04:00',
          '2011/02/25T23:00:00-04:00',
          '2011/02/30T'
        ]
        var formatted = [
          '2011-01-15',
          '2011-02-25',
          '2011-03-02'
        ]
        _.each(policies, function(policy, index){
          expect(policy._stripTimeFromDate(dates[index])).toBe(formatted[index]);
        });        
      });
    });


    it ('can format dates', function () {
      runs(function(){
        var dates = [
          '2011-01-15T23:00:00-04:00',
          '2011-02-25T23:00:00-04:00',
          '2011-02-30T'
        ]
        var formats = [
          'MM/DD/YYYY',
          'YYYY-MM-DDTHH:mm:ss.sssZ',
          'M/D/YY'
        ]
        var formatted = [
          '01/15/2011',
          '2011-02-25T22:00:00.000-05:00',
          '3/2/11'
        ]
        _.each(policies, function(policy, index){
          expect(policy._formatDate(dates[index], formats[index])).toBe(formatted[index]);
        });        
      });
    });

    it ('knows its Effective Date', function () {
      runs(function(){
        var dates = [
          '2012-06-28',
          '2010-10-29',
          '2010-10-29'
        ]
        _.each(policies, function(policy, index){
          expect(policy.getEffectiveDate()).toBe(dates[index]);
        });
      });
    });

    it ('knows its Expiration Date', function () {
      runs(function(){
        var dates = [
          '2013-06-28',
          '2011-10-29',
          '2011-10-29'
        ]
        _.each(policies, function(policy, index){
          expect(policy.getExpirationDate()).toBe(dates[index]);
        });        
      });
    });

  });

});
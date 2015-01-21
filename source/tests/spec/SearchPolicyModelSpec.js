define([
  'modules/Search/SearchPolicyModel'
], function (SearchPolicyModel) {

  var testData = {
    disposition: null,
    effectiveDate: "2014-05-08 00:00:00.0",
    identifiers: {
      policyId: "SCP042183000",
      quoteNumber: "CRU4Q-421830"
    },
    insured: {
      Address: "518 HOLLY ST, ",
      address: {
        city: null,
        line1: "518 HOLLY ST",
        state: null,
        zip: null
      },
      lastName: "Test"
    },
    policyState: "ACTIVEPOLICY",
    productLabel: "HO6 SC",
    renewalReviewRequired: false,
    reviewStatus: "Complete"
  };

  // SEARCH POLICY MODEL
  describe('SearchPolicyModel', function () {

    it ('should be a Constructor', function () {
      expect(SearchPolicyModel).toEqual(jasmine.any(Function));
    });

    describe('SearchPolicyModel.prototype.parse', function () {
      var data;
      var model;

      beforeEach(function () {
        data = _.clone(testData);
        model = new SearchPolicyModel();
      });

      it ('should add a default `CarrierId` property if none is present', function () {
        model.set(model.parse(data));
        expect(model.get('CarrierId')).toBe('--');
      });

      it ('should add a `CarrierId` equal to the `carrierId` property if `carrierId` is present', function () {
        data.carrierId = 'OFCC';
        model.set(model.parse(data));
        expect(model.get('CarrierId')).toBe('OFCC');
      });

      it ('should leave the `CarrierId` unchanged if it is already present', function () {
        data.CarrierId = 'OFCC';
        model.set(model.parse(data));
        expect(model.get('CarrierId')).toBe('OFCC');
      });
    });

  });

});
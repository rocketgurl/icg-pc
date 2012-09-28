// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel', 'base64'], function(BaseModel, Base64) {
    var PolicyModel;
    PolicyModel = BaseModel.extend({
      initialize: function() {
        return this.use_cripple();
      },
      url: function() {
        return this.get('urlRoot') + 'policies/' + this.id;
      },
      get_pxServerIndex: function() {
        var doc;
        doc = this.get('document');
        this.set('pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value'));
        return this.get('pxServerIndex');
      },
      get_policy_holder: function() {
        var doc, first, last;
        doc = this.get('document');
        last = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredLastName]').attr('value');
        first = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredFirstName]').attr('value');
        return "" + last + ", " + first;
      },
      get_policy_period: function() {
        var doc, end, start;
        doc = this.get('document');
        start = doc.find('Terms Term EffectiveDate').text().substr(0, 10);
        end = doc.find('Terms Term ExpirationDate').text().substr(0, 10);
        return "" + start + " - " + end;
      },
      get_ipm_header: function() {
        var doc, ipm_header;
        doc = this.get('document');
        ipm_header = {
          id: doc.find('Identifiers Identifier[name=PolicyID]').attr('value'),
          product: doc.find('Terms Term DataItem[name=OpProductLabel]').attr('value'),
          holder: this.get_policy_holder(),
          state: doc.find('Management PolicyState').text(),
          period: this.get_policy_period(),
          carrier: doc.find('Management Carrier').text()
        };
        return ipm_header;
      },
      getSystemOfRecord: function() {
        return this.get('document').find('Management SystemOfRecord').text();
      },
      isIPM: function() {
        if (this.getSystemOfRecord() === 'mxServer') {
          return true;
        } else {
          return false;
        }
      }
    });
    return PolicyModel;
  });

}).call(this);

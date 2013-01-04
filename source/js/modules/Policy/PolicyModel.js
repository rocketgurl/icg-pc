// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseModel'], function(BaseModel) {
    var PolicyModel;
    PolicyModel = BaseModel.extend({
      NAME: 'Policy',
      states: {
        ACTIVE_POLICY: 'ACTIVEPOLICY',
        ACTIVE_QUOTE: 'ACTIVEQUOTE',
        CANCELLED_POLICY: 'CANCELLEDPOLICY',
        EXPIRED_QUOTE: 'EXPIREDQUOTE',
        NON_RENEWED_POLICY: 'NONRENEWEDPOLICY'
      },
      initialize: function() {
        this.use_xml();
        return this.on('change', function(e) {
          e.setModelState();
          return e.get_pxServerIndex();
        });
      },
      url: function(route) {
        var url;
        url = this.get('urlRoot') + 'policies/' + this.id;
        if (route != null) {
          url = "" + url + route;
        }
        return url;
      },
      get_pxServerIndex: function() {
        var doc;
        doc = this.get('document');
        if (doc != null) {
          this.set('pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value'));
        }
        return this.get('pxServerIndex');
      },
      getPolicyHolder: function() {
        var doc, first, insured_data, last;
        doc = this.get('document');
        insured_data = this.getCustomerData('Insured');
        last = this.getDataItem(insured_data, 'InsuredLastName');
        first = this.getDataItem(insured_data, 'InsuredFirstName');
        if (last) {
          last = this.Helpers.properName(last);
        }
        if (first) {
          first = this.Helpers.properName(first);
        }
        return this.Helpers.concatStrings(last, first, ', ');
      },
      getPolicyPeriod: function() {
        var doc, end, start;
        doc = this.get('document');
        start = doc.find('Terms Term EffectiveDate').text().substr(0, 10);
        end = doc.find('Terms Term ExpirationDate').text().substr(0, 10);
        return this.Helpers.concatStrings(start, end, ' - ');
      },
      get_policy_id: function() {
        return this.get('document').find('Identifiers Identifier[name=PolicyID]').attr('value');
      },
      getIpmHeader: function() {
        var doc, imp_header, ipm_header;
        doc = this.get('document');
        imp_header = {};
        if (doc != null) {
          ipm_header = {
            id: this.getIdentifier('PolicyID'),
            product: this.getTermDataItemValue('ProductLabel'),
            holder: this.getPolicyHolder(),
            state: this.get('state').text || this.get('state'),
            period: this.getPolicyPeriod(),
            carrier: doc.find('Management Carrier').text()
          };
        }
        return ipm_header;
      },
      getSystemOfRecord: function() {
        var doc;
        doc = this.get('document');
        if (doc != null) {
          return doc.find('Management SystemOfRecord').text();
        }
      },
      isIPM: function() {
        if (this.getSystemOfRecord() === 'mxServer') {
          return true;
        } else {
          return false;
        }
      },
      _getAttributes: function(elem) {
        var attr, attribs, out, _i, _len;
        out = null;
        if ((elem[0] != null) && (elem[0].attributes != null)) {
          out = {};
          attribs = elem[0].attributes;
          for (_i = 0, _len = attribs.length; _i < _len; _i++) {
            attr = attribs[_i];
            out[attr.name] = attr.value;
          }
        }
        return out;
      },
      getState: function() {
        var attr, policyState, text;
        if (this.get('document') != null) {
          policyState = this.get('document').find('Management PolicyState');
          text = policyState.text();
          attr = this._getAttributes(policyState);
          if (attr === null) {
            return text;
          } else {
            return _.extend(attr, {
              'text': text
            });
          }
        }
      },
      isCancelled: function() {
        var state;
        state = this.getState();
        if (typeof state === 'object' && state.text === 'CANCELLEDPOLICY') {
          return true;
        } else {
          return false;
        }
      },
      isQuote: function() {
        var state, text;
        state = this.getState();
        text = typeof state === 'object' ? state.text : state;
        return text === this.states.ACTIVE_QUOTE || text === this.states.EXPIRED_QUOTE;
      },
      isPendingCancel: function(bool) {
        var pending;
        pending = this.get('json').Management.PendingCancellation || false;
        if (bool && pending) {
          return true;
        }
        return pending;
      },
      getCancellationEffectiveDate: function() {
        var effective_date, state;
        state = this.getState();
        effective_date = null;
        switch (state) {
          case "ACTIVEPOLICY":
            if (this.isPendingCancel(true)) {
              effective_date = this.isPendingCancel().cancellationEffectiveDate;
            }
            break;
          case "CANCELLEDPOLICY":
            effective_date = this.get('json').Management.PolicyState.effectiveDate;
            break;
          default:
            effective_date = null;
        }
        return effective_date;
      },
      getCancellationReasonCode: function() {
        var pending, reason_code, state;
        state = this.getState();
        reason_code = null;
        pending = this.isPendingCancel();
        state = typeof state === 'object' ? state.text : state;
        switch (state) {
          case 'ACTIVEPOLICY':
            if (pending) {
              reason_code = parseInt(pending.reasonCode, 10);
            }
            break;
          case 'CANCELLEDPOLICY':
            reason_code = this.get('json').Management.PolicyState.reasonCode;
            reason_code = parseInt(reason_code, 10);
            break;
          default:
            reason_code = null;
        }
        return reason_code;
      },
      getTerms: function() {
        var terms;
        terms = false;
        if (this.get('json').Terms.Term != null) {
          terms = this.get('json').Terms.Term;
        }
        if (_.isArray(terms)) {
          return terms;
        }
        if (_.isObject(terms)) {
          return [terms];
        }
      },
      getLastTerm: function() {
        var terms;
        if (terms = this.getTerms()) {
          return _.last(terms);
        } else {
          return {};
        }
      },
      getCustomerData: function(type) {
        var customer;
        if (type === null || type === void 0) {
          return false;
        }
        customer = _.filter(this.get('json').Customers.Customer, function(c) {
          return c.type === type;
        });
        if (customer.length > 0) {
          return customer[0].DataItem;
        } else {
          return false;
        }
      },
      getIntervalsOfTerm: function(term) {
        var out;
        if (term === null || term === void 0) {
          return false;
        }
        out = [];
        if (_.has(term, 'Intervals') && _.has(term.Intervals, 'Interval')) {
          if (_.isArray(term.Intervals.Interval)) {
            out = term.Intervals.Interval;
          } else {
            out = [term.Intervals.Interval];
          }
        }
        return out;
      },
      getLastInterval: function() {
        var out, term;
        term = this.getIntervalsOfTerm(this.getLastTerm());
        if (term && _.isArray(term)) {
          out = term[term.length - 1];
        } else {
          out = {};
        }
        return out;
      },
      getProductName: function() {
        var name, terms;
        terms = this.getLastTerm();
        if (_.has(terms, 'DataItem')) {
          terms = terms.DataItem;
        } else if (_.has(terms, 'Intervals') && _.has(terms.Intervals, 'Interval')) {
          if (_.isArray(terms.Intervals.Interval)) {
            terms = terms.Intervals.Interval[0].DataItem;
          } else {
            terms = terms.Intervals.Interval.DataItem;
          }
        }
        name = "" + (this.getDataItem(terms, 'Program')) + "-" + (this.getDataItem(terms, 'PolicyType')) + "-" + (this.getDataItem(terms, 'PropertyState'));
        return name.toLowerCase();
      },
      getIdentifier: function(name) {
        if (name === null || name === void 0) {
          return false;
        }
        return this.get('document').find("Identifiers Identifier[name=" + name + "]").attr('value');
      },
      isIssued: function() {
        var history;
        history = this.get('document').find('EventHistory Event[type=Issue]');
        if (history.length > 0) {
          return true;
        } else {
          return false;
        }
      },
      _stripTimeFromDate: function(date) {
        var clean, t;
        clean = date;
        t = date.indexOf('T');
        if (t > -1) {
          clean = clean.substring(0, t);
        }
        return this._formatDate(clean);
      },
      _formatDate: function(date, format) {
        format = format != null ? format : 'YYYY-MM-DD';
        if (moment(date) != null) {
          return moment(date).format(format);
        }
      },
      getEffectiveDate: function() {
        var date;
        date = this.get('document').find('Terms Term EffectiveDate').text();
        if (date !== void 0 || date !== '') {
          return this._stripTimeFromDate(date);
        } else {
          return false;
        }
      },
      getExpirationDate: function() {
        var date;
        date = this.get('document').find('Terms Term ExpirationDate').text();
        if (date !== void 0 || date !== '') {
          return this._stripTimeFromDate(date);
        } else {
          return false;
        }
      },
      getTermDataItemValues: function(vocabTerms) {
        var out, term, _i, _len, _ref;
        out = {};
        _ref = vocabTerms.terms;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          term = _ref[_i];
          out[term.name] = this.getTermDataItemValue(term.name);
          if (out[term.name] === void 0) {
            out[term.name] = false;
          }
        }
        return out;
      },
      getTermDataItemValue: function(name) {
        var doc, value;
        doc = this.get('document');
        if (doc != null) {
          value = doc.find("Terms Term DataItem[name=Op" + name + "]").attr('value') || doc.find("Terms Term DataItem[name=" + name + "]").attr('value');
        }
        return value;
      },
      getDataItem: function(items, name) {
        var data_obj, op_name;
        if (items === void 0 || name === void 0) {
          return false;
        }
        op_name = "Op" + name;
        data_obj = _.filter(items, function(item) {
          return item.name === op_name;
        });
        if (data_obj.length === 0) {
          data_obj = _.filter(items, function(item) {
            return item.name === name;
          });
        }
        if (_.isArray(data_obj) && (data_obj[0] != null)) {
          return data_obj[0].value;
        } else {
          return false;
        }
      },
      getDataItemValues: function(list, terms) {
        var out, term, _i, _len;
        out = {};
        for (_i = 0, _len = terms.length; _i < _len; _i++) {
          term = terms[_i];
          out[term] = this.getDataItem(list, term);
        }
        return out;
      },
      getEnumerations: function(viewData, vocabTerms) {
        var empty, term, _i, _len, _ref;
        if (viewData == null) {
          viewData = {};
        }
        empty = {
          value: '',
          label: 'Select'
        };
        _ref = vocabTerms.terms;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          term = _ref[_i];
          if (_.has(term, 'enumerations') && term.enumerations.length > 0) {
            viewData["Enums" + term.name] = [].concat(empty, term.enumerations);
          }
        }
        return viewData;
      },
      getValueByPath: function(path, dataItem) {
        if (path == null) {
          path = '';
        }
        if (dataItem != null) {
          return this.get('document').find(path).attr('value');
        } else {
          return this.get('document').find(path).text();
        }
      },
      getPolicyOverview: function() {
        var customerData, terms;
        terms = ['InsuredFirstName', 'InsuredMiddleName', 'InsuredLastName', 'InsuredMailingAddressLine1', 'InsuredMailingAddressLine2', 'InsuredMailingAddressCity', 'InsuredMailingAddressState', 'InsuredMailingAddressZip'];
        customerData = this.get('insuredData');
        return this.getDataItemValues(customerData, terms);
      },
      setModelState: function() {
        if ((this.get('document') != null) || this.get('document') !== void 0) {
          this.set('state', this.getState());
          this.set('quote', this.isQuote());
          this.set('pendingCancel', this.isPendingCancel());
          this.set('cancellationEffectiveDate', this.getCancellationEffectiveDate());
          this.set('cancelled', this.isCancelled());
          this.set('terms', this.getTerms());
          this.set('lastInterval', this.getLastInterval());
          this.set('insuredData', this.getCustomerData('Insured'));
          this.set('mortgageeData', this.getCustomerData('Mortgagee'));
          this.set('additionalInterestData', this.getCustomerData('AdditionalInterest'));
          this.set('productName', this.getProductName());
          this.set('insight_id', this.getIdentifier('InsightPolicyId'));
          this.set('isIssued', this.isIssued());
          this.set('effectiveDate', this.getEffectiveDate());
          return this.set('expirationDate', this.getExpirationDate());
        }
      }
    });
    return PolicyModel;
  });

}).call(this);

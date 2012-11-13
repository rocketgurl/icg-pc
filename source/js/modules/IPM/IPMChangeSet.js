// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'mustache', 'Helpers'], function($, _, Backbone, Mustache, Helpers) {
    var IPMChangeSet;
    return IPMChangeSet = (function() {

      function IPMChangeSet(POLICY, ACTION, USER) {
        this.POLICY = POLICY;
        this.ACTION = ACTION;
        this.USER = USER;
      }

      IPMChangeSet.prototype.getTransactionRequest = function(values, vocabTerms) {
        var context, partials, transaction_request_data, xml;
        context = this.getTransactionContext(this.POLICY, this.USER, values, vocabTerms);
        transaction_request_data = _.extend(values.formValues, context);
        console.log(['transaction_request_data', transaction_request_data]);
        partials = {
          body: this[_.underscored(this.ACTION)] || '',
          changes: this.dataItemTemplate
        };
        xml = Mustache.render(this.transactionRequestSkeleton, transaction_request_data, partials);
        return _.trim(xml.replace(/>(\s+)</g, '><'));
      };

      IPMChangeSet.prototype.getTransactionContext = function(policy, user, values, vocabTerms) {
        var context, dataItems;
        values.formValues = this.processTransactionFields(values.formValues);
        context = {
          id: policy.get('insight_id'),
          user: user.get('email'),
          version: policy.getValueByPath('Management Version'),
          timestamp: values.formValues.timestamp || Helpers.makeTimestamp(),
          datestamp: Helpers.formatDate(new Date()),
          effectiveDate: values.formValues.effectiveDate || Helpers.makeTimestamp(),
          comment: values.formValues.comment || "posted by Policy Central IPM Module"
        };
        dataItems = this.getChangedDataItems(values, vocabTerms);
        if (!_.isEmpty(dataItems)) {
          context.intervalRequest = dataItems;
        }
        return context;
      };

      IPMChangeSet.prototype.getChangedDataItems = function(values, vocabTerms) {
        var change_set, changed, key, keys, out, val;
        changed = values.changedValues;
        keys = _.intersection(_.keys(vocabTerms), changed);
        change_set = _.pick(values.formValues, keys);
        out = [];
        for (key in change_set) {
          val = change_set[key];
          out.push({
            key: key,
            value: val
          });
        }
        return out;
      };

      IPMChangeSet.prototype.processTransactionFields = function(fields) {
        var key, val;
        for (key in fields) {
          val = fields[key];
          if (key.indexOf('Date') !== -1) {
            if (val !== "" && val !== "__deleteEmptyProperty") {
              fields[key] = Helpers.formatDate(val);
            }
          }
        }
        return fields;
      };

      IPMChangeSet.prototype.getPolicyChangeSet = function(values) {
        var change_set_data, context, partials, xml;
        context = this.getPolicyContext(this.POLICY, this.USER, values);
        change_set_data = _.extend(values.formValues, context);
        partials = {
          body: this[_.underscored(this.ACTION)] || ''
        };
        xml = Mustache.render(this.policyChangeSetSkeleton, change_set_data, partials);
        return _.trim(xml.replace(/>(\s+)</g, '><'));
      };

      IPMChangeSet.prototype.getPolicyContext = function(policy, user, values) {
        var context;
        values.formValues = this.processChangeFields(values.formValues);
        context = {
          id: policy.get('insight_id'),
          user: user.get('email'),
          version: policy.getValueByPath('Management Version'),
          timestamp: values.formValues.timestamp || Helpers.makeTimestamp(),
          datestamp: Helpers.formatDate(new Date()),
          effectiveDate: values.formValues.effectiveDate || Helpers.makeTimestamp(),
          appliedDate: values.formValues.appliedDate || Helpers.makeTimestamp(),
          comment: values.formValues.comment || "posted by Policy Central IPM Module"
        };
        return context;
      };

      IPMChangeSet.prototype.processChangeFields = function(fields) {
        var key, val;
        for (key in fields) {
          val = fields[key];
          if (val === '__deleteEmptyProperty') {
            delete fields[key];
          }
          if (val === '__setEmptyValue') {
            fields[key] = '';
          }
          if (key.indexOf('Doc') !== -1) {
            console.log(['Context > Doc?', fields["" + key + "Url"]]);
          } else if (key.indexOf('Date') !== -1) {
            if (val !== "") {
              fields[key] = Helpers.formatDate(val.replace('.000Z', 'Z'), 'YYYY-MM-DDTHH:mm:ss.sssZ');
            }
          }
        }
        return fields;
      };

      IPMChangeSet.prototype.commitChange = function(xml, success, error, options) {
        var defaults, payload_schema, post, xmldoc;
        options = options != null ? options : {};
        xmldoc = $.parseXML(xml);
        payload_schema = "schema=" + (this.getPayloadType(xmldoc)) + "." + (this.getSchemaVersion(xmldoc));
        console.log(['Policy.url()', this.POLICY.url()]);
        defaults = {
          url: this.POLICY.url(),
          type: 'POST',
          dataType: 'xml',
          contentType: "application/xml; " + payload_schema,
          data: xml,
          headers: {
            'Authorization': "Basic " + (this.POLICY.get('digest')),
            'X-Authorization': "Basic " + (this.POLICY.get('digest')),
            'Accept': 'application/vnd.ics360.insurancepolicy.2.6+xml',
            'X-Commit': true
          }
        };
        options = _.extend(defaults, options);
        post = $.ajax(options);
        return $.when(post).then(success, error);
      };

      IPMChangeSet.prototype.getPayloadType = function(xml) {
        var node_name;
        node_name = $(xml).find('*').eq(0)[0].nodeName;
        return node_name.toLowerCase();
      };

      IPMChangeSet.prototype.getSchemaVersion = function(xml) {
        return $(xml).find('*').eq(0).attr('schemaVersion') || '';
      };

      IPMChangeSet.prototype.policyChangeSetSkeleton = "<PolicyChangeSet schemaVersion=\"3.1\">\n  <Initiation>\n    <Initiator type=\"user\">{{user}}</Initiator>\n  </Initiation>\n  <Target>\n    <Identifiers>\n      <Identifier name=\"InsightPolicyId\" value=\"{{id}}\" />\n    </Identifiers>\n    <SourceVersion>{{version}}</SourceVersion>\n  </Target>\n  <EffectiveDate>{{effectiveDate}}</EffectiveDate>\n  <AppliedDate>{{appliedDate}}</AppliedDate>\n  <Comment>{{comment}}</Comment>\n  {{>body}}\n</PolicyChangeSet>";

      IPMChangeSet.prototype.transactionRequestSkeleton = "<TransactionRequest schemaVersion=\"1.4\" type=\"{{transactionType}}\">\n  <Initiation>\n    <Initiator type=\"user\">{{user}}</Initiator>\n  </Initiation>\n  <Target>\n    <Identifiers>\n      <Identifier name=\"InsightPolicyId\" value=\"{{id}}\"/>\n    </Identifiers>\n    <SourceVersion>{{version}}</SourceVersion>\n  </Target>\n  <EffectiveDate>{{effectiveDate}}</EffectiveDate>\n  {{>body}}\n</TransactionRequest>";

      IPMChangeSet.prototype.dataItemTemplate = "{{#intervalRequest}}\n<DataItem name=\"{{key}}\" value=\"{{value}}\" />\n{{/intervalRequest}}";

      IPMChangeSet.prototype.endorse = "<ReasonCode>{{reasonCode}}</ReasonCode>\n<Comment>{{comment}}</Comment>\n<IntervalRequest>\n  <StartDate>{{effectiveDate}}</StartDate>\n  {{>changes}}\n</IntervalRequest>";

      IPMChangeSet.prototype.make_payment = "<Ledger>\n  <LineItem value=\"{{paymentAmount}}\" type=\"PAYMENT\" timestamp=\"{{timestamp}}\">\n    <Memo></Memo>\n    <DataItem name=\"Reference\" value=\"{{paymentReference}}\" />\n    <DataItem name=\"PaymentMethod\" value=\"{{paymentMethod}}\" />\n  </LineItem>\n</Ledger>\n<EventHistory>\n  <Event type=\"Payment\">\n    <DataItem name=\"PaymentAmount\" value=\"{{positivePaymentAmount}}\" />\n    <DataItem name=\"PaymentMethod\" value=\"{{paymentMethod}}\" />\n    <DataItem name=\"PaymentReference\" value=\"{{paymentReference}}\" />\n    <DataItem name=\"PaymentBatch\" value=\"{{paymentBatch}}\" />\n    <DataItem name=\"PostmarkDate\" value=\"{{postmarkDate}}\" />\n    <DataItem name=\"AppliedDate\" value=\"{{appliedDate}}\" />\n  </Event>\n</EventHistory>";

      return IPMChangeSet;

    })();
  });

}).call(this);

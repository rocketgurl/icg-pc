define [
  'jquery',
  'underscore',
  'backbone',
  'mustache',
  'Helpers'
], ($, _, Backbone, Mustache, Helpers) ->

  # QuotingChangeSet
  # ====
  # Handles building a Change Set or TR and shipping off to pxCentral
  #
  # NOTES:
  # * Need to AJAX the TRs to/from server and handle different states such as
  # Validations, errors, previews, etc.
  #
  class QuotingChangeSet

    constructor : (@POLICY, @ACTION, @USER) ->

    # Create TransactionRequest XML
    #
    # @param `values` _Object_ Form values object
    # @return _String_ PolicyChangeSet XML
    #
    getTransactionRequest : (values, vocabTerms) ->
      # Massage form values and get extra policy data for the ChangeSet
      context = @getTransactionContext(@POLICY, @USER, values, vocabTerms)
      transaction_request_data = _.extend values.formValues, context

      # Sweep object for removable fields
      for key, val of transaction_request_data
        if val == '__deleteEmptyProperty'
          delete transaction_request_data[key]

      # Fetch XML template for this action as a partial
      partials =
        body    : @[_.underscored(@ACTION)] || ''
        changes : @dataItemTemplate

      # Render ChangeSet XML (skeleton + data + partials)
      xml = Mustache.render @transactionRequestSkeleton, transaction_request_data, partials

      # We make it flat
      _.trim(xml.replace(/>(\s+)</g, '><'))

    # Build a context object for use in PolicyTransactionRequest
    #
    # @param `policy` _Object_ PolicyModel
    # @param `user` _Object_ UserModel
    # @param `values` _Object_ Form values
    # @return _Object_
    #
    getTransactionContext : (policy, user, values, vocabTerms) ->
      # Process any date fields from the form
      values.formValues = @processDateFields(values.formValues)

      context =
        id            : policy.get 'insight_id'
        user          : user.get 'email'
        version       : @getPolicyVersion()
        timestamp     : values.formValues.timestamp || Helpers.makeTimestamp()
        datestamp     : Helpers.formatDate new Date()
        effectiveDate : values.formValues.effectiveDate || Helpers.makeTimestamp()
        comment       : values.formValues.comment || "posted by Policy Central IPM Module"

      context.effectiveDate = Helpers.stripTimeFromDate(context.effectiveDate)

      # Get changed form values and assemble into array suitable for templates
      dataItems = @getChangedDataItems(values, vocabTerms)
      if !_.isEmpty(dataItems)
        context.intervalRequest = dataItems

      context

    # Retur the key:vals of formValues that were changed
    #
    # @param `values` _Object_ Form values
    # @param `vocabTerms` _Object_ ixVocab values from Policy XML
    # @return _Array_ of key:value objects for template
    #
    getChangedDataItems : (values, vocabTerms) ->
      changed    = values.changedValues
      keys       = _.intersection(_.keys(vocabTerms), changed)
      change_set = _.pick(values.formValues, keys)
      out        = []
      for key, val of change_set
        out.push {key: key, value: val}
      out

    # Process fields to handle dates
    #
    # @param `fields` _Object_ Form values
    # @return _Object_
    #
    processDateFields : (fields) ->
      for key, val of fields
        if key.indexOf('Date') != -1
          if val && val != "false" && val != "" && val != "__deleteEmptyProperty"
            fields[key] = Helpers.formatDate(val)
      fields

    # When we do a preview of a policy we get back a new version with an
    # incremented Version number. When we send the final back for commit
    # we need to send the original version number, so we check the previous
    # version of the policy for a version number
    #
    # @param `version` _Number_
    # @return _Number_
    #
    getPolicyVersion : ->
      prev = @POLICY.get('prev_document')
      if prev?
        if _.has(prev.json, 'Management') && _.has(prev.json.Management, 'Version')
          return prev.json.Management.Version
        else
          return @POLICY.get 'version'
      @POLICY.get 'version'

    # Build ChangeSet XML for use in PolicyChangeSet
    #
    # @param `values` _Object_ Form values object
    # @return _String_ PolicyChangeSet XML
    #
    getPolicyChangeSet : (values) ->
      # Massage form values and get extra policy data for the ChangeSet
      context = @getPolicyContext(@POLICY, @USER, values)

      # Get data together
      change_set_data = _.extend values.formValues, context

      # Fetch XML template for this action as a partial
      partials =
        body : @[_.underscored(@ACTION)] || ''

      # Render ChangeSet XML (skeleton + data + partials)
      xml = Mustache.render @policyChangeSetSkeleton, change_set_data, partials

      # We make it flat
      _.trim(xml.replace(/>(\s+)</g, '><'))


    # Build a context object for use in PolicyChangeSet
    #
    # @param `policy` _Object_ PolicyModel
    # @param `user` _Object_ UserModel
    # @param `values` _Object_ Form values
    # @return _Object_
    #
    getPolicyContext : (policy, user, values) ->
      # Standardize data fields and do a little cleanup
      values.formValues = @processChangeFields(values.formValues)

      context =
        id            : policy.get 'insight_id'
        user          : user.get 'email'
        version       : policy.getValueByPath('Management Version')
        timestamp     : values.formValues.timestamp || Helpers.makeTimestamp()
        datestamp     : Helpers.formatDate new Date()
        effectiveDate : values.formValues.effectiveDate || Helpers.makeTimestamp()
        appliedDate   : values.formValues.appliedDate || Helpers.makeTimestamp()
        comment       : values.formValues.comment || "posted by Policy Central IPM Module"

      context

    # Process ChangeSet fields to handle dates, urls, etc
    #
    # @param `fields` _Object_ Form values
    # @return _Object_
    #
    processChangeFields : (fields) ->
      for key, val of fields
        # Process fields marked with tokens
        if val == '__deleteEmptyProperty'
          delete fields[key]

        if val == '__setEmptyValue'
          fields[key] = ''

        if key.indexOf('Doc') != -1
          # attempt to massage an ixLibrary URL here, see 1549 in mxadmin/model.js
          console.log ['Context > Doc?', fields["#{key}Url"]]
        else if key.indexOf('Date') != -1
          if val != ""
            fields[key] = Helpers.formatDate(
              val.replace('.000Z', 'Z'),
              'YYYY-MM-DDTHH:mm:ss.sssZ'
            )
      fields

    # **Commit change to pxCentral**
    #
    # @param `xml` _String_ XML
    # @param `success` _Function_ success callback
    # @param `error` _Function_ error callback
    # @param `options` _Object_ AJAX options
    #
    commitChange : (xml, success, error, options) ->
      options = options ? {}
      xmldoc  = $.parseXML(xml) # Parse xml w/jQuery
      payload_schema = "schema=#{@getPayloadType(xmldoc)}.#{@getSchemaVersion(xmldoc)}"

      # Assemble the AJAX params
      defaults =
        url         : @POLICY.url()
        type        : 'POST'
        dataType    : 'xml'
        contentType : "application/xml; #{payload_schema}"
        data        : xml
        headers     :
          'Authorization' : "Basic #{@POLICY.get('digest')}"
          'Accept'        : 'application/vnd.ics360.insurancepolicy.2.8+xml'
          'X-Commit'      : true

      if _.has(options, 'headers')
        defaults.headers = _.extend(defaults.headers, options.headers)
        delete options.headers

      options = _.extend defaults, options

      # Post
      post = $.ajax(options)
      $.when(post).then(success, error)


    # Return the root node name in lowercase
    #
    # @param `xml` _XMLDocument_
    # @return _String_ lowercase node name
    #
    getPayloadType : (xml) ->
      node_name = $(xml).find('*').eq(0)[0].nodeName
      node_name.toLowerCase()

    # Return the schemaVersion of XML
    #
    # @param `xml` _XMLDocument_
    # @return _String_
    #
    getSchemaVersion : (xml) ->
      $(xml).find('*').eq(0).attr('schemaVersion') || ''

    # Base template for PolicyChangeSet
    policyChangeSetSkeleton : """
      <PolicyChangeSet schemaVersion="3.1">
        <Initiation>
          <Initiator type="user">{{user}}</Initiator>
        </Initiation>
        <Target>
          <Identifiers>
            <Identifier name="InsightPolicyId" value="{{id}}" />
          </Identifiers>
          <SourceVersion>{{version}}</SourceVersion>
        </Target>
        <EffectiveDate>{{effectiveDate}}</EffectiveDate>
        <AppliedDate>{{appliedDate}}</AppliedDate>
        <Comment>{{comment}}</Comment>
        {{>body}}
      </PolicyChangeSet>
    """

    # Base template for TransactionRequest
    transactionRequestSkeleton : """
      <TransactionRequest schemaVersion="1.4" type="{{transactionType}}">
        <Initiation>
          <Initiator type="user">{{user}}</Initiator>
        </Initiation>
        <Target>
          <Identifiers>
            <Identifier name="InsightPolicyId" value="{{id}}"/>
          </Identifiers>
          <SourceVersion>{{version}}</SourceVersion>
        </Target>
        {{#effectiveDate}}
        <EffectiveDate>{{effectiveDate}}</EffectiveDate>
        {{/effectiveDate}}
        {{>body}}
      </TransactionRequest>
    """

    # Tempalte for data item insertion
    dataItemTemplate : """
      {{#intervalRequest}}
      <DataItem name="{{key}}" value="{{value}}" />
      {{/intervalRequest}}
    """

    # Template bodies (partials) for specific actions

    unlock_quote: """
      <Flags>
        <Flag name="{{name}}" value="{{value}}"/>
      </Flags>
    """


define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'Helpers'
], ($, _, Backbone, Mustache, Helpers) ->

  # IPMChangeSet
  # ====
  # Handles building a Change Set or TR and shipping off to pxCentral 
  #
  # NOTES:  
  # * Need to handle XML templates for different requests (files? Cache them.)
  # * Need to AJAX the TRs to/from server and handle different states such as
  # Validations, errors, previews, etc.
  # 
  class IPMChangeSet

    constructor : (@POLICY, @ACTION, @USER) ->

    # Build a context object for use in PolicyChangeSet
    #
    # @param `values` _Object_ Form values object 
    # @return _String_ PolicyChangeSet XML 
    #
    getPolicyChangeSet : (values) ->
      # Massage form values and get extra policy data for the ChangeSet
      context = @getPolicyContext(@POLICY, @USER, values)

      # Get data together
      change_set_data = _.extend context, values.formValues

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

      # Data massaging: All date fields (effectiveDate, etc) should be in a 
      # timestamped format
      for key, val of values.formValues
        # Process fields marked with tokens
        if val == '__deleteEmptyProperty'
          delete values.formValues[key]

        if val == '__setEmptyValue'
          values.formValues[key] = ''

        if key.indexOf('Doc') != -1
          # attempt to massage an ixLibrary URL here, see 1549 in mxadmin/model.js
          console.log ['Context > Doc?', values.formValues["#{key}Url"]]        
        else if key.indexOf('Date') != -1
          if val != ""
            values.formValues[key] = Helpers.formatDate(
              val.replace('.000Z', 'Z'), 
              'YYYY-MM-DDTHH:mm:ss.sssZ'
            )

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

    # **Commit change to pxCentral**
    #
    # @param `xml` _String_ XML  
    # @param `success` _Function_ success callback  
    # @param `error` _Function_ error callback  
    #
    commitChange : (xml, success, error) ->
      xmldoc = $.parseXML(xml) # Parse xml w/jQuery
      payload_schema = "schema=#{@getPayloadType(xmldoc)}.#{@getSchemaVersion(xmldoc)}"

      # Assemble the AJAX params
      defaults =
        url         : @POLICY.url()
        type        : 'POST'
        dataType    : 'xml'
        contentType : "application/xml; #{payload_schema}"
        data        : xml
        headers     :
          'Authorization'   : "Basic #{@POLICY.get('digest')}"
          'X-Authorization' : "Basic #{@POLICY.get('digest')}"
          'Accept'          : 'application/vnd.ics360.insurancepolicy.2.6+xml'
          'X-Commit'        : true

      # Post
      post = $.ajax(defaults)
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

    # Template body for Make Payment
    make_payment : """
      <Ledger>
        <LineItem value="{{paymentAmount}}" type="PAYMENT" timestamp="{{timestamp}}">
          <Memo></Memo>
          <DataItem name="Reference" value="{{paymentReference}}" />
          <DataItem name="PaymentMethod" value="{{paymentMethod}}" />
        </LineItem>
      </Ledger>
      <EventHistory>
        <Event type="Payment">
          <DataItem name="PaymentAmount" value="{{positivePaymentAmount}}" />
          <DataItem name="PaymentMethod" value="{{paymentMethod}}" />
          <DataItem name="PaymentReference" value="{{paymentReference}}" />
          <DataItem name="PaymentBatch" value="{{paymentBatch}}" />
          <DataItem name="PostmarkDate" value="{{postmarkDate}}" />
          <DataItem name="AppliedDate" value="{{appliedDate}}" />
        </Event>
      </EventHistory>
    """
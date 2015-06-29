define [
  'BaseModel'
  'mustache'
], (BaseModel, Mustache) ->

  #### Policy
  #
  # We handle Policy XML here
  #
  PolicyModel = BaseModel.extend

    NAME : 'Policy'

    # Policy states
    # -------------
    states :
      ACTIVE_POLICY        : 'ACTIVEPOLICY'
      ACTIVE_QUOTE         : 'ACTIVEQUOTE'
      PENDING_CANCELLATION : 'PENDINGCANCELLATION'
      CANCELLED_POLICY     : 'CANCELLEDPOLICY'
      EXPIRED_QUOTE        : 'EXPIREDQUOTE'
      INCOMPLETE_QUOTE     : 'INCOMPLETEQUOTE'
      PENDING_NON_RENEWAL  : 'PENDINGNONRENWAL'
      NON_RENEWED_POLICY   : 'NONRENEWEDPOLICY'

    # Any products that have name conflicts
    # Where the first 3 identifiers aren't enough
    PRODUCT_COLLISIONS : [
      'OFCC-HO3-LA'
    ]

    SPECIAL_PROGRAMS : [
      'LAP'
    ]

    # Setup model
    # -----------
    # Notice the forced binding in initialize() - this aids
    # function composition later. Functions prefixed with _
    # are 'private' and used in compositions.
    #
    initialize : ->
      @use_xml() # Use CrippledClient XMLSync

      # When the model is loaded, make sure its state is current
      @on 'change', (model) ->
        model.setModelState()
        model.determineParentChildRelationship()
        model.get_pxServerIndex()
        model.applyFunctions()

      # Explicitly bind 'private' composable functions to this object
      # scope. These functions are _.composed() into other functions and
      # need their scope forced
      _.bindAll(this
                'getFirstValue'
                'getIdentifierArray'
                'checkNull'
                'baseGetIntervalsOfTerm'
                'baseGetCustomerData'
                'reset'
                'refreshFail'
                )

    # Does the actual partial application
    applyFunctions : (model, options) ->
      @find = _.partial @findProperty, @get('json')
      @findInLastTerm = _.partial @findProperty, @getLastTerm()
      @findInQuoteTerm = _.partial @findProperty, @getQuoteTerm()

    # Is the argument null or undefined?
    #
    # @param  `arg` any kind of argument
    # @return false || prop
    checkNull : (arg) ->
      if arg == null || arg == undefined
        return false

      arg

    # Take a collection (array) and pop-off the first element. If it has
    # a 'value' property then return it.
    #
    # @param  `collection` _Array_ objs: { name : 'foo', value : 1 }
    # @return _String_ || false
    getFirstValue : (collection) ->
      unless collection?
        return false

      if collection.length > 0 && _.has(collection[0], 'value')
        return collection[0].value

      false

    # **Assemble urls for Policies**
    # @params _String_
    # @return _String_
    url : (route) ->
      url = @get('urlRoot') + 'policies/' + @id
      if route?
        url = "#{url}#{route}"
      url

    # **Get the numeric portion of policy id used in pxServer**
    # @return _String_
    get_pxServerIndex : ->
      doc = @get 'document'
      if doc?
        @set 'pxServerIndex', @getIdentifier('pxServerIndex')
      @get 'pxServerIndex'

    # **Build a last, first policy holder name**
    # @return _String_
    getPolicyHolder : ->
      insured_data = @getCustomerData 'Insured'
      last         = @getDataItem(insured_data, 'InsuredLastName')
      first        = @getDataItem(insured_data, 'InsuredFirstName')

      if last
        last = @Helpers.properName last
      if first
        first = @Helpers.properName first

      @Helpers.concatStrings(last, first, ', ')

    # **Build a policy period date range for use in IPM header**
    # @return _String_
    getPolicyPeriod : ->
      start = @getTermItem('EffectiveDate').substr(0, 10)
      end   = @getTermItem('ExpirationDate').substr(0, 10)
      if start and end
        @Helpers.concatStrings(start, end, ' - ')
      else
        ''

    # **Return the full policy id taken from the XML**
    # @return _String_
    getPolicyId : ->
      id = @getIdentifier('PolicyID')
      if id then id else ''

    getQuoteNumber : ->
      qn = @getIdentifier('QuoteNumber')
      if qn then qn else ''

    getPolicyPrefix : ->
      prefix = @get('policyPrefix')
      unless prefix?
        id = @getPolicyId()
        prefix = id.substring(0, 3)
      prefix

    # **Build an object containing information for the IPM header**
    # @return _Object_
    getIpmHeader : ->
      ipm_header = {}
      policyState = @get('state')?.text or @get('state') or ''
      if @get('document')?
        ipm_header =
          id                      : @getPolicyId()
          product                 : @getProductLabel()
          holder                  : @getPolicyHolder()
          state                   : policyState
          stateClass              : ''
          period                  : @getPolicyPeriod()
          carrier                 : @getModelProperty('Management Carrier')
          parentChildRelationship : @get('parentChildRelationship')
          parentPolicyId          : @get('parentPolicyId')
          childPolicyId           : @get('childPolicyId')

      if @isPendingCancel true
        ipm_header.state      = 'PENDING CANCELLATION'
        ipm_header.stateClass = 'alert-warning'
      else if @isPendingNonRenewal()
        ipm_header.state      = 'PENDING NON-RENEWAL'
        ipm_header.stateClass = 'alert-warning'
      else if policyState is 'CANCELLEDPOLICY'
        ipm_header.state      = 'CANCELLED POLICY'
        ipm_header.stateClass = 'alert-danger'
      else if policyState is 'NONRENEWEDPOLICY'
        ipm_header.state      = 'NON-RENEWED POLICY'
        ipm_header.stateClass = 'alert-danger'
     
      # ICS-1641
      if @isQuote()
        start = (@findInQuoteTerm('EffectiveDate') or '').substr(0, 10)
        end   = (@findInQuoteTerm('ExpirationDate') or '').substr(0, 10)
        ipm_header.id = @getQuoteNumber()
        ipm_header.period = @Helpers.concatStrings(start, end, ' - ')
        ipm_header.isQuote = true
      ipm_header

    getTabLabel : ->
      doc = @get('document')
      $insuredLastName = doc.find('Customer[type="Insured"] DataItem')
          .filter('[name="OpInsuredLastName"],[name="InsuredLastName"]')
          .first()
      # Only return a label if there is a positive match with our query
      # Otherwise return undefined and leave the default label in place
      if $insuredLastName.length
        if @isQuote()
          id = @getQuoteNumber()
        else
          id = @getPolicyId()
        "#{$insuredLastName.attr('value')} #{id}"

    # Assemble all the policy data for HTML QuickView servicing tab into one place
    getServicingData : ->
      propertyData        = if @isQuote() then @get('quoteTerm').ProtoInterval else @getLastTerm()
      insuredData         = @get 'insuredData'
      mortgageeData       = @get 'mortgageeData'
      accountingData      = @getAccountingData() or ''
      accountingDataItems = accountingData.DataItem
      invoiceDueDate      = @getDataItem(accountingDataItems, 'InvoiceDueDateCurrent') or ''
      equityDate          = @getDataItem(accountingDataItems, 'EquityDate') or ''
      pastDueBalance      = @Helpers.formatMoney(@getDataItem(accountingDataItems, 'PastDueBalance'))
      paymentItemLast     = @getLastPaymentLineItem accountingData
      paymentPlan         = accountingData.PaymentPlan or {}
      billingIsPastDue    = pastDueBalance > 0
      policyIsQuote       = @isQuote()

      data =
        QuoteNumber       : @id
        IsQuote           : policyIsQuote
        IsNotQuote        : not policyIsQuote
        PolicyState       : @getPrettyPolicyState()
        OriginatingSystem : @Helpers.prettyMap(@getOriginatingSystem(), {
            'pxClient' : 'Agent Portal'
            'pxServer' : 'Agent Portal'
          }, 'Unknown')
        PropertyAddress   : @getDataItemValues(propertyData.DataItem, [
            'PropertyStreetNumber'
            'PropertyStreetName'
            'PropertyCity'
            'PropertyState'
            'PropertyZipCode'
          ])
        MailingAddress    : @getDataItemValues(insuredData, [
            'InsuredMailingAddressLine1'
            'InsuredMailingAddressLine2'
            'InsuredMailingAddressCity'
            'InsuredMailingAddressState'
            'InsuredMailingAddressZip'
          ])
        PrimaryMortgagee  : @getDataItemValues(mortgageeData, [
            'MortgageeNumber1'
            'Mortgagee1AddressLine1'
            'Mortgagee1AddressLine2'
            'Mortgagee1AddressCity'
            'Mortgagee1AddressState'
            'Mortgagee1AddressZip'
            'LoanNumber1'
          ])
        PropertyCoords     : @getPropertyCoords()
        PolicyId           : @getPolicyId()
        AgencyLocationCode : @getAgencyLocationCode()
        AgencyLocationId   : @getAgencyLocationId()

        # Billing
        BillingIsPastDue   : billingIsPastDue
        BillingIsCurrent   : not billingIsPastDue
        TotalPremium       : @Helpers.formatMoney(@getTermDataItemValue('TotalPremium'))
        OutstandingBalance : @Helpers.formatMoney(@getOutstandingBalance(accountingDataItems))
        MinimumPayment     : @Helpers.formatMoney(@getDataItem(accountingDataItems, 'MinimumPaymentDue'))
        LastPaymentReceived: @getLastPaymentReceived(paymentItemLast)
        Installments       : @getPaymentPlanInstallments(paymentPlan.Installments?.Installment)
        InvoiceDueDate     : @_stripTimeFromDate(invoiceDueDate)
        EquityDate         : @_stripTimeFromDate(equityDate)
        PastDueBalance     : pastDueBalance
        PaymentPlanType    : @Helpers.prettyMap(paymentPlan.type, {
            'invoice'        : 'Invoice'
            'fourPay'        : 'Four Pay'
            'fourPayInvoice' : 'Four Pay Invoice'
            'tenPay'         : 'Ten Pay'
            'tenPayInvoice'  : 'Ten Pay Invoice'
            'fullPay'        : 'Full Pay'
          })

    getUnderwritingData : ->
      if @isQuote()
        dataItems = @findInQuoteTerm('ProtoInterval')?.DataItem
      else if @isFNIC()
        dataItems = @findInLastTerm('Intervals Interval')?.DataItem
      else
        dataItems = @getLastTerm()?.DataItem

      @getDataItemValues(@_sanitizeNodeArray(dataItems), [
          'CoverageA'
          'ReplacementCostBuilding'
          'HurricaneDeductible'
          'WindHailDeductible'
          'AllOtherPerilsDeductible'
          'PropertyHazardLocation'
          'FloorArea'
          'ConstructionYear'
          'RoofAge'
          'RoofCoveringType'
          'RoofGeometryType'
          'PropertyUsage'
          'StructureType'
          'ProtectionClass'
          'InsuranceScoreRange'
        ])

    getProductLabel : ->
      label = @get('document')
        .find('ProductRef [name="Label"]')
        .attr('value')
      unless label
        if @isQuote()
          dataItems = @findInQuoteTerm('ProtoInterval')?.DataItem
        else if @isFNIC()
          dataItems = @findInLastTerm('Intervals Interval')?.DataItem
        else
          dataItems = @getLastTerm()?.DataItem
        label = @getDataItem @_sanitizeNodeArray(dataItems), 'ProductLabel'
      label

    # Map policy state to a prettier version
    getPrettyPolicyState : ->
      prettyStates =
        'ACTIVEPOLICY'        : 'Active Policy'
        'PENDINGCANCELLATION' : 'Pending Cancellation'
        'CANCELLEDPOLICY'     : 'Cancelled Policy'
        'NONRENEWEDPOLICY'    : 'Non-Renewed Policy'
        'PENDINGNONRENEWAL'   : 'Pending Non-Renewal'
        'ACTIVEQUOTE'         : 'Active Quote'
        'INCOMPLETEQUOTE'     : 'Incomplete Quote'
        'EXPIREDQUOTE'        : 'Expired Quote'
      
      # PolicyState is stored in a few different places and ways
      # WARNING: this can get messy
      state = @get('state').text or @get('state')
      policyStates = @get('document').find('PolicyState')

      if @isPendingCancel true
        state = 'PENDINGCANCELLATION'
      else if @isPendingNonRenewal()
        state = 'PENDINGNONRENEWAL'
      else if state is 'ACTIVEQUOTE'
        dataItems = @findInQuoteTerm('ProtoInterval')?.DataItem
        unless @getDataItem @_sanitizeNodeArray(dataItems), 'TotalPremium'
          state = 'INCOMPLETEQUOTE'
      
      @Helpers.prettyMap state, prettyStates

    getOriginatingSystem : ->
      if @isQuote()
        dataItems = @findInQuoteTerm('ProtoInterval')?.DataItem
      else
        dataItems = @getLastTerm()?.DataItem
      @getDataItem @_sanitizeNodeArray(dataItems), 'QuoteOriginationSystem'

    # Prefer Accounting > OutstandingBalanceDue, else fall back to OutstandingBalance
    getOutstandingBalance : (items) ->
      @getDataItem(items, 'OutstandingBalanceDue') || @getDataItem(items, 'OutstandingBalance')

    getLastPaymentLineItem : (accountingData) ->
      lineItems = accountingData?.Ledger?.LineItem
      lineItems = @_sanitizeNodeArray lineItems
      payments  = _.where(lineItems, { type : 'PAYMENT' })
      _.last payments

    # Return formatted version of last payment amount and last payment date
    # <PaymentAmountLast> - <PaymentDateLast> if PaymentDateLast > 1900-01-01
    getLastPaymentReceived : (paymentItem) ->
      if _.isObject paymentItem
        dataItems = @_sanitizeNodeArray paymentItem.DataItem
        appliedDate = @getDataItem dataItems, 'appliedDate'
        amount = @Helpers.formatMoney paymentItem.value
        date = @_stripTimeFromDate(appliedDate) if appliedDate
        unixInterval = Date.parse date
        if unixInterval > -1
          "#{amount} - #{date}"

    # Accounting.PaymentPlan.Installments is a mess of different possible data types
    # Try to standardize it to an array of installment objects
    getPaymentPlanInstallments : (installments) ->
      installments = @_sanitizeNodeArray installments
      _.map(installments, (item) =>
        item.amount = @Helpers.formatMoney item.amount
        item.charges = @Helpers.formatMoney item.charges
        item.feesAndPremiums = @Helpers.formatMoney item.feesAndPremiums
        return item
        )

    getPaymentPlanType : ->
      accountingData = @getAccountingData()
      paymentPlan = accountingData?.PaymentPlan
      paymentPlan.type if paymentPlan

    # Retrieve Lat/Long coords from last policy term
    # Return empty result if Lat/Long does not exist
    getPropertyCoords : ->
      if @isQuote()
        $protoInterval = @get('document').find('ProtoInterval')
        coords =
          Latitude  : $protoInterval.find('[name="Latitude"]').attr('value')
          Longitude : $protoInterval.find('[name="Longitude"]').attr('value')
      else
        coords =
          Latitude  : @getTermDataItemValue 'Latitude'
          Longitude : @getTermDataItemValue 'Longitude'
      coords if coords.Latitude and coords.Longitude

    # **Get <SystemOfRecord>** - used to determine IPM eligibility.
    # @return _String_
    getSystemOfRecord : -> @getModelProperty('Management SystemOfRecord')

    # **Is this an IPM policy?**
    # @return _Boolean_
    isIPM : -> @getSystemOfRecord() == 'mxServer'

    # **Is this an IPM policy?**
    # @return _Boolean_
    isDovetail : -> @getSystemOfRecord() == 'Dovetail'

    # Checks for <Flag name="Moved" value="true"/> in <Management>
    # @return _Boolean_
    isMoved : ->
      moved = _.filter @getModelProperty('Management Flags Flag'), (item) ->
        if _.has(item, 'name') && !_.isUndefined(item.name) && item.name.toLowerCase() == 'moved'
          _.has(item, 'value') && item.value == 'true'
      moved.length > 0

    # **Get attributes of an element**
    # Check a node for attributes and return as an obj, else null
    # @param `elem` _jQuery Element_
    # @return _Obj_ | _Null_
    _getAttributes : (elem) ->
      out = null

      if elem[0]? && elem[0].attributes?
        out = {}
        attribs = elem[0].attributes
        for attr in attribs
          out[attr.name] = attr.value

      out

    # **Determine the state of a policy**
    # If a node has no attributes, the node's text value is returned.
    # When the node has attributes, an Object is returned containing
    # the text value + attributes
    # @return _String_ | _Obj_
    getState : ->
      if @get('document')?
        policyState = @get('document').find('Management PolicyState')
        text        = policyState.text()
        attr        = @_getAttributes(policyState)
        if attr == null
          text
        else
          _.extend(attr, { 'text' : text })

    # **Determine if a policy is cancelled**
    # @return _Boolean_
    isCancelled : ->
      state = @getState()
      state == 'object' && state.text == 'CANCELLEDPOLICY'

    # **Is this policy actually a quote?**
    # @return _Boolean_
    isQuote : ->
      state = @getState()
      text = if typeof state == 'object' then state.text else state
      text == @states.ACTIVE_QUOTE or text == @states.EXPIRED_QUOTE

    isFNIC : ->
      programAdmin = @find('Management ProgramAdministrator')
      /fnic/gi.test programAdmin

    # **Is this policy pending cancellation?**
    # User can specify a boolean return (bool = true) or
    # will get back the pending cancel object
    #
    # @param `bool` _Boolean_ return boolean or object
    # @return _Boolean_ | _Obj_
    isPendingCancel : (bool) ->
      pending = @get('json')?.Management?.PendingCancellation
      if _.isObject pending
        if bool
          return true
        else
          return pending
      false

    # **Is this policy pending non-renewal?**
    #
    # @return _Boolean_
    isPendingNonRenewal : ->
      pending = @get('json')?.Management?.PendingNonRenewal
      if _.isObject pending
        true
      else
        false

    # **Determine the cancellation effective date if there is one**
    # @return _String_ | _Null_
    getCancellationEffectiveDate : ->
      state          = @getState()
      effective_date = null
      switch state
        when "ACTIVEPOLICY"
          if @isPendingCancel(true)
            effective_date = @isPendingCancel().cancellationEffectiveDate
        when "CANCELLEDPOLICY"
          effective_date = @getModelProperty('Management PolicyState effectiveDate')
        else
          effective_date = null
      effective_date

    # **Return the cancellation reason code if present, else null**
    # @return _Integer_ | _Null_
    getCancellationReasonCode : ->
      state       = @getState()
      reason_code = null
      pending     = @isPendingCancel()

      state = if typeof state == 'object' then state.text else state

      switch state
        when 'ACTIVEPOLICY'
          if pending then reason_code = parseInt pending.reasonCode, 10
        when 'CANCELLEDPOLICY'
          reason_code = @getModelProperty('Management PolicyState reasonCode')
          reason_code = parseInt reason_code, 10
        else
          reason_code = null

      reason_code

    # **Return the Terms of the policy**
    # @return _Array_
    getTerms : ->
      terms = false
      if @get('json')?.Terms?.Term?
        terms = @get('json').Terms.Term

      # If there are multiple terms then return the array, otherwise
      # create an array from the Term obj
      if _.isArray(terms)
        return terms
      if _.isObject(terms)
        return [terms]

    # **Return the last Term of the policy**
    # TODO: Check to make sure we're not just looking for <Intervals>
    # @return _Obj (XML)_
    getLastTerm : ->
      if terms = @getTerms()
        _.last terms
      else
        {}

    # **Return the first Term of the policy**
    # TODO: Check to make sure we're not just looking for <Intervals>
    # @return _Obj (XML)_
    getFirstTerm : ->
      if terms = @getTerms()
        _.first terms
      else
        {}

    # **Return ProtoTerm of a policy Quote if it exists**
    # @return _Obj_
    getQuoteTerm : ->
      if @isQuote() && protoTerm = @get('json')?.Quoting?.CurrentQuote?.ProtoTerm
        protoTerm
      else
        {}

    # Retrieve a single value from Last Term or send empty string
    getTermItem : (item) ->
      last_term = @getLastTerm()
      if last_term[item]? then last_term[item] else ''

    # **Return array of Customer <DataItem> objects by customer type**
    # @param `type` _String_
    # @return _Array_ | _False_
    baseGetCustomerData : (type) ->
      customer = _.filter(@getModelProperty('Customers Customer'), (c) ->
          return c.type == type
        )

      if customer.length > 0
        return customer[0].DataItem
      else
        return false

    # getCustomerData wrapped in null check
    getCustomerData : (type) ->
      _.compose(@baseGetCustomerData, @checkNull) type

    getAccountingData : ->
      @getModelProperty 'Accounting'

    # **Retrieve Policy Events**
    # @return _Array_ Policy Events or empty
    getEvents : ->
      events = @getModelProperty 'EventHistory'
      @_sanitizeNodeArray events?.Event

    # **Retrieve Policy Documents**
    # @return _Array_ Policy Documents or empty
    getDocuments : ->
      documents = @getModelProperty 'Documents'
      @_sanitizeNodeArray documents?.Reference

    # **Retrieve Policy Notes**
    # @return _Array_ Policy Notes or empty
    getNotes : ->
      notes = @getModelProperty 'RelatedItems Notes'
      @_sanitizeNodeArray notes?.Note

    # **Retrieve Policy Tasks**
    # @return _Array_ Policy Tasks or empty
    getTasks : ->
      tasks = @getModelProperty 'RelatedItems Tasks'
      @_sanitizeNodeArray tasks?.Task

    # **Retrieve Policy Documents**
    # @return _Array_ Policy Documents or empty
    getAttachments : ->
      attachments = @getModelProperty 'RelatedItems Attachments'
      @_sanitizeNodeArray attachments?.Attachment

    # **Notes field handling, post a notes ChangeSet**
    #
    # @param `note` _String_ Policy notes
    # @param `attachments` _Array_ list of attachment objects
    # @param `callbackSuccess` _Function_ Handle successful POST
    # @param `callbackError` _Function_ Handle error state
    # return an object with content roughly equivalent to the policyXML
    #
    postNote : (note='', attachments=[], callbackSuccess, callbackError) ->
      noteData =
        CreatedTimeStamp : new Date() + ''
        CreatedBy        : @get('module').view.controller.user.get('username')
        Content          : $.trim note
        Attachments      : attachments

      if noteData.Content.length or noteData.Attachments.length
        xml = """
          <PolicyChangeSet schemaVersion="2.1" username="{{{CreatedBy}}}" description="Added via Policy Central">
            {{#Content}}
            <Note>
              <Content><![CDATA[{{{Content}}}]]></Content>
            </Note>
            {{/Content}}
            {{#Attachments.length}}
            <Attachments>
              {{#Attachments}}
              <Attachment name="{{fileName}}" contentType="{{{fileType}}}">
                <Description/>
                <Location>{{{location}}}{{objectKey}}</Location>
              </Attachment>
              {{/Attachments}}
            </Attachments>
            {{/Attachments.length}}
          </PolicyChangeSet>
        """

        # Assemble the AJAX params
        params =
          url         :  @url()
          type        : 'POST'
          dataType    : 'xml'
          contentType : 'application/xml; schema=policychangeset.2.1'
          context     : this
          data        : Mustache.render xml, noteData
          headers     :
            'Authorization' : "Basic #{@get('digest')}"
            'Accept'        : 'application/vnd.ics360.insurancepolicy.2.8+xml'
            'X-Commit'      : true

        jqXHR = $.ajax params
        if _.isFunction(callbackSuccess) && _.isFunction(callbackError)
          $.when(jqXHR).then callbackSuccess, callbackError

      noteData

    # **Retrieve intervals of given Term obj**
    # @param `term` _Object_ Term obj
    # @return _Array_ Interval objs
    baseGetIntervalsOfTerm : (term) ->
      out = []

      if term.Intervals?.Interval?
        if _.isArray(term.Intervals.Interval)
          out = term.Intervals.Interval
        else
          out = [term.Intervals.Interval]

      out

    # getIntervalsOfTerm wrapped in null check
    getIntervalsOfTerm : (term) ->
      _.compose(@baseGetIntervalsOfTerm, @checkNull) term

    # **Get the last interval of the last term of the policy**
    # !!! Unclear if this is what should be returned
    # @return _Object_
    getLastInterval : ->
      term = @getIntervalsOfTerm(@getLastTerm())
      if term && _.isArray(term)
        out = term[term.length - 1]
      else
        out = {}
      out

    # **Derive the product name from policy information**
    # @return _String_
    getProductName : ->
      name = @get('productName')
      unless name?
        terms = @getLastTerm()

        # CRU4 return DataItem objs directly, in CRU6 we have to go
        # searching through Intervals to find the correct DataItem obj
        if terms.DataItem?
          terms = terms.DataItem
        else if terms.Intervals?.Interval?
          if _.isArray(terms.Intervals.Interval)
            terms = terms.Intervals.Interval[0].DataItem
          else
            terms = terms.Intervals.Interval.DataItem

        program        = @getDataItem terms, 'Program'
        policy_type    = @getDataItem terms, 'PolicyType'
        property_state = @getDataItem terms, 'PropertyState'
        name = "#{program}-#{policy_type}-#{property_state}"
        name = @_resolveProductNameCollision(name).toLowerCase()
      name

    # **Find <Identifier> by name and return value or false**
    # @param `name` _String_ name attr of element
    # @return _Array_
    getIdentifierArray : (name) ->
      if @get('json').Identifiers?.Identifier?
        return _.where(@get('json').Identifiers.Identifier, { name : name })
      false

    # Returns first value of _getIdentifier after null checks
    # @return _String_ | false
    getIdentifier : (name) ->
      _.compose(@getFirstValue, @getIdentifierArray, @checkNull) name

    # **Find <Event> with type=Issue**
    # @return _Boolean_
    isIssued : ->
      if @get('json').EventHistory?.Event?
        issued = _.findWhere(@get('json').EventHistory.Event, { type : 'Issue' })
        return _.isObject issued
      false

    # **Products with naming collisions (ICS-2475)**
    # as defined in the @PRODUCT_COLLISIONS list
    # only augment product name if the policy prefix is
    # in the list of @SPECIAL_PROGRAMS
    #
    # @param `product_name` _String_
    # @return _String_ the product name, modified or not
    _resolveProductNameCollision : (product_name) ->
      if product_name in @PRODUCT_COLLISIONS
        policy_prefix = @getPolicyPrefix()
        if policy_prefix in @SPECIAL_PROGRAMS
          product_name = "#{product_name}-#{policy_prefix}"
      product_name


    # **TODO: MOVE INTO HELPER MIXIN**
    # Some date strings we'll be dealing with are formatted with a full
    # timestamp like: "2011-01-15T23:00:00-04:00". The time, after the "T"
    # can sometimes cause weird rounding issues with the day. To safegaurd
    # against it, we'll just remove the "T" and everything after it.
    #
    # @param `date` _String_ A date string
    # @return _String_ An ISO formatted date string
    _stripTimeFromDate : (date) ->
      clean  = date
      t      = date.indexOf('T')
      if t > -1
        clean = clean.substring(0, t)
      @_formatDate clean

    # Format a date, defaulting to ISO format
    #
    # @param `date` _String_ A date string
    # @param `format` _String_ A date format string
    # @return _String_
    _formatDate : (date, format) ->
      format = format ? 'YYYY-MM-DD'
      if moment(date)?
        moment(date).format(format)

    # Helper function to map all string values to lowercase
    _toLowerCase : (val) ->
      if _.isString val
        val.toLowerCase()
      else
        val

    # Because of the quirky way the xml is parsed to json
    # Possible data types returned can be unreliable, especially for
    # Arrays of items. This is an attempt to sanitize the results
    _sanitizeNodeArray : (node) ->
      items = node || []
      unless _.isArray items
        items = [items]
      items

    # **Get the OpPolicyTerm value** from the last Term
    # @return _String_
    getPolicyTerm : ->
      doc = @get('document')
      if doc?.length
        items = doc.find("Terms Term > DataItem[name=OpPolicyTerm]")
        policy_term = items.last().attr('value')
      policy_term

    # **Determine policy effective date** from XML and convert to
    # standardized format
    # @return _String_
    getEffectiveDate : ->
      date = @getTermItem('EffectiveDate')
      if date != undefined && date != ''
        @_stripTimeFromDate date
      else
        false

    # **Determine policy inception date**
    # This is the effective date of the *first* term
    # @return _String_
    getInceptionDate : ->
      first_term = @getFirstTerm()
      date = first_term['EffectiveDate'] || ''
      if date != undefined && date != ''
        @_stripTimeFromDate date
      else
        false

    # **Determine policy effective date** from XML and convert to
    # standardized format
    # @return _String_
    getExpirationDate : ->
      date = @getTermItem('ExpirationDate')
      if date != undefined && date != ''
        @_stripTimeFromDate date
      else
        false

    # For each vocabTerms look for a DataItem in LastTerm and get its value.
    # We favor the Op{name} version of the DataItem
    #
    # @param `vocabTerms` _Object_ list of terms from ixVocab / model.json
    # @param `term` _Object_ Term object from Policy
    # @return _Object_
    #
    getTermDataItemValues : (vocabTerms, term = null) ->
      term = @getLastTerm().DataItem if _.isNull(term)
      out  = {}
      for vocab in vocabTerms.terms
        out[vocab.name] = @getDataItem term, vocab.name
      out

    # Grab the Data Item Value for the latest Term
    #
    # @param `name` _String_
    # @return _String_
    #
    getTermDataItemValue : (name) ->
      items = @getLastTerm().DataItem
      items = @_sanitizeNodeArray items
      @getDataItem items, name

    # **Extract the value of a named <DataItem> from a JSON collection**
    # _Alert_: Policies contain multiple versions of some fields, and we favor
    # the Op{name} version of the DataItem
    #
    # @param `items` _Object_ list of terms
    # @param `name` _String_ name of term value to find
    # @return _String_ | _False_
    #
    getDataItem : (items, name) ->
      if items == undefined || name == undefined
        return false
      op_name = "Op#{name}"

      # First try to find OpName
      data_obj = _.filter(items, (item) -> return item.name == op_name)

      # If no OpName then look for the original name
      if data_obj.length == 0
        data_obj = _.filter(items, (item) -> return item.name == name)

      if _.isArray(data_obj) && data_obj[0]?
        data_obj[0].value
      else
        false

    # For each terms look for a JSON list DataItem and get its value.
    #
    # @param `list` _Object_ JSON DataItems list
    # @param `terms` _Array_ list of terms to search for
    # @return _Object_
    #
    getDataItemValues : (list, terms) ->
      out = {}
      _.each(terms, ((term) ->
        val = @getDataItem list, term
        out[term] = val if val
        ), this)
      out unless _.isEmpty out

    # Check vocabTerms for enumerations fields and append to the viewData
    # object with a default field added.
    #
    # @param `viewData` _Object_ An object of Data Items to append enums to
    # @param `vocabTerms` _Object_ list of terms from ixVocab / model.json
    # @return _Object_
    #
    getEnumerations : (viewData, vocabTerms) ->
      viewData ?= {}
      empty =
        value : ''
        label : 'Select'

      for term in vocabTerms.terms
        if _.has(term, 'enumerations') && term.enumerations.length > 0
          viewData["Enums#{term.name}"] = [].concat empty, term.enumerations

      viewData

    # Convenience method to find a value in the Policy XML. Can handle DataItem
    # fields by setting the dataItem bool to true
    #
    # @param `path` _String_ jQuery path to use in search
    # @param `dataItem` _Boolean_ search for DataItem instead of text node
    # @return _String_
    #
    getValueByPath : (path, dataItem) ->
      path ?= ''
      if dataItem?
        @get('document').find(path).attr('value')
      else
        @get('document').find(path).text()

    # Return the version number
    getPolicyVersion : ->
      @getModelProperty 'Management Version'

    getAgencyLocationId : ->
      @getModelProperty 'Management AgencyLocationId'

    getAgencyLocationCode : ->
      @getModelProperty 'Management AgencyLocationCode'

    getParentPolicyId : ->
      @getIdentifier 'ParentPolicyID'

    getChildPolicyId : ->
      @getIdentifier 'ChildPolicyID'

    getParentInsightPolicyId : ->
      @getIdentifier 'ParentInsightPolicyId'

    getChildInsightPolicyId : ->
      @getIdentifier 'ChildInsightPolicyId'

    determineParentChildRelationship : ->
      if @get('childPolicyId') and @get('parentPolicyId')
        @set 'parentChildRelationship', 'has-both'
      else if @get 'childPolicyId'
        @set 'parentChildRelationship', 'has-child'
      else if @get 'parentPolicyId'
        @set 'parentChildRelationship', 'has-parent'
      else
        @set 'parentChildRelationship', 'has-none'

    hasLinks : ->
      if @get('parentChildRelationship') is 'has-none'
        false
      else
        true

    # Return Policy data for use in overviews
    getPolicyOverview : ->
      terms = [
        'InsuredFirstName',
        'InsuredMiddleName',
        'InsuredLastName',
        'InsuredMailingAddressLine1',
        'InsuredMailingAddressLine2',
        'InsuredMailingAddressCity',
        'InsuredMailingAddressState',
        'InsuredMailingAddressZip'
      ]
      customerData = @get 'insuredData'
      @getDataItemValues(customerData, terms)

    # Recursively search the model JSON for properties based
    # on a space separated path: 'Management Flags Flag'
    getModelProperty : (path, obj) ->
      # If no object then get the top level JSON model
      if _.nully(obj) then obj = @get('json')
      @findProperty obj, path


    # **Set a variety of properties on the model based on XML policy data**
    setModelState : ->
      if @get('document')?.length
        @set(
          'state': @getState()
          'quote': @isQuote()
          'pendingCancel': @isPendingCancel()
          'cancellationEffectiveDate': @getCancellationEffectiveDate()
          'cancelled': @isCancelled()
          'terms': @getTerms()
          'firstTerm': @getFirstTerm()
          'quoteTerm': @getQuoteTerm()
          'lastInterval': @getLastInterval()
          'insuredData': @getCustomerData('Insured')
          'mortgageeData': @getCustomerData('Mortgagee')
          'additionalInterestData': @getCustomerData('AdditionalInterest')
          'productName': @getProductName()
          'policyPrefix': @getPolicyPrefix()
          'insightId': @getIdentifier('InsightPolicyId')
          'policyId': @getPolicyId()
          'isIssued': @isIssued()
          'effectiveDate': @getEffectiveDate()
          'expirationDate': @getExpirationDate()
          'version': @getPolicyVersion()
          'parentPolicyId': @getParentPolicyId()
          'childPolicyId': @getChildPolicyId()
          'parentInsightPolicyId': @getParentInsightPolicyId()
          'childInsightPolicyId': @getChildInsightPolicyId()
          )

    # **Grab the latest version of the Policy**
    #
    # @param `view_id` _String_ The cid of the calling view
    #
    refresh : (view_id) ->
      xhr = $.ajax(
        url     : @url()
        type    : 'GET'
        headers :
          'Authorization' : "Basic #{@get('digest')}"
          'Cache-Control' : 'no-cache'
        )
      xhr.done @reset(view_id)
      xhr.fail @refreshFail(view_id)
      return this

    # **Load new Policy XML into Model**
    #
    # Inject the new policy XML into the model and setModelState()
    #
    # @param `view_id` _String_ The cid of the calling view
    # @return _Func_ Closure to handle jqXHR response
    #
    reset : (view_id) ->
      view_id = view_id || @get('module').policy_view.cid
      (data, textStatus, jqXHR) =>
        new_attributes = @parse(data, jqXHR)

        # Swap out Policy XML with new XML, saving the old one
        new_attributes.prev_document =
          document : @get('document')
          json     : @get('json')

        # Model.set() chokes on something in the response object,
        # so we just jam the values into attributes directly.
        for key, val of new_attributes
          @attributes[key] = val

        @trigger 'change:refresh', textStatus
        @Amplify.publish(view_id, 'success',
          "Policy #{@get('policyId')} refreshed!", 2000)

        @trigger 'change', this

    # **Handle jqXHR failure**
    #
    # Throw a hopefully helpful error
    #
    # @param `view_id` _String_ The cid of the calling view
    # @return _Func_ Closure to handle jqXHR response
    #
    refreshFail : (view_id) ->
      view_id = view_id || @get('module').policy_view.cid
      (jqXHR, textStatus, errorThrown) =>
        @trigger 'change:refresh', textStatus
        @Amplify.publish(view_id, 'warning',
          "There was an error refreshing the policy: #{jqXHR.status} (#{errorThrown})", 2000)
        return this

  PolicyModel

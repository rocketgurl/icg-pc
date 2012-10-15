define [
  'BaseModel'
], (BaseModel) ->

  #### Policy
  #
  # We handle Policy XML here
  #
  PolicyModel = BaseModel.extend

    # Policy states
    # -------------
    states : 
      ACTIVE_POLICY      : 'ACTIVEPOLICY',
      ACTIVE_QUOTE       : 'ACTIVEQUOTE',
      CANCELLED_POLICY   : 'CANCELLEDPOLICY',
      EXPIRED_QUOTE      : 'EXPIREDQUOTE',
      NON_RENEWED_POLICY : 'NONRENEWEDPOLICY'

    initialize : ->
      @use_cripple() # Use CrippledClient XMLSync

      # When the model is loaded, make sure its state is current
      @on 'change', (e) ->
        e.setModelState()

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
      @set 'pxServerIndex', doc.find('Identifiers Identifier[name=pxServerIndex]').attr('value')
      @get 'pxServerIndex'

    # **Build a last, first policy holder name**  
    # @return _String_
    get_policy_holder : ->
      doc = @get 'document'
      last = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredLastName]').attr('value')
      first = doc.find('Customers Customer[type=Insured] DataItem[name=OpInsuredFirstName]').attr('value')
      "#{last}, #{first}"

    # **Build a policy period date range for use in IPM header**  
    # @return _String_
    get_policy_period : ->
      doc   = @get 'document'
      start = doc.find('Terms Term EffectiveDate').text().substr(0,10)
      end   = doc.find('Terms Term ExpirationDate').text().substr(0,10)
      "#{start} - #{end}"

    # **Build an object containing information for the IPM header**  
    # @return _Object_
    get_ipm_header : ->
      doc = @get 'document'
      ipm_header =
        id      : doc.find('Identifiers Identifier[name=PolicyID]').attr('value')
        product : doc.find('Terms Term DataItem[name=OpProductLabel]').attr('value')
        holder  : @get_policy_holder()
        state   : doc.find('Management PolicyState').text()
        period  : @get_policy_period()
        carrier : doc.find('Management Carrier').text()
      ipm_header

    # **Get <SystemOfRecord>** - used to determine IPM eligibility.  
    # @return _String_
    getSystemOfRecord : ->
      @get('document').find('Management SystemOfRecord').text()

    # **Is this an IPM policy?**  
    # @return _Boolean_
    isIPM : ->
      if @getSystemOfRecord() == 'mxServer' then true else false

    # **Get attributes of an element**  
    # Check a node for attribures and return as an obj, else null  
    # @param `elem` _jQuery Element_
    # @return _Obj_ | _Null_
    _getAttributes : (elem) ->
      out = {}
      attribs = elem[0].attributes
      for attr in attribs
        out[attr.name] = attr.value 
      return if _.isEmpty(out) then null else out

    # **Determine the state of a policy**  
    # If a node has no attributes, the node's text value is returned. 
    # When the node has attributes, an Object is returned containing
    # the text value + attributes    
    # @return _String_ | _Obj_
    getState : ->
      policyState = @get('document').find('Management PolicyState')
      text        = policyState.text()
      attr        = @_getAttributes(policyState)
      if attr is null
        text
      else
        _.extend(attr, { 'text' : text })

    # **Determine if a policy is cancelled**  
    # @return _Boolean_ 
    isCancelled : ->
      state     = @getState()
      if typeof state == 'object' && state.text = 'CANCELLEDPOLICY'
        true
      else
        false

    # **Is this policy actually a quote?**  
    # @return _Boolean_ 
    isQuote : ->
      state = @getState()
      text = if typeof state == 'object' then state.text else state
      return text == @states.ACTIVE_QUOTE or text == @states.EXPIRED_QUOTE

    # **Is this policy pending cancellation?** 
    # User can specify a boolean return (bool = true) or
    # will get back the pending cancel object
    #
    # @param `bool` _Boolean_ return boolean or object  
    # @return _Boolean_ | _Obj_
    isPendingCancel : (bool) ->
      pending = @get('json').Management.PendingCancellation || false
      return true if (bool && pending) 
      pending

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
          effective_date = @get('json').Management.PolicyState.effectiveDate
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
          reason_code = @get('json').Management.PolicyState.reasonCode
          reason_code = parseInt reason_code, 10
        else
          reason_code = null

      reason_code

    # **Return the Terms of the policy as an array of XML nodes** 
    # @return _Array_
    getTerms : ->
      terms = false
      if @get('json').Terms.Term?
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
      if @getTerms()
        @getTerms().pop()
      else
        {}

    # **Return array of Customer <DataItem> objects by customer type**  
    # @param `type` _String_ 
    # @return _Array_ | _False_
    getCustomerData : (type) ->
      if type == null || type == undefined
        return false

      customer = _.filter(@get('json').Customers.Customer, (c) ->
          return c.type == type
        )

      if customer.length > 0
        return customer[0].DataItem
      else
        return false

    # **Retrieve intervals of given Term obj**  
    # @param `term` _Object_ Term obj
    # @return _Array_ Interval objs
    getIntervalsOfTerm : (term) ->
      if term == null || term == undefined
        return false

      if _.isArray term
        term = term.shift()

      intervals = []

      out = false

      if term.Intervals?
        if _.isArray term.Intervals.Interval
          out = term.Intervals.Interval
        else
          out = [term.Intervals.Interval]

      out

    # **Get the last interval of the last term of the policy**
    # !!! Unclear if this is what should be returned 
    # @return _Object_
    getLastInterval : ->
      term = @getIntervalsOfTerm(@getLastTerm())
      if term && _.isArray(term)
        term.pop()
      else
        {}

    # **Derive the product name from policy information**  
    # @return _String_
    getProductName : ->
      name = null
      terms = @getLastTerm().DataItem
      name = "#{@getDataItem(terms, 'OpProgram')}-#{@getDataItem(terms, 'OpPolicyType')}-#{@getDataItem(terms, 'OpPropertyState')}"
      name.toLowerCase()

    # **Extract the value of a named <DataItem> from a collection**  
    # @return _String_ | _False_
    getDataItem : (items, name) ->
      if items == undefined || name == undefined
        return false

      data_obj = _.filter(items, (item) -> return item.name == name)
      if _.isArray(data_obj) && _.has(data_obj[0], 'value')
        data_obj[0].value
      else
        false

    # **Find <Identifier> by name and return value or false**  
    # @param `name` _String_ name attr of element
    # @return _String_ | _False_
    getIdentifier : (name) ->
      if name == null || name == undefined
        return false
      @get('document').find("Identifier Indentifiers[name=#{name}]").attr('value')

    # **Find <Event> with type=Issue**  
    # @return _Boolean_ 
    isIssued : ->
      history = @get('document').find('EventHistory Event[type=Issue]')
      if history.length > 0
        true
      else
        false

    # **TODO: MOVE INTO HELPER MIXIN**  
    # Some date strings we'll be dealing with are formatted with a full
    # timestamp like: "2011-01-15T23:00:00-04:00". The time, after the "T"
    # can sometimes cause weird rounding issues with the day. To safegaurd
    # against it, we'll just remove the "T" and everything after it.
    #
    # @param `date` _String_ A date string  
    # @return _String_ 
    _stripTimeFromDate : (date) ->
      clean = date
      t = date.indexOf('T')
      if t > -1
        clean = clean.substring(0, t)
      date = new Date(clean)
      "#{date.getFullYear()}-#{date.getMonth()}-#{date.getDate()}"

    # **Determine policy effective date** from XML and convert to
    # standardized format  
    # @return _String_ 
    getEffectiveDate : ->
      date = @get('document').find('Terms Term EffectiveDate').text()
      if date != undefined || date != ''
        @_stripTimeFromDate date
      else
        false

    # **Determine policy effective date** from XML and convert to
    # standardized format  
    # @return _String_ 
    getExpirationDate : ->
      date = @get('document').find('Terms Term ExpirationDate').text()
      if date != undefined || date != ''
        @_stripTimeFromDate date
      else
        false

    # **Set a variety of properties on the model based on XML policy data**  
    setModelState : ->
      @set('state', @getState())
      @set('quote', @isQuote())
      @set('pendingCancel', @isPendingCancel())
      @set('cancellationEffectiveDate', @getCancellationEffectiveDate())
      @set('cancelled', @isCancelled())
      @set('terms', @getTerms())
      @set('lastInterval', @getLastInterval())
      @set('insuredData', @getCustomerData('Insured'))
      @set('mortgageeData', @getCustomerData('Mortgagee'))
      @set('additionalInterestData', @getCustomerData('AdditionalInterest'))
      @set('productName', @getProductName())
      @set('insight_id', @getIdentifier('InsightPolicyId'))
      @set('isIssued', @isIssued())
      @set('effectiveDate', @getEffectiveDate())
      @set('expirationDate', @getExpirationDate())

     
  PolicyModel
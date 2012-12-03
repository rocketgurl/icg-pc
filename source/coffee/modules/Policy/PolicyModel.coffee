define [
  'BaseModel'
], (BaseModel) ->

  #### Policy
  #
  # We handle Policy XML here
  #
  PolicyModel = BaseModel.extend

    NAME : 'Policy'

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
        e.checkModelState()

    # Guard code here because change event fires before response_state()
    checkModelState : ->
      if @get('fetch_state') == undefined
        @response_state()
        if @get('fetch_state').code == '200'
          try
            @setModelState()
          catch e
            @trigger 'policy_error', this    

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

    # **Return the full policy id taken from the XML**  
    # @return _String_
    get_policy_id : ->
      @get('document').find('Identifiers Identifier[name=PolicyID]').attr('value')

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
      doc = @get('document')
      if doc?
        doc.find('Management SystemOfRecord').text()

    # **Is this an IPM policy?**  
    # @return _Boolean_
    isIPM : ->
      if @getSystemOfRecord() == 'mxServer' then true else false

    # **Get attributes of an element**  
    # Check a node for attribures and return as an obj, else null  
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
      if typeof state == 'object' && state.text == 'CANCELLEDPOLICY'
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
      if terms = @getTerms()
        _.last terms
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

      out = []

      if _.has(term, 'Intervals') && _.has(term.Intervals, 'Interval')
        if _.isArray(term.Intervals.Interval)
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
        out = term[term.length - 1]
      else
        out = {}
      out

    # **Derive the product name from policy information**  
    # @return _String_
    getProductName : ->
      name  = null
      terms = @getLastTerm().DataItem
      name  = "#{@getDataItem(terms, 'Program')}-#{@getDataItem(terms, 'PolicyType')}-#{@getDataItem(terms, 'PropertyState')}"
      name.toLowerCase()

    # **Find <Identifier> by name and return value or false**  
    # @param `name` _String_ name attr of element
    # @return _String_ | _False_
    getIdentifier : (name) ->
      if name == null || name == undefined
        return false
      @get('document').find("Identifiers Identifier[name=#{name}]").attr('value')

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

    # For each vocabTerms look for a Term DataItem and get its value. We favor
    # the Op{name} version of the DataItem
    #
    # @param `vocabTerms` _Object_ list of terms from ixVocab / model.json    
    # @return _Object_  
    #
    getTermDataItemValues : (vocabTerms) ->
      out = {}
      for term in vocabTerms.terms
        out[term.name] = 
          @get('document').find("Terms Term DataItem[name=Op#{term.name}]").attr('value') ||
          @get('document').find("Terms Term DataItem[name=#{term.name}]").attr('value')
        if out[term.name] == undefined
          out[term.name] = false
      out

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
      for term in terms
        out[term] = @getDataItem list, term
      out

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


    # **Set a variety of properties on the model based on XML policy data**  
    setModelState : ->
      if @get('document')? || @get('document') != undefined
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
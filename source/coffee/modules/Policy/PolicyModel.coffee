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

    # Setup model
    # -----------
    # Notice the forced binding in initialize() - this aids
    # function composition later. Functions prefixed with _
    # are 'private' and used in compositions.
    #
    initialize : ->
      @use_xml() # Use CrippledClient XMLSync

      # When the model is loaded, make sure its state is current
      @on 'change', (e) ->
        e.setModelState()
        e.get_pxServerIndex()

      # Explicitly bind 'private' composable functions to this object
      # scope. These functions are _.composed() into other functions and
      # need their scope forced
      for f in ['getFirstValue', 'getIdentifierArray', 'checkNull', 'baseGetIntervalsOfTerm', 'baseGetCustomerData']
        @[f] = _.bind @[f], this

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
      start = @getTermItem('EffectiveDate').substr(0,10)
      end   = @getTermItem('ExpirationDate').substr(0,10)
      @Helpers.concatStrings(start, end, ' - ')

    # **Return the full policy id taken from the XML**
    # @return _String_
    getPolicyId: ->
      id = @getIdentifier('PolicyID')
      if id then id else ''

    # **Build an object containing information for the IPM header**
    # @return _Object_
    getIpmHeader : ->
      doc = @get 'document'
      imp_header = {}
      if doc?
        ipm_header =
          id      : @getPolicyId()
          product : @getTermDataItemValue 'ProductLabel'
          holder  : @getPolicyHolder()
          state   : @get('state').text || @get('state')
          period  : @getPolicyPeriod()
          carrier : @getModelProperty('Management Carrier')
      ipm_header

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

    # **Is this policy pending cancellation?**
    # User can specify a boolean return (bool = true) or
    # will get back the pending cancel object
    #
    # @param `bool` _Boolean_ return boolean or object
    # @return _Boolean_ | _Obj_
    isPendingCancel : (bool) ->
      pending = if @get('json').Management?.PendingCancellation?
                  @get('json').Management.PendingCancellation
                else
                  false
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
      if @get('json').Terms?.Term?
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

      name  = "#{@getDataItem(terms, 'Program')}-#{@getDataItem(terms, 'PolicyType')}-#{@getDataItem(terms, 'PropertyState')}"
      name.toLowerCase()

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
      date = @getTermItem('EffectiveDate')
      if date != undefined || date != ''
        @_stripTimeFromDate date
      else
        false

    # **Determine policy effective date** from XML and convert to
    # standardized format
    # @return _String_
    getExpirationDate : ->
      date = @getTermItem('ExpirationDate')
      if date != undefined || date != ''
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

    # We favor the Op{name} version of the DataItem
    #
    # @param `name` _String_
    # @return _String_
    #
    getTermDataItemValue : (name) ->
      doc = @get('document')
      if doc?
        value = doc.find("Terms Term DataItem[name=Op#{name}]").attr('value') || doc.find("Terms Term DataItem[name=#{name}]").attr('value')
      value

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

    # Return the version number
    getPolicyVersion : ->
      @getModelProperty('Management Version')

    getAgencyLocationId : ->
      @getModelProperty('Management AgencyLocationId')

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
      if obj == null || obj == undefined then obj = @get 'json'

      # If path is empty array then we're done recurring
      if _.isArray(path) && path.length == 0 then return obj

      # Make path into array if we need to
      path = if _.isString(path) then path.split(' ') else path

      # walk the obj if properties exist else return the obj
      if obj? && _.has(obj, _.first(path)) && !_.isUndefined(obj[_.first(path)])
        return @getModelProperty _.rest(path), obj[_.first(path)]
      else
        return obj

    # **Set a variety of properties on the model based on XML policy data**
    setModelState : ->
      if @get('document')? || @get('document') != undefined
        @set('state', @getState())
        @set('quote', @isQuote())
        @set('pendingCancel', @isPendingCancel())
        @set('cancellationEffectiveDate', @getCancellationEffectiveDate())
        @set('cancelled', @isCancelled())
        @set('terms', @getTerms())
        @set('firstTerm', @getFirstTerm())
        @set('lastInterval', @getLastInterval())
        @set('insuredData', @getCustomerData('Insured'))
        @set('mortgageeData', @getCustomerData('Mortgagee'))
        @set('additionalInterestData', @getCustomerData('AdditionalInterest'))
        @set('productName', @getProductName())
        @set('insight_id', @getIdentifier('InsightPolicyId'))
        @set('isIssued', @isIssued())
        @set('effectiveDate', @getEffectiveDate())
        @set('expirationDate', @getExpirationDate())
        @set('version', @getPolicyVersion())

  PolicyModel
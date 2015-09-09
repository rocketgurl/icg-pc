define [
  'modules/IPM/IPMActionView',
  'modules/IPM/actions/Endorse'
], (IPMActionView, Endorse) ->

  # **NOTE** - we are loading in the EndorseAction because we need to use
  # Endorse.parseIntervals
  #
  class CancelInsuredAction extends IPMActionView

    initialize : ->
      super

      # We need Endorse to parseIntervals
      @Endorse = new Endorse({
        PARENT_VIEW : @PARENT_VIEW
        MODULE      : @MODULE
        })

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'cancel-insured', @processView)

    # **Build view data objects and trigger loaded event**
    #
    # Takes the model.json and creates a custom data object for this view. We
    # then trigger the `loaded` event passing @postProcessView as the callback.
    # This will attach any necessary behaviors to the rendered form.
    #
    # @param `vocabTerms` _Object_ model.json
    # @param `view` _String_ HTML template
    #
    processView : (vocabTerms, view) =>
      [viewData, view] = @processViewData(vocabTerms, view)
      @processCancellationData(viewData)
      @FormValidation.validators =
        'effectiveDate' : 'dateRange'
      @trigger "loaded", this, @postProcessView

    # Assemble additional fields needed for the cancellation views
    #
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated @viewData
    #
    processCancellationData : (viewData) ->
      policy = @MODULE.POLICY
      cancelData =
        reasonCode           : 1 # Insured Cancel defaults to "Insured request"
        policyEffectiveDate  : policy.getEffectiveDate()
        policyExpirationDate : policy.getExpirationDate()
        policyInceptionDate  : policy.getInceptionDate()
      @viewData = _.extend(viewData, cancelData)

    # **Process Preview**
    #
    # Same as processView() but we add an interval obj to viewData to tell the
    # Mustache template to render a different part for the user. This is
    # a separate function so that it would be explicit what is being called
    # in the callbackPreview()
    #
    processPreview : (vocabTerms, view) =>
      @processViewData(vocabTerms, view, true)
      @viewDataPrevious = _.deepClone @viewData
      @viewData.currentPolicy = @currentPolicyIntervals
      @viewData.preview       = _.extend({},
        @Endorse.parseIntervals(@values),
        @extractCancelEventValues()
        )
      @trigger "loaded", this, @postProcessPreview

    # On success we need to get out of the sub-view.
    callbackSuccess : (data, status, jqXHR) =>
      @PARENT_VIEW.success_msg = """
      Cancellation of Policy #{@MODULE.POLICY.getPolicyId()}
      """

      # Extend callback in  IPMActionView
      super data, status, jqXHR

    # Special trickery to pass requestPayload to error callback
    callbackInstanceError : (requestPayload) =>
      staticCallback = @callbackError requestPayload
      (jqXHR, status, error) =>
        if _.has this, 'viewDataPrevious'
          @viewData = _.deepClone @viewDataPrevious
        @PARENT_VIEW.route 'Home'
        staticCallback jqXHR, status, error

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      unless @values.formValues.comment
        @values.formValues.comment = '__deleteEmptyProperty'
      @values.formValues.transactionType = 'Cancellation'

      # Derive intervals from the form values and policy, we use this in
      # the Preview, comparing it against what comes back from the server
      @currentPolicyIntervals = @Endorse.parseIntervals @values

      # Format the date to match the TR 1.4 spec
      if _.has(@values.formValues, 'effectiveDate')
        @values.formValues.effectiveDate = \
          @Helpers.stripTimeFromDate(@values.formValues.effectiveDate)

      # Success callback
      callbackFunc = @callbackSuccess

      # Options for TransactionRequest
      options = {}

      # Previews require a different callback and an extra header.
      # The header prevents the changes from committing to the DB.
      # If preview is set to 'confirm', then ignore & commit to the DB.
      if _.has(@values.formValues, 'preview')
        if @values.formValues.preview != 'confirm'
          callbackFunc = @callbackPreview
          options.headers =
            'X-Commit' : false

      requestPayload = @ChangeSet.getTransactionRequest(@values, @viewData)

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          requestPayload
          callbackFunc
          @callbackInstanceError(requestPayload)
          options
        )

    # Parse most recent Cancel Event from Policy and use it to build
    # values for the Cancellation preview
    #
    extractCancelEventValues : ->
      monetaryItems =
        'ChangeInPremium' : true
        'ChangeInTax'     : true
        'CancelAmount'    : true
        'ChangeInFee'     : true
        'ChangeInOthers'  : true

      # Find the most recent Cancel/Cancellation Event
      # Most recent is last in the XML, so we flip the array with reverse()
      events = @MODULE.POLICY.get('json').EventHistory.Event.reverse()
      cancelEvent = _.find(events, (event) -> event.type is 'Cancel')
      if cancelEvent
        cancelData = {Action : 'Cancellation'}
        _.each(cancelEvent.DataItem, (item) =>
          isMonetary = monetaryItems[item.name]
          if isMonetary
            cancelData[_.classify(item.name)] = \
              "$#{@Helpers.formatMoney(item.value)}"
          else
            cancelData[_.classify(item.name)] = item.value
          )
        cancelData.AdvanceNoticeDays = @calculateAdvanceNoticeDays cancelData
        if cancelData.ReasonCode is "15"
          cancelData.RateType = "Short-Rate"
        else
          cancelData.RateType = "Pro Rata"
      cancelData

    calculateAdvanceNoticeDays : (data) ->
      MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24;
      {EffectiveDate, AppliedDate} = data
      advanceNoticeDays = Date.parse(EffectiveDate) - Date.parse(AppliedDate)
      if advanceNoticeDays > 0
        advanceNoticeDays / MILLISECONDS_PER_DAY
      else
        0

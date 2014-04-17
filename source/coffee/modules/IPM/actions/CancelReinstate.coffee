define [
  'modules/IPM/IPMActionView',
  'modules/IPM/actions/Endorse'
], (IPMActionView, Endorse) ->

  # **NOTE** - we are loading in the EndorseAction because we need to use
  # Endorse.parseIntervals
  #
  class CancelReinstateAction extends IPMActionView

    initialize : ->
      super

      # We need Endorse to parseIntervals
      @Endorse = new Endorse({
        PARENT_VIEW : @PARENT_VIEW
        MODULE      : @MODULE
        })

      @events =
        "click input[name=cancel]" : "loadSubAction"
        "click input[name=cancel_pending]" : "loadSubAction"
        "click input[name=reinstate]" : "loadSubAction"
        "click input[name=rescind]" : "loadSubAction"

      # Metadata about Cancellation types, used in views
      @TRANSACTION_TYPES =
        'cancel' :
          label  : 'Cancellation'
          title  : 'The policy has been cancelled'
          submit : 'Cancel this policy immediately'
          validators :
            'effectiveDate' : 'dateRange'
        'cancel_pending' :
          label  : 'PendingCancellation'
          title  : 'The policy has been set to pending cancel'
          submit : 'Set to pending cancel'
          validators :
            'effectiveDate' : 'dateRange'
        'reinstate' :
          label  : 'Reinstatement'
          title  : 'The policy has been reinstated'
          submit : 'Reinstate this policy'
        'rescind' :
          label  : 'PendingCancellationRescission'
          title  : 'The policy pending cancellation has been rescinded'
          submit : 'Rescind pending cancellation'

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'cancellation', @processView)

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
      @CURRENT_SUBVIEW = false
      [viewData, view] = @processViewData(vocabTerms, view)

      @processCancellationData(viewData)
      @trigger "loaded", this, @postProcessView

    # **Build sub view template using existing data objects**
    #
    # We need to rebuild the @viewData object (processCancellationData) for
    # subviews, otherwise we will lose some data and get very subtle bugs
    # (missing dateRange, etc.)
    #
    # @param `vocabTerms` _Object_ model.json
    # @param `view` _String_ HTML template
    #
    processSubView : (vocabTerms, view) =>
      # **ALERT** - we must not cache subviews, or we will problems when we want
      # to go back to the parent view, hence third param of **true** in
      # @processViewData
      [viewData, view] = @processViewData(vocabTerms, view, true)
      @processCancellationData(viewData)

      # Load form validation rules into FormValidation
      if _.has(@TRANSACTION_TYPES[@CURRENT_SUBVIEW], 'validators')
        @FormValidation.validators = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].validators

      @trigger "loaded", this, @postProcessSubView

    # Apply standard DOM behaviors to sub views after rendered then override
    # the cancel/nevermind button to get back to CancelReinstate screen
    postProcessSubView : ->
      @postProcessView()
      nevermindButton = @$el.find('.form_actions a')
      nevermindButton.off 'click' # need to reset click to prevent stepping on @goHome()
      nevermindButton.one 'click', (e) =>
        e.preventDefault()
        policy = @rollbackPolicyModel()
        @fetchTemplates(policy, 'cancellation', @processView)

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

      @viewData.preview        = @Endorse.parseIntervals(@values)
      @viewData.current_policy = @current_policy_intervals

      preview_values = @extractEventValues(@MODULE.POLICY, @viewData)
      preview_labels = @determinePreviewLabel(@values.formValues, @viewData)
      preview_effective_date = @determineCorrectPreviewDate(@MODULE.POLICY, @viewData)

      @viewData = _.extend(
        @viewData, preview_values, preview_labels, preview_effective_date
      )

      # Calculate AdvanceNoticeDays
      @viewData = _.extend(@viewData, @calculateAdvanceNoticeDays(@viewData))

      # Get submitLabel
      @viewData.preview.submitLabel = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].submit ? ''

      # What's the RateType?
      @viewData.preview.RateType = if @viewData.preview.ReasonCode == "15" then \
        "Short-Rate" else "Pro Rata"

      @trigger("loaded", this, @postProcessSubView)

    # Assemble additional fields needed for the cancellation views
    #
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated @viewData
    #
    processCancellationData : (viewData) ->
      policy = @MODULE.POLICY

      cancel_data =
        policyState                  : policy.getState()
        policyStateVal               : null
        pendingCancel                : policy.isPendingCancel()
        pendingCancelReasonCode      : null
        pendingCancelReasonCodeLabel : null
        policyEffectiveDate          : policy.getEffectiveDate()
        policyExpirationDate         : policy.getExpirationDate()
        cancellationEffectiveDate    : null


      # getState() may return an object
      if _.isObject cancel_data.policyState
        cancel_data.policyStateVal = cancel_data.policyState.text
      else
        cancel_data.policyStateVal = cancel_data.policyState

      # Pending Cancellation policies require additional field processing
      if cancel_data.pendingCancel && _.isObject(cancel_data.pendingCancel)
        cancel_data = @processPendingCancellation(cancel_data, viewData)

      # Process more data based on policyState
      cancel_data = switch cancel_data.policyStateVal
        when 'ACTIVEPOLICY'
          @processActivePolicy(cancel_data)
        when 'CANCELLEDPOLICY'
          @processCancelledPolicy(cancel_data, viewData)
        else cancel_data

      @viewData = _.extend(viewData, cancel_data)

    # Pending Cancellations need some extra data extrapolated from the
    # viewData object
    #
    # @param `cancel_data` _Object_ values for cancellation
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated cancel_data
    #
    processPendingCancellation : (cancel_data, viewData) ->
      reasonLabel = _.where(viewData.EnumsReasonCodesAndLabels, { value : cancel_data.pendingCancel.reasonCode })
      if _.isArray(reasonLabel) && reasonLabel.length > 0
        reasonLabel = reasonLabel[0]['label']

      cancel_data.pendingCancelReasonCode = \
        cancel_data.pendingCancel.reasonCode

      cancel_data.pendingCancelReasonCodeLabel = reasonLabel

      cancel_data.cancellationEffectiveDate    = \
        @Helpers.stripTimeFromDate(cancel_data.pendingCancel.cancellationEffectiveDate)

      # I find this to be dubious, erasing the object with a boolean - DN
      cancel_data.pendingCancel = true

      cancel_data

    # Assemble message fields and other values for Active Policies
    #
    # @param `cancel_data` _Object_ values for cancellation
    # @return _Object_ updated cancel_data
    #
    processActivePolicy : (cancel_data) ->
      if cancel_data.pendingCancel
        active_data =
          cancelDisabled    : ''
          reinstateDisabled : 'disabled'
          pendingDisabled   : 'disabled'
          rescindDisabled   : ''
          msg               : true
          msgType           : 'notice'
          msgHeading        : 'This is an active policy that is pending cancellation.'
          msgText           : """
            Cancellation is effective <b>#{cancel_data.cancellationEffectiveDate}</b> due to <b>#{cancel_data.pendingCancelReasonCodeLabel}</b>
          """
      else
        active_data =
          cancelDisabled            : ''
          pendingDisabled           : ''
          reinstateDisabled         : 'disabled'
          rescindDisabled           : 'disabled'
          pendingCancelReasonCode   : null
          cancellationEffectiveDate : null
          msg                       : false
          msgType                   : null
          msgHeading                : null
          msgText                   : null

      if @CURRENT_SUBVIEW != false
        active_data.msg = false

      _.extend(cancel_data, active_data)

    # Assemble message fields and other values for Cancelled Policies
    #
    # @param `cancel_data` _Object_ values for cancellation
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated cancel_data
    #
    processCancelledPolicy : (cancel_data, viewData) ->
      reasonLabel = _.where(viewData.EnumsReasonCodesAndLabels, { value : cancel_data.policyState.reasonCode })

      if _.isArray(reasonLabel) && reasonLabel.length > 0
        reasonLabel = reasonLabel[0]['label']

      effectiveDate = 'not available'
      if _.has(cancel_data.policyState, 'effectiveDate')
        effectiveDate = @Helpers.stripTimeFromDate(cancel_data.policyState.effectiveDate)

      active_data =
        cancelDisabled    : 'disabled'
        pendingDisabled   : 'disabled'
        rescindDisabled   : 'disabled'
        reinstateDisabled : ''
        msg               : true
        msgType           : 'notice'
        msgHeading        : 'This is a cancelled policy'
        msgText           : """
            Cancellation took effect <b>#{effectiveDate}</b> due to <b>#{reasonLabel}</b>
          """

      if @CURRENT_SUBVIEW != false
        active_data.msg = false

      _.extend(cancel_data, active_data)

    # Load a sub-view into the current space
    # These are triggered by button clicks
    #
    loadSubAction : (e) ->
      e.preventDefault()
      if e.currentTarget.className != 'disabled'
        action = $(e.currentTarget).attr('name') ? false
        if action?
          @CURRENT_SUBVIEW = action
          @fetchTemplates(@MODULE.POLICY, action, @processSubView, true)
        else
          msg = "Could not load that action. Contact support."
          @PARENT_VIEW.displayMessage('error', msg, 12000)

    # On success we need to get out of the sub-view.
    callbackSuccess : (data, status, jqXHR) =>
      @PARENT_VIEW.success_msg = """
      #{_.classify(@CURRENT_SUBVIEW)} of Policy #{@MODULE.POLICY.getPolicyId()}
      """

      # Extend callback in  IPMActionView
      super data, status, jqXHR

    # On error we need to get out of the sub-view.
    callbackError : (jqXHR, status, error) =>

      if _.has this, 'viewDataPrevious'
        @viewData = _.deepClone @viewDataPrevious

      @PARENT_VIEW.route 'Home'

      super jqXHR, status, error

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      # We selectively delete certain empty values later
      if @values.formValues.comment == ''
        @values.formValues.comment = '__deleteEmptyProperty'

      transaction_types =
        'cancel'         : 'Cancellation'
        'cancel_pending' : 'PendingCancellation'
        'reinstate'      : 'Reinstatement'
        'rescind'        : 'PendingCancellationRescission'

      @values.formValues.transactionType = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].label ? false

      if !@values.formValues.transactionType
        msg = "There was an error determining which Transaction Type this request is."
        @PARENT_VIEW.displayMessage('error', msg, 12000)
        return false

      # Derive intervals from the form values and policy, we use
      # this in the Preview, comparing it against what comes back
      # from the server
      @current_policy_intervals = @Endorse.parseIntervals(@values)

      # Format the date to match the TR 1.4 spec
      if _.has(@values.formValues, 'effectiveDate')
        @values.formValues.effectiveDate = @Helpers.stripTimeFromDate(@values.formValues.effectiveDate)

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

      # Assemble the TransactionRequest XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getTransactionRequest(@values, @viewData),
          callbackFunc,
          @callbackError,
          options
        )

    # Parse most recent Event object from Policy and use it to build
    # values for the Cancellation preview
    #
    # @param `policy` _Object_ Policy
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    extractEventValues : (policy, viewData) ->
      # Find the most recent Cancellation/PendingCancellation in the Policy.
      # Most recent is last in the XML, so we flip the array with reverse()
      events = policy.get('json').EventHistory.Event.reverse()
      cancellation = _.find(events, (event) ->
          event.type == 'Cancel' || event.type == 'PendingCancellation'
        )

      viewData.preview.Action = \
        if cancellation.type == "Cancel"
          "Cancellation"
        else
          "Pending Cancellation"

      data_whitelist = [
        'AppliedDate',
        'reasonCode',
        'reasonCodeLabel',
        'EffectiveDate',
        'ChangeInPremium',
        'ChangeInTax',
        'CancelAmount',
        'ChangeInFee'
      ]

      data_money = [
        'ChangeInPremium',
        'ChangeInTax',
        'CancelAmount',
        'ChangeInFee'
      ]

      # Loop through whitelisted data items and drop properly formatted
      # values into the preview object
      for data in cancellation.DataItem
        if _.contains(data_whitelist, data.name)
          if _.contains(data_money, data.name)
            viewData.preview[_.classify(data.name)] = \
              "$#{@Helpers.formatMoney(data.value)}"
          else
            viewData.preview[_.classify(data.name)] = data.value

      viewData

    # Parse most recent Event object from Policy and use it to build
    # values for the Cancellation preview
    #
    # @param `formValues` _Object_ @values.formValues
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    determinePreviewLabel : (formValues, viewData) ->
      # Labels for buttons
      preview_labels =
        "PendingCancellationRescission" : "rescission of pending cancellation"
        "Reinstatement"                 : "reinstatement"
        "PendingCancellation"           : "pending cancellation"
        "Cancellation"                  : "cancellation"

      viewData.preview.PreviewLabel = preview_labels[formValues.transactionType]

      if formValues.transactionType == "PendingCancellation" || formValues.transactionType == "Resinstatement"
        viewData.preview.Undo = true

      viewData

    # ICS-1000 : For Pending Cancellations we want to show CancellationEffectiveDate
    # from the preview XML doc. For immediate cancellations we want to show
    # EffectiveDate from the preview XML doc. This is partially to
    # future proof things so that if the server does calculations on the
    # preview XML doc in the future we will show them to the user here
    # instead of their raw input.
    #
    # @param `policy` _Object_ Policy
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    determineCorrectPreviewDate : (policy, viewData) ->
      management = policy.get('json').Management

      if @values.formValues.transactionType == "PendingCancellation"
        viewData.preview.EffectiveDate = \
          management.PendingCancellation.cancellationEffectiveDate
      else if _.has(management, 'policyState') && _.has(management.policyState, 'effectiveDate')
        viewData.preview.EffectiveDate = management.policyState.effectiveDate

      viewData

    # Date math to get AdvanceNotceDays
    #
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    calculateAdvanceNoticeDays : (viewData) ->
      MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24;

      viewData.preview.AdvanceNoticeDays = \
        (Date.parse(viewData.preview.EffectiveDate) - Date.parse(viewData.preview.AppliedDate)) / MILLISECONDS_PER_DAY;

      if viewData.preview.AdvanceNoticeDays < 0
        viewData.preview.AdvanceNoticeDays = 0

      viewData

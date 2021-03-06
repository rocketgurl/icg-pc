define [
  'modules/IPM/IPMActionView',
  'modules/IPM/actions/Endorse',
  'mustache'
], (IPMActionView, Endorse, Mustache) ->

  # **NOTE** - we are loading in the EndorseAction because we need to use
  # Endorse.parseIntervals
  #
  class NonRenewalAction extends IPMActionView

    events :
      'click .load-subaction' : 'loadSubAction'

    # Metadata about NonRenewal types, used in views
    TRANSACTION_TYPES :
      'nonrenew' :
        label  : 'NonRenewal'
        title  : 'The policy has been set for immediate non-renewal'
        submit : 'Non-renew this policy immediately'
      'nonrenewpending' :
        label  : 'PendingNonRenewal'
        title  : 'The policy has been set to pending non-renewal'
        submit : 'Set to pending non-renewal'
      'nonrenewreinstate' :
        label  : 'NonRenewedReinstatement'
        title  : 'The policy has been reinstated'
        submit : 'Reinstate this policy'
      'nonrenewrescind' :
        label  : 'PendingNonRenewalRescission'
        title  : 'The policy pending non-renewal has been rescinded'
        submit : 'Rescind pending non-renewal'

    REASON_CODES :
      1   : "Insured Request"
      6   : "Physical Changes In The Property Insured"
      7   : "Increase In Liability Hazards Beyond What Is Normally Accepted"
      8   : "Increase In Property Hazards Beyond What Is Normally Accepted"
      9   : "Overexposed In Area Where Risk Is Located"
      10  : "Change In Occupancy Status"
      11  : "Other Underwriting Reasons"
      13  : "Change In Ownership"
      14  : "Missing Required Documentation"
      205 : "Loss History – Resolved"
      206 : "Negative feedback from claims adjustor – Resolved"
      207 : "Hazards found on a roof inspection - Resolved"

    PREVIEW_LABELS :
      'NonRenewal'                  : 'The policy has been set for immediate non-renewal'
      'PendingNonRenewal'           : 'The policy has been set to pending non-renewal'
      'PendingNonRenewalRescission' : 'The policy pending non-renewal has been rescinded'
      'NonRenewedReinstatement'     : 'The non-renewed policy has been reinstated'

    PREVIEW_ACTIONS :
      'NonRenewal'                  : 'Non-Renewal'
      'PendingNonRenewal'           : 'Pending Non-Renewal'
      'PendingNonRenewalRescission' : 'Rescind Pending Non-Renewal'
      'NonRenewedReinstatement'     : 'Non-Renewed Reinstatement'

    initialize : ->
      super

      # We need Endorse to parseIntervals
      @Endorse = new Endorse({
        PARENT_VIEW : @PARENT_VIEW
        MODULE      : @MODULE
        })

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'nonrenewal', @processView)

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

      @processNonRenewalData(viewData)
      @trigger "loaded", this, @postProcessView

    # **Build sub view template using existing data objects**
    #
    # We need to rebuild the @viewData object (processNonRenewalData) for
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
      @processNonRenewalData(viewData)

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
        @fetchTemplates(policy, 'nonrenewal', @processView)

    # **Process Preview**
    #
    # Same as processView() but we add an interval obj to viewData to tell the
    # Mustache template to render a different part for the user. This is
    # a separate function so that it would be explicit what is being called
    # in the callbackPreview()
    #
    processPreview : (vocabTerms, view) =>
      @processViewData vocabTerms, view, true
      @viewDataPrevious = _.deepClone @viewData

      transactionType = @values.formValues.transactionType
      reasonCode      = @values.formValues.reasonCode
      reasonCodeLabel = @REASON_CODES[reasonCode]

      @viewData.preview              = @Endorse.parseIntervals @values
      @viewData.preview.PreviewLabel = @Helpers.prettyMap @PREVIEW_LABELS[transactionType]
      @viewData.preview.Action       = @Helpers.prettyMap @PREVIEW_ACTIONS[transactionType]
      @viewData.preview.submitLabel  = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].submit ? 'Submit'

      if reasonCodeLabel
        @viewData.preview.ReasonCode = "#{reasonCode} - #{reasonCodeLabel}"
      else
        @viewData.preview.ReasonCode = reasonCode

      @trigger 'loaded', this, @postProcessSubView

    # Inspect the Policy to determine which buttons on the view to
    # enable/disable and which labels to display
    #
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated @viewData
    #
    processNonRenewalData : (viewData) ->
      policy = @MODULE.POLICY
      pendingNonRenewal = policy.get('json').Management?.PendingNonRenewal

      nonRenewData =
        policyState                      : policy.getState()
        policyStateVal                   : null
        pendingNonRenewal                : pendingNonRenewal
        pendingNonRenewalReasonCode      : null
        pendingNonRenewalReasonCodeLabel : null
        policyEffectiveDate              : policy.getEffectiveDate()
        policyExpirationDate             : policy.getExpirationDate()
        policyInceptionDate              : policy.getInceptionDate()
        nonRenewalEffectiveDate          : null
        nonrenewDisabled                 : 'disabled'
        setPendingDisabled               : ''
        reinstateDisabled                : 'disabled'
        rescindPendingDisabled           : 'disabled'

      # getState() may return an object
      if _.isObject nonRenewData.policyState
        nonRenewData.policyStateVal = nonRenewData.policyState.text
      else
        nonRenewData.policyStateVal = nonRenewData.policyState

      # Pending NonRenewal policies require additional field processing
      if _.isObject pendingNonRenewal
        nonRenewData = @processPendingNonRenewal nonRenewData

      # Process more data based on policyState
      nonRenewData = switch nonRenewData.policyStateVal
        when 'ACTIVEPOLICY'
          @processActivePolicy nonRenewData
        when 'NONRENEWEDPOLICY'
          @processNonRenewedPolicy nonRenewData
        else nonRenewData

      @viewData = _.extend viewData, nonRenewData

    processPendingNonRenewal : (nonRenewData) ->
      reasonLabel = '[reason not available]'
      if reasonCode = nonRenewData.pendingNonRenewal.reasonCode
        if label = @REASON_CODES[reasonCode]
          nonRenewData.pendingNonRenewalReasonCodeLabel = label
          nonRenewData.pendingNonRenewalReasonCode = reasonCode

      nonRenewData.nonRenewalEffectiveDate = \
        nonRenewData.policyExpirationDate

      nonRenewData

    processActivePolicy : (nonRenewData) ->
      if _.isObject nonRenewData.pendingNonRenewal
        data =
          nonrenewDisabled       : ''
          reinstateDisabled      : 'disabled'
          setPendingDisabled     : 'disabled'
          rescindPendingDisabled : ''
          msg                    : not @CURRENT_SUBVIEW
          msgType                : 'notice'
          msgHeading             : 'This is an active policy that is pending non-renewal.'
          msgText                : """
            Non-renewal is effective <strong>#{nonRenewData.nonRenewalEffectiveDate}</strong> due to <strong>#{nonRenewData.pendingNonRenewalReasonCodeLabel}</strong>
          """
      else
        data =
          nonrenewDisabled       : 'disabled'
          setPendingDisabled     : ''
          reinstateDisabled      : 'disabled'
          rescindPendingDisabled : 'disabled'
          msg                    : false
          msgType                : null
          msgHeading             : null
          msgText                : null

      _.extend nonRenewData, data

    processNonRenewedPolicy : (nonRenewData) ->
      reasonLabel = '[reason not available]'
      if reasonCode = nonRenewData.policyState.reasonCode
        if label = @REASON_CODES[reasonCode]
          reasonLabel = label

      effectiveDate = '[date not available]'
      if nonRenewData.policyState.effectiveDate
        effectiveDate = nonRenewData.policyState.effectiveDate

      data =
        nonrenewDisabled       : 'disabled'
        setPendingDisabled     : 'disabled'
        rescindPendingDisabled : 'disabled'
        reinstateDisabled      : ''
        msg                    : not @CURRENT_SUBVIEW
        msgType                : 'notice'
        msgHeading             : 'This is a non-renewed policy'
        msgText                : """
            Non-renewal took effect <b>#{effectiveDate}</b> due to <b>#{reasonLabel}</b>
          """

      _.extend nonRenewData, data

    # Load a sub-view into the current space
    # These are triggered by button clicks
    #
    loadSubAction : (e) ->
      e.preventDefault()
      if e.currentTarget.className != 'disabled'
        action = $(e.currentTarget).attr('name') ? false
        if action?
          @CURRENT_SUBVIEW = action
          @fetchTemplates(@MODULE.POLICY, "nonrenewal-#{action}", @processSubView, true)
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

      # We selectively delete certain empty values later
      unless @values.formValues.comment
        @values.formValues.comment = '__deleteEmptyProperty'

      @values.formValues.effectiveDate = @MODULE.POLICY.get('expirationDate')
      @values.formValues.transactionType = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].label ? false

      unless @values.formValues.transactionType
        msg = "There was an error determining which Transaction Type this request is."
        @PARENT_VIEW.displayMessage('error', msg, 12000)
        return false

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

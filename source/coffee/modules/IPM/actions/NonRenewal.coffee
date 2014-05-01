define [
  'modules/IPM/IPMActionView',
  'modules/IPM/actions/Endorse',
  'mustache'
], (IPMActionView, Endorse, Mustache) ->

  # **NOTE** - we are loading in the EndorseAction because we need to use
  # Endorse.parseIntervals
  #
  class NonRenewalAction extends IPMActionView

    initialize : ->
      super

      # We need Endorse to parseIntervals
      @Endorse = new Endorse({
        PARENT_VIEW : @PARENT_VIEW
        MODULE      : @MODULE
        })

      @events =
        "click input[name=nonrenew]" : "loadSubAction"
        "click input[name=nonrenewpending]" : "loadSubAction"
        "click input[name=nonrenewrescind]" : "loadSubAction"

      # Metadata about Cancellation types, used in views
      @TRANSACTION_TYPES =
        'nonrenew' :
          label  : 'NonRenewal'
          title  : 'The police has been set for immediate non-renewal'
          submit : 'Non-renew this policy immediately'
        'nonrenewpending' :
          label  : 'PendingNonRenewal'
          title  : 'The policy has been set to pending non-renewal'
          submit : 'Set to pending non-renewal'
        'nonrenewrescind' :
          label  : 'PendingNonRenewalRescission'
          title  : 'The policy pending non-renewal has been rescinded'
          submit : 'Rescind pending non-renewal'

      @REASON_CODES = [
        label: "Insured Request"
        value: "1"
      ,
        label: "Physical Changes In The Property Insured"
        value: "6"
      ,
        label: "Increase In Liability Hazards Beyond What Is Normally Accepted"
        value: "7"
      ,
        label: "Increase In Property Hazards Beyond What Is Normally Accepted"
        value: "8"
      ,
        label: "Overexposed In Area Where Risk Is Located"
        value: "9"
      ,
        label: "Change In Occupancy Status"
        value: "10"
      ,
        label: "Other Underwriting Reasons"
        value: "11"
      ,
        label: "Change In Ownership"
        value: "13"
      ,
        label: "Missing Required Documentation"
        value: "14"
      ]

      @XML_TEMPLATE = """
        <TransactionRequest schemaVersion="1.7" type="{{transactionType}}">
          <Initiation>
            <Initiator type="user">{{user}}</Initiator>
          </Initiation>
          <Target>
            <Identifiers>
              <Identifier name="InsightPolicyId" value="{{id}}"/>
            </Identifiers>
            <SourceVersion>{{version}}</SourceVersion>
          </Target>
          {{#reasonCode}}
          <ReasonCode>{{reasonCode}}</ReasonCode>
          {{/reasonCode}}
        </TransactionRequest>
      """

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
      @processViewData(vocabTerms, view, true)

      @viewDataPrevious = _.deepClone @viewData
      @viewData.preview = @Endorse.parseIntervals(@values)

      preview_values = @extractEventValues(@MODULE.POLICY, @viewData)
      preview_labels = @determinePreviewLabel(@values.formValues, @viewData)
      @viewData = _.extend(@viewData, preview_values, preview_labels)

      reasonCode = @values.formValues.reasonCode
      reason = _.first(_.filter(@REASON_CODES, (item) -> item.value == reasonCode))
      
      if !_.isUndefined(reason) && _.has reason, 'label'
        @viewData.preview.ReasonCode = reasonCode + " - " + reason.label
      else
        @viewData.preview.ReasonCode = reasonCode

      # Get submitLabel
      @viewData.preview.submitLabel = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].submit ? ''

      @trigger("loaded", this, @postProcessSubView)

    # Inspect the Policy to determine which buttons on the view to
    # enable/disable and which labels to display
    #
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated @viewData
    #
    processNonRenewalData : (viewData) ->
      policy = @MODULE.POLICY
      reasonCode = policy.find('Management PendingNonRenewal reasonCode')
      nonrenew_data = { EnumsNonRenewReason: @REASON_CODES }

      # Management > PendingNonRenewal isn't set yet without a policy refresh,
      # so this is our attempt to show the correct state
      unless reasonCode?
        events = policy.find('EventHistory Event')

        # policy.find returns an Array of Events if there are multiple Event
        # objects but only the one Event object if there is only one
        lastEvent = if _.isArray(events) then _.last(events) else events
        if lastEvent?.type is 'PendingNonRenewal'
          getReasonCode = (item) -> item.name is 'reasonCode'
          reasonCode = _.find(lastEvent.DataItem, getReasonCode).value

      # Toggle buttons on/off depending on
      # reason code's existence
      if reasonCode?
        nonrenew_data.reasonCode = reasonCode
        nonrenew_data.setPendingDisabled = 'disabled'
      else
        nonrenew_data.nonrenewDisabled = 'disabled'
        nonrenew_data.rescindPendingDisabled = 'disabled'

      @viewData = _.extend(viewData, nonrenew_data)

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
      unless @values.formValues.comment
        @values.formValues.comment = '__deleteEmptyProperty'

      @values.formValues.effectiveDate = @MODULE.POLICY.get('expirationDate')
      @values.formValues.transactionType = @TRANSACTION_TYPES[@CURRENT_SUBVIEW].label ? false

      if !@values.formValues.transactionType
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

      # Assemble the TransactionRequest XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getTransactionRequest(@values, @viewData),
          callbackFunc,
          @callbackError,
          options
        )

    # Parse most recent Event object from Policy and use it to build
    # values for the NonRenewal preview
    #
    # @param `policy` _Object_ Policy
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    extractEventValues : (policy, viewData) ->
      # Find the most recent Cancellation/PendingCancellation in the Policy.
      # Most recent is last in the XML, so we flip the array with reverse()
      events = policy.get('json').EventHistory.Event.reverse()
      actionsMap =
        'RescindPendingNonRenewal': 'Rescind Pending Non-Renewal'
        'PendingNonRenewal': 'Pending Non-Renewal'
        'NonRenewal': 'Non-Renewal'

      nonrenewal = _.find(events, (event) ->
          _.indexOf(_.keys(actionsMap), event.type) >= 0
        )

      viewData.preview.Action = actionsMap[nonrenewal.type]
      viewData

    # Determine the preview label
    #
    # @param `formValues` _Object_ @values.formValues
    # @param `viewData` _object_ model.json values
    # @return _Object_ updated viewData
    #
    determinePreviewLabel : (formValues, viewData) ->
      # Labels for buttons
      preview_labels =
        'NonRenewal'                 : 'The policy has been set for immediate non-renewal'
        'PendingNonRenewal'          : 'The policy has been set to pending non-renewal'
        'PendingNonRenewalRescission' : 'The policy pending non-renewal has been rescinded'

      viewData.preview.PreviewLabel = preview_labels[formValues.transactionType]

      viewData

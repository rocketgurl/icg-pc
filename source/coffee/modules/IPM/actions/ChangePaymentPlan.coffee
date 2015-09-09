define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class ChangePaymentPlanAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'change-payment-plan', @processView)

    # **Build a viewData object to populate the template form with**
    #
    # Takes the model.json and creates a custom data object for this view. We
    # then set that object to @viewData and the view to @view.
    #
    # @param `vocabTerms` _Object_ model.json
    # @param `view` _String_ HTML template
    # @return _Array_ [viewData object, view object]
    #
    processViewData : (vocabTerms, view) =>
      super vocabTerms, view

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
      @processViewData(vocabTerms, view)
      @trigger "loaded", this, @postProcessView

    postProcessView : ->
      super

      @$el.find(@makeId('paymentPlanType')).val(@MODULE.POLICY.find('Accounting PaymentPlan type'))

    # When payor == 100, payor = mortgagee, else payor = primary insured
    getPayorValues : (payor) ->
      policy = @MODULE.POLICY

      if payor is 100
        policy.getDataItemValues(policy.get('mortgageeData'), [
          'MortgageeNumber1'
          'Mortgagee1AddressLine1'
          'Mortgagee1AddressLine2'
          'Mortgagee1AddressCity'
          'Mortgagee1AddressState'
          'Mortgagee1AddressZip'
        ])
      else
        policy.getDataItemValues(policy.get('insuredData'), [
          'InsuredFirstName'
          'InsuredLastName'
          'InsuredMailingAddressLine1'
          'InsuredMailingAddressLine2'
          'InsuredMailingAddressCity'
          'InsuredMailingAddressState'
          'InsuredMailingAddressZip'
        ])

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      payorValues = {}

      values =
        startDate          : @MODULE.POLICY.get('lastInterval').StartDate ? null
        endDate            : @MODULE.POLICY.get('lastInterval').EndDate ? null
        termEffectiveDate  : @MODULE.POLICY.get('firstTerm').EffectiveDate ? null
        termExpirationDate : @MODULE.POLICY.get('firstTerm').ExpirationDate ? null
        comment            : @$el.find(@makeId('comment')).val()
        payor              : @getPayorVocab(@values.formValues.paymentPlanType)
        prevPayor          : @getPayorVocab(@MODULE.POLICY.getPaymentPlanType())

      # When the payor vocab code changes, we need to push some additional fields
      # in order to assemble a policy change set in IPMActionView
      if values.payor isnt values.prevPayor
        payorValues = @getPayorValues values.payor
        _.each _.keys(payorValues), (key) =>
          @values.changedValues.push key
        @values.changedValues.push 'payor'

      @values.formValues = _.extend(@values.formValues, values, payorValues)

      @values.formValues.transactionType = 'AccountingChanges'

      # ICS-2572: Effective Date should be explicitly set to the Policy Effective date
      # In order to allow Payment Plan Changes to be applied before Policy Inception
      @values.formValues.effectiveDate = @MODULE.POLICY.getEffectiveDate()

      requestPayload = @ChangeSet.getTransactionRequest(@values, @viewData)

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          requestPayload
          @callbackSuccess
          @callbackError(requestPayload)
        )

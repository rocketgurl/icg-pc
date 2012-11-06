define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class EndorseAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      @fetchTemplates(@MODULE.POLICY, 'endorse', @processView)

    # Build a viewData object to populate the template form with
    processView : (vocabTerms, view) =>
      super vocabTerms, view
      viewData = @MODULE.POLICY.getTermDataItemValues(vocabTerms)
      viewData = @MODULE.POLICY.getEnumerations(viewData, vocabTerms)
      viewData = _.extend(
        viewData,
        @MODULE.POLICY.getPolicyOverview(),
        { 
          policyOverview : true
          policyId : @MODULE.POLICY.get_pxServerIndex()
        }
      )
      @render viewData, view

    render : (viewData, view) ->
      super

      html = @MODULE.VIEW.Mustache.render(view, viewData)
      @trigger "loaded", html

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      # @@ Action specific processing
      @VALUES.formValues.positivePaymentAmount = \
        Math.abs(@VALUES.formValues.paymentAmount || 0)

      @VALUES.formValues.paymentAmount = \
        -1 * @VALUES.formValues.positivePaymentAmount

      # Assemble the ChangeSet XML and send to server
      @CHANGE_SET.commitChange(
          @CHANGE_SET.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )

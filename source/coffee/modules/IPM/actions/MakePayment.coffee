define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class MakePaymentAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'make-payment', @processView)

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

      @viewData = viewData
      @view     = view

      @trigger "loaded", this
      

    render : (viewData, view) ->
      super
      viewData = viewData || @viewData
      view     = view || @view
      @$el.html(@MODULE.VIEW.Mustache.render(view, viewData))

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

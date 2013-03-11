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

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      values =
        startDate          : @MODULE.POLICY.get('lastInterval').StartDate ? null
        endDate            : @MODULE.POLICY.get('lastInterval').EndDate ? null
        termEffectiveDate  : @MODULE.POLICY.get('firstTerm').EffectiveDate ? null
        termExpirationDate : @MODULE.POLICY.get('firstTerm').ExpirationDate ? null

      @VALUES.formValues = _.extend(@VALUES.formValues, values)

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )
define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class PremiumDisbursementAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'premium-disbursement', @processView)

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

      @FormValidation.validators =
        'amount' : 'money'

      @trigger "loaded", this, @postProcessView      

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @VALUES.formValues.amount = \
        @Helpers.formatMoney(@VALUES.formValues.amount) ? null

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )

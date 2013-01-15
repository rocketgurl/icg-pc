define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class GenerateDocumentAction extends IPMActionView

    initialize : ->
      super

      @events =
        "click .ipm-action-links li a" : "triggerDocumentAction"

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'generate-document', @processView)

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

      @viewData.documentGroups = vocabTerms.terms

      @trigger "loaded", this, @postProcessView   

    
    triggerDocumentAction : (e) ->
      e.preventDefault()
      if e.currentTarget.className != 'disabled'
        action = $(e.currentTarget).attr('href') ? false
        if action?
          console.log ['triggerDocumentAction', action]
        else
          msg = "Could not load that action. Contact support."
          @PARENT_VIEW.displayMessage('error', msg, 12000)   

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
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )

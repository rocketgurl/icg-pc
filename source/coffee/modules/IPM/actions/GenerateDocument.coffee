define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class GenerateDocumentAction extends IPMActionView

    initialize : ->
      super

      @CURRENT_ACTION = null

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

    # Extrapolate which action from href and submit the ChangeSet
    triggerDocumentAction : (e) ->
      e.preventDefault()
      if e.currentTarget.className != 'disabled'
        @CURRENT_ACTION = 
          type  : $(e.currentTarget).attr('href') ? false
          label : $(e.currentTarget).html() ? false
        if @CURRENT_ACTION.type?
          @submit() # Just trigger submit manually
        else
          msg = "Could not load that document action. Contact support."
          @PARENT_VIEW.displayMessage('error', msg, 12000)   

    # **Submit** - Assemble data for ChangeSet
    submit : (e) ->
      super e

      # Dates for template
      timestamp    = @Helpers.makeTimestamp()
      idStamp      = timestamp.replace(/:|\.\d{3}/g, '')
      labelStamp   = @Helpers.formatDate timestamp
      specialDocs  = ['ReissueDeclarationPackage', 'Invoice']
      templateName = "generate_document-#{@MODULE.POLICY.get('productName')}"

      @values.formValues.generating    = true
      @values.formValues.policyId      = @MODULE.POLICY.get 'insightId'
      @values.formValues.documentId    = "#{@CURRENT_ACTION.type}-#{idStamp}"
      @values.formValues.documentType  = @CURRENT_ACTION.type
      @values.formValues.documentLabel = @CURRENT_ACTION.label

      # If the documentLabel is NOT in specialDocs then append labelStamp
      if _.indexOf(specialDocs, @CURRENT_ACTION.label) != -1
        @values.formValues.documentLabel = \
          "#{@values.formValues.documentLabel} #{labelStamp}"

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@values)
          @callbackSuccess,
          @callbackError
        )

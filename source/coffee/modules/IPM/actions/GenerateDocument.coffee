define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class GenerateDocumentAction extends IPMActionView

    events :
      "change .doc-type" : "handleDoctypeSelect"

    initialize : ->
      super
      @CURRENT_ACTION = null

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

    postProcessView : ->
      super
      @$doctypeSelects = @$('.doc-type')

    handleDoctypeSelect : (e) ->
      $target = $(e.currentTarget)
      $selected = $target.find ':selected'
      @$doctypeSelects.not($target).val ''
      @CURRENT_ACTION = 
        type  : $target.val()
        label : $selected.text()

    # **Submit** - Assemble data for ChangeSet
    submit : (e) ->
      if _.isObject @CURRENT_ACTION
        super e

        # Dates for template
        timestamp    = @Helpers.makeTimestamp()
        idStamp      = timestamp.replace(/:|\.\d{3}/g, '')
        labelStamp   = @Helpers.formatDate timestamp

        @values.formValues.generating    = true
        @values.formValues.policyId      = @MODULE.POLICY.get 'insightId'
        @values.formValues.documentId    = "#{@CURRENT_ACTION.type}-#{idStamp}"
        @values.formValues.documentType  = @CURRENT_ACTION.type
        @values.formValues.documentLabel = @CURRENT_ACTION.label

        # If the documentLabel is NOT in specialDocs then append labelStamp
        unless _.indexOf(['ReissueDeclarationPackage', 'Invoice'], @CURRENT_ACTION.type) is -1
          @values.formValues.documentLabel = \
            "#{@values.formValues.documentLabel} #{labelStamp}"

        requestPayload = @ChangeSet.getPolicyChangeSet(@values)

        # # Assemble the ChangeSet XML and send to server
        @ChangeSet.commitChange(
            requestPayload
            @callbackSuccess
            @callbackError(requestPayload)
          )

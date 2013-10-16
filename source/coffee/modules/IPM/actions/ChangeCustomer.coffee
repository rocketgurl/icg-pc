define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class ChangeCustomerAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'change-customer', @processView)

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
      console.log vocabTerms

      @processViewData(vocabTerms, view)
      @trigger "loaded", this, @postProcessView


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

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @values.formValues.id              = @MODULE.POLICY.getPolicyId()
      @values.formValues.amount          = Math.abs(@values.formValues.amount || 0)
      @values.formValues.reasonCodeLabel = \
        $("#{@makeId('reasonCode')} option[value=#{@values.formValues.reasonCode}]").html()
      @values.formValues.lineItemType    = \
        @values.formValues.reasonCodeLabel.toUpperCase().replace(/\s/g, '_')
      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@values)
          @callbackSuccess,
          @callbackError
        )

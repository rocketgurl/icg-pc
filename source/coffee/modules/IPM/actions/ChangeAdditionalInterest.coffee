define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class ChangeAdditionalInterestAction extends IPMActionView

    initialize : ->
      super
      @events =
        "click fieldset h3" : "toggleFieldset"

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'change-additional-interest', @processView)

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

    # Apply behaviors to form after rendering
    postProcessView : ->
      super
      
    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @values.formValues.transactionType = 'AdditionalInterestChanges'
      @values.formValues.id              = @MODULE.POLICY.getPolicyId()

      # Manually filter out "0"s from unchanges State <select>s
      states = _.filter(_.keys(@values.formValues), (k) -> k.match(/State/))
      for state in states
        if @values.formValues[state] == "0"
          @values.formValues[state] = ""
          @values.changedValues = _.reject(@values.changedValues, (i) -> i == state )

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getTransactionRequest(@values, @viewData)
          @callbackSuccess,
          @callbackError
        )

define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class InvoiceAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'invoice', @processView)

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

      # @@ Action specific processing
      timestamp   = @Helpers.makeTimestamp()
      label_stamp = @Helpers.formatDate(new Date(),'ddd MMM DD YYYY HH:mm:ss Z')
      id_stamp    = timestamp.replace(/:|\.\d{3}/g, '')

      # Create additional fields needed to ChangeSet
      formValues =
        changeType         : 'INVOICE'
        reasonCode         : 'INVOICE'
        InvoiceDateCurrent : timestamp
        documentType       : 'Invoice'
        documentLabel      : "Invoice #{label_stamp}"
        documentHref       : ''
        documentId         : "Invoice-#{id_stamp}"

      if _.has(@VALUES.formValues, 'InvoiceAmountCurrent')
        formValues.InvoiceAmountCurrent = @Helpers.formatMoney @VALUES.formValues.InvoiceAmountCurrent 

      if _.has(@VALUES.formValues, 'installmentCharge') && @Helpers.isInt(@VALUES.formValues.installmentCharge)
        formValues.installmentCharge = @Helpers.formatMoney @VALUES.formValues.installmentCharge 
      
      @VALUES.formValues = _.extend @VALUES.formValues, formValues

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )
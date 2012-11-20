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

      timestamp = @Helpers.makeTimestamp()
      label_stamp = @Helpers.formatDate()

      # @VALUES.formValues.positivePaymentAmount = \
      #   Math.abs(@VALUES.formValues.paymentAmount || 0)

      # @VALUES.formValues.paymentAmount = \
      #   -1 * @VALUES.formValues.positivePaymentAmount

      # var id     = model.pxcentral.policy.id(CTX.policy),
      # toSend = null,

      # timestamp = new Date(),

      # // This will be appended to a few document labels
      # labelStamp = timestamp.toString('M/d/yy'),

      # // This will be appended to the document type to create
      # // the id attribute for the PCS
      # idStamp = timestamp.toISOString().replace(/:|\.\d{3}/g, '');

      #   if (params && !mxAdmin.helpers.isEmpty(params)) {
      # params.InvoiceDateCurrent = timestamp.toString('M/d/yyyy');
      # params.changeType = 'INVOICE';
      #       params.reasonCode = 'INVOICE';

      # // An invoice document needs to be generated, create the params needed
      # // NOTE: This isn't the best way to do this.
      # params.documentType  = 'Invoice';
      # params.documentLabel = 'Invoice ' + labelStamp;
      # params.documentHref  = '';
      # params.documentId    = params.documentType + '-' + idStamp;

      # if (!mxAdmin.helpers.isFloat(params.InvoiceAmountCurrent)) {
      #   params.InvoiceAmountCurrent = mxAdmin.helpers.formatMoney(params.InvoiceAmountCurrent);
      # }

      # if (params.installmentCharge && !mxAdmin.helpers.isFloat(params.installmentCharge)) {
      #   params.installmentCharge = mxAdmin.helpers.formatMoney(params.installmentCharge);
      # }




      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getPolicyChangeSet(@VALUES)
          @callbackSuccess,
          @callbackError
        )
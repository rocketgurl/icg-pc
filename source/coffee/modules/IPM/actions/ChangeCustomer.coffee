define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class ChangeCustomerAction extends IPMActionView

    initialize : ->
      super
      @events =
        "click fieldset h3" : "toggleFieldset"

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
      @processViewData(vocabTerms, view)
      @checkMailingAddress @viewData
      @createAdditionalInsured @viewData
      @trigger "loaded", this, @postProcessView

    checkMailingAddress : (view_data) ->
      view_data.DisableMailingAddress = true if view_data.MailingEqualPropertyAddress == "100"

    # Convert AdditionalInsured[n] field in viewData into an array of
    # object grouped by [n] on the additionalInsured property.
    #
    createAdditionalInsured : (view_data) ->
      keys = _.filter(_.keys(view_data),
                      (key) -> key.match /(AdditionalInsured[\d])/)

      grouped = _.groupBy(keys,
                          (i) ->
                            pos = i.search(/\d/)
                            i[pos] if (pos != -1))

      view_data.additionalInsured = _.map(_.values(grouped), (g, idx) ->
        field_values = _.map(g, (v) -> t = view_data[v]; delete view_data[v]; t)
        o = _.object(g, field_values)
        o.number = idx + 1
        o.itemPrefix = "AdditionalInsured#{idx+1}"
        o)

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

      # !! Here be Dragons !!
      #
      # We need to manually pull Customers Customer Insured data
      # into the form. We have to manually clean out false values
      # from the customer object
      customer = @MODULE.POLICY.getTermDataItemValues(
        vocabTerms,
        @MODULE.POLICY.find('Customers Customer[type=Insured]').DataItem)

      # keys w/o false vals
      keys = _.filter(_.keys(customer), (k) -> customer[k] != false)

      # new object w/o false values created with [[k,v],[k,v]] array
      clean_customer = _.object(_.map(keys, (k) -> [k, customer[k]]))

      @viewData = _.extend(@viewData, clean_customer)

    # Apply behaviors to form after rendering
    postProcessView : ->
      super

      @onMailingEqualProperty()
      @adjustInsuredAddress()

    onMailingEqualProperty : ->
      @$el.find(@makeId('MailingEqualPropertyAddress')).on 'change', (e) =>
        insuredAddressFields = @$el.find(@makeId('InsuredMailingAddressLine1')).parents('fieldset').first()

        insuredMailing = @$el.find(@makeId('InsuredMailingAddressLine1'))
                             .parents('fieldset').find('h3 a')
        if $(e.currentTarget).val() == "100"
          insuredAddressFields.css('display', 'block')
          insuredMailing.trigger('click')
        else
          insuredAddressFields.css('display', 'none')

    # Attach listeners to fields to dynamically update Insured Mailing
    # Adress when things change
    adjustInsuredAddress : ->
      mailingEqualProperty = @$el.find(@makeId('MailingEqualPropertyAddress'))

      insuredAddressFields = @$el.find(@makeId('InsuredMailingAddressLine1')).parents('fieldset').first()

      mailingEqualProperty.on 'change', (e) =>
        if $(e.currentTarget).val() == "100"
          insuredAddressFields.css('display', 'block')
          @loadAddressFields()
        else
          insuredAddressFields.css('display', 'none')

      listener_ids = _.map(['MailingEqualPropertyAddress', 'PropertyStreetNumber',
        'PropertyStreetName', 'PropertyAddressLine2', 'PropertyCity',
        'PropertyState', 'PropertyZipCode'], (i) => @makeId(i))

      _.each listener_ids, (i) =>
         @$el.find(i).on 'input', (e) =>
          if mailingEqualProperty.val() == '100'
            @loadAddressFields()

    # Helpers to quickly find scoped fields
    field : (id) -> @$el.find(@makeId(id))
    loadValue : (target, value) -> @field(target).val(value) unless _.isUndefined(value)

    # Move field values into Insured Mailing Address
    loadAddressFields : ->
      @loadValue('InsuredMailingAddressLine1',
                 "#{@field('PropertyStreetNumber').val()} #{@field('PropertyStreetName').val()}")
      @loadValue('InsuredMailingAddressLine2',
                 @field('PropertyAddressLine2').val())
      @loadValue('InsuredMailingAddressCity',
                 @field('PropertyCity').val())
      @loadValue('InsuredMailingAddressState',
                 @field('PropertyState').val())
      @loadValue('InsuredMailingAddressZip',
                 @field('PropertyZipCode').val())
      @loadValue('InsuredMailingAddressLine2', "")

    # **Process Form**
    # On submit we do some action specific processing and then send to the
    # TransactionRequest monster
    #
    submit : (e) ->
      super e

      @values.formValues.transactionType = 'InsuredChanges'

      @values.formValues.id              = @MODULE.POLICY.getPolicyId()
      @values.formValues.reasonCodeLabel = \
        $("#{@makeId('reasonCode')} option[value=#{@values.formValues.reasonCode}]").html()
      @values.formValues.lineItemType    = \
        @values.formValues.reasonCodeLabel.toUpperCase().replace(/\s/g, '_')

      # Assemble the ChangeSet XML and send to server
      @ChangeSet.commitChange(
          @ChangeSet.getTransactionRequest(@values, @viewData)
          @callbackSuccess,
          @callbackError
        )

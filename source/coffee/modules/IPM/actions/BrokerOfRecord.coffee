define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  class BrokerOfRecord extends IPMActionView

    initialize : ->
      super

      @searchAgencies = _.debounce @searchAgencies, 1000

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'broker-of-record', @processView)

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
      # TODO: Make a call to server to get all the agency types
      # and jam them into the vocabTerms for use in chosen powered
      # dropdown box
      location_default =
        {
          label        : 'Hello'
          name         : 'NewLocationCode'
          enumerations : [
            {
              label: "Start searching..."
              value: "0"
            }
          ]
        }
      vocabTerms.terms.push location_default
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


    postProcessView : ->
      super

      # AgencyLocationCode plopped into view
      $('.bor_input_alc').html @MODULE.POLICY.getTermDataItemValue('AgencyLocationCode')

      # Typing in the Chosen search field triggers an Ajax search
      $(document).on('keypress.search', '.chzn-search input', (e) =>
        @searchAgencies $(e.currentTarget)
      );

      # Turn our select into a Chosen select widget
      $(@makeId('NewLocationCode')).chosen({ width: '250px' })


    processPreView : (vocabTerms, view) =>
      @trigger("loaded", this, @postProcessPreview)


    submit : (e) ->
      super e

      # We have to find the real AgencyLocationCode
      xhr_agency_location = @getAgencyLocation(
          @MODULE.CONTROLLER.services.ixdirectory,
          @values.formValues.NewLocationCode
        )

      # We have an AgencyLocationCode
      xhr_agency_location.done(@submitTransaction)

      # We don't
      # xhr_agency_location.fail( - display error msg - )


    submitTransaction : (data, textStatus, jqxhr) =>

      @values.formValues.transactionType = 'BrokerOfRecordChange'
      @values.formValues.agencyLocationCode = \
        $(data).find('Organization Role[type=agency_location] DataItem[name=agencyLocationCode]').attr('value')
      @values.formValues.agencyLocationId = \
        $(data).find('Organization').attr('id')

      # Options for ChangeSet
      options =
        headers : {}

      # Success callback
      callbackFunc = @callbackSuccess

      # Previews require a different callback and an extra header.
      # The header prevents the changes from committing to the DB.
      # If preview is set to 'confirm', then ignore & commit to the DB.
      if _.has(@values.formValues, 'preview')
        if @values.formValues.preview != 'confirm'
          callbackFunc = @callbackPreview
          options.headers = _.extend(
            options.headers,
            { 'X-Commit' : false }
          )

      # Assemble the Transaction Request XML and send to server
      @ChangeSet.commitChange(
        @ChangeSet.getTransactionRequest(@values, @viewData),
        callbackFunc,
        @callbackError,
        options
      )

    getAgencyLocation : (baseUrl, id) ->
      url = "#{baseUrl}organizations/#{id}"
      $.ajax
          url      : url
          dataType : 'xml'
          headers  :
            'Authorization' : "Basic #{@MODULE.CONTROLLER.IXVOCAB_AUTH}"

    # **Populate Chosen select with Agency Locations**
    #
    # @param `$el` _jQuery Object_ Chosen input element
    #
    searchAgencies : ($el) ->
      val = $el.val()
      xhr = @sendAgencyQuery @MODULE.CONTROLLER.services.ixdirectory, val, @MODULE.USER

      $no_results = $('.no-results')
      $no_results.html($no_results.html()?.replace(/No results match/g, 'Searching for -'))

      $list_element = $(@makeId('NewLocationCode'))

      xhr.done(
        (data, textStatus, jqxhr) =>
          organizations = $(data).find('Organization')
          if organizations.length > 0
            list = ("<option value=\"#{o.attributes.id.nodeValue}\">#{o.attributes.id.nodeValue} : #{o.firstChild.childNodes[0].nodeValue}</option>" for o in organizations)
            $list_element.html(list)
            $list_element.trigger("liszt:updated")
            $el.val(val)
      )

    # **Send AJAX search request to ixDirectory**
    #
    # @param `baseUrl` _String_ base url for ixDirectory
    # @param `query` _String_ Search term
    # @param `user` _Object_ User
    # @return _jqXHR_ Deferred object
    #
    sendAgencyQuery : (baseUrl, query, user) ->
      url = "#{baseUrl}organizations/?query=agencyLocationCode:#{query}"
      $.ajax
          url      : url
          dataType : 'xml'
          headers  :
            'Authorization' : "Basic #{user.get('digest')}"
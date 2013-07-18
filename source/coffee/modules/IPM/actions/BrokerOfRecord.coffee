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
      console.log this

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

    # Not fully clear why I had to do this, but I did, the click event
    # was not getting attached to the confirm button
    postProcessPreview : ->
      super

      # Attach event listener to preview button
      @$el.find('form input.button[type=submit]').on(
          'click',
          (e) =>
            e.preventDefault()
            @submit e
        )

    # Assemble data for preview
    processPreview : (vocabTerms, view) =>
      @viewData.preview = @getPreviewData(@values)
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
      xhr_agency_location.fail(@agencyLocationError)

    # Throw an error if we can't get the ALC
    agencyLocationError : (jqXHR, status, error) =>
      @PARENT_VIEW.displayMessage(
        'warning',
        "Could not retrieve Agency Location Code: #{error}"
      ).remove_loader()

    # Assemble the TR
    #
    # - effectiveDate should be for the latest Term
    # - ALC & ALID are taken from the ALC XML (data)
    #
    submitTransaction : (data, textStatus, jqxhr) =>
      @values.formValues.effectiveDate = @MODULE.POLICY.getEffectiveDate()
      @values.formValues.transactionType = 'BrokerOfRecordChange'
      @values.formValues.agencyLocationCode = \
        $(data).find('Organization Role[type=agency_location] DataItem[name=agencyLocationCode]').attr('value')
      @values.formValues.agencyLocationId = \
        $(data).find('Organization').attr('id')

      # Maintain state so we don't have to get again
      @new_agency_data =
        document : data
        address  : @getMailingAddress data
        agency_location_code : @values.formValues.agencyLocationCode

      @current_alc = @MODULE.POLICY.getDataItem(@MODULE.POLICY.getLastTerm().DataItem, 'AgencyLocationCode')

      # Save a current set of BoR data from existing Policy
      @current_bor = @getBrokerOfRecord @MODULE.POLICY

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

    # Get Agency record from ixDirectory
    #
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
      $no_results.prepend('<img src="/img/wpspin_light.gif" class="bor-spinner" />');

      $list_element = $(@makeId('NewLocationCode'))

      # When the response comes back we parse it looking for Organization nodes
      # with an Affiliation childNode of side=location - these are turned into
      # <option> elements and jammed into Chosen
      xhr.done(
        (data, textStatus, jqxhr) =>
          organizations = $(data).find('Organization')
          if organizations.length > 0
            list = ("<option value=\"#{o.attributes.id.nodeValue}\">#{o.firstChild.childNodes[0].nodeValue}</option>" for o in organizations when $(o).find('Affiliation[side=location]').length > 0)
            $list_element.html(list)
            $list_element.trigger("liszt:updated")
            $el.val(val)
          else
            $no_results.html($no_results.html()?.replace(/Searching for -/g, 'No results match'))

          $no_results.find('img').remove()
      )

    # **Send AJAX search request to ixDirectory**
    #
    # @param `baseUrl` _String_ base url for ixDirectory
    # @param `query` _String_ Search term
    # @param `user` _Object_ User
    # @return _jqXHR_ Deferred object
    #
    sendAgencyQuery : (baseUrl, query, user) ->
      url = "#{baseUrl}organizations/?query=name:#{query}"
      $.ajax
          url      : url
          dataType : 'xml'
          headers  :
            'Authorization' : "Basic #{user.get('digest')}"

    # Assemble an object of data for the Preview
    getPreviewData : (values) ->
      {
        old_bor : @current_bor
        new_bor : @getBrokerOfRecord @MODULE.POLICY
        address : @new_agency_data.address
        history : @getBrokerOfRecordHistory @MODULE.POLICY
        values  : values
      }

    # Ask Andy how to get the Term data for this part of the view
    getBrokerOfRecordHistory : (policy) ->
      count = 0
      history = _.map(policy.getTerms(), (term) ->
        count++
        effectiveDate  = if term.EffectiveDate? then term.EffectiveDate else ''
        expirationDate = if term.ExpirationDate? then term.ExpirationDate else ''
        date = "#{moment(effectiveDate).format('YYYY-MM-DD')} - #{moment(expirationDate).format('YYYY-MM-DD')}"

        {
          policy_term       : count
          policy_term_dates : date
          current_alc       : policy.getDataItem(term.DataItem, 'AgencyLocationCode')
          proposed_alc      : policy.getDataItem(term.DataItem, 'AgencyLocationCode')
        }
      )
      last = _.last history
      last.proposed_alc = @new_agency_data.agency_location_code
      last.current_alc  = @current_alc
      history[history.length - 1] = last
      history

    # Return an array of Mailing Address fragments from Organization XML
    getMailingAddress : (organization) ->
      $organization = $(organization).find('Organization')
      $mailing      = $organization.find('Addresses Address[type=mailing]')

      m = (s) -> $mailing.find(s).text() # Round up mailing text

      address = _.map([
        $organization.find('Name').text(),
        "#{m('Street1')} #{m('Street2')} #{m('Street3')}",
        "#{m('City')}, #{m('Province')} #{m('PostalCode')}"
      ], (s) -> s.trim())

      address.join('<br />')

    # Return BoR information from Policy
    getBrokerOfRecord : (policy) ->
      findItem = _.partial policy.getDataItem, policy.getLastTerm().DataItem
      {
        'agency_name'          : findItem('AgencyName'),
        'agency_location_code' : findItem('AgencyLocationCode'),
        'agency_location_name' : findItem('AgencyLocationName'),
        'agency_affiliation'   : findItem('AgencyAffiliation')
      }


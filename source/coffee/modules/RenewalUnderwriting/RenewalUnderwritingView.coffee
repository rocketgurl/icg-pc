define [
  'BaseView',
  'Messenger',
  'modules/RenewalUnderwriting/RenewalUnderwritingModel',
  'modules/RenewalUnderwriting/RenewalVocabModel',
  'modules/ReferralQueue/ReferralAssigneesModel',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_container.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_assignee.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_disposition.html',
  'jqueryui'
], (BaseView, Messenger, RenewalUnderwritingModel, RenewalVocabModel, ReferralAssigneesModel, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) ->

  RenewalUnderwritingView = BaseView.extend

    changeset  : {}
    datepicker : ''

    events :
      'click a[href=assigned_to]' : (e) -> 
        @changeAssignment(@process_event e)

      'click a[href=current_disposition]' : (e) ->
        @changeDisposition(@process_event e)

      'click a[href=review_period]' : (e) -> 
        @reviewPeriod(@process_event e)

      'click a[href=review_deadline]' : (e) -> 
        @reviewDeadline(@process_event e)

      'click .menu-close' : (e) ->
        @Modal.clearMenu e

      'click .ru-assignees-row a' : (e) ->
        @selectAssignee(@process_event e)
        @$el.find('.menu-close').trigger('click')

      'click .ru-disposition-row a' : (e) ->
        @selectDisposition(@process_event e)
        @$el.find('.menu-close').trigger('click')

      'click .cancel' : (e) ->
        e.preventDefault()
        @$el.find('.menu-close').trigger('click')

      'click .confirm' : (e) ->
        @confirmDisposition(@process_event e)

      'change #disposition' : (e) ->
        @inspectDispositionOption(@process_event e)

    initialize : (options) ->
      @Policy      = options.policy
      @PolicyView  = options.policy_view
      @User        = @PolicyView.controller.user
      @ixVocabAuth = @PolicyView.controller.IXVOCAB_AUTH

      # Need to maintain some state around Disposition as we need to
      # do additional validation on changes
      @non_renew_mode = false

      # Setup model for moving metadata around
      @RenewalModel = new RenewalUnderwritingModel(
          id      : @Policy.id
          urlRoot : @Policy.get 'urlRoot'
          digest  : @Policy.get 'digest'
          user    : @User.id
        )

      # Attach events to model
      @RenewalModel.on 'renewal:success', @renewalSuccess, this
      @RenewalModel.on 'renewal:update', @renewalUpdate, this
      @RenewalModel.on 'renewal:error', @renewalError, this

      @putSuccess = _.bind @putSuccess, this
      @putError   = _.bind @putError, this

      ixlibrary = @PolicyView.controller.services.ixlibrary
      assigneeListUrl = "#{ixlibrary.baseURL}/buckets/#{ixlibrary.underwritingBucket}/objects/#{ixlibrary.assigneeListObjectKey}"

      # Get list of assignees
      @AssigneeList     = new ReferralAssigneesModel({ digest : @Policy.get 'digest' })
      @AssigneeList.url = assigneeListUrl
      
      @assigneesFetchError   = _.bind @assigneesFetchError, this
      @assigneesFetchSuccess = _.bind @assigneesFetchSuccess, this
      
      @AssigneeList.fetch
        success : @assigneesFetchSuccess
        error   : @assigneesFetchError

      # Setup ixVocab terms for disposition modal window
      vocabs =
        RenewalVocabDispositions : 'UnderwritingDisposition'
        RenewalVocabReasons      : 'NonRenewalReasonCode'

      for key, val of vocabs
        @[key] = new RenewalVocabModel({
          id       : val
          url_root : @PolicyView.controller.services.ixvocab
          digest   : @ixVocabAuth
        })
        @[key].checkCache()

    # Callbacks for Assignee List fetch
    assigneesFetchSuccess : (model, response, options) ->
      @assignees_list = model.getAll()
      if @assignees_list.length > 0
        @assignees_list = _.map @assignees_list, (assignee) ->
          _.extend assignee, { id : _.uniqueId() }

    assigneesFetchError : (model, xhr, options) ->
      @Amplify.publish(@PolicyView.cid, 'warning', "Could not fetch assignees list from server : #{xhr.status} - #{xhr.statusText}", 2000)

    render : ->
      if $("#ru-spinner-#{@PolicyView.cid}").length > 0
        $("#ru-loader-#{@PolicyView.cid}").show()
        @loader = @Helpers.loader("ru-spinner-#{@PolicyView.cid}", 80, '#696969')
        @loader.setFPS(48)
     
      # This is just for testing the loader, remove delay
      # load = _.bind(@RenewalModel.fetchRenewalMetadata, @Policy)
      # _.delay(load, 1000)

      @RenewalModel.fetch(
        success : (model, resp) ->
          model.trigger('renewal:success', resp)
        error : (model, resp) ->
          model.trigger('renewal:error', resp)
      )

      this # so we can chain

    removeLoader : ->
      if @loader?
        @loader.kill()
        $("#ru-loader-#{@cid}").hide()

    process_event : (e) ->
      e.preventDefault()
      $(e.currentTarget)

    # Stub data for changeAssignment menu
    changeAssignment : (el) ->
      data = 
        cid : @cid
        assignees : @assignees_list

      @Modal.attach_menu el, '.ru-menus', tpl_ru_assignees, data

    selectAssignee : (el) ->
      @processChange 'renewal.assignedTo', $(el).html()

    selectDisposition : (el) ->
      @processChange 'insuranceScore.disposition', $(el).html()

    changeDisposition : (el) ->
      r = @RenewalModel.attributes

      data = 
        cid                  : @cid
        dispositions         : @RenewalVocabDispositions.get 'data'
        reasons              : @RenewalVocabReasons.get 'data'
        disposition          : r.insuranceScore.disposition
        nonRenewalReasonCode : r.renewal.nonRenewalReasonCode
        nonRenewalReason     : r.renewal.nonRenewalReason
        comment              : r.renewal.comment

      @Modal.attach_menu(el, '.ru-menus', tpl_ru_disposition, data)

      # Set default val of selects
      for input in ['nonRenewalReasonCode', 'disposition']
        if data[input]?
          @$el.find("##{input}").val(data[input])

      @$el.find('.nonrenewal-reasons-block').hide()

      @inspectDispositionOption(@$el.find('#disposition'))

    # Display some extra fields if this is a non-renew disposition
    inspectDispositionOption : (el) ->
      @$el.find('.nonrenewal-reasons-block').hide()
      @non_renew_mode = false
      if el.val() == 'non-renew'
        @non_renew_mode = true # confirmDisposition() needs this
        @$el.find('.nonrenewal-reasons-block').show()

    # When we grab the form fields from disposition modal we need to:  
    # * validate any non-renew fields
    # * combine those field names into key.value forms for the right structure
    # * create a changeset for use by the model
    #
    confirmDisposition : (el) ->
      @$el.find('.confirm').attr('disabled', true)

      error = false
      field_map = 
        'disposition'          : 'insuranceScore'
        'comment'              : 'renewal'
        'nonRenewalReasonCode' : 'renewal'
        'nonRenewalReason'     : 'renewal'

      fields = _.keys field_map

      # Validate Non-renew fields if present
      if @non_renew_mode
        non_renew_fields = fields[2..]
        send_fields      = fields
        for field in non_renew_fields
          $field = @$el.find("##{field}")
          if $field.val() == '' || $field.val() == '- Select one -'
            error = true
            $field.parent().find('label').addClass('error')
          else
            $field.parent().find('label').removeClass('error')
        if error
          @$el.find('.confirm').attr('disabled', false)
          return null
      else
        send_fields = fields[0..1]

      # Create changeset (which updates the model)
      changes = false
      for field in send_fields
        if @updateChangeset("#{field_map[field]}.#{field}", @$el.find("##{field}").val())
          changes = true

      # If something actually changed, then persist it, or throw notice
      if changes
        @RenewalModel.putFragment(@putSuccess, @putError, @changeset)
        true
      else
        @$el.find('.confirm').attr('disabled', false)
        @Amplify.publish(@PolicyView.cid, 'notice', "No changes made", 2000)
        false

    reviewPeriod : (el) ->
      @$el.find('input[name=reviewPeriod]').datepicker("show")

    reviewDeadline : (el) ->
      @$el.find('input[name=reviewDeadline]').datepicker("show")

    attachDatepickers : ->
      @dateChanged   = _.bind(@dateChanged, this)
      @setDatepicker = _.bind(@setDatepicker, this)

      options =
        dateFormat : 'yy-mm-dd'
        onClose    : @dateChanged
        beforeShow : @setDatepicker

      @$el.find('input[name=reviewPeriod]').datepicker(options)
      @$el.find('input[name=reviewDeadline]').datepicker(options)

    # Get the field information from the HTML Element in datepicker and pass
    # to processChange to see if we need to save anything.  
    # @param `field` _String_ name of changeset field 
    dateChanged : (date) ->
      field = "renewal.#{$(@datepicker).attr('name')}"
      @processChange field, date

    # Alter responses based on boolean values from DB. This affects which
    # portions of the UI will appear and how they will appear
    #
    # @param `resp` _Object_ DB response   
    # @return _Object_
    processResponseFields : (resp) ->
      resp.reviewStatusFlag = resp.renewal.renewalReviewRequired
      resp.lossHistoryFlag  = true

      if _.isEmpty resp.lossHistory
        resp.lossHistoryFlag = false

      # Convert booleans to Yes/No
      for field in ['renewalReviewRequired']
        if resp.renewal[field] == true then resp.renewal[field] = 'Yes' else resp.renewal[field] = 'No'

      if resp.renewal.inspectionOrdered == false
        delete resp.renewal.inspectionOrdered

      # Normalize dates
      for field in ['reviewPeriod', 'reviewDeadline']
        if resp.renewal[field]?
          resp.renewal[field] = _.trim resp.renewal[field].replace(/00:00:00.0/g,'')

      # Remove quotes from scores (per Terry)
      for field in ['newInsuranceScore', 'oldInsuranceScore']
        if resp.insuranceScore[field]?
          resp.insuranceScore[field] = resp.insuranceScore[field].replace(/'|"/g,'')

      resp

    # **Did a value change?** Check the changeset to see if a value changed. 
    # Pre-process form fields for use in changeset - For the field we check
    # for the existence of a '.' and split on that to deal with deeper values
    # in the changeset.  
    #
    # @param `field` _String_ name of changeset field  
    # @param `val` _String_ value of field that changed  
    # @return _Boolean_  
    updateChangeset : (field, val) ->
      old_val = ''
      field = if field.indexOf('.') > -1 then field.split('.') else field
      if _.isArray(field)
        old_val = @changeset[field[0]][field[1]]
      else
        old_val = field

      @changed_field = field # We need to maintain state for @updateElement

      if old_val != val
        # This is where we would save the value to the server
        if _.isArray(field)
          # Update the changeset and set model
          @changeset[field[0]][field[1]] = val
          @RenewalModel.set(field[0], @changeset[field[0]])
        else
          @RenewalModel.set(field, val)
        true
      else
        false

    # **Did a value change?** If a value changed, then persist it to server  
    #
    # @param `field` _String_ name of changeset field  
    # @param `val` _String_ value of field that changed  
    # @return _Boolean_
    processChange : (field, val) ->
      if @updateChangeset(field, val)
        @updateElement 'loading'
        @RenewalModel.putFragment(@putSuccess, @putError, @changeset)
        true
      else
        @Amplify.publish(@PolicyView.cid, 'notice', "No changes made", 2000)
        false

    # Apply styles to elements to indicate loading/complete status. <a>'s
    # also need new html content inserted
    #
    # @param `new_class` _String_ className to apply  
    #
    updateElement : (new_class) ->
      elements = 
        assignedTo     : 'a[href=assigned_to]'
        disposition    : 'a[href=current_disposition]'
        reviewDeadline : 'input[name=reviewDeadline]'
        reviewPeriod   : 'input[name=reviewPeriod]'
        reason         : 'textarea[name=reason]'

      if @changed_field?
        target_el = elements[@changed_field[1]]
        new_value = @changeset[@changed_field[0]][@changed_field[1]]

      $el = @$el.find target_el 
      $el.removeClass().addClass(new_class)

      if $el.is('a')
        $el.html("""#{new_value}&nbsp;<i class="icon-pencil"></i>""")

      if $el.is('textarea') && new_class == 'complete'
        @resetRenewalReason $el

      if $el.is('textarea') && new_class == 'incomplete'
        $el.attr('disabled', false)
        $el.parent().find('.confirm').attr('disabled', false)


    # Set the value of datepicker for use in determining changes.  
    # @param `el` _HTML Element_  
    setDatepicker : (el) ->
      @datepicker = el

    # If the save is successfull then fetch the updated AssigneeList and
    # return model
    #
    # @param `model` _Object_  
    # @param `response` _Object_ XHR Object  
    # @param `options` _Object_    
    # @return _Object_ Model  
    #
    putSuccess : (model, response, options) ->
      @$el.find('.confirm').attr('disabled', false)
      @Amplify.publish(@PolicyView.cid, 'success', "Saved changes!", 2000)

      # Refresh the Assignee List
      @AssigneeList.fetch
        success : @assigneesFetchSuccess
        error   : @assigneesFetchError

      @RenewalModel.fetch(
        success : (model, resp) ->
          model.trigger('renewal:update', resp)
        error : (model, resp) ->
          model.trigger('renewal:error', resp)
      )

      model

    putError : (model, xhr, options) ->
      @$el.find('.confirm').attr('disabled', false)
      @Amplify.publish(@PolicyView.cid, 'warning', "Could not save!", 2000)

    processRenewalResponse : (resp) ->
      unless resp.insuranceScore?
        @renewalError {statusText : 'Dataset empty', status : 'pxCentral'}
        return false

      resp.cid = @cid # so we can phone home to the correct view

      if resp.insuranceScore.disposition == ''
        resp.insuranceScore.disposition = 'New'

      # Side effects!
      resp = @processResponseFields(resp)

      # Store a changeset to send back to server
      @changeset =
        renewal : _.omit(resp.renewal, ["inspectionOrdered", "renewalReviewRequired"])
        insuranceScore : 
          disposition : resp.insuranceScore.disposition

      resp

    renewalSuccess : (resp) ->
      if resp?
        # If the dataset comes back empty for some reason, then display
        # an error message and bomb out.
        if _.isEmpty resp
          @renewalError({statusText : 'Dataset empty', status : 'pxCentral'})
          return false

        # walk the response and adjust information to match the view
        resp = @processRenewalResponse(resp)

        if resp.lossHistoryFlag == true 
          for lossRecord in resp.lossHistory
            do (lossRecord) -> 
              lossDate = lossRecord.lossDate
              if lossDate.indexOf(' ') != -1
                lossRecord.lossDate = lossDate.substring 0, lossDate.indexOf(' ')
            
        @$el.html(@Mustache.render tpl_ru_container, resp)

        @removeLoader()
        @PolicyView.resize_view @$el
        @attachDatepickers()
      else
        @renewalError({statusText : 'Dataset empty', status : 'Backbone'})

    renewalUpdate : (resp) ->
      if resp == null || _.isEmpty(resp)
        @renewalError({statusText : 'Dataset empty', status : 'pxCentral'})
        return false

      # walk the response and adjust information to match the view
      resp = @processRenewalResponse(resp)

      @undelegateEvents()
      @$el.find('input[name=reviewPeriod]').datepicker("destroy")
      @$el.find('input[name=reviewDeadline]').datepicker("destroy")

      @$el.html @Mustache.render(tpl_ru_container, resp)

      @delegateEvents()
      @attachDatepickers()

    renewalError : (resp) ->
      @removeLoader()
      @Amplify.publish(@PolicyView.cid, 'warning', "Could not retrieve renewal underwriting information: #{resp.statusText} (#{resp.status})")
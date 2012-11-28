define [
  'BaseView',
  'Messenger',
  'modules/RenewalUnderwriting/RenewalUnderwritingModel',
  'modules/ReferralQueue/ReferralAssigneesModel',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_container.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_assignee.html',
  'text!modules/RenewalUnderwriting/templates/tpl_renewal_underwriting_disposition.html',
  'jqueryui'
], (BaseView, Messenger, RenewalUnderwritingModel, ReferralAssigneesModel, tpl_ru_container, tpl_ru_assignees, tpl_ru_disposition) ->

  RenewalUnderwritingView = BaseView.extend

    CHANGESET  : {}
    DATEPICKER : ''

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

    initialize : (options) ->
      @$el         = options.$el
      @policy      = options.policy
      @policy_view = options.policy_view


      # Setup model for moving metadata around
      @RenewalModel = new RenewalUnderwritingModel(
          id      : @policy.id
          urlRoot : @policy.get 'urlRoot'
          digest  : @policy.get 'digest'
        )

      # Attach events to model
      @RenewalModel.on 'renewal:success', @renewalSuccess, this
      @RenewalModel.on 'renewal:error', @renewalError, this

      @putSuccess = _.bind @putSuccess, this
      @putError   = _.bind @putError, this

      ixlibrary = "#{@policy_view.controller.services.ixlibrary}buckets/underwriting/objects/assignee_list.xml"

      # Get list of assignees
      @AssigneeList     = new ReferralAssigneesModel({ digest : @policy.get 'digest' })
      @AssigneeList.url = ixlibrary
      
      @assigneesFetchError   = _.bind @assigneesFetchError, this
      @assigneesFetchSuccess = _.bind @assigneesFetchSuccess, this
      
      @AssigneeList.fetch
        success : @assigneesFetchSuccess
        error   : @assigneesFetchError

    # Callbacks for Assignee List fetch
    assigneesFetchSuccess : (model, response, options) ->
      @ASSIGNEES_LIST = model.getRenewals()
      if @ASSIGNEES_LIST.length > 0
        @ASSIGNEES_LIST = _.map @ASSIGNEES_LIST, (assignee) ->
          _.extend assignee, { id : _.uniqueId() }

    assigneesFetchError : (model, xhr, options) ->
      @Amplify.publish(@policy_view.cid, 'warning', "Could not fetch assignees list from server : #{xhr.status} - #{xhr.statusText}", 2000)

    render : ->
      @show()
      $("#ru-loader-#{@policy_view.cid}").show()
      @loader = @Helpers.loader("ru-spinner-#{@policy_view.cid}", 80, '#696969')
      @loader.setFPS(48)
     
      # This is just for testing the loader, remove delay
      # load = _.bind(@RenewalModel.fetchRenewalMetadata, @policy)
      # _.delay(load, 1000)

      @RenewalModel.fetch(
          # url : @url('/underwriting')
          url : '/mocks/renewal_underwriting_get.json' #mocks
          success : (model, resp) ->
            model.trigger('renewal:success', resp)
          error : (model, resp) ->
            model.trigger('renewal:error', resp)
        )

      this # so we can chain

    removeLoader : ->
      @loader.kill()
      $("#ru-loader-#{@cid}").hide()

    show : ->
      @$el.fadeIn('fast')

    hide : ->
      @$el.hide()

    process_event : (e) ->
      e.preventDefault()
      $(e.currentTarget)

    # Stub data for changeAssignment menu
    changeAssignment : (el) ->
      data = 
        cid : @cid
        assignees : @ASSIGNEES_LIST

      @Modal.attach_menu el, '.ru-menus', tpl_ru_assignees, data

    selectAssignee : (el) ->
      @processChange 'renewal.assignedTo', $(el).html()

    changeDisposition : (el) ->
      data = 
        cid : @cid
        dispositions : [
          { id : 1, name : 'Pending' }
          { id : 2, name : 'Dead' }
          { id : 3, name : 'Vaporized' }
        ]

      @Modal.attach_menu el, '.ru-menus', tpl_ru_disposition, data

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

    # Get the field information from the HTML Element in DATEPICKER and pass
    # to processChange to see if we need to save anything.  
    # @param `field` _String_ name of CHANGESET field 
    dateChanged : (date) ->
      field = "renewal.#{$(@DATEPICKER).attr('name')}"
      @processChange field, date

    # **Did a value change?**  
    # Check the CHANGESET to see if a value changed. For the field we check
    # for the existence of a '.' and split on that to deal with deeper values
    # in the CHANGESET.  
    #
    # @param `field` _String_ name of CHANGESET field  
    # @param `val` _String_ value of field that changed  
    # @return _Boolean_
    processChange : (field, val) ->
      old_val = ''
      field = if field.indexOf('.') > -1 then field.split('.') else fiel
      if _.isArray(field)
        old_val = @CHANGESET[field[0]][field[1]]
      else
        old_val = field

      if old_val != val
        # This is where we would save the value to the server
        if _.isArray(field)
          # Update the changeset and set model
          @CHANGESET[field[0]][field[1]] = val
          @RenewalModel.set(field[0], @CHANGESET[field[0]])
        else
          @RenewalModel.set(field, val)

        @RenewalModel.putFragment(@putSuccess, @putError, @CHANGESET.renewal)
      else
        @Amplify.publish(@policy_view.cid, 'notice', "No changes made", 2000)
        false

    # Set the value of DATEPICKER for use in determining changes.  
    # @param `el` _HTML Element_  
    setDatepicker : (el) ->
      @DATEPICKER = el

    putSuccess : (model, response, options) ->
      assigned_to = @CHANGESET.renewal.assignedTo
      if assigned_to?
        @$el.find('a[href=assigned_to]').html(
            """#{assigned_to}&nbsp;<i class="icon-pencil"></i>"""
          )

      @Amplify.publish(@policy_view.cid, 'success', "Saved changes!", 2000)

      # Refresh the Assignee List
      @AssigneeList.fetch
        success : @assigneesFetchSuccess
        error   : @assigneesFetchError

    putError : () ->
      @Amplify.publish(@policy_view.cid, 'warning', "Could not save!", 2000)

    renewalSuccess : (resp) ->
      if resp?
        resp.cid = @cid

        # Store a changeset to send back to server
        @CHANGESET =
          renewal : _.omit(resp.renewal, ["inspectionOrdered", "renewalReviewRequired"])
          insuranceScore : resp.insuranceScore.currentDisposition

        @$el.html @Mustache.render tpl_ru_container, resp
        @removeLoader()
        @show()
        @attachDatepickers()

    renewalError : (resp) ->
      @Amplify.publish(@policy_view.cid, 'warning', "Could not retrieve renewal underwriting information: #{resp.statusText} (#{resp.status})")




define [
  'BaseView'
  'Helpers'
  'Messenger'
  'modules/ReferralQueue/ReferralTaskView'
  'modules/ReferralQueue/ReferralAssigneesModel'
  'text!modules/ReferralQueue/templates/tpl_referral_container.html'
  'text!modules/ReferralQueue/templates/tpl_manage_assignees.html'
], (BaseView, Helpers, Messenger, ReferralTaskView, ReferralAssigneesModel, tpl_container, tpl_menu_assignees) ->

  ReferralQueueView = BaseView.extend

    PAGINATION_EL : {} # Pagination form elements

    events :
      "change .referrals-pagination-page"    : 'updatePage'
      "change .referrals-pagination-perpage" : 'updatePerPage'
      "change input[name=show-all]"          : 'updateStatus'
      "click .referrals-switch a"            : 'updateOwner'
      "click .referrals-sort-link"           : 'sortTasks'
      "click .menu-confirm"                  : 'saveAssignees'
      "click .menu-cancel"                   : 'clearAssignees'
      "click .btn-manage-assignees"          : 'toggleManageAssignees'

    initialize : (options) ->
      _.bindAll(this
        'toggleLoader'
        'renderTasks'
        'tasksError'
        'renderAssigneesError'
        'assigneeSuccess'
        'assigneeError'
        )

      @MODULE      = options.module || false
      @COLLECTION  = options.collection || false
      @PARENT_VIEW = options.view || false

      # When the collection is populated, generate the views
      @COLLECTION.on 'update', => @toggleLoader true
      @COLLECTION.on 'reset', @renderTasks
      @COLLECTION.on 'error', @tasksError

      # Create an AssigneeList model to manage the XML list
      if @MODULE != false
        ixlibrary = @MODULE.controller.services.ixlibrary
        digest    = @MODULE.controller.user.get 'digest'
        assigneeListUrl = "#{ixlibrary.baseURL}/buckets/#{ixlibrary.underwritingBucket}/objects/#{ixlibrary.assigneeListObjectKey}"

      @AssigneeList     = new ReferralAssigneesModel({ digest : digest })
      @AssigneeList.url = assigneeListUrl
      @AssigneeList.fetch
        error : @renderAssigneesError

      @AssigneeList.on 'change', @assigneeSuccess
      @AssigneeList.on 'fail', @assigneeError

    render : ->
      # Setup flash module & main container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_container, { cid : @cid, pagination: {} }
      @$el.html html

      # Setup Flash Messenger
      @messenger = new Messenger(@PARENT_VIEW, @cid)

      # Find the container to load rows into
      @CONTAINER = @$('table.module-referrals tbody')

      # Cache form elements for speedy access
      @PAGINATION_EL = @cachePaginationElements()

      # Throw up our loading image until the tasks come in
      @toggleLoader(true)

      # If we couldn't load assignee_list.xml then disable the button
      unless @ASSIGNEE_STATE
        @$('.button-manage-assignees').attr('disabled', true)

      this

    # **Render tasks**
    # Map the collection models into an array of ReferralTaskViews that we
    # can use to populate the overall view with task rows.
    #
    # @param `collection` _Object_ ReferralTaskCollection
    # @return _Array_
    #
    renderTasks : (collection) ->
      @TASK_VIEWS = collection.map (model) =>
        new ReferralTaskView(
            model       : model,
            parent_view : this
          )

      @CONTAINER.html('')

      for task in @TASK_VIEWS
        @CONTAINER.append(task.render())

      @toggleLoader()
      @updatePagination(collection, @PAGINATION_EL)

      # Need to let the footer know that we changed height
      if _.has(@MODULE, 'trigger')
        @MODULE.trigger 'workspace.rendered'

    # Handle server errors from the Tasks Collection
    #
    # @param `collection` _Object_ ReferralTaskCollection
    # @param `response` _jqXHR_ Response object
    #
    tasksError : (collection, response) ->
      @toggleLoader()
      @Amplify.publish @cid, 'warning', "Could not load referrals: #{response.status} - #{response.statusText}"
      console.log ["tasksError", collection, response]

    # Toggle the owner buttons on the UI and trigger collection.getReferrals()
    updateOwner : (e) ->
      e.preventDefault()
      $btn = $(e.currentTarget)

      unless $btn.hasClass 'active'
        $('.referrals-switch > a').removeClass 'active'
        $btn.addClass 'active'

        if $btn.attr('href') is 'myreferrals'
          @COLLECTION.setParam 'owner', 'default'
        else
          @COLLECTION.setParam 'owner', null

    updatePage : (e) ->
      page = +e.currentTarget.value
      if page > 0
        @COLLECTION.setParam 'page', page

    updatePerPage : (e) ->
      perPage = +e.currentTarget.value
      if perPage > 0
        @COLLECTION.setParam 'perPage', perPage

    updateStatus : (e) ->
      showAll = $(e.currentTarget).prop 'checked'
      if showAll
        @COLLECTION.setParam 'status', null
      else
        @COLLECTION.setParam 'status', 'default'

    # Return an object of pagination form elements
    # @return _Object_
    cachePaginationElements : ->
      items    : @$el.find('.pagination-a')
      jump_to  : @$el.find('.referrals-pagination-page')
      per_page : @$el.find('.referrals-pagination-perpage')

    # Update the pagination controls with current info
    #
    # @param `collection` _Object_ ReferralTaskCollection
    # @param `elements` _Object_ jQuery wrapped HTML elements
    #
    updatePagination : (collection, elements) ->
      # Items count
      per_page = collection.perPage

      if per_page > collection.totalItems
        end_position   = collection.totalItems
        start_position = 1
      else
        end_position   = collection.page * per_page
        start_position = end_position - per_page

      start_position = if start_position == 0 then 1 else start_position

      if end_position > collection.totalItems
        end_position = collection.totalItems

      elements.items.find('span').html("Items #{start_position} - #{end_position} of #{collection.totalItems}")

      # Jump to pages
      pages        = [1..Math.ceil(collection.totalItems / per_page)]
      current_page = collection.page
      values       = _.map pages, (page) ->
        if page is current_page
          "<option value=\"#{page}\" selected>#{page}</option>"
        else
          "<option value=\"#{page}\">#{page}</option>"
      elements.jump_to.html(values)


    # Place a loading animation on top of the content
    toggleLoader : (bool) ->
      # If this is empty we're probably testing
      if $("#referrals-spinner-#{@cid}").length < 1
        return false

      if bool and !@loader?
        if $('html').hasClass('lt-ie9') is false
          @loader = Helpers.loader("referrals-spinner-#{@cid}", 100, '#ffffff')
          @loader.setDensity(70)
          @loader.setFPS(48)
        $("#referrals-loader-#{@cid}").show()
      else
        if @loader? and $('html').hasClass('lt-ie9') is false
          @loader.kill()
          @loader = null
        $("#referrals-loader-#{@cid}").hide()

    # Sort the current page of tasks in memory.
    #
    # @param `e` _Event_ Click event
    # @param `collection` _Object_ ReferralTaskCollection
    #
    sortTasks : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)
      $sortIcon = $el.find '.glyphicon'
      sortProp = $el.attr 'href'

      @COLLECTION.sortTasks sortProp
      @remove_indicators()

      if @COLLECTION.sortDir is 'asc'
        $sortIcon.addClass 'glyphicon-chevron-down'
      else
        $sortIcon.addClass 'glyphicon-chevron-up'

    # clear all sorting indicators
    remove_indicators : ->
      $('.referrals-sort-link').each ->
        $icon = $(this).find '.glyphicon'
        $icon.removeClass 'glyphicon-chevron-up'
        $icon.removeClass 'glyphicon-chevron-down'

    # JSON data from AssigneeList needs some additional parsing to render
    # correctly in Mustache
    toggleManageAssignees : (e) ->
      e.preventDefault()
      if @AssigneeList.get('json')?
        data =
          assignees  : @AssigneeList.getAll()
          isSagesure : @MODULE.controller.current_state?.business is 'cru'
        @Modal.attach_menu $(e.currentTarget), '.rq-menus', tpl_menu_assignees, data
      else
        @Amplify.publish @cid, 'warning', "Unable to load assignees from server."

    renderAssigneesError : (model, xhr, options) ->
      @ASSIGNEE_STATE = false
      @Amplify.publish 'controller', 'warning', "Warning - could not load assignees xml: #{xhr.status} - #{xhr.statusText}"

    # Loop through the assignee list and update the assignee objects'
    # attributes based on the associated checkbox's state.
    # 
    # SageSure assignees can be assigned 'new_business' and/or 'renewals'
    # and should be considered 'active' in case either is true.
    # 
    # FedNat assignees only have an 'active' attribute.
    #
    # The updated Assignee JSON is set back to the model, which generates XML
    # and PUTs it back to the server.
    saveAssignees : (e) ->
      e.preventDefault()
      @assigneeLoader()

      assigneeList = @AssigneeList.getAll()

      newList = _.map assigneeList, (assignee) ->
        newAssignee = {}
        newAssignee.identity = assignee.identity
        @$("input[name*='#{assignee.identity}']").each (i, input) ->
          name = $(input).attr('name')
          if /active_/.test name
            newAssignee.active = input.checked
          if /newbiz_/.test name
            newAssignee.new_business = input.checked
          if /renewal_/.test name
            newAssignee.renewals = input.checked

        if _.has(newAssignee, 'new_business') or _.has(newAssignee, 'renewals')
          newAssignee.active = newAssignee.new_business or newAssignee.renewals
        return newAssignee

      @AssigneeList.set 'json', { Assignee : newList }
      @AssigneeList.putList()

    # Remove the menu from DOM so it will be generated fresh erasing any
    # changes from the user
    clearAssignees : (e) ->
      e.preventDefault()
      @Modal.removeMenu()

    assigneeLoader : ->
      @$el.find('.menu-status')
          .show()
          .html('<strong class="menu-loading">Saving changes&hellip;</strong>')

    assigneeSuccess : (model) ->
      @$el.find('.menu-status')
          .show()
          .html('<strong class="menu-success">Assignee List saved!</strong>')
          .delay(2000)
          .fadeOut('slow')

    assigneeError : (msg) ->
      @$el.find('.menu-status')
          .show()
          .html("""<strong class="menu-error">Error saving: #{msg}</strong>""")
          .delay(5000)
          .fadeOut('slow')

define [
  'BaseView'
  'modules/ReferralQueue/AssigneeListCollection'
  'modules/ReferralQueue/AssigneeListItemView'
  'text!modules/ReferralQueue/templates/tpl_manage_assignees.html'
], (BaseView, AssigneeListCollection, AssigneeListItemView, tpl_manage_assignees) ->

  class AssigneeListView extends BaseView

    events :
      'click #assignee-list-confirm' : 'saveAssignees'

    # Cache subviews to reference and destroy when needed
    subviews : []

    initialize : (options) ->
      _.bindAll(this
        'getData'
        'resetData'
        'render'
        'assigneeLoader'
        'assigneeSuccess'
        'assigneeError'
        )

      # Is the the SageSure or FedNat workspace?
      @isSagesure = (options.controller.current_state or {}).business is 'cru'

      # Render and cache reusable DOM elements
      @cacheElements()

      # Instantiate the collection, pass a reference
      # to the controller, and setup event handlers
      @collection = new AssigneeListCollection()
      @collection.controller = options.controller
      @setupCollectionEventHandlers()
      
      # fetch the Assignee list the first time the modal is called
      @$el.on 'show.bs.modal', @getData

      # revert models back to their saved state when hiding the modal
      @$el.on 'hidden.bs.modal', @resetData

    setupCollectionEventHandlers : ->
      @collection.on 'reset',   @render
      @collection.on 'request', @assigneeLoader
      @collection.on 'success', @assigneeSuccess
      @collection.on 'error',   @assigneeError

    cacheElements : ->
      @$('.modal-body').html @Mustache.render tpl_manage_assignees, { isSagesure : @isSagesure }

      @$statusEl = @$('.list-status')
      @$confirmBtn = @$('#assignee-list-confirm')
      if @isSagesure
        @$newbizList = @$('#assignee-newbiz .list-group')
        @$renewalList = @$('#assignee-renewal .list-group')
      else
        @$activeList = @$('#assignee-active .list-group')

    getData : ->
      @collection.fetch()

    resetData : ->
      @clearLists()
      @clearSubviews()
      # @collection.revertModels()

    initSubview : (model, viewType, $listView) ->
      subview = new AssigneeListItemView
        model : model
        type  : viewType
      $listView.append subview.$el
      @subviews.push subview

    clearLists : ->
      if @isSagesure
        @$newbizList.empty()
        @$renewalList.empty()
      else
        @$activeList.empty()

    render : ->
      @collection.each (model) =>
        if @isSagesure
          @initSubview model, 'new_business', @$newbizList
          @initSubview model, 'renewals', @$renewalList
        else
          @initSubview model, 'active', @$activeList
      @$statusEl.empty()
      @$confirmBtn.prop 'disabled', @collection.length < 1

    saveAssignees : (e) ->
      e.preventDefault()
      @collection.update()

    assigneeLoader : ->
      @$confirmBtn.prop 'disabled', true
      @$statusEl
        .html('<strong class="list-loading">Working&hellip;</strong>')
        .show()

    assigneeSuccess : (collection, jqXHR) ->
      @$confirmBtn.prop 'disabled', @collection.length < 1
      @$statusEl
        .html('<strong class="list-success">List Updated!</strong>')
        .show()
        .delay(3000)
        .fadeOut('slow')
      @$el.modal('hide')

    assigneeError : (collection, jqXHR) ->
      @$confirmBtn.prop 'disabled', true
      @Amplify.publish 'controller', 'warning', "Warning - could not load assignees xml: #{jqXHR.status} - #{jqXHR.statusText}", 5000
      @$statusEl
        .html('<strong class="list-error">Error!</strong>')
        .show()
        .delay(5000)
        .fadeOut('slow')

    clearSubviews : ->
      while @subviews.length > 0
        view = @subviews.shift()
        view.destroy()
        view = null

    dispose : ->
      super()
      @collection = null
      @clearSubviews()



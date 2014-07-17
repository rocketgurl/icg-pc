define [
  'collapse'
  'button'
  'BaseView'
  'modules/PolicyQuickView/collections/ActivityCollection'
  'modules/PolicyQuickView/views/AddNoteView'
  'text!modules/PolicyQuickView/templates/tpl_activities.html'
], (collapse, button, BaseView, ActivityCollection, AddNoteView, tpl_activities) ->

  class ActivityView extends BaseView

    events :
      'keyup  .activity-search' : 'filterCollection'
      'change .activity-sort'   : 'sortCollection'

    initialize : (options) ->
      @POLICY = policy = options.policy
      events  = policy.getEvents()
      notes   = policy.getNotes()

      @collection = new ActivityCollection(events.concat(notes), {
        policyUrl   : policy.url()
        attachments : policy.getAttachments()
        tasks       : policy.getTasks()
      })

      @addNotes = new AddNoteView
        activityCollection  : @collection
        attachmentsLocation : options.attachmentsLocation
        policy              : policy
        el                  : @$("#add-note-container-#{options.qvid}")

      @collection.on 'reset add', @render, this
      @POLICY.on 'change:refresh change:version', @handlePolicyRefresh, this
      @render()

    handlePolicyRefresh : ->
      events = @POLICY.getEvents()
      notes  = @POLICY.getNotes()
      @collection.attachments = @POLICY.getAttachments()
      @collection.tasks       = @POLICY.getTasks()
      @collection.reset events.concat(notes)

    filterCollection : (e) ->
      throttledFilter = _.throttle @collection.filterByQuery, 500
      throttledFilter e.currentTarget.value
      return this

    sortCollection : (e) ->
      @collection.sortBy e.currentTarget.value
      return this

    render : ->
      template = @Mustache.render tpl_activities, { activities: @collection.toJSON() }
      @$('.activity-wrapper').html template
      return this

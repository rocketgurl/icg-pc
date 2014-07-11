define [
  'collapse'
  'button'
  'BaseView'
  'modules/PolicyQuickView/ActivityCollection'
  'text!modules/PolicyQuickView/templates/tpl_activities.html'
], (collapse, button, BaseView, ActivityCollection, tpl_activities) ->

  class ActivityView extends BaseView

    events:
      'keyup .activity-search' : 'filterCollection'
      'change .activity-sort'  : 'sortCollection'
      'submit .add-note-form'  : 'addNote'

    initialize : (options) ->
      @POLICY = policy = options.policy
      events  = policy.getEvents()
      notes   = policy.getNotes()

      @addNoteButton = @$('.add-note-button')
      @noteTextarea  = @$('.note-text')

      # Keep callback functions' context bound to this view
      _.bindAll this, 'addNoteSuccess', 'addNoteError'

      @collection = new ActivityCollection(events.concat(notes), {
        tasks : options.policy.getTasks()
      })

      @collection.on 'reset add', @render, this
      @render()

    filterCollection : (e) ->
      throttledFilter = _.throttle @collection.filterByQuery, 500
      throttledFilter e.currentTarget.value
      return this

    sortCollection : (e) ->
      @collection.sortBy e.currentTarget.value
      return this

    addNote : (e) ->
      noteValue = @noteTextarea.val() || ''
      if noteValue
        @addNoteButton.button 'loading'
        @noteData = @POLICY.postNote noteValue, @addNoteSuccess, @addNoteError
      return false

    addNoteSuccess : (data, textStatus, jqXHR) ->
      @collection.add @noteData
      @addNoteButton.button 'reset'
      @noteTextarea.val ''

    addNoteError : (jqXHR, textStatus, errorThrown) ->
      console.log errorThrown
      console.log @noteData

    render : ->
      template = @Mustache.render tpl_activities, { activities: @collection.toJSON() }
      @$('.activity-wrapper').html template
      return this

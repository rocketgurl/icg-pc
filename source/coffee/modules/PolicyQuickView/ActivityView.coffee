define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/ActivityCollection'
  'text!modules/PolicyQuickView/templates/tpl_activities.html'
], (collapse, BaseView, ActivityCollection, tpl_activities) ->

  class ActivityView extends BaseView

    events:
      'keyup .activity-search' : 'filterCollection'
      'change .activity-sort'  : 'sortCollection'

    initialize : (options) ->
      activities = options.policyNotes.concat(options.policyEvents)
      @collection = new ActivityCollection(activities, {
        tasks : options.policyTasks
      })

      @viewData = { cid : @cid }
      @collection.on 'reset', @render, this
      @render @collection

    filterCollection : (e) ->
      throttledFilter = _.throttle @collection.filterByQuery, 500
      throttledFilter e.currentTarget.value
      return this

    sortCollection : (e) ->
      @collection.sortBy e.currentTarget.value
      return this

    render : (collection) ->
      template = @Mustache.render tpl_activities, { activities: collection.toJSON() }
      @$('.activity-wrapper').html template
      return this

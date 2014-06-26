define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/ActivityCollection'
  'text!modules/PolicyQuickView/templates/tpl_activities.html'
], (collapse, BaseView, ActivityCollection, tpl_activities) ->

  class ActivityView extends BaseView

    events:
      'keyup .activity-search > input' : 'filterCollection'

    initialize : (options) ->
      activities = options.policyNotes.concat(options.policyEvents)
      @collection = new ActivityCollection(activities, {
        tasks : options.policyTasks
      })

      @viewData = { cid : @cid }
      
      window.ActivityCollection = @collection

      @collection.on 'filter', @render, this
      @render @collection

    filterCollection : (e) ->
      filterByQuery = _.throttle @collection.filterByQuery, 500
      filterByQuery e.currentTarget.value

    render : (collection) ->
      template = @Mustache.render tpl_activities, { activities: collection.toJSON() }
      @$('.activity-wrapper').html template
      return this

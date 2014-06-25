define [
  'collapse'
  'BaseView'
  'modules/PolicyQuickView/ActivityCollection'
  'text!modules/PolicyQuickView/templates/tpl_activity_panel.html'
], (collapse, BaseView, ActivityCollection, tpl_activity_panel) ->

  class ActivityView extends BaseView

    initialize : (options) ->
      activities = options.policyNotes.concat(options.policyEvents)
      @collection = new ActivityCollection activities
      viewData =
        cid : @cid
        activities : @collection.toJSON()
      
      window.ActivityCollection = @collection

      @collection.on 'sort', @render, this
      @render viewData

    render: (viewData) ->
      console.log viewData
      template = @Mustache.render tpl_activity_panel, viewData
      @$el.html template
      this

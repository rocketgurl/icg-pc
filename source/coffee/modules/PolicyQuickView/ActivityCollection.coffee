define [
  'jquery'
  'underscore'
  'backbone'
  'modules/PolicyQuickView/ActivityModel'
], ($, _, Backbone, ActivityModel) ->

  # A mixed, sortable, searchable collection of Notes & Events
  class ActivityCollection extends Backbone.Collection

    model : ActivityModel

    # By default, sort models by timeStamp
    comparator : (model) ->
      model.timeStamp

    initialize : (options) ->

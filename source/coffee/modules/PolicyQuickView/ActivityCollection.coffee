define [
  'backbone'
  'modules/PolicyQuickView/ActivityModel'
], (Backbone, ActivityModel) ->

  # A mixed, sortable, searchable collection of Notes & Events
  class ActivityCollection extends Backbone.Collection

    model : ActivityModel

    # Set the property by which to sort the collection
    sortProp : 'unixOffset'

    # By default, sort descending
    sortAsc  : false

    initialize : (options) ->
      @on 'sort', @report

    report : (data) ->
      console.log data, 'report'
      @each (model) ->
        console.log [
          model.unixOffset
          model.type
          model.get 'activityInitiator'
          model.toJSON()
        ]

    # Bacbone 0.9.2 only triggers a 'reset' event when sorting
    # Which is a bit generic. So, now triggering a 'sort' event
    sort : (options) ->
      super options
      @trigger 'sort', this
      return this

    # Like it says on the tin.
    # options are to be passed to Collection.prototype.sort
    # e.g. @reverseSort { silent: true }
    reverseSort : (options) ->
      @sortAsc = not @sortAsc
      @sort options
      return this

    # Sorts our collection by the given property
    # Sortable properties should be directly on the model,
    # Not in the attributes
    comparator : (modela, modelb) ->
      direction = if @sortAsc then 1 else -1
      a = modela[@sortProp]
      b = modelb[@sortProp]
      if a > b
        1 * direction
      else if a < b
        -1 * direction
      else
        0

    # Super-advanced, tokenized, multi-property search filter
    findMatches : (query) ->
      tokens = query.split ' '
      expr = "(?=.*#{tokens.join(')(?=.*')})"
      regex = new RegExp expr, 'i'
      @filter (item) ->
        return item if regex.test item.get('activityInitiator')
        return item if regex.test item.get('activityDate').date
        return item if regex.test item.get('activityType')


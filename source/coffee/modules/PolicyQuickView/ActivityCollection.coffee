define [
  'backbone'
  'modules/PolicyQuickView/ActivityModel'
], (Backbone, ActivityModel) ->

  # A mixed, sortable, searchable collection of Notes & Events
  class ActivityCollection extends Backbone.Collection

    model : ActivityModel

    initialize : (models, options) ->
      _.bindAll this, 'filterByQuery'

      @tasks = options.tasks
      
      # Default sorting / filtering options
      @options = _.defaults(options, {
        sortProp : 'unixOffset'
        sortAsc  : false
        query : ''
      })

      @on 'filter', @report

    # Utility function for debugging collection results
    report : (data) ->
      console.log data.options, 'report'
      data.each (model) ->
        console.log [
          model.unixOffset
          model.type
          model.get 'activityInitiator'
          model.cid
          model.toJSON()
        ]

    # Bacbone 0.9.2 only triggers a 'reset' event when sorting
    # Which is a bit generic. So, now triggering a 'sort' event
    sort : (options) ->
      super options

    # Like it says on the tin.
    # options are to be passed to Collection.prototype.sort
    # e.g. @reverseSort { silent: true }
    reverseSort : ->
      @options.sortAsc = not @options.sortAsc
      @sort()

    # Sorts our collection by the given property
    # Sortable properties should be directly on the model,
    # Not in the attributes
    comparator : (modela, modelb) ->
      direction = if @options.sortAsc then 1 else -1
      a = modela[@options.sortProp]
      b = modelb[@options.sortProp]
      if a > b
        1 * direction
      else if a < b
        -1 * direction
      else
        0

    # Super-advanced, tokenized, multi-property search filter
    filterByQuery : (query) ->
      if query != @options.query
        @options.query = query
        tokens = query.split /\s+/
        expr = "(?=.*#{tokens.join(')(?=.*')})"
        regex = new RegExp expr, 'i'
        filtered = @filter (item) ->
          return item if regex.test item.get('activityContent').raw
          return item if regex.test item.get('activityInitiator')
          return item if regex.test item.get('activityDate').date
          return item if regex.test item.get('activityType')
        @trigger 'filter', new ActivityCollection(filtered, @options)


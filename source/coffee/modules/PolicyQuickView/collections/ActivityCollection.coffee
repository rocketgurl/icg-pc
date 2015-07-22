define [
  'backbone'
  'modules/PolicyQuickView/models/ActivityModel'
], (Backbone, ActivityModel) ->

  # A mixed, sortable, searchable collection of Notes, Messages & Events
  class ActivityCollection extends Backbone.Collection

    model : ActivityModel

    modelCache : null

    initialized : false

    initialize : (models, options) ->
      _.bindAll this, 'filterByQuery'

      @policyUrl   = options.policyUrl
      @attachments = options.attachments
      @tasks       = options.tasks
      
      # Default sorting / filtering options
      @options = _.defaults(options, {
        sortProp : 'unixTime'
        sortAsc  : false
        query : ''
      })

      # Save the initial set of models for later filtering
      @on 'reset', @cacheModels

    cacheModels : ->
      unless @initialized
        @modelCache = @models
        @initialized = true

    updateModelCache : ->
      @modelCache = @models

    # ** HACK: Short circuit the initial silent sort **
    # We need to hook into the reset event in order to cache 
    # the initial set of models once they're model-ified
    # therefore, force { silent : false }
    sort : (options) ->
      unless @initialized
        options = { silent : false }
      super options

    sortBy : (value) ->
      switch value
        when 'date_desc'
          @options.sortProp = 'unixTime'
          @options.sortAsc = false
        when 'date_asc'
          @options.sortProp = 'unixTime'
          @options.sortAsc = true
        when 'type_desc'
          @options.sortProp = 'type'
          @options.sortAsc = false
        when 'type_asc'
          @options.sortProp = 'type'
          @options.sortAsc = true
        else
          @options.sortProp = 'unixTime'
          @options.sortAsc = false
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
        filtered = _.filter(@modelCache, (item) ->
          return item if regex.test item.get('activityContent').raw
          return item if regex.test item.get('activityInitiator')
          return item if regex.test item.get('activityDate').date
          return item if regex.test item.get('activityType')
          )
        @reset filtered


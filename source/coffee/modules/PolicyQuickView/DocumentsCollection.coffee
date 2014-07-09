define [
  'backbone'
  'modules/PolicyQuickView/DocumentModel'
], (Backbone, DocumentModel) ->

  # A mixed, sortable, searchable collection of Notes, Messages & Events
  class DocumentsCollection extends Backbone.Collection

    model : DocumentModel

    modelCache : null

    initialized : false

    sort : (options) ->
      unless @initialized
        options = { silent : false }
      super options

    comparator : (modela, modelb) ->
      a = modela.unixTime
      b = modelb.unixTime
      if a > b
        -1
      else if a < b
        1
      else
        0

    cacheModels : ->
      unless @initialized
        @modelCache = @models
        @initialized = true

    initialize : (models, options) ->
      @options = options
      @policyUrl = options.policyUrl

      @on 'reset', @cacheModels
      @on 'all', @report
      window.DocumentsCollection = this

    report : (evt) ->
      console.log evt
      @each (model) ->
        console.log [
          model.unixTime
          model.get('docGroup')
          model.get('subtype')
          model.id
        ]

    getGrouped : ->
      _.groupBy @toJSON(), (model) ->
        return model.docGroup


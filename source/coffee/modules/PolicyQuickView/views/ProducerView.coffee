define [
  'BaseView'
  'modules/PolicyQuickView/models/AgencyLocationModel'
  'text!modules/PolicyQuickView/templates/tpl_producer.html'
], (BaseView, AgencyLocationModel, tpl_producer) ->

  class ProducerView extends BaseView

    initialize : (options) ->
      controller = options.controller
      policy = options.policy

      @model = new AgencyLocationModel
        urlRoot : "#{controller.services.ixdirectory}organizations"
        policy  : policy
        auth    : controller.IXVOCAB_AUTH

      @model.on 'sync', @render, this
      @model.on 'error', @renderError, this

    renderError : (model, xhr) ->
      @render 'error', xhr

    render : (arg, xhr) ->
      viewData =
        cid            : @cid
        AgencyLocation : @model.toJSON()
        Error          : if arg is 'error' then xhr else null
      @trigger 'render', @Mustache.render(tpl_producer, viewData)
      this

define [
  'BaseView',
  'text!modules/ReferralQueue/templates/tpl_referral_task_row.html'
], (BaseView, tpl_row) ->

  ReferralTaskView = BaseView.extend

    tagName : 'tr'

    events :
      "click" : "openPolicy"

    initialize : (options) ->
      @PARENT_VIEW = options.parent_view
      @setStatusClass()
      this

    setStatusClass : ->
      status = @model.get 'status'
      if status is 'new'
        @$el.addClass 'status-new'

    render : ->
      html = @Mustache.render tpl_row, @model.toJSON()
      @$el.append html

    openPolicy : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)

      params =
        url : @model.get 'relatedQuoteId'

      @PARENT_VIEW?.MODULE.view.options.controller.launch_module('policyview', params)
      @PARENT_VIEW?.MODULE.view.options.controller.Router.append_module('policyview', params)


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
      @setAssignedTo()
      this

    setAssignedTo : ->
      if @model.get('AssignedTo') is 'Underwriting'
        @$el
          .addClass 'assigned-to-underwriting'
          .attr 'title', 'Assigned to Underwriting'
      else
        @$el.attr 'title', 'Assigned to Agent'

    render : ->
      html = @Mustache.render tpl_row, @model.toJSON()
      @$el.append html

    openPolicy : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)
      id = @model.get('relatedPolicyId') or @model.get('relatedQuoteId')

      params =
        url : @model.get 'relatedQuoteId'
        label : "#{@model.get('insuredLastName')} #{id}"

      @PARENT_VIEW?.MODULE.view.options.controller.launch_module('policyview', params)
      @PARENT_VIEW?.MODULE.view.options.controller.Router.append_module('policyview', params)


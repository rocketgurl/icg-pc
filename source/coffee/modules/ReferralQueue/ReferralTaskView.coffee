define [
  'BaseView',
  'text!modules/ReferralQueue/templates/tpl_referral_task_row.html'
], (BaseView, tpl_row) ->

  ReferralTaskView = BaseView.extend

    tagName   : 'a'

    className : 'tr'

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
      data = @model.toJSON()
      html = @Mustache.render tpl_row, data
      href = "##{@PARENT_VIEW.MODULE.controller.baseRoute}/policy"
      href += "/#{data.relatedQuoteId}"
      @$el.attr('href', href).append html


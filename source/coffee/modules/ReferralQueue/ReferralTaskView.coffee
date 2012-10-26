define [
  'BaseView',
  'text!modules/ReferralQueue/templates/tpl_referral_task_row.html'
], (BaseView, tpl_row) ->

  ReferralTaskView = BaseView.extend

    tagName : 'tr'

    initialize : (options) ->
      @PARENT_VIEW = options.parent_view || {}
      this

    render : ->
      html = @Mustache.render tpl_row, @model.getViewData()
      @$el.append html


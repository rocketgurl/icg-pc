define [
  'BaseView'
], (BaseView) ->

  ReferralTaskView = BaseView.extend

    tagName : 'tr'

    initialize : (options) ->
      @PARENT_VIEW = options.parent_view || {}
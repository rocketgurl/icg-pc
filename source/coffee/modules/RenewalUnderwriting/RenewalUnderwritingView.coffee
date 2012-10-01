define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_renewal_underwriting_container.html'
], (BaseView, Messenger, tpl_ru_container) ->

  RenewalUnderwritingView = BaseView.extend

    events : {}

    initialize : (options) ->
      @$el    = options.$el
      @policy = options.policy

    render : ->
      @$el.html @Mustache.render tpl_ru_container, { cid : @cid }
      @show()

    show : ->
      @$el.fadeIn('fast')

    hide : ->
      @$el.hide()

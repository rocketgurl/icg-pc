define [
  'BaseView',
  'Messenger',
  'text!modules/PolicyRepresentation/templates/tpl_policyrep_container.html'
], (BaseView, Messenger, tpl_policyrep_container) ->

  PolicyRepresentationView = BaseView.extend

    initialize : (options) ->
      for prop in ['$el','policy','policy_view']
        @[prop] = options[prop]
      this

    render : ->
      @$el.html @Mustache.render tpl_policyrep_container, { }
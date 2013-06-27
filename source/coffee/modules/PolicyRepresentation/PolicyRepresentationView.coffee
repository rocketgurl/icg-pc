define [
  'BaseView',
  'Messenger',
  'text!modules/PolicyRepresentation/templates/tpl_policyrep_container.html'
], (BaseView, Messenger, tpl_policyrep_container) ->

  PolicyRepresentationView = BaseView.extend

    initialize : (options) ->
      for prop in ['$el','policy','policy_view','services']
        @[prop] = options[prop]
      this

    render : ->
      view = @getRepresentationLinks()
      @$el.html @Mustache.render tpl_policyrep_container, view

    getRepresentationLinks : ->
      view =
        link_pxcentral   : "#{@services.pxcentral}policies/#{@policy.get_policy_id()}"
        link_ixdirectory : "#{window.location.origin}/#{@services.ixdirectory}organizations/#{@policy.getAgencyLocationId()}?mode=extended"
        link_mxserver    : "#{@services.mxserver}policies/#{@policy.get_policy_id()}?media=application/xml"

      view
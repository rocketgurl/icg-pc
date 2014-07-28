define [
  'BaseView',
  'Messenger',
  'text!modules/PolicyRepresentation/templates/tpl_policyrep_container.html'
], (BaseView, Messenger, tpl_policyrep_container) ->

  PolicyRepresentationView = BaseView.extend

    initialize : (options) ->
      for prop in ['policy','policy_view','services']
        @[prop] = options[prop]
      this

    render : ->
      view = @getRepresentationLinks()
      @$el.html @Mustache.render tpl_policyrep_container, view
      this

    # Assemble HREFs for links. Use different IDs for quotes/policies
    getRepresentationLinks : ->
      id = @policy.getIdentifier 'InsightPolicyId'

      view =
        link_pxcentral   : "#{@services.pxcentral}policies/#{id}"
        link_ixdirectory : "#{window.location.origin}/#{@services.ixdirectory}organizations/#{@policy.getAgencyLocationId()}?mode=extended"
        link_mxserver    : "#{@services.mxserver}policies/#{id}?media=application/xml"
        link_pxserver    : "#{@services.pxserver}/#{@policy.get('pxServerIndex')}"

      view
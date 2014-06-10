define [
  'BaseView'
  'modules/PolicyQuickView/AgencyLocationModel'
  'text!modules/PolicyQuickView/templates/tpl_servicing_tab.html'
], (BaseView, AgencyLocationModel, tpl_servicing_tab) ->

  # PolicyQuickView
  # ====
  # Build container view for PolicyQuickView subviews
  class ServicingTabView extends BaseView

    initialize : (options) ->
      @QuickView = options.quickview
      @CONTROLLER = options.controller
      @POLICY = options.policy

      @agency_location_model = @get_agency_location_model()
      @agency_location_model.on 'change', @render_servicing_tab_data, this

    get_agency_location_model : ->
      new AgencyLocationModel
        urlRoot : "#{@CONTROLLER.services.ixdirectory}organizations"
        id      : @POLICY.getAgencyLocationId()
        auth    : @CONTROLLER.IXVOCAB_AUTH

    render_servicing_tab_data : (agency_location) ->
      data =
        cid    : @cid
        agency : agency_location.toJSON()

      template = @Mustache.render tpl_servicing_tab, data
      @render template

    render : (template) ->
      @$el.html template
      return this

    cache_elements : ->
      cid = @cid

define [
  'BaseView'
  'carousel'
  'modules/Home/views/AgentPortalNoticesView'
  'modules/Home/views/PolicyCentralNoticesView'
  'text!modules/Home/templates/tpl_home_container.html'
], (BaseView, carousel, APNoticesView, PCNoticesView, tpl_home_container) ->

  # Home Module
  # ====
  # Parent view for Home page
  class HomeModule extends BaseView

    initialize : ->
      @CONTROLLER = @options.controller

      @renderContainer()
      homeCarousel = @$('#home-carousel').carousel()

      apUpdatesView = new APNoticesView
        el         : @$('#ap-notices')
        controller : @CONTROLLER

      pcUpdatesView = new PCNoticesView
        el : @$('#pc-notices')

    renderContainer : ->
      viewData =
        cid : @cid
      @$el.html @Mustache.render tpl_home_container, viewData

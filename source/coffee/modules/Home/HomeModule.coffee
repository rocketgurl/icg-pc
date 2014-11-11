define [
  'BaseView'
  'carousel'
  'text!modules/Home/templates/tpl_home_container.html'
], (BaseView, carousel, tpl_home_container) ->

  # Home Module
  # ====
  # Parent view for Home page
  class HomeModule extends BaseView

    initialize : ->
      @CONTROLLER = @options.controller

      @renderContainer()
      @$('#home-carousel').carousel()
      # @cacheElements()

    renderContainer : ->
      viewData =
        cid : @cid
      @$el.html @Mustache.render tpl_home_container, viewData

    cacheElements : ->
      # @renewalBatchesTable = @$("#renewal-batches-#{@cid}")
      # @renewalBatchesTbody = @renewalBatchesTable.find 'tbody'
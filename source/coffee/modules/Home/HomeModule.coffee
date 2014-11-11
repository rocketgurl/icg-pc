define [
  'BaseView'
], (BaseView) ->

  # Home Module
  # ====
  # Parent view for Home page
  class HomeModule extends BaseView

    initialize : ->
      @CONTROLLER = @options.controller
      # @cacheElements()

    cacheElements : ->
      # @renewalBatchesTable = @$("#renewal-batches-#{@cid}")
      # @renewalBatchesTbody = @renewalBatchesTable.find 'tbody'
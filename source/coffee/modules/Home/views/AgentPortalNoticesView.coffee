define [
  'BaseView'
  'modules/Home/collections/AgentPortalNoticesCollection'
], (BaseView, APNoticesCollection) ->

  class AgentPortalNoticesView extends BaseView

    collection : new APNoticesCollection()

    initialize : ->
      @collection.digest = @options.digest
      # @collection.fetch()


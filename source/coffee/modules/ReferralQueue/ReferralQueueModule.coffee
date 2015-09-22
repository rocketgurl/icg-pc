define [
  'modules/ReferralQueue/ReferralQueueView'
  'modules/ReferralQueue/ReferralTaskCollection'
  'loader'
  'Messenger'
  'Helpers'
], (ReferralQueueView, ReferralTaskCollection, CanvasLoader, Messenger, Helpers) ->

  class ReferralQueue

    constructor : (@view, @app, @params) ->
      # Bind events
      _.extend this, Backbone.Events

      @controller = @view.options.controller

      # Setup collection
      @TASKS         = new ReferralTaskCollection()
      @TASKS.baseURL = @controller.services.pxcentral + 'tasks'
      @TASKS.digest  = @controller.user.get 'digest'
      @TASKS.owner   = @TASKS.ownerDefault = @controller.user.get 'username'

      #Setup view
      @QUEUE_VIEW = new ReferralQueueView(
        module     : this
        collection : @TASKS
        view       : @view
        el         : @view.el
      )

    # Remove loader graphic. This will cause the CanvasView to trigger our
    # render() method 
    load : ->
      Helpers.callback_delay 200, =>
        @view.remove_loader(true)

    # Tell the Queue to render itself and the Collection of tasks to hit the
    # server for some XML
    render : ->

      if @controller.services.pxcentral
        if @QUEUE_VIEW.render()
          @TASKS.fetch()
      else
        errorMsg = 'Sorry, the Referral Queue could not be loaded'
        @QUEUE_VIEW.render errorMsg
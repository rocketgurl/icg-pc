define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'modules/ReferralQueue/ReferralQueueView',
  'modules/ReferralQueue/ReferralTaskCollection',
  'loader',
  'Messenger'
], ($, _, Backbone, Mustache, ReferralQueueView, ReferralTaskCollection, CanvasLoader, Messenger) ->

  class ReferralQueue

    constructor : (@view, @app, @params) ->
      # Bind events
      _.extend this, Backbone.Events

      @controller = @view.options.controller

      # Setup collection
      @TASKS        = new ReferralTaskCollection()
      @TASKS.url    = @controller.services.pxcentral + 'tasks'
      @TASKS.digest = @controller.user.get 'digest'
      @TASKS.email  = @controller.user.get 'email'

      #Setup view
      @QUEUE_VIEW = new ReferralQueueView(
        module     : this
        collection : @TASKS
        view       : @view
        owner      : @controller.user.get 'email'
      )

    # Remove loader graphic. This will cause the CanvasView to trigger our
    # render() method 
    load : ->
      @view.remove_loader(true)

    # Tell the Queue to render itself and the Collection of tasks to hit the
    # server for some XML
    render : ->
      if @QUEUE_VIEW.render()
        @TASKS.getReferrals()
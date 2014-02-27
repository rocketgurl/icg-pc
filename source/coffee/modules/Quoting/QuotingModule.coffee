define [
  'jquery',
  'underscore',
  'backbone',
  'mustache',
  'Messenger',
  'loader',
  'modules/Quoting/QuotingView'
  'amplify'
], ($, _, Backbone, Mustache, Messenger, CanvasLoader, QuotingView) ->

  class QuotingModule

    # pubsub interface
    Amplify : amplify

    # **Constructor**
    # @params `POLICY` _Object_ PolicyModel
    # @params `CONTAINER` _HTML Element_ element to render inside of
    # @params `USER` _Object_ UserModel
    # @return _this_
    #
    constructor : (@POLICY, @CONTAINER, @CONTROLLER) ->
      # Current action state
      @ACTION = null
      @USER   = @CONTROLLER.user

        # No Policy, No Container, No Dice!
      if !@POLICY || !@CONTAINER || !@USER
        throw new Error('FATAL - Missing PolicyModel, HTML Container or User.')

      # Fetch config in a deferred and then load the module
      config = $.getJSON('/js/modules/Quoting/config/quoting.json')
                .success((resp) => @load resp)

      # Add Events power
      _.extend @, Backbone.Events

      this

    # TODO:
    # * Remove any loader graphics
    # * Instantiate QuotingView
    load : (@CONFIG) ->
      
      if @CONFIG?
        @VIEW = new QuotingView(
            MODULE : this
          )

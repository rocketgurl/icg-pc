define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'Messenger',
  'loader',
  'modules/IPM/IPMView'
  'amplify'
], ($, _, Backbone, Mustache, Messenger, CanvasLoader, IPMView) ->

  class IPMModule

    # pubsub interface
    Amplify : amplify

    # **Constructor**  
    # @params `POLICY` _Object_ PolicyModel  
    # @params `CONTAINER` _HTML Element_ element to render inside of   
    # @params `USER` _Object_ UserModel  
    # @return _this_  
    #
    constructor : (@POLICY, @CONTAINER, @USER) ->
      # Current action state
      @ACTION = null

        # No Policy, No Container, No Dice!
      if !@POLICY || !@CONTAINER || !@USER
        throw new Error('FATAL - Missing PolicyModel, HTML Container or User.')

      # Fetch config in a deferred and then load the module
      config = $.getJSON('/js/modules/IPM/config/ipm.json')
                .success((resp) => @load resp)

      # Add Events power
      _.extend @, Backbone.Events

      this

    # TODO:  
    # * Remove any loader graphics
    # * Instantiate IPMView  
    load : (@CONFIG) ->
      if @CONFIG?
        @VIEW = new IPMView(
            MODULE : this
          )

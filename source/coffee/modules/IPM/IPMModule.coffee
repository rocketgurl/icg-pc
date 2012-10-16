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

    # Current action state
    ACTION : null

    # **Constructor**  
    # @params `POLICY` _Object_ PolicyModel  
    # @params `CONTAINER` _HTML Element_ element to render inside of   
    # @return _this_  
    constructor : (@POLICY, @CONTAINER) ->
      # No Policy, No Container, No Dice!
      if !@POLICY || !@CONTAINER
        throw new Error('FATAL - Missing PolicyModel or HTML Container.')

      # Fetch config in a deferred and then load the module
      config = $.getJSON('/js/modules/IPM/config/ipm.json')
                .pipe (resp) ->
                  return resp

      $.when(config).done((resp) => @load(resp))

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
            DEBUG  : true
          )

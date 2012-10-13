define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'Messenger',
  'loader'
], ($, _, Backbone, Mustache, Messenger, CanvasLoader) ->

  class IPMModule

    # pubsub interface
    Amplify : amplify

    
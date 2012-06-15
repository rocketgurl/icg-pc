define [
  'jquery', 
  'underscore',
  'backbone'
], ($, _, Backbone) ->

  originalSync = Backbone.sync

  XMLSync = (method, model, options) ->
    options = _.extend options,
    	dataType    : 'xml'
    	contentType : 'application/xml'
    	processData : false
    originalSync.apply(Backbone, [ method, model, options ])
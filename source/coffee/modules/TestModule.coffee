define [
  'jquery', 
  'underscore',
  'backbone',
  'mustache',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Mustache, amplify) ->

  TestModule = 

    init : (el) ->
      @el = el
      @render()

    render : () ->
      @el.html('TEST MODULE BE RENDERED!')
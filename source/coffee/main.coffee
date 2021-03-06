requirejs.config { waitSeconds: 0 }

require
  urlArgs: ''
  baseUrl: 'js'
  paths:
    jquery          : 'lib/jquery-1.8.2'
    jqueryui        : 'lib/jquery-ui-1.9.0.custom.min'
    underscore      : 'lib/underscore-1.4.4'
    backbone        : 'lib/backbone-0.9.2'
    amplify         : 'lib/amplify'
    mustache        : 'lib/requirejs.mustache'
    base64          : 'lib/base64'
    moment          : 'lib/moment'
    momentrange     : 'lib/moment-range'
    xml2json        : 'lib/jquery.xml2json'
    text            : 'lib/text'
    domReady        : 'lib/domReady'
    json            : 'lib/json2'
    loader          : 'lib/heartcode-canvasloader'
    swfobject       : 'lib/swfobject'
    u_string        : 'lib/underscore.string'
    u_policycentral : 'underscore.policycentral'
    herald          : 'lib/herald/herald'
    marked          : 'lib/marked'
    chosen          : 'lib/chosen.jquery'
    Apparatchik     : 'lib/Apparatchik'
    favicon         : 'lib/favicon'
    transition      : 'lib/bootstrap/transition'
    tab             : 'lib/bootstrap/tab'
    collapse        : 'lib/bootstrap/collapse'
    button          : 'lib/bootstrap/button'
    tooltip         : 'lib/bootstrap/tooltip'
    popover         : 'lib/bootstrap/popover'
    dropdown        : 'lib/bootstrap/dropdown'
    modal           : 'lib/bootstrap/modal'
    carousel        : 'lib/bootstrap/carousel'
  priority: ['jquery', 'xml2json', 'json']
  shim:
      'jquery' :
        deps    : ['require']
        exports : '$'
      'xml2json' :
        deps : ['jquery']
      'json' :
        deps    : ['jquery']
        exports : 'JSON'
      'underscore' :
        exports : '_'
      'backbone' :
        deps    : ['jquery', 'json', 'underscore']
        exports : 'Backbone'
      'amplify' :
        deps    : ['jquery', 'json']
        exports : 'amplify'
      'loader' :
        deps    : ['jquery']
        exports : 'CanvasLoader'
      'swfobject' :
        deps    : ['require']
        exports : 'swfobject'
      'u_string' :
        deps : ['underscore']
      'momentrange' :
        deps : ['moment']
      'chosen' :
        deps : ['jquery']
        exports : 'Chosen'
      'Apparatchik' :
        deps : ['jquery', 'underscore', 'moment']
      'favicon' :
        exports : 'favicon'
      'transition' :
        deps: ['jquery']
      'tab' :
        deps: ['jquery']
      'collapse' :
        deps: ['transition']
      'tooltip' :
        deps: ['jquery']
      'popover' :
        deps: ['tooltip']
      'dropdown' :
        deps: ['jquery']
      'modal' :
        deps: ['jquery']
      'carousel' :
        deps: ['transition']

require [
  'jquery'
  'underscore'
  'backbone'
  'WorkspaceController'
  'u_string'
  'u_policycentral'
  'domReady'
  'xml2json'
  'chosen'
  'dropdown'
  'modal'
  'tooltip'
], ($, _, Backbone, WorkspaceController, u_string, u_policycentral, domReady) ->

  (->
    unless window.trackJs
      return false

    _.each(["View", "Model", "Collection", "Router"], (className) ->
      Klass = Backbone[className]
      Backbone[className] = Klass.extend({
        constructor: ->
          # NOTE: This allows you to set _trackJs = false for any individual object
          # that you want excluded from tracking
          if typeof this._trackJs is "undefined"
            this._trackJs = true

          if this._trackJs
            # Additional parameters are excluded from watching. Constructors and Comparators
            # have a lot of edge-cases that are difficult to wrap so we'll ignore them.
            window.trackJs.watchAll(this, "model", "constructor", "comparator")

          return Klass.prototype.constructor.apply(this, arguments)
      })
    )
    return true
  )


  # Setup underscore.string
  _.mixin _.str.exports()

    # Bring in Underscore Policy Central extensions
  _.mixin u_policycentral


  # Initialize application when dom is ready
  domReady ->
    if $.fn.xml2json == undefined
      require ["xml2json"], (xml2json) ->
        console.log xml2json


    # Oh yes we did! Attached WorkspaceController to the window,
    # because it makes debugging a helluva lot easier.
    window.workspace = WorkspaceController
    window.workspace.init()

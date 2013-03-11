define [
  'jquery', 
  'underscore',
  'backbone',
  'Store',
  'amplify',
  'LocalStorageSync',
  'CrippledClientSync',
  'JSONAuthSync',
  'Helpers',
  'xmlSync'
], ($, _, Backbone, Store, amplify, LocalStorageSync, CrippledClientSync, JSONAuthSync, Helpers, XMLSync) ->

  #### BaseModel
  #
  # All models for PC 2.0 should inherit from BaseModel. This provides sync
  # adapters for localStorage and XML handling, in addition to standard
  # Backbone JSON handling. 
  # 
  class BaseModel extends Backbone.Model

    # make Helpers functions available to all models
    Helpers : Helpers

    # store a ref to Backbone's sync so we can use it again
    backboneSync  : Backbone.sync

    # Traditional Backbone JSON sync + Basic Auth
    backboneAuthSync : JSONAuthSync

    # store a ref to Backbone's parse so we can use it again
    backboneParse : Backbone.Model.prototype.parse

    # Deal with Crippled Clients
    crippledClientSync  : CrippledClientSync

    # Setup XML parsing using CrippledClient
    xmlSync  : XMLSync
    xmlParse : (response, xhr) ->
      if response?
        tree = response
        if _.has(response, 'xml')
          xmlstr = response.xml
        else
          xmlstr = (new XMLSerializer()).serializeToString(response)

      tree = $.parseXML(xmlstr)
      out  = { 'xhr' : xhr }

      if tree?
        out.document   = $(tree)
        out.raw_xml    = xhr.responseText
        out.json       = $.fn.xml2json(out.raw_xml)
      out

    # Response state (Hackety hack hack)
    # 
    # Since we're on **Crippled Client**, all requests come back as
    # 200's and we have to do header parsing to ascertain what 
    # is actually going on. We stash the jqXHR in the model and
    # do some checking to see what the error code really is, then
    # stash that in the model as 'fetch_state'
    #
    response_state : () ->
      xhr = @get 'xhr'
      fetch_state =
        text : xhr.getResponseHeader 'X-True-Statustext'
        code : xhr.getResponseHeader 'X-True-Statuscode'

      # This might be a CORS request in which case we can't
      # get our X-True-Statustext so we need to wing it.
      # This could still cause us some problems down the road.
      if not fetch_state.code?
        if xhr.readyState is 4 and xhr.status is 200
          fetch_state.code = "200"

      @set 'fetch_state', fetch_state
      this

    # Explicitly set sync for this model to Backbone default
    sync : @backboneSync

    # Switch models sync to another adapter
    switch_sync : (sync_adapater) ->
      @sync = @[sync_adapater]

    # Tell model to fetch & parse XML data
    use_xml : () ->
      @sync  = @xmlSync
      @parse = @xmlParse

    # Tell model to fetch & parse XML data from Crippled Clients
    use_cripple : () ->
      @sync  = @crippledClientSync
      @parse = @xmlParse

    # Tell model to use localStorage
    use_localStorage : (storage_key, expire) ->

      options = if expire? then { expires : expire } else null

      # Setup localStorage DB in browswer
      @localStorage = new Store(storage_key, options)
      @localSync    = LocalStorageSync

      @sync  = @localSync
      @parse = @backboneParse

    # Switch back to traditional JSON handling
    use_backbone : () ->
      @sync  = @backboneSync
      @parse = @backboneParse

    # Switch back to traditional JSON handling + Basic Auth
    use_backbone_auth : () ->
      @sync  = @backboneAuthSync
      @parse = @backboneParse

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    # Send Flash messages to UI
    flash : (type, msg) ->
      @Amplify.publish 'flash', type, msg

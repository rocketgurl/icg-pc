define [
  'jquery', 
  'underscore',
  'backbone',
  'Store',
  'LocalStorageSync',
  'CrippledClientSync',
  'xmlSync',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Store, LocalStorageSync, CrippledClientSync, XMLSync, amplify) ->

  #### BaseModel
  #
  # All models for PC 2.0 should inherit from BaseModel. This provides sync
  # adapters for localStorage and XML handling, in addition to standard
  # Backbone JSON handling. 
  # 
  BaseModel = Backbone.Model.extend

    # store a ref to Backbone's sync so we can use it again
    backboneSync  : Backbone.sync

    # store a ref to Backbone's parse so we can use it again
    backboneParse : Backbone.Model.prototype.parse

    # Setup localStorage DB in browswer
    localStorage : new Store 'ics_policy_central'
    localSync    : LocalStorageSync

    # Setup XML parsing using CrippledClient
    xmlSync  : CrippledClientSync
    xmlParse : (response) ->
      tree = new XML.ObjTree().parseDOM(response)
      { document : tree['#document'] }

    # Explicitly set sync for this model to Backbone default
    sync : @backboneSync

    # Switch models sync to another adapter
    switch_sync : (sync_adapater) ->
      @sync = @[sync_adapater]

    # Tell model to fetch & parse XML data
    use_xml : () ->
      @sync  = @xmlSync
      @parse = @xmlParse

    # Tell model to use localStorage
    use_localStorage : () ->
      @sync  = @localSync
      @parse = @backboneParse

    # Switch back to traditional JSON handling
    use_backbone : () ->
      @sync  = @backboneSync
      @parse = @backboneParse

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

define [
  'jquery', 
  'underscore',
  'backbone',
  'Store',
  'LocalStorageSync',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, Store, LocalStorageSync, amplify) ->

  #### BaseModel
  #
  # All models for PC 2.0 should inherit from BaseModel. This provides sync
  # adapters for localStorage and XML handling, in addition to standard
  # Backbone JSON handling. 
  # 
  BaseModel = Backbone.Model.extend

    # Explicitly set sync for this model to Backbone default
    sync : Backbone.sync

    # Setup localStorage DB in browswer
    localStorage : new Store 'ics_policy_central'
    localSync    : LocalStorageSync

    # Switch models sync to another adapter
    switch_sync : (sync_adapater) ->
      @sync = @[sync_adapater]

    # hook into Amplify.js on all models
    Amplify : amplify

    # Simple logger pubsub
    logger : (msg) ->
      @Amplify.publish 'log', msg

    initialize : () ->
       # @logger @sync
       # @switch_sync 'localSync'
       # @logger @sync

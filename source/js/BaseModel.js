// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'Store', 'LocalStorageSync', 'xmlSync', 'amplify_core', 'amplify_store'], function($, _, Backbone, Store, LocalStorageSync, XMLSync, amplify) {
    var BaseModel;
    return BaseModel = Backbone.Model.extend({
      backboneSync: Backbone.sync,
      backboneParse: Backbone.Model.prototype.parse,
      localStorage: new Store('ics_policy_central'),
      localSync: LocalStorageSync,
      xmlSync: XMLSync,
      xmlParse: function(response) {
        var tree;
        tree = new XML.ObjTree().parseDOM(response);
        return {
          document: tree['#document']
        };
      },
      sync: this.backboneSync,
      switch_sync: function(sync_adapater) {
        return this.sync = this[sync_adapater];
      },
      use_xml: function() {
        this.sync = this.xmlSync;
        return this.parse = this.xmlParse;
      },
      use_localStorage: function() {
        this.sync = this.localSync;
        return this.parse = this.backboneParse;
      },
      use_backbone: function() {
        this.sync = this.backboneSync;
        return this.parse = this.backboneParse;
      },
      Amplify: amplify,
      logger: function(msg) {
        return this.Amplify.publish('log', msg);
      },
      initialize: function() {}
    });
  });

}).call(this);

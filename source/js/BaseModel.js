// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'backbone', 'Store', 'amplify', 'LocalStorageSync', 'CrippledClientSync', 'xmlSync', 'Helpers'], function($, _, Backbone, Store, amplify, LocalStorageSync, CrippledClientSync, XMLSync, Helpers) {
    var BaseModel;
    return BaseModel = Backbone.Model.extend({
      Helpers: Helpers,
      backboneSync: Backbone.sync,
      backboneParse: Backbone.Model.prototype.parse,
      crippledClientSync: CrippledClientSync,
      xmlSync: XMLSync,
      xmlParse: function(response, xhr) {
        var out, tree, xmlstr;
        if (response != null) {
          tree = response;
        }
        xmlstr = response.xml ? response.xml : (new XMLSerializer()).serializeToString(response);
        tree = $.parseXML(xmlstr);
        out = {
          'xhr': xhr
        };
        if (tree != null) {
          out.document = $(tree);
          out.raw_xml = xhr.responseText;
          out.string_xml = xmlstr;
        }
        return out;
      },
      response_state: function() {
        var fetch_state, xhr;
        xhr = this.get('xhr');
        fetch_state = {
          text: xhr.getResponseHeader('X-True-Statustext'),
          code: xhr.getResponseHeader('X-True-Statuscode')
        };
        if (!(fetch_state.code != null)) {
          if (xhr.readyState === 4 && xhr.status === 200) {
            fetch_state.code = "200";
          }
        }
        this.set('fetch_state', fetch_state);
        return this;
      },
      sync: this.backboneSync,
      switch_sync: function(sync_adapater) {
        return this.sync = this[sync_adapater];
      },
      use_xml: function() {
        this.sync = this.xmlSync;
        return this.parse = this.xmlParse;
      },
      use_cripple: function() {
        this.sync = this.crippledClientSync;
        return this.parse = this.xmlParse;
      },
      use_localStorage: function(storage_key) {
        this.localStorage = new Store(storage_key);
        this.localSync = LocalStorageSync;
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
      flash: function(type, msg) {
        return this.Amplify.publish('flash', type, msg);
      }
    });
  });

}).call(this);

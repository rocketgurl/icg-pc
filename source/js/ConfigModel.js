// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel', 'base64'], function(BaseModel, Base64) {
    var ConfigModel;
    ConfigModel = BaseModel.extend({
      initialize: function() {
        this.use_xml();
        return this.urlRoot = this.get('urlRoot');
      }
    });
    return ConfigModel;
  });

}).call(this);
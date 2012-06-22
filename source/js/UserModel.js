// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel', 'base64'], function(BaseModel, Base64) {
    var UserModel;
    UserModel = BaseModel.extend({
      initialize: function() {
        this.use_cripple();
        this.urlRoot = this.get('urlRoot');
        if (this.get('username')) {
          this.id = this.get('username');
        }
        if (this.get('username') && this.get('password')) {
          this.set({
            'digest': Base64.encode("" + (this.get('username')) + ":" + (this.get('password')))
          });
          return delete this.attributes.password;
        }
      },
      parse_identity: function() {
        var doc,
          _this = this;
        doc = this.get('document');
        if (doc != null) {
          return _.each(['Name', 'Email', '-passwordHash'], function(key) {
            var name;
            if (doc.Identity[key] != null) {
              name = key.toLowerCase().replace(/-/, '');
              return _this.set(name, doc.Identity[key]);
            }
          });
        }
      }
    });
    return UserModel;
  });

}).call(this);

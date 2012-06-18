// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel', 'base64'], function(BaseModel, Base64) {
    var UserModel;
    UserModel = BaseModel.extend({
      initialize: function() {
        this.use_xml();
        if (this.get('username')) {
          this.id = this.get('username');
        }
        if (this.get('username') && this.get('password')) {
          this.set({
            'digest': Base64.encode("" + (this.get('username')) + ":" + (this.get('password')))
          });
          return delete this.attributes.password;
        }
      }
    });
    return UserModel;
  });

}).call(this);

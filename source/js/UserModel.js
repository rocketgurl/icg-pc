// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel'], function(BaseModel) {
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
            'digest': this.Helpers.createDigest(this.get('username'), this.get('password'))
          });
          return delete this.attributes.password;
        }
      },
      parse_identity: function() {
        var doc;
        doc = this.get('document');
        if (doc != null) {
          this.set('passwordHash', doc.find('Identity').attr('passwordHash'));
          this.set('name', doc.find('Identity Name').text());
          return this.set('email', doc.find('Identity Email').text());
        }
      }
    });
    return UserModel;
  });

}).call(this);

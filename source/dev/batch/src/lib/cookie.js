import _ from 'underscore';

function Cookie() {}

Cookie.prototype.pluses = /\+/g;

Cookie.prototype.defaults = {};

Cookie.prototype.cookie = null;

Cookie.prototype.raw = function(s) {
  return s;
};

Cookie.prototype.decoded = function(s) {
  return decodeURIComponent(s.replace(this.pluses, ' '));
};

Cookie.prototype.set = function(key, value, options) {
  var days, t;
  if ((value != null) && (options != null)) {
    options = _.extend({}, this.defaults, options);
    if (value == null) {
      options.expires = -1;
    }
    if (typeof options.expires === 'number') {
      days = options.expires;
      t = options.expires = new Date();
      t.setDate(t.getDate() + days);
    }
    value = String(value);
    return (document.cookie = [encodeURIComponent(key), '=', options.raw ? value : encodeURIComponent(value), options.expires ? "; expires=" + (options.expires.toUTCString()) : '', options.path ? "; path=" + options.path : '', options.domain ? "; domain=" + options.domain : '', options.secure ? "; secure" : ''].join(''));
  }
};

Cookie.prototype.get = function(key) {
  var cookie, cookies, parts, _i, _len;
  cookies = document.cookie.split('; ');
  for (_i = 0, _len = cookies.length; _i < _len; _i++) {
    cookie = cookies[_i];
    if (parts = cookie.split('=')) {
      if (parts.shift() === key) {
        return this.decoded(parts.join('='));
      }
    }
  }
  return null;
};

Cookie.prototype.remove = function(key) {
  if (key != null) {
    return document.cookie = "" + (encodeURIComponent(key)) + "=; expires=Thu, 01 Jan 1970 00:00:01 GMT;";
  }
  return false;
};

export default Cookie;
      
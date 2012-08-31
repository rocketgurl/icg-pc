// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'base64', 'loader'], function($, _, Base64, CanvasLoader) {
    var Helpers,
      _this = this;
    Helpers = {
      id_safe: function(string) {
        var out, reg;
        if (!(string != null)) {
          return null;
        }
        reg = new RegExp('/\s*\W/gi');
        out = string.replace(/\s*\W/gi, '_');
        if (out === 'undefined' || out === void 0) {
          return null;
        }
        return out;
      },
      uc_first: function(string) {
        return string.substr(0, 1).toUpperCase() + string.substr(1);
      },
      unserialize: function(string) {
        var k, out, params, v, value, _i, _len, _ref;
        out = {};
        params = string.split('/');
        for (_i = 0, _len = params.length; _i < _len; _i++) {
          value = params[_i];
          _ref = value.split(':'), k = _ref[0], v = _ref[1];
          if ((k != null) && (v != null)) {
            out[k] = decodeURI(v);
          }
        }
        return out;
      },
      serialize: function(object) {
        var key, serialized, value;
        serialized = '';
        for (key in object) {
          value = object[key];
          serialized += "/" + key + ":" + (encodeURI(value));
        }
        return serialized;
      },
      loader: function(id, diameter, color) {
        var cl;
        cl = new window.CanvasLoader(id);
        cl.setColor(color);
        cl.setShape('oval');
        cl.setDiameter(diameter);
        cl.setDensity(60);
        cl.setFPS(24);
        cl.show();
        return cl;
      },
      callback_delay: function(ms, func) {
        return setTimeout(func, ms);
      },
      random: function(min, max) {
        return Math.floor(Math.random() * (max - min + 1)) + min;
      }
    };
    return Helpers;
  });

}).call(this);

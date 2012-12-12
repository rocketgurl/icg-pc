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
      },
      createDigest: function(username, password) {
        return Base64.encode("" + username + ":" + password);
      },
      XMLToString: function(oXML) {
        if (window.ActiveXObject) {
          return oXML.xml;
        } else {
          return (new XMLSerializer()).serializeToString(oXML);
        }
      },
      XMLFromString: function(sXML) {
        var oXML;
        if (window.ActiveXObject) {
          oXML = new ActiveXObject("Microsoft.XMLDOM");
          oXML.loadXML(sXML);
          return oXML;
        } else {
          return (new DOMParser()).parseFromString(sXML, "text/xml");
        }
      },
      stripTimeFromDate: function(date, format) {
        var clean, t;
        format = format != null ? format : null;
        clean = date;
        t = date.indexOf('T');
        if (t > -1) {
          clean = clean.substring(0, t);
        }
        return this.formatDate(clean, format);
      },
      formatDate: function(date, format) {
        format = format || 'YYYY-MM-DD';
        return moment(date).format(format);
      },
      makeTimestamp: function() {
        return moment(new Date()).format('YYYY-MM-DDTHH:mm:ss.sssZ');
      },
      resize_element: function(el, offset) {
        var el_height;
        offset = offset || 0;
        el_height = Math.floor((($(window).height() - (184 + offset)) / $(window).height()) * 100) + "%";
        return el.css({
          'min-height': el_height,
          'height': $(window).height() - (184 + offset)
        });
      },
      properName: function(name) {
        name = this.parseNamePrefix(name.toLowerCase());
        name = this.parseNameSuffix(name);
        return name;
      },
      parseNamePrefix: function(name) {
        var prefixes, result;
        prefixes = ['mac', 'mc', 'van', "d'", "o'"];
        result = _.find(prefixes, function(prefix) {
          var re;
          re = RegExp(prefix, "i");
          return re.test(name);
        });
        if (result !== void 0) {
          name = name.split(result);
          name[0] = result;
          name = _.map(name, function(fragment) {
            return _.titleize(fragment);
          });
          name = name.join('');
        } else {
          name = _.titleize(name);
        }
        return name;
      },
      parseNameSuffix: function(name) {
        var re, result, suffixes;
        suffixes = ['jr', 'snr', 'phd', 'esq', 'cpa'];
        result = _.find(suffixes, function(suffix) {
          var re;
          re = RegExp(suffix, "i");
          return re.test(name);
        });
        if (result !== void 0) {
          re = RegExp(result, "i");
          name = name.replace(re, _.titleize(result));
        }
        return name;
      },
      concatStrings: function(a, b, separator) {
        var out;
        separator = separator != null ? separator : ', ';
        out = " ";
        if (a) {
          out = _.trim("" + a);
        }
        if (b) {
          out = _.trim("" + out + separator + b);
        }
        return out;
      }
    };
    return Helpers;
  });

}).call(this);

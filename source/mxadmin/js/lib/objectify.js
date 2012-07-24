(function() {
  var DEFAULTS, T, _a, escapeXML, isArray, merge, objectify;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty;
  /*
  XML Objectify  -- XML to JSON, JSON to XML but really opinionated

  Most of the ideas here are stolen from Yusuke Kawasaki's XML.ObjTree but this
  is a from-scratch implementation.

  This is a CoffeeScript module. If you're reading the JS, it'll be ugly.
  */
  DEFAULTS = {
    forceArray: null,
    forceContentAttr: null,
    attributePrefix: '$',
    contentAttrName: '$'
  };
  T = {
    ELEMENT: 1,
    ATTRIBUTE: 2,
    TEXT: 3,
    CDATA: 4,
    REFERENCE: 5,
    ENTITY: 6,
    PI: 7,
    COMMENT: 8,
    DOCUMENT: 9,
    DOCTYPE: 10,
    FRAGMENT: 11,
    NOTATION: 12
  };
  isArray = Array.isArray || function(obj) {
    var _a, _b, _c;
    return !!(obj && (typeof (_a = obj.concat) !== "undefined" && _a !== null) && (typeof (_b = obj.unshift) !== "undefined" && _b !== null) && !(typeof (_c = obj.callee) !== "undefined" && _c !== null));
  };
  merge = function(target) {
    var _a, _b, _c, _d, _e, k, sources, src, v;
    sources = __slice.call(arguments, 1);
    target || (target = {});
    _b = sources;
    for (_a = 0, _c = _b.length; _a < _c; _a++) {
      src = _b[_a];
      _d = src;
      for (k in _d) {
        if (!__hasProp.call(_d, k)) continue;
        v = _d[k];
        if (!(typeof (_e = target[k]) !== "undefined" && _e !== null)) {
          target[k] = v;
        }
      }
    }
    return target;
  };
  escapeXML = function(str) {
    return str.replace(/&|<|"/g, function(chr) {
      if (chr === '&') {
        return '&amp;';
      } else if (chr === '<') {
        return '&lt;';
      } else if (chr === '"') {
        return '&quot;';
      }
    });
  };
  objectify = function(opts) {
    var _a, fun, key, ret;
    ret = {};
    ret.settings = merge(opts, DEFAULTS);
    _a = objectify;
    for (key in _a) {
      if (!__hasProp.call(_a, key)) continue;
      fun = _a[key];
      if (typeof fun === 'function') {
        ret[key] = fun.bind(ret);
      }
    }
    return ret;
  };
  objectify.settings = merge({}, DEFAULTS);
  objectify.fromXML = function(source) {
    return typeof source === 'string' ? this._fromString(source) : this._fromDom(source);
  };
  objectify._fromString = function(source) {
    var parsed, parser;
    if (typeof DOMParser !== "undefined" && DOMParser !== null) {
      parser = new DOMParser();
      parsed = parser.parseFromString(source, 'application/xml');
      return this._fromDom((typeof parsed === "undefined" || parsed === null) ? undefined : parsed.documentElement);
    } else if (typeof ActiveXObject !== "undefined" && ActiveXObject !== null) {
      parser = new ActiveXObject('Microsoft.XMLDOM');
      parser.async = false;
      parser.loadXML(source);
      return this._fromDom(parser.documentElement);
    }
  };
  objectify._fromDom = function(source) {
    var toRet;
    toRet = this._element(source);
    if (((typeof source === "undefined" || source === null) ? undefined : source.nodeName) && source.nodeType === T.ELEMENT) {
      toRet.__rootName = source.nodeName;
    }
    return toRet;
  };
  objectify._element = function(node) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _i, attrPre, attribute, child, contentName, inline, key, name, thisNode, value;
    if ((_a = node.nodeType) === T.DOCUMENT) {
      name = node.firstChild == null ? undefined : node.firstChild.nodeName;
      if (name && name[0] !== '#') {
        thisNode = {};
        thisNode[name] = this._element(node.firstChild);
        return thisNode;
      } else {
        return this._element(node.firstChild);
      }
    } else if (_a === T.ELEMENT) {
      thisNode = {};
      attrPre = this.settings.attributePrefix;
      contentName = this.settings.contentAttrName;
      _c = node.attributes;
      for (_b = 0, _d = _c.length; _b < _d; _b++) {
        attribute = _c[_b];
        name = attribute.nodeName;
        thisNode[attrPre + name] = node.getAttribute(name);
      }
      _f = node.childNodes;
      for (_e = 0, _g = _f.length; _e < _g; _e++) {
        child = _f[_e];
        name = child.nodeName;
        if (name === '#text') {
          name = contentName;
        }
        value = this._element(child);
        if (value) {
          if (thisNode[name]) {
            if (!(typeof (_h = thisNode[name].push) !== "undefined" && _h !== null)) {
              thisNode[name] = [thisNode[name]];
            }
            thisNode[name].push(value);
          } else {
            thisNode[name] = this.settings.forceArray ? [value] : value;
          }
        }
      }
      inline = true;
      _i = thisNode;
      for (key in _i) {
        if (!__hasProp.call(_i, key)) continue;
        value = _i[key];
        if (key !== contentName) {
          inline = false;
          break;
        }
      }
      if (inline && !this.settings.forceContentAttr) {
        return thisNode[contentName] || null;
      } else {
        return thisNode;
      }
    } else if (_a === T.TEXT) {
      if (node.nodeValue.length > 0 && node.nodeValue.match(/\S/)) {
        return node.nodeValue;
      }
    }
    return null;
  };
  objectify.toXML = function(obj, rootName) {
    return this._elementToXML(rootName || obj.__rootName || null, obj).join('');
  };
  objectify._elementToXML = function(name, obj) {
    var _a, _b, _c, _d, _e, _f, _g, attrs, contentName, contents, do_attrs, item, key, res, toRet, val, value;
    if (!(typeof obj !== "undefined" && obj !== null)) {
      return [];
    }
    if (isArray(obj)) {
      return Array.prototype.concat.apply([], (function() {
        _a = []; _c = obj;
        for (_b = 0, _d = _c.length; _b < _d; _b++) {
          item = _c[_b];
          _a.push(this._elementToXML(name, item));
        }
        return _a;
      }).call(this));
    } else if (typeof obj === 'object') {
      contents = [];
      attrs = {};
      contentName = this.settings.contentAttrName;
      _e = obj;
      for (key in _e) {
        if (!__hasProp.call(_e, key)) continue;
        val = _e[key];
        if (key === contentName) {
          contents.push(val);
        } else if (key.substr(0,2) === '__') {
          continue;
        } else if (key[0] === this.settings.attributePrefix) {
          do_attrs = true;
          attrs[key.substr(1)] = escapeXML(val);
        } else {
          res = this._elementToXML(key, val);
          if (isArray(res)) {
            contents = contents.concat(res);
          } else {
            contents.push(res);
          }
        }
      }
    } else {
      contents = [escapeXML(obj)];
    }
    if (name === null) {
      return contents;
    }
    toRet = [("<" + (name))];
    if (do_attrs) {
      toRet.push(' ' + (function() {
        _f = []; _g = attrs;
        for (key in _g) {
          if (!__hasProp.call(_g, key)) continue;
          value = _g[key];
          _f.push("" + (key) + "=\"" + (value) + "\"");
        }
        return _f;
      })().join(' '));
    }
    if ((typeof contents === "undefined" || contents === null) ? undefined : contents.length) {
      toRet.push('>');
      toRet = toRet.concat(contents);
      toRet.push("</" + (name) + ">");
    } else {
      toRet.push('/>');
    }
    return toRet;
  };
  if (typeof (_a = (typeof module === "undefined" || module === null) ? undefined : module.exports) !== "undefined" && _a !== null) {
    module.exports = objectify;
  } else {
    window.objectify = objectify;
  }
})();

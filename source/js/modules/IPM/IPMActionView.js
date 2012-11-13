// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['BaseView', 'Messenger', 'modules/IPM/IPMChangeSet'], function(BaseView, Messenger, IPMChangeSet) {
    var IPMActionView;
    return IPMActionView = (function(_super) {

      __extends(IPMActionView, _super);

      function IPMActionView() {
        this.callbackError = __bind(this.callbackError, this);

        this.callbackSuccess = __bind(this.callbackSuccess, this);
        return IPMActionView.__super__.constructor.apply(this, arguments);
      }

      IPMActionView.prototype.MODULE = {};

      IPMActionView.prototype.VALUES = {};

      IPMActionView.prototype.TPL_CACHE = {};

      IPMActionView.prototype.CHANGE_SET = {};

      IPMActionView.prototype.tagName = 'div';

      IPMActionView.prototype.events = {
        "click form input.button": "submit",
        "click .form_actions a": "goHome",
        "click fieldset h3": "toggleFieldset"
      };

      IPMActionView.prototype.initialize = function(options) {
        this.PARENT_VIEW = options.PARENT_VIEW || {};
        this.MODULE = options.MODULE || {};
        this.CHANGE_SET = new IPMChangeSet(this.MODULE.POLICY, this.PARENT_VIEW.VIEW_STATE, this.MODULE.USER);
        this.options = null;
        return this.on('ready', this.ready, this);
      };

      IPMActionView.prototype.fetchTemplates = function(policy, action, callback) {
        var model, path, view;
        if (!(policy != null) || !(action != null)) {
          return false;
        }
        path = "/js/" + this.MODULE.CONFIG.PRODUCTS_PATH + (policy.get('productName')) + "/forms/" + (_.slugify(action));
        if (!_.has(this.TPL_CACHE, action)) {
          model = $.getJSON("" + path + "/model.json").pipe(function(resp) {
            return resp;
          });
          view = $.get("" + path + "/view.html", null, null, "text").pipe(function(resp) {
            return resp;
          });
          return $.when(model, view).then(callback, this.PARENT_VIEW.actionError);
        } else {
          return callback(this.TPL_CACHE[action].model, this.TPL_CACHE[action].view);
        }
      };

      IPMActionView.prototype.goHome = function(e) {
        e.preventDefault();
        return this.PARENT_VIEW.route('Home');
      };

      IPMActionView.prototype.toggleFieldset = function(e) {
        var a, a_html, container, h3;
        e.preventDefault();
        h3 = $(e.currentTarget);
        a = h3.find('a');
        container = h3.parent().find('.collapsibleFieldContainer');
        if (container.css('display') === 'none') {
          container.css('display', 'block');
        } else {
          container.css('display', 'none');
        }
        a_html = a.html();
        return a.html(a.data('altText')).data('altText', a_html);
      };

      IPMActionView.prototype.postProcessView = function() {
        var date_options;
        $('.labelRequired').append('<em>*</em>');
        $('select[data-value]').val(function() {
          return $(this).attr('data-value');
        });
        date_options = {
          dateFormat: 'yy-mm-dd'
        };
        if ($.datepicker) {
          return $('.datepicker').datepicker(date_options);
        }
      };

      IPMActionView.prototype.postProcessPreview = function() {
        return delete this.viewData.preview;
      };

      IPMActionView.prototype.getFormValues = function(form) {
        var formValues, item, _i, _len, _ref;
        formValues = {};
        _ref = form.serializeArray();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          formValues[item.name] = item.value;
        }
        return formValues;
      };

      IPMActionView.prototype.getChangedValues = function(form) {
        var changed;
        changed = [];
        form.find(':input').each(function(i, element) {
          var el, name, val;
          el = $(element);
          val = el.val();
          name = el.attr('name');
          if (el.is('select')) {
            if (el.data('value') != val) {
              return changed.push(name);
            }
          } else if (el.is('textarea')) {
            if (val.trim() !== '') {
              changed.push(name);
            }
            if (val.trim() === '' && el.data('hadValue')) {
              return changed.push(name);
            }
          } else {
            if (val !== element.getAttribute('value')) {
              return changed.push(name);
            }
          }
        });
        return changed;
      };

      IPMActionView.prototype.processViewData = function(vocabTerms, view) {
        return this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE] = {
          model: vocabTerms,
          view: view
        };
      };

      IPMActionView.prototype.callbackSuccess = function(data, status, jqXHR) {
        return console.log(jqXHR);
      };

      IPMActionView.prototype.callbackError = function(jqXHR, status, error) {
        return console.log(jqXHR);
      };

      IPMActionView.prototype.callbackPreview = function(data, status, jqXHR) {
        var prev_document;
        prev_document = this.MODULE.POLICY.get('document');
        this.MODULE.POLICY.attributes = this.MODULE.POLICY.parse(data, jqXHR);
        if (this.MODULE.POLICY.set('prev_document', prev_document)) {
          this.MODULE.POLICY.setModelState();
        }
        return this.processPreview(this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE].model, this.TPL_CACHE[this.PARENT_VIEW.VIEW_STATE].view);
      };

      IPMActionView.prototype.ready = function() {};

      IPMActionView.prototype.render = function() {};

      IPMActionView.prototype.validate = function() {};

      IPMActionView.prototype.preview = function() {};

      IPMActionView.prototype.submit = function(e) {
        var form;
        e.preventDefault();
        form = this.$el.find('form');
        return this.VALUES = {
          formValues: this.getFormValues(form),
          changedValues: this.getChangedValues(form)
        };
      };

      return IPMActionView;

    })(BaseView);
  });

}).call(this);

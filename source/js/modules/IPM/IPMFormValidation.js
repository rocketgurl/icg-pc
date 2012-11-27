// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'mustache', 'Helpers', 'moment', 'momentrange'], function($, _, Backbone, Mustache, Helpers, moment) {
    var IPMFormValidation;
    return IPMFormValidation = (function() {

      function IPMFormValidation(validators) {
        var _this = this;
        this.validators = validators;
        this.validateField = _.wrap(this.validateField, function(func) {
          var args;
          args = _.toArray(arguments);
          if (func(args[1])) {
            _this.showErrorState(args[1]);
            return true;
          } else {
            _this.removeErrorState(args[1]);
            return false;
          }
        });
        _.each(['showErrorState', 'removeErrorState'], function(f) {
          return _this[f] = _.wrap(_this[f], function(func) {
            var args;
            args = _.toArray(arguments);
            if (!(args[1] instanceof jQuery)) {
              args[1] = $(args[1]);
            }
            return func(args[1], _this);
          });
        });
      }

      IPMFormValidation.prototype.validateFields = function(arr) {
        var _this = this;
        return _.filter(arr, function(el) {
          return _this.validateField(el);
        });
      };

      IPMFormValidation.prototype.validateField = function(el) {
        var el_name;
        if (!(el instanceof jQuery)) {
          el = $(el);
        }
        if (el.val() === '' || el.val() === void 0) {
          return true;
        }
        el_name = el.attr('name');
        if ((this.validators != null) && _.has(this.validators, el_name)) {
          return this[this.validators[el_name]](el);
        } else {
          return false;
        }
      };

      IPMFormValidation.prototype.showErrorState = function(el, scope) {
        var _this = this;
        scope = scope != null ? scope : this;
        el.addClass('validation_error').on('change', function(el) {
          return scope.validateField($(el.currentTarget));
        }).parent().find('label').addClass('validation_error');
        return el;
      };

      IPMFormValidation.prototype.removeErrorState = function(el) {
        if (el.hasClass('validation_error')) {
          el.removeClass('validation_error').parent().find('label').removeClass('validation_error');
        }
        return el;
      };

      IPMFormValidation.prototype.displayErrorMsg = function(errors) {
        var details;
        details = _.map(errors, function(err) {
          var $label;
          $label = $(err).parent().find('label');
          $label.find('i').remove();
          return "<li>" + ($label.html()) + "</li>";
        });
        return "Please complete the required fields below\n<div class=\"error_details\">\n  <ul>\n    " + (details.join('')) + "\n  </ul>\n</div>";
      };

      IPMFormValidation.prototype.dateRange = function(el) {
        var end, range, start, whence;
        start = moment(el.data('minDate')).subtract('days', 1);
        end = moment(el.data('maxDate')).add('days', 1);
        whence = moment(el.val());
        range = moment().range(start, end);
        return whence.within(range);
      };

      IPMFormValidation.prototype.money = function(el) {
        return parseFloat(el.val()) > 0;
      };

      IPMFormValidation.prototype.number = function(el) {
        var max, min, val;
        val = parseInt(el.val(), 10);
        min = el.attr('min') ? parseInt(el.attr('min'), 10) : null;
        max = el.attr('max') ? parseInt(el.attr('max'), 10) : null;
        if (min && val < min) {
          false;
        }
        if (max && val > max) {
          false;
        }
        return true;
      };

      return IPMFormValidation;

    })();
  });

}).call(this);

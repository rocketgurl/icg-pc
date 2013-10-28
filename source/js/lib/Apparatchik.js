/* global $, _, moment */

/**
   Apparatchik
   ===========

   Grab bag of functions to handle dynamic behaviors witin IPM forms,
   like a little bureaucrat in a little cubicle.

   How to use:
   ----------

   Define some rules:

   var rules = [{
      field : 'HeatPump',
      condition : '> 100',
      target : 'CentralAir',
      effect : apparatchik.showElement
    },
    {
      field : 'ConstructionType',
      condition : '== 100',
      target : 'Cladding',
      effect : apparatchik.showElement
    },
    {
      field : 'WindstormDeductibleOption',
      sideEffects : [
        {
          target : 'HurricaneDeductible',
          condition : '== 100',
          effect : apparatchik.showElement
        },
        {
          target : 'WindHailDeductible',
          condition : '== 200',
          effect : apparatchik.showElement
        }
      ]
    }];

    Then pass them to Apparatchik: 

    if (apparatchik.isProduct('fsic-dp3-la') && apparatchik.isAction('Endorse')) {
      apparatchik.applyEnumDynamics(rules);
    }

    Notice that WindstormDeductibleOption has multiple side-effects
    which you can define in an array.

    Rules work like so:

    field     : the form field you want to listen to (onChange)
    condition : what condition it should meet (ex: < 100)
    target    : which field to modify if condition is met
    effect    : the function that handles effects

 */

var Apparatchik = (function(){
  /**
   * Constructor
   *
   * @param {Object} guid    IPM View prefix
   * @param {Object} policy  Policy
   * @param {Object} view    IPMView
   * @param {Object} form    jQuery(form)
   */
  function Apparatchik(guid, policy, view, form) {
    this.guid            = guid;
    this.policy          = policy;
    this.view            = view;
    this.$form           = form;
    this.form_properties = this.inspectForm();
  }

  /**
   * Assemble information about form
   *
   * @param {Object} jQuery(form)
   * @return {Object}
   */
  Apparatchik.prototype.inspectForm = function(form) {
    return {
      action  : this.view.view_state,
      product : this.policy.getProductName(),
      id      : this.policy.id
    };
  };

  /**
   * Predicate: match form action
   * @param {String} action
   * @return {Boolean}
   */
  Apparatchik.prototype.isAction = function(action) {
    return (action === this.form_properties.action);
  };

  /**
   * Predicate: match form product
   * @param {String} product
   * @return {Boolean}
   */
  Apparatchik.prototype.isProduct = function(product) {
    var prod = (!_.isArray(product)) ? [product] : product;
    return _.contains(prod, this.form_properties.product);
  };

  /**
   * Predicate: evaluate val in condition
   * @param {String} val
   * @param {String} condition
   * @return {Boolean}
   */
  Apparatchik.prototype.isCondition = function(val, condition) {
    var value = (_.isEmpty(val)) ? '0' : val,
        cond = (_.isNull(condition)) ? '== 0' : condition;
    return (eval(value + cond));
  };

  /**
   * We need jQuery wrapped & guid_ prefixed elements
   *
   * @param {String} field   name of field
   * @return {String}
   */
  Apparatchik.prototype.wrapField = function(field) { return $('#' + this.guid + '_' + field); };

  /**
   * Set initial state and attach listeners to fields
   *
   * @param {Object} rules
   * @return {void}
   */
  Apparatchik.prototype.applyEnumDynamics = function(rules) {
    var _this = this;
    _.each(rules, function(rule) {
      if (_.has(rule, 'sideEffects')) {
        _this.setMultipleListener(rule);
      } else {
        _this.setTargetState(rule.target, rule.effect);
        _this.setDynamicListener(rule);
      }
    });
  };

  /**
   * Set element to its initial state by passing true for reset
   *
   * @param {Object} target   jQuery wrapped el
   * @param {String} effect   jQuery function signature
   * @return {void}
   */
  Apparatchik.prototype.setTargetState = function(target, effect) {
    if (_.isUndefined(target)) { return false; }
    if (_.isFunction(effect)) { return effect.call(this, target, true); }
  };

  /**
   * Check field for initial condition and then attach
   * a listener so we can trigger effects on the target
   *
   * @param {String} rule
   * @return {void}
   */
  Apparatchik.prototype.setDynamicListener = function(rule) {
    var target = this.wrapField(rule.target).parent(),
        args   = (_.has(rule, 'args')) ? rule.args : '',
        _this  = this,
        field  = this.wrapField(rule.field);

    // Add a listener to 'change' which checks the condition
    field.on('change', function() {
      if (_this.isCondition($(this).val(), rule.condition)) {
        if (_.isFunction(rule.effect)) { return rule.effect.call(_this, rule.target, false, args); }
      } else {
        _this.setTargetState(rule.target, rule.effect);
      }
    });

    // If the value of the field already meets the condition
    // then go ahead and trigger its effect
    if (this.isCondition(field.val(), rule.condition)) {
      if (_.isFunction(rule.effect)) { return rule.effect.call(_this, rule.target, false, args); }  
    }
  };

  /**
   * Deal with a rule containing multiple side effects
   *
   * These are fields which affect multiple target fields
   * depending on what their condition evals to - so basically
   * a single enum will toggle on/off different fields
   *
   * {
   *   field : 'WindstormDeductibleOption',
   *   sideEffects : [
   *     {
   *       target    : 'HurricaneDeductible',
   *       condition : '== 100',
   *       effect    : Apparatchik.showElement
   *     },
   *     {
   *       target    : 'WindHailDeductible',
   *       condition : '== 200',
   *       effect    : Apparatchik.showElement
   *     }
   *   ]
   * }
   *
   * @param {Object} rule
   * @return {void}
   */
  Apparatchik.prototype.setMultipleListener = function(rule) {
    var _this = this,
        field = this.wrapField(rule.field);

    // Set target fields to default state
    this.resetSideEffects(rule.sideEffects);

    // Listen to change and then trigger target fields
    // that pass conditional
    field.on('change', function() {
      var val = $(this).val();
      var effect = _this.filterSideEffects(rule.sideEffects, val);
      if (effect.length > 0) {
        _this.resetSideEffects(rule.sideEffects); // reset
        _this.triggerSideEffects(effect); // trigger
      } else {
        _this.resetSideEffects(rule.sideEffects); // reset
      }
    });
    field.trigger('change');
  };

  /**
   * Set all side effect fields to default state
   *
   * @param {Array} side_effects
   * @return {void}
   */
  Apparatchik.prototype.resetSideEffects = function(side_effects) {
    var _this = this;
    _.each(side_effects, function(rule) {
      _this.setTargetState(rule.target, rule.effect);
    });
  };

  /**
   * Return array with only side effect rules that passed condition
   *
   * @param {Array} side_effects
   * @param {String} val
   * @return {void}
   */
  Apparatchik.prototype.filterSideEffects = function(side_effects, val) {
    var _this = this;
    return _.filter(side_effects, function(rule) {
      return (_this.isCondition(val, rule.condition));
    });
  };

  /**
   * Loop through array and trigger all effects
   *
   * @param {Array} side_effects
   * @param {String} val
   * @return {void}
   */
  Apparatchik.prototype.triggerSideEffects = function(side_effects, val) {
    var _this = this;
    _.each(side_effects, function(rule) {
      var args = (_.has(rule, 'args')) ? rule.args : '';
      if (_.isFunction(rule.effect)) { rule.effect.call(_this, rule.target, false, args); }
    });
  };

  /**
   * ================================================================
   * @@ Effect Functions @@
   *
   * All effect functions should take the same three params:
   *
   * target (HTMLElement)
   * reset (Boolean)
   * args (Object|Array|String)
   *
   * reset === true means to set the element to its default state
   *
   * ================================================================
   */
  
  /**
   * Effect: Show/hide element
   *
   * @param {HTMLElement}  target  
   * @param {Boolean}      reset
   * @param {Object}       args   any args passed to func
   * @return {Object}      jQuery wrapped element
   */
  Apparatchik.prototype.showElement = function(target, reset, args) {
    var $el = this.wrapField(target).parent();
    if (reset) { return $el.hide(args); }
    return $el.show(args);
  };

  // Return the module
  return Apparatchik;

})();

var root = typeof exports !== "undefined" && exports !== null ? exports : this;

if (typeof module === 'object' && module && typeof module.exports === 'object') {
  module.exports = Apparatchik;
} else if (typeof exports === 'object' && exports) {
  exports.Apparatchik = Apparatchik;
} else if (typeof define === 'function' && define.amd) {
  define('Apparatchik', [], function() {
    return Apparatchik;
  });
} else {
  root.Apparatchik = Apparatchik;
}

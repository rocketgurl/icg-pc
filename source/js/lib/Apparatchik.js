/* global $, _, moment, exports, module, define */

/**
   Apparatchik
   ===========

   Grab bag of functions to handle dynamic behaviors witin IPM forms,
   like a little bureaucrat in a little cubicle.


                 !#########       #
               !########!          ##!
            !########!               ###
         !##########                  ####
       ######### #####                ######
        !###!      !####!              ######
          !           #####            ######!
                        !####!         #######
                           #####       #######
                             !####!   #######!
                                ####!########
             ##                   ##########
           ,######!          !#############
         ,#### ########################!####!
       ,####'     ##################!'    #####
     ,####'            #######              !####!
    ####'                                      #####
    ~##                                          ##~

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
      field : 'DisposalType',
      condition : '== 200',
      target : ['VikingFunerals', 'FuneralPyres', 'ScienceDonation'],
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
    target    : which field(s) to modify if condition is met
    effect    : the function that handles effects

    If you want a condition to modify multiple targets place the id's
    of the target in an array: ['foo', 'bar']

    You can also pack multiple functions into effect, also because
    these are functions, you can drop your own closure in there
    taking the standard arguments for an effect to handle custom
    one-off jobbies.

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
    var value = (_.isEmpty(val) || _.isUndefined(val)) ? '0' : val,
        cond = (_.isNull(condition)) ? '== 0' : condition;
    if (condition === 'onchange') return true;
    if (_.isString(condition)) { return (eval(value + cond)); }
    if (_.isObject(condition)) {
      return this.compileConditions(value, condition);
    }
    return false;
  };

  /**
   * Take a named operator of conditions (and|or) and make the
   * comparison to value - this is very shallow, only one level deep
   *
   * @param {Number} value
   * @param {Object} conditions
   * @return {Boolean}
   */
  Apparatchik.prototype.compileConditions = function(val, conditions) {
    var _this = this,
        op = _.first(_.keys(conditions)),
        funcs = {
          and : _this.compileAnd,
          or : _this.compileOr
        };
    return (eval(funcs[op](val, conditions[op])));
  };

  /**
   * Build a string with val and array of conditions to pass to
   * eval() up in compileConditions. This is used to build
   * compileAnd & compileOr using _.partial()
   *
   * @param {String} operator
   * @param {Number} value
   * @param {Array} conditions
   * @return {String}
   */
  Apparatchik.prototype.compileOperator = function(operator, val, conditions) {
    var op = " " + operator + " ";
    return "(" + _.map(conditions, function(c){ return val + c; }).join(op) + ")";
  };

  // Use partial application to define specific string compilers
  Apparatchik.prototype.compileAnd = _.partial(Apparatchik.prototype.compileOperator, '&&');
  Apparatchik.prototype.compileOr = _.partial(Apparatchik.prototype.compileOperator, '||');

  /**
   * We need jQuery wrapped & guid_ prefixed elements
   *
   * @param {String} field   name of field
   * @return {String}
   */
  Apparatchik.prototype.wrapField = function(field) { return $('#' + this.guid + '_' + field); };

  /**
   * Ensure input is an array
   *
   * @param {*} i
   * @return {Array}
   */
  Apparatchik.prototype.wrapArray = function(i) { return (!_.isArray(i)) ? [i] : i; };

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
    if (_.isUndefined(target) || _.isUndefined(effect)) { return false; }
    var _this = this,
        _target = this.wrapArray(target),
        _effect = this.wrapArray(effect);
    return _.each(_target, function(t) {
      _this.callEffects(_effect, _this, target, true);
    });
  };

  /**
   * Check field for initial condition and then attach
   * a listener so we can trigger effects on the target
   *
   * @param {String} rule
   * @return {void}
   */
  Apparatchik.prototype.setDynamicListener = function(rule) {
    var _this   = this,
        _target = this.wrapArray(rule.target),
        _effect = this.wrapArray(rule.effect),
        args    = (_.has(rule, 'args')) ? rule.args : '',
        field   = this.wrapField(rule.field);

    // Add a listener to 'change' which checks the condition
    field.on('change', function() {
      if (_this.isCondition($(this).val(), rule.condition)) {
        if (!_.isEmpty(_effect)) {
          _.each(_target, function(t) {
            _this.callEffects(_effect, _this, t, false, args);
          });
        }
      } else {
        _.each(_target, function(t) {
          _this.setTargetState(t, rule.effect);
        });
      }
    });

    // If the value of the field already meets the condition
    // then go ahead and trigger its effect
    // UNLESS the condition is 'onchange'
    if (rule.condition !== 'onchange') {
      if (this.isCondition(field.val(), rule.condition)) {
        if (!_.isUndefined(rule.effect)) {
          _.each(_target, function(t) {
            _this.callEffects(_effect, _this, t, false, args);
          });
        }
      }
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
   *       target    : ['WindHailDeductible', 'HailMaryDeductible'],
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
      var _t = _this.wrapArray(rule.target);
      _.each(_t, function(t) {
        _this.setTargetState(t, rule.effect);
      });
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

      if (!_.isUndefined(rule.effect)) {
        var _target = _this.wrapArray(rule.target),
            _effect = _this.wrapArray(rule.effect),
            args    = (_.has(rule, 'args')) ? rule.args : '';

        _.each(_target, function(t) {
          _this.callEffects(_effect, _this, t, false, args);
        });
      }
    });
  };

  /**
   * Map over array of effect functions
   *
   * @param {Array} effects
   * @param {Object} scope
   * @param {String} target
   * @param {Boolean} reset
   * @param {Mixed} args
   * @return {Array} return values of functions
   */
  Apparatchik.prototype.callEffects = function(effects,
                                        scope,
                                        target,
                                        reset,
                                        args) {
    return _.map(effects, function(e) {
      return e.call(scope, target, reset, args);
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
    var _target = this.wrapArray(target),
        _this = this;
    _.each(_target, function(t){
      var $el = _this.wrapField(t).parent();
      if (reset) { return $el.hide(args); }
      $el.show(args);
    });
  };

  /**
   * Effect: Set form element and label to required state
   *
   * @param {HTMLElement}  target
   * @param {Boolean}      reset
   * @param {Object}       args   any args passed to func
   * @return {Object}      jQuery wrapped element
   */
  Apparatchik.prototype.makeRequired = function(target, reset, args) {
    var $el = this.wrapField(target),
        $label = $el.siblings('label');

    if (reset) {
      $label.removeClass('labelRequired');
      return $el.prop('required', false);
    }

    $label.addClass('labelRequired');
    return $el.prop('required', true);
  };

  /**
   * Effect: disable form element
   *
   * @param {HTMLElement}  target
   * @param {Boolean}      reset
   * @param {Object}       args   any args passed to func
   * @return {Object}      jQuery wrapped element
   */
  Apparatchik.prototype.makeReadOnly = function(target, reset, args) {
    var $el = this.wrapField(target);
    if (reset) { $el.prop('disabled', false); }
    return $el.prop('disabled', true);
  };

  /**
   * Effect: clear element value
   *
   * @param {HTMLElement}  target
   * @param {Boolean}      reset
   * @param {Object}       args   any args passed to func
   * @return {Object}      jQuery wrapped element
   */
  Apparatchik.prototype.clearValue = function(target, reset, args) {
    var $el = this.wrapField(target);
    if (reset) return $el;
    return $el.val('');
  };

  /**
   * Effect: force form element to be NOT disabled
   *
   * @param {HTMLElement}  target
   * @param {Boolean}      reset
   * @param {Object}       args   any args passed to func
   * @return {Object}      jQuery wrapped element
   */
  Apparatchik.prototype.makeWritable = function(target, reset, args) {
    return this.wrapField(target).prop('disabled', false);
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

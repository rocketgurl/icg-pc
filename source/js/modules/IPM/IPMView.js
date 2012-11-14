// Generated by CoffeeScript 1.3.3
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['BaseView', 'Messenger'], function(BaseView, Messenger) {
    var IPMView, dlogger;
    dlogger = function(methodBody) {
      return function() {
        if (this.DEBUG !== false && (this.DEBUG != null)) {
          console.log("DEBUG IPMView ->");
          console.log([this, this.options, arguments]);
        }
        return methodBody.apply(this, arguments);
      };
    };
    return IPMView = (function(_super) {

      __extends(IPMView, _super);

      function IPMView() {
        this.actionError = __bind(this.actionError, this);
        return IPMView.__super__.constructor.apply(this, arguments);
      }

      IPMView.prototype.initialize = function(options) {
        this.VIEW_STATE = '';
        this.VIEW_CACHE = {};
        this.FLASH_HTML = '';
        this.LOADER = {};
        this.DEBUG = options.DEBUG != null;
        this.MODULE = options.MODULE || false;
        this.FLASH_HTML = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        this.$el = this.MODULE.CONTAINER;
        this.buildHtmlElements();
        if (_.isEmpty(this.VIEW_STATE || this.VIEW_STATE === 'Home')) {
          return this.route('Home');
        }
      };

      IPMView.prototype.buildHtmlElements = function() {
        this.$el.html(this.FLASH_HTML);
        this.$el.find("#flash-message-" + this.cid).addClass('ipm-flash');
        this.$el.append("<div id=\"ipm-loader-" + this.cid + "\" class=\"ipm-loader\">\n  <h2 id=\"ipm-spinner-" + this.cid + "\"><span>Loading action&hellip;</span></h2>\n</div>");
        return this.$el.append("<div id=\"ipm-container-" + this.cid + "\" class=\"ipm-container\"></div>");
      };

      IPMView.prototype.route = function(action) {
        var _this = this;
        this.VIEW_STATE = action;
        this.insert_loader();
        if (!_.has(this.VIEW_CACHE, action)) {
          require(["" + this.MODULE.CONFIG.ACTIONS_PATH + action], function(Action) {
            var ActionView;
            _this.VIEW_CACHE[action] = $("<div id=\"dom-container-" + _this.cid + "-" + action + "\" class=\"dom-container\"></div>");
            ActionView = new Action({
              MODULE: _this.MODULE,
              PARENT_VIEW: _this
            });
            _this.hideOpenViews();
            ActionView.on("loaded", _this.render, _this);
            return ActionView.trigger("ready");
          }, function(err) {
            var failedId;
            failedId = err.requireModules && err.requireModules[0];
            _this.Amplify.publish(_this.cid, 'warning', "We could not load " + failedId + ". Sorry.");
            return _this.route('Home');
          });
        } else {
          this.remove_loader();
          this.hideOpenViews(function() {
            return _this.VIEW_CACHE[action].fadeIn('fast');
          });
        }
        return this;
      };

      IPMView.prototype.hideOpenViews = function(callback) {
        var action, view, _ref, _results;
        _ref = this.VIEW_CACHE;
        _results = [];
        for (action in _ref) {
          view = _ref[action];
          if (view.css('display') === 'block') {
            _results.push(view.fadeOut('fast', function() {
              if (callback != null) {
                return callback();
              }
            }));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      };

      IPMView.prototype.render = dlogger(function(action_view, callback) {
        var container,
          _this = this;
        this.remove_loader();
        container = this.$el.find("#ipm-container-" + this.cid);
        container.fadeOut('fast', function() {
          var func;
          action_view.setElement(_this.VIEW_CACHE[_this.VIEW_STATE]).render();
          container.append(_this.VIEW_CACHE[_this.VIEW_STATE]).fadeIn('fast');
          if (callback) {
            func = _.bind(callback, action_view);
            return func();
          }
        });
        return this.messenger = new Messenger(this, this.cid);
      });

      IPMView.prototype.insert_loader = function() {
        this.$el.find("#ipm-loader-" + this.cid).show();
        try {
          this.LOADER = this.Helpers.loader("ipm-spinner-" + this.cid, 100, '#ffffff');
          this.LOADER.setDensity(70);
          return this.LOADER.setFPS(48);
        } catch (e) {
          return this.$el.find("#ipm-loader-" + this.cid).hide();
        }
      };

      IPMView.prototype.remove_loader = function() {
        try {
          if ((this.LOADER != null) && this.LOADER !== void 0) {
            this.LOADER.kill();
            this.LOADER = null;
            return this.$el.find("#ipm-loader-" + this.cid).hide();
          }
        } catch (e) {
          this.$el.find("#canvasLoader").remove();
          return console.log([e, this.$el.find("#ipm-spinner-" + this.cid).html()]);
        }
      };

      IPMView.prototype.actionError = function(jqXHR) {
        var error_msg, name;
        name = this.VIEW_STATE || "";
        error_msg = "Could not load view/model for " + (this.MODULE.POLICY.get('productName')) + " " + name + " : " + jqXHR.status;
        this.Amplify.publish(this.cid, 'warning', "" + error_msg);
        return this.remove_loader();
      };

      IPMView.prototype.displayMessage = function(type, msg, delay) {
        return this.Amplify.publish(this.cid, type, msg, delay);
      };

      return IPMView;

    })(BaseView);
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore'], function($, _) {
    var Messenger;
    return Messenger = (function() {

      function Messenger(view, id) {
        this.view = view;
        this.id = id;
        if (this.view.$el != null) {
          this.flash_container = this.view.$el.find("#flash-message-" + this.id);
        } else {
          this.flash_container = this.view.find("#flash-message-" + this.id);
        }
        this.register(this.id);
      }

      Messenger.prototype.register = function(id) {
        var _this = this;
        amplify.subscribe(id, function(type, msg, delay) {
          if (type != null) {
            _this.flash_container.addClass(type);
          }
          if (msg != null) {
            msg = "<i class=\"icon-remove-sign\"></i> " + msg;
            _this.flash_container.html(msg).fadeIn('fast');
            if (delay != null) {
              return _.delay(function() {
                return _this.flash_container.html(msg).fadeOut('slow');
              }, delay);
            }
          }
        });
        this.flash_container.on('click', 'i', function(e) {
          e.preventDefault();
          return _this.flash_container.fadeOut('fast');
        });
        return this.flash_container.on('click', '.error_details a', function(e) {
          e.preventDefault();
          $(_this).next().toggle();
          return $(_this).toggle(function() {
            return $(this).html('<i class="icon-plus-sign"></i> Hide error details');
          }, function() {
            return $(this).html('<i class="icon-plus-sign"></i> Show error details');
          });
        });
      };

      return Messenger;

    })();
  });

}).call(this);

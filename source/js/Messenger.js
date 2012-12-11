// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore'], function($, _) {
    var Messenger;
    return Messenger = (function() {

      Messenger.prototype.animation_options = {
        "default": {
          start: {
            top: "+=115"
          },
          end: {
            top: "-=115"
          }
        },
        nomove: {
          start: false,
          end: false
        }
      };

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
        return amplify.subscribe(id, function(type, msg, delay, animation) {
          if (animation != null) {
            animation = _this.animation_options[animation];
          } else {
            animation = _this.animation_options["default"];
          }
          if (type != null) {
            _this.flash_container.addClass(type);
          }
          if (msg != null) {
            msg = "<span><i class=\"icon-remove-sign\"></i>" + msg + "</span>";
            _this.flash_container.parent().show();
            _this.flash_container.html(msg).show().animate({
              opacity: 1
            }, 500);
            _this.flash_container.parent().animate(animation.start, 500);
            if (delay != null) {
              _.delay(function() {
                _this.flash_container.html(msg).animate({
                  opacity: 0
                }, 500);
                return _this.flash_container.parent().animate(animation.end, 500, function() {
                  return $(this).hide();
                });
              }, delay);
            }
          }
          _this.flash_container.on('click', function(e) {
            e.preventDefault();
            _this.flash_container.animate({
              opacity: 0
            }, 300);
            return _this.flash_container.parent().animate(animation.end, 300, function() {
              return $(this).hide();
            });
          });
          return _this.flash_container.on('click', '.error_details a', function(e) {
            e.preventDefault();
            $(_this).next().toggle();
            return $(_this).toggle(function() {
              return $(this).html('<i class="icon-plus-sign"></i> Hide error details');
            }, function() {
              return $(this).html('<i class="icon-plus-sign"></i> Show error details');
            });
          });
        });
      };

      return Messenger;

    })();
  });

}).call(this);

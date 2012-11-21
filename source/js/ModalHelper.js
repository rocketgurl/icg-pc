// Generated by CoffeeScript 1.3.3
(function() {

  define(['jquery', 'underscore', 'mustache'], function($, _, Mustache) {
    var ModalHelper;
    return ModalHelper = (function() {

      function ModalHelper() {
        this.Mustache = Mustache;
      }

      ModalHelper.prototype.attach_menu = function(el, className, template, view_data) {
        var container, menu;
        this.el = el;
        this.className = className;
        this.template = template;
        container = this.el.parent();
        menu = container.find(this.className);
        if (menu.length === 0) {
          menu = this.Mustache.render(template, view_data);
          container.append(menu).find('div').fadeIn(200);
        } else {
          menu.fadeIn('fast');
        }
        this.overlay_trigger(container.find(className));
        return menu;
      };

      ModalHelper.prototype.clear_menu = function(e) {
        if (e.currentTarget != null) {
          $(e.currentTarget).parents(this.className).fadeOut(100);
        } else {
          e.fadeOut('fast');
        }
        return $('.modal-overlay').remove();
      };

      ModalHelper.prototype.overlay_trigger = function(menu) {
        var overlay,
          _this = this;
        overlay = $("<div></div>").addClass('modal-overlay').css({
          width: '100%',
          height: '100%',
          position: 'absolute',
          zIndex: 640,
          background: 'transparent'
        });
        $('body').prepend(overlay);
        return $(overlay).on('click', function(e) {
          return _this.clear_menu(menu);
        });
      };

      return ModalHelper;

    })();
  });

}).call(this);

// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView'], function(BaseView) {
    var WorkspaceNavView;
    return WorkspaceNavView = BaseView.extend({
      events: {
        "click li a": "toggle_main_nav",
        "click #workspace-subnav li a": "toggle_sub_nav"
      },
      initialize: function(options) {
        var _this = this;
        this.$sub_el = $(options.sub_el);
        this.$header = this.options.controller.$workspace_header;
        this.base_height = this.$header.height();
        this.$sub_el.hide();
        this.$el.hide();
        return $('#header-controls').on('click', '#button-workspace', function(e) {
          e.preventDefault();
          return _this.toggle_nav_slide();
        });
      },
      render: function() {
        this.$el.prepend(this.options.main_nav);
        this.$sub_el.html(this.options.sub_nav);
        return this.$sub_el.css({
          'min-height': this.$el.height()
        });
      },
      destroy: function() {
        this.$el.html();
        return this.$sub_el.html();
      },
      toggle_main_nav: function(e) {
        var $a, $li;
        e.preventDefault();
        $a = $(e.target).parent();
        $li = $a.parent();
        $li.addClass('open');
        $li.siblings().removeClass('open');
        this.$sub_el.find("#" + ($a.data('pc'))).removeClass();
        return this.$sub_el.find("#" + ($a.data('pc'))).siblings().addClass('sub_nav_off');
      },
      toggle_sub_nav: function(e) {
        var $a, $li;
        e.preventDefault();
        $a = $(e.target);
        $li = $a.parent();
        this.$sub_el.find('a').removeClass();
        $a.addClass('on');
        return this.options.router.navigate($a.attr('href'), {
          trigger: true
        });
      },
      toggle_nav_slide: function() {
        if (this.$header.height() === this.base_height + 30) {
          return this.$header.animate({
            height: 330 + this.base_height
          }, 200, 'swing', this.show_nav());
        } else {
          this.hide_nav();
          return this.$header.animate({
            height: this.base_height + 30
          }, 200, 'swing');
        }
      },
      show_nav: function() {
        this.$el.fadeIn('slow');
        return this.$sub_el.fadeIn('slow');
      },
      hide_nav: function() {
        this.$el.hide();
        return this.$sub_el.hide();
      }
    });
  });

}).call(this);

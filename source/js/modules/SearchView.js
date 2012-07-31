// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseView', 'Messenger', 'modules/SearchPolicyCollection', 'text!templates/tpl_search_container.html'], function(BaseView, Messenger, SearchPolicyCollection, tpl_search_container) {
    var SearchView;
    return SearchView = BaseView.extend({
      menu_cache: {},
      events: {
        "submit .filters form": "search",
        "click #search-control-context a": function(e) {
          return this.control_context(this.process_event(e));
        },
        "click #search-control-save a": function(e) {
          return this.control_save(this.process_event(e));
        },
        "click #search-control-share a": function(e) {
          return this.control_share(this.process_event(e));
        },
        "click #search-control-pin": function(e) {
          return this.control_pin(this.process_event(e));
        },
        "click .icon-remove-circle": function(e) {
          this.clear_menus();
          return this.controls.removeClass('active');
        }
      },
      initialize: function(options) {
        this.el = options.view.el;
        this.$el = options.view.$el;
        this.controller = options.view.options.controller;
        this.module = options.module;
        this.policies = new SearchPolicyCollection();
        this.policies.url = '/mocks/search_response_v2.json';
        return this.policies.container = this;
      },
      render: function() {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        html += this.Mustache.render(tpl_search_container, {
          cid: this.cid
        });
        this.$el.html(html);
        this.controls = $('.search-controls');
        return this.messenger = new Messenger(this.options.view, this.cid);
      },
      search: function(e) {
        var search_val,
          _this = this;
        e.preventDefault();
        search_val = this.$el.find('input[type=search]').val();
        this.policies.reset();
        return this.policies.fetch({
          headers: {
            'X-Authorization': "Basic " + (this.controller.user.get('digest')),
            'Authorization': "Basic " + (this.controller.user.get('digest'))
          },
          success: function(collection, resp) {
            collection.render();
            return _this.controller.Router.append_search(encodeURI(search_val));
          },
          error: function(collection, resp) {
            return _this.Amplify.publish(_this.cid, 'warning', "There was a problem with this request: " + resp.status + " - " + resp.statusText);
          }
        });
      },
      toggle_controls: function(id) {
        var $el;
        $el = $("#" + id);
        if ($el.hasClass('active')) {
          return this.controls.removeClass('active');
        } else {
          this.controls.removeClass('active');
          return $el.addClass('active');
        }
      },
      process_event: function(e) {
        var $el;
        this.clear_menus();
        e.preventDefault();
        $el = $(e.currentTarget).parent();
        this.toggle_controls($el.attr('id'));
        return $el;
      },
      clear_menus: function() {
        return _.each(this.menu_cache, function(menu, id) {
          return menu.fadeOut(100);
        });
      },
      attach_menu: function(e, template) {
        var $tpl, el_width, tpl, tpl_id;
        if (this.menu_cache[template] !== void 0) {
          return this.menu_cache[template].fadeIn(100);
        } else {
          el_width = e.css('width');
          tpl = this.$el.find("#" + template).html();
          tpl_id = $(tpl).attr('id');
          e.append(tpl);
          $tpl = $("#" + tpl_id);
          $tpl.fadeIn(100);
          return this.menu_cache[template] = $tpl;
        }
      },
      control_context: function(e) {
        if (e.hasClass('active')) {
          return this.attach_menu(e, 'tpl-context-menu');
        }
      },
      control_save: function(e) {
        if (e.hasClass('active')) {
          return this.attach_menu(e, 'tpl-save-menu');
        }
      },
      control_share: function(e) {
        if (e.hasClass('active')) {
          return this.attach_menu(e, 'tpl-share-menu');
        }
      },
      control_pin: function(e) {
        return console.log(e.attr('id'));
      }
    });
  });

}).call(this);

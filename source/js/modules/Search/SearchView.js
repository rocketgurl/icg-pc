// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseView', 'Helpers', 'Messenger', 'modules/Search/SearchPolicyCollection', 'text!modules/Search/templates/tpl_search_container.html', 'text!modules/Search/templates/tpl_search_menu_save.html', 'text!modules/Search/templates/tpl_search_menu_views.html', 'text!modules/Search/templates/tpl_search_menu_share.html'], function(BaseView, Helpers, Messenger, SearchPolicyCollection, tpl_search_container, tpl_search_menu_save, tpl_search_menu_views, tpl_search_menu_share) {
    var SearchView;
    return SearchView = BaseView.extend({
      menu_cache: {},
      sort_cache: {},
      events: {
        "submit .filters form": "search",
        "change .search-pagination-perpage": "search",
        "change .search-pagination-page": "search",
        "click .search-control-context > a": function(e) {
          return this.control_context(this.process_event(e));
        },
        "click .search-control-save > a": function(e) {
          return this.control_save(this.process_event(e));
        },
        "click .search-control-share > a": function(e) {
          return this.control_share(this.process_event(e));
        },
        "click .search-control-pin > a": function(e) {
          return this.control_pin(e);
        },
        "click .search-control-refresh": function(e) {
          return this.control_refresh(e);
        },
        "submit .search-menu-save form": function(e) {
          return this.save_search(e);
        },
        "click .search-sort-link": "sort_by",
        "click .icon-remove-circle": function(e) {
          this.clear_menus();
          return this.controls.removeClass('active');
        }
      },
      initialize: function(options) {
        var _ref;
        this.el = options.view.el;
        this.$el = options.view.$el;
        this.controller = options.view.options.controller;
        this.module = options.module;
        this.policies = new SearchPolicyCollection();
        this.policies.url = this.controller.services.pxcentral + 'policies';
        this.policies.container = this;
        this.fetch_count = 0;
        this.params = (_ref = this.module.app.params) != null ? _ref : {};
        this.menu_cache[this.cid] = {};
        if (this.params.renewalreviewrequired != null) {
          return this.renewal_review = true;
        }
      },
      render: function() {
        var html;
        html = this.Mustache.render($('#tpl-flash-message').html(), {
          cid: this.cid
        });
        html += this.Mustache.render(tpl_search_container, {
          cid: this.cid,
          pagination: this.policies.pagination
        });
        this.$el.html(html);
        this.controls = this.$el.find('.search-controls');
        this.messenger = new Messenger(this.options.view, this.cid);
        if (this.params != null) {
          if ((this.params.q != null) || (this.params.renewalreviewrequired != null)) {
            this.setContextLabel();
            this.set_search_options(this.params);
            return this.fetch(this.get_search_options(this.params));
          }
        }
      },
      setContextLabel: function() {
        var label;
        if ((this.params.q != null) && this.params.q !== '') {
          label = this.params.q;
        } else if ((this.params.renewalreviewrequired != null) && this.params.renewalreviewrequired !== '') {
          label = 'Renewal Underwriting';
        }
        return this.$el.find('.search-control-context strong').html(label);
      },
      search: function(e) {
        if (e != null) {
          e.preventDefault();
        }
        return this.fetch(this.get_search_options());
      },
      set_search_options: function(options) {
        var elements, key, sort, sorts, val, _i, _len;
        elements = {
          'q': 'input[type=search]',
          'state': '.query-type',
          'perpage': '.search-pagination-perpage',
          'page': '.search-pagination-page'
        };
        for (key in elements) {
          val = elements[key];
          if (_.has(options, key)) {
            this.$el.find(val).val(options[key]);
          }
        }
        sorts = ['sort', 'sortdir'];
        for (_i = 0, _len = sorts.length; _i < _len; _i++) {
          sort = sorts[_i];
          if (_.has(options, sort)) {
            this.sort_cache[sort] = options[sort];
          }
        }
        if (!_.isEmpty(this.sort_cache)) {
          return this.$el.find("a[href=" + this.sort_cache['sort'] + "]").data('dir', this.sort_cache['sortdir']).trigger('click', {
            silent: true
          });
        }
      },
      get_search_options: function(options) {
        var key, page, perpage, policystate, q, query, value, _ref, _ref1, _ref2, _ref3, _ref4;
        perpage = (_ref = this.$el.find('.search-pagination-perpage').val()) != null ? _ref : 15;
        page = (_ref1 = this.$el.find('.search-pagination-page').val()) != null ? _ref1 : 1;
        policystate = (_ref2 = this.$el.find('.query-type').val()) != null ? _ref2 : '';
        q = (_ref3 = this.$el.find('input[type=search]').val()) != null ? _ref3 : '';
        query = {
          q: _.trim(q),
          perpage: perpage,
          page: page,
          policystate: policystate
        };
        if (this.renewal_review != null) {
          if ((query.q != null) && query.q !== '') {
            delete query.renewalreviewrequired;
          } else {
            query.renewalreviewrequired = true;
          }
        }
        if (!_.isEmpty(this.sort_cache)) {
          _ref4 = this.sort_cache;
          for (key in _ref4) {
            value = _ref4[key];
            query[key] = value;
          }
        }
        if (options != null) {
          for (key in options) {
            value = options[key];
            query[key] = value;
          }
        }
        for (key in query) {
          value = query[key];
          this.params[key] = value;
        }
        return query;
      },
      fetch: function(query) {
        var digest,
          _this = this;
        this.loader_ui(true);
        this.policies.reset();
        digest = this.controller.user.get('digest');
        return this.policies.fetch({
          data: query,
          headers: {
            'Authorization': "Basic " + digest
          },
          success: function(collection, resp) {
            if (collection.models.length === 0) {
              _this.loader_ui(false);
              _this.Amplify.publish(_this.cid, 'notice', "No policies found when searching for " + query.q, 3000);
              return;
            }
            collection.render();
            _this.loader_ui(false);
            _this.params = {
              q: query.q
            };
            _this.params = _.extend(_this.params, _this.get_search_options());
            _this.controller.set_active_url(_this.module.app.app);
            return _this.setContextLabel();
          },
          error: function(collection, resp) {
            _this.Amplify.publish(_this.cid, 'warning', "There was a problem with this request: " + resp.status + " - " + resp.statusText);
            return _this.loader_ui(false);
          }
        });
      },
      toggle_controls: function(id) {
        var $el;
        $el = this.$el.find("." + id);
        if ($el.hasClass('active')) {
          return this.controls.removeClass('active');
        } else {
          this.controls.removeClass('active');
          return $el.addClass('active');
        }
      },
      process_event: function(e) {
        var $el, id;
        e.preventDefault();
        this.clear_menus();
        $el = $(e.currentTarget).parent();
        id = $el.attr('class').split(' ');
        this.toggle_controls(id[1]);
        return $el;
      },
      clear_menus: function() {
        _.each(this.menu_cache[this.cid], function(menu, id) {
          return menu.fadeOut(100);
        });
        if (this.search_context_menu != null) {
          return this.search_context_menu.fadeOut(100);
        }
      },
      attach_menu: function(e, template, view_data) {
        var cache_key, el_width;
        view_data = view_data != null ? view_data : {};
        cache_key = e.attr('class').split(' ')[1];
        if (this.menu_cache[this.cid][cache_key] !== void 0) {
          this.menu_cache[this.cid][cache_key].fadeIn(100);
          return this.menu_cache[this.cid][cache_key];
        } else {
          el_width = e.css('width');
          e.append(this.Mustache.render(template, view_data));
          this.menu_cache[this.cid][cache_key] = e.find("div");
          this.menu_cache[this.cid][cache_key].fadeIn(100);
          return this.menu_cache[this.cid][cache_key];
        }
      },
      control_context: function(e) {
        if (e.hasClass('active')) {
          this.search_context_menu = this.controller.SEARCH.saved_searches.getMenu(this);
          e.append(this.search_context_menu);
          return e.find('div').fadeIn(100);
        }
      },
      control_save: function(e) {
        if (e.hasClass('active')) {
          this.attach_menu(e, tpl_search_menu_save);
          $('#search_save_label').val('').removeAttr('disabled');
          return $('.search-menu-save input[type=submit]').removeAttr('disabled').removeClass('button-disabled').addClass('button-green').val('Save view');
        }
      },
      control_share: function(e) {
        if (e.hasClass('active')) {
          return this.attach_menu(e, tpl_search_menu_share, {
            url: window.location.href
          });
        }
      },
      control_pin: function(e) {
        var search_val;
        e.preventDefault();
        search_val = this.$el.find('input[type=search]').val();
        return this.controller.Router.navigate_to_module('search', this.get_search_options());
      },
      control_refresh: function(e) {
        var options;
        e.preventDefault();
        options = {
          'cache-control': 'no-cache'
        };
        return this.fetch(this.get_search_options(options));
      },
      save_search: function(e) {
        var saved, val;
        e.preventDefault();
        val = $('#search_save_label').val();
        if (val === '') {
          return false;
        }
        saved = this.controller.SEARCH.saved_searches.create({
          label: val,
          params: this.params
        });
        if (saved) {
          $('#search_save_label').attr('disabled', 'disabled');
          return $('.search-menu-save input[type=submit]').attr('disabled', 'disabled').addClass('button-disabled').removeClass('button-green').val('Saved!');
        }
      },
      loader_ui: function(bool) {
        if (bool && !(this.loader != null)) {
          if ($('html').hasClass('lt-ie9') === false) {
            this.loader = Helpers.loader("search-spinner-" + this.cid, 100, '#ffffff');
            this.loader.setDensity(70);
            this.loader.setFPS(48);
          }
          return $("#search-loader-" + this.cid).show();
        } else {
          if ((this.loader != null) && $('html').hasClass('lt-ie9') === false) {
            this.loader.kill();
            this.loader = null;
          }
          return $("#search-loader-" + this.cid).hide();
        }
      },
      sort_by: function(e, options) {
        var $el;
        if (options == null) {
          options = {};
        }
        e.preventDefault();
        $el = $(e.currentTarget);
        this.sort_cache = {
          'sort': $el.attr('href'),
          'sortdir': $el.data('dir')
        };
        if (!_.has(options, 'silent')) {
          this.fetch(this.get_search_options(this.sort_cache));
        }
        this.remove_indicators();
        if ($el.data('dir') === 'asc') {
          $el.data('dir', 'desc');
          return this.swap_indicator($el, '&#9660;');
        } else {
          $el.data('dir', 'asc');
          return this.swap_indicator($el, '&#9650;');
        }
      },
      swap_indicator: function(el, char) {
        var reg, text;
        text = el.html();
        reg = /▲|▼/gi;
        if (text.match('▲') || text.match('▼')) {
          text = text.replace(reg, char);
          return el.html(text);
        } else {
          return el.html(text + (" " + char));
        }
      },
      remove_indicators: function() {
        return $('.search-sort-link').each(function(index, el) {
          var reg;
          el = $(el);
          reg = /▲|▼/gi;
          return el.html(el.html().replace(reg, ''));
        });
      }
    });
  });

}).call(this);

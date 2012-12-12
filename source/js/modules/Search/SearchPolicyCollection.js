// Generated by CoffeeScript 1.4.0
(function() {

  define(['BaseCollection', 'modules/Search/SearchPolicyModel', 'modules/Search/SearchPolicyView', 'base64'], function(BaseCollection, SearchPolicyModel, SearchPolicyView, Base64) {
    var SearchPolicyCollection;
    SearchPolicyCollection = BaseCollection.extend({
      model: SearchPolicyModel,
      views: [],
      parse: function(response) {
        this.pagination = {
          page: response.page,
          per_page: response.perPage,
          total_items: response.totalItems
        };
        return response.policies;
      },
      render: function() {
        this.render_pagination();
        this.container.$el.find('table.module-search tbody').html('');
        this.views = [];
        return this.populate();
      },
      populate: function() {
        var _this = this;
        this.each(function(model) {
          return _this.views.push(new SearchPolicyView({
            model: model,
            container: _this.container
          }));
        });
        return this.force_stripes();
      },
      render_pagination: function() {
        this.calculate_metadata();
        this.container.$el.find('.pagination-a span').html("Items " + this.pagination.items);
        return this.container.$el.find('.pagination-b select').html(this.calculate_pagejumps());
      },
      calculate_pagejumps: function() {
        var current_page, pages, per_page, values, _i, _ref, _results;
        per_page = $('.search-pagination-perpage').val();
        pages = (function() {
          _results = [];
          for (var _i = 1, _ref = Math.round(+this.pagination.total_items / per_page); 1 <= _ref ? _i <= _ref : _i >= _ref; 1 <= _ref ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this);
        current_page = parseInt(this.pagination.page, 10);
        values = _.map(pages, function(page) {
          if (page === current_page) {
            return $("<option value=\"" + page + "\" selected>" + page + "</option>");
          } else {
            return $("<option value=\"" + page + "\">" + page + "</option>");
          }
        });
        return values;
      },
      calculate_metadata: function() {
        var end_position, per_page, start_position;
        per_page = $('.search-pagination-perpage').val();
        if (this.pagination.total_items < per_page) {
          end_position = this.pagination.total_items;
          start_position = 1;
        } else {
          end_position = +this.pagination.page * per_page;
          start_position = end_position - per_page;
        }
        start_position = start_position === 0 ? 1 : start_position;
        return this.pagination.items = "#" + start_position + " - " + end_position + " of " + this.pagination.total_items;
      },
      force_stripes: function() {
        if ($('html').hasClass('lt-ie9')) {
          return this.container.$el.find('table.module-search tbody tr').each(function(index, el) {
            if (index % 2 === 1) {
              return $(el).find('td').css('background', '#ffffff');
            }
          });
        }
      }
    });
    return SearchPolicyCollection;
  });

}).call(this);

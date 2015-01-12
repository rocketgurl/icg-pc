define [
  'BaseCollection',
  'modules/Search/SearchPolicyModel',
  'modules/Search/SearchPolicyView',
  'base64'
], (BaseCollection, SearchPolicyModel, SearchPolicyView, Base64) ->

  #### A collection of policies
  #
  SearchPolicyCollection = BaseCollection.extend

    model : SearchPolicyModel
    views : [] # view stack

    # Retrieve the policies from the response
    parse: (response) ->
      @pagination =
        page        : response.page
        per_page    : response.perPage
        total_items : response.totalItems
      response.policies;

    # We need to reset the table so that future searches
    # won't append tables to the existing result set.
    render : ->
      @render_pagination()
      @container.$el.find('table.module-search tbody').html('')
      @views = []
      @populate()
      if @length is 1
        @views[0].open_policy()

    # Load table with policy views
    populate : ->
      @each (model) =>
        searchPolicyView = new SearchPolicyView
          model     : model
          container : @container
        @views.push searchPolicyView

    # Build and display pagination control information
    render_pagination : ->
      @calculate_metadata()
      @container.$el.find('.pagination-a span').html("Items #{@pagination.items}")
      @container.$el.find('.pagination-b select').html(@calculate_pagejumps())      

    # Calculate the page jump option tags
    calculate_pagejumps : ->
      per_page     = $('.search-pagination-perpage').val()
      pages        = [1..Math.ceil(+@pagination.total_items / per_page)]
      current_page = parseInt(@pagination.page, 10)
      values       = _.map pages, (page) ->
        if page == current_page
          return $("<option value=\"#{page}\" selected>#{page}</option>")
        else
          return $("<option value=\"#{page}\">#{page}</option>")
      
      values

    # Build the items count string for pagination
    calculate_metadata : ->
      per_page = $('.search-pagination-perpage').val()

      if @pagination.total_items < per_page
        end_position   = @pagination.total_items
        start_position = 1
      else
        end_position   = +@pagination.page * per_page
        start_position = end_position - per_page

      start_position = if start_position == 0 then 1 else start_position

      if end_position > @pagination.total_items
        end_position = @pagination.total_items

      @pagination.items = "#{start_position} - #{end_position} of #{@pagination.total_items}"

  SearchPolicyCollection
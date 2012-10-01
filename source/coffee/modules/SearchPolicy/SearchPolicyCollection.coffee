define [
  'BaseCollection',
  'modules/SearchPolicy/SearchPolicyModel',
  'modules/SearchPolicy/SearchPolicyView',
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

    # Load table with policy views
    populate : ->
      @.each (model) =>
        @views.push new SearchPolicyView(
            model     : model
            container : @container
          )
      @force_stripes() # Tell IE8 to get s*****d.

    # Build and display pagination control information
    render_pagination : ->
      @calculate_metadata()
      @container.$el.find('.pagination-a span').html("Items #{@pagination.items}")
      @container.$el.find('.pagination-b select').html(@calculate_pagejumps())      

    # Calculate the page jump option tags
    calculate_pagejumps : ->
      pages = Math.round(+@pagination.total_items / +@pagination.per_page)
      selects = ""
      for page in [1..pages]
        selected = ''
        if page is @pagination.page
          selected = ' selected'
        selects += """
            <option value="#{page}"#{selected}>#{page}</option>
          """
          
      selects

    # Build the items count string for pagination
    calculate_metadata : ->
      finish = +@pagination.page * +@pagination.per_page
      start = finish - +@pagination.per_page
      start = 1 if start is 0
      @pagination.items = "#{start} - #{finish} of #{@pagination.total_items}"

    # If you happen to be IE8 then we have to brute force striped
    # table rows, because you're lame.
    force_stripes : ->
      if $('html').hasClass('lt-ie9')
        @container.$el.find('table.module-search tbody tr').each (index, el) ->
          if index % 2 is 1
            $(el).find('td').css('background', '#ffffff')

  SearchPolicyCollection
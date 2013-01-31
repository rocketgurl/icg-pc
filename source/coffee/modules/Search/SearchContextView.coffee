define [
  'BaseView',
  'Messenger',
  'text!modules/Search/templates/tpl_search_menu_views_row.html',
  'Helpers'
], (BaseView, Messenger, tpl_search_menu_views_row, Helpers) ->

  SearchContextView = BaseView.extend

    tagName : 'tr'

    events : 
      "click .search-views-row a" : "launch_search"
      "click .admin-icon-trash" : "destroy"

    initialize : (options) ->
      @parent      = options.parent      
      @target      = @parent.find('table tbody')
      @data        = options.data
      @render()

    render : ->
      @$el.html(@Mustache.render tpl_search_menu_views_row, @data)
      @target.append(@$el)
      $('.search-filter-renewal').off('click')
      @target.on('click', '.search-filter-renewal', (e) => 
        e.preventDefault()
        @launch_search(e)
      )

    launch_search : (e) ->
      e.preventDefault()
      params = Helpers.unserialize $(e.currentTarget).attr('href')
      # params = 
      #   url   : href.url
      #   query : href.query
      @options.controller.launch_module 'search', params
      @options.controller.Router.append_module 'search', params

      # We want to close the menu in the active search view when something is
      # clicked
      @model.collection.closeMenu()

    #### Remove saved search. 
    #
    # Remember, we have to remove it from 
    # all existing menu's in the UI as well as remove from
    # the collection
    #
    destroy : (e) ->
      e.preventDefault()
      id = $(e.currentTarget).attr('href').substr(7)
      @options.controller.SEARCH.saved_searches.destroy(id)
      @$el.fadeOut('fast', (id) ->
          $('.row-' + id).html('').remove()
        )
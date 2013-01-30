define [
  'BaseView',
  'Messenger',
  'text!modules/Search/templates/tpl_search_menu_views_row.html',
  'Helpers'
], (BaseView, Messenger, tpl_search_menu_views_row, Helpers) ->

  SearchContextView = BaseView.extend

    tagName : 'tr'

    events : 
      "click .search-views-row > a" : "launch_search"
      "click .admin-icon-trash" : "destroy"

    initialize : (options) ->
      @parent      = options.parent      
      @target      = @parent.find('table tbody')
      @data        = options.data
      @search_view = options.search_view
      @render()

    render : ->
      @$el.html(@Mustache.render tpl_search_menu_views_row, @data)
      @target.append(@$el)
      $('.search-filter-renewal').off('click')
      $('.search-filter-renewal').on('click', (e) => 
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

      # We close the menu because this will force a refresh on opening it
      # again, preventing extra stacking of menu items
      if @search_view?
        @search_view.clear_menus()
        @search_view.controls.removeClass('active')

    #### Remove saved search. 
    #
    # Remember, we have to remove it from 
    # all existing menu's in the UI as well as remove from
    # the collection
    #
    destroy : (e) ->
      e.preventDefault()
      id = $(e.currentTarget).attr('href').substr(7)
      @options.collection.destroy(id)
      @$el.fadeOut('fast', (id) ->
          $('.row-' + id).html('').remove()
        )
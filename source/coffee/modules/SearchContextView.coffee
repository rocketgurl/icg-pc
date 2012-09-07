define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_search_menu_views_row.html',
  'Helpers'
], (BaseView, Messenger, tpl_search_menu_views_row, Helpers) ->

  SearchContextView = BaseView.extend

    tagName : 'tr'

    events : 
      "click .search-views-row > a" : "launch_search"
      "click .admin-icon-trash" : "destroy"

    initialize : (options) ->
      @parent = options.parent
      @target = @parent.find('table tbody')
      @data   = options.data
      @render()

    render : ->
      @$el.append(@Mustache.render tpl_search_menu_views_row, @data)
      @target.append(@$el)

    launch_search : (e) ->
      e.preventDefault()
      params = Helpers.unserialize $(e.currentTarget).attr('href')
      # params = 
      #   url   : href.url
      #   query : href.query
      @options.controller.launch_module 'search', params
      @options.controller.Router.append_module 'search', params

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
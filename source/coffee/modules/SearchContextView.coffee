define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_search_menu_views_row.html',
  'Helpers'
], (BaseView, Messenger, tpl_search_menu_views_row, Helpers) ->

  SearchContextView = BaseView.extend

    tagName : 'tr'

    events : 
      "click a" : "launch_search"

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
      href = Helpers.unserialize $(e.currentTarget).attr('href')
      params = 
        url   : href.url
        query : href.query
      @options.controller.launch_module 'search', params
      @options.controller.Router.append_module 'search', params
define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_search_menu_views_row.html'
], (BaseView, Messenger, tpl_search_menu_views_row) ->

  SearchContextView = BaseView.extend

    tagName : 'tr'

    initialize : (options) ->
      @parent = options.parent
      @target = @parent.find('table tbody')
      @data   = options.data
      @render()

    render : ->
      @$el.append(@Mustache.render tpl_search_menu_views_row, @data)
      @target.append(@$el)

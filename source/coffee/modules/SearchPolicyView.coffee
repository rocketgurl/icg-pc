define [
  'BaseView',
  'text!templates/tpl_search_policy_row.html'
], (BaseView, tpl_search_policy_row) ->

  SearchPolicyView = BaseView.extend

    tagName : 'tr'

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @data = options.model.attributes
      @parent = options.container.$el
      @target = @parent.find('table.module-search')
      @render()

    render : ->
      @$el.attr 
        id : @data.id

      @$el.html @Mustache.render tpl_search_policy_row, @data
      @target.append @$el
define [
  'BaseView',
  'text!templates/tpl_search_policy_row.html'
], (BaseView, tpl_search_policy_row) ->

  SearchPolicyView = BaseView.extend

    tagName : 'tr'

    events :
      "click" : "open_policy"

    # We need to brute force the View's container to the 
    # WorkspaceCanvasView's el
    initialize : (options) ->
      @data   = options.model.attributes
      @parent = options.container.$el
      @target = @parent.find('table.module-search tbody')
      @module = options.model.collection.container.module
      @render()

    # Attach view to table
    render : ->
      @$el.attr 
        id : @data.id

      @$el.html @Mustache.render tpl_search_policy_row, @data
      @target.append @$el

    # Remove view and deref what we can for GC
    destroy : ->
      @$el.remove()
      @model = null
      @el    = null

    # Open a new PolicyView tab with the current policy
    open_policy : (e) ->
      e.preventDefault()
      $el = $(e.currentTarget)

      identifiers = @model.get('identifiers')

      # Setup the app object to launch policy view with
      app =
        app       : 'policyview'
        app_label : identifiers.QuoteNumber
        params    :
          id : $el.attr('id')

      @module.view.launch_child_app app

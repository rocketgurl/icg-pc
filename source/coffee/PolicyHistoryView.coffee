define [
  'BaseView'
], (BaseView) ->

  PolicyHistoryView = BaseView.extend

    template : _.template """
    <h4>Recently Viewed</h4>
    <ul id="<%= id %>">
      <% _.each(historyStack, function (item) { %>
      <li><a href="#" id="<%= item.app %>"><%= item.app_label %></a></li>
      <% }) %>
    </ul>
    """

    initialize : (options) ->
      _.bindAll this, 'render', 'launchApp'
      @controller = options.controller
      @workspaceState = options.workspaceState
      @listenTo @workspaceState, 'change:history', @render
      
      # HACK!
      # Since we're currently forced to use the same $el for each instance of PolicyHistoryView,
      # Namespace our click handler to the workspace state id to prevent firing multiple events
      @$el.on 'click', "##{@workspaceState.id} > li > a", @launchApp

    launchApp : (e) ->
      e.preventDefault()
      historyStack = @workspaceState.getHistoryStack()
      app = _.findWhere historyStack, { app: e.currentTarget.id }
      @controller.launch_module 'policyview', app.params
      @controller.Router.append_module 'policyview', app.params

    render : ->
      data = {}
      data.historyStack = @workspaceState.getHistoryStack()
      data.id           = @workspaceState.id
      if data.historyStack.length > 0
        @$el.html @template data
        @$el.removeClass 'hidden'
      else
        @$el.empty()
        @$el.addClass 'hidden'
      


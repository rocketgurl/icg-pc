define [
  'BaseView'
], (BaseView) ->

  PolicyHistoryView = BaseView.extend

    template : _.template """
    <h4>Recently Viewed</h4>
    <ul id="<%= id %>">
      <% _.each(historyStack, function (item) { %>
        <% if (item.params) { %>
        <li><a href="#<%= baseRoute %>/policy/<%= item.params.url %>" id="<%= item.app %>"><%= item.app_label %></a></li>
        <% } %>
      <% }) %>
    </ul>
    """

    initialize : (options) ->
      _.bindAll this, 'render'
      @controller = options.controller
      @workspaceState = @controller.workspace_state
      @listenTo @workspaceState, 'change:history', @render

    render : ->
      data = {}
      data.baseRoute    = @controller.baseRoute
      data.historyStack = @workspaceState.getHistoryStack()
      data.id           = @workspaceState.id
      if data.historyStack.length > 0
        @$el.html @template data
        @$el.removeClass 'hidden'
      else
        @$el.empty()
        @$el.addClass 'hidden'

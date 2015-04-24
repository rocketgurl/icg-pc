define [
  'BaseView'
], (BaseView) ->

  class OpenPoliciesNavView extends BaseView

    template : _.template """
    <% _.each(policyApps, function (app) { %>
    <li>
      <span class="glyphicon glyphicon-remove-circle" title="Close this tab" data-view="<%= app.view %>"></span>
      <a href="#<%= baseRoute %>/policy/<%= app.params.url %>"><%= app.label %></a>
    </li>
    <% }) %>
    """

    initialize : (options) ->
      _.bindAll this, 'render'
      @controller = options.controller
      @workspaceState = options.workspaceState
      @listenTo @workspaceState, 'change:apps', @render

    render : ->
      data = {}
      data.baseRoute  = @controller.baseRoute
      data.policyApps = _.reject @workspaceState.get('apps'), (app) ->
        not (/policyview/.test(app.app))
      console.log 'NAV RENDERED'
      if data.policyApps.length > 0
        @$el.html @template data
      else
        @$el.html '<li class="no-policies"><em>You Have No Open Policies</em></li>'

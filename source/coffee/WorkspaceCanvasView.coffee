define [
  'mustache'
], (Mustache) ->

  WorkspaceCanvasView =
    render_tab : (template) ->
      tab = Mustache.render template, { tab_class : ' class="selected"', tab_url : '#login', tab_label : 'Login' }
      @options.controller.$workspace_tabs.append(tab)
      console.log tab
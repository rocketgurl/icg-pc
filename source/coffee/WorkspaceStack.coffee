define ['underscore'], (_) ->

  ###
  # Manage an array of Workspaces for the main Controller
  ###

  class WorkspaceStack

    policyCount : 0

    constructor : (@controller) ->
      @stack = []

    # Add a view to the stack, but check for duplicates first
    add : (view) ->
      exists = _.find @stack, (item) ->
        return item.app.app == view.app.app
      if !exists?
        @stack.push view

        # increment policy count
        if /policyview/.test view.app.app
          @policyCount += 1

    # Remove a view from the stack
    remove : (view) ->
      _.each @stack, (obj, index) =>
        if view.app.app == obj.app.app
          @stack.splice index, 1

          # decrement policy count
          if /policyview/.test view.app.app
            @policyCount -= 1

          # Remove params from stack if present
          if view.app.params?
            @controller.current_state.params = null
            @controller.setWorkspaceState()

    # Remove all views from stack
    clear : ->
      while @stack.length
        view = @stack.shift()
        if /policyview/.test view.app.app
            @policyCount -= 1
        view.dispose()
        view.destroy()
        view = null

    has : (app_name) ->
      _.any @stack, (item) ->
        item.app.app is app_name

    # Find a view in the stack and return it
    get : (app) ->
      for index, obj of @stack
        if app == obj.app.app
          return obj

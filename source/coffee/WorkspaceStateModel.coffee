define [
  'BaseModel'
], (BaseModel) ->

  #### WorkspaceStateModel
  #
  # Store information about the current workspace
  #
  WorkspaceStateModel = BaseModel.extend

    historyStackMaxSize : 10

    initialize : (attributes) ->
      @use_localStorage('ics_policy_central') # Use LocalStorage

      # Build name attr from WorkspaceController.current_state
      if attributes?
        @build_name(attributes)

    build_name : (workspace) ->
      workspace = if workspace is not undefined then workspace else @get('workspace')
      if workspace? 
        @set 'name', "#{workspace.business}_#{workspace.context}_#{workspace.env}"

    getSafeArray : (key) ->
      arr = @get key
      unless _.isArray arr
        arr = []
      arr

    getHistoryStack : ->
      @getSafeArray 'history'

    getAppStack : ->
      @getSafeArray 'apps'

    # Updates an app config item from a given
    # stack. Valid stacks include `apps` and `history`
    # Should trigger a `change:type` event on the model
    #
    # @param `key` _Object_ name of the stack to retrieve
    # @param `app` _Object_ application config object
    updateStackItem : (key, app) ->
      if _.contains ['apps', 'history'], key
        stack = _.clone @getSafeArray key
        updated = _.any stack, (item) ->
          if item.app is app.app
            _.extend item, app
            true
        if updated
          @set key, stack, { trigger : false }
          @trigger "change:#{key}", @, @get(key)
        updated

    # Updating info on an app config item
    updateAppItem : (app) ->
      @updateStackItem 'apps', app

    # Updating info on an historic app config item
    updateHistoryItem : (app) ->
      @updateStackItem 'history', app

    # Maintain a history of recently viewed apps
    # Ordered by most recently updated
    #
    # @param `app` _Object_ application config object
    updateHistoryStack : (app) ->
      history = @getHistoryStack()

      # History items should be unique. If an app item is
      # already in the stack, return a new array minus the item
      history = _.reject history, (item) ->
        item.app is app.app

      # Add the item to the front of the stack
      history.unshift app

      # The history stack is limited to the @historyStackMaxSize
      history = history.slice 0, @historyStackMaxSize

      @set 'history', history
      this

      
  WorkspaceStateModel
define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

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
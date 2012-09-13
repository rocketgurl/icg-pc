define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### WorkspaceStateModel
  #
  # Store information about the current workspace
  #
  WorkspaceStateModel = BaseModel.extend

    initialize : (attributes) ->
      @use_localStorage('ics_policy_central') # Use LocalStorage

      # Build name attr from WorkspaceController.current_state
      if attributes?
        @build_name(attributes)

    build_name : (workspace) ->
      workspace = if workspace is not undefined then workspace else @get('workspace')
      if workspace? 
        @set 'name', "#{workspace.business}_#{workspace.context}_#{workspace.env}"

      
  WorkspaceStateModel
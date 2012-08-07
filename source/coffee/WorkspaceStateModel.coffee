define [
  'BaseModel',
  'base64'
], (BaseModel, Base64) ->

  #### WorkspaceStateModel
  #
  # Store information about the current workspace
  #
  WorkspaceStateModel = BaseModel.extend

    initialize : () ->
      @use_localStorage('ics_policy_central') # Use LocalStorage

      
  WorkspaceStateModel
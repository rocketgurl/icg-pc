define [
  'BaseCollection',
  'WorkspaceStateModel',
  'WorkspaceController'
], (BaseCollection, WorkspaceStateModel, WorkspaceController) ->

  #### Manage multiple Workspaces
  #
  WorkspaceStateCollection = BaseCollection.extend

    model: WorkspaceStateModel

    retrieve : (current_state) ->
      if !current_state?
        return false

      @where({
        name : "#{current_state.business}_#{current_state.context}_#{current_state.env}"
        })


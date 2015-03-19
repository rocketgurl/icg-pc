define [
  'BaseCollection'
  'WorkspaceStateModel'
], (BaseCollection, WorkspaceStateModel) ->

  #### Manage multiple Workspaces
  #
  WorkspaceStateCollection = BaseCollection.extend

    model : WorkspaceStateModel

    # Return model by name, which is generated from current_state obj
    retrieve : (state) ->
      unless _.isEmpty state
        @find (model) ->
          name = "#{state.business}_#{state.context}_#{state.env}"
          name is model.get 'name'

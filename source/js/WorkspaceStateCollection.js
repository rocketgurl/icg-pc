// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseCollection', 'WorkspaceStateModel', 'WorkspaceController'], function(BaseCollection, WorkspaceStateModel, WorkspaceController) {
    var WorkspaceStateCollection;
    return WorkspaceStateCollection = BaseCollection.extend({
      model: WorkspaceStateModel,
      retrieve: function(current_state) {
        if (!(current_state != null)) {
          return false;
        }
        return this.where({
          name: "" + current_state.business + "_" + current_state.context + "_" + current_state.env
        });
      }
    });
  });

}).call(this);
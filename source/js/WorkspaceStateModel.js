// Generated by CoffeeScript 1.3.3
(function() {

  define(['BaseModel', 'base64'], function(BaseModel, Base64) {
    var WorkspaceStateModel;
    WorkspaceStateModel = BaseModel.extend({
      initialize: function(attributes) {
        this.use_localStorage('ics_policy_central');
        if (attributes != null) {
          return this.build_name(attributes);
        }
      },
      build_name: function(workspace) {
        workspace = workspace === !void 0 ? workspace : this.get('workspace');
        if (workspace != null) {
          return this.set('name', "" + workspace.business + "_" + workspace.context + "_" + workspace.env);
        }
      }
    });
    return WorkspaceStateModel;
  });

}).call(this);

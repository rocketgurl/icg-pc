define [
  'jquery', 
  'underscore',
  'backbone',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, amplify) ->

  WorkspaceController =
    Amplify              : amplify
    workspace_button     : $('#button-workspace')
    workspace_breadcrumb : $('#breadcrump')
    workspace_admin      : $('#header-admin')
    logger               : (msg) ->
      @Amplify.publish 'log', msg

  _.extend WorkspaceController, Backbone.Events

  WorkspaceController.on "log", (msg) ->
    @logger msg

  WorkspaceController
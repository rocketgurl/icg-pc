define [
  'jquery', 
  'underscore',
  'backbone',
  'UserModel',
  'WorkspaceLoginView',
  'amplify_core',
  'amplify_store'
], ($, _, Backbone, UserModel, WorkspaceLoginView, amplify) ->

  #### Orchestrate the Workspace 
  #
  # This controller wires together different views/models
  # to handle Workspace events and in general act like
  # a switchboard operator.
  #
  WorkspaceController =
    Amplify              : amplify
    workspace_button     : $('#button-workspace')
    workspace_breadcrumb : $('#breadcrump')
    workspace_admin      : $('#header-admin')
    workspace_canvas     : $('#canvas')
    
    # Simple logger
    logger               : (msg) ->
      @Amplify.publish 'log', msg

    # Stub for login form. This should be expanded to handle
    # checking for Auth in cookies, etc.
    build_login : () ->
      @user = new UserModel()
      @login_view = new WorkspaceLoginView({
          id : '#canvas'
          el : 'section'
          template : $('#tpl-ics-login')
        })
      @login_view.render()


  _.extend WorkspaceController, Backbone.Events

  WorkspaceController.on "log", (msg) ->
    @logger msg

  WorkspaceController
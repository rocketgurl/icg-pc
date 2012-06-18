define [
  'BaseView'
], (BaseView) ->

  WorkspaceView = BaseView.extend
    initialize : (options) ->
      @logger 'View is ready!'
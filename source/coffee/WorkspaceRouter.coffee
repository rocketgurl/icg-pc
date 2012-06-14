define [
  'BaseRouter'
], (BaseRouter) ->

  WorkspaceRouter = BaseRouter.extend
    initialize : (options) ->
      @logger 'Router is ready!'
define [
  'BaseView'
], (BaseView) ->

  WorkspaceLoginView = BaseView.extend
    initialize : (options) ->
      @template = options.template if options.template?

    render : () ->
      @$el.html @template.html()


define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  # Build the main list of action views for the default page
  class MakePaymentAction extends IPMActionView

    initialize : ->
      super

    ready : ->
      @fetchTemplates(@MODULE.POLICY, 'make-payment', @render)

    success : (model, view) ->
      console.log ['MakePayment::success', model, view]

    render : (model, view) =>
      html = @MODULE.VIEW.Mustache.render(view, model)
      @trigger "loaded", html
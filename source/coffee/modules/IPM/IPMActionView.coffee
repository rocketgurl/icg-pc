define [
  'BaseView',
  'Messenger'
], (BaseView, Messenger) ->

  # IPMActionView
  # ====  
  # IPM sub views (action views) inherit from this base view 
  class IPMActionView extends BaseView
    
    MODULE     : {}    

    initialize : (options) ->
      # Access BaseView from here
      @super   = IPMActionView.prototype
      @MODULE  = options.MODULE if options.MODULE?
      @$el     = @MODULE.CONTAINER if @MODULE.CONTAINER
      
      delete @options

    # Your Action View should define the following methods:
  
    render : -> 

    validate : ->

    preview : ->
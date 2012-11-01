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
      @super       = IPMActionView.prototype
      @PARENT_VIEW = options.PARENT_VIEW if options.PARENT_VIEW?
      @MODULE      = options.MODULE if options.MODULE?
      @$el         = @MODULE.CONTAINER if @MODULE.CONTAINER
      
      delete @options

      @on('ready', @ready, this)

    # **fetchTemplates**  
    # Grab the model.json and 
    #
    # @param `policy` _Object_ PolicyModel
    # @param `action` _String_ Name of this action 
    # @param `callback` _Function_ function to call on AJAX success  
    #
    fetchTemplates : (policy, action, callback) ->
      if !policy? || !action?
        return false

      path = "js/modules/IPM/products/#{policy.get('productName')}/forms/#{_.slugify(action)}"

      model = $.getJSON("#{path}/model.json")
                .pipe (resp) -> return resp

      view = $.get("#{path}/view.html", null, null, "text")
              .pipe (resp) -> return resp

      $.when(model, view).then(callback, @PARENT_VIEW.actionError)

    # Your Action View should define the following methods:
    ready : ->

    render : -> 

    validate : ->

    preview : -> 


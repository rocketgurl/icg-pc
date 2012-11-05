define [
  'BaseView',
  'Messenger',
  'modules/IPM/IPMChangeSet'
], (BaseView, Messenger, IPMChangeSet) ->

  # IPMActionView
  # ====  
  # IPM sub views (action views) inherit from this base view 
  class IPMActionView extends BaseView
    
    MODULE     : {} # Containing module
    VALUES     : {} # Form values
    TPL_CACHE  : {} # Template Cache
    CHANGE_SET : {}

    events :
      "click form input.button" : "submit"
      "click .form_actions a"   : "goHome"

    initialize : (options) ->
      @PARENT_VIEW = options.PARENT_VIEW || {}
      @MODULE      = options.MODULE || {}
      @CHANGE_SET  = new IPMChangeSet(@MODULE.POLICY, @PARENT_VIEW.VIEW_STATE, @MODULE.USER)
      @$el         = @MODULE.CONTAINER if @MODULE.CONTAINER
      
      @options = null

      @on('ready', @ready, this)

    # **fetchTemplates** grab the model.json and view.html for processing  
    #
    # @param `policy` _Object_ PolicyModel
    # @param `action` _String_ Name of this action 
    # @param `callback` _Function_ function to call on AJAX success  
    #
    fetchTemplates : (policy, action, callback) ->
      if !policy? || !action?
        return false

      path  = "/js/#{@MODULE.CONFIG.PRODUCTS_PATH}#{policy.get('productName')}/forms/#{_.slugify(action)}"

      # Stash the files in the cache on first load
      if !_.has(@TPL_CACHE, action)          
        model = $.getJSON("#{path}/model.json")
                  .pipe (resp) -> return resp        
        view  = $.get("#{path}/view.html", null, null, "text")
                  .pipe (resp) -> return resp
        $.when(model, view).then(callback, @PARENT_VIEW.actionError)
      else
        callback(@TPL_CACHE[action].model, @TPL_CACHE[action].view)

    # **Return to home page of IPM**  
    #
    # @param `e` _Event_  
    #
    goHome : (e) ->
      e.preventDefault()
      @PARENT_VIEW.route 'Home'

    # **Get the form values**  
    #
    # @param `form` _HTML Form Element_  
    # @return _Object_ key:val object of form values  
    #
    getFormValues : (form) ->
      formValues = {}
      for item in form.serializeArray()
        formValues[item.name] = item.value
      formValues

    # **Which form values changed?**  
    #
    # @param `form` _HTML Form Element_  
    # @return _Object_ key:val object of changed form values  
    #
    getChangedValues : (form) ->
      changed = []
      form.find(':input').each (i, element) ->
        el   = $(element)
        val  = el.val()
        name = el.attr 'name'

        # Check on data-value of <select> element
        if el.is 'select'
          if el.data('value') != val
            changed.push name

        # Check on <textarea> fields.
        else if el.is 'textarea'
          if val.trim() != ''
            changed.push name
          if val.trim() == '' && el.data('hadValue')
            changed.push name

        else
          if val != element.getAttribute('value')
            changed.push name

      changed

    # Keep a cache of loaded files for this action
    processView : (vocabTerms, view) ->
      @TPL_CACHE[@PARENT_VIEW.VIEW_STATE] =
        model : vocabTerms
        view  : view

    callbackSuccess : (data, status, jqXHR) =>
      console.log jqXHR
     
    callbackError : (jqXHR, status, error) =>
      console.log jqXHR

    # Your Action View should define the following methods:
    ready : ->

    render : -> 

    validate : ->

    preview : ->

    # **Submit form** - set the form values on the ActionView for 
    # use in inherited ActionViews
    #
    # @param `e` _Event_ Submit event   
    #
    submit : (e) ->
      e.preventDefault()
      form = @$el.find('form')      
      @VALUES =
        formValues    : @getFormValues form
        changedValues : @getChangedValues form


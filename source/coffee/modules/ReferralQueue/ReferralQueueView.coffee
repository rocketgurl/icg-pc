define [
  'BaseView',
  'Helpers',
  'Messenger',
  'modules/ReferralQueue/ReferralTaskView',
  'text!modules/ReferralQueue/templates/tpl_referral_container.html'
], (BaseView, Helpers, Messenger, ReferralTaskView, tpl_container) ->

  ReferralQueueView = BaseView.extend

    initialize : (options) ->
      @MODULE      = options.module || false
      @COLLECTION  = options.collection || false
      @PARENT_VIEW = options.view || false

      # When the collection is populated, generate the views
      @COLLECTION.bind('reset', @renderTasks, this);

      # Setup our DOM hooks
      @el  = @PARENT_VIEW.el
      @$el = @PARENT_VIEW.$el

    render : ->
      # Setup flash module & main container
      html = @Mustache.render $('#tpl-flash-message').html(), { cid : @cid }
      html += @Mustache.render tpl_container, { cid : @cid, pagination: {} }
      @$el.html html

      # Find the container to load rows into
      @CONTAINER = @$el.find('table.module-referrals tbody')

      this

    # **Render tasks**  
    # Map the collection models into an array of ReferralTaskViews that we
    # can use to populate the overall view with task rows.
    #
    # @param `collection` _Object_ ReferralTaskCollection  
    # @return _Array_  
    #
    renderTasks : (collection) ->
      @TASK_VIEWS = collection.map (model) => 
        new ReferralTaskView(
            model       : model,
            parent_view : this
          )

      for task in @TASK_VIEWS
        @CONTAINER.append(task.render())
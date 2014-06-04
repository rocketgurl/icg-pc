define [
  'BaseView',
  'Messenger',
  'modules/LossHistory/LossHistoryModel',
  'text!modules/LossHistory/templates/tpl_loss_history_container.html',
  'jqueryui'
], (BaseView, Messenger, LossHistoryModel, tpl_lh_container) ->

  LossHistoryView = BaseView.extend

    initialize : (options) ->
      @Policy      = options.policy
      @PolicyView  = options.policy_view
      @User        = @PolicyView.controller.user

      # Setup model for moving metadata around
      @LossHistoryModel = new LossHistoryModel(
          id      : @Policy.id
          urlRoot : @Policy.get 'urlRoot'
          digest  : @Policy.get 'digest'
          user    : @User.id
        )

      # Attach events to model
      @LossHistoryModel.on 'all', -> console.log(arguments)
      @LossHistoryModel.on 'losshistory:success', @lossHistorySuccess, this
      @LossHistoryModel.on 'losshistory:error', @lossHistoryError, this

    render : ->
      @setupLoader()
   
      @LossHistoryModel.fetch(
        success : (model, resp) ->
          model.trigger('losshistory:success', resp)
        error : (model, resp) ->
          model.trigger('losshistory:error', resp)
      )

      this # so we can chain

    setupLoader : ->
      $loader = $("""
        <div id="lh-loader-#{@cid}" class="lh-loader">
          <h2 id="lh-spinner-#{@cid}"><span>Loading Loss History&hellip;</span></h2>
        </div>
        """)
      @$el.append $loader
      @loader = @Helpers.loader "lh-spinner-#{@cid}", 80, '#696969'
      @loader.setFPS 48

    removeLoader : ->
      @loader?.kill()

    process_event : (e) ->
      e.preventDefault()
      $(e.currentTarget)

    processRenewalResponse : (resp) ->
      resp.cid = @cid # so we can phone home to the correct view
      
      resp.lossHistoryFlag  = true
      
      if _.isEmpty resp.lossHistory
        resp.lossHistoryFlag = false

      resp

    lossHistorySuccess : (resp) ->
      if resp?
        # If the dataset comes back empty, the policy does not have loss history, so simply
        # display that information to the user and return
        if _.isEmpty resp
          @removeLoader()
          $("#lh-spinner-#{@cid}").find("span").html("No Loss History for this Policy")
          return false

        # walk the response and adjust information to match the view
        resp = @processRenewalResponse(resp)

        if resp.lossHistoryFlag == false
          @removeLoader()
          $("#lh-spinner-#{@cid}").find("span").html("No Loss History for this Policy")
          return false
        
        # trim the timestamp off the date data
        for lossRecord in resp.lossHistory
          do (lossRecord) -> 
            lossDate = lossRecord.lossDate
            if lossDate.indexOf(' ') != -1
              lossRecord.lossDate = lossDate.substring 0, lossDate.indexOf(' ')

        @$el.html @Mustache.render tpl_lh_container, resp

        @removeLoader()
        @PolicyView.resize_view @$el
      else
        @removeLoader()
        @lossHistoryError({statusText : 'Dataset empty', status : 'Backbone'})

    lossHistoryError : (resp) ->
      @removeLoader()
      @Amplify.publish(@PolicyView.cid, 'warning', "Could not retrieve loss history information: #{resp.statusText} (#{resp.status})")
define [
  'BaseView',
  'Messenger',
  'text!modules/ZenDesk/templates/tpl_zendesk_container.html'
], (BaseView, Messenger, tpl_zd_container) ->

  ZenDeskView = BaseView.extend

    # Setup commons references to parents and this element
    initialize : (options) ->
      [@$el, @policy, @policy_view] = [options.$el, options.policy, options.policy_view]
      @$el.append("<div id=\"zd_shim_#{@cid}\" class=\"zd-shim\"><div id=\"zd_loader_#{@cid}\" class=\"zd-loader\"></div></div>");
      this

    # Get tickets from the ZenDesk proxy
    fetch : ->
      @show()
      @fetch_tickets(@policy.get_policy_id())

    render : ->
      @remove_loader()
      @$el.find("#zd_shim_#{@cid}").html @Mustache.render tpl_zd_container, { results : @tickets.results }

    show : ->
      @$el.fadeIn 'fast', =>
        @attach_loader()

    hide : ->
      @$el.hide()

    attach_loader : ->
      if $("#zd_loader_#{@cid}").length > 0
        @loader = @Helpers.loader("zd_loader_#{@cid}", 80, '#696969')
        @loader.setFPS(48)

    remove_loader : ->
      if @loader?
        @loader.kill();
        $("#zd_loader_#{@cid}").hide()

    # Hit our proxy to get tickets from ZenDesk by searching on the policy id.
    # It basically simpler at this point to hit it directly instead of creating
    # Model/Controllers as we're not doing anything special with them.
    fetch_tickets : (query) -> 
      if _.isEmpty query
        @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to search the ZenDesk API at this time. Sorry.")
        return false
      else
        $.ajax
          url         : @policy_view.services.zendesk
          type        : 'GET'
          contentType : 'application/json'
          data :
            query      : query
            sort_order : 'desc'
            sort_by    : 'created_at'
          dataType : 'json'
          success : (data, textStatus, jqXHR) =>
            @tickets = data
            @render()
            @policy_view.resize_workspace(@$el, null)
          error: (jqXHR, textStatus, errorThrown) =>
            @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to access the ZenDesk API at this time. Message: #{textStatus}")
            @remove_loader()
            false
      this

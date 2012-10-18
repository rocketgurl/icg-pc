define [
  'BaseView',
  'Messenger',
  'text!modules/ZenDesk/templates/tpl_zendesk_container.html'
], (BaseView, Messenger, tpl_zd_container) ->

  ZenDeskView = BaseView.extend

    # Setup commons references to parents and this element
    initialize : (options) ->
      [@$el, @policy, @policy_view] = [options.$el, options.policy, options.policy_view]
      this

    # Get tickets from the ZenDesk proxy
    fetch : ->
      @fetch_tickets(@policy.get_policy_id())

    render : ->
      @$el.html @Mustache.render tpl_zd_container, { results : @tickets.results }
      @show()

    show : ->
      @$el.fadeIn('fast')

    hide : ->
      @$el.hide()

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
          error: (jqXHR, textStatus, errorThrown) =>
            @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to access the ZenDesk API at this time. Message: #{textStatus}")
            false
      this

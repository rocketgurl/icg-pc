define [
  'BaseView',
  'Messenger',
  'text!templates/tpl_zendesk_container.html'
], (BaseView, Messenger, tpl_zd_container) ->

  ZenDeskView = BaseView.extend

    events :
      'click a[href=assigned_to]' : (e) -> @process_event e

    initialize : (options) ->
      [@$el, @policy, @policy_view] = [options.$el, options.policy, options.policy_view]

    render : ->
      tickets = @fetch_tickets(@policy.get_policy_id())
      @$el.html @Mustache.render tpl_zd_container, { results : tickets.results }
      @show()

    show : ->
      @$el.fadeIn('fast')

    hide : ->
      @$el.hide()

    process_event : (e) ->
      e.preventDefault()
      $(e.currentTarget)

    fetch_tickets : (query) ->
      if _.isEmpty query
        @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to search the ZenDesk API at this time. Sorry.")
        false

      digest = @Helpers.createDigest 'darren.newton@arc90.com', 'arc90zen'

      if !digest
        @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to search the ZenDesk API at this time. Sorry.")
        false
      else
        $.ajax
          url : "#{@policy_view.services.zendesk}/search.json"
          type : 'GET'
          contentType : 'application/json'
          data :
            query      : query
            sort_order : 'desc'
            sort_by    : 'created_at'
          dataType : 'json'
          headers :
            'Authorization' : "Basic #{digest}"
          success : (data, textStatus, jqXHR) =>
            console.log data
            data
          error: (jqXHR, textStatus, errorThrown) =>
            @Amplify.publish(@policy_view.cid, 'warning', "This policy is unable to access the ZenDesk API at this time. Message: #{textStatus}")
            console.log jqXHR
            false

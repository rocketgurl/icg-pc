define [
  'BaseView'
  'modules/Home/collections/AgentPortalNoticesCollection'
], (BaseView, APNoticesCollection) ->

  class AgentPortalNoticesView extends BaseView

    noticeItemTemplate : _.template("""
    <li id="notice-item-<%= id %>" class="notice-item">
      <h3><%= title %> &ndash; <small><%= datePublished %></small></h3>
      <div class="notice-item-content"><%= content %></div>
      <div class="notice-item-toggle">
        <a href="#" class="more">&hellip; Read More</a>
        <a href="#" class="less">&hellip; Read Less</a>
      </div>
    </li>
    """)

    events :
      'click .notice-item-toggle > a' : 'toggleNoticeItem'

    initialize : ->
      _.bindAll this, 'renderNotices'
      @$noticeList = @$('.panel-body > ul')
      @collection = new APNoticesCollection()
      @collection.digest = @options.controller.APP_PC_AUTH
      @collection.config = @options.controller.services.agentPortalNotices
      @collection.on 'reset', @renderNotices
      @collection.fetch() if @options.controller.services.agentPortalNotices?

    toggleNoticeItem : (e) ->
      $noticeItem = $(e.currentTarget).parents '.notice-item'
      $noticeItem[if $noticeItem.hasClass 'open' then 'removeClass' else 'addClass']('open')
      e.preventDefault()

    renderNotices : ->
      @$noticeList.empty()
      @collection.each (model) =>
        $noticeItem = $(@noticeItemTemplate model.toJSON())
        @$noticeList.append $noticeItem
        contentHeight = $noticeItem.find('.notice-item-content').height()
        if contentHeight > 40
          $noticeItem.addClass 'needs-toggle'


define [
  'tab'
  'BaseView'
  'modules/PolicyQuickView/views/ServicingTabView'
  'modules/PolicyQuickView/views/ActivityView'
  'modules/PolicyQuickView/views/DocumentsView'
  'text!modules/PolicyQuickView/templates/tpl_quickview_container.html'
], (tab, BaseView, ServicingTabView, ActivityView, DocumentsView, tpl_qv_container) ->

  # PolicyQuickView
  # ====
  # Parent view for PolicyQuickView subviews
  class PolicyQuickView extends BaseView

    initialize : (options) ->
      @CONTROLLER = options.controller
      @POLICY = options.policy
      return this

    render : ->
      attachmentsLocation = "#{@CONTROLLER.services.ixlibrary}buckets/policy_attachments/objects/"
      viewData =
        cid                 : @cid
        attachmentsLocation : attachmentsLocation
        authToken           : "Basic #{@POLICY.get('digest')}"

      @$el.html @Mustache.render tpl_qv_container, viewData

      servicing = new ServicingTabView
        qvid       : @cid
        controller : @CONTROLLER
        policy     : @POLICY
        el         : @$("#tab-servicing-#{@cid}")

      activities = new ActivityView
        qvid                : @cid
        policy              : @POLICY
        attachmentsLocation : attachmentsLocation
        el                  : @$("#activity-#{@cid}")

      documents = new DocumentsView
        qvid   : @cid
        policy : @POLICY
        el     : @$("#documents-#{@cid}")

      return this

define [
  'modules/IPM/IPMActionView',
  'mustache'
], (IPMActionView, Mustache) ->

  ###
  # This sends a very minimal and simple PCS which should
  # 'unlock' a policy
  #
  # !! NOTE !!
  #
  # We have to make a custom PCS and send it to
  # pxServer, not pxCentral so we handroll the XML and
  # point ChangeSet to pxServer
  #
  ###

  class UnlockPolicy extends IPMActionView

    initialize : ->
      super
      @events =
        "click .unlock-links li a" : "submit"

    ready : ->
      super
      @fetchTemplates(@MODULE.POLICY, 'unlock-policy', @processView)

    processViewData : (vocabTerms, view) =>
      super vocabTerms, view

    processView : (vocabTerms, view) =>
      @processViewData(vocabTerms, view)
      @trigger "loaded", this, @postProcessView

    submit : (e) ->
      super
      context =
        user : @MODULE.USER.get 'email'

      tpl = """<PolicyChangeSet schemaVersion="2.1" username="{{user}}" description="Unlock Policy"><Flags><Flag name="locked" value="false"/></Flags></PolicyChangeSet>"""

      xml      = Mustache.render tpl, context
      id       = @MODULE.POLICY.id
      pxserver = "#{@MODULE.CONTROLLER.services.pxserver}/#{id}"

      @ChangeSet.commitChange(
        xml,
        @callbackSuccess,
        @callbackError(xml)
        url : pxserver
        headers :
          'Authorization' : "Basic #{@MODULE.CONTROLLER.IXVOCAB_AUTH}"
      )

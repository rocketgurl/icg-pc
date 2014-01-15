define [
  'modules/IPM/IPMActionView'
], (IPMActionView) ->

  ###
  # This sends a very minimal and simple PCS which should
  # 'unlock' a policy
  ###

  class UnlockPolicy extends IPMActionView

    initialize : ->
      super
      @events =
        "click .ipm-action-links li a" : "submit"

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

      @values.formValues.name = "locked"
      @values.formValues.value = "false"

      @ChangeSet.commitChange(
        @ChangeSet.getPolicyChangeSet(@values),
        @callbackSuccess,
        @callbackError
      )

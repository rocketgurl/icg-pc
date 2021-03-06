define [
  'BaseModel'
], (BaseModel) ->

  # Renewal Underwriting Metadata (Policy)
  # ====
  #
  # Handles the Metadata for Policies around Renewal Underwriting.
  # Moved this into its own model as it's passing around JSON instead of
  # XML and would have clouded the intent of PolicyModel a bit.
  #
  LossHistoryModel = BaseModel.extend

    # We will use traditional Backbone JSON sync + Basic Auth
    initialize : ->
      @use_backbone_auth()

    # **Assemble urls for Loss History - Using Renewal Underwriting Call (which includes Loss History)**  
    # @return _String_  
    url : ->
      "#{@get('urlRoot')}policies/#{@id}/renewalunderwriting"
      #"/js/templates/renewal_underwriting_get.json"

    # We don't want to send the whole model back to pxCentral, just a
    # small JSON fragment, so we override Backbone a bit.
    putFragment : (success, error, fragment) ->
      success ?= @putSuccess
      error  ?= @putError

      # Ensure user.id is on all changeSets
      fragment = _.extend fragment, { user : @get('user') }

      @save({},{ 
          data        : JSON.stringify fragment 
          contentType : 'application/json'
          success     : success
          error       : error
        })
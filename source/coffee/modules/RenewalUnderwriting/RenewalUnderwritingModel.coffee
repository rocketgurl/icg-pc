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
  RenewalUnderwritingModel = BaseModel.extend

    # We will use traditional Backbone JSON sync + Basic Auth
    initialize : ->
      @use_backbone_auth()

    # **Assemble urls for Policiy Renewal Underwriting**  
    # @return _String_  
    url : ->
      "#{@get('urlRoot')}policies/#{@id}/underwriting"


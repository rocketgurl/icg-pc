define [
  'BaseModel'
], (BaseModel) ->

  # Referral Task
  # ====  
  # Referral Tasks for the queue collection
  #
  ReferralTaskModel = BaseModel.extend

    initialize : ->
      
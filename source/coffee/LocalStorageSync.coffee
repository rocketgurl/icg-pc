define [
  'jquery', 
  'underscore',
  'amplify_store'
], ($, _, amplify) ->

	LocalStorageSync = (method, model, options) ->
  	store = model.localStorage || model.collection.localStorage
  	switch method
  		when "read"
  			if model.id
  				resp = store.find(model) 
  			else 
  				resp = store.findAll()
  		when "create" then resp = store.create model
  		when "update" then resp = store.update model
  		when "delete" then resp = store.destroy model

  	if resp then options.success(resp) else options.error "Record not fonund"

  LocalStorageSync
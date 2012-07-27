define [
  'jquery', 
  'underscore',
  'amplify'
], ($, _, amplify) ->

	#### Sync adapter for localstorage
	#
	# Backbone.sync will use localStorage instead of hitting the server
	#
	# @param **name** _String_ name for your localStorage DB
	# 
	Store = (name) ->
		@name = name
		store = amplify.store(@name); # use Amplify to interface w/ storage
		@data = (store) || {}
		@

	_.extend Store.prototype, {

		# Generate primitive for GUID
		s4 : () ->
			(((1+Math.random())*0x10000)|0).toString(16).substring(1)

		# Generate GUID, used as a key in localstorage
		guid : () ->
			(@s4()+@s4()+"-"+@s4()+"-"+@s4()+"-"+@s4()+"-"+@s4()+@s4()+@s4())

		# Save the current state of the **Store** to *localStorage*.
		save : () ->
		  amplify.store(@name, @data)

		# Add a model, giving it a (hopefully)-unique GUID, if it doesn't already
		# have an id of it's own.
		create : (model) ->
	    if !model.id then model.set(model.idAttribute, @guid())
	    @data[model.id] = model
	    @save()
	    model

	  # Update a model by replacing its copy in `this.data`.
		update : (model) ->
	    @data[model.id] = model
	    @save()
	    model

	  # Retrieve a model from `this.data` by id.
	  find : (model) ->
	  	@data[model.id];

	  # Return the array of all models currently in storage.
	  findAll : () ->
	  	_.values this.data 

	  # Delete a model from `this.data`, returning it.
	  destroy : (model) ->
	    delete @data[model.id]
	    @save()
	    model
	}

	Store


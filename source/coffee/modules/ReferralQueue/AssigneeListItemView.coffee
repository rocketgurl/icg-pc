define [
  'backbone'
], (Backbone) ->

  class AssigneeListItemView extends Backbone.View

    tagName : 'li'

    className : 'list-group-item checkbox'

    template : _.template """
    <label><input type="checkbox"<% if (isChecked) { %> checked<% } %>> <%= identity %></label>
    """

    events :
      'change input[type=checkbox]' : 'updateModel'

    initialize : ->
      @render()

    render : ->
      data =
        identity  : @model.get 'identity'
        isChecked : @model.get @options.type
      @$el.html @template data
      this

    updateModel : (e) ->
      target = e.currentTarget
      if _.isBoolean target.checked
        if @options.type is 'active'
          @model.set 'active', target.checked
        else
          @model.set @options.type, target.checked, { silent : true }
          @model.setActiveAttribute()

    destroy : ->
      @off()
      @undelegateEvents()
      if @model
        @model.off()
      if @collection
        @collection.off()
      this
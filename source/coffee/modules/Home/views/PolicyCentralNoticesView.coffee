define [
  'BaseView'
  'marked'
], (BaseView, marked) ->

  class PolicyCentralNoticesView extends BaseView

    baseURL : '/'

    changesFile : 'CHANGES.md'

    initialize : ->
      _.bindAll this, 'renderNotices'
      xhr = $.get "#{@baseURL}#{@changesFile}"
      xhr.done @renderNotices

    renderNotices : (markdown) ->
      rawHTML = marked markdown
      @$('.panel-body').html rawHTML

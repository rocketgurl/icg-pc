define [
  'BaseView'
  'modules/PolicyQuickView/ActivityCollection'
], (BaseView, ActivityCollection) ->

  class ActivityView extends BaseView

    initialize : (options) ->
      notes = options.policyNotes
      evnts = options.policyEvents
      activities = notes.concat evnts
      @collection = new ActivityCollection activities
      @collection.each (activity) ->
        console.log activity.timeStamp, activity.type, activity.initiator
      # console.log this

    # TODO: Notes filter
    #   auxEvents: {
    #     'keyup .filter-typeahead input': 'lookup'
    #   },
 
    #   query: '',
 
    #   lookup: function (e) {
    #     var that = this;
    #     this.query = e.currentTarget.value;
    #     this.process(_.filter(this.options.data.attributes, function (item) {
    #       return that.matcher(item) || item.checked === 'checked';
    #     }));
    #   },
 
    #   process: function (items) {
    #     items = this.sorter(items);
    #     this.draw(items);
    #   },
 
    #   matcher: function (item) {
    #     return ~item.full_name.toLowerCase().indexOf(this.query.toLowerCase());
    #   },
 
    #   sorter: function (items) {
    #     var q = this.query, checked = [], begins = [], scase = [], icase = [];
    #     _.each(items, function (it) {
    #       var name = it.full_name;
    #       it.checked === 'checked' ? checked.push(it) :
    #         name.toLowerCase().indexOf(q.toLowerCase()) === 0 ? begins.push(it) :
    #         name.indexOf(q) !== -1 ? scase.push(it) :
    #         icase.push(it);
    #     });
    #     return checked.concat(begins, scase, icase);
    #   },
 
    #   highlighter: function (name, query) {
    #     if (query.replace(/[\[\]{}()*+?,\\\^$|#]/g, '\\$&')) {
    #       return name.replace(new RegExp('(' + query + ')', 'ig'), function ($1, match) {
    #         return '<strong>' + match + '</strong>';
    #       });
    #     }
    #   },
 
    #   draw: function (items) {
    #     this.$('.filter-opts').html(this.itemTemplate({
    #       items: items,
    #       showLabel: true,
    #       showPrice: false,
    #       showCount: false,
    #       query: this.query,
    #       highlighter: this.highlighter
    #     }));
    #   }
    # });

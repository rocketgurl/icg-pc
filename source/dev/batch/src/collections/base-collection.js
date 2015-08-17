import _ from 'underscore';
import Collection from 'ampersand-rest-collection';
import app from 'ampersand-app';

export default Collection.extend({
  initialize() {
    this.on('error', this._onXHRError);
  },

  query: function(attrs) {
    let options = this.options;
    if (attrs) _.extend(options.attrs, attrs);
    options.success = (resp) => {
      this.reset(resp, options);
      this.trigger('sync', this, resp, options);
    };
    options.error = (resp) => {
      this.trigger('error', this, resp, options);
    };
    return this.sync('create', this, options);
  },

  _onXHRError(collection, xhr) {
    const {status, statusText} = xhr;
    app.errors.add({status, statusText, xhr});
  }
});
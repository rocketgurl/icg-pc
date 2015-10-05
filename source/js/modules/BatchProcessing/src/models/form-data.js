import Model from 'ampersand-model';
import _ from 'underscore';
import app from 'ampersand-app';

export default Model.extend({
  url() {
    if (this.batchType) {
      return `/batch/icg/batch-processes/${this.batchType}`;
    } else {
      app.errors.add({
        error: 'Batch Type Not Set',
        exception: 'XMLHTTPRequestException',
        message: 'Fatal error: batchType value is missing',
        path: '/icg/batch-processes/${this.batchType}'
      });
    }
  },

  // set up the Auth header one time for all requests
  ajaxConfig() {
    return {
      headers: {
        'Authorization': app.user.getBasicAuth()
      }
    };
  },

  initialize() {
    this.options = {parse: true};
    this.batchType = null;
    this.body = null;

    // errors are pushed to an Errors collection
    this.on('error', this._onXHRError);
  },

  setBatchType(type) {
    this.batchType = type;
  },

  // sets the request body to a given data payload
  setBody(data) {
    this.body = data;
  },

  // Create options hash to match Collection.sync's requirements,
  // and post to the activiti api
  submit() {
    let options = {...this.options};
    options.attrs = this.body;
    options.success = (resp) => {
      if (!this.set(this.parse(resp, options), options)) return false;
      this.trigger('sync', this, resp, options);
    };
    options.error = (resp) => {
      this.trigger('error', this, resp, options);
    };
    return this.sync('create', this, options);
  },

  _onXHRError(collection, xhr) {
    const {response} = xhr;
    app.errors.add({...JSON.parse(response), xhr});
  }
});

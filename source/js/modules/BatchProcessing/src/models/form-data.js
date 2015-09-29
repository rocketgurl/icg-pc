import Model from 'ampersand-model';
import _ from 'underscore';
import app from 'ampersand-app';

export default Model.extend({
  url() {
    if (this.batchType) {
      return `/batch/icg/batch-processes/${this.batchType}`;
    }
    app.errors.add({
      status: 'Error',
      statusText: 'Batch type is not set!'
    });
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

  // will trim & split any values separated
  // by any number of whitespace chars
  splitRefsStr(str) {
    const trimmed = str.trim();
    const split = trimmed.split(/\s+/);
    return split;
  },

  // check an array of policy refs for any characters
  // other than alpha-numeric.
  // @returns an array of invalid refs with offending
  // chars bracketed. If all refs are valid, returns
  // an empty array
  validateRefs(refsArray) {
    const invalidChars = /[^A-Z0-9-]+/gi;
    const invalidRefs = []; 
    _.each(refsArray, ref => {
      if (invalidChars.test(ref)) {
        invalidRefs.push(ref.replace(invalidChars, $1 => {
          return `[${$1}]`;
        }));
      }
    });
    return invalidRefs;
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
    const {status, statusText} = xhr;
    app.errors.add({status, statusText, xhr});
  }
});

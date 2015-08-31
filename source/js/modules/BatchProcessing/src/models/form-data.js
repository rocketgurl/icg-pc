import Model from 'ampersand-model';
import _ from 'underscore';
import app from 'ampersand-app';

export default Model.extend({
  url: '/batch/form/form-data',

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
    this.parameters = {};
    this.properties = [];

    // errors are pushed to an Errors collection
    this.on('error', this._onXHRError);
  },

  setProcessDefinitionId(id) {
    this.parameters.processDefinitionId = id;
  },

  getProperty(id) {
    return _.find(this.properties, prop => {
      return id === prop.id;
    });
  },

  // add a property object to the properties array.
  // Properties should be unique, so if property
  // exists, overwrite it
  addProperty(id, value) {
    let property = this.getProperty(id);
    if (property) {
      property.value = value;
    } else {
      this.properties = this.properties || [];
      this.properties.push({id, value});
    }
  },

  // delete a specific property. Currently assumes
  // there is only one property of each name, and removes the
  // first instance of that property found.
  deleteProperty(id) {
    const index = _.findIndex(this.properties, prop => {
      return id === prop.id;
    });
    if (index > -1) this.properties.splice(index, 1);
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
    options.attrs = {...this.parameters};
    options.attrs.properties = [...this.properties];
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

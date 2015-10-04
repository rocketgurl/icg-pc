import _ from 'underscore';
import Collection from 'ampersand-rest-collection';
import app from 'ampersand-app';

export default Collection.extend({

  // set up the Auth header one time for all requests
  ajaxConfig() {
    return {
      headers: {
        'Authorization': app.user.getBasicAuth()
      }
    };
  },

  // calculate pagination properties
  parse(response) {
    this.pageStart  = response.start + 1;
    this.pageEnd    = response.start + response.size;
    this.totalItems = response.total;
    return response.data;
  },

  initialize() {
    this.options    = {}; // collection.sync options
    this.parameters = {}; // parameters passed in query
    this.variables  = []; // process variables for activiti
    this.pageStart  = 0;
    this.pageEnd    = 0;
    this.totalItems = 0;

    // errors are pushed to an Errors collection
    this.on('error', this._onXHRError);
  },

  // returns a copy of this.parameters to avoid
  // any other parts of the app mutating the options obj
  getParameters() {
    return {...this.parameters};
  },

  // update JSON parameter as defined by activi
  // http://www.activiti.org/userguide/#restHistoricProcessInstancesGet
  //
  // passing 'default' as the value will remove that query parameter
  // and will the result set will be determined by the defaults set
  // by the activiti api
  //
  // Note that process variables should be updated via `updateProcessVariables`
  updateParameter(name, value) {
    if (value === 'default') {
      this.parameters[name] = null;
    } else {
      this.parameters[name] = value;
    }
  },

  getProcessVariable(name) {
    return _.find(this.variables, v => {
      return name === v.name;
    });
  },

  addProcessVariable(name, operation, value) {
    this.variables.push({
      name, operation, value
    });
  },

  // update or add JSON variables as defined by activi
  // http://www.activiti.org/userguide/#_query_for_historic_process_instances
  updateProcessVariable(name, operation, value) {
    let variable = this.getProcessVariable(name);
    if (variable) {
      variable.operation = operation;
      variable.value = value;
    } else {
      this.addProcessVariable(name, operation, value);
    }
  },

  // delete a specific process variable. Currently assumes
  // there is only one variable of each name, and removes the
  // first instance of that variable found.
  deleteProcessVariable(name) {
    const index = _.findIndex(this.variables, v => {
      return name === v.name;
    });
    if (index > -1) this.variables.splice(index, 1);
  },

  // Create options hash to match Collection.sync's requirements, and
  // query the activiti api using a somewhat non-semantic 'create' (e.g. POST)
  // request per activiti's specifications defined at:
  // http://www.activiti.org/userguide/#_query_for_historic_process_instances
  query() {
    let options = {...this.options};
    options.attrs = {...this.parameters};
    options.attrs.variables = [...this.variables];
    options.success = (resp) => {
      this.reset(resp, options);
      this.trigger('sync', this, resp, options);
    };
    options.error = (resp) => {
      this.trigger('error', this, resp, options);
    };
    return this.sync('create', this, options);
  },

  incrementPage() {
    if (this.pageEnd < this.totalItems) {
      this.updateParameter('start', this.pageEnd);
      this.query();
    }
  },

  decrementPage() {
    const {start, size} = this.parameters;
    const pageStart = start - size;
    if (pageStart > -1) {
      this.updateParameter('start', pageStart);
      this.query();
    }
  },

  _onXHRError(collection, xhr) {
    const {status, statusText} = xhr;
    app.errors.add({status, statusText, xhr});
  }
});

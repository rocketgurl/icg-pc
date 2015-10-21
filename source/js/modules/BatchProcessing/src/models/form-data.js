import Model from 'ampersand-model';
import app from 'ampersand-app';

class FormData extends Model {
  constructor() {
    super();
    this.urlRoot = app.urlRoot;
    this.batchType = null;
    this.body = null;

    // errors are pushed to an Errors collection
    this.on('error', this._onXHRError);
  }

  url() {
    if (!this.batchType) {
      app.errors.add({
        error: 'Batch Type Not Set',
        status: 'BatchTypeException',
        exception: 'BatchTypeException',
        message: 'Fatal error: batchType value is missing',
        path: `/icg/batch-processes/${this.batchType}`
      });
    } else {
      return `${this.urlRoot}/icg/batch-processes/${this.batchType}`;
    }
  }

  // set up the Auth header one time for all requests
  ajaxConfig() {
    return {
      xhrFields: {
        timeout: 0 // override 5 second timeout
      },
      beforeSend(xhr) {
        xhr.setRequestHeader('Authorization', app.user.getBasic());
      }
    };
  }

  setBatchType(type) {
    this.batchType = type;
  }

  // sets the request body to a given data payload
  setBody(data) {
    this.body = data;
  }

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
  }

  _onXHRError(model, xhr) {
    app.errors.parseError(xhr);
  }
}

export default FormData;


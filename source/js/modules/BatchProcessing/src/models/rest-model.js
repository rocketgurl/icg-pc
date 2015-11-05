import Model from 'ampersand-model';
import app from 'ampersand-app';

class RestModel extends Model {
  constructor() {
    super();
    this.urlRoot = app.urlRoot;
    this.body = null;

    this.on({
      request: this._onRequest,
      error:   this._onXHRError,
      sync:    this._onSync
    });
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

  // sets the request body to a given data payload
  setBody(data) {
    this.body = data;
  }

  // Create options hash to match Collection.sync's requirements,
  // and post to the activiti api
  query() {
    let options = {...this.options};
    options.attrs = this.body;
    options.success = (resp) => {
      if (!this.set(this.parse(resp, options), options)) return false;
      this.trigger('sync', this, resp, options);
    };
    options.error = (resp) => {
      this.trigger('error', this, resp, options);
    };
    console.info(JSON.stringify(options));
    return this.sync('create', this, options);
  }

  _onRequest() {
    app.trigger('request');
  }

  _onSync() {
    app.trigger('complete');
  }

  // errors are pushed to an Errors collection
  _onXHRError(model, xhr) {
    this._onSync();
    app.errors.parseError(xhr);
  }
}

export default RestModel;


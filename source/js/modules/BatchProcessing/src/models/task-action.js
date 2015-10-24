import Model from 'ampersand-model';
import app from 'ampersand-app';

class TaskAction extends Model {
  constructor() {
    super();
    this.urlRoot = app.urlRoot;
    this.body = null;

    // errors are pushed to an Errors collection
    this.on('error', this._onXHRError);
  }

  url() {
    return `${this.urlRoot}/icg/batch-processes/tasks/`;
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

export default TaskAction;

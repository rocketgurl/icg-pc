import RestModel from './rest-model';
import app from 'ampersand-app';

class FormData extends RestModel {
  constructor() {
    super();
    this.batchType = null;
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

  setBatchType(type) {
    this.batchType = type;
  }

  // sets the request body to a given data payload
  setBody(data) {
    this.body = data;
  }
}

export default FormData;


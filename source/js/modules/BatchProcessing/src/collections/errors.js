import Collection from 'ampersand-collection';
import ErrorModel from '../models/error';
import {messages} from '../constants';

class Errors extends Collection {
  constructor() {
    super();
    this.model = ErrorModel;
    this.mainIndex = 'timestamp';
    this.on('add', this._onErrorAdd);
  }

  parseError(xhr) {
    const {headers, response, status, statusText, url} = xhr;
    try {
      if (/application\/json/.test(headers['content-type'])) {
        this.add({...JSON.parse(response)});
      } else if (status === 0) {
        this.add({
          status,
          error: statusText || 'No Response',
          exception: `(${status}) No Server Response`,
          message: messages.errors.xhr[0],
          path: url
        });
      } else {
        this.add({
          status,
          error: statusText,
          exception: `(${status}) ${statusText}`,
          message: messages.errors.xhr.DEFAULT,
          path: url
        });
      }
    } catch (ex) {
      console.error(ex);
    }
  }

  _onErrorAdd(model) {
    console.info(JSON.stringify(model.serialize()));
  }
}

export default Errors;

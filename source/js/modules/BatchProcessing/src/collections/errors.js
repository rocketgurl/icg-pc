import Collection from 'ampersand-rest-collection';
import ErrorModel from '../models/error';

class Errors extends Collection {
  constructor() {
    super();
    this.mainIndex = 'timestamp';
    this.on('add', this._onErrorAdd);
  }

  parseError(xhr) {
    const {ajaxSettings, headers, response, status, statusCode, statusText} = xhr;
    const contentType = headers['content-type'];
    try {
      if (/application\/json/.test(contentType)) {
        this.add({...JSON.parse(response)});
      } else if (statusCode === 0) {
        this.add({
          status: statusCode,
          error: statusText || 'No Response',
          exception: `(${statusCode}) No Server Response`,
          message: `The server is currently unresponsive. Please contact
the help desk if the problem persists.`,
          path: ajaxSettings.url
        });
      } else {
        this.add({
          status,
          error: statusText,
          exception: `(${statusCode}) ${statusText}`,
          message: `The server is temporarily unable to service your request
due to maintenance downtime or capacity problems. Please contact the help
desk if the problem persists.`,
          path: ajaxSettings.url
        });
      }
    } catch (ex) {
      console.error(ex);
    }
  }

  _onErrorAdd(model) {
    console.info(`error: ${model.error}
status: ${model.status}
exception: ${model.exception}
message: ${model.message}
path: ${model.path}
    `);
  }
}

export default Errors;

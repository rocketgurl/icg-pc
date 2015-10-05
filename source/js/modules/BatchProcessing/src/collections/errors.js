import Collection from 'ampersand-rest-collection';
import ErrorModel from '../models/error';

class Errors extends Collection {
  constructor() {
    super();
    this.mainIndex = 'timestamp';
    this.on('add', this._onErrorAdd);
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

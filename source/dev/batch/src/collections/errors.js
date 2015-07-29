import Collection from 'ampersand-rest-collection';
import ErrorModel from '../models/error';

export default Collection.extend({
  mainIndex: 'timestamp',

  model: ErrorModel,

  initialize() {
    this.on('add', this._onErrorAdd);
  },

  _onErrorAdd(data, ...args) {
    console.error(data.status, data.statusText, data, ...args);
  }
});

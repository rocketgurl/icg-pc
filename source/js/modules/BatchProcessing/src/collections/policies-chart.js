import {pick} from 'underscore';
import Collection from 'ampersand-collection';
import Task from '../models/task';

const CHANGE_EVENT = 'change';

export default Collection.extend({
  url: './public/models/policies.json',

  getData(...keys) {
    if (keys.length) {
      return this.pick(...keys);
    } else {
      return this.serialize();
    }
  },

  pick(...keys) {
    return this.map(d => {
      return pick(d, 'date', ...keys); // always return the date prop
    });
  }
});

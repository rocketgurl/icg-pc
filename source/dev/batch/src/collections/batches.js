import _ from 'underscore';
import Collection from 'ampersand-rest-collection';
import Batch from '../models/batch';

export default Collection.extend({
  model: Batch,

  url: '/batch/history/historic-process-instances',

  parse(response) {
    this.size     = response.size;
    this.order    = response.order;
    this.sortProp = response.sort;
    this.total    = response.total;
    this.start    = response.start;
    return response.data;
  }
});

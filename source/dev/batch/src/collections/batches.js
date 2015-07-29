import _ from 'underscore';
import BaseCollection from './base-collection';
import BatchModel from '../models/batch';

export default BaseCollection.extend({
  model: BatchModel,

  url: '/batch/query/historic-process-instances',

  ajaxConfig() {
    return {
      headers: {
        'Authorization': 'Basic ZGV2QGljZzM2MC5jb206bW92aWVMdW5jaGVzRlRXMjAxNQ=='
      }
    };
  },

  options: {
    parse: true,
    attrs: {}
  },

  parse(response) {
    this.total = response.total;
    return response.data;
  }
});

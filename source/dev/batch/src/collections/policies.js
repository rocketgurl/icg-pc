import _ from 'underscore';
import BaseCollection from './base-collection';
import PolicyModel from '../models/policy';

export default BaseCollection.extend({
  model: PolicyModel,

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
    attrs: {
      start: 0,
      size: 50,
      sort: 'startTime',
      order: 'desc',
      includeProcessVariables: true,
      variables: [{
        name: 'batchId', // HACK: This should only return "policy" processes
        operation: 'greaterThanOrEquals',
        value: "0"
      }]
    }
  },

  parse(response) {
    _.extend(this.options.attrs, {
      order: response.order,
      size: response.size,
      sort: response.sort,
      start: response.start
    });
    this.total = response.total;
    return response.data;
  }
});

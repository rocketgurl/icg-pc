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

  parse(response) {
    this.total = response.total;
    return response.data;
  },

  initialize() {
    this.options = {
      parse: true,
      attrs: {
        start: 0,
        size: 50,
        sort: 'startTime',
        order: 'desc',
        includeProcessVariables: true,

        // HACK: This default query should
        // return all "non-batch" processes
        variables: [{
          name: 'batchId',
          operation: 'notEquals',
          value: '0'
        }]
      }
    };
  },

  // If this collection has a parent batch model
  // this method will be invoked to update the
  // batchId in the query variables.
  setBatchId(batchId) {
    this.options.attrs.variables = [{
      name: 'batchId',
      operation: 'equals',
      value: batchId
    }]
  }
});

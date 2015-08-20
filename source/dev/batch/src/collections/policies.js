import _ from 'underscore';
import BaseCollection from './base-collection';
import PolicyModel from '../models/policy';

export default BaseCollection.extend({
  model: PolicyModel,

  url: '/batch/query/historic-process-instances',

  parse(response) {
    this.total = response.total;
    return response.data;
  },

  initialize() {
    this.options = {parse: true};
    this.parameters = {
      start: 0,
      size: 50,
      sort: 'startTime',
      order: 'desc',
      includeProcessVariables: true
    };

    // HACK: This default query should
    // return all "non-batch" processes
    this.variables = [{
      name: 'batchId',
      operation: 'notEquals',
      value: '0'
    }];
  },

  // If this collection has a parent batch model
  // this method will be invoked once by the model
  // to update the batchId in the query variables.
  setBatchId(batchId) {
    this.updateProcessVariable('batchId', 'equals', batchId);
  }
});

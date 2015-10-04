import _ from 'underscore';
import BaseCollection from './base-collection';
import PolicyModel from '../models/policy';

export default BaseCollection.extend({
  model: PolicyModel,

  url: '/batch/query/historic-process-instances',

  initialize() {
    this.options = {parse: true};
    this.parameters = {
      start: 0,
      size: 25,
      sort: 'startTime',
      order: 'desc',
      includeProcessVariables: true
    };
    this.pageStart  = 0; // these props are calculated on
    this.pageEnd    = 0; // successful response in the parse
    this.totalItems = 0; // method of the BaseCollection

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

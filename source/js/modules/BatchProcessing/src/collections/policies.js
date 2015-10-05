import BaseCollection from './base-collection';
import PolicyModel from '../models/policy';

class Policies extends BaseCollection {
  constructor() {
    super();

    this.url = '/batch/query/historic-process-instances';
    this.model = PolicyModel;

    // HACK: This default query should
    // return all "non-batch" processes
    this.variables = [{
      name: 'batchId',
      operation: 'notEquals',
      value: '0'
    }];
  }

  // If this collection has a parent batch model
  // this method will be invoked once by the model
  // to update the batchId in the query variables.
  setBatchId(batchId) {
    this.updateProcessVariable('batchId', 'equals', batchId);
  }
}

export default Policies;

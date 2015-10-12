import BaseCollection from './base-collection';
import TaskModel from '../models/task';

class Tasks extends BaseCollection {
  constructor() {
    super();

    this.url = '/batch/query/historic-process-instances';
    this.model = TaskModel;

    // This default query should return all "non-batch" processes
    this.variables = [{
      name: 'isBatchInstance',
      operation: 'equals',
      value: false
    }];
  }

  // If this collection has a parent batch model
  // this method will be invoked once by the model
  // to update the batchId in the query variables.
  setBatchId(batchId) {
    if (batchId !== '0')
      this.updateProcessVariable('batchId', 'equals', batchId);
  }

  // enables filtering by the derived status of a task
  filterByStatus(status) {
    this.status = status;
    switch (status) {
      case 'end-success':
        this.updateParameter('finished', true);
        this.updateProcessVariable('hasException', 'equals', false);
        break;
      case 'end-error':
        this.updateParameter('finished', true);
        this.updateProcessVariable('hasException', 'equals', true);
        break;
      case 'action-required':
        this.updateParameter('finished', false);
        this.updateProcessVariable('hasException', 'equals', true);
        break;
      case 'in-progress':
        this.updateParameter('finished', false);
        this.updateProcessVariable('hasException', 'equals', false);
        break;
      case 'default':
        this.updateParameter('finished', 'default');
        this.deleteProcessVariable('hasException');
        break;
    }
    this.query();
  }
}

export default Tasks;

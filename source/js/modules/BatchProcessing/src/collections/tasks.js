import BaseCollection from './base-collection';
import TaskModel from '../models/task';
import _ from 'underscore';

class Tasks extends BaseCollection {
  url() {
    return `${this.urlRoot}/query/historic-process-instances`;
  }

  constructor() {
    super();

    this.model    = TaskModel;
    this.status   = 'default';
    this.assignee = 'default';

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

  filterByAssignee(assignee) {
    this.assignee = assignee;
    if (assignee === 'default') {
      this.deleteProcessVariable('currentAssignee');
    } else {
      this.updateProcessVariable('currentAssignee', 'equals', assignee);
    }
  }

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
  }
}

export default Tasks;

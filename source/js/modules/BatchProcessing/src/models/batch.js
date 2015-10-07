import BaseModel from './base-model';
import JobsCollection from '../collections/jobs';

export default BaseModel.extend({
  props: {
    id: 'string',
    batchType: 'string',
    businessKey: 'string',
    deleteReason: 'string',
    durationInMillis: 'number',
    endActivityId: 'string',
    endTime: 'string',
    numberOfInstances: 'number',
    numberOfActiveInstances: 'number',
    numberOfErrorInstances: 'number',
    numberOfSuccessInstances: 'number',
    processDefinitionId: 'string',
    processDefinitionUrl: 'string',
    startActivityId: 'string',
    startTime: 'string',
    startUserId: 'string',
    superProcessInstanceId: 'string',
    tenantId: 'string',
    variables: 'array'
  },

  derived: {
    type: {
      deps: ['batchType'],
      fn: function deriveType() {
        return this.batchType.replace('batch', '');
      }
    },

    // derive a status label from the given information
    // className corresponds to the bootstrap 3 label classes
    status: {
      deps: ['numberOfInstances', 'numberOfSuccessInstances', 'numberOfErrorInstances'],
      fn: function deriveStatus() {
        const {
          numberOfInstances,
          numberOfErrorInstances,
          numberOfSuccessInstances} = this;
        if (numberOfSuccessInstances === numberOfInstances) {
          return 'finished-success';
        }
        if (numberOfSuccessInstances +
          numberOfErrorInstances === numberOfInstances) {
          return 'finished-error';
        }
        return 'in-progress';
      }
    }
  },

  // initializes the associated jobs collection,
  // and updates the batchId query variable
  initialize() {
    this.jobs = new JobsCollection();
    this.jobs.setBatchId(this.id);
  }
});
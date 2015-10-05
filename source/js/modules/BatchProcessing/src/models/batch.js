import BaseModel from './base-model';
import PoliciesCollection from '../collections/policies';

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
    status: {
      // derive a status label from the given information
      // className corresponds to the bootstrap 3 label classes
      fn: function deriveStatus() {
        const {
          numberOfInstances,
          numberOfActiveInstances,
          numberOfErrorInstances,
          numberOfSuccessInstances} = this;
        if (numberOfSuccessInstances === numberOfInstances) {
          return {
            className: 'label label-success',
            message: `FINISHED: ${numberOfSuccessInstances} out of ${numberOfInstances} successfully run`
          };
        } else if (numberOfSuccessInstances +
          numberOfErrorInstances === numberOfInstances) {
          return {
            className: 'label label-danger',
            message: `FINISHED: ${numberOfErrorInstances} out of ${numberOfInstances} failed`
          };
        } else {
          return {
            className: 'label label-warning',
            message: `IN PROGRESS: ${numberOfSuccessInstances} out of ${numberOfInstances} successfully run`
          };
        }
      }
    }
  },

  // initializes the associated policies collection,
  // and updates the batchId query variable
  initialize() {
    this.policies = new PoliciesCollection();
    this.policies.setBatchId(this.id);
  }
});
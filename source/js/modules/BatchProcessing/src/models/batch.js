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

  // initializes the associated policies collection,
  // and updates the batchId query variable
  initialize() {
    this.policies = new PoliciesCollection();
    this.policies.setBatchId(this.id);
  }
});
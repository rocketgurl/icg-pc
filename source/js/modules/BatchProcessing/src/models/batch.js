import BaseModel from './base-model';
import PoliciesCollection from '../collections/policies';

export default BaseModel.extend({
  props: {
    id: 'string',
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
      deps: ['processDefinitionId'],
      fn: function () {
        const processDefinitionKey = this.processDefinitionId.split(':')[0];
        return processDefinitionKey.replace('batch', '');
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
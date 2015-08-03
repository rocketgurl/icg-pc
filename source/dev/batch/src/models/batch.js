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
    processDefinitionKey: {
      deps: ['processDefinitionId'],
      fn: function () {
        return this.processDefinitionId.split(':')[0];
      }
    },
    numPolicyRefs: {
      fn: function () {
        const numRefs = this.findVariableWhere({name: 'numPolicyRefs'});
        return numRefs && numRefs.value;
      }
    }
  },

  // updates the batchId query variable
  initialize() {
    this.policies = new PoliciesCollection();
    this.policies.setBatchId(this.id);
  }
});
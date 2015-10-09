import BaseModel from './base-model';

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
    batchId: {
      fn: function deriveBatchId() {
        return this.getVariableValue('batchId');
      }
    },
    errorCode: {
      fn: function deriveErrorCode() {
        return this.getVariableValue('errorCode');
      }
    },
    errorMessage: {
      fn: function deriveErrorMessage() {
        return this.getVariableValue('errorMessage');
      }
    },
    errorResponse: {
      fn: function deriveErrorResponse() {
        return this.getVariableValue('errorResponse');
      }
    },
    hasException: {
      fn: function deriveHasException() {
        return this.getVariableValue('hasException');
      }
    },
    policyLookup: {
      fn: function derivePolicyLookup() {
        return this.getVariableValue('policyLookup');
      }
    },
    processDefinitionKey: {
      deps: ['processDefinitionId'],
      fn: function () {
        return this.processDefinitionId.split(':')[0];
      }
    },

    // derive a status label from the given information
    // className corresponds to the bootstrap 3 label classes
    status: {
      deps: ['endActivityId'],
      fn: function deriveStatus() {
        const {endActivityId} = this;
        const hasException = this.getVariableValue('hasException');
        if (endActivityId === 'endEvent') {
          return 'end-success';
        }
        if (endActivityId === 'endEventError') {
          return 'end-error';
        }
        if (!endActivityId && hasException === true) {
          return 'action-required';
        }
        if (!endActivityId && hasException === false) {
          return 'in-progress';
        }
        return 'started';
      }
    }
  }
});
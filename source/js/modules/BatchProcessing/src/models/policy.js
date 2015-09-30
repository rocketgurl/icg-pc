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
      fn: function () {
        return this.getVariableValue('batchId');
      }
    },
    errorCode: {
      fn: function () {
        return this.getVariableValue('errorCode');
      }
    },
    errorMessage: {
      fn: function () {
        return this.getVariableValue('errorMessage');
      }
    },
    errorResponse: {
      fn: function () {
        return this.getVariableValue('errorResponse');
      }
    },
    hasException: {
      fn: function () {
        return this.getVariableValue('hasException');
      }
    },
    policyLookup: {
      fn: function () {
        return this.getVariableValue('policyLookup');
      }
    },
    processDefinitionKey: {
      deps: ['processDefinitionId'],
      fn: function () {
        return this.processDefinitionId.split(':')[0];
      }
    },
    status: {
      // derive a status label from the given information
      // className corresponds to the bootstrap 3 label classes
      fn: function deriveStatus() {
        if (this.endActivityId === 'endEvent') {
          return {
            className: 'label label-success',
            message: 'SUCCESS: COMPLETE'
          };
        } else if (this.endActivityId === 'endEventError') {
          return {
            className: 'label label-danger',
            message: 'ERROR: COMPLETE'
          };
        } else if (this.endActivityId === null && this.getVariableValue('hasException')) {
          return {
            className: 'label label-warning',
            message: 'ERROR: ACTION NEEDED'
          }
        } else {
          return {
            className: 'label label-info',
            message: 'IN PROGRESS'
          };
        }
      }
    }
  }
});
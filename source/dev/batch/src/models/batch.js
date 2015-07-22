import Model from 'ampersand-model';
import _ from 'underscore';

export default Model.extend({
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
        return this.processDefinitionId.split(':')[0]
      }
    },
    numPolicyRefs: {
      fn: function () {
        const numRefs = _.findWhere(this.variables, {name: 'numPolicyRefs'});
        console.log(numRefs)
        return numRefs.value;
      }
    }
  },

  initialize() {
    console.log(this.processDefinitionId, this)
  }
});
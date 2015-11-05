import Collection from 'ampersand-collection';
import moment from 'moment';
import {isString} from 'underscore';
import {constants} from 'ampersand-app';

class SelectedTasks extends Collection {
  getCurrentTaskIds() {
    return this.map(model => {
      return model.currentTaskId;
    });
  }

  getProcessDefinitionKeys() {
    return this.map(model => {
      return model.processDefinitionKey;
    });
  }

  getValsForKey(key) {
    return this.map(model => {
      let val = model[key];
      if (isString(val)) {
        return val.trim();
      }
      return val || 'null';
    });
  }

  getPaymentsData() {
    return this.map(model => {
      return {
        policyNumberBase: model.policyNumberBase,
        origPolicyNumberBase: model.origPolicyNumberBase,
        amount: model.getVariableValue('amount'),
        method: model.getVariableValue('method'),
        receivedDate: moment(model.getVariableValue('receivedDate')).format(constants.dates.SYSTEM_FORMAT),
        referenceNum: model.getVariableValue('referenceNum'),
        lockBoxReference: model.getVariableValue('lockBoxReference')
      };
    });
  }
}

export default SelectedTasks;

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

  getPolicyLookups() {
    return this.map(model => {
      let policyLookup = model.policyLookup || '';
      if (isString(policyLookup)) {
        return policyLookup.trim();
      }
      return model.policyLookup;
    });
  }

  getPaymentsData() {
    return this.map(model => {
      return {
        policyNumberBase: model.policyLookup,
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

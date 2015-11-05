import Model from 'ampersand-model';
import {findWhere, isObject} from 'underscore';

export default Model.extend({
  findVariableWhere(properties) {
    if (this.variables) {
      return findWhere(this.variables, properties);
    }
  },

  getVariableValue(name) {
    const variableObj = this.findVariableWhere({name});
    if (isObject(variableObj)) {
      return variableObj.value;
    }
    return null;
  }
});

import Model from 'ampersand-model';
import _ from 'underscore';

export default Model.extend({
  findVariableWhere(properties) {
    if (this.variables) {
      return _.findWhere(this.variables, properties);
    }
  },

  getVariableValue(name) {
    const variableObj = this.findVariableWhere({name});
    if (_.isObject(variableObj)) {
      return variableObj.value;
    }
    return null;
  }
});

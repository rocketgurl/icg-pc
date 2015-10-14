import _ from 'underscore';

const validators = {
  validatePolicyNum(policyNum) {
    const validPattern = /^[a-z]{3}\d{7,9}$/i;
    if (!validPattern.test(policyNum)) {
      return `Error: ${policyNum} does not match the pattern ABC0123456`;
    }
    return policyNum;
  },

  validateString(str="", type="", invalid=/[]/) {
    str = str.trim();
    if (str.length === 0) {
      return `Error: ${type} value is empty`;
    }
    if (invalid.test(str)) {
      str = str.replace(invalid, $1 => {
        return `[${$1}]`
      });
      return `Error: Invalid chars in ${type}: ${str}`;
    }
    return str;
  }
};

export default validators;


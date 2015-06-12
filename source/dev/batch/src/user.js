import _ from 'underscore';

const userJSON = window.sessionStorage.getItem('user');
const user = JSON.parse(userJSON) || {};

function validate() {
  if (!_.has(user, 'digest') ||
      !_.has(user, 'email') ||
      !_.has(user, 'name') ||
      !_.has(user, 'username')) {
    document.location = '/#login';
  }
  return user;
}

user.validate = validate;

export default user;
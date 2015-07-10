import _ from 'underscore';
import Cookie from './lib/cookie';

const cookie = new Cookie();
const token  = cookie.get('ics360_PolicyCentral') || '';

const userJSON = window.sessionStorage.getItem('user');
const user = JSON.parse(userJSON) || {};

function validate() {
  if (!token.length ||
      !_.has(user, 'digest') ||
      !_.has(user, 'email') ||
      !_.has(user, 'name') ||
      !_.has(user, 'username')) {
    document.location = '/#login';
  }
  return user;
}

user.validate = validate;

export default user;
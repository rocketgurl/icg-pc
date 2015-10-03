import _ from 'underscore';
import Cookie from './lib/cookie';

const cookie = new Cookie();
const token  = 'ZGV2QGljZzM2MC5jb206bW92aWVMdW5jaGVzRlRXMjAxNQ=' // cookie.get('ics360_PolicyCentral') || '';

const userJSON = window.sessionStorage.getItem('user');
let user = JSON.parse(userJSON) || {};

function getBasicAuth() {
  return `Basic ${token}`;
}

function validate() {
  if (!token.length ||
      !_.has(user, 'email') ||
      !_.has(user, 'name') ||
      !_.has(user, 'username')) {
    document.location = '/#login';
  }
  return {
    getBasicAuth,
    name: user.name,
    username: user.username,
    email: user.email
  };
}

user.validate = validate;

export default user;

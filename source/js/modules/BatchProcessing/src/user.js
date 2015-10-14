import _ from 'underscore';
import Cookie from './lib/cookie';

// Login relies on the token cookie set by Policy Central
const cookie = new Cookie();
const str    = cookie.get('ics360_PolicyCentral') || '';

// Some details about the user have
// hopefully been persisted to session storage
const userJSON = window.sessionStorage.getItem('user');
const user = JSON.parse(userJSON) || {};

function User(name) {this.name = name}
User.prototype.getBasic = function () {return `Basic ${str}`};

// no token, no login
function validate() {
  if (!str.length) {
    document.location = '/#login';
    return null;
  }
  return new User(user.name || user.username || user.email); // attempt to derive some kind of username
}

export default {validate};

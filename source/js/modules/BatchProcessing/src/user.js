import {Cookie} from './lib';

// Login relies on the token cookie set by Policy Central
const cookie = new Cookie();
const str    = cookie.get('ics360_PolicyCentral') || '';

// Some details about the user should have been
// persisted to session storage from policy central
const userJSON = window.sessionStorage.getItem('user');
const user = JSON.parse(userJSON) || {};

function User(name) {this.name = name}
User.prototype.getBasic = function getBasic() { return `Basic ${str}` };

// no token, no login
function validateUser() {
  if (!str.length) {
    document.location = '/#login';
    return null;
  }
  return new User(user.name || user.username || user.email); // attempt to derive some kind of username
}

export default validateUser;

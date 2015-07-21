import app from 'ampersand-app';
import user from './user';
import Router from './router';
import PoliciesCollection from './collections/policies';
import BatchesCollection from './collections/batches';

const userNameNode = document.getElementById('user-name');

app.extend({
  init() {
    this.user = user.validate();
    this.batches = new BatchesCollection();
    this.policies = new PoliciesCollection();
    this.policies.fetch();
    this.router = new Router({});
    this.router.history.start({
      pushState: false,
      root: '/dev/batch/'
    });
    userNameNode.textContent = user.name;
    return this;
  }
});

window.app = app.init();
import app from 'ampersand-app';
import user from './user';

app.extend({
  init() {
    // this.me = new Me()
    // this.me.fetchAll()
    // this.router = new Router()
    // this.router.history.start()
    return this;
  }
});

window.app = app.init();
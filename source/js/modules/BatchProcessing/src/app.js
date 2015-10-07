import app from 'ampersand-app';
import user from './user';
import Router from './router';
import ErrorsCollection from './collections/errors';
import BatchesCollection from './collections/batches';
import JobsCollection from './collections/jobs';
import FormDataModel from './models/form-data';

const userNameNode = document.getElementById('user-name');

app.extend({
  init() {
    this.user = user.validate();
    this.errors = new ErrorsCollection();
    this.batches = new BatchesCollection();
    this.allJobs = new JobsCollection();
    this.formData = new FormDataModel();
    this.router = new Router({});
    this.router.history.start({
      pushState: false,
      root: '/batch-processing/'
    });
    userNameNode.textContent = user.name;
    return this;
  }
});

window.app = app.init();
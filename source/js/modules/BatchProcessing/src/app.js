import app from 'ampersand-app';
import user from './user';
import Router from './router';
import ErrorsCollection from './collections/errors';
import BatchesCollection from './collections/batches';
import TasksCollection from './collections/tasks';
import FormDataModel from './models/form-data';

const userNameNode = document.getElementById('user-name');

app.extend({
  init() {
    this.user = user.validate();
    this.urlRoot = 'https://stage-sagesure-svc.icg360.org/cru-4/batch';
    this.errors = new ErrorsCollection();
    this.batches = new BatchesCollection();
    this.allTasks = new TasksCollection();
    this.formData = new FormDataModel();
    this.router = new Router({});
    this.router.errors = this.errors;
    this.router.history.start({
      pushState: false,
      root: '/batch-processing/'
    });
    userNameNode.textContent = this.user.name;
    return this;
  }
});

window.app = app.init();

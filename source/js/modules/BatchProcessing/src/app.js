import {version} from '../package.json';
import app from 'ampersand-app';
import constants from './constants';
import user from './user';
import Router from './router';
import ErrorsCollection from './collections/errors';
import BatchesCollection from './collections/batches';
import TasksCollection from './collections/tasks';
import FormDataModel from './models/form-data';

const userNameNode = document.getElementById('user-name');
const versionNode  = document.getElementById('version-number');

app.extend({
  init() {
    this.user = user.validate();
    this.VERSION = version;
    this.constants = constants;
    this.errors = new ErrorsCollection();
    this.batches = new BatchesCollection();
    this.allTasks = new TasksCollection();
    this.activeTasks = new TasksCollection();
    this.formData = new FormDataModel();
    this.router = new Router({});
    this.router.errors = this.errors;
    this.router.history.start({
      pushState: false,
      root: '/batch-processing/'
    });
    userNameNode.textContent = this.user.name;
    versionNode.textContent = version;
    return this;
  }
});

window.app = app.init();

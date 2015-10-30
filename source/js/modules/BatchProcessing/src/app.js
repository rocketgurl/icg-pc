import {version} from '../package.json';
import app from 'ampersand-app';
import constants from './constants';
import validateUser from './user';
import getUrlRoot from './url';
import Router from './router';
import ErrorsCollection from './collections/errors';
import BatchesCollection from './collections/batches';
import TasksCollection from './collections/tasks';
import SelectedTasksCollection from './collections/selected-tasks';
import FormDataModel from './models/form-data';
import TaskActionModel from './models/task-action';
import ApiVersionModel from './models/api-version';

const {APP_PATH, STAGE_BASE, PROD_BASE} = constants;
const apiVersionModel = new ApiVersionModel();

app.extend(window.app, {
  init() {
    this.user = validateUser();
    this.urlRoot = getUrlRoot(this.ENV, APP_PATH, STAGE_BASE, PROD_BASE);
    this.VERSION = version;
    this.constants = constants;
    this.errors = new ErrorsCollection();
    this.batches = new BatchesCollection();
    this.allTasks = new TasksCollection();
    this.selectedTasks = new SelectedTasksCollection();
    this.formData = new FormDataModel();
    this.taskAction = new TaskActionModel();
    this.router = new Router();
    this.router.errors = this.errors;
    this.router.history.start({
      pushState: false,
      root: '/batch-processing/'
    });
    this.noop = function () {};

    this.listenTo(apiVersionModel, 'change:version', this.writeApiVersion);
    apiVersionModel.fetch();

    return this;
  },

  writeApiVersion(model, apiVersion) {
    document.getElementById('api-version').textContent = apiVersion;
    app.API_VERSION = apiVersion;
  }
});

window.app = app.init();
document.getElementById('user-name').textContent = app.user.name;
document.getElementById('ui-version').textContent = version;

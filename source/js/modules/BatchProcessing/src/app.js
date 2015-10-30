import React from 'react';
import ReactDOM from 'react-dom';
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
import HeaderNavbar from './components/header-navbar';
import HeaderAdmin from './components/header-admin';
import Footer from './components/footer';

app.extend(window.app, {
  init() {
    const {APP_PATH, STAGE_BASE, PROD_BASE} = constants;
    this.user = validateUser();
    this.urlRoot = getUrlRoot(this.ENV,
      APP_PATH, STAGE_BASE, PROD_BASE);
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
    return this;
  },

  getApiVersion() {
    const apiVersionModel = new ApiVersionModel();
    this.listenToOnce(apiVersionModel, 'change:version', (model, apiVersion) => {
        this.API_VERSION = apiVersion;
        this.footer();
    });
    apiVersionModel.fetch();
    return this;
  },

  headerNavbar() {
    ReactDOM.render(<HeaderNavbar/>,
      document.getElementById('header-navbar'));
    return this;
  },

  headerAdmin() {
    ReactDOM.render(<HeaderAdmin userName={this.user.name}/>,
      document.getElementById('header-admin'));
    return this;
  },

  footer() {
    ReactDOM.render(<Footer apiVersion={this.API_VERSION} uiVersion={this.VERSION}/>,
      document.getElementById('footer-main'));
    return this;
  }
});

window.app = app.init()
                .getApiVersion()
                .headerNavbar()
                .headerAdmin()
                .footer();



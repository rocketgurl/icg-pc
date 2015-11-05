import app from 'ampersand-app';
import RestModel from './rest-model';

class TaskAction extends RestModel {
  constructor() {
    super();
  }

  url() {
    return `${this.urlRoot}/icg/batch-processes/tasks/`;
  }
}

export default TaskAction;


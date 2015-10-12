import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

export default Router.extend({
  routes: {
    ''                         : 'main',
    'batches'                  : 'batches',
    'tasks'                    : 'tasks',
    'tasks/bid/:bid'           : 'tasks',
    'batch-action/:type/:name' : 'batchActionModal',
    '*notFound'                : 'notFound'
  },

  main(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.main({tab: 'batches'});
  },

  tasks(batchId) {
    const activeBatchId = batchId ? `${batchId}` : '0'; // default to id '0', which is all the tasks
    this.main({activeBatchId, tab: 'tasks'});
  },

  batchActionModal(batchType, actionName) {
    actionName = decodeURIComponent(actionName);
    this.main({
      actionName,
      batchType,
      showBatchActionModal: true
    });
  },

  notFound(route) {
    this.errors.add({
      error: 'Route Not Found',
      status: 'NotFound',
      exception: null,
      message: `"#${route}" not match any known route.`,
      path: `#${route}`
    });
  }
});

import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

export default Router.extend({
  routes: {
    ''                         : 'main',
    'batches'                  : 'batches',
    'jobs'                     : 'jobs',
    'jobs/bid/:bid'            : 'jobs',
    'batch-action/:type/:name' : 'batchActionModal',
    '*notFound'                : 'notFound'
  },

  main(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.main({tab: 'batches'});
  },

  jobs(batchId) {
    const activeBatchId = batchId ? `${batchId}` : '0'; // default to id 0, which is all the jobs
    this.main({activeBatchId, tab: 'jobs'});
  },

  batchActionModal(batchType, actionName) {
    actionName = decodeURIComponent(actionName);
    this.main({
      actionName,
      batchType,
      showBatchActionModal: true
    });
  },

  notFound() {
    console.log('NOT FOUND');
  }
});

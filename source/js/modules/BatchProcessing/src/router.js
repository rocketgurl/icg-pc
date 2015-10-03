import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

export default Router.extend({
  routes: {
    ''                         : 'main',
    'batches'                  : 'batches',
    'policies'                 : 'policies',
    'policies/bid/:bid'        : 'policies',
    'batch-action/:type/:name' : 'batchActionModal',
    '*notFound'                : 'notFound'
  },

  main(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.main({tab: 'batches'});
  },

  policies(batchId) {
    const activeBatchId = batchId ? `${batchId}` : '0'; // default to id 0, which is all the policies
    this.main({activeBatchId, tab: 'policies'});
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

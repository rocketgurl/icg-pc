import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

export default Router.extend({
  routes: {
    ''                         : 'main',
    'batches'                  : 'batches',
    'policies'                 : 'policies',
    'policies/?*params'        : 'policies',
    'batch-action/:type/:name' : 'batchActionModal',
    '*notFound'                : 'notFound'
  },

  main(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.main({tab: 'batches'});
  },

  policies(params) {
    const {bid} = deparam(params);
    const activeBatchId = bid ? `${bid}` : '0';
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

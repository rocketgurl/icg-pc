import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

let activeBatchId = '0';

export default Router.extend({
  routes: {
    ''                  : 'main',
    'batches'           : 'batches',
    'policies'          : 'policies',
    'policies/?*params' : 'policies',
    'batch-action/*id'  : 'batchActionModal',
    '*notFound'         : 'notFound'
  },

  main(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.main({tab: 'batches'});
  },

  policies(params) {
    const {bid} = deparam(params);
    if (bid) activeBatchId = bid + '';
    this.main({activeBatchId, tab: 'policies'});
  },

  batchActionModal(processDefinitionId) {
    this.main({
      processDefinitionId,
      showBatchActionModal: true
    });
  },

  notFound() {
    console.log('NOT FOUND');
  }
});

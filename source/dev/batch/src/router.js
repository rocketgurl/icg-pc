import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';
import {deparam} from 'node-qs-serialization';

let activeBatchId = '0';

export default Router.extend({
  routes: {
    ''                  : 'batches',
    'batches'           : 'batches',
    'policies'          : 'policies',
    'policies/?*params' : 'policies',
    '*notFound'         : 'notFound'
  },

  actuateTab(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.actuateTab({tab: 'batches'});
  },

  policies(params) {
    const {bid} = deparam(params);
    if (bid) activeBatchId = bid + '';
    this.actuateTab({activeBatchId, tab: 'policies'});
  },

  notFound() {
    console.log('NOT FOUND');
  }
});

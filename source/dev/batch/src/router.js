import Router from 'ampersand-router';
import React from 'react';
import Main from './components/main';


export default Router.extend({
  routes: {
    '': 'policies',
    'batches': 'batches',
    'policies': 'policies',
    '*notFound': 'notFound'
  },

  actuateTab(props={}) {
    React.render(<Main {...props}/>, document.getElementById('main'));
  },

  batches() {
    this.actuateTab({tab: 'batches'});
  },

  policies() {
    this.actuateTab({tab: 'policies'});
  },

  notFound() {
    console.log('NOT FOUND');
  }
})

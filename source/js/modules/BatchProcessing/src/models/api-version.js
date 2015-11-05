import Model from 'ampersand-model';
import app from 'ampersand-app';

export default Model.extend({
  props: {
    appname: 'string',
    version: 'string'
  },

  url() {
    return `${app.urlRoot}/version`;
  },

  // set up the Auth header one time for all requests
  ajaxConfig() {
    return {
      xhrFields: {
        timeout: 0 // override 5 second timeout
      }
    };
  }
});


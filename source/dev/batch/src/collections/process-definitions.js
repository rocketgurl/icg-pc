import BaseCollection from './base-collection';

export default BaseCollection.extend({
  url: '/batch/repository/process-definitions',

  ajaxConfig() {
    return {
      headers: {
        'Authorization': 'Basic ZGV2QGljZzM2MC5jb206bW92aWVMdW5jaGVzRlRXMjAxNQ=='
      }
    };
  },

  parse(response) {
    this.total = response.total;
    return response.data;
  }
});

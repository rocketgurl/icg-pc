import BaseCollection from './base-collection';

export default BaseCollection.extend({
  url: '/batch/repository/process-definitions',

  parse(response) {
    this.total = response.total;
    return response.data;
  }
});

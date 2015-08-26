import _ from 'underscore';
import BaseCollection from './base-collection';
import BatchModel from '../models/batch';

export default BaseCollection.extend({
  model: BatchModel,

  url: '/batch/query/historic-process-instances',

  parse(response) {
    this.total = response.total;
    return response.data;
  },

  initialize() {
    this.options = {parse: true};
    this.parameters = {
      start: 0,
      size: 50,
      sort: 'startTime',
      order: 'desc',
      includeProcessVariables: true,
    };

    // HACK: This should only return "batch" processes
    this.variables = [{
      name: 'numPolicyRefs',
      operation: 'greaterThan',
      value: 0
    }];
  }
});

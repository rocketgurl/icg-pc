import _ from 'underscore';
import BaseCollection from './base-collection';
import BatchModel from '../models/batch';

export default BaseCollection.extend({
  model: BatchModel,

  url: '/batch/icg/batch-processes/query',

  initialize() {
    this.options = {parse: true};
    this.parameters = {
      start: 0,
      size: 25,
      sort: 'startTime',
      order: 'desc',
      includeProcessVariables: true,
    };
    this.pageStart  = 0; // these props are calculated on
    this.pageEnd    = 0; // successful response in the parse 
    this.totalItems = 0; // method of the BaseCollection
    this.variables  = [];
  }
});

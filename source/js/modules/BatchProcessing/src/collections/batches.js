import BaseCollection from './base-collection';
import BatchModel from '../models/batch';

class Batches extends BaseCollection {
  constructor() {
    super();
    this.url = '/batch/icg/batch-processes/querys';
    this.model = BatchModel;
  }
}

export default Batches;

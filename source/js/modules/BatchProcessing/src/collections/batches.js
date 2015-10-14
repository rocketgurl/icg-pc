import BaseCollection from './base-collection';
import BatchModel from '../models/batch';

class Batches extends BaseCollection {
  url() {
    return `${this.baseURL}/icg/batch-processes/query`;
  }

  constructor() {
    super();
    this.model = BatchModel;
  }
}

export default Batches;

import Model from 'ampersand-model';

class ErrorModel extends Model {
  constructor() {
    super();
    this.props = {
      error: 'string',
      exception: 'string',
      message: 'string',
      path: 'string',
      status: 'number',
      timestamp: ['number', true, +(new Date())]
    };
  }
}

export default ErrorModel;

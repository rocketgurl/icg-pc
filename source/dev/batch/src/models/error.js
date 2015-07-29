import Model from 'ampersand-model';

export default Model.extend({
  props: {
    xhr: 'object',
    message: 'string',
    status: 'number',
    statusText: 'string',
    timestamp: ['number', true, +(new Date())]
  }
});
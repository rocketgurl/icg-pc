import React from 'react';
import {dates} from '../constants';
import moment from 'moment';

export default React.createClass({
  getStatusLabel(batch) {
    const {status,
           numberOfInstances,
           numberOfSuccessInstances,
           numberOfErrorInstances} = batch;
    let className = 'label label-block label-info';
    let message   = `IN PROGRESS: ${numberOfSuccessInstances}
                     out of ${numberOfInstances} complete`;

    switch (status) {
      case 'finished-success':
        className = 'label label-block label-success';
        message   = `FINISHED: ${numberOfSuccessInstances}
                     out of ${numberOfInstances} complete`;
        break;
      case 'finished-error':
        className = 'label label-block label-danger';
        message   = `FINISHED: ${numberOfSuccessInstances}
                     out of ${numberOfInstances} complete`;
        break;
      case 'in-progress':
        if (numberOfErrorInstances > 0)
          className = 'label label-block label-warning';
        break;
    }

    return <span className={className}>{message}</span>;
  },

  render() {
    const {batch} = this.props;
    const dateFormat = dates.USER_FORMAT;
    return (
      <a className="tr" href={`#tasks/bid/${batch.id}`}>
        <div className="td">{this.getStatusLabel(batch)}</div>
        <div className="td batch-id">{batch.type}</div>
        <div className="td batch-id">{batch.id}</div>
        <div className="td">{batch.numberOfInstances}</div>
        <div className="td">{moment(batch.startTime).format(dateFormat)}</div>
        <div className="td">{batch.startUserId}</div>
      </a>
      );
  }
});

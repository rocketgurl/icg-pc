import React from 'react';
import app from 'ampersand-app';
import moment from 'moment';

// Jun 07, 2014 8:56 AM
const DATE_FORMAT = 'MMM DD, YYYY h:mm A';

export default React.createClass({
  getStatusLabel(batch) {
    const {status,
           numberOfInstances,
           numberOfSuccessInstances,
           numberOfErrorInstances} = batch;
    let className = 'label label-info';
    let message   = `IN PROGRESS: ${numberOfSuccessInstances}
                     out of ${numberOfInstances} complete`;

    switch (status) {
      case 'finished-success':
        className = 'label label-success';
        message   = `FINISHED: ${numberOfSuccessInstances}
                     out of ${numberOfInstances} complete`;
        break;
      case 'finished-error':
        className = 'label label-danger';
        message   = `FINISHED: ${numberOfErrorInstances}
                     out of ${numberOfInstances} failed`;
        break;
      case 'in-progress':
        if (numberOfErrorInstances > 0)
          className = 'label label-warning';
        break;
    }

    return <span className={className}>{message}</span>;
  },

  render() {
    const {batch} = this.props;
    return (
      <a className="tr" href={`#jobs/bid/${batch.id}`}>
        <div className="td">
          {this.getStatusLabel(batch)}
        </div>
        <div className="td batch-id">{`${batch.type} ${batch.id}`}</div>
        <div className="td">{batch.numberOfInstances}</div>
        <div className="td">{moment(batch.startTime).format(DATE_FORMAT)}</div>
        <div className="td">{batch.startUserId}</div>
      </a>
      );
  }
});

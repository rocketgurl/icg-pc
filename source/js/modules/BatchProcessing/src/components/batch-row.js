import React from 'react';
import app from 'ampersand-app';
import moment from 'moment';

// Jun 07, 2014 8:56 AM
const DATE_FORMAT = 'MMM DD, YYYY h:mm A';

export default React.createClass({
  render() {
    const {batch} = this.props;
    return (
      <a className="tr" href={`#policies/?bid=${batch.id}`}>
        <div className="td">{moment(batch.startTime).format(DATE_FORMAT)}</div>
        <div className="td">{batch.numberOfInstances}</div>
        <div className="td batch-id">{`${batch.type} ${batch.id}`}</div>
        <div className="td">{batch.startUserId}</div>
        <div className="td">
          <span className={batch.status.className}>{batch.status.message}</span>
        </div>
      </a>
      );
  }
});

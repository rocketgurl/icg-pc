import React from 'react';
import app from 'ampersand-app';

export default React.createClass({
  render() {
    const {batch} = this.props;
    return (
      <a className="tr" href={`#policies/?bid=${batch.id}`}>
        <div className="td">{batch.startTime}</div>
        <div className="td">{batch.numberOfInstances}</div>
        <div className="td">{`${batch.type} ${batch.id}`}</div>
        <div className="td">{batch.startUserId}</div>
        <div className="td"><span className="label label-default">Status</span></div>
      </a>
      );
  }
});

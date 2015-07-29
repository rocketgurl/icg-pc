import React from 'react';
import app from 'ampersand-app';
import BatchRow from './batch-row';

export default React.createClass({
  render() {
    return (
      <div className="div-table table-striped table-hover table-scrollable table-5-columns">
        <div className="thead">
          <div className="tr">
            <div className="th"><a href="status">Status <span className="glyphicon"></span></a></div>
            <div className="th"><a href="batch-id">Batch ID <span className="glyphicon"></span></a></div>
            <div className="th"><a href="quantity">Quantity <span className="glyphicon"></span></a></div>
            <div className="th"><a href="time-started">Time Started <span className="glyphicon"></span></a></div>
            <div className="th"><a href="assignee">Assignee <span className="glyphicon"></span></a></div>
          </div>
        </div>
        <div className="tbody" style={{maxHeight: `${500}px`}}>
          {this.props.batches.map((batch, index) => {
            return <BatchRow key={batch.id} batch={batch}/>;
          })}
        </div>
      </div>
    );
  }
});

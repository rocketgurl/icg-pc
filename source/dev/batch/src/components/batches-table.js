import React from 'react';

export default React.createClass({
  render() {
    return (
      <div className="div-table table-striped table-hover table-condensed table-scrollable table-5-columns">
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
          <div className="tr">
            <div className="td">Status</div>
            <div className="td">Batch ID</div>
            <div className="td">Quantity</div>
            <div className="td">Time Started</div>
            <div className="td">Assignee</div>
          </div>
        </div>
      </div>
    );
  }
});

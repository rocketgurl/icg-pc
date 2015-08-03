import React from 'react';

export default React.createClass({
  render() {
    return (
      <div className="row">
        <div className="col-xs-2">
          <select className="form-control"
            onChange={this.props.onActionSelect}>
            <option>Select a Batch Action</option>
            <option value="invoice">Invoice Policies</option>
          </select>
        </div>
      </div>
      );
  }
});

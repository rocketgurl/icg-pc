import React from 'react';
import DatePicker from 'react-datepicker';
import moment from 'moment';

const DATE_FORMAT = 'YYYY-MM-DD';

export default React.createClass({
  getDefaultProps() {
    return {
      processDefinitionKey: null,
      status: null,
      startedBy: null,
      startedAfter: null,
      startedBefore: null
    };
  },

  render() {
    const {startedAfter, startedBefore} = this.props;
    return (
      <div className="div-table table-6-columns table-controls">
        <div className="tbody">
          <div className="tr">
            <div className="td">
              <label htmlFor="processDefinitionKey">Batch Types</label>
              <select
                name="processDefinitionKey"
                defaultValue={this.props.processDefinitionKey}
                className="form-control"
                onChange={this._onSelectChange}>
                <option value="default">All</option>
                <option value="invoicing">Invoicing</option>
                <option value="issuance">Issuance</option>
                <option value="payment">Payment</option>
              </select>
            </div>
            <div className="td">
              <label htmlFor="status">Status</label>
              <select
                name="status"
                defaultValue={this.props.status}
                className="form-control">
                <option value="default">All</option>
              </select>
            </div>
            <div className="td">
              <label htmlFor="startedBy">Initiator</label>
              <select
                name="startedBy"
                defaultValue={this.props.startedBy}
                className="form-control"
                onChange={this._onSelectChange}>
                <option value="default">All</option>
                <option>dev@icg360.com</option>
              </select>
            </div>
            <div className="td clearable">
              <label htmlFor="startedAfter">From</label>
              <DatePicker
                name="startedAfter"
                selected={startedAfter ? moment(startedAfter) : null}
                onChange={this._onDateChange('startedAfter')}
                placeholderText="Started after&hellip;"
                className="form-control"/>
              {startedAfter ?
                <button
                  className="close"
                  data-dismiss="startedAfter"
                  onClick={this._onClearButtonClick}>
                  &times;
                </button> : null}
            </div>
            <div className="td clearable">
              <label htmlFor="startedBefore">To</label>
              <DatePicker
                name="startedBefore"
                selected={startedBefore ? moment(startedBefore) : null}
                onChange={this._onDateChange('startedBefore')}
                placeholderText="Started before&hellip;"
                className="form-control"/>
              {startedBefore ?
                <button
                  className="close"
                  data-dismiss="startedBefore"
                  onClick={this._onClearButtonClick}>
                  &times;
                </button> : null}
            </div>
            <div className="td">
              <div className="col-xs-6">
                <button
                  className="btn btn-primary btn-block"
                  onClick={this._onRefreshClick}>
                  <span className="glyphicon glyphicon-repeat"/>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  },

  _onRefreshClick() {
    this.props.onRefreshClick();
  },

  _onSelectChange(e) {
    this.props.onControlChange(e.target.name, e.target.value);
  },

  _onClearButtonClick(e) {
    const {value} = e.target.attributes['data-dismiss'];
    this.props.onControlChange(value, 'default');
  },

  _onDateChange(targetName) {
    return momentInstance => {
      if (targetName === 'startedBefore') {
        momentInstance.add(1, 'days');
      }
      this.props.onControlChange(targetName, momentInstance.format());
    }
  }
});

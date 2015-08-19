import React from 'react';
import DatePicker from 'react-datepicker';
import moment from 'moment';

const DATE_FORMAT = 'YYYY-MM-DD';

export default React.createClass({
  getInitialState() {
    return {
      startedAfter: null,
      startedBefore: null
    };
  },

  render() {
    const {startedAfter, startedBefore} = this.state;
    return (
      <div className="div-table table-6-columns table-controls">
        <div className="tbody">
          <div className="tr">
            <div className="td">
              <label htmlFor="processDefinitionKey">Batch Types</label>
              <select className="form-control" name="processDefinitionKey" onChange={this._onSelectChange}>
                <option value="default">All</option>
                <option value="invoicing">Invoicing</option>
                <option value="payments">Payments</option>
              </select>
            </div>
            <div className="td">
              <label htmlFor="status">Status</label>
              <select className="form-control" name="status">
                <option value="default">All</option>
              </select>
            </div>
            <div className="td">
              <label htmlFor="startedBy">Initiator</label>
              <select className="form-control" name="startedBy" onChange={this._onSelectChange}>
                <option value="default">All</option>
                <option>dev@icg360.com</option>
              </select>
            </div>
            <div className="td clearable">
              <label htmlFor="startedAfter">From</label>
              <DatePicker
                name="startedAfter"
                selected={startedAfter}
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
                selected={startedBefore}
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
                <button className="btn btn-primary btn-block">
                  <span className="glyphicon glyphicon-list"/>
                </button>
              </div>
              <div className="col-xs-6">
                <button className="btn btn-primary btn-block">
                  <span className="glyphicon glyphicon-repeat"/>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  },

  _onSelectChange(e) {
    this.props.onControlChange(e.target.name, e.target.value);
  },

  _onClearButtonClick(e) {
    const {value} = e.target.attributes['data-dismiss'];
    let stateAttr = {};
    stateAttr[value] = null;
    this.props.onControlChange(value, 'default');
    this.setState(stateAttr);
  },

  _onDateChange(targetName) {
    return momentInstance => {
      let stateAttr = {};
      stateAttr[targetName] = momentInstance.clone();
      if (targetName === 'startedBefore') {
        momentInstance.add(1, 'days');
      }
      this.props.onControlChange(targetName, momentInstance.format());
      this.setState(stateAttr);
    }
  }
});

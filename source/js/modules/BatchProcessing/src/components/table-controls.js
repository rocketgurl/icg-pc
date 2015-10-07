import React from 'react';
import _ from 'underscore';
import moment from 'moment';
import DatePicker from 'react-datepicker';

const DATE_FORMAT = 'YYYY-MM-DD';

export default React.createClass({
  propTypes: {
    controlType: React.PropTypes.string.isRequired,
    batchTypes: React.PropTypes.array.isRequired,
    pageStart: React.PropTypes.number.isRequired,
    pageEnd: React.PropTypes.number.isRequired,
    totalItems: React.PropTypes.number.isRequired,
    incrementPage: React.PropTypes.func.isRequired,
    decrementPage: React.PropTypes.func.isRequired,
    refreshPage: React.PropTypes.func.isRequired,
    updateParameter: React.PropTypes.func.isRequired,
    statuses: React.PropTypes.array,
    filterByStatus: React.PropTypes.func
  },

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
    const {
      startedAfter,
      startedBefore,
      pageStart,
      pageEnd,
      totalItems} = this.props;
    return (
      <div className="div-table table-condensed table-7-columns table-controls">
        <div className="tbody">
          <div className="tr">
            <div className="td">
              <select
                name="processDefinitionKey"
                defaultValue={this.props.processDefinitionKey}
                className="form-control input-sm"
                onChange={this._onSelectChange}>
                <option value="default">Batch Types: All</option>
                {_.map(this.props.batchTypes, (item, key) => {
                  return <option key={key} value={item.value}>{item.name}</option>;
                })}
              </select>
            </div>
            <div className="td">
              <select
                name="status"
                defaultValue={this.props.status}
                className="form-control input-sm"
                onChange={this._onStatusChange}>
                <option value="default">Status: All</option>
                {_.map(this.props.statuses, (item, key) => {
                  return <option key={key} value={item.value}>{item.name}</option>;
                })}
              </select>
            </div>
            <div className="td">
              <select
                name="startedBy"
                defaultValue={this.props.startedBy}
                className="form-control input-sm"
                onChange={this._onSelectChange}>
                <option value="default">Initiator: All</option>
              </select>
            </div>
            <div className="td clearable">
              <DatePicker
                name="startedAfter"
                selected={startedAfter ? moment(startedAfter) : null}
                onChange={this._onDateChange('startedAfter')}
                placeholderText="Started after&hellip;"
                className="form-control input-sm"/>
              {startedAfter ?
                <button
                  className="close"
                  data-dismiss="startedAfter"
                  onClick={this._onClearButtonClick}>
                  &times;
                </button> : null}
            </div>
            <div className="td clearable">
              <DatePicker
                name="startedBefore"
                selected={startedBefore ? moment(startedBefore) : null}
                onChange={this._onDateChange('startedBefore')}
                placeholderText="Started before&hellip;"
                className="form-control input-sm"/>
              {startedBefore ?
                <button
                  className="close"
                  data-dismiss="startedBefore"
                  onClick={this._onClearButtonClick}>
                  &times;
                </button> : null}
            </div>
            <div className="td">
              <div className="page-count">
                <strong>{pageStart}-{pageEnd}</strong>
                <span> of </span>
                <strong>{totalItems.toLocaleString()}</strong>
              </div>
            </div>
            <div className="td">
              <div className="btn-toolbar">
                <div className="btn-group">
                  <button
                    className="btn btn-default btn-sm"
                    disabled={pageStart <= 1}
                    onClick={this.props.decrementPage}>
                    <span className="glyphicon glyphicon-menu-left"/>
                  </button>
                  <button
                    className="btn btn-default btn-sm"
                    disabled={pageEnd >= totalItems}
                    onClick={this.props.incrementPage}>
                    <span className="glyphicon glyphicon-menu-right"/>
                  </button>
                </div>
                {this.props.controlType === 'jobs' ?
                <div className="btn-group">
                  <button
                    disabled={true}
                    className="btn btn-default btn-sm">
                    <span className="glyphicon glyphicon-stats"/>
                  </button>
                </div> : null}
                <div className="btn-group">
                  <button
                    className="btn btn-default btn-sm"
                    onClick={this.props.refreshPage}>
                    <span className="glyphicon glyphicon-refresh"/>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  },

  _onStatusChange(e) {
    this.props.filterByStatus(e.target.value);
  },

  _onSelectChange(e) {
    this.props.updateParameter(e.target.name, e.target.value);
  },

  _onClearButtonClick(e) {
    const {value} = e.target.attributes['data-dismiss'];
    this.props.updateParameter(value, 'default');
  },

  // closure to caputre the targetName of the particular field
  // returns an anonymouse function that takes the particular
  // instance of Moment as its arguments.
  _onDateChange(targetName) {
    return momentInstance => {
      if (targetName === 'startedBefore') {
        momentInstance.add(1, 'days');
      }
      this.props.updateParameter(targetName, momentInstance.format());
    }
  }
});

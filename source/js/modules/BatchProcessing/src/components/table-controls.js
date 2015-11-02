import React from 'react';
import {map} from 'underscore';
import app from 'ampersand-app';
import moment from 'moment';
import DatePicker from 'react-datepicker';

export default React.createClass({
  propTypes: {
    controlType: React.PropTypes.string.isRequired,
    isRequesting: React.PropTypes.bool.isRequired,
    processDefinitionKeys: React.PropTypes.array.isRequired,
    pageStart: React.PropTypes.number.isRequired,
    pageEnd: React.PropTypes.number.isRequired,
    totalItems: React.PropTypes.number.isRequired,
    incrementPage: React.PropTypes.func.isRequired,
    decrementPage: React.PropTypes.func.isRequired,
    refreshPage: React.PropTypes.func.isRequired,
    updateParameter: React.PropTypes.func.isRequired,
    status: React.PropTypes.string,
    statusOpts: React.PropTypes.array,
    filterByStatus: React.PropTypes.func,
    filterByAssignee: React.PropTypes.func
  },

  getDefaultProps() {
    return {
      processDefinitionKey: null,
      assignee: null,
      status: null,
      pageStart: 0,
      pageEnd: 0,
      totalItems: 0,
      startedAfter: null,
      startedBefore: null,
      isRequesting: false,
    };
  },

  render() {
    const {
      isRequesting,
      assignee,
      startedAfter,
      startedBefore,
      pageStart,
      pageEnd,
      totalItems} = this.props;
    return (
      <div className="row table-controls controls-condensed">
        <div className="col-md-8">
          <div className="div-table table-condensed table-5-columns">
            <div className="tbody">
              <div className="tr">
                <div className="td">
                  <select
                    name="processDefinitionKey"
                    disabled={isRequesting}
                    defaultValue={this.props.processDefinitionKey}
                    className="form-control input-sm"
                    onChange={this._onSelectChange}>
                    <option value="default">Batch Types: All</option>
                    {map(this.props.processDefinitionKeys, (item, key) => {
                      return <option key={key} value={item.value}>{item.name}</option>;
                    })}
                  </select>
                </div>
                {this.props.controlType === 'tasks' ?
                <div className="td">
                  <select
                    name="status"
                    disabled={isRequesting}
                    defaultValue={this.props.status}
                    className="form-control input-sm"
                    onChange={this.props.filterByStatus}>
                    <option value="default">Status: All</option>
                    {map(this.props.statusOpts, (item, key) => {
                      return <option key={key} value={item.value}>{item.name}</option>;
                    })}
                  </select>
                </div> : null}
                {this.props.controlType === 'tasks' ?
                <div className="td clearable">
                  <input
                    name="assignee"
                    disabled={isRequesting}
                    value={assignee === 'default' ? null : assignee}
                    className="form-control input-sm"
                    onBlur={this.props.filterByAssignee}
                    placeholder="Assignee&hellip;"/>
                  {assignee === 'default' ? null :
                    <button
                      value="default"
                      className="close"
                      disabled={isRequesting}
                      onClick={this.props.filterByAssignee}>
                      &times;
                    </button>}
                </div> : null}
                <div className="td clearable">
                  <DatePicker
                    name="startedAfter"
                    disabled={isRequesting}
                    selected={startedAfter ? moment(startedAfter) : null}
                    onChange={this._onDateChange('startedAfter')}
                    placeholderText="From&hellip;"
                    className="form-control input-sm"/>
                  {startedAfter ?
                    <button
                      className="close"
                      data-param="startedAfter"
                      disabled={isRequesting}
                      onClick={this._onDateClear}>
                      &times;
                    </button> : null}
                </div>
                <div className="td clearable">
                  <DatePicker
                    name="startedBefore"
                    disabled={isRequesting}
                    selected={startedBefore ? moment(startedBefore) : null}
                    onChange={this._onDateChange('startedBefore')}
                    placeholderText="To&hellip;"
                    className="form-control input-sm"/>
                  {startedBefore ?
                    <button
                      className="close"
                      data-param="startedBefore"
                      disabled={isRequesting}
                      onClick={this._onDateClear}>
                      &times;
                    </button> : null}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="control-wrapper">
            <div className="btn-toolbar pull-right">
              <div className="btn-group">
                <button
                  className="btn btn-default btn-sm"
                  disabled={pageStart <= 1 || isRequesting}
                  onClick={this.props.decrementPage}>
                  <span className="glyphicon glyphicon-menu-left"/>
                </button>
                <button
                  className="btn btn-default btn-sm"
                  disabled={pageEnd >= totalItems || isRequesting}
                  onClick={this.props.incrementPage}>
                  <span className="glyphicon glyphicon-menu-right"/>
                </button>
              </div>
              <div className="btn-group">
                <button
                  className="btn btn-default btn-sm"
                  disabled={isRequesting}
                  onClick={this.props.refreshPage}>
                  <span className={`glyphicon glyphicon-refresh${isRequesting ? ' animate-spin' : ''}`}/>
                </button>
              </div>
            </div>
            <div className="page-count pull-right">
              <strong>{pageStart}-{pageEnd}</strong>
              <span> of </span>
              <strong>{totalItems.toLocaleString()}</strong>
            </div>
          </div>
        </div>
      </div>
    );
  },

  _onSelectChange(e) {
    this.props.updateParameter(e.target.name, e.target.value);
  },

  _onDateClear(e) {
    const {value} = e.target.attributes['data-param'];
    this.props.updateParameter(value, 'default');
  },

  // closure to capture the targetName of the particular field
  // returns an anonymouse function that takes the particular
  // instance of Moment as its arguments.
  _onDateChange(targetName) {
    return momentInstance => {
      if (targetName === 'startedBefore') {
        momentInstance.add(1, 'days');
      }
      this.props.updateParameter(
        targetName, momentInstance.format(app.constants.dates.SYSTEM_FORMAT));
    }
  }
});

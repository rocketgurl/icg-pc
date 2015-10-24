import React from 'react';
import _ from 'underscore';
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
    status: React.PropTypes.string.isRequired,
    statusOpts: React.PropTypes.array,
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
      isRequesting,
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
                    {_.map(this.props.processDefinitionKeys, (item, key) => {
                      return <option key={key} value={item.value}>{item.name}</option>;
                    })}
                  </select>
                </div>
                <div className="td">
                  <select
                    name="status"
                    disabled={isRequesting}
                    defaultValue={this.props.status}
                    className="form-control input-sm"
                    onChange={this.props.filterByStatus}>
                    <option value="default">Status: All</option>
                    {_.map(this.props.statusOpts, (item, key) => {
                      return <option key={key} value={item.value}>{item.name}</option>;
                    })}
                  </select>
                </div>
                {this.props.controlType === 'tasks' ?
                <div className="td">
                  <select
                    name="startedBy"
                    disabled={isRequesting}
                    defaultValue={this.props.startedBy}
                    className="form-control input-sm"
                    onChange={this._onSelectChange}>
                    <option value="default">Assignee: All</option>
                  </select>
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
                      data-dismiss="startedAfter"
                      disabled={isRequesting}
                      onClick={this._onClearButtonClick}>
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
                      data-dismiss="startedBefore"
                      disabled={isRequesting}
                      onClick={this._onClearButtonClick}>
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
              {this.props.controlType === 'tasks' ?
              <div className="btn-group">
                <button
                  disabled={true}
                  className="btn btn-default btn-sm">
                  <span className="glyphicon glyphicon-list"/>
                </button>
                <button
                  disabled={true}
                  className="btn btn-default btn-sm">
                  <span className="glyphicon glyphicon-stats"/>
                </button>
              </div> : null}
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

  _onClearButtonClick(e) {
    const {value} = e.target.attributes['data-dismiss'];
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

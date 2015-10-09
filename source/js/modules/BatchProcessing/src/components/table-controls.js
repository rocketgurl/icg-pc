import React from 'react';
import _ from 'underscore';
import moment from 'moment';
import DatePicker from 'react-datepicker';

const DATE_FORMAT = 'YYYY-MM-DD';

export default React.createClass({
  propTypes: {
    controlType: React.PropTypes.string.isRequired,
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
                    defaultValue={this.props.status}
                    className="form-control input-sm"
                    onChange={this.props.filterByStatus}>
                    <option value="default">Status: All</option>
                    {_.map(this.props.statusOpts, (item, key) => {
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
                  onClick={this.props.refreshPage}>
                  <span className="glyphicon glyphicon-refresh"/>
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

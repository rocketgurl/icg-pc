import React from 'react';
import {OverlayTrigger, Popover} from 'react-bootstrap';
import app from 'ampersand-app';
import moment from 'moment';
import {dates} from '../constants';

export default React.createClass({
  getInitialState() {
    return {selected: this.props.selected};
  },

  componentWillReceiveProps(newProps) {
    if (newProps.selected !== this.state.selected)
      this._setSelected(newProps.selected);
  },

  componentWillUnmount() {
    this._setSelected(false);
  },

  getStatusLabel(task) {
    const {status, endActivityId} = task;
    let className = 'label label-block label-default';
    let message   = 'STARTED';
    switch (status) {
      case 'end-success':
        className = 'label label-block label-success';
        message   = 'ENDED: SUCCESS';
        break;
      case 'end-error':
        className = 'label label-block label-danger';
        message   = 'ENDED: ERROR';
        break;
      case 'action-required':
        className = 'label label-block label-warning';
        message   = 'ERROR: ACTION REQUIRED';
        break;
      case 'in-progress':
        className = 'label label-block label-info';
        message   = 'IN PROGRESS';
        break
    }
    return <span className={className}>{message}</span>;
  },

  render() {
    const {task, enabled} = this.props;
    const {selected} = this.state;
    const dateFormat = dates.USER_FORMAT;
    const errorMessage = `${task.errorCode} - ${task.errorMessage}`;
    const infoPopover = (
      <OverlayTrigger key="overlay" rootClose trigger="click" placement="left"
        overlay={<Popover className="error-popover" id={`task-${task.id}`} title={errorMessage}>{task.errorResponse}</Popover>}>
        <span title="Click for more info"
          className="glyphicon glyphicon-info-sign info-toggle"></span>
      </OverlayTrigger>);

    return (
      <div id={task.id}
        className={`tr${selected ? ' active' : ''}`}
        title={`Process Instance ID ${task.id}`}
        onClick={this._onRowClick}>
        <div className="td task-select">
          <input type="checkbox"
            checked={selected}
            disabled={!enabled}
            onChange={app.noop}/>
        </div>
        <div className="td">{moment(task.startTime).format(dateFormat)}</div>
        <div className="td policy-lookup">{task.origPolicyLookup || task.origPolicyNumberBase}</div>
        <div className="td batch-id">{`${task.processDefinitionKey} ${task.batchId}`}</div>
        <div className="td">{task.currentAssignee}</div>
        <div className="td">
          {this.getStatusLabel(task)}
        </div>
        <div className="td text-danger">
          {task.hasException ? [errorMessage, ' ', infoPopover] : null}
        </div>
      </div>
      );
  },

  _setSelected(selected) {
    if (this.props.enabled) {
      this.setState({selected});
      app.selectedTasks[selected ? 'add' : 'remove'](this.props.task);
    }
  },

  _onRowClick() {
    this._setSelected(!this.state.selected);
  }
});

import React from 'react';
import {OverlayTrigger, Popover} from 'react-bootstrap';
import app from 'ampersand-app';
import moment from 'moment';

export default React.createClass({
  getInitialState() {
    return {checked: this.props.checked};
  },

  componentWillReceiveProps(newProps) {
    this._handleCheckToggle(newProps.checked);
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

  _handleCheckToggle(checked) {
    this.setState({checked});
    app.selectedTasks[checked ? 'add' : 'remove'](this.props.task);
  },

  render() {
    const {task, enabled} = this.props;
    const {checked} = this.state;
    const dateFormat = app.constants.dates.USER_FORMAT;
    const errorMessage = `${task.errorCode} - ${task.errorMessage}`;
    const infoPopover = (
      <OverlayTrigger key="overlay" rootClose trigger="click" placement="left"
        overlay={<Popover title={errorMessage}>{task.errorResponse}</Popover>}>
        <span title="Click for more info"
          className="glyphicon glyphicon-info-sign info-toggle"></span>
      </OverlayTrigger>);

    return (
      <div id={task.id}
        className={`tr${checked ? ' active' : ''}`}
        title={`Process Instance ID ${task.id}`}
        onClick={this._onRowClick}>
        <div className="td task-select">
          <input type="checkbox"
            checked={checked}
            disabled={!enabled}
            onChange={app.noop}/>
        </div>
        <div className="td">{moment(task.startTime).format(dateFormat)}</div>
        <div className="td policy-lookup">{task.policyLookup}</div>
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

  _handleCheckToggle(checked) {
    if (this.props.enabled) {
      this.setState({checked});
      app.selectedTasks[checked ? 'add' : 'remove'](this.props.task);
    }
  },

  _onRowClick() {
    this._handleCheckToggle(!this.state.checked);
  }
});

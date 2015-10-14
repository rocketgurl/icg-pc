import React from 'react';
import {OverlayTrigger, Popover} from 'react-bootstrap';
import app from 'ampersand-app';
import moment from 'moment';

// Jun 07, 2014 8:56 AM
const DATE_FORMAT = 'MMM DD, YYYY h:mm A';

export default React.createClass({
  getInitialState() {
    return {checked: this.props.checked};
  },

  componentWillReceiveProps(newProps) {
    this.setState({checked: newProps.checked});
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
    const {checked} = this.state;
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
        onClick={this._onClick}
        title={`Process Instance ID ${task.id}`}>
        <div className="td task-select">
          <input type="checkbox"
            checked={checked}
            disabled={!enabled}
            onChange={this._onCheckToggle}/>
        </div>
        <div className="td">{moment(task.startTime).format(DATE_FORMAT)}</div>
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

  _onClick(e) {
    if (this.props.enabled)
      this.setState({checked: !this.state.checked});
  },

  _onCheckToggle(e) {
    this.setState({checked: e.target.checked});
  },
});

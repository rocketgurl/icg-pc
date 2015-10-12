import React from 'react';
import {OverlayTrigger, Popover} from 'react-bootstrap';
import app from 'ampersand-app';
import moment from 'moment';

// Jun 07, 2014 8:56 AM
const DATE_FORMAT = 'MMM DD, YYYY h:mm A';

export default React.createClass({
  getInitialState() {
    return {
      isChecked: this.props.itemShouldBeChecked
    };
  },

  componentWillReceiveProps(newProps) {
    this.setState({isChecked: newProps.itemShouldBeChecked});
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
    const {task} = this.props;
    const errorMessage = `${task.errorCode} - ${task.errorMessage}`;
    const infoPopover = (
      <OverlayTrigger key="overlay" rootClose trigger="click" placement="left"
        overlay={<Popover title={errorMessage}>{task.errorResponse}</Popover>}>
        <span title="Click for more info"
          className="glyphicon glyphicon-info-sign info-toggle"></span>
      </OverlayTrigger>);

    return (
      <div className="tr" id={task.id} title={`Process Instance ID ${task.id}`}>
        <div className="td">
          <input type="checkbox"
            checked={this.state.isChecked}
            onChange={this._onCheckToggle}/>
        </div>
        <div className="td">{moment(task.startTime).format(DATE_FORMAT)}</div>
        <div className="td policy-lookup">{task.policyLookup}</div>
        <div className="td batch-id">{`${task.processDefinitionKey} ${task.batchId}`}</div>
        <div className="td">{task.startUserId}</div>
        <div className="td">
          {this.getStatusLabel(task)}
        </div>
        <div className="td text-danger">
          {task.hasException ? [errorMessage, ' ', infoPopover] : null}
        </div>
      </div>
      );
  },

  _onCheckToggle(e) {
    this.setState({isChecked: e.target.checked});
  },
});

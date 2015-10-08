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

  getStatusLabel(job) {
    const {status, endActivityId} = job;
    let className = 'label label-block label-info';
    let message   = 'IN PROGRESS';
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
    }
    return <span className={className}>{message}</span>;
  },

  render() {
    const {job} = this.props;
    const errorMessage = `${job.errorCode} - ${job.errorMessage}`;
    const infoPopover = (
      <OverlayTrigger key="overlay" rootClose trigger="click" placement="left"
        overlay={<Popover title={errorMessage}>{job.errorResponse}</Popover>}>
        <span title="Click for more info"
          className="glyphicon glyphicon-info-sign info-toggle"></span>
      </OverlayTrigger>);

    return (
      <div className="tr">
        <div className="td">
          <input type="checkbox"
            checked={this.state.isChecked}
            onChange={this._onCheckToggle}/>
        </div>
        <div className="td">{moment(job.startTime).format(DATE_FORMAT)}</div>
        <div className="td policy-lookup">{job.policyLookup}</div>
        <div className="td batch-id">{`${job.processDefinitionKey} ${job.batchId}`}</div>
        <div className="td">{job.startUserId}</div>
        <div className="td">
          {this.getStatusLabel(job)}
        </div>
        <div className="td text-danger">
          {job.hasException ? [errorMessage, ' ', infoPopover] : null}
        </div>
      </div>
      );
  },

  _onCheckToggle(e) {
    this.setState({isChecked: e.target.checked});
  },
});

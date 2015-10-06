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

  getStatusLabel(policy) {
    const {status, endActivityId} = policy;
    let className = 'label label-info';
    let message   = 'IN PROGRESS';
    switch (status) {
      case 'end-success':
        className = 'label label-success';
        message   = 'ENDED: SUCCESS';
        break;
      case 'end-error':
        className = 'label label-danger';
        message   = 'ENDED: ERROR';
        break;
      case 'action-required':
        className = 'label label-warning';
        message   = 'ERROR: ACTION REQUIRED';
        break;
    }
    return <span className={className}>{message}</span>;
  },

  render() {
    const {policy} = this.props;
    const errorMessage = `${policy.errorCode} - ${policy.errorMessage}`;
    const infoPopover = (
      <OverlayTrigger key="overlay" rootClose trigger="click" placement="left"
        overlay={<Popover title={errorMessage}>{policy.errorResponse}</Popover>}>
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
        <div className="td">{moment(policy.startTime).format(DATE_FORMAT)}</div>
        <div className="td policy-lookup">{policy.policyLookup}</div>
        <div className="td batch-id">{`${policy.processDefinitionKey} ${policy.batchId}`}</div>
        <div className="td">{policy.startUserId}</div>
        <div className="td">
          {this.getStatusLabel(policy)}
        </div>
        <div className="td text-danger">
          {policy.hasException ? [errorMessage, ' ', infoPopover] : null}
        </div>
      </div>
      );
  },

  _onCheckToggle(e) {
    this.setState({isChecked: e.target.checked})
  },
});

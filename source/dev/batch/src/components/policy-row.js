import React from 'react';
import app from 'ampersand-app';

export default React.createClass({

  render() {
    const {policy} = this.props;
    return (
      <div className="tr">
        <div className="td"><input type="checkbox"/></div>
        <div className="td">{policy.startTime}</div>
        <div className="td">{policy.policyLookup}</div>
        <div className="td">{`${policy.processDefinitionKey} ${policy.batchId}`}</div>
        <div className="td">{policy.startUserId}</div>
        <div className="td"><span className="label label-default">Status</span></div>
        <div className="td" title={policy.errorResponse}>
          {policy.hasException ? `${policy.errorCode} - ${policy.errorMessage}` : null}
        </div>
      </div>
      );
  }
});

import React from 'react';
import app from 'ampersand-app';

export default React.createClass({
  getInitialState() {
    return {
      isChecked: this.props.itemShouldBeChecked
    };
  },

  componentWillReceiveProps(newProps) {
    this.setState({isChecked: newProps.itemShouldBeChecked});
  },

  render() {
    const {policy} = this.props;
    return (
      <div className="tr">
        <div className="td">
          <input
            type="checkbox"
            checked={this.state.isChecked}
            onChange={this._onCheckToggle}/>
        </div>
        <div className="td">{policy.startTime}</div>
        <div className="td">{policy.policyLookup}</div>
        <div className="td">{`${policy.processDefinitionKey} ${policy.batchId}`}</div>
        <div className="td">{policy.startUserId}</div>
        <div className="td"><span className="label label-default">{policy.status}</span></div>
        <div className="td" title={policy.errorResponse}>
          {policy.hasException ? `${policy.errorCode} - ${policy.errorMessage}` : null}
        </div>
      </div>
      );
  },

  _onCheckToggle(e) {
    this.setState({isChecked: e.target.checked})
  },
});

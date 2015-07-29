import React from 'react';
import app from 'ampersand-app';
import PolicyRow from './policy-row';

export default React.createClass({
  getInitialState() {
    return {policies: []};
  },

  componentDidMount() {
    app.policies.on('sync', this._onPoliciesSync);
    app.policies.query(this.state.query);
  },

  render() {
    return (
      <div className="div-table table-striped table-hover table-scrollable table-7-columns">
        <div className="thead">
          <div className="tr">
            <div className="th"><input type="checkbox"/></div>
            <div className="th"><a href="startTime">Time Started <span className="glyphicon"></span></a></div>
            <div className="th"><a href="policyNum">Policy # <span className="glyphicon"></span></a></div>
            <div className="th"><a href="batchId">Batch ID <span className="glyphicon"></span></a></div>
            <div className="th"><a href="assignee">Assignee <span className="glyphicon"></span></a></div>
            <div className="th"><a href="status">Status <span className="glyphicon"></span></a></div>
            <div className="th"><a href="message">Message <span className="glyphicon"></span></a></div>
          </div>
        </div>
        <div className="tbody" style={{maxHeight: `${500}px`}}>
          {this.state.policies.map((policy, index) => {
            return <PolicyRow key={policy.id} policy={policy}/>;
          })}
        </div>
      </div>
    );
  },

  _onPoliciesSync(collection) {
    this.setState({policies: collection});
  }
});

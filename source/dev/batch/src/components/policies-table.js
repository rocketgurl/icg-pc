import React from 'react';
import app from 'ampersand-app';
import PolicyRow from './policy-row';

export default React.createClass({
  getInitialState() {
    return {
      policies: [],
      query: null
    };
  },

  componentDidMount() {
    const {policies} = this.props;
    policies.on('sync', this._onPoliciesSync);
    if (policies.length) {
      this.setState({policies})
    } else {
      policies.query();
    }
  },

  componentWillUnmount() {
    this.props.policies.off();
  },

  render() {
    return (
      <div className="div-table table-striped table-hover table-scrollable table-7-columns">
        <div className="thead">
          <div className="tr">
            <div className="th"><input type="checkbox"/></div>
            <div className="th"><a href="startTime">Time Started <span className="glyphicon"></span></a></div>
            <div className="th">Policy #</div>
            <div className="th">Batch ID</div>
            <div className="th"><a href="startUserId">Initiator <span className="glyphicon"></span></a></div>
            <div className="th">Status</div>
            <div className="th">Message</div>
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

  _onPoliciesSync(policies) {
    this.setState({policies});
  }
});

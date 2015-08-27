import React from 'react';
import app from 'ampersand-app';
import TabContent from './tab-content';
import BatchActionSelect from './batch-action-select';
import BatchActionModal from './batch-action-modal';
import BatchesTable from './batches-table';
import PoliciesTable from './policies-table';
import {Nav, NavItem, TabPane} from 'react-bootstrap';

export default React.createClass({
  getDefaultProps() {
    return {
      showBatchActionModal: false,
      processDefinitionId: null
    };
  },

  getInitialState() {
    return {
      tab: this.props.tab || 'batches',
      batches: app.batches
    };
  },

  componentWillReceiveProps(props) {
    if (props.tab) {
      this.setState({tab: props.tab});
    }
  },

  componentWillMount() {
    app.batches.on('sync', this._onBatchesSync);
  },

  componentWillUnmount() {
    app.batches.off();
  },

  // Determine the correct collection of policies and return it
  // along with the <PoliciesTable/> node
  getPoliciesTable() {
    const {activeBatchId} = this.props;
    if (app.batches.length) {
      const activeBatch = app.batches.get(activeBatchId);
      const policies = activeBatch ?
        activeBatch.policies :
        app.allPolicies;
      return <PoliciesTable key={activeBatchId} collection={policies}/>;
    }
  },

  render() {
    const {tab} = this.state;
    const {
      showBatchActionModal,
      processDefinitionId,
      actionName} = this.props;
    return (
      <div>
        <div className="row action-row">
          <BatchActionSelect
            collection={app.processDefinitions}
            processDefinitionId={processDefinitionId}
            router={app.router}/>
          <BatchActionModal
            showModal={showBatchActionModal}
            actionName={actionName}
            processDefinitionId={processDefinitionId}
            router={app.router}/>
        </div>
        <div className="panel panel-default panel-nav">
          <Nav bsStyle="tabs" activeKey={tab}>
            <NavItem eventKey="batches" href="#batches">Batches</NavItem>
            <NavItem eventKey="policies" href="#policies">Policies</NavItem>
          </Nav>
          <div className="panel-body">
            <TabContent activeKey={tab}>
              <TabPane key="batches">
                <BatchesTable collection={this.state.batches}/>
              </TabPane>
              <TabPane key="policies">
                {this.getPoliciesTable()}
              </TabPane>
            </TabContent>
          </div>
        </div>
      </div>
    );
  },

  _onBatchesSync(batches) {
    this.setState({batches});
  }
});
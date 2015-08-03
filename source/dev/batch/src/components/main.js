import React from 'react';
import app from 'ampersand-app';
import TabContent from './tab-content';
import StackedBarChart from './stacked-bar-chart';
import FormControls from './form-controls';
import BatchActionSelect from './batch-action-select';
import BatchesTable from './batches-table';
import PoliciesTable from './policies-table';
import {Nav, NavItem, TabPane} from 'react-bootstrap';

export default React.createClass({
  getInitialState() {
    return {
      batches: [],
      query: {
        start: 0,
        size: 50,
        sort: 'startTime',
        order: 'desc'
      }
    };
  },

  componentDidMount() {
    app.batches.on('sync', this._onBatchesSync);
    app.batches.query(this.state.query);
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
      return <PoliciesTable key={activeBatchId} policies={policies}/>;
    }
  },

  render() {
    const {tab} = this.props;
    return (
      <div>
        <BatchActionSelect onActionSelect={this._onActionSelect}/>
        <div className="panel panel-default panel-nav">
          <Nav bsStyle="tabs" activeKey={tab}>
            <NavItem eventKey="batches" href="#batches">Batches</NavItem>
            <NavItem eventKey="policies" href="#policies">Policies</NavItem>
          </Nav>
          <div className="panel-body">
            <TabContent activeKey={tab}>
              <TabPane key="batches">
                <BatchesTable batches={this.state.batches} onSort={this._onBatchesSort}/>
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

  _onBatchesSync(collection) {
    this.setState({batches: collection});
  },

  _onBatchesSort(sortBy, order) {
    const {query} = this.state;
    query.sort = sortBy;
    query.order = order;
    this.setState({query});
    app.batches.query(query);
   },

  _onActionSelect() {}
});

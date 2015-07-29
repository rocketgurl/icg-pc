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
        order: 'desc',
        includeProcessVariables: true,
        variables: [{
          name : 'numPolicyRefs', // HACK: This should only return "batch" processes
          operation : 'greaterThanOrEquals',
          value : 0
        }]
      }
    };
  },

  componentDidMount() {
    // app.batches.on('all', (...args) => { console.log('COLL', args) })
    app.batches.on('sync', this._onBatchesSync);
    app.batches.query(this.state.query);
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
                <BatchesTable batches={this.state.batches}/>
              </TabPane>
              <TabPane key="policies">
                <PoliciesTable/>
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

  _onActionSelect() {}
});

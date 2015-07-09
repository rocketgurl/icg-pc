import React from 'react';
import TabContent from './tab-content';
import StackedBarChart from './stacked-bar-chart';
import FormControls from './form-controls';
import BatchesTable from './batches-table';
import {Nav, NavItem, TabPane} from 'react-bootstrap';

export default React.createClass({
  render() {
    const {tab} = this.props;
    return (
      <div className="panel panel-default panel-nav">
        <Nav bsStyle="tabs" activeKey={tab}>
          <NavItem eventKey="batches" href="#batches">Batches</NavItem>
          <NavItem eventKey="policies" href="#policies">Policies</NavItem>
        </Nav>
        <div className="panel-body">
          <TabContent activeKey={tab}>
            <TabPane key="batches">
              <FormControls/>
              <BatchesTable/>
            </TabPane>
            <TabPane key="policies">
              <FormControls/>
              <StackedBarChart/>
            </TabPane>
          </TabContent>
        </div>
      </div>
    );
  }
});

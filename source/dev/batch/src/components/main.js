import React from 'react';
import TabContent from './tab-content';
import {Nav, NavItem, TabPane} from 'react-bootstrap';


export default React.createClass({
  render() {
    const {tab} = this.props;
    return (
      <div className="panel panel-default panel-nav">
        <Nav bsStyle='tabs' activeKey={tab}>
          <NavItem eventKey="batches" href="#batches">Batches</NavItem>
          <NavItem eventKey="policies" href="#policies">Policies</NavItem>
        </Nav>
        <div className="panel-body">
          <TabContent activeKey={tab}>
            <TabPane key="batches">TabPane 1 content</TabPane>
            <TabPane key="policies">TabPane 2 content</TabPane>
          </TabContent>
        </div>
      </div>
    );
  }
});

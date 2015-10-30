import React from 'react';
import {Navbar, Nav, NavItem, NavDropdown, MenuItem} from 'react-bootstrap';

export default (props) => (
  <ul className="nav navbar-nav">
    <NavItem eventKey={1} href="/#workspace/staging/cru/crunyho/policies_crunyho/home" target="policy-central">Home</NavItem>
    <NavItem eventKey={2} href="/#workspace/staging/cru/crunyho/policies_crunyho/search" target="policy-central">Search</NavItem>
    <NavDropdown eventKey={3} title="Servicing" id="basic-nav-dropdown">
      <MenuItem eventKey="1" href="/batch" target="_blank">Batch Wolf</MenuItem>
      <MenuItem divider />
      <MenuItem eventKey="2">Batch Processing <span className="label label-info">New</span></MenuItem>
    </NavDropdown>
    <NavDropdown eventKey={4} title="Underwriting" id="basic-nav-dropdown">
      <MenuItem eventKey="1" href="/#workspace/staging/cru/crunyho/policies_crunyho/underwriting/referrals" target="policy-central">New Business Underwriting</MenuItem>
      <MenuItem divider />
      <MenuItem eventKey="2" href="/#workspace/staging/cru/crunyho/policies_crunyho/underwriting/renewals" target="policy-central">Renewal Underwriting</MenuItem>
    </NavDropdown>
    <NavItem eventKey={5} href="https://agencyadmin.icg360.com/" target="_blank">Agencies</NavItem>
    <NavItem eventKey={6} href="https://ixreport.icg360.com/rfk/root/" target="_blank">Reports</NavItem>
  </ul>
);

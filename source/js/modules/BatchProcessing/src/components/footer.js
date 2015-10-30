import React from 'react';

export default ({apiVersion, uiVersion}) => (
  <ul>
    <li>&copy; {new Date().getFullYear()} Insight Catastrophe Group</li>
    <li>API <span id="api-version">{apiVersion}</span></li>
    <li>UI <span id="ui-version">{uiVersion}</span></li>
  </ul>
);

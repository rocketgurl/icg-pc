import React from 'react';

export default ({userName}) => (
  <ul>
    <li>Welcome back <a id="user-name">{userName}</a></li>
    <li><a href="/#logout">Logout</a></li>
  </ul>
);

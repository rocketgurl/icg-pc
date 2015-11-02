import React from 'react';
import ChartFactory from '../charts/chart-factory';


export default function Spinner(props) {
  return (
    <div className="table-spinner">
      <span className="message">{props.message}</span>
      <span className="glyphicon glyphicon-refresh animate-spin"/>
    </div>
    );
}

Spinner.propTypes = {
  message: React.PropTypes.string.isRequired
};

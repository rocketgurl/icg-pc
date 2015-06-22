import React from 'react';
import Chart from './chart';

const totalData = [];
const errorsOnlyData = [];

export default React.createClass({
  getInitialState() {
    return {
      errorsOnly: false
    }
  },

  render() {
    return (
      <div>
        <h2>Events API Activity</h2>
        <input type='checkbox' onChange={this._onToggleErrorsOnly} value={this.state.errorsOnly} />
        <Chart
          type='StackedAreaChart'
          data={this._aggregateAppropriateData()}
          options={{
            height: 500,
            width: 960,
            margin: {
              left: 50,
              top: 20,
              right: 20,
              bottom: 30
            }
          }}
        />
      </div>
    );
  },

  _onToggleErrorsOnly() {
    this.setState({
      errorsOnly: !this.state.errorsOnly
    });
  },

  _aggregateAppropriateData() {
    if (this.state.errorsOnly) {
      return errorsOnlyData;
    }
    return totalData;
  },
});
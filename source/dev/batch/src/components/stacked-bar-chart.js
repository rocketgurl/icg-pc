import React from 'react';
import Chart from './chart';
import app from 'ampersand-app';

let showErrorsOnly = false;

function getPolicyData() {
  let keys = showErrorsOnly ? ['errors'] : [];
  return app.policies.getData(...keys);
}

export default React.createClass({
  getInitialState() {
    return {
      policies: getPolicyData()
    }
  },

  componentDidMount() {
    app.policies.on('sync', this._onSync);
  },

  componentWillUnmount() {
    app.policies.off();
  },

  render() {
    console.log(this.state)
    return (
      <div>
        <button className="btn btn-primary" onClick={this._onClick}>Toggle</button>
        <Chart
          type="StackedBarChart"
          data={this.state.policies}
          options={{
            height: 500,
            width: 960,
            margin: {
              left: 50,
              top: 20,
              right: 20,
              bottom: 30
            },
            yaxis: {
              orientation: 'right'
            }
          }}
        />
      </div>
    );
  },

  _onClick() {
    showErrorsOnly = !showErrorsOnly;
    this.setState({
      policies: getPolicyData()
    });
  },

  _onSync() {
    this.setState({
      policies: getPolicyData()
    });
  }

});
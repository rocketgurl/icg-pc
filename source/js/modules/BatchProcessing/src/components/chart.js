import React from 'react';
import ChartFactory from '../charts/chart-factory';


export default React.createClass({
  propTypes: {
    type: React.PropTypes.string.isRequired,
    data: React.PropTypes.array.isRequired,
    options: React.PropTypes.object
  },

  // create chart and do first data bind
  componentDidMount() {
    this._chart = new ChartFactory(
      this.props.type,
      this.props.data,
      this.props.options,
      this.getDOMNode()
    );
  },

  componentDidUpdate() {
    this._chart.update(this.props.data);
  },

  componentWillUnmount() {
    this._chart.remove();
  },

  render() {
    return (
      <div className={`chart ${this.props.type}`}></div>
    );
  }
});
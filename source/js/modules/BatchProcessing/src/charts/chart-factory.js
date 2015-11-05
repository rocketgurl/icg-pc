import {extend, defaults} from 'underscore';
import d3 from 'd3';
import StackedBarChart from './stacked-bar-chart';

const defaultOpts = {
  height: 960,
  width: 480,
  margin: {
    left: 20,
    top: 20,
    right: 20,
    bottom: 20
  },
  yaxis: {
    orientation: 'left'
  },
  xaxis: {
    orientation: 'bottom'
  }
};

function ChartFactory(type, data, options, DOMNode) {
  if (typeof ChartFactory[type] !== 'function' ||
      typeof ChartFactory[type].prototype.update !== 'function') {
    throw new Error(`${type} is not a valid chart!`);
  }
  if (!ChartFactory[type].prototype.initialize) {
    extend(ChartFactory[type].prototype, ChartFactory.prototype);
  }
  let newChart = new ChartFactory[type]();
  newChart.initialize(data, options, DOMNode);
  return newChart;
}

// initial d3 setup, like merging options and defaults
ChartFactory.prototype.initialize = function (data, options, DOMNode) {
  var opts = this.options = defaults(options || {}, defaultOpts);

  // set dimensions, translation offset for axes, etc. nothing related to data!
  this.height = opts.height - (opts.margin.top + opts.margin.bottom);
  this.width = opts.width - (opts.margin.right + options.margin.left);
  this.xAxis = d3.svg.axis().orient(options.xaxis.orientation);
  this.yAxis = d3.svg.axis().orient(options.yaxis.orientation);

  // main chart svg width, height, and margins
  this.svg = d3.select(DOMNode).append('svg')
      .attr('width', opts.width)
      .attr('height', opts.height)
    .append('g')
      .attr('transform', `translate(${opts.margin.left}, ${opts.margin.top})`);

  // setup axes positions only (scaling involves data and should be chart-specific)
  this.svg.append('g').attr('class', 'x axis')
      .attr('transform', `translate(0, ${this.height})`);
  this.svg.append('g').attr('class', 'y axis')
      .append('text').attr('transform', 'rotate(-90)');

  // now make first data bind (update) via chart-specific update method
  this.update(data);
};

// attach all chart types as static properties
ChartFactory.StackedBarChart = StackedBarChart;

export default ChartFactory;
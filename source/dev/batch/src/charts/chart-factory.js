

function ChartFactory(type, data, options, DOMNode) {
  if (typeof ChartFactory[type] !== 'function' ||
      typeof ChartFactory[type].prototype.update !== 'function') {
    throw new Error(`${type} is not a valid chart!`);
  }
  if (!ChartFactory[type].prototype.initialize)) {
    _.extend(ChartFactory[type].prototype, ChartFactory.prototype);
  }
  let newChart = new ChartFactory[type]();
  return newChart;
}

// attach all chart types as static properties
// ChartFactory.StackedAreaChart = StackedAreaChart;

export default ChartFactory;
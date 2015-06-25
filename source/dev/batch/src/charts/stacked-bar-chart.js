import d3 from 'd3';

const hour = 3600000; // 1 hour = (60 * 60 * 1000)
const step = hour * 2;
function StackedBarChart() {};

StackedBarChart.prototype.update = function update(data) {
  const {xAxis, yAxis, svg, width, height} = this;
  const dataTypes = d3.keys(data[0]).filter(d => {
          return d !== 'date';
        });

  const x = d3.time.scale().range([0, width]),
        y = d3.scale.linear().rangeRound([height, 0]),
        color = d3.scale.category20();

  color.domain(dataTypes);

  // aggregates time series data into buckets (e.g. 1 hour * scalar)
  // creates y values for stacking each separate data type
  const buckets = d3.nest()
    .key(d => { return d.date - (d.date % step)})
    .rollup(values => {
      let y = 0;
      let total = 0;
      let aggregate = dataTypes.map(type => {
        let y0 = y;
        let y1 = total = y += d3.sum(values, d => { return d[type]; });
        return {type, y0, y1};
      });
      aggregate.total = total;
      return aggregate;
    })
    .entries(data);

  const startDate = d3.min(buckets, d => { return +d.key; }),
        endDate = d3.max(buckets, d => { return +d.key; }) + step; // add an extra step to round nicely

  let legend = svg.selectAll('.legend')
        .data(dataTypes)
      .enter().append('g')
        .attr('class', 'legend')
        .attr('transform', (d, i) => { return `translate(0, ${i * 20})`; });

  legend.append('rect')
      .attr('x', width - 18)
      .attr('width', 18)
      .attr('height', 18)
      .style('fill', color);

  legend.append('text')
      .attr('x', width - 24)
      .attr('y', 9)
      .attr('dy', '.35em')
      .style('text-anchor', 'end')
      .text(d => { return d; });

  x.domain([startDate, endDate]);
  y.domain([0, d3.max(buckets, d => { return d.values.total; })]);
  xAxis.scale(x).ticks(d3.time.day);
  yAxis.scale(y).tickSize(width);

  d3.transition().duration(1000).each(function () {
    let bars = svg.selectAll('.bar')
        .data(buckets);

    bars.enter().append('g')
        .attr('class', 'bar');

    bars.transition()
        .attr('transform', d => { return `translate(${x(d.key)}, 0)`; });

    let rects = bars.selectAll('rect')
        .data(d => { return d.values; });

    rects.enter().append('rect')
        .style('fill', d => { return color(d.type); });

    rects.transition()
        .attr('width', x(startDate + step)) // x func to derive bar width
        .attr('y', d => { return y(d.y1); })
        .attr('height', d => { return y(d.y0) - y(d.y1); });

    bars.exit().remove();
    rects.exit().remove();

    svg.select('.x.axis').transition().call(xAxis);

    let gy = svg.select('.y.axis').transition()
        .call(yAxis);

    gy.selectAll('g').filter(d => { return d !== 0; })
        .attr('class', 'tick minor');

    gy.selectAll('text')
        .attr('x', -5)
        .attr('dy', 4)
        .style('text-anchor', 'end');
  });
};

export default StackedBarChart;

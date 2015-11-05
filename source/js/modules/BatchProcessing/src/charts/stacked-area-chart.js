import d3 from 'd3';

function StackedAreaChart() {};

StackedAreaChart.prototype.update = function (data) {
  var {xAxis, yAxis, svg, width, height} = this;

  var x = d3.time.scale()
      .range([0, width]);

  var y = d3.scale.linear()
      .range([height, 0]);

  var color = d3.scale.category20();

  var area = d3.svg.area()
      .x(function(d) { return x(d.date); })
      .y0(function(d) { return y(d.y0); })
      .y1(function(d) { return y(d.y0 + d.y); })
      .interpolate('basis');

  xAxis.scale(x)
      .orient('bottom')
      .ticks(d3.time.day);

  yAxis.scale(y);

  var stack = d3.layout.stack()
      .values(function(d) { return d.values; });

  d3.tsv('./public/models/data.tsv', (error, data) => {
    if (error) throw error;

    data.forEach(function(d) {
      d.date = +d.date;
      d.errors = +d.errors;
      d.successes = +d.successes;
    });

    x.domain(d3.extent(data, function(d) { return d.date; }));
    y.domain([0, d3.max(data, function(d) { return d.errors + d.successes; })]);
    color.domain(d3.keys(data[0]).filter(function(key) { return key !== 'date'; }));

    var browsers = stack(color.domain().map(function(name) {
      return {
        name: name,
        values: data.map(function(d) {
          return {date: d.date, y: d[name]};
        })
      };
    }));

    var browser = svg.selectAll('.browser')
        .data(browsers)
      .enter().append('g')
        .attr('class', 'browser');

    browser.append('path')
        .attr('class', 'area')
        .attr('d', function(d) { return area(d.values); })
        .style('fill', function(d) { return color(d.name); });

    svg.append('g')
        .attr('class', 'x axis')
        .attr('transform', 'translate(0,' + height + ')')
        .call(xAxis);

    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis);
  });
};

export default StackedAreaChart;
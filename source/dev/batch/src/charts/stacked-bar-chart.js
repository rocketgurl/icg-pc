import d3 from 'd3';

const hour       = 3600000; // 1 hour = (60 * 60 * 1000)
const bucketSize = hour * 2;
function StackedBarChart() {};

StackedBarChart.prototype.update = function update(data) {
  const {xAxis, yAxis, svg, width, height} = this;

  const x = d3.time.scale()
      .range([0, width]);

  const y = d3.scale.linear()
      .rangeRound([height, 0]);

  const color = d3.scale.category20();

  xAxis.scale(x).ticks(d3.time.day);
  yAxis.scale(y)
      .tickSize(width)
      .orient('right');

  d3.tsv("./public/models/data.tsv", function (error, data) {
    if (error) throw error;

    color.domain(d3.keys(data[0]).filter(key => { return key !== "date"; }));

    // aggregates time series data into buckets (e.g. 1 hour * scalar)
    // creates y values for stacking each separate process type
    const buckets = d3.nest()
      .key(d => { return d.date - (d.date % bucketSize)})
      .rollup(data => {
        let y = 0;
        let total = 0;
        let values = color.domain().map(type => {
          let y0 = y;
          let y1 = total = y += d3.sum(data, d => { return d[type]; });
          return {type, y0, y1};
        });
        values.total = total;
        return values;
      })
      .entries(data);

    const startDate = d3.min(buckets, d => { return +d.key; });

    x.domain(d3.extent(buckets, d => { return +d.key; }));
    y.domain([0, d3.max(buckets, d => { return d.values.total; })]);

    const padding   = 0.1;                            // space between bars
    const step      = bucketSize * (1 - padding * 2); // corrected for padding
    const offset    = step / 2;                       // center bar over the tick
    const barWidth = x(startDate + step);             // x func translates the step to chart proportions

    let bar = svg.selectAll(".bar")
        .data(buckets)
      .enter().append("g")
        .attr("class", "bar")
        .attr("transform", d => { return `translate(${x(d.key - offset)}, 0)`; });

    bar.selectAll("rect")
        .data(d => { return d.values; })
      .enter().append("rect")
        .attr("width", barWidth)
        .attr("y", d => { return y(d.y1); })
        .attr("height", d => { return y(d.y0) - y(d.y1); })
        .style("fill", d => { return color(d.type); });

    var legend = svg.selectAll(".legend")
        .data(color.domain().slice().reverse())
      .enter().append("g")
        .attr("class", "legend")
        .attr("transform", (d, i) => { return `translate(0, ${i * 20})`; });

    legend.append("rect")
        .attr("x", width - 18)
        .attr("width", 18)
        .attr("height", 18)
        .style("fill", color);

    legend.append("text")
        .attr("x", width - 24)
        .attr("y", 9)
        .attr("dy", ".35em")
        .style("text-anchor", "end")
        .text(d => { return d; });

    svg.select(".x.axis").call(xAxis);
    svg.select(".y.axis")
        .call(yAxis)
      .selectAll("text")
        .attr("x", -5)
        .attr("dy", 5)
        .style("text-anchor", "end");

  });
};

export default StackedBarChart;

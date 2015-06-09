import _ from 'underscore';
import Collection from 'ampersand-rest-collection';
import Policy from '../models/policy';

const CHANGE_EVENT = 'change';
const NUM_BUCKETS = 10;
var startDate = new Date("2014-06-07T08:50:59-0400");

export default Collection.extend({
  model: Policy,

  url: './public/models/policies.json',

  // date  errors  successes
  // 11-Oct-13 41.62 22.36
  // 11-Oct-14 41.95 22.15
  // 11-Oct-15 37.64 24.77
  // 11-Oct-16 37.27 24.65
  // 11-Oct-17 42.74 21.87
  // 11-Oct-18 42.14 22.22
  // 11-Oct-19 41.92 22.42
  // 11-Oct-20 42.41 22.08
  // 11-Oct-21 42.74 22.23
  // 11-Oct-22 36.95 25.45
  // 11-Oct-23 37.52 24.73
  // 11-Oct-24 42.69 22.14
  // 11-Oct-25 42.31 22.26
  // 11-Oct-26 42.22 22.28
  // 11-Oct-27 42.62 22.36
  // 11-Oct-28 42.76 22.36
  // 11-Oct-29 38.92 24.36
  // 11-Oct-30 38.06 24.58
  // 11-Oct-31 42.1  22.45
  generateData() {
    var data = [['date', 'errors', 'successes'].join(',')];
    for (let i=0; i < 100; i++) {
      data.push(generateDatum())
    }
    return data.join('\n');
  },

  bucketize(byProp) {
    var d = this.serialize().sort((a, b) => {
      return a[byProp] - b[byProp];
    });
    var min = d[0][byProp];
    var max = _.last(d)[byProp];
    var diff = max - min;
    var size = Math.ceil(diff / NUM_BUCKETS);
    var part = min;
    var buckets = {};
    _.each(d, (item) => {
      var p = item[byProp];
      buckets[part] = buckets[part] || {};
      buckets[part].data = buckets[part].data || [];
      if (p <= part + size) {
        buckets[part].data.push(item);
      } else {
        part = p;
        buckets[part] = {data: [item]};
      }
    })
    return buckets;
  },

  stack() {
    var buckets = this.bucketize('timeStarted');
    _.each(buckets, (b, k) => {
      var complete = 0;
      b = _.extend(b, _.groupBy(b.data, 'status'));
      if (_.has(b, 'Success')) {
        complete += b.Success.length;
      }
      if (_.has(b, 'Error')) {
        complete += b.Error.length;
      }
      b.complete = complete;
    })
    return buckets;
  }

});

function generateData() {
  var data = [['date', 'errors', 'successes'].join(',')];
  for (let i=0; i < 100; i++) {
    data.push(generateDatum())
  }
  return data.join('\n');
}

function generateDatum() {
  var stati = ['Success', 'In Progress', 'Error'];
  var statusCode = generateStatusCode();

  return [
    +(startDate = augmentDate(startDate)),
    generateErrors(),
    generateSuccesses()
  ].join(',');
}

function generateErrors() {
  return randBetween(0, 20);
}

function generateSuccesses() {
  return randBetween(20, 200);
}

function generatePolicyId() {
  var pre = prefix();
  var idx = pad(randBetween(10000, 500000), 7);
  var suf = pad(randBetween(0, 4), 2);
  return `${pre}${idx}${suf}`;
}

function generateStatusCode() {
  var codes = [0, 0, 0, 0, 0, 1, 1, 2, 2, 2];
  return codes[randBetween(0, codes.length-1)]
}

function augmentDate(dateObj) {
  var seconds = randBetween(120000, 360000);
  var minutes = randBetween(2, 30);
  return new Date(dateObj - minutes * seconds);
}

function prefix() {
  var prefixes = ['AKH', 'LUH', 'SCP', 'LAP', 'ALF', 'VAH', 'FNA', 'ALW', 'NYP', 'SCH']
  return prefixes[randBetween(0, prefixes.length-1)]
}

function pad(n, width, z) {
  z = z || '0';
  n = n + '';
  return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
}

function randBetween(a, b) {
  return Math.floor(Math.random() * b) + a;
}

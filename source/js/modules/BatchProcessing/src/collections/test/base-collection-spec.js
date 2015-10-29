import test from 'tape';
import BaseCollection from '../base-collection';

test('baseCollection.getParameters', assert => {
  const collection = new BaseCollection();
  const actual = collection.getParameters();
  const expected = {
    start: 0,
    size: 50,
    sort: 'startTime',
    order: 'desc',
    includeProcessVariables: true
  };
  assert.deepEqual(actual, expected,
    'initial actual parameters should equal the expected');

  assert.end();
});


test('baseCollection.updateParameters', assert => {
  const collection = new BaseCollection();
  const testVal = 'testing';
  let actual;
  let expected;

  collection.updateParameter('test', testVal);
  
  actual = collection.getParameters().test;
  expected = testVal;
  assert.equal(actual, expected);

  collection.updateParameter('test', 'default');

  actual = collection.getParameters().test;
  expected = null;
  assert.equal(actual, expected,
    'updating parameter to "default" should set the property to null');

  assert.end();
});

test('baseCollection.incrementPage', assert => {
  const collection = new BaseCollection();
  let {start} = collection.getParameters();
  let actual;
  let expected;
  
  actual = start;
  expected = 0;
  assert.equal(actual, expected,
    'start parameter should be 0 initially');

  assert.end();
});


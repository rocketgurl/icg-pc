import test from 'tape';
import TasksCollection from '../tasks';

test('tasks.filterByAssignee', assert => {
  const tasks = new TasksCollection();
  const assignee = 'test.user';
  let actual;
  let expected;
  
  actual = tasks.assignee;
  expected = 'default';
  assert.equal(actual, expected,
    'tasks.assignee property should be "default" initially');

  tasks.filterByAssignee(assignee);

  actual = tasks.assignee;
  expected = assignee;
  assert.equal(actual, expected,
    'tasks.assignee property should be equal to filterByAssignee argument');

  actual = tasks.getProcessVariable('currentAssignee');
  expected = {
    name: 'currentAssignee',
    operation: 'equals',
    value: assignee
  };
  assert.deepEqual(actual, expected,
    'there should be a variable object named currentAssignee equal to the assignee');

  tasks.filterByAssignee('default');

  actual = tasks.getProcessVariable('currentAssignee');
  expected = undefined;
  assert.equal(actual, expected,
    'passing "default" should remove the currentAssignee variable object');


  actual = tasks.assignee;
  expected = 'default';
  assert.equal(actual, expected,
    'passing "default" should set tasks.assignee to "default"');

  assert.end();
});

test('tasks.filterByStatus', assert => {
  const tasks = new TasksCollection();
  let status;
  let actual;
  let expected;
  
  actual = tasks.status;
  expected = 'default';
  assert.equal(actual, expected,
    'tasks.status property should be "default" initially');

  // End Success
  status = 'end-success';
  tasks.filterByStatus(status);

  actual = tasks.status;
  expected = status;
  assert.equal(actual, expected,
    'tasks.status property should be equal to filterByStatus argument');

  actual = tasks.getParameters().finished;
  expected = true;
  assert.equal(actual, expected,
    `when status == "${status}" parameter "finished" should be "true"`);

  actual = tasks.getProcessVariable('hasException');
  expected = {
    name: 'hasException',
    operation: 'equals',
    value: false
  };
  assert.deepEqual(actual, expected,
    `when status == "${status}" there should be a variable object named "hasException" equal to false`);

  // End Error
  status = 'end-error';
  tasks.filterByStatus(status);

  actual = tasks.getParameters().finished;
  expected = true;
  assert.equal(actual, expected,
    `when status == "${status}" parameter "finished" should be true`);

  actual = tasks.getProcessVariable('hasException');
  expected = {
    name: 'hasException',
    operation: 'equals',
    value: true
  };
  assert.deepEqual(actual, expected,
    `when status == "${status}" there should be a variable object named "hasException" equal to true`);

  // Action Required
  status = 'action-required';
  tasks.filterByStatus(status);

  actual = tasks.getParameters().finished;
  expected = false;
  assert.equal(actual, expected,
    `when status == "${status}" parameter "finished" should be false`);

  actual = tasks.getProcessVariable('hasException');
  expected = {
    name: 'hasException',
    operation: 'equals',
    value: true
  };
  assert.deepEqual(actual, expected,
    `when status == "${status}" there should be a variable object named "hasException" equal to true`);

  // In Progress
  status = 'in-progress';
  tasks.filterByStatus(status);

  actual = tasks.getParameters().finished;
  expected = false;
  assert.equal(actual, expected,
    `when status == "${status}" parameter "finished" should be false`);

  actual = tasks.getProcessVariable('hasException');
  expected = {
    name: 'hasException',
    operation: 'equals',
    value: false
  };
  assert.deepEqual(actual, expected,
    `when status == "${status}" there should be a variable object named "hasException" equal to false`);

  // Default
  status = 'default';
  tasks.filterByStatus(status);

  actual = tasks.getParameters().finished;
  expected = null;
  assert.equal(actual, expected,
    `when status == "${status}" parameter "finished" should be null`);

  actual = tasks.getProcessVariable('hasException');
  expected = undefined
  assert.equal(actual, expected,
    `when status == "${status}" the variable object named "hasException" should not exist`);

  actual = tasks.status;
  expected = 'default';
  assert.equal(actual, expected,
    'passing "default" should set tasks.status to "default"');

  assert.end();
});


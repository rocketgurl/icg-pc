import test from 'tape';
import TasksCollection from '../tasks';


test('tasks.assignee property should be null initially', assert => {
  const tasks = new TasksCollection();
  const assignee = 'test.user';
  
  const actual = tasks.assignee;
  const expected = null;
  assert.equal(actual, expected);

  assert.end();
});

test('tasks.assignee property should be equal to filterByAssignee argument', assert => {
  const tasks = new TasksCollection();
  const assignee = 'test.user';

  tasks.filterByAssignee(assignee);

  const actual = tasks.assignee;
  const expected = assignee;
  assert.equal(actual, expected);

  assert.end();
});

test('there should be a variable object named currentAssignee equal to the assignee name', assert => {
  const tasks = new TasksCollection();
  const assignee = 'test.user';

  tasks.filterByAssignee(assignee);

  const actual = tasks.getProcessVariable('currentAssignee');
  const expected = {
    name: 'currentAssignee',
    operation: 'equals',
    value: assignee
  };
  assert.deepEqual(actual, expected);

  assert.end();
});

test('passing a null argument should remove the currentAssignee variable object', assert => {
  const tasks = new TasksCollection();
  const assignee = 'test.user';

  tasks.filterByAssignee(assignee);
  tasks.filterByAssignee(null);

  const actual = tasks.getProcessVariable('currentAssignee');
  const expected = undefined;
  assert.equal(actual, expected);

  assert.end();
});

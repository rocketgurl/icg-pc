import React from 'react';
import app from 'ampersand-app';
import TabContent from './tab-content';
import AlertQueue from './alert-queue';
import BatchActionSelect from './batch-action-select';
import BatchActionModal from './batch-action-modal';
import TaskActionSelect from './task-action-select';
import BatchesTable from './batches-table';
import TasksTable from './tasks-table';
import {Nav, NavItem, TabPane} from 'react-bootstrap';

export default React.createClass({
  getDefaultProps() {
    return {
      showBatchActionModal: false,
      activeBatchId: '0',
      batchType: null
    };
  },

  getInitialState() {
    return {
      tab: this.props.tab || 'batches',
      batches: app.batches,
      errors: app.errors
    };
  },

  componentWillReceiveProps(props) {
    if (props.tab) {
      this.setState({tab: props.tab});
    }
  },

  componentWillMount() {
    app.batches.on('sync', this._onBatchesSync);
    app.errors.on('add remove', this._onErrorsUpdate);
  },

  componentWillUnmount() {
    app.batches.off();
    app.errors.off();
  },

  // Determine the correct collection of tasks and return it
  // along with the <TasksTable/> node
  getTasksTable() {
    const {activeBatchId} = this.props;
    if (app.batches.length) {
      const activeBatch = app.batches.get(activeBatchId);
      const collection = activeBatch ?
        activeBatch.tasks : app.allTasks;
      return <TasksTable key={activeBatchId} collection={collection}/>
    }
  },

  render() {
    const {tab, errors} = this.state;
    const {showBatchActionModal, batchType, actionName} = this.props;
    return (
      <div>
        <AlertQueue collection={errors}/>
        <div className="row action-row">
          <BatchActionSelect router={app.router}/>
          <BatchActionModal
            showModal={showBatchActionModal}
            actionName={actionName}
            batchType={batchType}
            router={app.router}/>
          <TaskActionSelect router={app.router}/>
        </div>
        <div className="panel panel-default panel-nav">
          <Nav bsStyle="tabs" activeKey={tab}>
            <NavItem eventKey="batches" href="#batches">Batches</NavItem>
            <NavItem eventKey="tasks" href="#tasks">Tasks</NavItem>
          </Nav>
          <div className="panel-body">
            <TabContent activeKey={tab}>
              <TabPane key="batches">
                <BatchesTable collection={this.state.batches}/>
              </TabPane>
              <TabPane key="tasks">
                {this.getTasksTable()}
              </TabPane>
            </TabContent>
          </div>
        </div>
      </div>
    );
  },

  _onErrorsUpdate(error, errors) {
    this.setState({errors});
  },

  _onBatchesSync(batches) {
    this.setState({batches});
  }
});

import React from 'react';
import app from 'ampersand-app';
import {Nav, NavItem, Tab} from 'react-bootstrap';
import {CONTROLS_HEIGHT} from '../constants';
import TabContent from './tab-content';
import AlertQueue from './alert-queue';
import BatchActionSelect from './batch-action-select';
import BatchActionModal from './batch-action-modal';
import TaskActionSelect from './task-action-select';
import BatchesTable from './batches-table';
import TasksTable from './tasks-table';
import Progress from './progress';

export default React.createClass({
  getDefaultProps() {
    return {
      showBatchActionModal: false,
      activeBatchId: '0',
      batchType: null,
      working: false
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
    app.on({
      request: this._onAppRequest,
      complete: this._onAppComplete
    });
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
    const {tab, errors, working} = this.state;
    const {showBatchActionModal, batchType, actionName} = this.props;
    return (
      <div>
        <Progress working={working}/>
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
              <Tab key="batches">
                <BatchesTable collection={this.state.batches}/>
              </Tab>
              <Tab key="tasks">
                {this.getTasksTable()}
              </Tab>
            </TabContent>
          </div>
        </div>
      </div>
    );
  },

  _onAppRequest() {
    this.setState({working: true});
  },

  _onAppComplete() {
    this.setState({working: false});
  },

  _onErrorsUpdate(error, errors) {
    this.setState({errors});
  },

  _onBatchesSync(batches) {
    this.setState({batches});
  }
});

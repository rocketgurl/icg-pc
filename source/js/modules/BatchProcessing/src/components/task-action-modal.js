import React from 'react';
import {Modal} from 'react-bootstrap';
import TaskAssign from './task-action-assign';
import TaskComplete from './task-action-complete';
import {batches, allTasks, selectedTasks, taskAction} from 'ampersand-app';

export default React.createClass({
  propTypes: {
    showModal: React.PropTypes.bool.isRequired,
    actionName: React.PropTypes.string,
    taskType: React.PropTypes.string,
    onHide: React.PropTypes.func.isRequired
  },

  getInitialState() {
    const {showModal, batchType} = this.props;
    return {
      showModal: !!(showModal && taskType),
      isRequesting: false
    };
  },

  componentDidMount() {
    taskAction.on({
      request: this._onRequest,
      error: this._onComplete,
      sync: this._onComplete
    });
  },

  componentWillUnmount() {
    taskAction.off();
  },

  componentWillReceiveProps(props) {
    const {showModal, taskType} = props;
    this.setState({
      showModal: !!(showModal && taskType)
    });
  },

  render() {
    const {isRequesting} = this.state;
    const {onHide, actionName, taskType} = this.props;
    return (
      <Modal show={this.state.showModal} onHide={onHide}>
        <Modal.Header closeButton>
          <Modal.Title>{actionName}</Modal.Title>
        </Modal.Header>
        {this.props.taskType === 'assign' ?
          <TaskAssign
            selectedTasks={selectedTasks}
            taskAction={taskAction}
            isRequesting={isRequesting}
            parentClose={onHide}/> :
          <TaskComplete
            selectedTasks={selectedTasks}
            taskAction={taskAction}
            taskType={taskType}
            actionName={actionName}
            isRequesting={isRequesting}
            parentClose={onHide}/>}
      </Modal>
    );
  },

  _onRequest() {
    this.setState({isRequesting: true});
  },

  _onComplete() {
    this.setState({isRequesting: false});
    this.props.onHide();
    batches.query();
    allTasks.query();
  }
});

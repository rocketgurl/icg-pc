import React from 'react';
import {Modal} from 'react-bootstrap';
import TextArea from './batch-action-textarea';
import FileInput from './batch-action-fileinput';
import {batches, allJobs, formData} from 'ampersand-app';

export default React.createClass({
  getInitialState() {
    const {showModal, batchType} = this.props;
    return {
      showModal: !!(showModal && batchType),
      isRequesting: false
    };
  },

  componentDidMount() {
    formData.on({
      request: this._onRequest,
      error: this._onComplete,
      sync: this._onComplete
    });
  },

  componentWillUnmount() {
    formData.off();
  },

  componentWillReceiveProps(props) {
    const {showModal, batchType} = props;
    this.setState({
      showModal: !!(showModal && batchType)
    });
    formData.setBatchType(batchType);
  },

  // close the modal by clearing the modal route
  close() {
    this.props.router.navigate('/');
  },

  render() {
    const {isRequesting} = this.state;
    return (
      <Modal show={this.state.showModal} onHide={this.close}>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.actionName}</Modal.Title>
        </Modal.Header>
        {this.props.batchType === 'payment' ?
          <FileInput
            isRequesting={isRequesting}
            formData={formData}
            parentClose={this.close}/> :
          <TextArea
            isRequesting={isRequesting}
            formData={formData}
            parentClose={this.close}/>}
      </Modal>
    );
  },

  _onRequest() {
    this.setState({isRequesting: true});
  },

  _onComplete() {
    this.setState({isRequesting: false});
    this.close();
    batches.query();
    allJobs.query();
  }
});

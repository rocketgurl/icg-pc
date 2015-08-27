import React from 'react';
import {Modal} from 'react-bootstrap';

export default React.createClass({
  getInitialState() {
    const {showModal, processDefinitionId} = this.props;
    return {
      showModal: !!(showModal && processDefinitionId)
    };
  },

  componentWillReceiveProps(props) {
    const {showModal, processDefinitionId} = props;
    this.setState({
      showModal: !!(showModal && processDefinitionId)
    });
  },

  // close the modal by navigating away from the modal route
  close() {
    this.props.router.navigate('/');
  },

  render() {
    return (
      <Modal show={this.state.showModal} onHide={this.close}>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.actionName}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Enter 1 Policy Number per line</p>
          <textarea className="form-control" rows="10"></textarea>
        </Modal.Body>
        <Modal.Footer>
          <button className="btn btn-default" onClick={this.close}>Cancel</button>
          <button className="btn btn-primary" onClick={this._onSubmitClick}>Submit</button>
        </Modal.Footer>
      </Modal>
    );
  },

  _onSubmitClick(e) {
    console.log({...e})
  }
});

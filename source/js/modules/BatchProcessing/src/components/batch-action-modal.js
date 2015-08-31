import React from 'react';
import {Modal} from 'react-bootstrap';
import {batches, allPolicies, formData} from 'ampersand-app';

const placeHolder = `ABCXXXXXXXXX
DEFXXXXXXXXX
GHIXXXXXXXXX
JKLXXXXXXXXX
...`;

export default React.createClass({
  getInitialState() {
    const {showModal, processDefinitionId} = this.props;
    return {
      showModal: !!(showModal && processDefinitionId),
      invalidRefs: [],
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
    const {showModal, processDefinitionId} = props;
    this.setState({
      showModal: !!(showModal && processDefinitionId)
    });
    formData.setProcessDefinitionId(processDefinitionId);
  },

  // close the modal by navigating away from the modal route
  close() {
    this.props.router.navigate('/');
  },

  getPolicyRefsStr() {
    const policyRefsNode = this.refs.policyRefs.getDOMNode();
    const policyRefsArray = formData.splitRefsStr(policyRefsNode.value);
    const invalidRefs = formData.validateRefs(policyRefsArray);
    this.setState({invalidRefs});
    if (!invalidRefs.length) return policyRefsArray.join(',');
  },

  alertInvalid() {
    return (
      <div className="alert alert-danger">
        <strong>The following items contain 1 or more [invalid characters]:</strong>
        <ol>
          {this.state.invalidRefs.map((ref, index) => {
            return <li key={index}>{ref}</li>;
          })}
        </ol>
      </div>
      );
  },

  render() {
    const {isRequesting} = this.state;
    return (
      <Modal show={this.state.showModal} onHide={this.close}>
        <Modal.Header closeButton>
          <Modal.Title>{this.props.actionName}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <p>Enter 1 Policy Number per line</p>
          {this.state.invalidRefs.length ? this.alertInvalid() : null}
          <textarea
            ref="policyRefs"
            className="form-control"
            rows="10"
            disabled={isRequesting}
            placeholder={placeHolder}/>
        </Modal.Body>
        <Modal.Footer>
          <button
            className="btn btn-default"
            disabled={isRequesting}
            onClick={this.close}>
            Cancel
          </button>
          <button
            className="btn btn-primary"
            disabled={isRequesting}
            onClick={this._onSubmitClick}>
            Submit
          </button>
        </Modal.Footer>
      </Modal>
    );
  },

  _onSubmitClick(e) {
    const refsString = this.getPolicyRefsStr();
    if (refsString) {
      formData.addProperty('policyRefsStr', refsString);
      formData.submit();
    }
  },

  _onRequest() {
    this.setState({isRequesting: true});
  },

  _onComplete() {
    this.setState({isRequesting: false});
    this.close();
    batches.query();
    allPolicies.query();
  }
});

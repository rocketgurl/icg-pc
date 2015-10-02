import React from 'react';
import {Modal} from 'react-bootstrap';

const placeHolder = `ABCXXXXXXXXX
DEFXXXXXXXXX
GHIXXXXXXXXX
JKLXXXXXXXXX
...`;

export default React.createClass({
  propTypes: {
    formData: React.PropTypes.object.isRequired,
    parentClose: React.PropTypes.func.isRequired,
    isRequesting: React.PropTypes.bool.isRequired
  },

  getInitialState() {
    return {
      invalidRefs: []
    };
  },

  getPolicyRefsStr() {
    const policyRefsNode = this.refs.policyRefs.getDOMNode();
    const policyRefsArray = this.props.formData.splitRefsStr(policyRefsNode.value);
    const invalidRefs = this.props.formData.validateRefs(policyRefsArray);
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
    const {isRequesting} = this.props;
    return (
      <div className="text-area">
        <Modal.Body>
          <p>Enter 1 Policy Number per Line</p>
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
            onClick={this.props.parentClose}>
            Cancel
          </button>
          <button
            className="btn btn-primary"
            disabled={isRequesting}
            onClick={this._onSubmitClick}>
            Submit
          </button>
        </Modal.Footer>
      </div>
    );
  },

  _onSubmitClick(e) {
    const {formData} = this.props;
    const refsString = this.getPolicyRefsStr();
    if (refsString) {
      formData.setBody({policyRefsStr: refsString});
      formData.submit();
    }
  }
});
import React from 'react';
import _ from 'underscore';
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
    const policyRefsArray = this.splitRefsStr(policyRefsNode.value);
    const invalidRefs = this.validateRefs(policyRefsArray);
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
            Run Job
          </button>
        </Modal.Footer>
      </div>
    );
  },

  // will trim & split any values separated
  // by any number of whitespace chars
  splitRefsStr(str) {
    const trimmed = str.trim();
    const split = trimmed.split(/\s+/);
    return split;
  },

  // check an array of policy refs for any characters
  // other than alpha-numeric.
  // @returns an array of invalid refs with offending
  // chars bracketed. If all refs are valid, returns
  // an empty array
  validateRefs(refsArray) {
    const invalidChars = /[^A-Z0-9-]+/gi;
    const invalidRefs = [];
    _.each(refsArray, ref => {
      if (invalidChars.test(ref)) {
        invalidRefs.push(ref.replace(invalidChars, $1 => {
          return `[${$1}]`;
        }));
      }
    });
    return invalidRefs;
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
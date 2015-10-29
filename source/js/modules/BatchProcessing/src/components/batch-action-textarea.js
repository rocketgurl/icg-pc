import React from 'react';
import _ from 'underscore';
import {Modal} from 'react-bootstrap';
import {validateString, validatePolicyNum} from '../lib/validators';

const placeHolder = `ABC0123456
DEF0123456
GHI0123456
JKL0123456
...`;

export default React.createClass({
  propTypes: {
    formData: React.PropTypes.object.isRequired,
    parentClose: React.PropTypes.func.isRequired,
    isRequesting: React.PropTypes.bool.isRequired
  },

  getInitialState() {
    return {
      invalidRefs: [],
      transformedRefs: {},
      origRefsStr: '',
      truncRefsStr: ''
    };
  },

  alertInvalid() {
    return (
      <div className="alert alert-danger">
        <strong>The following errors were detected:</strong>
        <code>
          <ol>
            {this.state.invalidRefs.map((ref, index) => {
              return <li key={index}>{ref}</li>;
            })}
          </ol>
        </code>
      </div>
      );
  },

  alertInfo() {
    return (
      <div className="alert alert-info">
        <h5>The following Policy IDs will be changed from the entered values:</h5>
        <code>
          <ul className="list-unstyled change-list">
            {_.map(this.state.transformedRefs, (item, row) => {
              return (
                <li key={row}>
                  <span className="row-num">{`${row}.`}</span>
                  <span className="lhs">{item.orig}</span>
                  <span>to</span>
                  <span className="rhs">{item.trans}</span>
                </li>);
            })}
          </ul>
        </code>
        <em>To avoid this message in the future, format your Policy IDs as follows: ABC0123456</em>
      </div>
      );
  },

  render() {
    const {isRequesting} = this.props;
    const {invalidRefs, transformedRefs, truncRefsStr} = this.state;
    const isEmpty = !truncRefsStr.length
    const hasErrors = invalidRefs.length;
    return (
      <div className="text-area">
        <Modal.Body>
          <p>Enter 1 Policy Number per Line</p>
          {invalidRefs.length ? this.alertInvalid() : null}
          {!_.isEmpty(transformedRefs) ? this.alertInfo() : null}
          <textarea
            ref="policyRefs"
            className="form-control"
            rows="10"
            disabled={isRequesting}
            placeholder={placeHolder}
            onChange={this._onTextChange}/>
        </Modal.Body>
        <Modal.Footer>
          <button
            className="btn btn-default"
            disabled={isRequesting}
            onClick={this.props.parentClose}>
            Cancel
          </button>
          <button
            className={`btn ${hasErrors ? 'btn-danger' : 'btn-primary'}`}
            disabled={isEmpty || isRequesting || hasErrors}
            onClick={this._onSubmitClick}>
            {hasErrors ? 'Please Fix Errors' : 'Run Tasks'}
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

  parsePolicyRefsStr(refsStr) {
    let policyRefsArray = this.splitRefsStr(refsStr);
    let invalidRefs     = [];
    let truncatedRefs   = [];
    let transformedRefs = {};

    // check policy ref for any characters other than alpha-numeric.
    _.each(policyRefsArray, (ref, index) => {
      ref = validateString(ref, index+1, /[^A-Z0-9-]+/gi);
      if (ref.indexOf('Error') === -1) ref = validatePolicyNum(ref);
      if (ref.indexOf('Error') > -1) {
        invalidRefs.push(ref);
      } else {
        if (ref.length > 10) {
          transformedRefs[index+1] = {orig: ref, trans: ref.slice(0, 10)};
        }
        truncatedRefs.push(`${parseFloat(ref.slice(3, 10))}`);
      }
    });

    this.setState({
      invalidRefs,
      transformedRefs,
      origRefsStr: policyRefsArray.join(','),
      truncRefsStr: truncatedRefs.join(',')
    });
  },

  _onTextChange(e) {
    this.parsePolicyRefsStr(e.target.value);
  },

  _onSubmitClick(e) {
    const {formData} = this.props;
    formData.setBody({
      origPolicyRefsStr: this.state.origRefsStr,
      policyRefsStr: this.state.truncRefsStr
    });
    formData.query();
  }
});
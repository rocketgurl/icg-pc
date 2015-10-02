import React from 'react';
import _ from 'underscore';
import moment from 'moment';
import {Modal} from 'react-bootstrap';
import Papa from 'papaparse';

export default React.createClass({
  propTypes: {
    formData: React.PropTypes.object.isRequired,
    parentClose: React.PropTypes.func.isRequired,
    isRequesting: React.PropTypes.bool.isRequired
  },

  getInitialState() {
    return {
      paymentsList: [],
      data: [],
      errors: [],
      meta: {}
    };
  },

  getPolicyRefsStr() {
    const policyRefsNode = this.refs.policyRefs.getDOMNode();
    const policyRefsArray = this.props.formData.splitRefsStr(policyRefsNode.value);
    const invalidRefs = this.props.formData.validateRefs(policyRefsArray);
    this.setState({invalidRefs});
    if (!invalidRefs.length) return policyRefsArray.join(',');
  },

  alertErrors() {
    return _.map(this.state.errors, (error, index) => {
      return (
        <div key={index} className="alert alert-danger form-horizontal">
          <ul className="list-unstyled list-labeled">
            <li className="clearfix">
              <label className="col-xs-3">Error ({error.type}):</label>
              <div className="col-xs-9">{error.code}</div>
            </li>
            <li className="clearfix">
              <label className="col-xs-3">Message:</label>
              <div className="col-xs-9">{error.message}</div>
            </li>
            <li className="clearfix">
              <label className="col-xs-3">Row:</label>
              <div className="col-xs-9">{error.row}</div>
            </li>
          </ul>
        </div>
      );
    });
  },

  buildTable() {
    const {data, errors, meta} = this.state;
    if (data.length > 0) {
      return (
        <table className="table table-condensed">
          <thead>
            <tr>
              <th>#</th>
              {_.map(meta.fields, (field, index) => {
                return <th key={index}>{field}</th>;
              })}
            </tr>
          </thead>
          <tbody>
            {_.map(data, (row, index) => {
              return (
                <tr key={index} className={row.Invalid ? 'danger' : null}>
                  <th scope="row">{index+1}</th>
                  {_.map(row, (col, index) => {
                    return <td key={index}>{col}</td>
                  })}
                </tr>);
            })}
          </tbody>
        </table>
      );
    }
  },

  render() {
    const {isRequesting} = this.props;
    const hasErrors = this.state.errors.length > 0;
    const hasPayments = this.state.paymentsList.length > 0;
    return (
      <div className="file-upload">
        <Modal.Body>
          {this.alertErrors()}
          <p>Select a CSV File to Upload</p>
          <div className="well">
            <input
              type="file"
              accept=".csv"
              ref="fileInput"
              onClick={this._onFileInputClick}
              onChange={this._onFileInputChange}
              disabled={isRequesting}/>
          </div>
          {this.buildTable()}
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
            disabled={!hasPayments || isRequesting || hasErrors}
            onClick={this._onSubmitClick}>
            {hasErrors ? 'Please Fix Errors' : 'Submit'}
          </button>
        </Modal.Footer>
      </div>
    );
  },


  // Validate the data & match the following format
  // for submission to api:
  // 
  // [{
  //   "policyLookup": "AKH042758600",
  //   "method": "ach",
  //   "receivedDate": "2015-09-09T00:00:00.000-04:00",
  //   "lockBoxReference": "",
  //   "amount": 21.00,
  //   "referenceNum": "12345"
  // }]
  _processCSVData(results) {
    let paymentsList = [];
    if (results.errors.length === 0) {
      _.each(results.data, (row, index) => {
        try {
          const policyLookup = this.validate(row.PolicyNumberBase, 'PolicyLookup');
          const method = this.validate(row.PaymentMethod, 'PaymentMethod');
          const lockBoxReference = row.LockBoxReference.trim();
          const referenceNum = row.PaymentReference.trim();
          const receivedDate = moment(row.PaymentDate, 'MM/DD/YYYY').format();
          const amount = parseFloat(row.Amount.replace('$', ''));
          
          // validation hurdles
          if (policyLookup.indexOf('Error') > -1) {
            results.errors.push(this._formatError(
              'PolicyNumberBase',
              policyLookup,
              index+1));
            row.Invalid = true;
          }
          if (method.indexOf('Error') > -1) {
            results.errors.push(this._formatError(
              'PaymentMethod',
              method,
              index+1));
            row.Invalid = true;
          }
          if (receivedDate === 'Invalid date') {
            results.errors.push(this._formatError(
              'PaymentDate',
              'PaymentDate must be a valid date and match format MM/DD/YYYY',
              index+1));
            row.Invalid = true;
          }
          if (isNaN(amount)) {
            results.errors.push(this._formatError(
              'PaymentAmount',
              'Non-numeric characters detected in PaymentAmount',
              index+1));
            row.Invalid = true;
          }

          paymentsList.push({
            policyLookup,
            method,
            receivedDate,
            lockBoxReference,
            amount,
            referenceNum
          });
        } catch (e) {
          results.errors.push(this._formatError(
            'Exception',
            e.toString()));
          console.error('FILE UPLOAD ERROR:', e);
        }
      });
    }
    this.setState({paymentsList, ...results});
  },

  validate(str="", type="") {
    const invalidChars = /[^A-Z0-9-]+/gi;
    str = str.trim();
    if (str.length === 0) {
      return `Error: ${type} value is empty`;
    }
    if (invalidChars.test(str)) {
      str = str.replace(invalidChars, $1 => {
        return `[${$1}]`;
      });
      return `Error: Invalid chars in ${type}: ${str}`;
    }
    return str;
  },

  _formatError(type, message, row) {
    return {code: `Invalid${type}`, type, message, row};
  },

  // Clears the selected file & re-arms the onChange event.
  // Useful when a user must select the same file multiple times
  // E.g. when fixing an error.
  _onFileInputClick(e) {
    e.target.value = '';
  },

  _onFileInputChange(e) {
    const fileList = e.target.files;
    if (fileList.length > 0) {
      Papa.parse(fileList[0], {
        header: true,
        complete: this._processCSVData
      });
    }
  },

  _onSubmitClick(e) {
    const {formData} = this.props;
    const {paymentsList} = this.state;
    if (paymentsList.length) {
      formData.setBody({paymentsList});
      formData.submit();
    }
  }
});
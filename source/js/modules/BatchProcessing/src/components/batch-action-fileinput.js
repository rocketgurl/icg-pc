import React from 'react';
import _ from 'underscore';
import moment from 'moment';
import {Modal} from 'react-bootstrap';
import Papa from 'papaparse';

// 2015-09-09T00:00:00.000-04:00
const DATE_FORMAT = 'YYYY-MM-DDThh:mm:ss.SSSZ'

// TODO: generalize this. Move form validation
// and Payment-specific stuff into separate library
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
      meta: {},
      totalBatchAmountExpected: 0,
      totalBatchAmountActual: 0,
      totalNumPaymentsExpected: 0,
      totalNumPaymentsActual: 0
    };
  },

  alertErrors() {
    return _.map(this.state.errors, (error, index) => {
      return (
        <div key={index} className="alert alert-danger form-horizontal">
          <ul className="list-unstyled list-labeled">
            {error.code ?
            <li className="clearfix">
              <label className="col-xs-3">Error:</label>
              <div className="col-xs-9">{error.code}</div>
            </li> : null}
            {error.message ?
            <li className="clearfix">
              <label className="col-xs-3">Message:</label>
              <div className="col-xs-9">{error.message}</div>
            </li> : null}
            {error.row ?
            <li className="clearfix">
              <label className="col-xs-3">Row:</label>
              <div className="col-xs-9">{error.row}</div>
            </li> : null}
          </ul>
        </div>
      );
    });
  },

  render() {
    const {isRequesting} = this.props;
    const hasErrors = this.state.errors.length > 0;
    const hasPayments = this.state.paymentsList.length > 0;

    // compare expected values with actual values
    const batchAmountMatch = (!hasPayments ||
      (parseFloat(this.state.totalBatchAmountExpected) === this.state.totalBatchAmountActual));
    const numPaymentsMatch = (!hasPayments ||
      (parseFloat(this.state.totalNumPaymentsExpected) === this.state.totalNumPaymentsActual));
    const hasMismatch = !batchAmountMatch || !numPaymentsMatch;

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
          <div className="row">
            <div className={`form-group calc-group col-xs-6${batchAmountMatch ? '' : ' has-error'}`}>
              <label
                htmlFor="batch-amount"
                className="control-label">Total Batch Amount</label>
              <div className="input-group">
                <div className="input-group-addon">$</div>
                <input
                  type="text"
                  ref="totalBatchAmount"
                  className="form-control"
                  name="totalBatchAmountExpected"
                  onChange={this._onTextInputChange}
                  value={this.state.totalBatchAmountExpected}/>
              </div>
              <div className={`calculated text-danger${batchAmountMatch ? ' invisible' : ''}`}>
                <strong>{this.state.totalBatchAmountActual.toLocaleString()}</strong> calculated from CSV
              </div>
            </div>
            <div className={`form-group calc-group col-xs-6${numPaymentsMatch ? '' : ' has-error'}`}>
              <label
                htmlFor="num-payments"
                className="control-label">Total Number of Payments</label>
              <div className="input-group">
                <div className="input-group-addon">#</div>
                <input
                  type="text"
                  ref="totalNumPayments"
                  className="form-control"
                  name="totalNumPaymentsExpected"
                  onChange={this._onTextInputChange}
                  value={this.state.totalNumPaymentsExpected}/>
              </div>
              <div className={`calculated text-danger${numPaymentsMatch ? ' invisible' : ''}`}>
                <strong>{this.state.totalNumPaymentsActual.toLocaleString()}</strong> calculated from CSV
              </div>
            </div>
          </div>
        </Modal.Body>
        <Modal.Footer>
          <button
            className="btn btn-default"
            disabled={isRequesting}
            onClick={this.props.parentClose}>
            Cancel
          </button>
          <button
            className={`btn ${hasErrors || hasMismatch ? 'btn-danger' : 'btn-primary'}`}
            disabled={!hasPayments || isRequesting || hasErrors || hasMismatch}
            onClick={this._onSubmitClick}>
            {hasErrors || hasMismatch ? 'Please Fix Errors' : 'Run Tasks'}
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

    // initialize accumulator value
    results.totalBatchAmountActual = 0;

    // check for any missing columns
    const missingFields = this.validateFields(results.meta.fields);
    if (missingFields.length > 0) {
      results.errors.push(this._formatError(
        'Fields',
        `The following field(s) are missing from the CSV:\n[${missingFields.join(', ')}]`,
        0));
    }

    if (results.errors.length === 0) {
      paymentsList = _.map(results.data, (row, index) => {
        
        // check each column in the row for invalid characters
        // (except for the Date and Amount columns)
        // push any invalid matches onto the errors array
        let validated = {};
        _.each(_.omit(row, 'PaymentReceivedDate', 'Amount'), (val, key) => {
          val = this.validateString(val, key, /[^A-Z0-9-]+/gi);
          if (val.indexOf('Error') > -1) {
            results.errors.push(this._formatError(key, val, index+1));
          }
          validated[key] = val;
        });

        // delegate date validation for received date to moment
        const receivedDate = moment(row.PaymentReceivedDate, 'MM/DD/YYYY');
        if (receivedDate === 'Invalid date') {
          results.errors.push(this._formatError(
            'PaymentReceivedDate',
            'PaymentReceivedDate must be a valid date and match format MM/DD/YYYY',
            index+1));
        }

        // verify amount is a number
        // if so, add it to the total batch amount
        let amount = row.Amount.replace(/[$,]/g, ''); // strip out any commas and $'s
        amount = this.validateString(amount, 'Amount', /[^0-9\.]/g);
        if (amount.indexOf('Error') > -1) {
          results.errors.push(this._formatError(
            'Amount',
            amount,
            index+1));
        } else {
          results.totalBatchAmountActual += parseFloat(amount);
        }

        // push items onto an array of data objects
        // formatted for api consumption
        return {
          amount: parseFloat(amount),
          receivedDate: receivedDate.format(DATE_FORMAT),
          method: validated.PaymentMethod,
          referenceNum: validated.PaymentReference,
          policyLookup: validated.PolicyNumberBase,
          lockBoxReference: validated.LockBoxReference
        };
      });
    }
    results.totalNumPaymentsActual = paymentsList.length;
    this.setState({paymentsList, ...results});
  },

  // CSV must contain at least the following fields
  validateFields(actualFields) {
    const expectedFields = [
      'PaymentMethod',
      'PaymentReceivedDate',
      'LockBoxReference',
      'Amount',
      'PaymentReference',
      'PolicyNumberBase'
    ];
    return _.difference(expectedFields, actualFields);
  },

  validateString(str="", type="", invalid=/[]/) {
    str = str.trim();
    if (str.length === 0) {
      return `Error: ${type} value is empty`;
    }
    if (invalid.test(str)) {
      str = str.replace(invalid, $1 => {
        return `[${$1}]`
      });
      return `Error: Invalid chars in ${type}: ${str}`;
    }
    return str;
  },

  _formatError(type, message, row) {
    return {code: `Invalid${type}`, type, message, row};
  },

  _onTextInputChange(e) {
    const {name, value} = e.target;
    const stateObj = {};
    stateObj[name] = value.replace(/[$,]/g, '');
    this.setState(stateObj);
  },

  _onFileInputClick(e) {
    let errors = [];
    let {totalBatchAmountExpected,
      totalNumPaymentsExpected} = this.state;

    // check that validation inputs have something greater than 0
    if (totalBatchAmountExpected == 0) {
      errors.push(this._formatError('TotalBatchAmount',
        'Please enter expected total batch amount'));
      e.preventDefault();
    }
    if (totalNumPaymentsExpected == 0) {
      errors.push(this._formatError('TotalNumberOfPayments',
        'Please enter expected total number of payments'));
      e.preventDefault();
    }
    this.setState({errors});

    // Clears the selected file & re-arms the onChange event.
    // Useful when a user must select the same file multiple times
    // E.g. when fixing an error.
    e.target.value = '';
  },

  _onFileInputChange(e) {
    const fileList = e.target.files;
    if (fileList.length > 0) {
      Papa.parse(fileList[0], {
        header: true,
        skipEmptyLines: true,
        complete: this._processCSVData
      });
    }
  },

  _onSubmitClick(e) {
    const {formData} = this.props;
    const {paymentsList} = this.state;
    if (paymentsList.length) {
      formData.setBody(paymentsList);
      formData.submit();
    }
  }
});
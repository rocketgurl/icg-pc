import React from 'react';
import sortableTableMixin from '../lib/sortable-table-mixin';
import BatchRow from './batch-row';
import TableControls from './table-controls';

const batchTypes = [
  {name: 'Invoicing', value: 'batchInvoicing'},
  {name: 'Issuance', value: 'batchIssuance'},
  {name: 'Payments', value: 'batchPayment'}
];

export default React.createClass({
  mixins: [sortableTableMixin],

  getInitialState() {
    return {
      sortTable: {
        startTime: {
          active: true,
          order: 'desc'
        }
      }
    };
  },

  componentWillMount() {
    const {collection} = this.props;
    this.setState({collection, ...collection.getParameters()});
    if (!collection.length) {
      collection.query();
    }
  },

  makeQuery() {
    this.props.collection.query();
  },

  render() {
    const {sort, order, collection} = this.state;
    return (
      <div>
        <div className="tab-pane-heading">
          <TableControls {...this.state}
            batchTypes={batchTypes}
            pageStart={collection.pageStart}
            pageEnd={collection.pageEnd}
            totalItems={collection.totalItems}
            incrementPage={this._onPageIncrement}
            decrementPage={this._onPageDecrement}
            refreshPage={this.makeQuery}
            updateParameter={this._onParameterUpdate}/>
        </div>
        <div className="div-table panel-table table-striped table-hover table-scrollable table-sortable table-5-columns">
          <div className="thead">
            <div className="tr">
              <div className="th">Status</div>
              <div className="th">Batch ID</div>
              <div className="th">Quantity</div>
              <div className="th">
                <a data-sortby="startTime"
                  className={sort === 'startTime' ? order : null}
                  onClick={this._onHeaderClick}>
                  Time Started <span className="caret"/>
                </a>
              </div>
              <div className="th">Initiator</div>
            </div>
          </div>
          <div className="tbody" style={{maxHeight: `${500}px`}}>
            {this.state.collection.map(batch => {
              return <BatchRow key={batch.id} batch={batch}/>;
            })}
          </div>
        </div>
      </div>
    );
  },

  _onPageIncrement() {
    this.props.collection.incrementPage();
  },

  _onPageDecrement() {
    this.props.collection.decrementPage();
  },

  _onParameterUpdate(name, value) {
    const {collection} = this.props;
    collection.updateParameter(name, value);
    this.setState({...collection.getParameters()});
    this.makeQuery();
  }
});

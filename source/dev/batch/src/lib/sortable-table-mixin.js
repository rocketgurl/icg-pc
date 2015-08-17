import React from 'react';
import _ from 'underscore';

const sortableTableMixin = {
  propTypes: {
    collection: React.PropTypes.object
  },

  updateSortTable(sortBy) {
    const {sortTable} = this.state;
    _.each(sortTable, (item, key) => {
      if (key === sortBy) {
        item.active = true;
        item.order = item.order === 'asc' ? 'desc' : 'asc';
      } else {
        item.active = false;
      }
    });
    return sortTable;
  },

  updateQuery(sortBy, sortTable) {
    const {query} = this.state;
    query.sort = sortBy;
    query.order = sortTable[sortBy].order;
    return query;
  },

  _onHeaderClick(e) {
    e.preventDefault();
    const sortBy = e.currentTarget.attributes['data-sortby'].value;
    const sortTable = this.updateSortTable(sortBy);
    const query = this.updateQuery(sortBy, sortTable);
    this.setState({query, sortTable});
    this.makeQuery();
  }
};

export default sortableTableMixin;

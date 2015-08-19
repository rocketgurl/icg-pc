import React from 'react';
import _ from 'underscore';

const sortableTableMixin = {
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

  updateSortQuery(sortBy, sortTable) {
    const {query} = this.state;
    query.sort = sortBy;
    query.order = sortTable[sortBy].order;
    return query;
  },

  _onHeaderClick(e) {
    e.preventDefault();
    const sortBy = e.currentTarget.attributes['data-sortby'].value;
    const sortTable = this.updateSortTable(sortBy);
    const query = this.updateSortQuery(sortBy, sortTable);
    this.setState({query, sortTable});
    this.makeQuery();
  }
};

export default sortableTableMixin;

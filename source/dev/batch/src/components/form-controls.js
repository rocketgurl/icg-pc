import React from 'react';

export default React.createClass({
  render() {
    return (
      <div className="div-table table-6-columns">
        <div className="tbody">
          <div className="tr">
            <div className="td">
              <select className="form-control">
                <option>Show: All Batch Types</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </select>
            </div>
            <div className="td">
              <select className="form-control">
                <option>Status: FAILED</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </select>
            </div>
            <div className="td">
              <select className="form-control">
                <option>Assignee: All</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </select>
            </div>
            <div className="td">
              <select className="form-control">
                <option>From: June 1, 2015</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </select>
            </div>
            <div className="td">
              <select className="form-control">
                <option>To: June 7, 2015</option>
                <option>2</option>
                <option>3</option>
                <option>4</option>
                <option>5</option>
              </select>
            </div>
            <div className="td">
              <button className="btn">1</button>
              <button className="btn">2</button>
            </div>
          </div>
        </div>
      </div>
    );
  }
});

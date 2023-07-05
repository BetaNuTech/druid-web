function filterTableRows(tableId, columnIndexes) {
  document.addEventListener("turbolinks:load", function() {
    var searchInput = document.querySelector(`#${tableId} tr.filter-row input[type="text"]`);
    var tableRows = document.querySelectorAll(`#${tableId} tbody tr`);

    searchInput.addEventListener("keyup", function() {
      clearTimeout(debounceTimeout);
      var debounceTimeout = setTimeout(function() {
        var searchTerms = searchInput.value.toLowerCase().split(/[\s,;]+/);
        tableRows.forEach(function(row) {
          if (row.classList.contains('filter-row') || row.classList.contains('filter-sum')) return;

          var columnsText = "";

          columnIndexes.forEach(function(columnIndex) {
            var column = row.querySelector(`td:nth-child(${columnIndex})`);
            columnsText += column.textContent.toLowerCase();
          });

          var rowMatches = searchTerms.every(function(term) {
            return columnsText.includes(term);
          });

          if (searchTerms.length === 0 || rowMatches) {
            row.style.display = "table-row";
          } else {
            row.style.display = "none";
          }
        });
      }, 200);
    });
  });
}

function sumFilteredTable(tableId) {
  document.addEventListener("turbolinks:load", function() {
    const table = document.getElementById(tableId);
    const filterRow = table?.querySelector('tr.filter-row');
    const filterInput = filterRow?.querySelector('input');

    if (!filterInput) return;

    const debounce = (func, delay) => {
      let timeoutId;

      return function () {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(func, delay);
      };
    };

    const updateFilterSum = () => {
      const filterSumCell = table.querySelector('td.filter-sum');

      if (!filterSumCell) return;

      const sumIndex = filterSumCell.cellIndex;
      var displayedRows = Array.from(table.rows).filter(row => row.style.display !== 'none' && !row.classList.contains('filter-sum'));

      var sum = displayedRows.reduce((acc, row) => {
        var sumCell = row.cells[sumIndex+1];
        if (!sumCell) return acc;

        var cellValue = parseInt(sumCell.textContent);
        return isNaN(cellValue) ? acc : acc + cellValue;
      }, 0);

      filterSumCell.textContent = sum.toString();
    };

    updateFilterSum();
    filterInput.addEventListener('keyup', debounce(updateFilterSum, 300));
  });
}

function getTableData(table_id) {
  var table = document.getElementById(table_id);
  var headers = [];
  var output_array = [];
  var headerRow = table.rows[0];

  for (var i = 0; i < headerRow.cells.length; i++) {
    headers.push(headerRow.cells[i].textContent);
  }
  output_array.push(headers);

  var rows = table.rows;
  for (var i = 1; i < rows.length; i++) {
    var row = rows[i];
    if (row.classList.contains('filter-data') && row.style.display !== 'none') {
      var rowData = Array.from(row.cells, cell => cell.textContent);
      output_array.push(rowData);
    }
  }

  return output_array;
}

function saveFilteredTable(tableId) {
  function saveTableData() {
    var tableData = getTableData(tableId);
    var csvContent = "data:text/csv;charset=utf-8,";

    tableData.forEach(function(row) {
      var rowData = row.join(",");
      csvContent += rowData + "\r\n";
    });

    var blob = new Blob([csvContent], { type: "text/csv" });
    var url = URL.createObjectURL(blob);

    var link = document.createElement("a");
    link.href = url;

    const dateTime = new Date().toISOString().replace(/[-:.]/g, "");
    link.download = `table_data_${dateTime}.csv`;
    link.click();

    URL.revokeObjectURL(url);
  }

  document.addEventListener('turbolinks:load', function(){
    var table = document.getElementById(tableId);
    if (!table) return;

    var button = table.querySelector("[data-table-id]");
    button.addEventListener("click", function() {
      saveTableData();
    });
  });
}

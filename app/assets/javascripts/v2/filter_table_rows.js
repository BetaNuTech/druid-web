function filterTableRows(tableId, columnIndexes) {
  document.addEventListener("turbolinks:load", function() {
    var table = document.querySelector(`#${tableId}`);
    var searchInput = document.querySelector(`#${tableId} .filter-row input[type="text"]`);
    var tableRows = document.querySelectorAll(`#${tableId} tbody tr`);
    var noMatchesRow = document.createElement("tr");
    var noMatchesCell = document.createElement("td");
    noMatchesCell.colSpan = table.rows[1].cells.length;
    noMatchesCell.textContent = "No Matches";
    noMatchesRow.appendChild(noMatchesCell);
    noMatchesRow.style.display = "none";
    tableRows[0].parentNode.insertBefore(noMatchesRow, tableRows[0]);

    searchInput.addEventListener("keyup", function() {
      var searchTerm = searchInput.value.toLowerCase();
      var hasMatches = false;
      tableRows.forEach(function(row) {
        var columnsText = "";
        columnIndexes.forEach(function(columnIndex) {
          var column = row.querySelector(`td:nth-child(${columnIndex})`);
          columnsText += column.textContent.toLowerCase();
        });

        if (searchTerm === "" || columnsText.includes(searchTerm)) {
          row.style.display = "table-row";
          hasMatches = true;
        } else {
          row.style.display = "none";
        }
        noMatchesRow.style.display = hasMatches ? "none" : "table-row";
      });
    });
  });
}


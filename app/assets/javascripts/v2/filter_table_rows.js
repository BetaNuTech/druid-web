function filterTableRows(tableId, columnIndexes) {
  document.addEventListener("turbolinks:load", function() {
    console.log('Filtering Table #', tableId, ' on columns ', columnIndexes)
    // Get the search input field and table rows
    var searchInput = document.querySelector(`#${tableId} .filter-row input[type="text"]`);
    var tableRows = document.querySelectorAll(`#${tableId} tbody tr`);

    console.log('searchInput: ', searchInput)
    console.log('tableRows: ', tableRows.length)

    // Add event listener to search input field
    searchInput.addEventListener("keyup", function() {
      // Get the search term and convert to lowercase
      var searchTerm = searchInput.value.toLowerCase();

      // Loop through table rows and hide/show based on search term
      tableRows.forEach(function(row) {
        var columnsText = "";
        columnIndexes.forEach(function(columnIndex) {
          var column = row.querySelector(`td:nth-child(${columnIndex})`);
          columnsText += column.textContent.toLowerCase();
        });

        if (searchTerm === "" || columnsText.includes(searchTerm)) {
          row.style.display = "table-row";
        } else {
          row.style.display = "none";
        }
      });
    });
  });
}


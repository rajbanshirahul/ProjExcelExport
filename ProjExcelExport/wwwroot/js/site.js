// Please see documentation at https://docs.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

$(document).ready(function () {
    $('#searchFilter').multiselect({
        enableFiltering: true,
        enableCaseInsensitiveFiltering: true,
        maxHeight: 400,
        includeSelectAllOption: true,
        //buttonWidth: '240px',
        numberDisplayed: 6,
        includeResetOption: true,
        //enableResetButton: true,
    });

    $('#paginationForm').on('keyup keypress', function (e) {
        var keyCode = e.keyCode || e.which;
        if (keyCode === 13 && !$(document.activeElement).is('textarea')) {
            e.preventDefault();
            $('#paginationForm').submit();
        }
    });

    $('#paginationForm #pageSize').on('keyup keypress', function (e) {
        var elPageSize = $("#paginationForm #pageSize");
        var maxValPageSize = elPageSize.attr('max');
        var minValPageSize = elPageSize.attr('min');
        var currentValPageSize = Number(elPageSize.val());

        if (currentValPageSize > maxValPageSize) elPageSize.val(maxValPageSize);
        if (currentValPageSize < minValPageSize) elPageSize.val(minValPageSize);

        var pageIndex = $('#paginationForm #pageIndex');
        var minValPageIndex = $('#paginationForm #pageIndex').attr('min');
        pageIndex.val(minValPageIndex);
    });
    
    $('#paginationForm #pageIndex').on('keyup keypress', function (e) {
        var pageIndex = $('#paginationForm #pageIndex');
        var maxVal = $('#pageIndex').attr('max');
        var minVal = $('#pageIndex').attr('min');
        if (Number(pageIndex.val()) > maxVal) pageIndex.val(maxVal);
        if (Number(pageIndex.val()) < minVal) pageIndex.val(minVal);
    });

    $('#btnPrev').on('click', function (e) {
        e.preventDefault();
        var pageIndex = $('#pageIndex');
        var currVal = Number(pageIndex.val());
        var minVal = $('#pageIndex').attr('min');
        pageIndex.val(currVal > minVal ? currVal - 1 : currVal);
        $('#paginationForm').submit();
    });

    $('#btnNext').on('click', function (e) {
        e.preventDefault();
        var pageIndex = $('#pageIndex');
        var currVal = Number(pageIndex.val());
        var maxVal = $('#pageIndex').attr('max');
        pageIndex.val(currVal < maxVal ? currVal + 1 : currVal);
        $('#paginationForm').submit();
    });
})
using System;
using System.Collections.Generic;
using System.Linq;

namespace ProjExcelExport.Pagination
{
    public class PaginationSpec
    {
        private const int _maxPageSize = PaginationDefaults.MaxPageSize;

        private int _pageSize = PaginationDefaults.DefaultPageSize;
        private int _pageIndex = PaginationDefaults.DefaultPageIndex;
        private string _search = null;
        private List<string> _searchFilter = null;
        private string _exactMatch = null;
        private string _sortBy = null;
        private string _sortOrder = null;
        
        public int PageSize
        {
            get => _pageSize;
            set => _pageSize = (value > _maxPageSize)
                ? _maxPageSize
                : (value < 1) ? _pageSize : value;
        }

        public int PageIndex
        {
            get => _pageIndex;
            set => _pageIndex = (value < 1) ? _pageIndex : value;
        }

        public string Search
        {
            get => _search;
            set => _search = string.IsNullOrEmpty(value)
                ? _search
                : value.Trim();
        }

        public List<string> SearchFilter
        {
            get => _searchFilter;
            set => _searchFilter =
                value.Where(x => !string.IsNullOrEmpty(x) && !string.IsNullOrEmpty(x.Trim())).ToList();
        }

        public string ExactMatch
        {
            get => _exactMatch;
            set => _exactMatch =
                (!string.IsNullOrEmpty(value) && value.Equals("on", StringComparison.OrdinalIgnoreCase))
                ? "on"
                : null;
        }

        public string SortBy
        {
            get => _sortBy;
            set => _sortBy = string.IsNullOrEmpty(value)
                ? _sortBy
                : value.Trim();
        }

        public string SortOrder
        {
            get => _sortOrder;
            set => _sortOrder = string.IsNullOrEmpty(value)
                ? _sortOrder
                : string.Equals("DESC", value, StringComparison.OrdinalIgnoreCase) ? "DESC" : "ASC";
        }
    }
}

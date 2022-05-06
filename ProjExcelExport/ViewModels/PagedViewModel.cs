using ProjExcelExport.Pagination;
using System.Collections.Generic;

namespace ProjExcelExport.ViewModels
{
    public class PagedViewModel<T>
    {
        public int MaxPageSize { get => PaginationDefaults.MaxPageSize; }
        public int MinPageSize { get => PaginationDefaults.MinPageSize; }

        private int _pageSize = PaginationDefaults.DefaultPageSize;
        private int _pageIndex = PaginationDefaults.DefaultPageIndex;
        private int _totalPageCount = PaginationDefaults.MinTotalPageCount;

        public long TotalRecordsCount { get; set; }
        public long TotalFilteredCount { get; set; }
        public int TotalPageCount 
        {
            get => _totalPageCount;
            set => _totalPageCount = value < PaginationDefaults.MinTotalPageCount
                ? PaginationDefaults.MinTotalPageCount
                : value;
        }
        public int PageSize
        {
            get => _pageSize;
            set => _pageSize = (value > MaxPageSize)
                ? MaxPageSize
                : (value < PaginationDefaults.MinPageSize)
                    ? PaginationDefaults.MinPageSize
                    : value;
        }

        public int PageIndex
        {
            get => _pageIndex;
            set => _pageIndex = (value < PaginationDefaults.DefaultPageIndex)
                ? PaginationDefaults.DefaultPageIndex
                : value;
        }
        public string Search { get; set; }
        public List<string> SearchFilter { get; set; }
        public string ExactMatch { get; set; }
        public string SortBy { get; set; }
        public string SortOrder { get; set; }

        public T Data { get; set; }
    }
}

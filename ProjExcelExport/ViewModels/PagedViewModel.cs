using System.Collections.Generic;

namespace ProjExcelExport.ViewModels
{
    public class PagedViewModel<T>
    {
        public int TotalCount { get; set; }
        public int TotalPageCount { get; set; }
        public int PageIndex { get; set; }
        public int PageSize { get; set; }
        public string Search { get; set; }
        public List<string> SearchFilter { get; set; }
        public string SortBy { get; set; }
        public string SortOrder { get; set; }

        public T Data { get; set; }
    }
}

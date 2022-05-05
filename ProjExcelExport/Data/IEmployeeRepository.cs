using ProjExcelExport.Models;
using System.Collections.Generic;
using System.Threading.Tasks;
using ProjExcelExport.Pagination;
using ProjExcelExport.ViewModels;

namespace ProjExcelExport.Data
{
    public interface IEmployeeRepository
    {
        Task<Employee> GetEmployeeByIdAsync(int id);
        //Task<IReadOnlyList<Employee>> GetEmployeesAsync(SpecParams specParams);
        int Count();
        Task<List<Employee>> ListAsync(PaginationSpec spec);
        Task<PagedViewModel<IEnumerable<Employee>>> ListDapperAsync(PaginationSpec spec);
        Task<Employee> AddAsync(Employee entity);
        Task<Employee> UpdateAsync(Employee entity);
        Task<Employee> DeleteAsync(Employee entity);
    }
}

using System;
using Microsoft.EntityFrameworkCore;
using ProjExcelExport.Models;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ProjExcelExport.Pagination;
using ProjExcelExport.Data.Helper;
using Dapper;
using System.Data;
using ProjExcelExport.ViewModels;

namespace ProjExcelExport.Data
{

    public class EmployeeRepository : IEmployeeRepository
    {
        private readonly DataContext _context;
        public EmployeeRepository(DataContext context)
        {
            _context = context;

        }

        public async Task<Employee> AddAsync(Employee entity)
        {
            var employee = _context.Employees.Add(entity).Entity;
            await _context.SaveChangesAsync();
            return employee;
        }

        public int Count()
        {
            return _context.Employees.AsQueryable().Count();
        }

        public async Task<Employee> DeleteAsync(Employee entity)
        {
            var employee = _context.Employees.Remove(entity).Entity;
            await _context.SaveChangesAsync();

            return employee;
        }

        public async Task<Employee> GetEmployeeByIdAsync(int id)
        {
            return await _context.Employees.FirstOrDefaultAsync(x => x.Id == id);
        }

        public async Task<List<Employee>> ListAsync(PaginationSpec spec)
        {
            var query = _context.Employees.AsQueryable<Employee>();
            if (!string.IsNullOrEmpty(spec.Search))
            {
                query = query.Where(x =>
                    x.FirstName.ToLower().Contains(spec.Search.ToLower())
                    || x.LastName.ToLower().Contains(spec.Search.ToLower())
                    || x.Title.ToLower().Contains(spec.Search.ToLower())
                    || x.City.ToLower().Contains(spec.Search.ToLower())
                    || x.Department.ToLower().Contains(spec.Search.ToLower()));

            }

            if (!string.IsNullOrEmpty(spec.SortBy))
            {
                var properties = typeof(Employee).GetProperties();
                var containsProperty =
                    properties.Any(x => x.Name.Equals(spec.SortBy, StringComparison.OrdinalIgnoreCase));

                if (containsProperty && (string.IsNullOrEmpty(spec.SortOrder) || spec.SortOrder.Equals("ASC", StringComparison.OrdinalIgnoreCase)))
                {
                    switch (spec.SortBy.ToLower())
                    {
                        case "department":
                            query = query.OrderBy(x => x.Department);
                            break;
                        case "firstname":
                            query = query.OrderBy(x => x.FirstName);
                            break;
                        default:
                            query = query.OrderBy(x => x.Id);
                            break;
                    }
                }
                else if (containsProperty && spec.SortOrder.Equals("DESC", StringComparison.OrdinalIgnoreCase))
                {
                    switch (spec.SortBy.ToLower())
                    {
                        case "department":
                            query = query.OrderByDescending(x => x.Department);
                            break;
                        case "firstname":
                            query = query.OrderByDescending(x => x.FirstName);
                            break;

                        default:
                            query = query.OrderByDescending(x => x.Id);
                            break;
                    }
                }
                else
                {
                    query = query.OrderBy(x => x.Id);
                }
            }

            query = query
                .Skip(spec.PageSize * (spec.PageIndex - 1))
                .Take(spec.PageSize);

            return await query.ToListAsync(); ;
        }

        public async Task<PagedViewModel<IEnumerable<Employee>>> ListDapperAsync(PaginationSpec spec)
        {
            using var connection = DbHelper.GetConnnectionDapper();

            var paramsSp = new DynamicParameters();
            paramsSp.Add("@PageSize", spec.PageSize);
            paramsSp.Add("@PageIndex", spec.PageIndex);
            paramsSp.Add("@Search", spec.Search);
            paramsSp.Add("@SortBy", spec.SortBy);
            paramsSp.Add("@SortOrder", spec.SortOrder);
            paramsSp.Add("@FilteredCount", dbType: DbType.Int32, direction: ParameterDirection.Output);

            var listEmployees = await connection
                .QueryAsync<Employee>("[dbo].[spGerEmployeeReport]", paramsSp, commandType: CommandType.StoredProcedure);
            var filteredCount = paramsSp.Get<int>("@FilteredCount");

            return new PagedViewModel<IEnumerable<Employee>>
            {
                PageSize = filteredCount < spec.PageSize ? filteredCount : spec.PageSize,
                PageIndex = spec.PageIndex,
                Search = string.IsNullOrEmpty(spec.Search) ? "" : spec.Search,
                SearchFilter = spec.SearchFilter,
                SortBy = spec.SortBy,
                SortOrder = string.IsNullOrEmpty(spec.SortOrder) || string.Equals("ASC", spec.SortOrder, StringComparison.OrdinalIgnoreCase)
                    ? "ASC"
                    : "DESC",
                TotalCount = filteredCount,
                TotalPageCount = filteredCount % spec.PageSize == 0
                    ? filteredCount / spec.PageSize
                    : (filteredCount / spec.PageSize) + 1,
                Data = listEmployees
            };
        }

        public async Task<Employee> UpdateAsync(Employee entity)
        {
            var employee = _context.Employees.Update(entity).Entity;
            await _context.SaveChangesAsync();
            return employee;
        }

    }
}

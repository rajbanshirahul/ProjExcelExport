using ClosedXML.Excel;
using Microsoft.AspNetCore.Mvc;
using ProjExcelExport.Data;
using ProjExcelExport.Models;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Threading.Tasks;
using ProjExcelExport.Pagination;

namespace ProjExcelExport.Controllers
{
    public class EmployeesController : Controller
    {
        private readonly IEmployeeRepository _employeeRepository;

        public EmployeesController(IEmployeeRepository employeeRepository)
        {
            _employeeRepository = employeeRepository;
        }

        public async Task<IActionResult> List([FromForm] PaginationSpec model)
        {
            var vm = await _employeeRepository.ListDapperAsync(model);

            return View(vm);
        }

        public async Task<IActionResult> Export([FromQuery] PaginationSpec model)
        {
            var vm = await _employeeRepository.ListDapperAsync(model);

            var dt = GetDataTable(vm.Data);

            using var wb = new XLWorkbook();
            wb.Worksheets.Add(dt);
            using var stream = new MemoryStream();
            wb.SaveAs(stream);

            return File(stream.ToArray(),
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Employees.xlsx");
        }

        private static DataTable GetDataTable(IEnumerable<Employee> employees)
        {
            var dt = new DataTable("Employees");
            dt.Columns.AddRange(new DataColumn[] {new DataColumn("Id"),
                                        new DataColumn("FirstName"),
                                        new DataColumn("LastName"),
                                        new DataColumn("Email"),
                                        new DataColumn("SocialSecurityNumber"),
                                        new DataColumn("Department"),
                                        new DataColumn("City"),
                                        new DataColumn("Salary")
            });

            foreach (var employee in employees)
            {
                dt.Rows.Add(employee.Id, employee.FirstName, employee.LastName,
                    employee.Email, employee.SocialSecurityNumber, employee.Department,
                    employee.City, employee.Salary);
            }
            return dt;
        }
    }
}


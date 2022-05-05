using Microsoft.Extensions.Logging;
using ProjExcelExport.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;

namespace ProjExcelExport.Data
{
    public class DataContextSeed
    {
        public static async Task SeedAsync(DataContext context, ILoggerFactory loggerFactory)
        {
            try
            {
                if (!context.Employees.Any())
                {
                    var employeesData =
                        File.ReadAllText("./Data/SeedData/employees.json");

                    var employees = JsonSerializer.Deserialize<List<Employee>>(employeesData);

                    foreach (var item in employees)
                    {
                        context.Employees.Add(item);
                    }

                    await context.SaveChangesAsync();
                }

            }
            catch (Exception ex)
            {
                var logger = loggerFactory.CreateLogger<DataContextSeed>();
                logger.LogError(ex.Message);
            }
        }
    }
}

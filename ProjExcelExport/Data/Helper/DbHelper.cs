using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Data;
using System.IO;

namespace ProjExcelExport.Data.Helper
{
    public class DbHelper
    {
        public static IDbConnection GetConnnectionDapper()
        {
            return new SqlConnection(GetConnectionString());
        }

        public static string GetConnectionString()
        {

            IConfigurationBuilder builderConfig = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json");

            IConfiguration config = builderConfig.Build();
            return config["ConnectionStrings:DefaultConnection"];
        }
    }
}

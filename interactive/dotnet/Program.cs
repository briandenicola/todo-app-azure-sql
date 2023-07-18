using Microsoft.Data.SqlClient;

static SqlConnectionStringBuilder BuildAzureConnectionString( string sqlServerName, string clientid, string catalog = "todo" )
{
    return new SqlConnectionStringBuilder
    {
        DataSource = $"tcp:{sqlServerName}.database.windows.net,1433",
        InitialCatalog = catalog,
        TrustServerCertificate = false,
        Encrypt = true,
        Authentication = SqlAuthenticationMethod.ActiveDirectoryManagedIdentity,
        UserID = clientid,
    };
}

var UserID = Environment.GetEnvironmentVariable("SQL_USER_ID", EnvironmentVariableTarget.Process);
var SQLName = Environment.GetEnvironmentVariable("SQL_SERVER_NAME", EnvironmentVariableTarget.Process);

var connectionString = BuildAzureConnectionString( SQLName, UserID);
if( connectionString is null ) throw new ArgumentException("No Connection String defined. Please define environment variable SQL_CON_STR with the proper connection string");

using (SqlConnection connection = new SqlConnection(connectionString.ToString()))
{
    Console.WriteLine("\nQuery data example:");
    Console.WriteLine("=========================================\n");
    
    connection.Open();       

    String sql = "SELECT Name, IsComplete FROM todos";

    using (SqlCommand command = new SqlCommand(sql, connection))
    {
        using (SqlDataReader reader = command.ExecuteReader())
        {
            while (reader.Read())
            {
                Console.WriteLine("{0} {1}", reader.GetString(0), reader.GetBoolean(1).ToString());
            }
        }
    }                    
}
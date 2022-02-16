var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

var connection = new SqlConnectionStringBuilder
{
    DataSource = "tcp:sqlserver01.database.windows.net,1433",
    InitialCatalog = "todo",
    TrustServerCertificate = false,
    Encrypt = true,
    Authentication = SqlAuthenticationMethod.ActiveDirectoryManagedIdentity,
};

builder.Services.AddDbContext<TodoDbContext>(    
    options => options.UseSqlServer(
        connection.ConnectionString
    )
);

var app = builder.Build();
app.MapControllers();
app.Run();
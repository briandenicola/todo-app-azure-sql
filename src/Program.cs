var builder = WebApplication.CreateBuilder(args);

var keyVaultClient = new CertificateClient(new Uri("https://myvault.vault.azure.net/"), new DefaultAzureCredential());
var keyVaultCertificateX509 = (await keyVaultClient.DownloadCertificateAsync("my-wildcard-pfx-cert")).Value;

int port = 443;
builder.WebHost.UseKestrel( opt => 
{
    opt.ConfigureHttpsDefaults( httpsOptions => 
    {
        httpsOptions.SslProtocols = System.Security.Authentication.SslProtocols.Tls13;
    });
    opt.Listen(IPAddress.Any, port, listenOptions =>
    {
        listenOptions.UseHttps(keyVaultCertificateX509);
    });
});

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
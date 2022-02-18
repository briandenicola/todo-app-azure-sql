namespace Todos;

public class TodoMain 
{
    public static async Task RunAsync (Uri keyVault, String sqlServerName)
    {   
        var builder = WebApplication.CreateBuilder();

        var keyVaultClient = new CertificateClient(keyVault, new DefaultAzureCredential());
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
            DataSource = $"tcp:{sqlServerName}.database.windows.net,1433",
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
    }
}
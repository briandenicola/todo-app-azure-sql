namespace Todos;

public static class ProgramExtensions
{
    public static async Task AddCustomKeyVaultConfiguration (this WebApplicationBuilder builder, Uri keyVaultUri, String certificateName = "my-wildcard-pfx-cert")
    {
        int port = 8443;
        var keyVaultClient = new CertificateClient(keyVaultUri, new DefaultAzureCredential());
        var keyVaultCertificateX509 = (await keyVaultClient.DownloadCertificateAsync(certificateName)).Value;

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
    }

    public static void AddCustomApplicationInsightsConfiguration (this WebApplicationBuilder builder, string aiConnectionString)
    {
        builder.Logging.AddConsole();
        builder.Logging.AddApplicationInsights();
        builder.Services.Configure<TelemetryConfiguration>(config =>  {
            var credential = new DefaultAzureCredential();
            config.SetAzureTokenCredential(credential);
        });
        builder.Services.AddApplicationInsightsTelemetry(new ApplicationInsightsServiceOptions
        {
            ConnectionString = aiConnectionString
        });
    }

    public static void AddCustomSQLAuthentication(this WebApplicationBuilder builder, String sqlServerName)
    {
        var connection = Helpers.BuildAzureConnectionString(sqlServerName);

        builder.Services.AddDbContext<TodoDbContext>(    
            options => options.UseSqlServer(connection.ConnectionString, o => o.EnableRetryOnFailure() )
                              .AddInterceptors(new AadAuthenticationDbConnectionInterceptor())
        );
    }
}
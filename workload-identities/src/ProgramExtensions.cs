namespace Todos;

public static class ProgramExtensions
{
    public static async Task AddCustomKeyVaultConfiguration (this WebApplicationBuilder builder, Uri keyVaultUri, String certificateName = "my-wildcard-pfx-cert")
    {
        int port = 8443;
        //var keyVaultClient = new CertificateClient(keyVaultUri, new DefaultAzureCredential());
        var credential = new ChainedTokenCredential( new AzureCliCredential(), new ManagedIdentityCredential() );
        var keyVaultClient = new CertificateClient(keyVaultUri, credential);
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

        QuickPulseTelemetryProcessor processor = null;
        builder.Services.Configure<TelemetryConfiguration>(config =>  
        {    
            var credential = new DefaultAzureCredential();
            config.SetAzureTokenCredential(credential);

            config.TelemetryProcessorChainBuilder
                .Use(next =>
                {
                    processor = new QuickPulseTelemetryProcessor(next);
                    return processor;
                })
                .Build();
        });

        builder.Services.AddApplicationInsightsTelemetry(new ApplicationInsightsServiceOptions
        {
            ConnectionString = aiConnectionString
        });

        builder.Services.ConfigureTelemetryModule<QuickPulseTelemetryModule>( (module, o) =>
        { 
            module.RegisterTelemetryProcessor(processor);
        });
    }
}
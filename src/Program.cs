 async Task RunMain (Uri keyVault, String sqlServerName)
 {   
    var builder = WebApplication.CreateBuilder(args);

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

RootCommand command = new RootCommand("A basic ASP.NET MVC todo API")
{
    new Option<Uri>(
        aliases: new [] {"--key-vault", "-k"},
        description: "Key Vault name or URI, e.g. my-vault or https://my-vault-vault.azure.net",
        parseArgument: result =>
        {
            string value = result.Tokens.Single().Value;
            if (Uri.TryCreate(value, UriKind.Absolute, out Uri vaultUri) ||
                Uri.TryCreate($"https://{value}.vault.azure.net", UriKind.Absolute, out vaultUri))
            {
                return vaultUri;
            }

            result.ErrorMessage = "Must specify a vault name or URI";
            return null!;
        }
    )
    {
        Name = "vaultUri",
        IsRequired = true,
    },

    new Option<string>(
        aliases: new[] { "--database-server", "-d", },
        description: "Azure SQL Database name."
    )
    {
        Name = "sqlServerName",
        IsRequired = true,
    },
};

command.Handler = CommandHandler.Create<Uri, string>(RunMain);
return command.InvokeAsync(args).Result;
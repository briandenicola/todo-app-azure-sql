Uri keyVaultUri;
IConfigurationRoot config;
SqlConnectionStringBuilder connection;
string appInsights;;

{
    var switchMappings = new Dictionary<string, string>()
    {
        { "-kv", "keyvault" },
        { "-db", "azuresql" },
    };

    var builder = new ConfigurationBuilder();  

    builder.AddEnvironmentVariables(prefix: "BJD_TODO_");
    builder.AddCommandLine(args, switchMappings);

    config = builder.Build();
    keyVaultUri = Helpers.GetKeyVaultUri(config["keyvault"]);
    appInsights = config["appinsights"];
    connection = Helpers.BuildAzureConnectionString(config["azuresql"], clientid: config["clientid"]);
}

{   
    var builder = WebApplication.CreateBuilder();

    builder.AddCustomApplicationInsightsConfiguration(appInsights);
    //builder.AddCustomSQLAuthentication(config["azuresql"]);
    
    if( keyVaultUri is not null ) {
        await builder.AddCustomKeyVaultConfiguration(keyVaultUri);
    }

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    
    builder.Services.AddDbContext<TodoDbContext>(    
        options => options.UseSqlServer(
            connection.ConnectionString
        )
    );

    var app = builder.Build();
    app.Logger.LogInformation("Application is ready to run."); 
    app.MapControllers();
    app.Run();
}
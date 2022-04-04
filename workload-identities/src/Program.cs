Uri keyVaultUri;
IConfigurationRoot config;

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
}

{   
    var builder = WebApplication.CreateBuilder();

    builder.Logging.AddConsole();
    builder.Logging.AddApplicationInsights();

    builder.AddCustomSQLAuthentication(config["azuresql"]);
    
    if( keyVaultUri is not null ) {
        await builder.AddCustomKeyVaultConfiguration(keyVaultUri);
    }

    builder.Services.AddControllers();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddApplicationInsightsTelemetry();
    
    var app = builder.Build();
    app.Logger.LogInformation("Application is ready to run."); 
    app.MapControllers();
    app.Run();
}
Uri keyVaultUri;
SqlConnectionStringBuilder connection;

{
    var switchMappings = new Dictionary<string, string>()
    {
        { "-kv", "keyvault" },
        { "-db", "azuresql" },
    };

    var builder = new ConfigurationBuilder();
    builder.AddEnvironmentVariables(prefix: "BJD_TODO_");
    builder.AddCommandLine(args, switchMappings);

    var config = builder.Build();
    keyVaultUri = Helpers.GetKeyVaultUri(config["keyvault"]);
    connection = Helpers.BuildAzureConnectionString(config["azuresql"]);
}

{   
    var builder = WebApplication.CreateBuilder();

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

    app.MapControllers();
    app.Run();
}
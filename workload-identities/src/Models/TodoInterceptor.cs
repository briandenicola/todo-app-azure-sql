namespace Todos;

public class AadAuthenticationDbConnectionInterceptor : DbConnectionInterceptor
{
    public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(
        DbConnection connection,
        ConnectionEventData eventData,
        InterceptionResult result,
        CancellationToken cancellationToken)
    {
        var sqlConnection = (SqlConnection)connection;
        var connectionStringBuilder = new SqlConnectionStringBuilder(sqlConnection.ConnectionString);
        sqlConnection.AccessToken = await GetAzureSqlAccessToken(cancellationToken);
        return await base.ConnectionOpeningAsync(connection, eventData, result, cancellationToken);
    }

    private static async Task<string> GetAzureSqlAccessToken(CancellationToken cancellationToken)
    {
        var tokenRequestContext = new TokenRequestContext(new[] { "https://database.windows.net//.default" });
        var tokenRequestResult = await new DefaultAzureCredential().GetTokenAsync(tokenRequestContext, cancellationToken);
        return tokenRequestResult.Token;
    }
}
namespace Todos;

//https://purple.telstra.com/blog/a-better-way-of-resolving-ef-core-interceptors-with-dependency-injection

public class AadAuthenticationDbConnectionInterceptor : DbConnectionInterceptor
{
    public override async ValueTask<InterceptionResult> ConnectionOpeningAsync(
        DbConnection connection,
        ConnectionEventData eventData,
        InterceptionResult result,
        CancellationToken cancellationToken)
    {
        var sqlConnection = (SqlConnection)connection;
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

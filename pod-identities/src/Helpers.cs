namespace Todos;

public class Helpers 
{
    public static Uri GetKeyVaultUri( string uri )
    {
        if (Uri.TryCreate(uri, UriKind.Absolute, out Uri vaultUri) ||
            Uri.TryCreate($"https://{uri}.vault.azure.net", UriKind.Absolute, out vaultUri)) 
        {
            return vaultUri;
        }

        return null;
    }

    public static SqlConnectionStringBuilder BuildAzureConnectionString( string sqlServerName, string clientid, string catalog = "todo" )
    {
        return new SqlConnectionStringBuilder
        {
            DataSource = $"tcp:{sqlServerName}.database.windows.net,1433",
            InitialCatalog = catalog,
            TrustServerCertificate = false,
            Encrypt = true,
            Authentication = SqlAuthenticationMethod.ActiveDirectoryManagedIdentity,
            UserID = clientid,
        };
    }
}
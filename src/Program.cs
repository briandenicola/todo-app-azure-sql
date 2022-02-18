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

command.Handler = CommandHandler.Create<Uri, string>(TodoMain.RunAsync);
return command.InvokeAsync(args).Result;
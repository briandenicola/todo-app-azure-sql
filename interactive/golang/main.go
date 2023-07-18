// Go connection Sample Code:
package main
import (
	_ "github.com/microsoft/go-mssqldb"
	"github.com/microsoft/go-mssqldb/azuread"
	"database/sql"
	"context"
	"log"
	"fmt"
	"flag"
)


func main() {
	
	var db *sql.DB
	var server string
	var user string
	var database = "todo"

	flag.StringVar(&server, "server", "", "The Fully Qualified URl for the Azure SQL database. eg.  marmot-15146-sql.database.windows.net")
	flag.StringVar(&user, "user", "", "The Object ID of the User Assigned Managed Identity for this container")
	flag.Parse()

	connString := fmt.Sprintf("server=%s;user id=%s;fedauth=ActiveDirectoryDefault;database=%s;",server, user, database)
	
	var err error
	
	db, err = sql.Open(azuread.DriverName, connString)
	if err != nil {
		log.Fatal("Error creating connection pool: ", err.Error())
	}
	ctx := context.Background()
	err = db.PingContext(ctx)
	if err != nil {
		log.Fatal(err.Error())
	}
	fmt.Printf("Connected!")
}
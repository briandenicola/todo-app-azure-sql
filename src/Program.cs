var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

builder.Services.AddDbContext<TodoDbContext>(
    options => options.UseInMemoryDatabase("Todos")
);

var app = builder.Build();
app.MapControllers();
app.Run();
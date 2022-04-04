
namespace Todos;

[ApiController]
[Route("/api/todo")]
public class TodoController : ControllerBase
{
    private readonly ILogger<TodoController> _logger;
    private readonly TodoDbContext _db;

    public TodoController(ILogger<TodoController> logger, TodoDbContext dbcontext)
    {
        _logger = logger;
        _db = dbcontext ?? throw new ArgumentNullException(nameof(dbcontext));
    }

    [HttpPost]
    public async Task Post(Todo todo, CancellationToken cancellationToken)
    {
        _logger.LogInformation($"Handling POST request for ${todo.Id}");
        _db.Todos.Add(todo);
        await _db.SaveChangesAsync();
    }

    [HttpGet]
    public async Task<ActionResult<List<Todo>>> GetAll()
    {
        _logger.LogInformation($"Handling Get Alls request");
        var todos = await _db.Todos.ToListAsync();
        return Ok(todos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Todo>> Get(int id, CancellationToken cancellationToken)
    {
        _logger.LogInformation($"Handling GET request for ${id}");
        var todo = await _db.Todos.FindAsync(id);
        if (todo == null)
        {
            return NotFound();
        }

        return Ok(todo);
    }

}

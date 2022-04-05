
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
        _logger.LogTrace($"Trace Handling of {todo.Id}");
        _db.Todos.Add(todo);
        await _db.SaveChangesAsync();
    }

    [HttpGet]
    public async Task<ActionResult<List<Todo>>> GetAll()
    {
        _logger.LogInformation($"Informational handling of Get All Request");
        var todos = await _db.Todos.ToListAsync();
        return Ok(todos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Todo>> Get(int id, CancellationToken cancellationToken)
    {
        _logger.LogDebug($"Debug Handling of {id}");
        var todo = await _db.Todos.FindAsync(id);
        if (todo == null)
        {
            _logger.LogCritical($"Handling GET request for {id} resulted in NotFound()");
            return NotFound();
        }

        return Ok(todo);
    }

}

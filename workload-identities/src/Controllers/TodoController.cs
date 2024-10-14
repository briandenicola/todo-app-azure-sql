
namespace Todos;

/// <summary>
/// Controller for managing Todo items.
/// </summary>
/// [ApiController]
[Route("/api/todo")]
public class TodoController : ControllerBase
{
    private readonly ILogger<TodoController> _logger;
    private readonly TodoDbContext _db;

    /// <summary>
    /// Initializes a new instance of the <see cref="TodoController"/> class.
    /// </summary>
    /// <param name="logger">The logger instance.</param>
    /// <param name="dbcontext">The database context instance.</param>
    public TodoController(ILogger<TodoController> logger, TodoDbContext dbcontext)
    {
        _logger = logger;
        _db = dbcontext ?? throw new ArgumentNullException(nameof(dbcontext));
    }

    /// <summary>
    /// Handles the creation of a new Todo item.
    /// </summary>
    /// <param name="todo">The Todo item to create.</param>
    /// <param name="cancellationToken">The cancellation token.</param>
    /// <returns>A task that represents the asynchronous operation.</returns>
    [HttpPost]
    public async Task Post(Todo todo, CancellationToken cancellationToken)
    {
        _logger.LogInformation($"Handling POST request for ${todo.Id}");
        _db.Todos.Add(todo);
        await _db.SaveChangesAsync();
    }

    /// <summary>
    /// Retrieves all Todo items.
    /// </summary>
    /// <returns>A list of all Todo items.</returns>
    [HttpGet]
    public async Task<ActionResult<List<Todo>>> GetAll()
    {
        _logger.LogInformation($"Handling Get Alls request");
        var todos = await _db.Todos.ToListAsync();
        return Ok(todos);
    }

    /// <summary>
    /// Retrieves a specific Todo item by its ID.
    /// </summary>
    /// <param name="id">The ID of the Todo item to retrieve.</param>
    /// <param name="cancellationToken">The cancellation token.</param>
    /// <returns>The requested Todo item, or a NotFound result if the item does not exist.</returns>
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

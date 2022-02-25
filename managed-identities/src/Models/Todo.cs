namespace Todos;
public class Todo
{
    public Todo(int id, string name) => (Id, Name) = (id, name);
    public int Id { get; set; }
    public string Name { get; set; }
    public bool IsComplete { get; set; }
}


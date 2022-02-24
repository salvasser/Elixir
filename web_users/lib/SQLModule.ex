defmodule SQLmodule do



  def all_users(pid) do
    {:ok, data} = MyXQL.query(pid, "SELECT * FROM data")
    [data.columns, data.rows]
  end

  def one_user(pid, id) do
    {:ok, data} = MyXQL.query(pid, "SELECT * FROM data WHERE id = ?", [id])
    [data.columns, data.rows]
  end

  def older_than(pid, age) do
    {:ok, data} = MyXQL.query(pid, "SELECT * FROM data WHERE age > ?", [age])
    [data.columns, data.rows]
  end 

  def younger_than(pid, age) do
    {:ok, data} = MyXQL.query(pid, "SELECT * FROM data WHERE age < ?", [age])
    [data.columns, data.rows]
  end 

  def find_by_name(pid, name) do
    {:ok, data} = MyXQL.query(pid, "SELECT * FROM data WHERE name = ?", [name])
    [data.columns, data.rows]
  end

  def delete_user(pid, id) do
    MyXQL.query(pid, "DELETE FROM data WHERE id = ?", [id])
  end

  def add_user(pid, idList) do
    try do
      id = IO.gets("Enter ID: ") |> String.trim
      name = IO.gets("Enter name: ") |> String.trim
      phone = IO.gets("Enter phone: ") |> String.trim
      {age, "\n"} = IO.gets("Enter age: ") |> Integer.parse

      if Enum.member?(idList, id) do
        "<h3>Error adding. User with this ID already exists</h3>"
      else
        MyXQL.query(pid, "INSERT INTO data (id, name, phone, age) VALUES (?,?,?,?)", [id, name, phone, age])
        "<h3>User added</h3>";
      end
    rescue
      e in MatchError -> "<h3>Data entry error. Enter a number in the age field</h3>"
    end

  end

  def id_list(pid) do
    {:ok, data} = MyXQL.query(pid, "SELECT id FROM data")
    id_list(data.rows, [])
  end
    defp id_list([], acc) do 
      acc
    end
    defp id_list([headId|tailId], acc) do
      id_list(tailId, [List.to_string(headId)|acc])
    end

  def name_list(pid) do
    {:ok, data} = MyXQL.query(pid, "SELECT name FROM data")
    name_list(data.rows, [])
  end
    defp name_list([], acc) do 
      acc
    end
    defp name_list([headId|tailId], acc) do
      name_list(tailId, [List.to_string(headId)|acc])
    end

end
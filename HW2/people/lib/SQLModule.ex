defmodule SQLmodule do

  def sql_start() do
    {:ok, pid} = MyXQL.start_link(username: "root", password: "password", protocol: :tcp)
    MyXQL.query!(pid, "CREATE DATABASE IF NOT EXISTS people")
    {:ok, pid} = MyXQL.start_link(username: "root", password: "password", database: "people", protocol: :tcp)
    MyXQL.query!(pid, "CREATE TABLE IF NOT EXISTS data (id VARCHAR(4), name VARCHAR(255), phone VARCHAR(4), age INT)")
    pid
  end

  def existing_users() do
    pid = sql_start()
    {:ok, data} = File.read("resources/users.dat")
    listOfData = String.split(data, [", ", "\n"])
    read(listOfData, pid)
  end

    defp read([], _) do
      :ok
    end
    defp read([headName, headPhone, headAge, headId | tailData], pid) do
      MyXQL.query!(pid, "INSERT INTO data (id, name, phone, age) VALUES (?,?,?,?)", [headId, headName, headPhone, String.to_integer(headAge)])
      read(tailData, pid)
    end
 
  def delete_data() do
    pid = sql_start()
    MyXQL.query!(pid, "DROP DATABASE people")
  end

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
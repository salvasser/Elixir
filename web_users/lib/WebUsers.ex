defmodule WebUsers do
  #import SQLmodule


  def server() do
    {:ok, socket} = :gen_tcp.listen(8090, [:binary, packet: :line, active: false, reuseaddr: true])
    #Logger.info("Accepting connections on port #{port}")
    client(socket)
  end

  defp client(serverSocket) do
    sql_start()
    idList = id_list()
    nameList = name_list()
    {:ok, socket} = :gen_tcp.accept(serverSocket)
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.puts(msg)
    html = handler(msg) |> request(idList, nameList, msg)
    responce = "HTTP/1.1 200 OK\nContent-Type: text/html; charset=utf-8\nContent-Length: " <> Integer.to_string(String.length(html)) <> "\n\n" <> html
    :gen_tcp.send(socket, responce)
    :gen_tcp.close(socket)
    client(serverSocket)
  end

  defp handler(msg) do
    listOfText = ["get-users", "get-user", "delete-user", "add-user"]
    [_, request | _Tail] = splitting(msg)
    handler(request, listOfText)
  end

    defp handler(_request, []) do
      "start-page"
    end

    defp handler(request, [headText | tailText]) do 
      if request == headText do
        headText
      else
        handler(request, tailText)
      end
    end


  defp request(data, idList, nameList, msg) do 
      [term, value] = find_value(msg)
      case data do
        "get-users" ->
          cond do
            term == "older" ->
              "<h1>User data</h1><br>" <> output(older_than(value))
            term == "younger" -> 
              "<h1>User data</h1><br>" <> output(younger_than(value))
            true ->
              "<h1>User data</h1><br>" <> output(all_users())
          end
        "get-user" ->
          if (Enum.member?(idList, value)) or (Enum.member?(nameList, value)) do
            cond do
              term == "id" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> output(one_user(value))
              term == "name" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> output(find_by_name(value))
              true ->
                "<h3>Error query after (get-user). Enter (name) or (id)</h3>"
            end
          else
            "<h3>There is no user with this ID/name, check the data</h3>"
          end
        "delete-user" ->
          if Enum.member?(idList, value) do
            delete_user(value)
            "<h1>Removing a user</h1><br><p>user " <> to_string(value) <> " deleted</p>"
          else
            "<h3>There is no user with this ID, check the data<h3>"
          end
        "add-user" ->
          add_user(idList)
          
        _-> {:ok, data} = File.read("resources/start_page.html")
            data
      end

  end 

  defp output([_key, value]) do 
    output_data(value, [])
  end
  
  defp output_data([], acc) do
    {:ok, result} = JSON.encode(Enum.reverse(acc))
    result
  end

  defp output_data([[headId, headName, headPhone, headAge] | tailData], acc) do
    output_data(tailData, [[id: headId, name: headName, phone: headPhone, age: Integer.to_string(headAge)] | acc])
  end

  defp splitting(msg) do
    String.split(to_string(msg), [" /", " ", "/"])
  end


  defp find_value(msg) do
    [_, _query, term | _] = splitting(msg)
    list = String.split(term, "-")
      if length(list) == 2 do 
        list
      else
        [:error, ""]
      end
  end



  defp sql_start() do
    #{:ok, pid} = MyXQL.start_link(username: "root", password: "password", protocol: :tcp)
    #MyXQL.query!(pid, "CREATE DATABASE IF NOT EXISTS people")
    {:ok, pid} = MyXQL.start_link(username: "root", password: "123456", host: "db", database: "erlang", protocol: :tcp)
    :erlang.register(:db, pid)
    MyXQL.query!(:db, "CREATE TABLE IF NOT EXISTS data (id VARCHAR(4), name VARCHAR(255), phone VARCHAR(4), age INT)")
  end

  def existing_users() do
    #pid = sql_start()
    {:ok, data} = File.read("resources/users.dat")
    listOfData = String.split(data, [", ", "\n"])
    read(listOfData)
  end

    defp read([]) do
      :ok
    end
    defp read([headName, headPhone, headAge, headId | tailData]) do
      MyXQL.query!(:db, "INSERT INTO data (id, name, phone, age) VALUES (?,?,?,?)", [headId, headName, headPhone, String.to_integer(headAge)])
      read(tailData)
    end
 
  def delete_data() do
    #pid = sql_start()
    MyXQL.query!(:db, "DROP DATABASE people")
  end

  def all_users() do
    {:ok, data} = MyXQL.query(:db, "SELECT * FROM data")
    [data.columns, data.rows]
  end

  def one_user(id) do
    {:ok, data} = MyXQL.query(:db, "SELECT * FROM data WHERE id = ?", [id])
    [data.columns, data.rows]
  end

  def older_than(age) do
    {:ok, data} = MyXQL.query(:db, "SELECT * FROM data WHERE age > ?", [age])
    [data.columns, data.rows]
  end 

  def younger_than(age) do
    {:ok, data} = MyXQL.query(:db, "SELECT * FROM data WHERE age < ?", [age])
    [data.columns, data.rows]
  end 

  def find_by_name(name) do
    {:ok, data} = MyXQL.query(:db, "SELECT * FROM data WHERE name = ?", [name])
    [data.columns, data.rows]
  end

  def delete_user(id) do
    MyXQL.query(:db, "DELETE FROM data WHERE id = ?", [id])
  end

  def add_user(idList) do
    try do
      id = IO.gets("Enter ID: ") |> String.trim
      name = IO.gets("Enter name: ") |> String.trim
      phone = IO.gets("Enter phone: ") |> String.trim
      {age, "\n"} = IO.gets("Enter age: ") |> Integer.parse

      if Enum.member?(idList, id) do
        "<h3>Error adding. User with this ID already exists</h3>"
      else
        MyXQL.query(:db, "INSERT INTO data (id, name, phone, age) VALUES (?,?,?,?)", [id, name, phone, age])
        "<h3>User added</h3>";
      end
    rescue
      e in MatchError -> "<h3>Data entry error. Enter a number in the age field</h3>"
    end

  end

  def id_list() do
    {:ok, data} = MyXQL.query(:db, "SELECT id FROM data")
    id_list(data.rows, [])
  end
    defp id_list([], acc) do 
      acc
    end
    defp id_list([headId|tailId], acc) do
      id_list(tailId, [List.to_string(headId)|acc])
    end

  def name_list() do
    {:ok, data} = MyXQL.query(:db, "SELECT name FROM data")
    name_list(data.rows, [])
  end
    defp name_list([], acc) do 
      acc
    end
    defp name_list([headId|tailId], acc) do
      name_list(tailId, [List.to_string(headId)|acc])
    end

end
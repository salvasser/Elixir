defmodule WebUsers do
  import SQLmodule
  @moduledoc """
  Documentation for `People`.

  database application.

  ## Examples
      first execute:
      iex> People.existing_users()

      iex> People.main()
      Enter your request: all_users/one_user/users_older/users_younger/find_by_name

      If you need delete data in database execute:
      iex> People.delete_data()
  """

  def server(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    #Logger.info("Accepting connections on port #{port}")
    client(socket)
  end

  defp client(serverSocket) do
    pid = sql_start()
    idList = id_list(pid)
    nameList = name_list(pid)
    {:ok, socket} = :gen_tcp.accept(serverSocket)
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.puts(msg)
    html = handler(msg) |> request(pid, idList, nameList, msg)
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


  defp request(data, pid, idList, nameList, msg) do 
      [term, value] = find_value(msg)
      case data do
        "get-users" ->
          cond do
            term == "older" ->
              "<h1>User data</h1><br>" <> output(older_than(pid, value))
            term == "younger" -> 
              "<h1>User data</h1><br>" <> output(younger_than(pid, value))
            true ->
              "<h1>User data</h1><br>" <> output(all_users(pid))
          end
        "get-user" ->
          if (Enum.member?(idList, value)) or (Enum.member?(nameList, value)) do
            cond do
              term == "id" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> output(one_user(pid, value))
              term == "name" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> output(find_by_name(pid, value))
              true ->
                "<h3>Error query after (get-user). Enter (name) or (id)</h3>"
            end
          else
            "<h3>There is no user with this ID/name, check the data</h3>"
          end
        "delete-user" ->
          if Enum.member?(idList, value) do
            delete_user(pid, value)
            "<h1>Removing a user</h1><br><p>user " <> to_string(value) <> " deleted</p>"
          else
            "<h3>There is no user with this ID, check the data<h3>"
          end
        "add-user" ->
          add_user(pid, idList)
          
        _-> {:ok, data} = File.read("resources/start_page.html")
            data
      end

  end 

  defp output([key, value]) do 
    #mirrorKey = Enum.reverse(key)
    #mirrorValue = Enum.reverse(value)
    output(value, key, [])
  end
  
  defp output([], _, acc) do
    [lineBreak, _ | tailAcc] = acc   #delete extra comma
    "[" <> to_string(Enum.reverse([lineBreak] ++ tailAcc)) <> "]"
  end

  defp output([[headId, headName, headPhone, headAge] | tailData], [id, name, phone, age], acc) do
    output(tailData, [id, name, phone, age], ["<br>", ",", "}", Integer.to_string(headAge), ": ", "&#34", age, "&#34", "<br>", ",", headPhone, ": ", "&#34", phone, "&#34", "<br>", ",", "&#34", headName, "&#34", ": ", "&#34", name, "&#34", "<br>", ",", headId, ": ", "&#34", id, "&#34", "{", "<br>" | acc])
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


end
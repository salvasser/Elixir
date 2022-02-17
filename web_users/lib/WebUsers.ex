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
              "<h1>User data</h1><br>" <> "<table>" <> output(older_than(pid, value)) <> "</table>"
            term == "younger" -> 
              "<h1>User data</h1><br>" <> "<table>" <> output(younger_than(pid, value)) <> "</table>"
            true ->
              "<h1>User data</h1><br>" <> "<table>" <> output(all_users(pid)) <> "</table>"
          end
        "get-user" ->
          if (Enum.member?(idList, value)) or (Enum.member?(nameList, value)) do
            cond do
              term == "id" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> "<table>" <> output(one_user(pid, value)) <> "</table>"
              term == "name" ->
                "<h1>User " <> to_string(value) <> " data</h1><br>" <> "<table>" <> output(find_by_name(pid, value)) <> "</table>"
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


  defp output([[id, name, phone, age], data]) do
    header = ["<tr>","<td>","<h4>",id,"</h4>","</td>","<td>","<h4>",name,"</h4>","</td>","<td>","<h4>",phone,"</h4>","</td>","<td>","<h4>",age,"</h4>","</td>","</tr>"]
    output_data(data, header, [])
  end

    defp output_data([], header, acc) do
      to_string(header ++ Enum.reverse(acc))
    end
    defp output_data([[headId, headName, headPhone, headAge] | tailData], header, acc) do
      output_data(tailData, header, ["</tr>","</td>",Integer.to_string(headAge),"<td>","</td>",headPhone,"<td>","</td>",headName,"<td>","</td>",headId,"<td>","<tr>" | acc])
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

end
defmodule People do
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

  def main() do
    pid = sql_start()
    idList = id_list(pid)
    nameList = name_list(pid)
    #existing_users(pid)
    request(pid, idList, nameList)
  end

  def request(pid, idList, nameList) do 
    input = IO.gets("Enter your request: ") |> String.trim
    try do
      case input do
        "all_users" -> 
          all_users(pid) |> output()
        "one_user" ->
          id = IO.gets("Enter user's id: ") |> String.trim
          try do
            if Enum.member?(idList, id) do
              one_user(pid, id) |> output()
            else
              raise IdError
            end
          rescue
            e in IdError -> e          
          end
        "users_older" ->
          {age, "\n"} = IO.gets("Enter age: ") |> Integer.parse
          older_than(pid, age) |> output()
        "users_younger" ->
          {age, "\n"} = IO.gets("Enter age: ") |> Integer.parse
          younger_than(pid, age) |> output()
        "find_by_name" ->
          name = IO.gets("Enter user's name: ") |> String.trim
          try do
          if Enum.member?(nameList, name) do
            find_by_name(pid, name) |> output()
          else
            raise NameError
          end
          rescue
            e in NameError -> e          
          end
          #find_by_name(pid, name) |> output()
        _-> raise RequestError
      end
    rescue
      e in RequestError -> e
    end
  end 

  def output([[id, name, phone, age], data]) do
    IO.puts("#{id} #{name} #{phone} #{age}")
    output_data(data)
  end

    defp output_data([]) do
      :ok
    end
    defp output_data([[headId, headName, headPhone, headAge] | tailData]) do
      IO.puts("#{headId}  #{headName}  #{headPhone}  #{headAge}")
      output_data(tailData)
    end
end
defmodule WebUsersTest do
  use ExUnit.Case
  doctest WebUsers

  test "greets the world" do
    assert WebUsers.hello() == :world
  end
end

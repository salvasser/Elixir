defmodule WebUsersTest do
  use ExUnit.Case
  #doctest WebUsers

  test "handler1" do
    assert WebUsers.handler("GET /get-users HTTP/1.1") == "get-users"
  end

  test "handler2" do
    assert WebUsers.handler("GET /add-user HTTP/1.1") == "add-user"
  end









end

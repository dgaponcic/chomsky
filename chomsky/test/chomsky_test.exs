defmodule ChomskyTest do
  use ExUnit.Case
  doctest Chomsky

  test "greets the world" do
    assert Chomsky.hello() == :world
  end
end

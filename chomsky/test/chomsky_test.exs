defmodule ChomskyTest do
  use ExUnit.Case
  doctest Chomsky

  test "V9" do
    input = %{
      :S => ["bA", "BC"],
      :A => ["a", "aS", "bAaAb"],
      :B => ["A", "bS", "aAa"],
      :C => ["", "AB"],
      :D => ["AB"]
    }

    output = %{
      A: ["a", "X1S", "X2X3"],
      B: ["a", "X1S", "X2X3", "X2S", "X1X4"],
      C: ["AB"],
      S: ["X2A", "BC", "a", "X1S", "X2X3", "X2S", "X1X4"],
      X1: ["a"],
      X2: ["b"],
      X3: ["AX5"],
      X4: ["AX1"],
      X5: ["X1X6"],
      X6: ["AX2"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V10" do
    input = %{
      :S => ["dB", "AB"],
      :A => ["d", "dS", "aAaAb", ""],
      :B => ["a", "aS", "A"],
      :D => ["Aba"]
    }

    output = %{
      A: ["d", "X1S", "X2X3", "X2X4", "X2X5", "X2X6"],
      B: ["a", "X2S", "d", "X1S", "X2X3", "X2X4", "X2X5", "X2X6"],
      S: ["X1B", "d", "AB", "X1S", "X2X3", "X2X4", "X2X5", "X2X6", "a", "X2S"],
      X1: ["d"],
      X2: ["a"],
      X3: ["AX4"],
      X4: ["X2X7"],
      X5: ["AX6"],
      X6: ["X2X8"],
      X7: ["AX8"],
      X8: ["b"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V19" do
    input = %{
      :S => ["aA", "AC"],
      :A => ["a", "ASC", "BC", "aD"],
      :B => ["b", "bA"],
      :C => ["", "BA"],
      :D => ["abC"],
      :E => ["aB"]
    }

    output = %{
      A: ["a", "AX1", "AS", "BC", "b", "X2A", "X3D"],
      B: ["b", "X2A"],
      C: ["BA"],
      D: ["X3X4", "X3X2"],
      S: ["X3A", "AC", "a", "AX1", "AS", "BC", "b", "X2A", "X3D"],
      X1: ["SC"],
      X2: ["b"],
      X3: ["a"],
      X4: ["X2C"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V23" do
    input = %{
      :S => ["bAC", "B"],
      :A => ["a", "aS", "bCaCb"],
      :B => ["AC", "bS", "aAa"],
      :C => ["", "AB"],
      :E => ["BA"]
    }

    output = %{
      A: ["a", "X1S", "X2X3", "X2X4", "X2X5", "X2X6"],
      B: ["AC", "a", "X1S", "X2X3", "X2X4", "X2X5", "X2X6", "X2S", "X1X7"],
      C: ["AB"],
      S: ["X2X8", "X2A", "AC", "a", "X1S", "X2X3", "X2X4", "X2X5", "X2X6", "X2S", "X1X7"],
      X1: ["a"],
      X2: ["b"],
      X3: ["CX4"],
      X4: ["X1X9"],
      X5: ["CX6"],
      X6: ["X1X2"],
      X7: ["AX1"],
      X8: ["AC"],
      X9: ["CX2"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V31" do
    input = %{
      :S => ["AC", "bA", "B", "aA"],
      :A => ["", "aS", "ABAb"],
      :B => ["a", "AbSA"],
      :C => ["abC"],
      :D => ["AB"]
    }

    output = %{
      A: ["X1S", "AX2", "BX3", "AX4", "BX5"],
      B: ["a", "AX6", "X5X7", "AX8", "X5S"],
      S: ["X5A", "b", "a", "AX6", "X5X7", "AX8", "X5S", "X1A"],
      X1: ["a"],
      X2: ["BX3"],
      X3: ["AX5"],
      X4: ["BX5"],
      X5: ["b"],
      X6: ["X5X7"],
      X7: ["SA"],
      X8: ["X5S"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V17" do
    input = %{
      :S => ["aA", "AC"],
      :A => ["a", "ASC", "BC", "aD"],
      :B => ["b", "bA"],
      :C => ["", "BA"],
      :E => ["aB"],
      :D => ["abC"]
    }

    output = %{
      A: ["a", "AX1", "AS", "BC", "b", "X2A", "X3D"],
      B: ["b", "X2A"],
      C: ["BA"],
      D: ["X3X4", "X3X2"],
      S: ["X3A", "AC", "a", "AX1", "AS", "BC", "b", "X2A", "X3D"],
      X1: ["SC"],
      X2: ["b"],
      X3: ["a"],
      X4: ["X2C"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V3" do
    input = %{
      :S => ["dB", "A"],
      :A => ["d", "dS", "aAdAB"],
      :B => ["aC", "aS", "AC"],
      :C => [""],
      :E => ["AS"]
    }

    output = %{
      A: ["d", "X1S", "X2X3"],
      B: ["a", "X2S", "d", "X1S", "X2X3"],
      S: ["X1B", "d", "X1S", "X2X3"],
      X1: ["d"],
      X2: ["a"],
      X3: ["AX4"],
      X4: ["X1X5"],
      X5: ["AB"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end

  test "V13" do
    input = %{
      :S => ["aB", "DA"],
      :A => ["a", "BD", "bDAB"],
      :B => ["b", "BA"],
      :D => ["", "BA"],
      :C => ["BA"]
    }

    output = %{
      A: ["a", "BD", "b", "BA", "X1X2", "X1X3"],
      B: ["b", "BA"],
      D: ["BA"],
      X1: ["b"],
      X2: ["DX3"],
      X3: ["AB"]
    }

    assert Chomsky.convert2chomsky(input) == output
  end
end

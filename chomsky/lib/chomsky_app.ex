defmodule ChomskyApp do
  def start() do
    %{
      :S => ["bA", "BC"],
      :A => ["a", "aS", "bAaAb"],
      :B => ["A", "bS", "aAa"],
      :C => ["", "AB"],
      :D => ["AB"]
    }
    |> Chomsky.convert2chomsky()
    |> IO.inspect()
  end
end

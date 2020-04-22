defmodule Combinations do
  def comb(0, _arr), do: [[]]
  def comb(_nb, []), do: []

  def comb(nb, [head | tail]) do
    for(element <- comb(nb - 1, tail), do: [head | element]) ++ comb(nb, tail)
  end

  defp get_combinations_n_states(n, possitions) do
    Enum.reduce(Combinations.comb(n, possitions), [], fn x, acc ->
      Enum.concat(acc, [x])
    end)
  end

  def get_all_combinations(possitions) do
    1..length(possitions)
    |> Enum.reduce([], fn i, acc ->
      Enum.concat(acc, get_combinations_n_states(i, possitions))
    end)
  end
end

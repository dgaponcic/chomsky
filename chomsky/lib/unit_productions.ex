defmodule UnitProductions do
  def remove_duplicates(grammar) do
    grammar
    |> Enum.map(fn {state, transitions} -> {state, Enum.uniq(transitions)} end)
    |> Map.new()
  end

  def has_unit_pr({_state, transitions}) do
    Enum.any?(transitions, fn transition ->
      is_unit_pr(transition)
    end)
  end

  def is_unit_pr(transition) do
    String.length(transition) == 1 and transition == String.upcase(transition)
  end

  def get_transitions(_grammar, transition, acc, false) do
    Enum.concat(acc, [transition])
  end

  def get_transitions(grammar, transition, acc, true) do
    Enum.concat(acc, Map.get(grammar, String.to_atom(transition)))
  end

  def remove_unit_pr(grammar, transitions) do
    transitions
    |> Enum.reduce([], fn transition, acc ->
      get_transitions(grammar, transition, acc, is_unit_pr(transition))
    end)
  end

  def get_grammar_without_unit_pr(grammar, true) do
    grammar
  end

  def get_grammar_without_unit_pr(grammar, false) do
    grammar =
      grammar
      |> Enum.map(fn {state, transitions} ->
        {state, remove_unit_pr(grammar, transitions)}
      end)
      |> remove_duplicates()

    get_grammar_without_unit_pr(grammar, Enum.all?(grammar, &(!UnitProductions.has_unit_pr(&1))))
  end

  def get_grammar_without_unit_pr(grammar) do
    grammar
    |> get_grammar_without_unit_pr(Enum.all?(grammar, &(!has_unit_pr(&1))))
  end
end

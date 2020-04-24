defmodule Chomsky do
  defp init_grammar(grammar) do
    grammar
    |> EpsilonRemoval.get_grammar_without_epsilon()
    |> UnitProductions.get_grammar_without_unit_pr()
    |> UnproductiveRemoval.get_grammar_without_unproductive()
    |> InaccessibleRemoval.get_grammar_without_inaccessible()
  end

  defp get_counter() do
    {:ok, pid} = Agent.start_link(fn -> 1 end)
    fn -> Agent.get_and_update(pid, fn i -> {i, i + 1} end) end
  end

  defp get_updated_grammar(grammar, new_states) do
    grammar
    |> ChomskyTransitions.transform_transitions2chomsky(new_states)
    |> ChomskyStates.add_new_states2grammar(new_states)
  end

  def convert2chomsky(grammar, _counter, _new_states, true) do
    grammar
  end

  def convert2chomsky(grammar, counter, new_states, false) do
    new_states = ChomskyStates.get_new_states(grammar, counter, new_states)
    grammar = get_updated_grammar(grammar, new_states)

    convert2chomsky(
      grammar,
      counter,
      new_states,
      Enum.all?(grammar, &ChomskyStates.is_in_chomsky(&1))
    )
  end

  def convert2chomsky(grammar) do
    counter = get_counter()
    is_in_chomsky = Enum.all?(grammar, &ChomskyStates.is_in_chomsky(&1))

    grammar
    |> init_grammar()
    |> convert2chomsky(counter, %{}, is_in_chomsky)
  end
end

defmodule EpsilonRemoval do
  defp get_state_pos(transitions, state) do
    transitions
    |> Enum.with_index()
    |> Enum.filter(fn {x, _} -> x == state end)
    |> Enum.map(fn {_, i} -> i end)
  end

  defp get_new_transition(combination, transition) do
    combination
    |> Enum.reduce(String.graphemes(transition), fn id, acc ->
      List.replace_at(acc, id, "")
    end)
    |> Enum.join("")
  end

  defp replace_epsilon_state(state, transition) do
    String.graphemes(transition)
    |> get_state_pos(Atom.to_string(state))
    |> Combinations.get_all_combinations()
    |> Enum.reduce([transition], fn combination, acc ->
      Enum.concat(acc, [get_new_transition(combination, transition)])
    end)
  end

  defp delete_epsilon(grammar, state) do
    transitions_with_eps = Map.get(grammar, state)
    Map.put(grammar, state, List.delete(transitions_with_eps, ""))
  end

  defp concat_transitions(acc, state, transition, true) do
    Enum.concat(acc, replace_epsilon_state(state, transition))
  end

  defp concat_transitions(acc, _state, transition, false) do
    Enum.concat(acc, [transition])
  end

  defp get_transitions_without_eps(transitions, state) do
    Enum.reduce(transitions, [], fn transition, acc ->
      is_contained = String.contains?(transition, Atom.to_string(state))
      concat_transitions(acc, state, transition, is_contained)
    end)
  end

  defp get_transitions(grammar, state_with_eps) do
    grammar
    |> Enum.map(fn {state, transitions} ->
      {state, get_transitions_without_eps(transitions, state_with_eps)}
    end)
    |> Map.new()
  end

  defp remove_epsilon(grammar, _state_with_epsilon, false) do
    grammar
  end

  defp remove_epsilon(grammar, state_with_eps, true) do
    grammar
    |> delete_epsilon(state_with_eps)
    |> get_transitions(state_with_eps)
  end

  defp remove_duplicates(grammar) do
    grammar
    |> Enum.map(fn {state, transitions} -> {state, Enum.uniq(transitions)} end)
    |> Map.new()
  end

  defp has_epsilon({_state, transitions}) do
    Enum.member?(transitions, "")
  end

  defp get_grammar_without_epsilon(grammar, true) do
    grammar
  end

  defp get_grammar_without_epsilon(grammar, false) do
    grammar
    |> Enum.reduce(grammar, fn {state, transitions}, acc ->
      remove_epsilon(acc, state, has_epsilon({state, transitions}))
    end)
    |> remove_duplicates()
    |> get_grammar_without_epsilon(Enum.all?(grammar, &(!has_epsilon(&1))))
  end

  def get_grammar_without_epsilon(grammar) do
    grammar
    |> get_grammar_without_epsilon(Enum.all?(grammar, &(!has_epsilon(&1))))
  end
end

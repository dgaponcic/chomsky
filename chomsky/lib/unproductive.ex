defmodule UnproductiveRemoval do
  defp is_terminal(transition) do
    String.length(transition) == 1 and transition == String.downcase(transition)
  end

  defp is_non_terminal(transition) do
    transition == String.upcase(transition)
  end

  defp get_non_terminals(transition) do
    String.graphemes(transition)
    |> Enum.filter(&is_non_terminal(&1))
    |> Enum.uniq()
    |> Enum.map(fn state -> String.to_atom(state) end)
  end

  defp is_productive(transition, productive) do
    get_non_terminals(transition)
    |> Enum.all?(fn state -> Enum.member?(productive, state) end)
  end

  defp is_unproductive(transition, unproductive) do
    get_non_terminals(transition)
    |> Enum.any?(fn state -> Enum.member?(unproductive, state) end)
  end

  defp add_state_by_predicate(acc, state, true) do
    [state | acc]
  end

  defp add_state_by_predicate(acc, _state, false) do
    acc
  end

  defp find_all_terminal_states(grammar) do
    grammar
    |> Enum.reduce([], fn {state, transitions}, acc ->
      add_state_by_predicate(acc, state, Enum.any?(transitions, &is_terminal(&1)))
    end)
  end

  defp get_productive(grammar, productive) do
    Enum.reduce(grammar, [], fn {state, transitions}, acc ->
      add_state_by_predicate(acc, state, Enum.any?(transitions, &is_productive(&1, productive)))
    end)
  end

  defp find_all_productive_states(_grammar, productive, true) do
    productive
  end

  defp find_all_productive_states(grammar, productive, false) do
    new_productive = get_productive(grammar, productive)
    find_all_productive_states(grammar, new_productive, new_productive == productive)
  end

  defp filter_transitions(transitions, unproductive) do
    Enum.filter(transitions, &(!is_unproductive(&1, unproductive)))
  end

  defp add_productive(acc, _state, _transitions, true) do
    acc
  end

  defp add_productive(acc, state, transitions, false) do
    Map.put(acc, state, transitions)
  end

  defp filter_unproductive(grammar, _unproductive, false) do
    grammar
  end

  defp filter_unproductive(grammar, unproductive, true) do
    grammar
    |> Enum.reduce(%{}, fn {state, transitions}, acc ->
      add_productive(acc, state, transitions, Enum.member?(unproductive, state))
    end)
    |> Enum.map(fn {state, transitions} ->
      {state, filter_transitions(transitions, unproductive)}
    end)
  end

  def get_grammar_without_unproductive(grammar) do
    productive = find_all_productive_states(grammar, find_all_terminal_states(grammar), false)

    unproductive =
      Enum.filter(Map.keys(grammar), fn state ->
        !Enum.member?(productive, state)
      end)

    filter_unproductive(grammar, unproductive, length(unproductive) > 0)
  end
end

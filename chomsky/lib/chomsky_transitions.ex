defmodule ChomskyTransitions do
  defp string_replace(transition, string_to_replace, new_states) do
    String.replace(
      transition,
      string_to_replace,
      Atom.to_string(Map.get(new_states, string_to_replace)),
      global: false
    )
  end

  defp update_transition_two_symbols(transition, new_states) do
    head = Enum.at(String.graphemes(transition), 0)
    tail = Enum.at(String.graphemes(transition), 1)

    cond do
      ChomskyStates.are_terminals(transition) ->
        transition |> string_replace(head, new_states) |> string_replace(tail, new_states)

      ChomskyStates.are_terminals(head) ->
        string_replace(transition, head, new_states)

      true ->
        string_replace(transition, tail, new_states)
    end
  end

  defp update_first_symbol(transition, head, new_states) do
    if head != String.upcase(head) do
      string_replace(transition, head, new_states)
    else
      transition
    end
  end

  defp update_transition_n_symbols(transition, new_states) do
    [head | tail] = String.graphemes(transition)
    tail = List.to_string(tail)
    new_transition = update_first_symbol(transition, head, new_states)
    String.replace(new_transition, tail, Atom.to_string(Map.get(new_states, tail)), global: false)
  end

  defp update_transition(transition, new_states) do
    cond do
      length(String.graphemes(transition)) == 2 and !ChomskyStates.are_nonterminals(transition) ->
        update_transition_two_symbols(transition, new_states)

      length(String.graphemes(transition)) > 2 and !ChomskyStates.was_converted(transition) ->
        update_transition_n_symbols(transition, new_states)

      true ->
        transition
    end
  end

  defp update_transitions(transitions, new_states) do
    Enum.map(transitions, fn transition ->
      update_transition(transition, new_states)
    end)
  end

  def transform_transitions2chomsky(grammar, new_states) do
    grammar
    |> Enum.map(fn {state, transitions} ->
      {state, update_transitions(transitions, new_states)}
    end)
    |> Map.new()
  end
end

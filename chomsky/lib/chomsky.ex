defmodule Chomsky do
  defp init_grammar(grammar) do
    grammar
    |> EpsilonRemoval.get_grammar_without_epsilon(
      Enum.all?(grammar, &(!EpsilonRemoval.has_epsilon(&1)))
    )
    |> UnitProductions.get_grammar_without_unit_pr(
      Enum.all?(grammar, &(!UnitProductions.has_unit_pr(&1)))
    )
    |> UnproductiveRemoval.get_grammar_without_unproductive()
    |> InaccessibleRemoval.get_grammar_without_inaccessible()
  end

  defp get_counter() do
    {:ok, pid} = Agent.start_link(fn -> 1 end)
    fn -> Agent.get_and_update(pid, fn i -> {i, i + 1} end) end
  end

  defp are_terminals(transition) do
    transition == String.downcase(transition)
  end

  defp are_nonterminals(transition) do
    transition == String.upcase(transition)
  end

  defp convert_terminals(init_acc, transition, counter) do
    Enum.reduce(String.graphemes(transition), init_acc, fn state, acc ->
      convert_one_symbol(acc, state, counter)
    end)
  end

  defp convert_one_symbol(acc, state, counter) do
    if Enum.member?(Map.keys(acc), state) do
      acc
    else
      Map.put(acc, state, :"X#{counter.()}")
    end
  end

  defp add_states_two_symbols(transition, counter, acc) do
    head = Enum.at(String.graphemes(transition), 0)

    cond do
      are_terminals(transition) ->
        convert_terminals(acc, transition, counter)

      are_terminals(head) ->
        convert_one_symbol(acc, head, counter)

      true ->
        tail = Enum.at(String.graphemes(transition), 1)
        convert_one_symbol(acc, tail, counter)
    end
  end

  defp add_state_first_symbol(head, acc, counter) do
    if !are_nonterminals(head) do
      convert_one_symbol(acc, head, counter)
    else
      acc
    end
  end

  defp add_states_n_symbols(transition, counter, acc) do
    [head | tail] = String.graphemes(transition)
    acc = add_state_first_symbol(head, acc, counter)
    convert_one_symbol(acc, List.to_string(tail), counter)
  end

  defp add_new_state(transition, counter, acc) do
    cond do
      length(String.graphemes(transition)) == 2 and transition != String.upcase(transition) ->
        add_states_two_symbols(transition, counter, acc)

      length(String.graphemes(transition)) > 2 and !was_converted(transition) ->
        add_states_n_symbols(transition, counter, acc)

      true ->
        acc
    end
  end

  defp add_new_states(transitions, new_states, counter) do
    Enum.reduce(transitions, new_states, fn transition, acc ->
      add_new_state(transition, counter, acc)
    end)
  end

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
      are_terminals(transition) ->
        transition |> string_replace(head, new_states) |> string_replace(tail, new_states)

      are_terminals(head) ->
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
      length(String.graphemes(transition)) == 2 and !are_nonterminals(transition) ->
        update_transition_two_symbols(transition, new_states)

      length(String.graphemes(transition)) > 2 and !was_converted(transition) ->
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

  defp was_converted(transition) do
    Regex.match?(~r/\d/, transition)
  end

  defp is_one_terminal(transition) do
    length(String.graphemes(transition)) == 1 and !are_nonterminals(transition)
  end

  defp are_two_nonterminal(transition) do
    length(String.graphemes(transition)) == 2 and are_nonterminals(transition)
  end

  defp is_in_chomsky({_state, transitions}) do
    Enum.all?(transitions, fn transition ->
      are_two_nonterminal(transition) or is_one_terminal(transition) or was_converted(transition)
    end)
  end

  defp get_new_states(grammar, counter, new_states) do
    grammar
    |> Enum.reduce(new_states, fn {_state, transitions}, acc ->
      add_new_states(transitions, acc, counter)
    end)
  end

  defp transform_transitions2chomsky(grammar, new_states) do
    grammar
    |> Enum.map(fn {state, transitions} ->
      {state, update_transitions(transitions, new_states)}
    end)
    |> Map.new()
  end

  defp add_new_states2grammar(grammar, new_states) do
    new_states
    |> Enum.reduce(grammar, fn {transition, state}, acc ->
      Map.put_new(acc, state, [transition])
    end)
    |> Map.new()
  end

  defp get_updated_grammar(grammar, new_states) do
    grammar
      |> transform_transitions2chomsky(new_states)
      |> add_new_states2grammar(new_states)
  end

  defp convert_transitions(grammar, _counter, _new_states, true) do
    grammar
  end

  defp convert_transitions(grammar, counter, new_states, false) do
    new_states = get_new_states(grammar, counter, new_states)
    grammar = get_updated_grammar(grammar, new_states)
    convert_transitions(grammar, counter, new_states, Enum.all?(grammar, &is_in_chomsky(&1)))
  end

  def to_chomsky(grammar) do
    counter = get_counter()

    grammar
    |> init_grammar()
    |> convert_transitions(counter, %{}, Enum.all?(grammar, &is_in_chomsky(&1)))
    |> IO.inspect()
  end
end

%{
  :S => ["bA", "BC"],
  :A => ["a", "aS", "bAaAb"],
  :B => ["A", "bS", "aAa"],
  :C => ["", "AB"],
  :D => ["AB"]
}

# %{:S => ["dB", "AB"], :A => ["d", "dS", "aAaAb", ""], :B => ["a", "aS", "A"], :D => ["Aba"]}
|> Chomsky.to_chomsky()

defmodule ChomskyStates do
  defp convert_terminals(init_acc, transition, counter) do
    Enum.reduce(String.graphemes(transition), init_acc, fn symbol, acc ->
      convert_one_symbol(acc, symbol, counter)
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

  defp is_one_terminal(transition) do
    length(String.graphemes(transition)) == 1 and !are_nonterminals(transition)
  end

  defp are_two_nonterminal(transition) do
    length(String.graphemes(transition)) == 2 and are_nonterminals(transition)
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

  def are_terminals(transition) do
    transition == String.downcase(transition)
  end

  def are_nonterminals(transition) do
    transition == String.upcase(transition)
  end

  def was_converted(transition) do
    Regex.match?(~r/\d/, transition)
  end

  def is_in_chomsky({_state, transitions}) do
    Enum.all?(transitions, fn transition ->
      are_two_nonterminal(transition) or is_one_terminal(transition) or was_converted(transition)
    end)
  end

  def get_new_states(grammar, counter, new_states) do
    grammar
    |> Enum.reduce(new_states, fn {_state, transitions}, acc ->
      add_new_states(transitions, acc, counter)
    end)
  end
end

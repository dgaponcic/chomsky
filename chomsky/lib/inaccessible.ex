defmodule InaccessibleRemoval do
  defp join_transitions(transitions, acc) do
    transitions
    |> Enum.concat(acc)
    |> Enum.uniq()
  end

  def get_new_states(transitions, acc) do
    transitions
    |> Enum.reduce([], fn transition, acc ->
      join_transitions(String.graphemes(transition), acc)
    end)
    |> join_transitions(acc)
  end

  def is_terminal(transition) do
    String.length(transition) == 1 and transition == String.downcase(transition)
  end

  def is_non_terminal(transition) do
    String.length(transition) == 1 and transition == String.upcase(transition)
  end

  def get_keys(grammar) do
    grammar
    |> Map.keys()
    |> Enum.map(fn key -> Atom.to_string(key) end)
  end

  def get_all_states(grammar) do
    Enum.reduce(grammar, get_keys(grammar), fn {_, transitions}, acc ->
      transitions
      |> get_new_states(acc)
    end)
  end

  defp get_states_for_nonterminals(_grammar, state, acc, false) do
    [state | acc]
  end

  defp get_states_for_nonterminals(grammar, state, acc, true) do
    Map.get(grammar, String.to_atom(state)) |> get_new_states(acc)
  end

  def find_all_accessible_states(grammar, accessible, false) do
    new_accessible =
      accessible
      |> Enum.reduce([], fn state, acc ->
        get_states_for_nonterminals(grammar, state, acc, is_non_terminal(state))
      end)

    find_all_accessible_states(grammar, new_accessible, new_accessible == accessible)
  end

  def find_all_accessible_states(_, accessible, true) do
    accessible
  end

  def add_accessible(acc, state, transitions, false) do
    Map.put(acc, state, transitions)
  end

  def add_accessible(acc, _state, _transitions, true) do
    acc
  end

  def filter_inaccessible(grammar, _inaccessible, false) do
    grammar
  end

  def filter_inaccessible(grammar, inaccessible, true) do
    grammar
    |> Enum.reduce(%{}, fn {state, transitions}, acc ->
      is_member = Enum.member?(inaccessible, Atom.to_string(state))
      add_accessible(acc, state, transitions, is_member)
    end)
  end

  def get_grammar_without_inaccessible(grammar) do
    accessible = find_all_accessible_states(grammar, ["S"], false)
    all_states = get_all_states(grammar)
    inaccessible = Enum.filter(all_states, fn state -> !Enum.member?(accessible, state) end)
    filter_inaccessible(grammar, inaccessible, length(inaccessible) > 0)
  end
end

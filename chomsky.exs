defmodule Combinations do
  def comb(0, _), do: [[]]
  def comb(_, []), do: []
  def comb(m, [h|t]) do
    (for l <- comb(m-1, t), do: [h|l]) ++ comb(m, t)
  end
end 

defmodule Epsilon_Removal do

  def get_state_pos(transitions, state) do
    transitions 
    |> Enum.with_index() 
    |> Enum.filter(fn {x, _} -> x == state end)
    |> Enum.map(fn {_, i} -> i end)
  end

  def has_epsilon({ _, transitions }) do
    Enum.member?(transitions, "")
  end

  def get_all_combinations(possitions) do
    range = 1..length(possitions)
    Enum.reduce(range, [], fn i, acc -> Enum.concat(acc, Enum.reduce(Combinations.comb(i, possitions), [], fn x, acc -> Enum.concat(acc, [x]) end)) end)
  end

  def get_new_transition(combination, transition) do
    Enum.join(Enum.reduce(combination, String.graphemes(transition), fn id, acc -> 
      List.replace_at(acc, id, "") 
    end), "")
  end

  def replace_epsilon_state(state, transition) do
    ids = get_state_pos(String.graphemes(transition), Atom.to_string(state))

    get_all_combinations(ids) 
    |> Enum.reduce([transition], fn combination, acc -> Enum.concat(acc, [get_new_transition(combination, transition)]) end) 
  
  end

  def delete_epsilon(grammar, state) do
    transitions_with_eps = Map.get(grammar, state)
    Map.put(grammar, state,  List.delete(transitions_with_eps, ""))
  end

  def get_transitions_without_eps(transitions, state) do 
    Enum.reduce(transitions, [], fn element, acc -> 
      if String.contains?(element, Atom.to_string(state)) do
        Enum.concat(acc, replace_epsilon_state(state, element))
      else
        Enum.concat(acc, [element])
      end
    end)
  end

  def remove_epsilon(grammar, _, false) do
    grammar
  end

  def remove_epsilon(grammar, state_with_eps, true) do
    grammar
    |> delete_epsilon(state_with_eps)
    |> Enum.map(fn {state, transitions} -> 
        {state, get_transitions_without_eps(transitions, state_with_eps)}
    end)
    |> Map.new
  end

  def remove_duplicates(grammar) do
    grammar
    |> Enum.map(fn {state, transitions} -> {state, Enum.uniq(transitions)} end)
    |> Map.new
  end

  def get_grammar_without_epsilon(grammar, true) do
    grammar
  end

  def get_grammar_without_epsilon(grammar, false) do
    grammar 
    |>  Enum.reduce(grammar, fn {state, transitions}, acc -> 
          remove_epsilon(acc, state, Enum.member?(transitions, ""))
        end)
    |> remove_duplicates()
    |> get_grammar_without_epsilon(Enum.all?(grammar, &!Epsilon_Removal.has_epsilon(&1)))
  end
end


defmodule Unit_Productions do
  def remove_duplicates(grammar) do
    grammar
    |> Enum.map(fn {state, transitions} -> {state, Enum.uniq(transitions)} end)
    |> Map.new
  end

  def has_unit_pr({_, transitions}) do
    Enum.any?(transitions, fn transition ->
      is_unit_pr(transition)
    end)
  end

  def is_unit_pr(transition) do
    String.length(transition) == 1 and transition == String.upcase(transition)
  end

  def remove_unit_pr(grammar, transitions) do
    transitions
    |>  Enum.reduce([], fn transition, acc -> 
          if is_unit_pr(transition) do
            Enum.concat(acc, Map.get(grammar, String.to_atom(transition)))
          else 
            Enum.concat(acc, [transition])
          end
        end)
  end

  def get_grammar_without_unit_pr(grammar, true) do
    grammar
  end

  def get_grammar_without_unit_pr(grammar, false) do
    grammar
    |>  Enum.map(fn {state, transitions} -> 
          {state, remove_unit_pr(grammar, transitions)}
        end)
    |> remove_duplicates()
    |> get_grammar_without_unit_pr(Enum.all?(grammar, &!Unit_Productions.has_unit_pr(&1)))
  end

end


defmodule Unproductive_Removal do

  def is_terminal(transition) do
    String.length(transition) == 1 and transition == String.downcase(transition)
  end

  def is_non_terminal(transition) do
    transition == String.upcase(transition)
  end

  def get_non_terminals(transition) do
    String.graphemes(transition)
    |> Enum.filter(&is_non_terminal(&1))
    |> Enum.uniq
    |> Enum.map(fn state -> String.to_atom(state) end)
  end

  def is_productive(transition, productive) do
    get_non_terminals(transition)
    |> Enum.all?(fn state -> Enum.member?(productive, state) end)
  end

  def is_unproductive(transition, unproductive) do
    get_non_terminals(transition)
    |> Enum.any?(fn state -> Enum.member?(unproductive, state) end)
  end

  def find_all_terminal_states(grammar) do
    grammar
    |>  Enum.reduce([], fn {state, transitions}, acc -> 
          if Enum.any?(transitions, &is_terminal(&1)) do [state | acc] else acc end
        end)
  end

  def find_all_productive_states(_, productive, true) do
    productive
  end

  def find_all_productive_states(grammar, productive, false) do
    new_productive = grammar
    |>  Enum.reduce([], fn {state, transitions}, acc -> 
          if Enum.any?(transitions, &is_productive(&1, productive)) do [state | acc] else acc end
        end)

    find_all_productive_states(grammar, new_productive, new_productive == productive)
  end

  def filter_transitions(transitions, unproductive) do
    Enum.filter(transitions, &!is_unproductive(&1, unproductive))
  end

  def filter_unproductive(grammar, unproductive) do
    grammar
    |>  Enum.reduce(%{}, fn {state, transitions}, acc -> 
          if Enum.member?(unproductive, state) do acc else Map.put(acc, state, transitions) end
        end)
    |>  Enum.map(fn {state, transitions} -> 
          {state, filter_transitions(transitions, unproductive)}
        end)
  end

  def get_grammar_without_unproductive(grammar) do
    productive = find_all_productive_states(grammar, find_all_terminal_states(grammar), false)
    unproductive = Enum.filter(Map.keys(grammar), fn state -> !Enum.member?(productive, state) end)
    if length(unproductive) > 0 do filter_unproductive(grammar, unproductive) else grammar end
  end
end

defmodule Chomsky do
  def to_chomsky(grammar) do
    grammar
    |> Epsilon_Removal.get_grammar_without_epsilon(Enum.all?(grammar, &!Epsilon_Removal.has_epsilon(&1)))
    |> IO.inspect
    |> Unit_Productions.get_grammar_without_unit_pr(Enum.all?(grammar, &!Unit_Productions.has_unit_pr(&1)))
    |> IO.inspect
    |> Unproductive_Removal.get_grammar_without_unproductive()
    |> IO.inspect
  end
end

%{:S => ["bA", "BC"], :A => ["a", "aS"], :B => ["A", "bS", "aAa"], :C => ["", "AB", "bAaAbE"], :D => ["AB"]}
|> Chomsky.to_chomsky()

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
  def get_grammar_without_unit_pr(grammar) do
    grammar
  end
end

grammar = %{:S => ["bA", "BC"], :A => ["a", "aS", "bAaAb"], :B => ["A", "bS", "aAa"], :C => ["", "AB"], :D => ["AB"]}

grammar
|> Epsilon_Removal.get_grammar_without_epsilon(Enum.all?(grammar, &!Epsilon_Removal.has_epsilon(&1)))
|> Unit_Productions.get_grammar_without_unit_pr()
|> IO.inspect
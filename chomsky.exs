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

defmodule Inaccessible_removal do
  def get_new_states(transitions, acc) do
    transitions
    |>  Enum.reduce([], fn transition, acc ->
          String.graphemes(transition)
          |> Enum.concat(acc)
          |> Enum.uniq
        end)
    |> Enum.concat(acc)
    |> Enum.uniq
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


  def find_all_accessible_states(_, accessible, true) do
    accessible
  end

  def find_all_accessible_states(grammar, accessible, false) do
    new_accessible = accessible
    |>  Enum.reduce([], fn state, acc -> 
          if is_non_terminal(state) do 
            Map.get(grammar, String.to_atom(state)) |> get_new_states(acc) 
          else 
            [state | acc]
          end
        end)
    
    find_all_accessible_states(grammar, new_accessible, new_accessible == accessible)
  end

  def filter_inaccessible(grammar, inaccessible) do
    grammar
    |>  Enum.reduce(%{}, fn {state, transitions}, acc -> 
          if Enum.member?(inaccessible, Atom.to_string(state)) do acc else Map.put(acc, state, transitions) end
        end)
  end

  def get_grammar_without_inaccessible(grammar) do
    accessible = find_all_accessible_states(grammar, ["S"], false)
    all_states = get_all_states(grammar)
    inaccessible = Enum.filter(all_states, fn state -> !Enum.member?(accessible, state) end)
    if length(inaccessible) > 0 do filter_inaccessible(grammar, inaccessible) else grammar end
  end
end

defmodule Chomsky do
  def init_grammar(grammar) do
    grammar
    |> Epsilon_Removal.get_grammar_without_epsilon(Enum.all?(grammar, &!Epsilon_Removal.has_epsilon(&1)))
    # |> IO.inspect
    |> Unit_Productions.get_grammar_without_unit_pr(Enum.all?(grammar, &!Unit_Productions.has_unit_pr(&1)))
    # |> IO.inspect
    |> Unproductive_Removal.get_grammar_without_unproductive()
    # |> IO.inspect
    |> Inaccessible_removal.get_grammar_without_inaccessible()
    |> IO.inspect
  end


  def get_counter() do
    {:ok, pid} = Agent.start_link(fn -> 1 end)
    fn -> Agent.get_and_update(pid, fn i -> {i, i + 1} end) end
  end

  def add_states_from_2(transition, counter, acc) do
    head = Enum.at(String.graphemes(transition), 0)
    tail = Enum.at(String.graphemes(transition), 1)

    cond do
      transition == String.downcase(transition) -> 
        if Enum.member?(Map.keys(acc), head) do acc else Map.put(acc, head, :"X#{counter.()}") end
        if Enum.member?(Map.keys(acc), tail) do acc else Map.put(acc, tail, :"X#{counter.()}") end
      head == String.downcase(head) ->
        if Enum.member?(Map.keys(acc), head) do acc else Map.put(acc, head, :"X#{counter.()}") end
      true ->
        tail = Enum.at(String.graphemes(transition), 1)
        if Enum.member?(Map.keys(acc), tail) do acc else Map.put(acc, tail, :"X#{counter.()}") end
    end

  end

  def add_states_from_more(transition, counter, acc) do
    [head| tail] = String.graphemes(transition)

    if head != String.upcase(head) do
      if Enum.member?(Map.keys(acc), head) do Map.put(acc, head, :"X#{counter.()}") end
    end

    tail = List.to_string(tail)
    if Enum.member?(Map.keys(acc), tail) do acc else Map.put(acc, tail, :"X#{counter.()}") end
  end

  def add_new_states(transitions, new_states, counter) do
    Enum.reduce(transitions, new_states, fn transition, acc -> 

      cond do 
      length(String.graphemes(transition)) == 2 and transition != String.upcase(transition)->
        add_states_from_2(transition, counter, acc)
      length(String.graphemes(transition)) > 2 and !Regex.match?(~r/\d/, transition)->
        add_states_from_more(transition, counter, acc)
      true ->
        acc
      end

    end)
  end


  def update_transition_from_2(transition, new_states) do
    head = Enum.at(String.graphemes(transition), 0)
    tail = Enum.at(String.graphemes(transition), 1)

    cond do
      transition == String.downcase(transition) -> 
        transition = String.replace(transition, head, Atom.to_string(Map.get(new_states, head)), global: false)
        String.replace(transition, tail, Atom.to_string(Map.get(new_states, tail)), global: false)
      head == String.downcase(head) ->
        String.replace(transition, head, Atom.to_string(Map.get(new_states, head)), global: false)
      true ->
        String.replace(transition, tail, Atom.to_string(Map.get(new_states, tail)), global: false)
      end
  end

  def update_first_state(transition, head, new_states) do
    if head != String.upcase(head) do
      String.replace(transition, head, Atom.to_string(Map.get(new_states, head)), global: false)
    else
      transition
    end
  end

  def update_transition_from_more(transition, new_states) do
    [head| tail] = String.graphemes(transition)
    tail = List.to_string(tail)
    new_transition = update_first_state(transition, head, new_states)
    String.replace(new_transition, tail, Atom.to_string(Map.get(new_states, tail)), global: false)
  end

  def update_transitions(transitions, new_states) do
    Enum.map(transitions, fn transition -> 
      cond do 
        length(String.graphemes(transition)) == 2 and transition != String.upcase(transition)->
          update_transition_from_2(transition, new_states)
        length(String.graphemes(transition)) > 2 and !Regex.match?(~r/\d/, transition) ->
          update_transition_from_more(transition, new_states)
        true ->
          transition
      end
    end)
  end

  def is_in_chomsky({_, transitions}) do
    Enum.all?(transitions, fn transition -> 
      cond do
        length(String.graphemes(transition)) == 2 and transition == String.upcase(transition) ->
          true
        length(String.graphemes(transition)) == 1 and transition == String.downcase(transition) ->
          true
        Regex.match?(~r/\d/, transition) ->
          true
        true ->
          false
      end
    end)
  end

  def get_new_states(grammar, counter, new_states) do
    grammar
    |>  Enum.reduce(%{}, fn {_, transitions}, acc -> 
          add_new_states(transitions, acc, counter)
        end)
    |> Enum.concat(new_states)
    |> Map.new
  end

 def transform_transitions2chomsky(grammar, new_states) do
    grammar
    |>  Enum.map(fn {state, transitions} -> 
          {state, update_transitions(transitions, new_states)}
        end)
    |> Map.new
  end

  def add_new_states2grammar(grammar, new_states) do
    new_states
    |>  Enum.reduce(grammar, fn {transition, state}, acc -> 
          Map.put_new(acc, state, [transition])
        end)
    |> Map.new
  end

  def convert_transitions(grammar, _, _, true) do
    grammar
  end

  def convert_transitions(grammar, counter, new_states, false) do
    new_states = get_new_states(grammar, counter, new_states)

    grammar = grammar
    |> transform_transitions2chomsky(new_states)
    |> add_new_states2grammar(new_states)

    convert_transitions(grammar, counter, new_states, Enum.all?(grammar, &is_in_chomsky(&1)))
  end

  def to_chomsky(grammar) do
    counter = get_counter()
    grammar
    |> init_grammar()
    |> convert_transitions(counter, [], false)
    |> IO.inspect
  end
end

# %{:S => ["bA", "BC"], :A => ["a", "aS", "bAaAb"], :B => ["A", "bS", "aAa"], :C => ["", "AB"], :D => ["AB"]}
%{:S => ["dB", "AB"], :A => ["d", "dS", "aAaAb", ""], :B => ["a", "aS", "A"], :D => ["Aba"]}

|> Chomsky.to_chomsky()

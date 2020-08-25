defmodule Artemis.Helpers do
  @doc """
  Generate a random string
  """
  def random_string(string_length) do
    string_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, string_length)
  end

  @doc """
  Detect if value is truthy
  """
  def present?(nil), do: false
  def present?(""), do: false
  def present?(0), do: false
  def present?(_value), do: true

  @doc """
  Detect if a key's value is truthy
  """
  def present?(entry, key) when is_list(entry) do
    entry
    |> Keyword.get(key)
    |> present?
  end

  def present?(entry, key) when is_map(entry) do
    entry
    |> Map.get(key)
    |> present?
  end

  @doc """
  Detect if the first map is a subset of the second

      Input: %{one: 1}, %{one: 1, two: 2}
      Output: true
  """
  def subset?(first, %_{} = second), do: subset?(first, Map.from_struct(second))

  def subset?(first, second), do: Enum.all?(first, &(&1 in second))

  @doc """
  Renames a key in a map. If the key does not exist, original map is returned.
  """
  def rename_key(map, current_key, new_key) when is_map(map) do
    case Map.has_key?(map, current_key) do
      true -> Map.put(map, new_key, Map.get(map, current_key))
      false -> map
    end
  end

  @doc """
  Takes the result of a `group_by` statement, applying the passed function
  to each grouping's values. Returns a map.
  """
  def reduce_group_by(grouped_data, function) do
    Enum.reduce(grouped_data, %{}, fn {key, values}, acc ->
      Map.put(acc, key, function.(values))
    end)
  end

  @doc """
  Takes a collection of values and an attribute and returns the max value for that attribute.
  """
  def max_by_attribute(values, attribute, fun \\ fn x -> x end)
  def max_by_attribute([], _, _), do: nil

  def max_by_attribute(values, attribute, fun) do
    values
    |> Enum.max_by(&fun.(Map.get(&1, attribute)))
    |> Map.get(attribute)
  end

  @doc """
  Takes a collection of values and an attribute and returns the min value for that attribute.
  """
  def min_by_attribute(values, attribute, fun \\ fn x -> x end)
  def min_by_attribute([], _, _), do: []

  def min_by_attribute(values, attribute, fun) do
    values
    |> Enum.min_by(&fun.(Map.get(&1, attribute)))
    |> Map.get(attribute)
  end

  @doc """
  Returns a titlecased string. Example:

      Input: hello world
      Ouput: Hello World
  """
  def titlecase(value) when is_nil(value), do: ""

  def titlecase(value) do
    value
    |> String.split(" ")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join(" ")
  end

  @doc """
  Returns a snakecase string. Example:

      Input: Artemis.HelloWorld
      Ouput: "hello_world"
  """
  def snakecase(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> snakecase()
  end

  def snakecase(value) when is_bitstring(value) do
    Macro.underscore(value)
  end

  @doc """
  Returns a dashcase string. Example:

      Input: Artemis.HelloWorld
      Ouput: "hello-world"
  """
  def dashcase(value) do
    value
    |> snakecase()
    |> String.replace("_", "-")
  end

  @doc """
  Returns a modulecase string. Example:

      Input: "hello_world"
      Ouput: HelloWorld
  """
  def modulecase(value) do
    value
    |> snakecase()
    |> String.split("_")
    |> Enum.map(&String.capitalize(&1))
    |> Enum.join("")
  end

  @doc """
  Returns a simplified module name. Example:

      Input: Elixir.MyApp.MyModule
      Ouput: MyModule
  """
  def module_name(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> List.last()
    |> String.to_atom()
  end

  @doc """
  Arbitrary addition using Decimal and returning a Float
  """
  def decimal_add(first, second) when is_float(first), do: decimal_add(Decimal.from_float(first), second)
  def decimal_add(first, second) when is_float(second), do: decimal_add(first, Decimal.from_float(second))

  def decimal_add(first, second) do
    first
    |> Decimal.add(second)
    |> Decimal.to_float()
  end

  @doc """
  Converts an atom or string to an integer
  """
  def to_integer(value) when is_float(value), do: Kernel.trunc(value)
  def to_integer(value) when is_atom(value), do: to_integer(Atom.to_string(value))
  def to_integer(value) when is_bitstring(value), do: String.to_integer(value)
  def to_integer(value), do: value

  @doc """
  Converts an atom or integer to a bitstring
  """
  def to_string(value) when is_nil(value), do: ""
  def to_string(value) when is_atom(value), do: Atom.to_string(value)
  def to_string(value) when is_integer(value), do: Integer.to_string(value)
  def to_string(value) when is_float(value), do: Float.to_string(value)
  def to_string(value), do: value

  @doc """
  Converts a nested list to a nested map. Example:

  Input: [[:one, :two, 3], [:one, :three, 3]]
  Output: %{one: %{two: 2, three: 3}}
  """
  def nested_list_to_map(nested_list) do
    Enum.reduce(nested_list, %{}, fn item, acc ->
      deep_merge(acc, list_to_map(item))
    end)
  end

  @doc """
  Converts a simple list to a nested map. Example:

  Input: [:one, :two, 3]
  Output: %{one: %{two: 2}}
  """
  def list_to_map([head | tail]) when tail == [], do: head
  def list_to_map([head | tail]) when is_integer(head), do: list_to_map([Integer.to_string(head) | tail])
  def list_to_map([head | tail]), do: Map.put(%{}, head, list_to_map(tail))

  @doc """
  Deep merges two maps

  See: https://stackoverflow.com/questions/38864001/elixir-how-to-deep-merge-maps/38865647#38865647
  """
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  defp deep_resolve(_key, left = %{}, right = %{}) do
    # Key exists in both maps, and both values are maps as well.
    # These can be merged recursively.
    deep_merge(left, right)
  end

  defp deep_resolve(_key, _left, right) do
    # Key exists in both maps, but at least one of the values is
    # NOT a map. We fall back to standard merge behavior, preferring
    # the value on the right.
    right
  end

  # Tasks

  @doc """
  Runs a list of tasks in parallel. Example:

    async_await_many([&task_one/0, &task_two/0])

  Returns:

    ["task_one/0 result", "task_two/0 result"]

  ## Maps

  Also accepts a map:

    async_await_many(%{
      one: &task_one/0,
      two: &task_two/0
    })

  Returns:

    %{
      one: "task_one/0 result",
      two: "task_two/0 result"
    }

  """
  def async_await_many(tasks) when is_list(tasks) do
    tasks
    |> Enum.map(&Task.async(&1))
    |> Enum.map(&Task.await/1)
  end

  def async_await_many(tasks) when is_map(tasks) do
    values =
      tasks
      |> Map.values()
      |> async_await_many

    tasks
    |> Map.keys()
    |> Enum.zip(values)
    |> Enum.into(%{})
  end

  @doc """
  Convert a list of bitstrings to atoms. If passed the `allow` option with a
  list of atoms, only converted values matching that list will be returned.

  Options:

    `:allow` -> List of allowed atoms. When passed, any converted values not in the list will be removed

  Example:

    list_to_atoms([:hello, "world"])

  Returns:

    [:hello, :world]

  """
  def list_to_atoms(values, options \\ [])

  def list_to_atoms(values, options) when is_list(values) do
    allow = Keyword.get(options, :allow)

    convert_values_to_atoms(values, allow)
  end

  def list_to_atoms(value, options) do
    [value]
    |> list_to_atoms(options)
    |> List.first()
  end

  defp convert_values_to_atoms(values, allow) do
    values
    |> Enum.reduce([], fn value, acc ->
      case convert_value_to_atom(value, allow) do
        nil -> acc
        value -> [value | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp convert_value_to_atom(value, allow) when is_atom(value) and is_list(allow) do
    case Enum.member?(allow, value) do
      true -> value
      false -> nil
    end
  end

  defp convert_value_to_atom(value, allow) when is_bitstring(value) and is_list(allow) do
    allow_strings = Enum.map(allow, &Artemis.Helpers.to_string(&1))

    case Enum.member?(allow_strings, value) do
      true -> String.to_atom(value)
      false -> nil
    end
  end

  defp convert_value_to_atom(value, _allow) when is_atom(value), do: value

  defp convert_value_to_atom(value, _allow) when is_bitstring(value), do: String.to_atom(value)

  defp convert_value_to_atom(_value, _allow), do: nil

  @doc """
  Recursively converts the keys of a map into an atom.

  Options:

    `:whitelist` -> List of strings to convert to atoms. When passed, only strings in whitelist will be converted.

  Example:

    keys_to_atoms(%{"nested" => %{"example" => "value"}})

  Returns:

    %{nested: %{example: "value"}}
  """
  def keys_to_atoms(map, options \\ [])
  def keys_to_atoms(%_{} = struct, _options), do: struct

  def keys_to_atoms(map, options) when is_map(map) do
    for {key, value} <- map, into: %{} do
      key =
        case is_bitstring(key) do
          false ->
            key

          true ->
            case Keyword.get(options, :whitelist) do
              nil ->
                String.to_atom(key)

              whitelist ->
                case Enum.member?(whitelist, key) do
                  false -> key
                  true -> String.to_atom(key)
                end
            end
        end

      {key, keys_to_atoms(value, options)}
    end
  end

  def keys_to_atoms(value, _), do: value

  @doc """
  Recursively converts the keys of a map into a string.

  Example:

    keys_to_strings(%{nested: %{example: "value"}})

  Returns:

    %{"nested" => %{"example" => "value"}}

  """
  def keys_to_strings(map, options \\ [])
  def keys_to_strings(%_{} = struct, _options), do: struct

  def keys_to_strings(map, options) when is_map(map) do
    for {key, value} <- map, into: %{} do
      key =
        case is_atom(key) do
          false -> key
          true -> Atom.to_string(key)
        end

      {key, keys_to_strings(value, options)}
    end
  end

  def keys_to_strings(value, _), do: value

  @doc """
  Serialize process id (pid) number to string
  """
  def serialize_pid(pid) when is_pid(pid) do
    pid
    |> :erlang.pid_to_list()
    |> :erlang.list_to_binary()
  end

  @doc """
  Deserialize process id (pid) string to pid
  """
  def deserialize_pid("#PID" <> string), do: deserialize_pid(string)

  def deserialize_pid(string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end

  @doc """
  Get a map or struct value by either atom or string key

  Example:

    my_struct = %MyStruct{ hello: "world" }

    indifferent_get(my_struct, "hello")

  Returns:

    "world"

  """
  def indifferent_get(%_{} = struct, key) do
    struct
    |> Map.from_struct()
    |> indifferent_get(key)
  end

  def indifferent_get(map, key) when is_atom(key), do: indifferent_get(map, Atom.to_string(key))

  def indifferent_get(map, key) when is_bitstring(key) do
    map
    |> keys_to_strings()
    |> Map.get(key)
  end

  @doc """
  Recursive version of `Map.delete/2`. Deletes all instances of the given key.

  Adds support for nested values:

  Example:

    map = %{
      hello: "world",
      nested: %{example: "value", hello: "world"}
    }

    deep_delete(map, :hello)

  Returns:

    %{
      nested: %{example: "value"}
    }

  """
  def deep_delete(data, delete_key) when is_map(data) do
    data
    |> Map.delete(delete_key)
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      Map.put(acc, key, deep_delete(value, delete_key))
    end)
  end

  def deep_delete(data, _), do: data

  @doc """
  Recursive version of `Map.drop/2`. Adds support for nested values:

  Example:

    map = %{
      simple: "simple",
      nested: %{example: "value", other: "value"}
    }

    deep_drop(map, [nested: [:example]])

  Returns:

    map = %{
      simple: "simple",
      nested: %{other: "value"}
    }

  """
  def deep_drop(map, keys) when is_map(map) do
    {nested_keys, simple_keys} = Enum.split_with(keys, &is_tuple/1)

    simple = Map.drop(map, simple_keys)

    nested =
      Enum.reduce(nested_keys, %{}, fn {key, keys}, acc ->
        value =
          map
          |> Map.get(key)
          |> deep_drop(keys)

        Map.put(acc, key, value)
      end)

    Map.merge(simple, nested)
  end

  @doc """
  Recursively drops all instances of the given value.

  Example:

    map = %{
      hello: "world",
      nested: %{example: "value", hello: "world"}
    }

    deep_drop_by_value(map, "world")

  Returns:

    %{
      nested: %{example: "value"}
    }

  """
  def deep_drop_by_value(data, match) when is_map(data) do
    matcher = get_deep_drop_by_value_match_function(match)

    Enum.reduce(data, %{}, fn {key, value}, acc ->
      case matcher.(value) do
        true -> acc
        false -> Map.put(acc, key, deep_drop_by_value(value, match))
      end
    end)
  end

  def deep_drop_by_value(data, _), do: data

  defp get_deep_drop_by_value_match_function(match) when is_function(match), do: match
  defp get_deep_drop_by_value_match_function(match), do: &(&1 == match)

  @doc """
  Recursive version of `Map.get/2`. Adds support for nested values:

  Example:

    map = %{
      simple: "simple",
      nested: %{example: "value", other: "value"}
    }

    deep_get(map, [:nested, :example])

  Returns:

    "value"

  """
  def deep_get(data, keys, default \\ nil)

  def deep_get(data, [current_key | remaining_keys], default) when is_map(data) do
    value = Map.get(data, current_key)

    case remaining_keys do
      [] -> value
      _ -> deep_get(value, remaining_keys, default)
    end
  end

  def deep_get(_data, _, default), do: default

  @doc """
  A version of `Kernel.put_in/3` with added support for creating keys that
  don't exist.

  Example:

    map = %{
      simple: "simple"
    }

    deep_put(map, [:nested, :example], "value")

  Returns:

    map = %{
      simple: "simple",
      nested: %{example: "value"}
    }

  See: https://elixirforum.com/t/put-update-deep-inside-nested-maps-and-auto-create-intermediate-keys/7993/8
  """
  def deep_put(map, keys, value) do
    put_in(map, Enum.map(keys, &Access.key(&1, %{})), value)
  end

  @doc """
  Recursive version of `Map.size/2`. Returns the total number of keys in
  Maps and Keyword Lists.

  All other values, including Lists, return 0.

  Example:

    map = %{
      hello: "world",
      nested: %{example: "value", hello: "world"},
      keywords: [one: 1, two: 2],
      list: [1, 2, 3]
    }

    deep_size(map, [:nested, :example])

  Returns:

    8

  """
  def deep_size(data) when is_map(data) do
    Enum.reduce(data, 0, fn {_, value}, acc ->
      1 + deep_size(value) + acc
    end)
  end

  def deep_size(data) when is_list(data) do
    case Keyword.keyword?(data) do
      false ->
        0

      true ->
        Enum.reduce(data, 0, fn {_, value}, acc ->
          1 + deep_size(value) + acc
        end)
    end
  end

  def deep_size(_), do: 0

  @doc """
  Recursive version of `Map.take/2`. Adds support for nested values:

  Example:

    map = %{
      simple: "simple",
      nested: %{example: "value", other: "value"}
    }

    deep_take(map, [:simple, nested: [:example]])

  Returns:

    map = %{
      simple: "simple",
      nested: %{example: "value"}
    }

  """
  def deep_take(map, keys) when is_map(map) do
    {nested_keys, simple_keys} = Enum.split_with(keys, &is_tuple/1)

    simple = Map.take(map, simple_keys)

    nested =
      Enum.reduce(nested_keys, %{}, fn {key, keys}, acc ->
        value =
          map
          |> Map.get(key)
          |> deep_take(keys)

        Map.put(acc, key, value)
      end)

    Map.merge(simple, nested)
  end

  @doc """
  Generate a slug value from bitstring
  """
  def generate_slug(value, limit \\ 80)
  def generate_slug(nil, _limit), do: nil

  def generate_slug(value, limit) do
    slug = Slugger.slugify_downcase(value)

    case is_number(limit) do
      true -> Slugger.truncate_slug(slug, limit)
      false -> slug
    end
  end

  @doc """
  Print entire value without truncation
  """
  def print(value) do
    IO.inspect(value, limit: :infinity, printable_limit: :infinity)
  end
end

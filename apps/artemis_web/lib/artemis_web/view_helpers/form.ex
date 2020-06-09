defmodule ArtemisWeb.ViewHelper.Form do
  use Phoenix.HTML

  import Phoenix.HTML.Tag

  @doc """
  Returns a blank option value
  """
  def blank_option(), do: [key: " ", value: ""]

  @doc """
  Returns option data for a select field

  Options

    :key_field -> atom. required if passing a list of maps or list of keyword lists
    :value_field -> atom. required if passing a list of maps or list of keyword lists
    :blank_option -> boolean. include a blank option

  Example:

    select_options(["one", "two"])

  Returns:

    [
      [key: "one", value: "one"],
      [key: "two", value: "two"]
    ]

  """
  def select_options(data, options \\ []) do
    results =
      data
      |> Enum.map(&select_option(&1, options))
      |> Enum.reject(&is_nil(Keyword.get(&1, :value)))

    case Keyword.get(options, :blank_option) do
      true -> [blank_option() | results]
      _ -> results
    end
  end

  defp select_option(entry, options) when is_map(entry) do
    key = Keyword.get(options, :field) || Keyword.fetch!(options, :key_field)
    value = Keyword.get(options, :field) || Keyword.fetch!(options, :value_field)

    [
      key: Map.get(entry, key),
      value: Map.get(entry, value)
    ]
  end

  defp select_option(entry, options) when is_list(entry) do
    key = Keyword.get(options, :key_field)
    value = Keyword.get(options, :value_field)

    [
      key: Keyword.get(entry, key),
      value: Keyword.get(entry, value)
    ]
  end

  defp select_option(entry, _options), do: [key: entry, value: entry]

  @doc """
  Returns the value of a changeset field
  """
  def get_changeset_value(changeset, field), do: Ecto.Changeset.get_field(changeset, field)

  @doc """
  Render a standalone select input form field. Note, if using `form_for`, use
  the Phoenix built-in function `select` instead.

  Expects `data` to be in the form of a list of keyword pairs:

      [
        [key: "Option One", value: "option-value-1"],
        [key: "Option Two", value: "option-value-2"]
      ]

  """
  def select_tag(data, options \\ []) do
    name = Keyword.get(options, :name)
    placeholder = Keyword.get(options, :placeholder)
    class = Keyword.get(options, :class, "enhanced")

    content_tag(:select, class: class, name: name, placeholder: placeholder) do
      Enum.map(data, fn [key: key, value: value] ->
        content_tag(:option, value: value) do
          key
        end
      end)
    end
  end

  @doc """
  From Phoenix.HTML.Form >= 2.14. Can be removed in the future once mix.exs
  version matches.
  """
  def deprecated_options_for_select(options, selected_values) do
    {:safe,
     escaped_options_for_select(
       options,
       selected_values |> List.wrap() |> Enum.map(&html_escape/1)
     )}
  end

  defp escaped_options_for_select(options, selected_values) do
    Enum.reduce(options, [], fn
      {option_key, option_value}, acc ->
        [acc | option(option_key, option_value, [], selected_values)]

      options, acc when is_list(options) ->
        {option_key, options} = Keyword.pop(options, :key)

        option_key ||
          raise ArgumentError,
                "expected :key key when building <option> from keyword list: #{inspect(options)}"

        {option_value, options} = Keyword.pop(options, :value)

        option_value ||
          raise ArgumentError,
                "expected :value key when building <option> from keyword list: #{inspect(options)}"

        [acc | option(option_key, option_value, options, selected_values)]

      option, acc ->
        [acc | option(option, option, [], selected_values)]
    end)
  end

  defp option(group_label, group_values, [], value)
       when is_list(group_values) or is_map(group_values) do
    section_options = escaped_options_for_select(group_values, value)
    {:safe, contents} = content_tag(:optgroup, {:safe, section_options}, label: group_label)
    contents
  end

  defp option(option_key, option_value, extra, value) do
    option_key = html_escape(option_key)
    option_value = html_escape(option_value)
    opts = [value: option_value, selected: option_value in value] ++ extra
    {:safe, contents} = content_tag(:option, option_key, opts)
    contents
  end
end

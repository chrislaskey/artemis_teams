defmodule Artemis.Helpers.DateTime do

  @doc """
  Sort an enumerable by Date

  Calling `sort` on Date structs will return unexpected results, since:

  > In Elixir structs are compared by their contents, in alphabetical order of the fields.
  > In this case the most significant would be the `day`, then `month` and `year`

  From: https://stackoverflow.com/questions/41655852/sorting-list-of-dates-in-elixir/41655967
  """
  def sort_by_date(dates) do
    Enum.sort_by(dates, & &1, &date_sorter/2)
  end

  defp date_sorter(date_1, date_2) do
    case Date.compare(date_1, date_2) do
      r when r == :lt or r == :eq -> true
      _ -> false
    end
  end

  @doc """
  Sort an enumerable by DateTime

  Calling `sort` on DateTime structs will return unexpected results, since:

  > In Elixir structs are compared by their contents, in alphabetical order of the fields.
  > In this case the most significant would be the `day`, then `month` and `year`

  From: https://stackoverflow.com/questions/41655852/sorting-list-of-dates-in-elixir/41655967
  """
  def sort_by_date_time(date_times) do
    Enum.sort_by(date_times, & &1, &date_time_sorter/2)
  end

  defp date_time_sorter(date_time_1, date_time_2) do
    case DateTime.compare(date_time_1, date_time_2) do
      r when r == :lt or r == :eq -> true
      _ -> false
    end
  end

  @doc """
  Adds microseconds to an existing DateTime:

      #DateTime<2020-01-03 19:25:05Z>
      #DateTime<2020-01-03 19:25:05.000000Z>
  
  Also works on NaiveDateTimes:

      ~N[2020-01-03 19:30:00]
      ~N[2020-01-03 19:30:00.000000]
  
  """
  def add_microseconds(date_time, value \\ 0, precision \\ 6) do
    %{date_time | microsecond: {value, precision}}
  end
end

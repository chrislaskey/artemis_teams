defmodule ArtemisWeb.EventView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteEventTemplate.call_many(&1, &2),
        authorize: &has?(&1, "event-templates:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete EventTemplates"
      }
    ]
  end

  def allowed_bulk_actions(user) do
    Enum.reduce(available_bulk_actions(), [], fn entry, acc ->
      case entry.authorize.(user) do
        true -> [entry | acc]
        false -> acc
      end
    end)
  end

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Active", "active"},
      {"Instances", "instances"},
      {"Current Instance", "actions_current_instance"},
      {"Team", "team"},
      {"Title", "title"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "actions_current_event_instance" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_current_event_instance_column_html/2
      ],
      "active" => [
        label: fn _conn -> "Active" end,
        label_html: fn conn ->
          sortable_table_header(conn, "active", "Active")
        end,
        value: fn _conn, row -> row.active end
      ],
      "event_instances" => [
        label: fn _conn -> "Instances" end,
        label_html: fn conn ->
          sortable_table_header(conn, "title", "Instances")
        end,
        value: fn _conn, row -> row.title end,
        value_html: fn conn, row ->
          case has?(conn, "event-answers:list") do
            true -> link(row.title, to: Routes.event_instance_path(conn, :index, row))
            false -> row.title
          end
        end
      ],
      "team" => [
        label: fn _conn -> "Team" end,
        value: fn _conn, row -> row.team.name end,
        value_html: fn conn, row ->
          case has?(conn, "teams:show") do
            true -> link(row.team.name, to: Routes.team_path(conn, :show, row.team))
            false -> row.team.name
          end
        end
      ],
      "title" => [
        label: fn _conn -> "Title" end,
        label_html: fn conn ->
          sortable_table_header(conn, "title", "Title")
        end,
        value: fn _conn, row -> row.title end,
        value_html: fn conn, row ->
          case has?(conn, "event-templates:show") do
            true -> link(row.title, to: Routes.event_path(conn, :show, row))
            false -> row.title
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "event-templates:show"),
        link: link("Show", to: Routes.event_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "event-templates:update"),
        link: link("Edit", to: Routes.event_path(conn, :edit, row))
      ]
    ]

    content_tag(:div, class: "actions") do
      Enum.reduce(allowed_actions, [], fn action, acc ->
        case Keyword.get(action, :verify) do
          true -> [acc | Keyword.get(action, :link)]
          _ -> acc
        end
      end)
    end
  end

  defp data_table_actions_current_event_instance_column_html(conn, row) do
    today = Date.to_iso8601(Date.utc_today())

    allowed_actions = [
      [
        verify: has?(conn, "event-answers:update"),
        link:
          action("Update My Answers", to: Routes.event_instance_path(conn, :edit, row, today), color: "green", size: "mini")
      ],
      [
        verify: has?(conn, "event-answers:show"),
        link:
          action("View My Answers", to: Routes.event_instance_path(conn, :show, row, today), color: "blue", size: "mini")
      ]
    ]

    content_tag(:div, class: "actions-current-event-instance") do
      Enum.reduce(allowed_actions, [], fn action, acc ->
        case Keyword.get(action, :verify) do
          true -> [acc | Keyword.get(action, :link)]
          _ -> acc
        end
      end)
    end
  end

  # Helpers

  def render_projects(%{projects: projects}) when is_list(projects) do
    html =
      projects
      |> Enum.map(& &1.title)
      |> Enum.join("<br/>")

    raw(html)
  end

  def render_projects(_), do: nil

  def render_show_link(_conn, nil), do: nil

  def render_show_link(conn, record) do
    link(record.title, to: Routes.event_path(conn, :show, record))
  end
end

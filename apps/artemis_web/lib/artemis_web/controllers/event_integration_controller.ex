defmodule ArtemisWeb.EventIntegrationController do
  use ArtemisWeb, :controller

  alias Artemis.CreateEventIntegration
  alias Artemis.EventIntegration
  alias Artemis.DeleteEventIntegration
  alias Artemis.GetEventIntegration
  alias Artemis.GetEventTemplate
  alias Artemis.ListEventIntegrations
  alias Artemis.UpdateEventIntegration

  @preload [:event_template]

  def index(conn, %{"event_id" => event_template_id} = params) do
    authorize(conn, "event-integrations:list", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_integrations = get_event_integrations(params, user)

      assigns = [
        event_integrations: event_integrations,
        event_template: event_template
      ]

      authorize_team_admin(conn, event_template.team_id, fn ->
        render_format(conn, "index", assigns)
      end)
    end)
  end

  def new(conn, %{"event_id" => event_template_id}) do
    authorize(conn, "event-integrations:create", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_integration = %EventIntegration{event_template_id: event_template_id}
      changeset = EventIntegration.changeset(event_integration)

      assigns = [
        changeset: changeset,
        event_integration: event_integration,
        event_template: event_template
      ]

      authorize_team_admin(conn, event_template.team_id, fn ->
        render(conn, "new.html", assigns)
      end)
    end)
  end

  def create(conn, %{"event_integration" => params, "event_id" => event_template_id}) do
    authorize(conn, "event-integrations:create", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)

      authorize_team_admin(conn, event_template.team_id, fn ->
        case CreateEventIntegration.call(params, user) do
          {:ok, _event_integration} ->
            conn
            |> put_flash(:info, "Event Integration created successfully.")
            |> redirect(to: Routes.event_path(conn, :show, event_template_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            event_integration = %EventIntegration{event_template_id: event_template_id}

            assigns = [
              changeset: changeset,
              event_integration: event_integration,
              event_template: event_template
            ]

            render(conn, "new.html", assigns)
        end
      end)
    end)
  end

  def show(conn, %{"event_id" => event_template_id, "id" => id}) do
    authorize(conn, "event-integrations:show", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_integration = GetEventIntegration.call!(id, user, preload: @preload)

      assigns = [
        event_integration: event_integration,
        event_template: event_template
      ]

      authorize_team_admin(conn, event_template.team_id, fn ->
        render(conn, "show.html", assigns)
      end)
    end)
  end

  def edit(conn, %{"event_id" => event_template_id, "id" => id}) do
    authorize(conn, "event-integrations:update", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_integration = GetEventIntegration.call(id, user, preload: @preload)
      changeset = EventIntegration.changeset(event_integration)

      assigns = [
        changeset: changeset,
        event_integration: event_integration,
        event_template: event_template
      ]

      authorize_team_admin(conn, event_template.team_id, fn ->
        render(conn, "edit.html", assigns)
      end)
    end)
  end

  def update(conn, %{"id" => id, "event_id" => event_template_id, "event_integration" => params}) do
    authorize(conn, "event-integrations:update", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)

      authorize_team_admin(conn, event_template.team_id, fn ->
        case UpdateEventIntegration.call(id, params, user) do
          {:ok, _event_integration} ->
            conn
            |> put_flash(:info, "Event Integration updated successfully.")
            |> redirect(to: Routes.event_path(conn, :show, event_template_id))

          {:error, %Ecto.Changeset{} = changeset} ->
            event_integration = GetEventIntegration.call(id, user, preload: @preload)

            assigns = [
              changeset: changeset,
              event_integration: event_integration,
              event_template: event_template
            ]

            render(conn, "edit.html", assigns)
        end
      end)
    end)
  end

  def delete(conn, %{"event_id" => event_template_id, "id" => id} = params) do
    authorize(conn, "event-integrations:delete", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)

      authorize_team_admin(conn, event_template.team_id, fn ->
        {:ok, _event_integration} = DeleteEventIntegration.call(id, params, user)

        conn
        |> put_flash(:info, "Event Integration deleted successfully.")
        |> redirect(to: Routes.event_path(conn, :show, event_template_id))
      end)
    end)
  end

  # Helpers

  defp get_event_integrations(params, user) do
    required_params = %{
      filters: %{
        event_template_id: Map.fetch!(params, "event_id")
      },
      paginate: true,
      preload: @preload
    }

    event_integration_params = Map.merge(params, Artemis.Helpers.keys_to_strings(required_params))

    ListEventIntegrations.call(event_integration_params, user)
  end
end

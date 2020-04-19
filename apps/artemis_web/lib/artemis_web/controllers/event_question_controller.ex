defmodule ArtemisWeb.EventQuestionController do
  use ArtemisWeb, :controller

  alias Artemis.CreateEventQuestion
  alias Artemis.EventQuestion
  alias Artemis.DeleteEventQuestion
  alias Artemis.GetEventQuestion
  alias Artemis.GetEventTemplate
  alias Artemis.UpdateEventQuestion

  @preload [:event_template]

  def index(conn, %{"event_id" => event_template_id}) do
    redirect(conn, to: Routes.event_path(conn, :show, event_template_id))
  end

  def new(conn, %{"event_id" => event_template_id}) do
    authorize(conn, "event-questions:create", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_question = %EventQuestion{event_template_id: event_template_id}
      changeset = EventQuestion.changeset(event_question)

      assigns = [
        changeset: changeset,
        event_question: event_question,
        event_template: event_template
      ]

      render(conn, "new.html", assigns)
    end)
  end

  def create(conn, %{"event_question" => params, "event_id" => event_template_id}) do
    authorize(conn, "event-questions:create", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)

      case CreateEventQuestion.call(params, user) do
        {:ok, _event_question} ->
          conn
          |> put_flash(:info, "Event Question created successfully.")
          |> redirect(to: Routes.event_path(conn, :show, event_template_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_question = %EventQuestion{event_template_id: event_template_id}

          assigns = [
            changeset: changeset,
            event_question: event_question,
            event_template: event_template
          ]

          render(conn, "new.html", assigns)
      end
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "event-questions:show", fn ->
      event_question = GetEventQuestion.call!(id, current_user(conn), preload: @preload)

      render(conn, "show.html", event_question: event_question)
    end)
  end

  def edit(conn, %{"event_id" => event_template_id, "id" => id}) do
    authorize(conn, "event-questions:update", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)
      event_question = GetEventQuestion.call(id, user, preload: @preload)
      changeset = EventQuestion.changeset(event_question)

      assigns = [
        changeset: changeset,
        event_question: event_question,
        event_template: event_template
      ]

      render(conn, "edit.html", assigns)
    end)
  end

  def update(conn, %{"id" => id, "event_id" => event_template_id, "event_question" => params}) do
    authorize(conn, "event-questions:update", fn ->
      user = current_user(conn)
      event_template = GetEventTemplate.call!(event_template_id, user)

      case UpdateEventQuestion.call(id, params, user) do
        {:ok, _event_question} ->
          conn
          |> put_flash(:info, "EventQuestion updated successfully.")
          |> redirect(to: Routes.event_path(conn, :show, event_template_id))

        {:error, %Ecto.Changeset{} = changeset} ->
          event_question = GetEventQuestion.call(id, user, preload: @preload)

          assigns = [
            changeset: changeset,
            event_question: event_question,
            event_template: event_template
          ]

          render(conn, "edit.html", assigns)
      end
    end)
  end

  def delete(conn, %{"event_id" => event_template_id, "id" => id} = params) do
    authorize(conn, "event-questions:delete", fn ->
      {:ok, _event_question} = DeleteEventQuestion.call(id, params, current_user(conn))

      conn
      |> put_flash(:info, "Event Question deleted successfully.")
      |> redirect(to: Routes.event_path(conn, :show, event_template_id))
    end)
  end
end

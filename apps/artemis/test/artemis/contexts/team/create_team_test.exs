defmodule Artemis.CreateTeamTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateTeam

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn ->
        CreateTeam.call!(%{}, Mock.system_user())
      end
    end

    test "creates a team when passed valid params" do
      params = params_for(:team)

      team = CreateTeam.call!(params, Mock.system_user())

      assert team.name == params.name
    end

    test "creates slug from name if not passed as a param" do
      params = params_for(:team, slug: "passed-slug")

      team = CreateTeam.call!(params, Mock.system_user())

      assert team.slug == "passed-slug"

      # When slug is not passed

      params = params_for(:team, name: "Passed Name", slug: nil)

      team = CreateTeam.call!(params, Mock.system_user())

      assert team.slug == "passed-name"
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, changeset} = CreateTeam.call(%{}, Mock.system_user())

      assert errors_on(changeset).slug == ["can't be blank"]
    end

    test "creates a team when passed valid params" do
      params = params_for(:team)

      {:ok, team} = CreateTeam.call(params, Mock.system_user())

      assert team.name == params.name
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, team} = CreateTeam.call(params_for(:team), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "team:created",
        payload: %{
          data: ^team
        }
      }
    end
  end
end

defmodule ArtemisWeb.GithubIssueController do
  use ArtemisWeb, :controller

  alias Artemis.ListGithubIssues

  @default_columns [
    "number",
    "assignee",
    "zenhub_pipeline",
    "zenhub_epic",
    "title",
    "labels",
    "comments",
    "milestone",
    "zenhub_estimate",
    "created_at"
  ]

  def index(conn, params) do
    authorize(conn, "github-issues:list", fn ->
      user = current_user(conn)
      github_repositories = get_github_repositories()
      github_issues_all = ListGithubIssues.call(user)
      github_issues_filtered = ListGithubIssues.call(params, user)

      assigns = [
        default_columns: @default_columns,
        github_issues_all: github_issues_all,
        github_issues_filtered: github_issues_filtered,
        github_repositories: github_repositories
      ]

      render_format(conn, "index", assigns)
    end)
  end

  def show(conn, %{"id" => id, "organization" => organization, "repository" => repository}) do
    authorize(conn, "github-issues:show", fn ->
      user = current_user(conn)
      github_issue = Artemis.GetGithubIssue.call(organization, repository, id, user)
      github_issues = ListGithubIssues.call(user)

      assigns = [
        default_columns: @default_columns,
        github_issue: github_issue,
        github_issues: github_issues
      ]

      render(conn, "show.html", assigns)
    end)
  end

  # Helpers

  defp get_github_repositories() do
    :artemis
    |> Application.fetch_env!(:github)
    |> Keyword.fetch!(:repositories)
  end
end

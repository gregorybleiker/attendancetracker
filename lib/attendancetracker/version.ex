defmodule AttendanceTracker.Version do
  @moduledoc """
  The running application version together with the git revision it was built
  from, so a deployment can be identified from the admin area without shell
  access.

  The revision is resolved at build time: the `GIT_SHA` environment variable
  (passed as a Docker build arg by the publish workflow) takes precedence,
  otherwise the local git repository is consulted during development. When
  neither is available it falls back to `"unknown"`.
  """

  @git_hash (try do
               case System.get_env("GIT_SHA") do
                 sha when is_binary(sha) and sha != "" ->
                   String.slice(sha, 0, 12)

                 _ ->
                   case System.cmd("git", ["rev-parse", "--short", "HEAD"],
                          stderr_to_stdout: true
                        ) do
                     {hash, 0} -> String.trim(hash)
                     _ -> "unknown"
                   end
               end
             rescue
               _ -> "unknown"
             end)

  @doc "The semantic application version, e.g. `\"0.1.0\"`."
  def version do
    case Application.spec(:attendancetracker, :vsn) do
      nil -> "dev"
      vsn -> to_string(vsn)
    end
  end

  @doc "The short git revision the build was made from, or `\"unknown\"`."
  def git_hash, do: @git_hash

  @doc "The version and revision combined, e.g. `\"0.1.0+g1a2b3c4\"`."
  def full, do: "#{version()}+#{@git_hash}"
end

defmodule AttendanceTrackerWeb.Locales do
  @moduledoc """
  The languages the app ships with.
  """

  @locales ~w(en de)
  @default "en"

  def all, do: @locales
  def default, do: @default
  def valid?(locale), do: locale in @locales
end

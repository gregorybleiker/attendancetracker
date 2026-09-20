# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs

alias AttendanceTracker.Tracker

for name <- [
      "Alex Rivera",
      "Sam Chen",
      "Jordan Smith",
      "Casey Novak",
      "Robin Patel",
      "Jamie Okafor"
    ] do
  {:ok, _} = Tracker.create_participant(%{name: name, active: true})
end

# Weekly training schedule: 1 = Monday, 7 = Sunday
{:ok, _} =
  Tracker.create_training_day(%{
    name: "Kids Judo Monday",
    weekday: 1,
    starts_at: ~T[19:00:00],
    ends_at: ~T[21:30:00]
  })

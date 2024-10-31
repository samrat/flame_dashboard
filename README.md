# FLAMEDashboard

[FLAME](https://github.com/phoenixframework/flame) statistics visualization for [Phoenix LiveDashboard](https://github.com/phoenixframework/phoenix_live_dashboard).

<video src='https://github.com/user-attachments/assets/ac1bb6e8-0cd3-470e-b456-a74a1060e21b' alt='FLAME LiveDashboard'></video>

## Installation

1. Enable `LiveDashboard` by following these [instructions](https://github.com/phoenixframework/phoenix_live_dashboard?tab=readme-ov-file#installation).
   In most cases you can skip this step as `Phoenix` comes with `LiveDashboard` enabled by default.

2. Add `:flame_dashboard` to your list of dependencies

```elixir
def deps do
  [
    {:flame_dashboard, git: "https://github.com/samrat/flame_dashboard"}
  ]
end
```

3. Add `FLAMEDashboard` as an additional `LiveDashboard` page, listing your FLAME pools:

```elixir
live_dashboard "/dashboard",
  additional_pages: [flame: {FLAMEDashboard, [MyApp.FfmpegRunner, MyApp.MLRunner]}]
```

That's it!
`FLAMEDashboard` will track your FLAME runners and visualize their statistics.

## License

MIT License. © [Octocut](https://octocut.com), Samrat Man Singh
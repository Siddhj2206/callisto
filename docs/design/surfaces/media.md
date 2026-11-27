# Surface: MediaBar (pill + popover)

Board: `MediaBar.dc.html` (also `Lock` media pill, `Main` QS media card).
Replaces: nothing. There is no Mpris code in the shell today.

## Component tree

```
(inside Bar CenterGroup)
MediaPill                      pattern T20, exists only while a player is active
  WaveShape(size disc 40, art clip)            album art (image masked by wave)
  Column: AppText(labelM, title, maxWidth Size.media.titleMax) / AppText(caption, artist, med)
  LevelMeter                                   playing only
  Row: IconButton(prev, hover only) IconButton(play|pause, filled) IconButton(next, hover only)

MediaPopover                   Popover(panel.m, width Size.panel.media)
  PlayerCard{variant: popover}
    WaveShape art 112 (source in `caption` low)
    AppText(titleDisplay) title, AppText(bodyM, med) "artist - album", AppText(caption, low) "Source"
    ProgressBar(wavy) + AppText(monoS) elapsed/total
    Row: IconButton(shuffle, 70 %) IconButton(prev) IconButton(play, wave 64) IconButton(next) IconButton(repeat, 70 %)
    Row: Icon(volume) + Slider(standard)
  PlayerPicker (when > 1 player): ListGroup of ListRow(density: roomy 68, avatar art, title, "artist - source", play/pause IconButton), selected = primary row
```

## Layout rules
- The pill is a third `Island` in the centre; width = content + padding; title
  max 200 px, ellipsis; prev/next appear on hover by widening (not by overlay).
- Popover width pref 440, min 340; art scales 112 -> 80 below min; progress bar
  fills; transport buttons never wrap (scales to icon sizes).
- Player picker rows: first/last radii `28 28 8 8` / `8 8 28 28`, middle 8
  (these are connected-group radii at row scale: `ListGroup` `corner: "connected"`).

## States
nothing playing (no pill), playing (meter), hover (widen), paused (art dimmed,
opacity .75, no meter, fades out after `mediaPauseFade` 2 min, returns on
play), popover open, several players (most recent owns the pill), player closes
(pill removed).

## Motion
`pillMorph` (widen, appear/disappear), `popoverOpen/Close`, meter = level-driven
(`loop.meter`), `colorShift`. Reduce motion: pill swaps controls without widen,
meter static.

## Behaviour
- Never forces the bar open (autohide stays hidden; media keys show the OSD
  `track` variant instead).
- Click pill -> popover; click picker row -> sets the pill's player.
- Keyboard in popover: Space play/pause, Left/Right prev/next, Up/Down volume,
  Esc closes.

## Services (new)
`MediaService` over `Quickshell.Services.Mpris`: `players`, `active` (most
recently played), `title/artist/album/artUrl/position/length/playbackState/
shuffle/loop/volume`, actions. Position needs a 1 s `SystemClock`-driven tick
only while the popover is visible (no polling elsewhere).

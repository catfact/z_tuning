# bugs

- when loading a tuning from `.lua`, the resulting pseudo-octave is always ==2, even if the tuning set contains ratios >2.
  ~~- at minimum, should respect the `pseudo_octave` field if defined in the table returned by the tuning file.~~
  - some automatic behavior would be useful: either the next power of 2 above the highest ratio, or the next integer, or ...?

# enhancements

- `tuning::note_freq_from_table` could use some optimization

# features

- expose more useful things in mod API

- create parameters automatically? API call to add parameters?

- display more stuff about selected tuning in the mod screen:
  - basic stuff like number of degrees, pseudo-octave
  - fancy stuff like visualizing deviation from EDo12
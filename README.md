# z_tuning

tuning mod for monome norns

- use the normal install process for norns scripts: `;install https://github.com/catfact/z_tuning`

- with the mod enabled, tuning is applied globally, to all scripts which use the `musicutil.note_num_to_freq` library function and its variants. 
  - **caveat**: unfortunately, not all scripts use this library; many hardcode their own MIDI->hz conversions and are not open to tuning adjustments.
  - **caveat**: `ratio_to_note_num` remains unchanged because it is mathematically unfeasible in the general case.)

- new tunings can be specified either:
  - using the [Scala format](https://www.huygens-fokker.org/scala/scl_format.html) (extension `.scl`),
   - or as Lua files (`.lua`). 

- `.lua` files defining scales can contain any lua code, but should return a table containing a field called `ratios` or a field called `cents`, either of which should be another table.

- tuning data files should be placed in `~/dust/data/z.tuning/lib/data`. this location will be populated with some "factory" files when the mod is first run.

## mod menu usage

- the mod menu exposes:
  - tuning selection,
  - specification of root note as MIDI number,
  - independent specification of base frequency
  - hold down K3 to couple base freq to root note; that is:
    - whenever the root note changes, update the base frequency such that the tuning would not change under 12tet

## API usage

return the current state of the mod, a table containing:
- tuning selection (ID string)
- root note number
- base frequency
`api.get_tuning_state()`

return the entire collection of tuning data
`api.get_tuning_data()`

save/recall the current tuning state
`api.save_state()`
`api.recall_state()`

set the root note,  independent odf base frequency
`api.set_root_note_keep_freq(note)`

change the root note, moving the base frequency
`api.set_root_note_move_freq(note)`

set the current tuning, given numerical index
`api.select_tuning_by_index(idx)`

set the current tuning, given ID string
`api.select_tuning_by_id(id)`

----

- see [CHANGELIST.md](CHANGELIST.md) for version information

- see [TODO.md](TODO.md) for a list of known issues / development roadmap.

- you may encounter bugs! please report them by visiting the [github issue list](https://github.com/catfact/z.tuning/issues). (feature requests are not needed.)

----

all original work is copyright ©ezra buchla and released into the public domain.

(note that this repo contains some `.scl` files downloaded from [huygens-fokker.org](https://www.huygens-fokker.org/docs/scalesdir.txt). the licensing terms for this material are unclear to me, but it is freely available and builds on the work of others (e.g. composers), and i hope that sharing it here is in keeping with the spirit of the author's intentions.)

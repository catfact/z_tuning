# z_tuning

tuning mod for monome norns

- use the normal install process for norns scripts: `;install https://github.com/catfact/z_tuning`

- with the mod enabled, tuning is applied globally, to all scripts which use the `musicutil.note_num_to_freq` library function and its variants. 
  - **caveat**: unfortunately, not all scripts use this library; many hardcode their own MIDI->hz conversions and are not open to tuning adjustments.
  - **caveat**: `ratio_to_note_num` remains unchanged because it is mathematically unfeasible in the general case.

- new tunings can be specified either:
  - using the [Scala format](https://www.huygens-fokker.org/scala/scl_format.html) (extension `.scl`),
  - or as Lua files (`.lua`). 

- `.lua` files defining scales can contain any lua code, but should return a table containing a field called `ratios` or a field called `cents`, either of which should be another table.

- tuning data files should be placed in `~/dust/data/z_tuning/tunings/`. this location will be populated with some "factory" files when the mod is first run.

- tuning state (selection, root note, and base frequency) is saved on a clean shutdown with SLEEP, and restored on boot. this state is global for all scripts (for now.)

## parameters

as of v0.2.0, `z_tuning` will add a group of parameters to the params list, following the script parameters. (this is awkward, but necessary to avoid corrupting existing script PSETs.)

these parameters can be saved and loaded as part of a PSET, thus allowing different scripts to be assigned different tuning configurations in a persistent manner.

the parameters are:

- `tuning`: select a tuning ID from the list created at startup

- `root note (transposing)`: set the root note, without updateing the root frequency; this effects a transposition unless `root frequency` is also adjusted to match.

- `root note (adjusting)`: set the root note, and adjust the root frequency such that the new frequency value is what it would have been with the old root frequency under 12TET. (this sounds complicated, but it is the most intuitive way to change temperament independently of tuning offset.)

- `root note (pivoting)`: set the root note, and set the root frequency such that the new root note has its frequency unchanged. this is an unusual feature: it provides an interesting way to perform JI transpositions, but it is not an reversible operation!

- `root frequency`: set the root frequency directly. this effects a transposition unless `root note` is also adjusted to match.

(note that setting any three paraneters for updating root note all cause each other's values to refresh, but only the acting parameter produces side effects.)

## mod menu usage

- the mod menu exposes:
  - tuning selection,
  - specification of root note as MIDI number,
  - independent specification of base frequency

by default, base freq is coupled to root note; that is:  whenever the root note changes, update the base frequency such that the tuning would not change under 12tet. hold down K3 to decouple them.

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

set the root note, as the `root note` parameter above
`api.set_root_note(note)`

set the root note, as with the `root note (adjusting)` parameter above
`api.set_root_note_adjusting(note)`

set the root note, as with the `root note (pivoting)` parameter above
`api.set_root_note_pivoting(note)`

set the current tuning, given numerical index
`api.select_tuning_by_index(idx)`

set the current tuning, given ID string
`api.select_tuning_by_id(id)`

add a new tuning table (e.g. constructed with `Tuning.new`)
(note that this will mess up existing tuning selection parameter values! this feature may be reconsidered.)
`api.add_tuning(id, t)`

get the deviation in semitones from 12EDO/A440, for a given note. 
(could be useful for implementing tuning by MIDI pitch bend.)
`api.get_bend_semitones(num)`

set an arbitrary global callback to execute whenever tuning functions are recalculated
`api.set_tuning_change_callback(function())`


clear the global callback (also happens automatically in post-cleanup hook)
`api.clear_tuning_change_callback()`


add a new tuning spec to the in-memory list
table should be e.g. constructed by `tuning.new({ratios={...}})` 
`api.add_tuning(name, table)`


------

- see [CHANGELIST.md](CHANGELIST.md) for version information

- see [TODO.md](TODO.md) for a list of known issues / development roadmap.

- you may encounter bugs! please report them by visiting the [github issue list](https://github.com/catfact/z.tuning/issues). (feature requests are not needed.)

------

all original work is copyright ©ezra buchla and released into the public domain.

(note that this repo contains some `.scl` files downloaded from [huygens-fokker.org](https://www.huygens-fokker.org/docs/scalesdir.txt). the licensing terms for this material are unclear to me, but it is freely available and builds on the work of others (e.g. composers), and i hope that sharing it here is in keeping with the spirit of the author's intentions.)
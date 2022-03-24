# thronegen

## design goals
* make thrones a bit fresh and a little more interesting, but not whacky
* viable in vanilla games to spice things up a little, without making the mod central to the game
* throne power level: good lvl2 thrones or slightly stronger
* balanced, not swingy

### throne powers to implement
* questionable value items - more likely usable for negative effects, but negative effects probably need to be capped to avoid being swingy
  * #res
  * #decunrest
  * #supply
* useful effects, hopefully easy in current framework
  * #heal - perhaps dubious because this is the lesser talked about way to unfeeblemind tarts and people might find this a bit wild
  * all of the bless bonuses
  * #recallgod
  * #domwar
* potential for negative effects to refund points
* potential for event-driven alternative effects, but this is harder to implement and much more difficult to communicate via ingame text
  * ... but turn 1 event info messages that can be screenshotted and shared amongst the players in the game, plus a reference comment section in the .dm could help that



### misc big plans
* throne themes -- how to solve?
  * Manual tagging themes onto everything...?
    * Maybe automate tagging based on what kind of words are used for sites/units/spells associated with these tags in vanilla/DE
  * Something more exotic like finding/making a word association corpus from vast quantities of text, and seeing if it can produce something sensible...?

### bugs
* underwater thrones can have recruitable non-aquatic mages

@tool
extends RefCounted
## Every word MapStack Lite's dock shows, in one place.

const TITLE := "MapStack"
const PITCH := "Pick a landscape, press Create, and a whole map appears in your 3D view: terrain, ground, water, trees, rocks, grass and daylight. Then you shape it from there."
const INSTALL := "Install MapStack Free"
const GET_FREE := "Get MapStack Free"
const TURN_ON := "Turn MapStack on"
const TRAILER := "Watch the trailer"
const PRO := "See what Pro adds"
const CONFIRM_TITLE := "Install MapStack Free?"
const CONFIRM_TAIL := "\n\nMapStack goes into addons/mapstack in this project. Its full license is addons/mapstack/LICENSE.txt."
const STATE_READY := "MapStack is installed and on. Open its dock to make your first landscape."
const STATE_OFF := "MapStack is installed but turned off."
const STATE_MISSING := "MapStack Free is not in this project yet."
const STATE_BROWSER := "Download MapStack Free from its page, then unzip it into this project."
const STATE_DOWNLOADING := "Downloading MapStack Free..."
const STATE_CHECKING := "Checking the download..."
const STATE_INSTALLING := "Installing..."
const FAIL_DOWNLOAD := "The download did not finish (%s). Try again, or get it from the page instead."
const FAIL_CHECK := "The download does not match MapStack Free %s, so nothing was installed. Try again, or get it from the page instead."

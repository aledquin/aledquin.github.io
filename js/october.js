/* October Horror — catalog data and page logic.
   Classic script with bundled data (no fetch, no ES modules) so the page also renders from file://.
   Each movie: stable id (slug of title + year, plus a country label where needed), title, year,
   calendarDay (1–31), editorial intensity (light / moderate / intense — not an age rating or score),
   genre tags, and a spoiler-free blurb (≤ 25 words). Optional imdbUrl / rottenTomatoesUrl must be
   verified exact film pages; without them, cards link to labeled IMDb / Rotten Tomatoes searches. */

var OCTOBER_HORROR_MOVIES = [
  {id: "sleepy-hollow-1999", title: "Sleepy Hollow", year: 1999, calendarDay: 1, intensity: "moderate", genres: ["gothic", "supernatural"], blurb: "A squeamish New York constable travels upriver to investigate a string of beheadings blamed on a legendary headless horseman."},
  {id: "crimson-peak-2015", title: "Crimson Peak", year: 2015, calendarDay: 1, intensity: "moderate", genres: ["gothic", "ghost"], blurb: "A young author marries into a crumbling English mansion where red clay seeps through the walls and the past refuses to stay buried."},
  {id: "the-woman-in-black-2012", title: "The Woman in Black", year: 2012, calendarDay: 1, intensity: "moderate", genres: ["ghost", "gothic"], blurb: "A widowed lawyer settles a dead client’s estate at a remote marsh house and glimpses a figure the villagers fear."},
  {id: "beetlejuice-1988", title: "Beetlejuice", year: 1988, calendarDay: 1, intensity: "light", genres: ["comedy", "ghost"], blurb: "A recently deceased couple hires a chaotic bio-exorcist to scare the new owners out of their beloved country home."},
  {id: "the-skeleton-key-2005", title: "The Skeleton Key", year: 2005, calendarDay: 1, intensity: "moderate", genres: ["supernatural", "thriller"], blurb: "A hospice nurse takes a job at a Louisiana bayou mansion and becomes curious about a locked attic room."},
  {id: "the-awakening-2011", title: "The Awakening", year: 2011, calendarDay: 1, intensity: "moderate", genres: ["ghost", "gothic"], blurb: "In 1921 England, an author who debunks hoaxes is invited to a boarding school to investigate sightings of a ghostly child."},
  {id: "bram-stokers-dracula-1992", title: "Bram Stoker’s Dracula", year: 1992, calendarDay: 1, intensity: "intense", genres: ["vampire", "gothic"], blurb: "A lavish, operatic retelling of the Transylvanian count’s voyage to London and his obsession with a young solicitor’s fiancée."},
  {id: "suspiria-1977", title: "Suspiria", year: 1977, calendarDay: 1, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "An American dancer joins a prestigious German ballet academy as a series of gruesome deaths begins. Vivid color, pounding score."},
  {id: "scream-1996", title: "Scream", year: 1996, calendarDay: 2, intensity: "moderate", genres: ["slasher", "thriller"], blurb: "A year after her mother’s murder, a teenager and her small town are stalked by a masked killer obsessed with horror movies."},
  {id: "i-know-what-you-did-last-summer-1997", title: "I Know What You Did Last Summer", year: 1997, calendarDay: 2, intensity: "moderate", genres: ["slasher", "thriller"], blurb: "Four friends cover up a deadly roadside accident; a year later, someone sends them a message that they know."},
  {id: "urban-legend-1998", title: "Urban Legend", year: 1998, calendarDay: 2, intensity: "moderate", genres: ["slasher"], blurb: "College students realize a killer is staging murders inspired by the campus folklore they love to retell."},
  {id: "happy-death-day-2017", title: "Happy Death Day", year: 2017, calendarDay: 2, intensity: "light", genres: ["slasher", "comedy"], blurb: "A self-absorbed college student relives her birthday again and again, murdered each time by a masked killer she must unmask."},
  {id: "totally-killer-2023", title: "Totally Killer", year: 2023, calendarDay: 2, intensity: "moderate", genres: ["slasher", "comedy", "sci-fi"], blurb: "A teenager travels back to 1987 hoping to stop a masked serial killer before his infamous spree begins."},
  {id: "happy-birthday-to-me-1981", title: "Happy Birthday to Me", year: 1981, calendarDay: 2, intensity: "moderate", genres: ["slasher"], blurb: "Members of an elite private-school clique start disappearing in the days before a troubled student’s eighteenth birthday."},
  {id: "black-christmas-1974", title: "Black Christmas", year: 1974, calendarDay: 2, intensity: "intense", genres: ["slasher"], blurb: "Sorority sisters staying on campus over winter break receive increasingly threatening phone calls as the house empties out."},
  {id: "alice-sweet-alice-1976", title: "Alice, Sweet Alice", year: 1976, calendarDay: 2, intensity: "intense", genres: ["slasher", "psychological"], blurb: "After a girl is killed at her First Communion, suspicion falls on her moody older sister in this grim, Catholic-tinged mystery."},
  {id: "the-cabin-in-the-woods-2012", title: "The Cabin in the Woods", year: 2012, calendarDay: 3, intensity: "moderate", genres: ["comedy", "supernatural"], blurb: "Five college friends head to a remote cabin for the weekend, unaware that their trip is not at all what it seems."},
  {id: "the-final-girls-2015", title: "The Final Girls", year: 2015, calendarDay: 3, intensity: "light", genres: ["comedy", "slasher"], blurb: "A grieving teen and her friends are pulled into the 1980s summer-camp slasher film that starred her late mother."},
  {id: "behind-the-mask-the-rise-of-leslie-vernon-2006", title: "Behind the Mask: The Rise of Leslie Vernon", year: 2006, calendarDay: 3, intensity: "moderate", genres: ["slasher", "comedy", "found-footage"], blurb: "A documentary crew follows an aspiring slasher villain as he cheerfully explains how he plans his upcoming massacre."},
  {id: "the-blackening-2022", title: "The Blackening", year: 2022, calendarDay: 3, intensity: "light", genres: ["comedy", "slasher"], blurb: "Seven Black friends reunite at a cabin for Juneteenth weekend and find themselves trapped in a deadly, horror-savvy game."},
  {id: "freaky-2020", title: "Freaky", year: 2020, calendarDay: 3, intensity: "moderate", genres: ["comedy", "slasher"], blurb: "A bullied high schooler swaps bodies with a notorious serial killer and has twenty-four hours to switch back."},
  {id: "better-watch-out-2016", title: "Better Watch Out", year: 2016, calendarDay: 3, intensity: "moderate", genres: ["thriller", "comedy"], blurb: "A babysitter looking after a twelve-year-old on a snowy suburban night before Christmas faces what seems to be a home invasion."},
  {id: "barbarian-2022", title: "Barbarian", year: 2022, calendarDay: 3, intensity: "intense", genres: ["thriller"], blurb: "A woman arrives at her Detroit rental to find it double-booked by a stranger, and the house holds more than one surprise."},
  {id: "malignant-2021", title: "Malignant", year: 2021, calendarDay: 3, intensity: "intense", genres: ["supernatural", "slasher"], blurb: "A woman begins having vivid visions of brutal murders, then learns they are really happening. Gleefully over the top."},
  {id: "shaun-of-the-dead-2004", title: "Shaun of the Dead", year: 2004, calendarDay: 4, intensity: "light", genres: ["zombie", "comedy"], blurb: "An aimless London shop worker tries to win back his girlfriend, patch things up with his mum, and survive a zombie uprising."},
  {id: "zombieland-2009", title: "Zombieland", year: 2009, calendarDay: 4, intensity: "light", genres: ["zombie", "comedy"], blurb: "A nervous college student follows strict survival rules while road-tripping across a zombie-overrun America with unlikely companions."},
  {id: "warm-bodies-2013", title: "Warm Bodies", year: 2013, calendarDay: 4, intensity: "light", genres: ["zombie", "comedy"], blurb: "A lovesick zombie begins to feel human again after meeting a living girl, in this gentle romantic take on the apocalypse."},
  {id: "fido-2006", title: "Fido", year: 2006, calendarDay: 4, intensity: "light", genres: ["zombie", "comedy"], blurb: "In a 1950s-style suburb where tamed zombies work as servants, a lonely boy befriends his family’s new undead helper."},
  {id: "night-of-the-living-dead-1968", title: "Night of the Living Dead", year: 1968, calendarDay: 4, intensity: "moderate", genres: ["zombie"], blurb: "Strangers barricade themselves inside a Pennsylvania farmhouse as the recently dead rise and surround them."},
  {id: "the-girl-with-all-the-gifts-2016", title: "The Girl with All the Gifts", year: 2016, calendarDay: 4, intensity: "moderate", genres: ["zombie", "sci-fi"], blurb: "After a fungal plague, a gifted young girl held at a military base may be the key to humanity’s survival."},
  {id: "train-to-busan-2016", title: "Train to Busan", year: 2016, calendarDay: 4, intensity: "intense", genres: ["zombie", "thriller"], blurb: "A workaholic father and his young daughter board a high-speed train just as a zombie outbreak sweeps across South Korea."},
  {id: "28-days-later-2002", title: "28 Days Later", year: 2002, calendarDay: 4, intensity: "intense", genres: ["zombie", "sci-fi"], blurb: "A bicycle courier wakes from a coma to find London deserted after a rage-inducing virus has torn through Britain."},
  {id: "the-others-2001", title: "The Others", year: 2001, calendarDay: 5, intensity: "moderate", genres: ["ghost", "gothic"], blurb: "On a fog-bound island after World War II, a devout mother keeps her light-sensitive children in darkness as strange events unfold."},
  {id: "the-orphanage-2007", title: "The Orphanage", year: 2007, calendarDay: 5, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "A woman reopens the seaside orphanage where she grew up, and her young son begins talking about invisible new friends."},
  {id: "the-devils-backbone-2001", title: "The Devil’s Backbone", year: 2001, calendarDay: 5, intensity: "moderate", genres: ["ghost", "gothic"], blurb: "During the Spanish Civil War, a boy left at a remote orphanage encounters the ghost of a former pupil."},
  {id: "the-frighteners-1996", title: "The Frighteners", year: 1996, calendarDay: 5, intensity: "light", genres: ["ghost", "comedy"], blurb: "A psychic con man who teams up with ghost friends to scam homeowners stumbles onto a genuinely deadly supernatural force."},
  {id: "the-innocents-1961", title: "The Innocents", year: 1961, calendarDay: 5, intensity: "moderate", genres: ["ghost", "gothic", "psychological"], blurb: "A governess caring for two children on a grand English estate becomes convinced they are visited by former servants who died."},
  {id: "the-haunting-1963", title: "The Haunting", year: 1963, calendarDay: 5, intensity: "moderate", genres: ["ghost", "psychological"], blurb: "A paranormal researcher gathers a small group at Hill House, a mansion with a long reputation for being unwelcoming."},
  {id: "the-entity-1982", title: "The Entity", year: 1982, calendarDay: 5, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A single mother is repeatedly attacked by an invisible force, while her doctors insist the cause must be in her mind."},
  {id: "the-sentinel-1977", title: "The Sentinel", year: 1977, calendarDay: 5, intensity: "intense", genres: ["supernatural", "gothic"], blurb: "A fashion model moves into a Brooklyn brownstone whose odd neighbors and reclusive blind priest upstairs hint at something sinister."},
  {id: "the-ring-2002", title: "The Ring", year: 2002, calendarDay: 6, intensity: "moderate", genres: ["supernatural", "ghost"], blurb: "A journalist investigates a mysterious videotape rumored to kill its viewers seven days after they watch it."},
  {id: "the-grudge-2004", title: "The Grudge", year: 2004, calendarDay: 6, intensity: "intense", genres: ["ghost", "supernatural"], blurb: "An American care worker in Tokyo becomes caught up in a curse born in a house where a terrible crime occurred."},
  {id: "shutter-2004-thailand", title: "Shutter", year: 2004, calendarDay: 6, version: "Thailand", intensity: "intense", genres: ["ghost", "supernatural"], blurb: "After a hit-and-run on a dark road, a young photographer and his girlfriend notice strange shapes appearing in his pictures."},
  {id: "drag-me-to-hell-2009", title: "Drag Me to Hell", year: 2009, calendarDay: 6, intensity: "light", genres: ["supernatural", "comedy"], blurb: "A loan officer refuses an elderly woman an extension and is cursed, unleashing a gleefully gross demonic torment."},
  {id: "ringu-1998", title: "Ringu", year: 1998, calendarDay: 6, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "A reporter looking into her niece’s sudden death traces it to a cursed videotape. The Japanese original behind The Ring."},
  {id: "dark-water-2002-japan", title: "Dark Water", year: 2002, calendarDay: 6, version: "Japan", intensity: "moderate", genres: ["ghost", "psychological"], blurb: "A mother in the middle of a custody battle moves into a rundown apartment with a persistent leak in the ceiling."},
  {id: "ju-on-the-grudge-2002", title: "Ju-On: The Grudge", year: 2002, calendarDay: 6, intensity: "intense", genres: ["ghost", "supernatural"], blurb: "Told in overlapping episodes, people who enter a cursed Tokyo house fall prey to the vengeful spirits within."},
  {id: "incantation-2022", title: "Incantation", year: 2022, calendarDay: 6, intensity: "intense", genres: ["found-footage", "supernatural"], blurb: "Through recovered footage, a mother recounts how breaking a religious taboo years ago placed a curse on her daughter."},
  {id: "the-sixth-sense-1999", title: "The Sixth Sense", year: 1999, calendarDay: 7, intensity: "moderate", genres: ["ghost", "psychological"], blurb: "A child psychologist tries to help a frightened young boy who says he can see dead people."},
  {id: "the-changeling-1980", title: "The Changeling", year: 1980, calendarDay: 7, intensity: "moderate", genres: ["ghost"], blurb: "A grieving composer rents a vast old Seattle mansion and begins hearing noises that point to a decades-old secret."},
  {id: "a-tale-of-two-sisters-2003", title: "A Tale of Two Sisters", year: 2003, calendarDay: 7, intensity: "moderate", genres: ["ghost", "psychological"], blurb: "Two sisters return home from a psychiatric hospital to a cold stepmother and an increasingly unsettling house."},
  {id: "paranorman-2012", title: "ParaNorman", year: 2012, calendarDay: 7, intensity: "light", genres: ["comedy", "spooky-adventure", "ghost"], blurb: "A misunderstood boy who can talk to ghosts must save his town from a centuries-old witch’s curse. Stop-motion animation."},
  {id: "stir-of-echoes-1999", title: "Stir of Echoes", year: 1999, calendarDay: 7, intensity: "moderate", genres: ["ghost", "psychological"], blurb: "After being hypnotized at a party, a Chicago phone lineman starts experiencing disturbing visions of a ghost."},
  {id: "mama-2013", title: "Mama", year: 2013, calendarDay: 7, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "Two girls found living alone in a forest cabin after five years are taken in by their uncle, but something followed them."},
  {id: "his-house-2020", title: "His House", year: 2020, calendarDay: 7, intensity: "intense", genres: ["ghost", "psychological"], blurb: "A refugee couple who fled South Sudan are placed in a rundown English house, where something evil seems to live in the walls."},
  {id: "lake-mungo-2008", title: "Lake Mungo", year: 2008, calendarDay: 7, intensity: "intense", genres: ["ghost", "found-footage"], blurb: "A mock documentary follows an Australian family after their daughter drowns and unexplained images surface in photos and video."},
  {id: "alien-1979", title: "Alien", year: 1979, calendarDay: 8, intensity: "intense", genres: ["sci-fi", "creature"], blurb: "The crew of a commercial towing spaceship answers a distress signal and brings something deadly aboard."},
  {id: "event-horizon-1997", title: "Event Horizon", year: 1997, calendarDay: 8, intensity: "intense", genres: ["sci-fi", "supernatural"], blurb: "A rescue crew sent to recover a missing experimental spaceship finds it has returned from somewhere terrible."},
  {id: "pandorum-2009", title: "Pandorum", year: 2009, calendarDay: 8, intensity: "intense", genres: ["sci-fi", "creature"], blurb: "Two crew members wake from hypersleep aboard a dark, seemingly abandoned ship with no memory of their mission."},
  {id: "killer-klowns-from-outer-space-1988", title: "Killer Klowns from Outer Space", year: 1988, calendarDay: 8, intensity: "light", genres: ["comedy", "sci-fi", "creature"], blurb: "Alien clowns land outside a small town and start collecting residents in cotton-candy cocoons. Gleefully absurd."},
  {id: "pitch-black-2000", title: "Pitch Black", year: 2000, calendarDay: 8, intensity: "moderate", genres: ["sci-fi", "creature"], blurb: "Stranded on a sun-scorched planet, crash survivors must rely on a dangerous convict when an eclipse brings creatures out of the dark."},
  {id: "europa-report-2013", title: "Europa Report", year: 2013, calendarDay: 8, intensity: "moderate", genres: ["sci-fi", "found-footage"], blurb: "Recovered mission footage chronicles a privately funded crew’s journey to Jupiter’s moon Europa in search of life."},
  {id: "life-2017", title: "Life", year: 2017, calendarDay: 8, intensity: "intense", genres: ["sci-fi", "creature"], blurb: "Astronauts aboard the International Space Station study a Martian life form that proves far more capable than expected."},
  {id: "sunshine-2007", title: "Sunshine", year: 2007, calendarDay: 8, intensity: "intense", genres: ["sci-fi", "psychological"], blurb: "A crew carrying an enormous bomb travels toward the dying sun on a last-chance mission to reignite it."},
  {id: "the-thing-1982", title: "The Thing", year: 1982, calendarDay: 9, intensity: "intense", genres: ["creature", "sci-fi", "body-horror"], blurb: "An Antarctic research team is infiltrated by a shape-shifting organism that can perfectly imitate any living thing."},
  {id: "the-fly-1986", title: "The Fly", year: 1986, calendarDay: 9, intensity: "intense", genres: ["body-horror", "sci-fi"], blurb: "An eccentric scientist’s teleportation experiment goes wrong when a housefly slips into the pod with him."},
  {id: "color-out-of-space-2019", title: "Color Out of Space", year: 2019, calendarDay: 9, intensity: "intense", genres: ["sci-fi", "body-horror"], blurb: "A meteorite lands on a remote New England farm and begins to change the land, the animals, and the family. Lovecraft adaptation."},
  {id: "the-blob-1958", title: "The Blob", year: 1958, calendarDay: 9, intensity: "light", genres: ["creature", "sci-fi"], blurb: "A teenager struggles to convince his small town that a growing, jelly-like mass from space is devouring people."},
  {id: "invasion-of-the-body-snatchers-1978", title: "Invasion of the Body Snatchers", year: 1978, calendarDay: 9, intensity: "moderate", genres: ["sci-fi", "psychological"], blurb: "San Francisco health inspectors notice that people are being replaced by emotionless duplicates grown from strange pods."},
  {id: "the-faculty-1998", title: "The Faculty", year: 1998, calendarDay: 9, intensity: "moderate", genres: ["sci-fi", "creature"], blurb: "A group of high school misfits suspects their teachers have been taken over by parasitic aliens."},
  {id: "the-blob-1988", title: "The Blob", year: 1988, calendarDay: 9, intensity: "intense", genres: ["creature", "body-horror", "sci-fi"], blurb: "A remake that sends a far nastier, flesh-dissolving ooze through a small town, with gory practical effects."},
  {id: "the-void-2016", title: "The Void", year: 2016, calendarDay: 9, intensity: "intense", genres: ["body-horror", "supernatural"], blurb: "A small-town deputy and a skeleton hospital staff are besieged by hooded figures outside while grotesque things emerge inside."},
  {id: "the-descent-2005", title: "The Descent", year: 2005, calendarDay: 10, intensity: "intense", genres: ["creature", "thriller"], blurb: "Six friends on a caving expedition in the Appalachians become trapped in an uncharted cave system with something living in it."},
  {id: "as-above-so-below-2014", title: "As Above, So Below", year: 2014, calendarDay: 10, intensity: "intense", genres: ["found-footage", "supernatural"], blurb: "A team of explorers ventures into the catacombs beneath Paris in search of a legendary alchemical artifact."},
  {id: "the-ruins-2008", title: "The Ruins", year: 2008, calendarDay: 10, intensity: "intense", genres: ["creature", "body-horror"], blurb: "Vacationing friends visit a remote Mayan temple in Mexico and become stranded on top of it."},
  {id: "the-monster-squad-1987", title: "The Monster Squad", year: 1987, calendarDay: 10, intensity: "light", genres: ["spooky-adventure", "comedy", "creature"], blurb: "A gang of monster-obsessed kids must stop Dracula and his classic monster allies from seizing a powerful amulet."},
  {id: "47-meters-down-2017", title: "47 Meters Down", year: 2017, calendarDay: 10, intensity: "moderate", genres: ["thriller", "creature"], blurb: "Two sisters on vacation in Mexico are trapped in a shark cage on the ocean floor with dwindling air."},
  {id: "crawl-2019", title: "Crawl", year: 2019, calendarDay: 10, intensity: "moderate", genres: ["creature", "thriller"], blurb: "During a major Florida hurricane, a swimmer searching for her father becomes trapped with alligators in a flooding house."},
  {id: "the-hills-have-eyes-2006", title: "The Hills Have Eyes", year: 2006, calendarDay: 10, intensity: "intense", genres: ["slasher", "thriller"], blurb: "A family’s car breaks down in the New Mexico desert, near territory held by a violent clan. A remake."},
  {id: "green-room-2015", title: "Green Room", year: 2015, calendarDay: 10, intensity: "intense", genres: ["thriller"], blurb: "A struggling punk band witnesses a crime at a remote neo-Nazi club and must fight their way out of the back room."},
  {id: "tucker-and-dale-vs-evil-2010", title: "Tucker & Dale vs. Evil", year: 2010, calendarDay: 11, intensity: "light", genres: ["comedy", "slasher"], blurb: "Two good-natured hillbillies fixing up their vacation cabin are mistaken for killers by a group of panicking college students."},
  {id: "what-we-do-in-the-shadows-2014", title: "What We Do in the Shadows", year: 2014, calendarDay: 11, intensity: "light", genres: ["comedy", "vampire"], blurb: "A documentary crew follows four vampire flatmates in Wellington as they bicker over chores and navigate modern nightlife."},
  {id: "housebound-2014", title: "Housebound", year: 2014, calendarDay: 11, intensity: "light", genres: ["comedy", "ghost"], blurb: "Sentenced to home detention at her mother’s house, a sullen young woman starts to suspect the place is haunted."},
  {id: "young-frankenstein-1974", title: "Young Frankenstein", year: 1974, calendarDay: 11, intensity: "light", genres: ["comedy", "gothic"], blurb: "The grandson of the infamous Victor Frankenstein travels to Transylvania and reluctantly takes up the family business."},
  {id: "an-american-werewolf-in-london-1981", title: "An American Werewolf in London", year: 1981, calendarDay: 11, intensity: "moderate", genres: ["creature", "comedy"], blurb: "Two American backpackers are attacked on the Yorkshire moors, and the survivor fears what will happen at the next full moon."},
  {id: "the-burbs-1989", title: "The ’Burbs", year: 1989, calendarDay: 11, intensity: "moderate", genres: ["comedy", "thriller"], blurb: "A suburbanite spending his week off at home becomes obsessed with his strange new neighbors and their nightly activities."},
  {id: "re-animator-1985", title: "Re-Animator", year: 1985, calendarDay: 11, intensity: "intense", genres: ["body-horror", "comedy"], blurb: "A medical student’s arrogant new roommate develops a serum that brings the dead back to life, with very messy results."},
  {id: "from-beyond-1986", title: "From Beyond", year: 1986, calendarDay: 11, intensity: "intense", genres: ["body-horror", "sci-fi"], blurb: "Scientists build a machine that awakens a hidden sense, opening their perception to monstrous beings from another dimension."},
  {id: "the-lost-boys-1987", title: "The Lost Boys", year: 1987, calendarDay: 12, intensity: "moderate", genres: ["vampire", "comedy"], blurb: "Two brothers move to a California beach town and discover that a local gang of motorbiking teens are vampires."},
  {id: "fright-night-1985", title: "Fright Night", year: 1985, calendarDay: 12, intensity: "moderate", genres: ["vampire", "comedy"], blurb: "A teenage horror fan becomes convinced his charming new neighbor is a vampire and recruits a TV horror host for help."},
  {id: "30-days-of-night-2007", title: "30 Days of Night", year: 2007, calendarDay: 12, intensity: "intense", genres: ["vampire"], blurb: "As an Alaskan town plunges into a month of darkness, a pack of vampires descends on the residents who stayed behind."},
  {id: "renfield-2023", title: "Renfield", year: 2023, calendarDay: 12, intensity: "light", genres: ["vampire", "comedy"], blurb: "Dracula’s long-suffering servant joins a support group and tries to escape his toxic boss in modern New Orleans."},
  {id: "let-the-right-one-in-2008", title: "Let the Right One In", year: 2008, calendarDay: 12, intensity: "moderate", genres: ["vampire", "psychological"], blurb: "A bullied boy in a snowy Stockholm suburb befriends the mysterious girl who has moved in next door."},
  {id: "byzantium-2012", title: "Byzantium", year: 2012, calendarDay: 12, intensity: "moderate", genres: ["vampire", "gothic"], blurb: "Two women with a centuries-old secret arrive in a faded English seaside town, where the younger one longs to tell her story."},
  {id: "from-dusk-till-dawn-1996", title: "From Dusk Till Dawn", year: 1996, calendarDay: 12, intensity: "intense", genres: ["vampire", "thriller", "comedy"], blurb: "Two criminal brothers take a family hostage and flee to a Mexican bar that proves far more dangerous than the law."},
  {id: "stake-land-2010", title: "Stake Land", year: 2010, calendarDay: 12, intensity: "intense", genres: ["vampire", "thriller"], blurb: "After a vampire epidemic collapses society, an orphaned teen and a hardened hunter travel north in search of a safe haven."},
  {id: "a-nightmare-on-elm-street-1984", title: "A Nightmare on Elm Street", year: 1984, calendarDay: 13, intensity: "moderate", genres: ["slasher", "supernatural"], blurb: "Teenagers on one suburban street are stalked in their dreams by a burned man wearing a bladed glove."},
  {id: "oculus-2013", title: "Oculus", year: 2013, calendarDay: 13, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A young woman sets out to prove that an antique mirror caused her family’s tragedy, with her recently released brother in tow."},
  {id: "jacobs-ladder-1990", title: "Jacob’s Ladder", year: 1990, calendarDay: 13, intensity: "intense", genres: ["psychological"], blurb: "A Vietnam veteran working in New York experiences increasingly disturbing hallucinations as his reality seems to come apart."},
  {id: "little-monsters-1989", title: "Little Monsters", year: 1989, calendarDay: 13, intensity: "light", genres: ["comedy", "spooky-adventure"], blurb: "A boy discovers a world of mischievous monsters living under the bed and befriends one of them."},
  {id: "before-i-wake-2016", title: "Before I Wake", year: 2016, calendarDay: 13, intensity: "moderate", genres: ["supernatural"], blurb: "A couple fostering an eight-year-old boy discover that his dreams take physical form, and so do his nightmares."},
  {id: "paperhouse-1988", title: "Paperhouse", year: 1988, calendarDay: 13, intensity: "moderate", genres: ["psychological", "supernatural"], blurb: "A feverish girl finds that, in her dreams, she can visit a house she has drawn and the lonely boy she drew inside."},
  {id: "in-the-mouth-of-madness-1994", title: "In the Mouth of Madness", year: 1994, calendarDay: 13, intensity: "intense", genres: ["psychological", "supernatural"], blurb: "An insurance investigator searches for a missing horror novelist whose books seem to drive readers insane."},
  {id: "possessor-2020", title: "Possessor", year: 2020, calendarDay: 13, intensity: "intense", genres: ["sci-fi", "body-horror", "psychological"], blurb: "A corporate agent uses brain-implant technology to take over other people’s bodies and carry out assassinations."},
  {id: "it-follows-2014", title: "It Follows", year: 2014, calendarDay: 14, intensity: "intense", genres: ["supernatural"], blurb: "After a sexual encounter, a young woman is pursued by a slow, relentless entity that can look like anyone."},
  {id: "smile-2022", title: "Smile", year: 2022, calendarDay: 14, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A psychiatrist witnesses a disturbing incident involving a patient and starts experiencing frightening things she cannot explain."},
  {id: "final-destination-2000", title: "Final Destination", year: 2000, calendarDay: 14, intensity: "intense", genres: ["supernatural", "thriller"], blurb: "After a premonition saves a group of students from a plane explosion, death seems determined to collect them anyway."},
  {id: "the-house-with-a-clock-in-its-walls-2018", title: "The House with a Clock in Its Walls", year: 2018, calendarDay: 14, intensity: "light", genres: ["spooky-adventure", "comedy"], blurb: "An orphaned boy moves in with his warlock uncle and learns a mysterious clock is ticking somewhere inside their mansion’s walls."},
  {id: "lights-out-2016", title: "Lights Out", year: 2016, calendarDay: 14, intensity: "moderate", genres: ["supernatural", "ghost"], blurb: "A young woman and her little brother confront an entity that appears only when the lights go off."},
  {id: "the-boogeyman-2023", title: "The Boogeyman", year: 2023, calendarDay: 14, intensity: "moderate", genres: ["supernatural", "creature"], blurb: "A grieving teenager and her younger sister are menaced by a creature that preys on suffering families. Based on a Stephen King story."},
  {id: "smile-2-2024", title: "Smile 2", year: 2024, calendarDay: 14, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A pop star preparing for a comeback world tour begins experiencing terrifying events she cannot explain."},
  {id: "it-2017", title: "It", year: 2017, calendarDay: 14, intensity: "intense", genres: ["supernatural", "creature"], blurb: "Bullied kids in Derry, Maine, band together against a shape-shifting entity that often appears as a clown."},
  {id: "get-out-2017", title: "Get Out", year: 2017, calendarDay: 15, intensity: "moderate", genres: ["thriller", "psychological"], blurb: "A young Black photographer visits his white girlfriend’s family estate for a weekend and senses that something is deeply wrong."},
  {id: "us-2019", title: "Us", year: 2019, calendarDay: 15, intensity: "intense", genres: ["thriller", "psychological"], blurb: "A family’s beach vacation turns into a nightmare when menacing doppelgängers appear in their driveway."},
  {id: "the-stepford-wives-1975", title: "The Stepford Wives", year: 1975, calendarDay: 15, intensity: "moderate", genres: ["psychological", "sci-fi", "thriller"], blurb: "A photographer moves to an idyllic Connecticut suburb and grows suspicious of its eerily perfect, submissive housewives."},
  {id: "little-shop-of-horrors-1986", title: "Little Shop of Horrors", year: 1986, calendarDay: 15, intensity: "light", genres: ["comedy", "creature"], blurb: "A nerdy florist’s assistant raises an exotic plant with a bloodthirsty appetite in this rock-musical comedy."},
  {id: "the-invitation-2015", title: "The Invitation", year: 2015, calendarDay: 15, intensity: "moderate", genres: ["thriller", "psychological"], blurb: "A man attends a dinner party at the home of his ex-wife and her new partner and grows suspicious of their intentions."},
  {id: "coherence-2013", title: "Coherence", year: 2013, calendarDay: 15, intensity: "moderate", genres: ["sci-fi", "psychological"], blurb: "A passing comet sets off strange events during a dinner party among friends. Low-budget and puzzling."},
  {id: "the-invisible-man-2020", title: "The Invisible Man", year: 2020, calendarDay: 15, intensity: "intense", genres: ["thriller", "sci-fi", "psychological"], blurb: "A woman escapes her controlling partner, then becomes convinced he is still stalking her despite news of his death."},
  {id: "speak-no-evil-2022-denmark", title: "Speak No Evil", year: 2022, calendarDay: 15, version: "Denmark", intensity: "intense", genres: ["psychological", "thriller"], blurb: "A Danish family accepts an invitation to visit a Dutch couple they met on vacation, and politeness becomes a trap."},
  {id: "the-conjuring-2013", title: "The Conjuring", year: 2013, calendarDay: 16, intensity: "intense", genres: ["supernatural", "ghost"], blurb: "Paranormal investigators Ed and Lorraine Warren help a family terrorized by a dark presence in their Rhode Island farmhouse."},
  {id: "insidious-2010", title: "Insidious", year: 2010, calendarDay: 16, intensity: "intense", genres: ["supernatural", "ghost"], blurb: "A couple’s young son falls into an inexplicable coma, and their home becomes the center of disturbing activity."},
  {id: "poltergeist-1982", title: "Poltergeist", year: 1982, calendarDay: 16, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "A suburban family’s house becomes host to playful spirits that soon turn menacing and target their youngest daughter."},
  {id: "ghostbusters-1984", title: "Ghostbusters", year: 1984, calendarDay: 16, intensity: "light", genres: ["comedy", "ghost", "spooky-adventure"], blurb: "Three disgraced parapsychologists start a ghost-catching business in New York just as spectral activity surges."},
  {id: "house-1985", title: "House", year: 1985, calendarDay: 16, intensity: "moderate", genres: ["comedy", "supernatural"], blurb: "A horror novelist moves into his late aunt’s house to write a Vietnam memoir and finds monsters in the closets."},
  {id: "the-amityville-horror-1979", title: "The Amityville Horror", year: 1979, calendarDay: 16, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "A family moves into a Long Island house where a mass murder took place, and strange occurrences begin almost immediately."},
  {id: "the-conjuring-2-2016", title: "The Conjuring 2", year: 2016, calendarDay: 16, intensity: "intense", genres: ["supernatural", "possession"], blurb: "The Warrens travel to London to help a single mother and her children plagued by a malevolent spirit in their home."},
  {id: "annabelle-creation-2017", title: "Annabelle: Creation", year: 2017, calendarDay: 16, intensity: "intense", genres: ["supernatural", "possession"], blurb: "Years after their daughter’s death, a dollmaker and his wife welcome a nun and several orphans into their isolated home."},
  {id: "rec-2007", title: "[REC]", year: 2007, calendarDay: 17, intensity: "intense", genres: ["found-footage", "zombie"], blurb: "A TV reporter and her cameraman follow firefighters into a Barcelona apartment building that authorities suddenly seal off."},
  {id: "gonjiam-haunted-asylum-2018", title: "Gonjiam: Haunted Asylum", year: 2018, calendarDay: 17, intensity: "intense", genres: ["found-footage", "ghost"], blurb: "A horror web-series crew livestreams an overnight exploration of an abandoned Korean psychiatric hospital."},
  {id: "hell-house-llc-2015", title: "Hell House LLC", year: 2015, calendarDay: 17, intensity: "intense", genres: ["found-footage", "supernatural"], blurb: "A documentary revisits the crew behind a haunted-house attraction whose opening night ended in tragedy."},
  {id: "deadstream-2022", title: "Deadstream", year: 2022, calendarDay: 17, intensity: "light", genres: ["found-footage", "comedy", "ghost"], blurb: "A disgraced internet personality livestreams a night alone in a haunted house to win back his followers."},
  {id: "the-visit-2015", title: "The Visit", year: 2015, calendarDay: 17, intensity: "moderate", genres: ["found-footage", "thriller"], blurb: "Two kids film their week-long stay with grandparents they have never met, whose behavior grows increasingly odd."},
  {id: "creep-2014", title: "Creep", year: 2014, calendarDay: 17, intensity: "moderate", genres: ["found-footage", "psychological"], blurb: "A videographer answers an online ad to film a day in the life of a man with an unusual request."},
  {id: "grave-encounters-2011", title: "Grave Encounters", year: 2011, calendarDay: 17, intensity: "intense", genres: ["found-footage", "ghost"], blurb: "A ghost-hunting reality show crew locks itself inside an abandoned psychiatric hospital for the night."},
  {id: "the-poughkeepsie-tapes-2007", title: "The Poughkeepsie Tapes", year: 2007, calendarDay: 17, intensity: "intense", genres: ["found-footage", "thriller"], blurb: "A mock documentary built around a trove of videotapes left behind by a serial killer. Extremely bleak."},
  {id: "ready-or-not-2019", title: "Ready or Not", year: 2019, calendarDay: 18, intensity: "moderate", genres: ["comedy", "thriller"], blurb: "A new bride’s wedding night becomes a deadly game of hide-and-seek with her wealthy in-laws."},
  {id: "youre-next-2011", title: "You’re Next", year: 2011, calendarDay: 18, intensity: "intense", genres: ["thriller", "slasher"], blurb: "A family reunion at a remote vacation home is interrupted by masked attackers, but one guest proves unexpectedly resourceful."},
  {id: "the-menu-2022", title: "The Menu", year: 2022, calendarDay: 18, intensity: "moderate", genres: ["thriller", "comedy"], blurb: "A young couple travels to a remote island to dine at an exclusive restaurant where the celebrity chef has prepared surprises."},
  {id: "vampires-vs-the-bronx-2020", title: "Vampires vs. the Bronx", year: 2020, calendarDay: 18, intensity: "light", genres: ["vampire", "comedy"], blurb: "Teens in a gentrifying Bronx neighborhood discover that the newcomers buying up local businesses are vampires."},
  {id: "escape-room-2019", title: "Escape Room", year: 2019, calendarDay: 18, intensity: "moderate", genres: ["thriller"], blurb: "Six strangers accept an invitation to an immersive escape room and discover that the puzzles are lethal."},
  {id: "circle-2015", title: "Circle", year: 2015, calendarDay: 18, intensity: "moderate", genres: ["thriller", "sci-fi", "psychological"], blurb: "Fifty strangers wake up in a dark room, arranged in a circle, and must vote on who dies next."},
  {id: "saw-2004", title: "Saw", year: 2004, calendarDay: 18, intensity: "intense", genres: ["thriller", "body-horror"], blurb: "Two men wake up chained in a filthy bathroom, pawns in a sadistic game devised by a mysterious killer."},
  {id: "would-you-rather-2012", title: "Would You Rather", year: 2012, calendarDay: 18, intensity: "intense", genres: ["thriller"], blurb: "A woman desperate to help her sick brother accepts a wealthy man’s invitation to a dinner-party game with brutal stakes."},
  {id: "the-autopsy-of-jane-doe-2016", title: "The Autopsy of Jane Doe", year: 2016, calendarDay: 19, intensity: "intense", genres: ["supernatural"], blurb: "A father-and-son team of coroners examines an unidentified woman’s body overnight and uncovers increasingly bizarre findings."},
  {id: "1408-2007", title: "1408", year: 2007, calendarDay: 19, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A skeptical writer of haunted-hotel guides checks into a New York hotel room that the manager insists is evil."},
  {id: "last-shift-2014", title: "Last Shift", year: 2014, calendarDay: 19, intensity: "intense", genres: ["supernatural", "ghost"], blurb: "A rookie police officer is assigned to guard a closing police station alone on its final night."},
  {id: "extra-ordinary-2019", title: "Extra Ordinary", year: 2019, calendarDay: 19, intensity: "light", genres: ["comedy", "ghost", "supernatural"], blurb: "An Irish driving instructor with a gift for talking to spirits reluctantly helps a widower whose daughter is targeted by a has-been rock star."},
  {id: "devil-2010", title: "Devil", year: 2010, calendarDay: 19, intensity: "moderate", genres: ["supernatural", "thriller"], blurb: "Five strangers trapped in a stalled Philadelphia elevator begin to suspect that one of them may not be human."},
  {id: "pontypool-2008", title: "Pontypool", year: 2008, calendarDay: 19, intensity: "moderate", genres: ["psychological", "zombie"], blurb: "A shock jock at a small-town Ontario radio station receives reports of a strange outbreak spreading through the area."},
  {id: "the-vigil-2019", title: "The Vigil", year: 2019, calendarDay: 19, intensity: "intense", genres: ["supernatural"], blurb: "A man paid to sit overnight with the body of a deceased member of his former Orthodox Jewish community confronts a malevolent presence."},
  {id: "the-eyes-of-my-mother-2016", title: "The Eyes of My Mother", year: 2016, calendarDay: 19, intensity: "intense", genres: ["psychological"], blurb: "A lonely young woman on an isolated farm grows up shaped by a childhood trauma. Stark black-and-white and deeply disturbing."},
  {id: "the-witch-2015", title: "The Witch", year: 2015, calendarDay: 20, intensity: "intense", genres: ["folk", "supernatural"], blurb: "In 1630s New England, a Puritan family exiled to the edge of a forest begins to unravel after their baby vanishes."},
  {id: "midsommar-2019", title: "Midsommar", year: 2019, calendarDay: 20, intensity: "intense", genres: ["folk", "psychological"], blurb: "A grieving young woman joins her boyfriend’s trip to a remote Swedish commune for its midsummer festival."},
  {id: "the-wicker-man-1973", title: "The Wicker Man", year: 1973, calendarDay: 20, intensity: "moderate", genres: ["folk", "thriller"], blurb: "A devout police sergeant travels to a remote Scottish island to investigate a missing girl and finds unusual pagan customs."},
  {id: "the-witches-1990", title: "The Witches", year: 1990, calendarDay: 20, intensity: "light", genres: ["spooky-adventure", "comedy"], blurb: "A young boy staying at a seaside hotel with his grandmother stumbles onto a convention of child-hating witches."},
  {id: "the-hallow-2015", title: "The Hallow", year: 2015, calendarDay: 20, intensity: "moderate", genres: ["folk", "creature"], blurb: "A conservationist moves his young family to a remote Irish forest and disturbs creatures from local legend."},
  {id: "gretel-and-hansel-2020", title: "Gretel & Hansel", year: 2020, calendarDay: 20, intensity: "moderate", genres: ["folk", "supernatural"], blurb: "A dark, atmospheric retelling of the fairy tale, following two siblings who search for food and work in a forbidding wood."},
  {id: "apostle-2018", title: "Apostle", year: 2018, calendarDay: 20, intensity: "intense", genres: ["folk", "thriller"], blurb: "In 1905, a man travels to a remote Welsh island to rescue his sister from the religious cult holding her for ransom."},
  {id: "kill-list-2011", title: "Kill List", year: 2011, calendarDay: 20, intensity: "intense", genres: ["folk", "thriller", "psychological"], blurb: "A former soldier turned hitman takes a new contract with his old partner, and the job grows increasingly strange."},
  {id: "the-wailing-2016", title: "The Wailing", year: 2016, calendarDay: 21, intensity: "intense", genres: ["supernatural", "possession", "folk"], blurb: "A police officer in a rural Korean village investigates a wave of violent illnesses that locals blame on a mysterious stranger."},
  {id: "cure-1997", title: "Cure", year: 1997, calendarDay: 21, intensity: "intense", genres: ["psychological", "thriller"], blurb: "A Tokyo detective investigates a string of murders committed by different people who cannot explain their motives."},
  {id: "noroi-the-curse-2005", title: "Noroi: The Curse", year: 2005, calendarDay: 21, intensity: "intense", genres: ["found-footage", "supernatural"], blurb: "A paranormal researcher’s documentary connects a series of seemingly unrelated strange incidents across Japan."},
  {id: "one-cut-of-the-dead-2017", title: "One Cut of the Dead", year: 2017, calendarDay: 21, intensity: "light", genres: ["comedy", "zombie"], blurb: "A low-budget crew shooting a zombie movie in an abandoned facility gets more than it bargained for. Stick with it."},
  {id: "house-hausu-1977", title: "House / Hausu", year: 1977, calendarDay: 21, intensity: "moderate", genres: ["comedy", "supernatural", "ghost"], blurb: "A schoolgirl and six friends visit her aunt’s countryside home in this surreal, wildly inventive Japanese cult film."},
  {id: "the-host-2006-south-korea", title: "The Host", year: 2006, calendarDay: 21, version: "South Korea", intensity: "moderate", genres: ["creature", "comedy"], blurb: "A monster emerges from Seoul’s Han River, and a bumbling family sets out to rescue its youngest member."},
  {id: "terrified-aterrados-2017", title: "Terrified / Aterrados", year: 2017, calendarDay: 21, intensity: "intense", genres: ["supernatural", "ghost"], blurb: "Paranormal investigators look into terrifying occurrences plaguing several houses on one Buenos Aires street."},
  {id: "when-evil-lurks-2023", title: "When Evil Lurks", year: 2023, calendarDay: 21, intensity: "intense", genres: ["possession", "supernatural"], blurb: "Two brothers in rural Argentina find a man infected by a demon and try, disastrously, to get rid of him."},
  {id: "the-babadook-2014", title: "The Babadook", year: 2014, calendarDay: 22, intensity: "intense", genres: ["psychological", "supernatural"], blurb: "A widowed mother struggling with her troubled son finds a sinister pop-up book that neither of them can get rid of."},
  {id: "relic-2020", title: "Relic", year: 2020, calendarDay: 22, intensity: "intense", genres: ["psychological", "supernatural"], blurb: "A woman and her daughter return to the family home after her elderly mother goes missing, and find the house changed."},
  {id: "the-night-house-2020", title: "The Night House", year: 2020, calendarDay: 22, intensity: "intense", genres: ["psychological", "ghost"], blurb: "A newly widowed teacher alone in the lakeside home her husband built begins uncovering his disturbing secrets."},
  {id: "frankenweenie-2012", title: "Frankenweenie", year: 2012, calendarDay: 22, intensity: "light", genres: ["comedy", "spooky-adventure"], blurb: "A young filmmaker uses science to bring his beloved dog back to life. Black-and-white stop-motion animation."},
  {id: "the-monster-2016", title: "The Monster", year: 2016, calendarDay: 22, intensity: "moderate", genres: ["creature", "psychological"], blurb: "A troubled mother and her daughter are stranded on a dark, rain-soaked road while something stalks them from the woods."},
  {id: "a-dark-song-2016", title: "A Dark Song", year: 2016, calendarDay: 22, intensity: "moderate", genres: ["supernatural", "psychological"], blurb: "A grieving woman hires an occultist to perform a months-long ritual inside an isolated Welsh house."},
  {id: "saint-maud-2019", title: "Saint Maud", year: 2019, calendarDay: 22, intensity: "intense", genres: ["psychological"], blurb: "A pious young hospice nurse becomes obsessed with saving the soul of her dying patient."},
  {id: "goodnight-mommy-2014-austria", title: "Goodnight Mommy", year: 2014, calendarDay: 22, version: "Austria", intensity: "intense", genres: ["psychological"], blurb: "Twin boys begin to suspect that the woman who returned from surgery with a bandaged face is not their mother."},
  {id: "talk-to-me-2022", title: "Talk to Me", year: 2022, calendarDay: 23, intensity: "intense", genres: ["possession", "supernatural"], blurb: "Teens discover how to conjure spirits using an embalmed hand and become hooked on the thrill."},
  {id: "ouija-origin-of-evil-2016", title: "Ouija: Origin of Evil", year: 2016, calendarDay: 23, intensity: "intense", genres: ["possession", "supernatural"], blurb: "In 1967 Los Angeles, a widowed mother who runs a séance scam adds a Ouija board to her act."},
  {id: "host-2020", title: "Host", year: 2020, calendarDay: 23, intensity: "intense", genres: ["supernatural", "found-footage"], blurb: "Six friends hold a séance over a video call during lockdown and invite something in. Told entirely on screen."},
  {id: "the-haunted-mansion-2003", title: "The Haunted Mansion", year: 2003, calendarDay: 23, intensity: "light", genres: ["comedy", "ghost", "spooky-adventure"], blurb: "A workaholic real-estate agent and his family are stranded in a sprawling mansion full of ghosts."},
  {id: "the-black-phone-2021", title: "The Black Phone", year: 2021, calendarDay: 23, intensity: "moderate", genres: ["supernatural", "thriller"], blurb: "An abducted boy trapped in a basement receives calls on a disconnected phone from the kidnapper’s previous victims."},
  {id: "veronica-2017", title: "Verónica", year: 2017, calendarDay: 23, intensity: "moderate", genres: ["possession", "supernatural"], blurb: "In 1991 Madrid, a teenager uses a Ouija board during a solar eclipse and draws in a dark presence."},
  {id: "the-medium-2021", title: "The Medium", year: 2021, calendarDay: 23, intensity: "intense", genres: ["possession", "found-footage", "folk"], blurb: "A documentary crew follows a shaman in rural Thailand whose niece starts behaving strangely."},
  {id: "the-cleansing-hour-2019", title: "The Cleansing Hour", year: 2019, calendarDay: 23, intensity: "intense", genres: ["possession", "supernatural"], blurb: "Two friends who livestream staged exorcisms face a real demon during one of their broadcasts."},
  {id: "hereditary-2018", title: "Hereditary", year: 2018, calendarDay: 24, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "After the family matriarch dies, her daughter’s family begins uncovering unsettling secrets about their ancestry."},
  {id: "the-dark-and-the-wicked-2020", title: "The Dark and the Wicked", year: 2020, calendarDay: 24, intensity: "intense", genres: ["supernatural"], blurb: "Siblings return to their family’s rural Texas farm to say goodbye to their dying father, and an evil presence awaits."},
  {id: "sinister-2012", title: "Sinister", year: 2012, calendarDay: 24, intensity: "intense", genres: ["supernatural"], blurb: "A true-crime writer finds a box of home movies in his new house that document a series of disturbing murders."},
  {id: "scouts-guide-to-the-zombie-apocalypse-2015", title: "Scouts Guide to the Zombie Apocalypse", year: 2015, calendarDay: 24, intensity: "light", genres: ["zombie", "comedy"], blurb: "Three scouts on the eve of their last campout team up with a cocktail waitress to save their town from zombies."},
  {id: "the-gift-2000", title: "The Gift", year: 2000, calendarDay: 24, intensity: "moderate", genres: ["thriller", "supernatural"], blurb: "A widowed psychic in small-town Georgia becomes entangled in the disappearance of a young woman."},
  {id: "the-mothman-prophecies-2002", title: "The Mothman Prophecies", year: 2002, calendarDay: 24, intensity: "moderate", genres: ["supernatural", "thriller"], blurb: "After his wife’s death, a reporter is drawn to a West Virginia town where residents report sightings of a winged figure."},
  {id: "the-blackcoats-daughter-2015", title: "The Blackcoat’s Daughter", year: 2015, calendarDay: 24, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "Two girls left behind at a Catholic boarding school over winter break sense an evil presence closing in."},
  {id: "suspiria-2018", title: "Suspiria", year: 2018, calendarDay: 24, intensity: "intense", genres: ["supernatural", "psychological"], blurb: "A young American dancer joins a renowned Berlin dance company in 1977 as a divided city simmers outside. A remake."},
  {id: "the-shining-1980", title: "The Shining", year: 1980, calendarDay: 25, intensity: "intense", genres: ["psychological", "supernatural"], blurb: "A writer takes a winter caretaker job at an isolated mountain hotel with his wife and psychic young son."},
  {id: "the-lodge-2019", title: "The Lodge", year: 2019, calendarDay: 25, intensity: "intense", genres: ["psychological"], blurb: "A soon-to-be stepmother is snowed in with her partner’s two children at a remote winter cabin."},
  {id: "the-lighthouse-2019", title: "The Lighthouse", year: 2019, calendarDay: 25, intensity: "intense", genres: ["psychological"], blurb: "Two lighthouse keepers on a remote New England island in the 1890s slowly lose their grip. Shot in black-and-white."},
  {id: "werewolves-within-2021", title: "Werewolves Within", year: 2021, calendarDay: 25, intensity: "light", genres: ["comedy", "creature"], blurb: "A new forest ranger arrives in a small Vermont town just as a snowstorm traps its squabbling residents with a possible werewolf."},
  {id: "session-9-2001", title: "Session 9", year: 2001, calendarDay: 25, intensity: "moderate", genres: ["psychological"], blurb: "An asbestos-removal crew working inside an abandoned mental hospital begins to unravel under a tight deadline."},
  {id: "the-vanishing-1988-netherlands", title: "The Vanishing", year: 1988, calendarDay: 25, version: "Netherlands", intensity: "moderate", genres: ["thriller", "psychological"], blurb: "A young man spends years searching for his girlfriend after she disappears from a busy highway rest stop."},
  {id: "misery-1990", title: "Misery", year: 1990, calendarDay: 25, intensity: "intense", genres: ["thriller", "psychological"], blurb: "A famous novelist injured in a car crash is rescued by his self-proclaimed number one fan."},
  {id: "possum-2018", title: "Possum", year: 2018, calendarDay: 25, intensity: "intense", genres: ["psychological"], blurb: "A disgraced children’s puppeteer returns to his childhood home and tries to get rid of a hideous puppet."},
  {id: "the-exorcist-1973", title: "The Exorcist", year: 1973, calendarDay: 26, intensity: "intense", genres: ["possession", "supernatural"], blurb: "When a twelve-year-old girl begins behaving violently and strangely, her desperate mother turns to two priests."},
  {id: "the-exorcism-of-emily-rose-2005", title: "The Exorcism of Emily Rose", year: 2005, calendarDay: 26, intensity: "intense", genres: ["possession", "thriller"], blurb: "A lawyer defends a priest accused of negligence after a young woman dies following an exorcism."},
  {id: "the-taking-of-deborah-logan-2014", title: "The Taking of Deborah Logan", year: 2014, calendarDay: 26, intensity: "intense", genres: ["found-footage", "possession"], blurb: "A documentary crew filming an elderly woman with Alzheimer’s begins witnessing things that defy medical explanation."},
  {id: "my-best-friends-exorcism-2022", title: "My Best Friend’s Exorcism", year: 2022, calendarDay: 26, intensity: "light", genres: ["comedy", "possession"], blurb: "In 1988, a high schooler suspects her best friend has become possessed after a night in the woods."},
  {id: "the-last-exorcism-2010", title: "The Last Exorcism", year: 2010, calendarDay: 26, intensity: "moderate", genres: ["found-footage", "possession"], blurb: "A disillusioned evangelical minister invites a documentary crew to film what he plans to be his last, staged exorcism."},
  {id: "the-possession-2012", title: "The Possession", year: 2012, calendarDay: 26, intensity: "moderate", genres: ["possession", "supernatural"], blurb: "A divorced father watches his younger daughter grow obsessed with an antique wooden box she bought at a yard sale."},
  {id: "the-exorcist-iii-1990", title: "The Exorcist III", year: 1990, calendarDay: 26, intensity: "intense", genres: ["possession", "thriller"], blurb: "A Georgetown detective investigates a series of murders bearing the hallmarks of an executed serial killer."},
  {id: "the-devils-candy-2015", title: "The Devil’s Candy", year: 2015, calendarDay: 26, intensity: "intense", genres: ["supernatural", "thriller"], blurb: "A struggling painter and his family move into a rural Texas home, where he begins hearing voices."},
  {id: "the-blair-witch-project-1999", title: "The Blair Witch Project", year: 1999, calendarDay: 27, intensity: "moderate", genres: ["found-footage", "folk"], blurb: "Three student filmmakers hike into the Maryland woods to document a local legend. Their footage is all that remains."},
  {id: "the-ritual-2017", title: "The Ritual", year: 2017, calendarDay: 27, intensity: "intense", genres: ["folk", "creature"], blurb: "Four old friends take a shortcut through a Swedish forest on a hiking trip and become hopelessly lost."},
  {id: "dog-soldiers-2002", title: "Dog Soldiers", year: 2002, calendarDay: 27, intensity: "intense", genres: ["creature", "comedy"], blurb: "A squad of British soldiers on a training exercise in the Scottish Highlands is hunted by werewolves."},
  {id: "ernest-scared-stupid-1991", title: "Ernest Scared Stupid", year: 1991, calendarDay: 27, intensity: "light", genres: ["comedy", "spooky-adventure"], blurb: "Bumbling Ernest accidentally frees a troll that has been trapped beneath a tree for centuries."},
  {id: "the-watcher-in-the-woods-1980", title: "The Watcher in the Woods", year: 1980, calendarDay: 27, intensity: "moderate", genres: ["ghost", "spooky-adventure"], blurb: "An American family rents an English country house, and their teenage daughter senses a presence in the surrounding woods."},
  {id: "the-village-2004", title: "The Village", year: 2004, calendarDay: 27, intensity: "moderate", genres: ["thriller", "folk"], blurb: "A tight-knit, isolated village lives by strict rules to keep peace with creatures said to dwell in the surrounding woods."},
  {id: "the-wind-2018", title: "The Wind", year: 2018, calendarDay: 27, intensity: "intense", genres: ["psychological", "supernatural"], blurb: "A frontierswoman left alone on the 1800s American plains grows convinced an evil presence haunts the land."},
  {id: "the-witch-in-the-window-2018", title: "The Witch in the Window", year: 2018, calendarDay: 27, intensity: "intense", genres: ["ghost"], blurb: "A father renovating an old Vermont farmhouse with his son discovers the house’s previous owner never left."},
  {id: "the-return-of-the-living-dead-1985", title: "The Return of the Living Dead", year: 1985, calendarDay: 28, intensity: "moderate", genres: ["zombie", "comedy"], blurb: "Two warehouse workers accidentally release a military gas that reanimates the dead. Punk-rock attitude to spare."},
  {id: "tremors-1990", title: "Tremors", year: 1990, calendarDay: 28, intensity: "light", genres: ["creature", "comedy"], blurb: "Two handymen in a tiny Nevada town discover that giant underground creatures are hunting the residents."},
  {id: "slither-2006", title: "Slither", year: 2006, calendarDay: 28, intensity: "moderate", genres: ["creature", "body-horror", "comedy"], blurb: "An alien parasite crash-lands near a small South Carolina town and infects its wealthiest resident."},
  {id: "gremlins-1984", title: "Gremlins", year: 1984, calendarDay: 28, intensity: "light", genres: ["creature", "comedy"], blurb: "A boy receives an unusual pet that comes with three important rules, and breaking them unleashes chaos on his town at Christmas."},
  {id: "critters-1986", title: "Critters", year: 1986, calendarDay: 28, intensity: "moderate", genres: ["creature", "comedy", "sci-fi"], blurb: "Furry, ravenous alien creatures land on a Kansas farm, followed by a pair of shape-shifting bounty hunters."},
  {id: "eight-legged-freaks-2002", title: "Eight Legged Freaks", year: 2002, calendarDay: 28, intensity: "moderate", genres: ["creature", "comedy"], blurb: "Toxic waste turns the spiders around a struggling Arizona mining town into giants."},
  {id: "splinter-2008", title: "Splinter", year: 2008, calendarDay: 28, intensity: "intense", genres: ["creature", "body-horror"], blurb: "A couple and an escaped convict are trapped in a gas station by a parasite that transforms its hosts."},
  {id: "the-mist-2007", title: "The Mist", year: 2007, calendarDay: 28, intensity: "intense", genres: ["creature", "thriller"], blurb: "After a storm, a thick mist rolls into a Maine town, trapping shoppers in a supermarket with something lurking outside."},
  {id: "halloween-1978", title: "Halloween", year: 1978, calendarDay: 29, intensity: "moderate", genres: ["slasher"], blurb: "Fifteen years after a childhood murder, Michael Myers escapes and returns to his hometown on Halloween night."},
  {id: "friday-the-13th-1980", title: "Friday the 13th", year: 1980, calendarDay: 29, intensity: "moderate", genres: ["slasher"], blurb: "Counselors reopening Camp Crystal Lake, despite its grim history, are picked off one by one by an unseen killer."},
  {id: "the-texas-chain-saw-massacre-1974", title: "The Texas Chain Saw Massacre", year: 1974, calendarDay: 29, intensity: "intense", genres: ["slasher"], blurb: "Five friends visiting a family grave in rural Texas cross paths with a household of cannibals."},
  {id: "club-dread-2004", title: "Club Dread", year: 2004, calendarDay: 29, intensity: "light", genres: ["comedy", "slasher"], blurb: "Staff at an island party resort run by a washed-up rock star realize a masked killer is on the loose."},
  {id: "childs-play-1988", title: "Child’s Play", year: 1988, calendarDay: 29, intensity: "moderate", genres: ["slasher", "supernatural"], blurb: "A single mother buys her son a talking doll, unaware that a serial killer’s soul is trapped inside it."},
  {id: "psycho-1960", title: "Psycho", year: 1960, calendarDay: 29, intensity: "moderate", genres: ["thriller", "psychological"], blurb: "A secretary on the run with stolen money checks into a remote motel run by a young man under his mother’s thumb."},
  {id: "candyman-1992", title: "Candyman", year: 1992, calendarDay: 29, intensity: "intense", genres: ["supernatural", "slasher"], blurb: "A Chicago graduate student researching urban legends investigates a hook-handed figure said to appear when his name is repeated."},
  {id: "x-2022", title: "X", year: 2022, calendarDay: 29, intensity: "intense", genres: ["slasher"], blurb: "In 1979, a small film crew rents a guesthouse on an elderly couple’s rural Texas farm to shoot an adult film."},
  {id: "trick-r-treat-2007", title: "Trick ’r Treat", year: 2007, calendarDay: 30, intensity: "moderate", genres: ["supernatural", "comedy"], blurb: "Four interwoven Halloween tales in one small town, watched over by a tiny trick-or-treater who enforces the holiday’s rules."},
  {id: "halloween-iii-season-of-the-witch-1982", title: "Halloween III: Season of the Witch", year: 1982, calendarDay: 30, intensity: "moderate", genres: ["sci-fi", "supernatural"], blurb: "A doctor investigates a novelty company whose Halloween masks are flying off shelves ahead of a big televised promotion."},
  {id: "scary-stories-to-tell-in-the-dark-2019", title: "Scary Stories to Tell in the Dark", year: 2019, calendarDay: 30, intensity: "moderate", genres: ["supernatural", "spooky-adventure"], blurb: "In 1968, teens find a book of scary stories in a haunted house, and new tales begin writing themselves."},
  {id: "hocus-pocus-1993", title: "Hocus Pocus", year: 1993, calendarDay: 30, intensity: "light", genres: ["comedy", "spooky-adventure"], blurb: "A new kid in Salem accidentally resurrects three seventeenth-century witch sisters on Halloween night."},
  {id: "ginger-snaps-2000", title: "Ginger Snaps", year: 2000, calendarDay: 30, intensity: "moderate", genres: ["creature", "body-horror"], blurb: "The bond between two morbid teenage sisters is tested after the elder is bitten by a mysterious creature."},
  {id: "pumpkinhead-1988", title: "Pumpkinhead", year: 1988, calendarDay: 30, intensity: "moderate", genres: ["creature", "supernatural"], blurb: "A grieving father seeks out a backwoods witch to summon a vengeance demon against the teens responsible for his son’s death."},
  {id: "haunt-2019", title: "Haunt", year: 2019, calendarDay: 30, intensity: "intense", genres: ["slasher", "thriller"], blurb: "Friends out on Halloween night visit an extreme haunted-house attraction that promises to feed on their darkest fears."},
  {id: "hell-fest-2018", title: "Hell Fest", year: 2018, calendarDay: 30, intensity: "intense", genres: ["slasher"], blurb: "A group of friends at a traveling horror-themed amusement park is stalked by a masked killer."},
  {id: "the-evil-dead-1981", title: "The Evil Dead", year: 1981, calendarDay: 31, intensity: "intense", genres: ["supernatural", "possession"], blurb: "Five friends at a remote Tennessee cabin find a book and a tape recording that unleash demonic forces."},
  {id: "evil-dead-ii-1987", title: "Evil Dead II", year: 1987, calendarDay: 31, intensity: "moderate", genres: ["supernatural", "comedy", "possession"], blurb: "Ash returns to the cabin in the woods for a frantic, slapstick-tinged battle against the demons of the Necronomicon."},
  {id: "evil-dead-rise-2023", title: "Evil Dead Rise", year: 2023, calendarDay: 31, intensity: "intense", genres: ["possession", "supernatural"], blurb: "A visit between estranged sisters in a Los Angeles apartment building turns violent after a dark discovery in the basement."},
  {id: "army-of-darkness-1992", title: "Army of Darkness", year: 1992, calendarDay: 31, intensity: "light", genres: ["comedy", "spooky-adventure", "supernatural"], blurb: "Hurled back to the Middle Ages, Ash must recover the Necronomicon and battle an army of the dead to get home."},
  {id: "night-of-the-demons-1988", title: "Night of the Demons", year: 1988, calendarDay: 31, intensity: "moderate", genres: ["supernatural", "possession"], blurb: "Teenagers throw a Halloween party at an abandoned funeral parlor and accidentally awaken a demon."},
  {id: "the-fog-1980", title: "The Fog", year: 1980, calendarDay: 31, intensity: "moderate", genres: ["ghost", "supernatural"], blurb: "On its centennial, a California coastal town is engulfed by a glowing fog that carries vengeful figures."},
  {id: "evil-dead-2013", title: "Evil Dead", year: 2013, calendarDay: 31, intensity: "intense", genres: ["possession", "supernatural"], blurb: "Friends help a young woman detox at a remote cabin and discover a book that unleashes a demon. A reimagining of the original."},
  {id: "hellraiser-1987", title: "Hellraiser", year: 1987, calendarDay: 31, intensity: "intense", genres: ["supernatural", "body-horror"], blurb: "A man’s search for forbidden pleasure through a mysterious puzzle box draws his family into a gruesome nightmare."},
];

(function (global) {
  'use strict';

  var CATALOG_VERSION = 'october-248-v1';
  var STORAGE_KEY = 'octoberHorror';
  var SCHEMA_VERSION = 1;
  var PICK_COUNT = 3;
  var FILMS_PER_DAY = 8;
  var MAX_SEARCH_LENGTH = 100;

  var GENRES = [
    'supernatural', 'ghost', 'possession', 'slasher', 'creature', 'vampire', 'zombie', 'psychological',
    'folk', 'sci-fi', 'body-horror', 'found-footage', 'comedy', 'gothic', 'thriller', 'spooky-adventure'
  ];
  var INTENSITIES = ['light', 'moderate', 'intense'];
  var INTENSITY_RANK = { light: 0, moderate: 1, intense: 2 };
  var INTENSITY_LABELS = {
    light: 'Light / fun',
    moderate: 'Creepy / moderate',
    intense: 'Intense / disturbing'
  };
  var SORTS = ['scheduled', 'title', 'year', 'intensity'];
  var WEEKDAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  var MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'];

  var MOVIES = OCTOBER_HORROR_MOVIES;
  var ORDER = {};
  var MOVIE_BY_ID = {};
  MOVIES.forEach(function (movie, index) {
    ORDER[movie.id] = index;
    MOVIE_BY_ID[movie.id] = movie;
  });

  // ── Dates (always local calendar parts, never toISOString) ──

  function pad2(n) {
    return (n < 10 ? '0' : '') + n;
  }

  function octoberKey(year, day) {
    return year + '-10-' + pad2(day);
  }

  function localDateInfo(date) {
    var year = date.getFullYear();
    var month = date.getMonth() + 1;
    var day = date.getDate();
    return {
      year: year,
      month: month,
      day: day,
      weekday: date.getDay(),
      key: year + '-' + pad2(month) + '-' + pad2(day),
      inOctober: month === 10
    };
  }

  function octoberWeekday(year, day) {
    return new Date(year, 9, day).getDay();
  }

  function formatOctoberDate(year, day) {
    return WEEKDAYS[octoberWeekday(year, day)] + ', October ' + day + ', ' + year;
  }

  function formatLocalDate(info) {
    return WEEKDAYS[info.weekday] + ', ' + MONTHS[info.month - 1] + ' ' + info.day + ', ' + info.year;
  }

  // ── Filters ─────────────────────────────────────────────────

  function defaultFilters() {
    return { search: '', genres: [], intensities: [], hideWatched: false };
  }

  function foldText(text) {
    return String(text)
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[\u2018\u2019\u02bc]/g, '\'')
      .toLowerCase();
  }

  function uniqueStrings(list) {
    var seen = {};
    var out = [];
    list.forEach(function (item) {
      if (typeof item === 'string' && !seen[item]) {
        seen[item] = true;
        out.push(item);
      }
    });
    return out;
  }

  function normalizeFilters(raw) {
    var filters = defaultFilters();
    if (!raw || typeof raw !== 'object') return filters;
    if (typeof raw.search === 'string') filters.search = raw.search.slice(0, MAX_SEARCH_LENGTH);
    if (Array.isArray(raw.genres)) {
      filters.genres = uniqueStrings(raw.genres).filter(function (g) { return GENRES.indexOf(g) !== -1; });
    }
    if (Array.isArray(raw.intensities)) {
      filters.intensities = INTENSITIES.filter(function (level) { return raw.intensities.indexOf(level) !== -1; });
    } else if (raw.maxIntensity === 'light' || raw.maxIntensity === 'moderate') {
      filters.intensities = INTENSITIES.slice(0, INTENSITY_RANK[raw.maxIntensity] + 1);
    }
    if (typeof raw.hideWatched === 'boolean') filters.hideWatched = raw.hideWatched;
    return filters;
  }

  function movieMatches(movie, filters, watchedLookup) {
    var query = foldText(filters.search.trim());
    if (query && foldText(movie.title).indexOf(query) === -1) return false;
    if (filters.genres.length && !movie.genres.some(function (g) { return filters.genres.indexOf(g) !== -1; })) {
      return false;
    }
    if (filters.intensities.length && filters.intensities.indexOf(movie.intensity) === -1) return false;
    if (filters.hideWatched && watchedLookup[movie.id]) return false;
    return true;
  }

  function toLookup(ids) {
    var lookup = {};
    (ids || []).forEach(function (id) { lookup[id] = true; });
    return lookup;
  }

  function filterMovies(movies, filters, watchedIds) {
    var watched = toLookup(watchedIds);
    return movies.filter(function (movie) { return movieMatches(movie, filters, watched); });
  }

  function filterSignature(filters, watchedIds, catalogVersion) {
    var parts = {
      v: catalogVersion || CATALOG_VERSION,
      q: filters.search.trim().toLowerCase(),
      g: filters.genres.slice().sort(),
      i: filters.intensities.length === INTENSITIES.length ? [] : INTENSITIES.filter(function (level) {
        return filters.intensities.indexOf(level) !== -1;
      }),
      hw: filters.hideWatched
    };
    if (filters.hideWatched) parts.w = (watchedIds || []).slice().sort();
    return JSON.stringify(parts);
  }

  // ── Sorting (catalog only) ───────────────────────────────────

  var titleCollator = typeof Intl !== 'undefined'
    ? new Intl.Collator('en', { sensitivity: 'base', ignorePunctuation: true, numeric: true })
    : null;

  function compareTitles(a, b) {
    return titleCollator ? titleCollator.compare(a, b) : (a < b ? -1 : a > b ? 1 : 0);
  }

  function sortMovies(movies, sort) {
    var list = movies.slice();
    var byOrder = function (a, b) { return ORDER[a.id] - ORDER[b.id]; };
    var comparators = {
      scheduled: byOrder,
      title: function (a, b) { return compareTitles(a.title, b.title) || a.year - b.year || byOrder(a, b); },
      year: function (a, b) { return a.year - b.year || byOrder(a, b); },
      intensity: function (a, b) { return INTENSITY_RANK[a.intensity] - INTENSITY_RANK[b.intensity] || byOrder(a, b); }
    };
    return list.sort(comparators[sort] || byOrder);
  }

  // ── Deterministic randomness ─────────────────────────────────
  // Seed string -> FNV-1a 32-bit hash -> mulberry32 PRNG. Candidate IDs are sorted
  // before a Fisher–Yates shuffle, so object/array iteration order never matters.

  function hashString(text) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < text.length; i++) {
      hash ^= text.charCodeAt(i);
      hash = Math.imul(hash, 0x01000193);
    }
    return hash >>> 0;
  }

  function mulberry32(seed) {
    var a = seed >>> 0;
    return function () {
      a = (a + 0x6d2b79f5) | 0;
      var t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function seededShuffle(ids, rng) {
    var list = ids.slice().sort();
    for (var i = list.length - 1; i > 0; i--) {
      var j = Math.floor(rng() * (i + 1));
      var tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }

  // ── Selection ────────────────────────────────────────────────
  // One film from each available intensity first, then the rest at random.
  // The seed plus the filter signature fully determine the result.

  function selectPicks(options) {
    var movies = options.movies || MOVIES;
    var byId = {};
    movies.forEach(function (m) { byId[m.id] = m; });
    var signature = filterSignature(options.filters, options.watchedIds, options.catalogVersion);
    var eligible = filterMovies(movies, options.filters, options.watchedIds).map(function (m) { return m.id; }).sort();
    var rng = mulberry32(hashString(options.seed + '|' + signature));
    var groups = {};
    INTENSITIES.forEach(function (level) {
      groups[level] = seededShuffle(eligible.filter(function (id) { return byId[id].intensity === level; }), rng);
    });
    var picks = [];
    seededShuffle(INTENSITIES.filter(function (level) { return groups[level].length; }), rng)
      .slice(0, PICK_COUNT)
      .forEach(function (level) { picks.push(groups[level][0]); });
    seededShuffle(eligible.filter(function (id) { return picks.indexOf(id) === -1; }), rng).forEach(function (id) {
      if (picks.length < PICK_COUNT) picks.push(id);
    });
    return { ids: picks, eligibleCount: eligible.length };
  }

  function moviesOnDay(day) {
    return MOVIES.filter(function (m) { return m.calendarDay === day; });
  }

  // Tonight's picks come only from tonight's scheduled films and stay fixed for the date.
  function tonightPicks(today, filters, watchedIds) {
    if (!today.inOctober) return { ids: [], eligibleCount: 0 };
    return selectPicks({
      movies: moviesOnDay(today.day),
      filters: filters,
      watchedIds: watchedIds,
      seed: 'tonight|' + today.key,
      catalogVersion: CATALOG_VERSION
    });
  }

  function randomPicks(filters, watchedIds, seed) {
    return selectPicks({
      movies: MOVIES,
      filters: filters,
      watchedIds: watchedIds,
      seed: 'random|' + seed,
      catalogVersion: CATALOG_VERSION
    });
  }

  function getSeason(state, year, create) {
    var key = String(year);
    if (!state.seasons[key] && create) {
      state.seasons[key] = { selectedIds: [], watchedIds: [] };
    }
    return state.seasons[key] || { selectedIds: [], watchedIds: [] };
  }

  function setTracked(state, year, kind, id, value) {
    if (!MOVIE_BY_ID[id] || (kind !== 'selected' && kind !== 'watched')) return;
    var season = getSeason(state, year, true);
    var field = kind === 'selected' ? 'selectedIds' : 'watchedIds';
    var list = season[field].filter(function (x) { return x !== id; });
    if (value) list.push(id);
    season[field] = list;
  }

  function resetSeason(state, year) {
    delete state.seasons[String(year)];
    state.filters = defaultFilters();
    state.sort = 'scheduled';
  }

  // ── Persistence ──────────────────────────────────────────────

  function defaultState() {
    return {
      schemaVersion: SCHEMA_VERSION,
      catalogVersion: CATALOG_VERSION,
      filters: defaultFilters(),
      sort: 'scheduled',
      seasons: {}
    };
  }

  function isPlainObject(value) {
    return !!value && typeof value === 'object' && !Array.isArray(value);
  }

  function knownIds(list) {
    return Array.isArray(list) ? uniqueStrings(list).filter(function (id) { return MOVIE_BY_ID[id]; }) : [];
  }

  function sanitizeState(raw) {
    if (!isPlainObject(raw)) return { state: defaultState(), problem: 'corrupt' };
    if (raw.schemaVersion !== SCHEMA_VERSION) return { state: defaultState(), problem: 'unsupported' };
    var state = defaultState();
    state.filters = normalizeFilters(raw.filters);
    if (SORTS.indexOf(raw.sort) !== -1) state.sort = raw.sort;
    if (isPlainObject(raw.seasons)) {
      Object.keys(raw.seasons).forEach(function (year) {
        var season = raw.seasons[year];
        if (!/^\d{4}$/.test(year) || !isPlainObject(season)) return;
        state.seasons[year] = { selectedIds: knownIds(season.selectedIds), watchedIds: knownIds(season.watchedIds) };
      });
    }
    return { state: state, problem: null };
  }

  // getStorage may throw (e.g. SecurityError when storage is blocked).
  function loadState(getStorage) {
    var storage = null;
    try {
      storage = getStorage();
      if (!storage) throw new Error('no storage');
    } catch (err) {
      return { state: defaultState(), storage: null, problem: 'unavailable' };
    }
    var text;
    try {
      text = storage.getItem(STORAGE_KEY);
    } catch (err) {
      return { state: defaultState(), storage: null, problem: 'unavailable' };
    }
    if (text === null || text === undefined) return { state: defaultState(), storage: storage, problem: null };
    var parsed;
    try {
      parsed = JSON.parse(text);
    } catch (err) {
      return { state: defaultState(), storage: storage, problem: 'corrupt' };
    }
    var result = sanitizeState(parsed);
    return { state: result.state, storage: storage, problem: result.problem };
  }

  function saveState(storage, state) {
    if (!storage) return false;
    try {
      storage.setItem(STORAGE_KEY, JSON.stringify(state));
      return true;
    } catch (err) {
      return false;
    }
  }

  // ── Reference links ──────────────────────────────────────────

  var REFERENCE_RULES = {
    imdb: { hosts: ['www.imdb.com', 'imdb.com', 'm.imdb.com'], path: /^\/title\/tt\d{7,9}\/?$/ },
    rt: { hosts: ['www.rottentomatoes.com', 'rottentomatoes.com'], path: /^\/m\/[a-z0-9_]+\/?$/ }
  };

  function isAllowedReferenceUrl(url, site) {
    var rule = REFERENCE_RULES[site];
    if (!rule || typeof url !== 'string' || typeof URL === 'undefined') return false;
    try {
      var parsed = new URL(url);
      return parsed.protocol === 'https:' && rule.hosts.indexOf(parsed.hostname) !== -1 &&
        !parsed.username && !parsed.password && !parsed.port && !parsed.search && !parsed.hash &&
        rule.path.test(parsed.pathname);
    } catch (err) {
      return false;
    }
  }

  function searchQuery(movie) {
    return movie.title.replace(/[\u2018\u2019]/g, '\'') + ' ' + movie.year;
  }

  function referenceLinks(movie) {
    var query = encodeURIComponent(searchQuery(movie));
    var imdbDirect = isAllowedReferenceUrl(movie.imdbUrl, 'imdb');
    var rtDirect = isAllowedReferenceUrl(movie.rottenTomatoesUrl, 'rt');
    return {
      imdb: {
        href: imdbDirect ? movie.imdbUrl : 'https://www.imdb.com/find/?q=' + query + '&s=tt',
        direct: imdbDirect
      },
      rt: {
        href: rtDirect ? movie.rottenTomatoesUrl : 'https://www.rottentomatoes.com/search?search=' + query,
        direct: rtDirect
      }
    };
  }

  // ── DOM rendering ────────────────────────────────────────────

  var SVG_NS = 'http://www.w3.org/2000/svg';

  function svgIcon(doc, paths, className, viewBox) {
    var svg = doc.createElementNS(SVG_NS, 'svg');
    svg.setAttribute('viewBox', viewBox || '0 0 24 24');
    svg.setAttribute('aria-hidden', 'true');
    svg.setAttribute('focusable', 'false');
    svg.setAttribute('class', className);
    paths.forEach(function (spec) {
      var node = doc.createElementNS(SVG_NS, spec[0]);
      Object.keys(spec[1]).forEach(function (attr) { node.setAttribute(attr, spec[1][attr]); });
      svg.appendChild(node);
    });
    return svg;
  }

  function externalIcon(doc) {
    return svgIcon(doc, [
      ['path', { d: 'M14 4h6v6' }],
      ['path', { d: 'M20 4l-9 9' }],
      ['path', { d: 'M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5' }]
    ], 'oh-ext');
  }

  var INTENSITY_SHAPES = {
    light: [['circle', { cx: '8', cy: '8', r: '6' }]],
    moderate: [['path', { d: 'M8 1.5 15 14.5H1z' }]],
    intense: [['path', { d: 'M8 1 15 8 8 15 1 8z' }], ['path', { d: 'M8 4.5v4.5M8 11.2v.3', class: 'oh-intensity__mark' }]]
  };

  function intensityBadge(doc, level) {
    var wrap = doc.createElement('p');
    wrap.className = 'oh-intensity oh-intensity--' + level;
    wrap.appendChild(svgIcon(doc, INTENSITY_SHAPES[level], 'oh-intensity__icon', '0 0 16 16'));
    var text = doc.createElement('span');
    text.textContent = INTENSITY_LABELS[level];
    wrap.appendChild(text);
    return wrap;
  }

  function el(doc, tag, className, text) {
    var node = doc.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  function hiddenText(doc, text) {
    return el(doc, 'span', 'oh-sr', text);
  }

  function movieLabel(movie) {
    return movie.title + ' (' + movie.year + (movie.version ? ', ' + movie.version : '') + ')';
  }

  var uid = 0;

  function renderMovieCard(doc, movie, opts) {
    var links = referenceLinks(movie);
    var card = el(doc, 'article', 'oh-movie oh-movie--' + movie.intensity);
    card.setAttribute('data-movie-id', movie.id);

    var n = ++uid;
    var bodyId = 'oh-' + opts.context + '-' + movie.id + '-body-' + n;
    var expanded = !!opts.expanded;

    var top = el(doc, 'div', 'oh-movie__top');
    var heading = el(doc, opts.headingLevel || 'h3', 'oh-movie__title');
    heading.appendChild(el(doc, 'span', 'oh-movie__name', movie.title));
    top.appendChild(heading);

    var toggle = el(doc, 'button', 'oh-movie__more');
    toggle.type = 'button';
    toggle.setAttribute('aria-expanded', expanded ? 'true' : 'false');
    toggle.setAttribute('aria-controls', bodyId);
    toggle.appendChild(el(doc, 'span', 'oh-movie__more-label', 'Details'));
    toggle.appendChild(hiddenText(doc, ': ' + movieLabel(movie)));
    toggle.appendChild(svgIcon(doc, [['path', { d: 'm6 9 6 6 6-6' }]], 'oh-movie__chevron', '0 0 24 24'));
    top.appendChild(toggle);
    card.appendChild(top);

    var labels = el(doc, 'div', 'oh-movie__labels');
    var tags = el(doc, 'ul', 'oh-tags');
    tags.setAttribute('aria-label', 'Genres');
    movie.genres.forEach(function (genre) { tags.appendChild(el(doc, 'li', 'oh-tag', genre)); });
    labels.appendChild(tags);
    labels.appendChild(intensityBadge(doc, movie.intensity));
    card.appendChild(labels);

    var body = el(doc, 'div', 'oh-movie__body');
    body.id = bodyId;
    body.hidden = !expanded;

    var meta = el(doc, 'p', 'oh-movie__meta');
    meta.appendChild(el(doc, 'span', '', String(movie.year)));
    if (movie.version) meta.appendChild(el(doc, 'span', '', movie.version));
    meta.appendChild(el(doc, 'span', '', 'Scheduled Oct ' + movie.calendarDay));
    body.appendChild(meta);

    var refs = el(doc, 'p', 'oh-movie__refs');
    var imdb = el(doc, 'a', 'oh-movie__imdb');
    imdb.href = links.imdb.href;
    imdb.target = '_blank';
    imdb.rel = 'noopener noreferrer';
    imdb.appendChild(doc.createTextNode(links.imdb.direct ? 'View on IMDb' : 'Search IMDb'));
    imdb.appendChild(externalIcon(doc));
    imdb.setAttribute('aria-label', links.imdb.direct
      ? movie.title + ': view on IMDb (opens in a new tab)'
      : movie.title + ': search IMDb for ' + movieLabel(movie) + ' (opens in a new tab)');
    refs.appendChild(imdb);

    var rt = el(doc, 'a', 'oh-movie__rt');
    rt.href = links.rt.href;
    rt.target = '_blank';
    rt.rel = 'noopener noreferrer';
    rt.appendChild(doc.createTextNode(links.rt.direct ? 'Rotten Tomatoes' : 'Search Rotten Tomatoes'));
    rt.appendChild(externalIcon(doc));
    rt.appendChild(hiddenText(doc, ' for ' + movieLabel(movie) + ' (opens in a new tab)'));
    refs.appendChild(rt);
    body.appendChild(refs);

    body.appendChild(el(doc, 'p', 'oh-movie__blurb', movie.blurb));

    var track = el(doc, 'div', 'oh-movie__track');
    [['selected', 'Want to watch'], ['watched', 'Watched']].forEach(function (pair) {
      var id = 'oh-' + opts.context + '-' + movie.id + '-' + pair[0] + '-' + n;
      var input = doc.createElement('input');
      input.type = 'checkbox';
      input.id = id;
      input.setAttribute('data-track', pair[0]);
      input.setAttribute('data-movie-id', movie.id);
      input.checked = opts.tracked[pair[0]].indexOf(movie.id) !== -1;
      var label = doc.createElement('label');
      label.htmlFor = id;
      label.className = 'oh-check';
      label.appendChild(input);
      label.appendChild(doc.createTextNode(' ' + pair[1]));
      label.appendChild(hiddenText(doc, ': ' + movieLabel(movie)));
      track.appendChild(label);
    });
    body.appendChild(track);
    card.appendChild(body);
    return card;
  }

  // ── Page controller ──────────────────────────────────────────

  var NOTICES = {
    corrupt: 'Saved October data could not be read, so it was reset.',
    unsupported: 'Saved October data came from an unsupported version, so it was reset.',
    unavailable: 'This browser is blocking storage, so changes will not be saved after you leave this page.',
    writeFailed: 'Your browser could not save changes (storage may be full or blocked). They will last only until you leave this page.'
  };

  function createApp(root, deps) {
    var doc = root.ownerDocument;
    var win = doc.defaultView;
    var now = deps.now || function () { return new Date(); };
    var confirmFn = deps.confirm || function (msg) { return win.confirm(msg); };
    var loaded = loadState(deps.getStorage || function () { return win.localStorage; });
    var state = loaded.state;
    var storage = loaded.storage;
    var today = localDateInfo(now());
    var selectedDay = today.inOctober ? today.day : 1;
    var followToday = today.inOctober;
    var random = deps.random || function () { return win.Math.random(); };
    var randomSeed = String(random());
    var expandedCards = {};
    var $ = function (sel) { return root.querySelector(sel); };

    function showNotice(key) {
      var box = $('#oh-notice');
      box.textContent = key ? NOTICES[key] : '';
      box.hidden = !key;
    }

    function persist() {
      if (!storage) return;
      if (!saveState(storage, state)) {
        storage = null;
        showNotice('writeFailed');
      }
    }

    function season() {
      return getSeason(state, today.year, false);
    }

    function tracked() {
      var s = season();
      return { selected: s.selectedIds, watched: s.watchedIds };
    }

    // ── Filters form ──

    function syncFilterControls() {
      var f = state.filters;
      $('#oh-search').value = f.search;
      root.querySelectorAll('input[name="oh-genre"]').forEach(function (box) {
        box.checked = f.genres.indexOf(box.value) !== -1;
      });
      root.querySelectorAll('input[name="oh-intensity"]').forEach(function (box) {
        box.checked = f.intensities.indexOf(box.value) !== -1;
      });
      $('#oh-hide-watched').checked = f.hideWatched;
      $('#oh-sort').value = state.sort;
      renderFilterSummary();
    }

    function renderFilterSummary() {
      var f = state.filters;
      var active = (f.search.trim() ? 1 : 0) + f.genres.length + f.intensities.length + (f.hideWatched ? 1 : 0);
      $('#oh-filters-active').textContent = active ? active + ' active' : 'none active';
    }

    function setSectionOpen(toggle, open) {
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      doc.getElementById(toggle.getAttribute('aria-controls')).hidden = !open;
    }

    function buildGenreControls() {
      var box = $('#oh-genres');
      GENRES.forEach(function (genre) {
        var id = 'oh-genre-' + genre;
        var label = el(doc, 'label', 'oh-check oh-chip');
        label.htmlFor = id;
        var input = doc.createElement('input');
        input.type = 'checkbox';
        input.name = 'oh-genre';
        input.id = id;
        input.value = genre;
        label.appendChild(input);
        label.appendChild(doc.createTextNode(' ' + genre));
        box.appendChild(label);
      });
    }

    function readFilters() {
      var genres = [];
      root.querySelectorAll('input[name="oh-genre"]:checked').forEach(function (box) { genres.push(box.value); });
      var intensities = [];
      root.querySelectorAll('input[name="oh-intensity"]:checked').forEach(function (box) { intensities.push(box.value); });
      state.filters = normalizeFilters({
        search: $('#oh-search').value,
        genres: genres,
        intensities: intensities,
        hideWatched: $('#oh-hide-watched').checked
      });
    }

    // ── Rendering ──

    function renderCards(container, ids, context, headingLevel) {
      container.textContent = '';
      container.setAttribute('data-context', context);
      var t = tracked();
      ids.forEach(function (id) {
        var item = el(doc, 'li', 'oh-list__item');
        item.appendChild(renderMovieCard(doc, MOVIE_BY_ID[id], {
          context: context,
          headingLevel: headingLevel,
          tracked: t,
          expanded: !!expandedCards[context + '|' + id]
        }));
        container.appendChild(item);
      });
    }

    function toggleCard(button) {
      var card = button.closest('.oh-movie');
      var context = button.closest('[data-context]').getAttribute('data-context');
      var open = button.getAttribute('aria-expanded') !== 'true';
      var key = context + '|' + card.getAttribute('data-movie-id');
      if (open) expandedCards[key] = true;
      else delete expandedCards[key];
      button.setAttribute('aria-expanded', open ? 'true' : 'false');
      doc.getElementById(button.getAttribute('aria-controls')).hidden = !open;
    }

    // ── Tabs ──

    function tabs() {
      return Array.prototype.slice.call(root.querySelectorAll('.oh-tab'));
    }

    function selectTab(tab, focus) {
      tabs().forEach(function (t) {
        var on = t === tab;
        t.setAttribute('aria-selected', on ? 'true' : 'false');
        t.tabIndex = on ? 0 : -1;
        doc.getElementById(t.getAttribute('aria-controls')).hidden = !on;
      });
      if (focus) tab.focus();
    }

    function onTabKey(event) {
      var list = tabs();
      var index = list.indexOf(event.target);
      var next = {
        ArrowRight: (index + 1) % list.length,
        ArrowLeft: (index - 1 + list.length) % list.length,
        Home: 0,
        End: list.length - 1
      }[event.key];
      if (next === undefined) return;
      event.preventDefault();
      selectTab(list[next], true);
    }

    function renderPicks() {
      var heading = $('#oh-picks-date');
      var result = tonightPicks(today, state.filters, season().watchedIds);
      var status;
      if (!today.inOctober) {
        heading.textContent = formatLocalDate(today);
        status = 'Tonight’s picks come from the calendar from October 1 to 31. Until then, try the Randomizer.';
      } else {
        heading.textContent = formatLocalDate(today) + ' — three of tonight’s scheduled films.';
        status = filtersActive()
          ? result.eligibleCount + ' of tonight’s ' + FILMS_PER_DAY + ' films match your filters.'
          : '';
        if (result.eligibleCount > 0 && result.eligibleCount < PICK_COUNT) {
          status += ' Fewer than three match, so fewer picks are shown.';
        }
      }
      $('#oh-picks-status').textContent = status.trim();
      renderCards($('#oh-picks-list'), result.ids, 'pick', 'h3');
      $('#oh-picks-empty').hidden = !today.inOctober || result.ids.length !== 0;
    }

    function renderRandom() {
      var result = randomPicks(state.filters, season().watchedIds, randomSeed);
      var status = result.eligibleCount + (result.eligibleCount === 1 ? ' movie matches' : ' movies match') + ' your filters.';
      if (result.eligibleCount > 0 && result.eligibleCount < PICK_COUNT) status += ' Fewer than three match, so fewer picks are shown.';
      $('#oh-random-status').textContent = status;
      renderCards($('#oh-random-list'), result.ids, 'random', 'h3');
      $('#oh-random-empty').hidden = result.ids.length !== 0;
      $('#oh-shuffle').disabled = result.eligibleCount <= PICK_COUNT;
    }

    function shuffle() {
      randomSeed = String(random());
      renderRandom();
    }

    function renderCalendar() {
      var year = today.year;
      $('#oh-cal-year').textContent = 'October ' + year;
      var list = $('#oh-cal-days');
      list.textContent = '';
      var offset = octoberWeekday(year, 1);
      var filtered = filtersActive();
      var matchesByDay = {};
      filterMovies(MOVIES, state.filters, season().watchedIds).forEach(function (m) {
        (matchesByDay[m.calendarDay] = matchesByDay[m.calendarDay] || []).push(m.id);
      });
      for (var day = 1; day <= 31; day++) {
        var matchCount = (matchesByDay[day] || []).length;
        var item = el(doc, 'li', 'oh-cal__cell');
        if (day === 1) item.style.gridColumnStart = String(offset + 1);
        var button = el(doc, 'button', 'oh-cal__day');
        button.type = 'button';
        button.setAttribute('data-day', String(day));
        button.setAttribute('aria-pressed', day === selectedDay ? 'true' : 'false');
        var isToday = today.inOctober && day === today.day;
        button.appendChild(el(doc, 'span', 'oh-cal__num', String(day)));
        if (isToday) {
          button.classList.add('oh-cal__day--today');
          button.setAttribute('aria-current', 'date');
          button.appendChild(el(doc, 'span', 'oh-cal__today', 'Today'));
        } else if (day === 31) {
          button.classList.add('oh-cal__day--halloween');
          button.appendChild(svgIcon(doc, [
            ['ellipse', { cx: '8', cy: '9.5', rx: '6.5', ry: '5.5' }],
            ['rect', { x: '7.2', y: '2', width: '1.6', height: '3', rx: '0.8' }]
          ], 'oh-cal__pumpkin', '0 0 16 16'));
        }
        if (filtered && !matchCount) button.classList.add('oh-cal__day--none');
        button.setAttribute('aria-label', formatOctoberDate(year, day) +
          (day === 31 ? ' (Halloween)' : '') + (isToday ? ' (today)' : '') +
          (filtered ? ', ' + matchCount + ' of ' + FILMS_PER_DAY + ' films match' : ''));
        item.appendChild(button);
        list.appendChild(item);
      }
      $('#oh-day-heading').textContent = formatOctoberDate(year, selectedDay);
      var ids = matchesByDay[selectedDay] || [];
      $('#oh-day-status').textContent = filtered
        ? ids.length + ' of ' + FILMS_PER_DAY + ' scheduled films match your filters.'
        : FILMS_PER_DAY + ' scheduled films.';
      renderCards($('#oh-day-list'), ids, 'day', 'h4');
      $('#oh-day-empty').hidden = ids.length !== 0;
    }

    function filtersActive() {
      var f = state.filters;
      return !!(f.search.trim() || f.genres.length || f.intensities.length || f.hideWatched);
    }

    function renderCatalog() {
      var matches = sortMovies(filterMovies(MOVIES, state.filters, season().watchedIds), state.sort);
      $('#oh-catalog-count').textContent = 'Showing ' + matches.length + ' of ' + MOVIES.length + ' movies.';
      $('#oh-catalog-summary').textContent = matches.length === MOVIES.length
        ? MOVIES.length + ' movies'
        : matches.length + ' of ' + MOVIES.length + ' match';
      renderCards($('#oh-catalog-list'), matches.map(function (m) { return m.id; }), 'cat', 'h3');
      $('#oh-catalog-empty').hidden = matches.length !== 0;
    }

    function scheduledOrder(ids) {
      return sortMovies(ids.map(function (id) { return MOVIE_BY_ID[id]; }), 'scheduled').map(function (m) { return m.id; });
    }

    function renderMine() {
      var ids = scheduledOrder(season().selectedIds);
      $('#oh-tab-mine-count').textContent = String(ids.length);
      renderCards($('#oh-mine-list'), ids, 'mine', 'h3');
      $('#oh-mine-empty').hidden = ids.length !== 0;
    }

    function renderWatched() {
      var ids = scheduledOrder(season().watchedIds);
      $('#oh-tab-watched-count').textContent = String(ids.length);
      $('#oh-watched-count').textContent = 'Watched this season: ' + ids.length + ' of ' + MOVIES.length + '.';
      renderCards($('#oh-watched-list'), ids, 'watched', 'h3');
      $('#oh-watched-empty').hidden = ids.length !== 0;
    }

    function renderAll() {
      root.querySelectorAll('.oh-season-year').forEach(function (node) { node.textContent = String(today.year); });
      // Keep each section independent so one missing node cannot blank the page.
      [
        renderCalendar,
        renderPicks,
        renderRandom,
        renderCatalog,
        renderMine,
        renderWatched
      ].forEach(function (render) {
        try { render(); }
        catch (err) { if (win.console && win.console.error) win.console.error(err); }
      });
    }

    function syncTrackInputs(kind, id, value) {
      root.querySelectorAll('input[data-track="' + kind + '"][data-movie-id="' + id + '"]').forEach(function (input) {
        input.checked = value;
      });
    }

    // ── Events ──

    function onFiltersChanged() {
      readFilters();
      renderFilterSummary();
      persist();
      renderCalendar();
      renderCatalog();
      renderPicks();
      renderRandom();
    }

    var FOCUS_AFTER_REMOVAL = {
      '#oh-day-list': '#oh-day-heading',
      '#oh-catalog-list': '#oh-catalog-toggle',
      '#oh-mine-list': '#oh-mine-heading',
      '#oh-watched-list': '#oh-watched-heading'
    };

    function onTrackChange(input) {
      var kind = input.getAttribute('data-track');
      var id = input.getAttribute('data-movie-id');
      var listSel = Object.keys(FOCUS_AFTER_REMOVAL).filter(function (sel) { return input.closest(sel); })[0];
      setTracked(state, today.year, kind, id, input.checked);
      persist();
      syncTrackInputs(kind, id, input.checked);
      if (kind === 'selected') renderMine();
      else renderWatched();
      if (kind === 'watched' && state.filters.hideWatched) {
        renderCalendar();
        renderCatalog();
        renderPicks();
        renderRandom();
      }
      if (listSel && !input.isConnected) $(FOCUS_AFTER_REMOVAL[listSel]).focus();
    }

    function clearFilters() {
      state.filters = defaultFilters();
      syncFilterControls();
      persist();
      renderCalendar();
      renderCatalog();
      renderPicks();
      renderRandom();
    }

    function resetMyOctober() {
      var ok = confirmFn('Reset your October ' + today.year + '? This clears this season’s Want to watch and ' +
        'Watched lists, and restores default filters. Other seasons are kept.');
      if (!ok) return;
      resetSeason(state, today.year);
      syncFilterControls();
      persist();
      renderAll();
      $('#oh-mine-status').textContent = 'Your October was reset.';
    }

    function checkDate() {
      var next = localDateInfo(now());
      if (next.key === today.key) return;
      today = next;
      if (followToday) {
        selectedDay = today.inOctober ? today.day : selectedDay;
      }
      followToday = today.inOctober && selectedDay === today.day;
      renderAll();
    }

    root.addEventListener('change', function (event) {
      var target = event.target;
      if (target.matches('input[data-track]')) onTrackChange(target);
      else if (target.matches('#oh-sort')) {
        state.sort = SORTS.indexOf(target.value) !== -1 ? target.value : 'scheduled';
        persist();
        renderCatalog();
      } else if (target.closest('#oh-filters')) onFiltersChanged();
    });
    $('#oh-search').addEventListener('input', onFiltersChanged);
    $('#oh-filters').addEventListener('submit', function (event) { event.preventDefault(); });
    root.addEventListener('click', function (event) {
      if (event.target.closest('.oh-jump')) {
        event.preventDefault();
        setSectionOpen($('#oh-filters-toggle'), true);
        $('#oh-filters-toggle').focus();
        return;
      }
      var target = event.target.closest('button');
      if (!target) return;
      if (target.matches('.oh-tab')) selectTab(target, false);
      else if (target.matches('.oh-movie__more')) toggleCard(target);
      else if (target.matches('.oh-toggle')) {
        setSectionOpen(target, target.getAttribute('aria-expanded') !== 'true');
      } else if (target.matches('.oh-clear')) clearFilters();
      else if (target.id === 'oh-shuffle') shuffle();
      else if (target.id === 'oh-reset') resetMyOctober();
      else if (target.matches('.oh-cal__day')) {
        selectedDay = Number(target.getAttribute('data-day'));
        followToday = today.inOctober && selectedDay === today.day;
        renderCalendar();
        var again = root.querySelector('.oh-cal__day[data-day="' + selectedDay + '"]');
        if (again) again.focus();
      }
    });
    $('.oh-tabs').addEventListener('keydown', function (event) {
      if (event.target.matches('.oh-tab')) onTabKey(event);
    });
    win.addEventListener('focus', checkDate);
    doc.addEventListener('visibilitychange', function () {
      if (doc.visibilityState === 'visible') checkDate();
    });
    win.setInterval(checkDate, 60000);

    buildGenreControls();
    setSectionOpen($('#oh-filters-toggle'), false);
    setSectionOpen($('#oh-catalog-toggle'), false);
    syncFilterControls();
    if (loaded.problem) showNotice(loaded.problem);
    renderAll();
    root.classList.add('oh--ready');

    return {
      checkDate: checkDate,
      getState: function () { return state; },
      getToday: function () { return today; }
    };
  }

  var api = {
    CATALOG_VERSION: CATALOG_VERSION,
    STORAGE_KEY: STORAGE_KEY,
    GENRES: GENRES,
    INTENSITIES: INTENSITIES,
    INTENSITY_LABELS: INTENSITY_LABELS,
    MOVIES: MOVIES,
    localDateInfo: localDateInfo,
    octoberKey: octoberKey,
    octoberWeekday: octoberWeekday,
    defaultFilters: defaultFilters,
    normalizeFilters: normalizeFilters,
    filterMovies: filterMovies,
    filterSignature: filterSignature,
    sortMovies: sortMovies,
    hashString: hashString,
    mulberry32: mulberry32,
    seededShuffle: seededShuffle,
    selectPicks: selectPicks,
    tonightPicks: tonightPicks,
    randomPicks: randomPicks,
    getSeason: getSeason,
    setTracked: setTracked,
    resetSeason: resetSeason,
    defaultState: defaultState,
    sanitizeState: sanitizeState,
    loadState: loadState,
    saveState: saveState,
    isAllowedReferenceUrl: isAllowedReferenceUrl,
    searchQuery: searchQuery,
    referenceLinks: referenceLinks,
    createApp: createApp
  };

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  } else {
    global.OctoberHorror = api;
    var start = function () {
      var root = document.getElementById('october-horror');
      if (root && !root.hasAttribute('data-manual-init')) api.createApp(root, {});
    };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start);
    else start();
  }
})(typeof window !== 'undefined' ? window : this);

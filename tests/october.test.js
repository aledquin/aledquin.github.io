// Dependency-free tests for js/october.js. Run with: node --test tests/october.test.js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const OH = require('../js/october.js');

const SUPPLIED = [
  'Sleepy Hollow (1999) [M]; Crimson Peak (2015) [M]; The Woman in Black (2012) [M]; Beetlejuice (1988) [L]; The Skeleton Key (2005) [M]; The Awakening (2011) [M]; Bram Stoker’s Dracula (1992) [H]; Suspiria (1977) [H]',
  'Scream (1996) [M]; I Know What You Did Last Summer (1997) [M]; Urban Legend (1998) [M]; Happy Death Day (2017) [L]; Totally Killer (2023) [M]; Happy Birthday to Me (1981) [M]; Black Christmas (1974) [H]; Alice, Sweet Alice (1976) [H]',
  'The Cabin in the Woods (2012) [M]; The Final Girls (2015) [L]; Behind the Mask: The Rise of Leslie Vernon (2006) [M]; The Blackening (2022) [L]; Freaky (2020) [M]; Better Watch Out (2016) [M]; Barbarian (2022) [H]; Malignant (2021) [H]',
  'Shaun of the Dead (2004) [L]; Zombieland (2009) [L]; Warm Bodies (2013) [L]; Fido (2006) [L]; Night of the Living Dead (1968) [M]; The Girl with All the Gifts (2016) [M]; Train to Busan (2016) [H]; 28 Days Later (2002) [H]',
  'The Others (2001) [M]; The Orphanage (2007) [M]; The Devil’s Backbone (2001) [M]; The Frighteners (1996) [L]; The Innocents (1961) [M]; The Haunting (1963) [M]; The Entity (1982) [H]; The Sentinel (1977) [H]',
  'The Ring (2002) [M]; The Grudge (2004) [H]; Shutter (2004; Thailand) [H]; Drag Me to Hell (2009) [L]; Ringu (1998) [M]; Dark Water (2002; Japan) [M]; Ju-On: The Grudge (2002) [H]; Incantation (2022) [H]',
  'The Sixth Sense (1999) [M]; The Changeling (1980) [M]; A Tale of Two Sisters (2003) [M]; ParaNorman (2012) [L]; Stir of Echoes (1999) [M]; Mama (2013) [M]; His House (2020) [H]; Lake Mungo (2008) [H]',
  'Alien (1979) [H]; Event Horizon (1997) [H]; Pandorum (2009) [H]; Killer Klowns from Outer Space (1988) [L]; Pitch Black (2000) [M]; Europa Report (2013) [M]; Life (2017) [H]; Sunshine (2007) [H]',
  'The Thing (1982) [H]; The Fly (1986) [H]; Color Out of Space (2019) [H]; The Blob (1958) [L]; Invasion of the Body Snatchers (1978) [M]; The Faculty (1998) [M]; The Blob (1988) [H]; The Void (2016) [H]',
  'The Descent (2005) [H]; As Above, So Below (2014) [H]; The Ruins (2008) [H]; The Monster Squad (1987) [L]; 47 Meters Down (2017) [M]; Crawl (2019) [M]; The Hills Have Eyes (2006) [H]; Green Room (2015) [H]',
  'Tucker & Dale vs. Evil (2010) [L]; What We Do in the Shadows (2014) [L]; Housebound (2014) [L]; Young Frankenstein (1974) [L]; An American Werewolf in London (1981) [M]; The ’Burbs (1989) [M]; Re-Animator (1985) [H]; From Beyond (1986) [H]',
  'The Lost Boys (1987) [M]; Fright Night (1985) [M]; 30 Days of Night (2007) [H]; Renfield (2023) [L]; Let the Right One In (2008) [M]; Byzantium (2012) [M]; From Dusk Till Dawn (1996) [H]; Stake Land (2010) [H]',
  'A Nightmare on Elm Street (1984) [M]; Oculus (2013) [H]; Jacob’s Ladder (1990) [H]; Little Monsters (1989) [L]; Before I Wake (2016) [M]; Paperhouse (1988) [M]; In the Mouth of Madness (1994) [H]; Possessor (2020) [H]',
  'It Follows (2014) [H]; Smile (2022) [H]; Final Destination (2000) [H]; The House with a Clock in Its Walls (2018) [L]; Lights Out (2016) [M]; The Boogeyman (2023) [M]; Smile 2 (2024) [H]; It (2017) [H]',
  'Get Out (2017) [M]; Us (2019) [H]; The Stepford Wives (1975) [M]; Little Shop of Horrors (1986) [L]; The Invitation (2015) [M]; Coherence (2013) [M]; The Invisible Man (2020) [H]; Speak No Evil (2022; Denmark) [H]',
  'The Conjuring (2013) [H]; Insidious (2010) [H]; Poltergeist (1982) [M]; Ghostbusters (1984) [L]; House (1985) [M]; The Amityville Horror (1979) [M]; The Conjuring 2 (2016) [H]; Annabelle: Creation (2017) [H]',
  '[REC] (2007) [H]; Gonjiam: Haunted Asylum (2018) [H]; Hell House LLC (2015) [H]; Deadstream (2022) [L]; The Visit (2015) [M]; Creep (2014) [M]; Grave Encounters (2011) [H]; The Poughkeepsie Tapes (2007) [H]',
  'Ready or Not (2019) [M]; You’re Next (2011) [H]; The Menu (2022) [M]; Vampires vs. the Bronx (2020) [L]; Escape Room (2019) [M]; Circle (2015) [M]; Saw (2004) [H]; Would You Rather (2012) [H]',
  'The Autopsy of Jane Doe (2016) [H]; 1408 (2007) [H]; Last Shift (2014) [H]; Extra Ordinary (2019) [L]; Devil (2010) [M]; Pontypool (2008) [M]; The Vigil (2019) [H]; The Eyes of My Mother (2016) [H]',
  'The Witch (2015) [H]; Midsommar (2019) [H]; The Wicker Man (1973) [M]; The Witches (1990) [L]; The Hallow (2015) [M]; Gretel & Hansel (2020) [M]; Apostle (2018) [H]; Kill List (2011) [H]',
  'The Wailing (2016) [H]; Cure (1997) [H]; Noroi: The Curse (2005) [H]; One Cut of the Dead (2017) [L]; House / Hausu (1977) [M]; The Host (2006; South Korea) [M]; Terrified / Aterrados (2017) [H]; When Evil Lurks (2023) [H]',
  'The Babadook (2014) [H]; Relic (2020) [H]; The Night House (2020) [H]; Frankenweenie (2012) [L]; The Monster (2016) [M]; A Dark Song (2016) [M]; Saint Maud (2019) [H]; Goodnight Mommy (2014; Austria) [H]',
  'Talk to Me (2022) [H]; Ouija: Origin of Evil (2016) [H]; Host (2020) [H]; The Haunted Mansion (2003) [L]; The Black Phone (2021) [M]; Verónica (2017) [M]; The Medium (2021) [H]; The Cleansing Hour (2019) [H]',
  'Hereditary (2018) [H]; The Dark and the Wicked (2020) [H]; Sinister (2012) [H]; Scouts Guide to the Zombie Apocalypse (2015) [L]; The Gift (2000) [M]; The Mothman Prophecies (2002) [M]; The Blackcoat’s Daughter (2015) [H]; Suspiria (2018) [H]',
  'The Shining (1980) [H]; The Lodge (2019) [H]; The Lighthouse (2019) [H]; Werewolves Within (2021) [L]; Session 9 (2001) [M]; The Vanishing (1988; Netherlands) [M]; Misery (1990) [H]; Possum (2018) [H]',
  'The Exorcist (1973) [H]; The Exorcism of Emily Rose (2005) [H]; The Taking of Deborah Logan (2014) [H]; My Best Friend’s Exorcism (2022) [L]; The Last Exorcism (2010) [M]; The Possession (2012) [M]; The Exorcist III (1990) [H]; The Devil’s Candy (2015) [H]',
  'The Blair Witch Project (1999) [M]; The Ritual (2017) [H]; Dog Soldiers (2002) [H]; Ernest Scared Stupid (1991) [L]; The Watcher in the Woods (1980) [M]; The Village (2004) [M]; The Wind (2018) [H]; The Witch in the Window (2018) [H]',
  'The Return of the Living Dead (1985) [M]; Tremors (1990) [L]; Slither (2006) [M]; Gremlins (1984) [L]; Critters (1986) [M]; Eight Legged Freaks (2002) [M]; Splinter (2008) [H]; The Mist (2007) [H]',
  'Halloween (1978) [M]; Friday the 13th (1980) [M]; The Texas Chain Saw Massacre (1974) [H]; Club Dread (2004) [L]; Child’s Play (1988) [M]; Psycho (1960) [M]; Candyman (1992) [H]; X (2022) [H]',
  'Trick ’r Treat (2007) [M]; Halloween III: Season of the Witch (1982) [M]; Scary Stories to Tell in the Dark (2019) [M]; Hocus Pocus (1993) [L]; Ginger Snaps (2000) [M]; Pumpkinhead (1988) [M]; Haunt (2019) [H]; Hell Fest (2018) [H]',
  'The Evil Dead (1981) [H]; Evil Dead II (1987) [M]; Evil Dead Rise (2023) [H]; Army of Darkness (1992) [L]; Night of the Demons (1988) [M]; The Fog (1980) [M]; Evil Dead (2013) [H]; Hellraiser (1987) [H]'
];
const LEVEL = { L: 'light', M: 'moderate', H: 'intense' };

function parseSupplied() {
  const out = [];
  SUPPLIED.forEach((row, index) => {
    const re = /(.+?) \((\d{4})(?:; ([^)]+))?\) \[([LMH])\](?:; |$)/g;
    let match;
    while ((match = re.exec(row))) {
      out.push({ day: index + 1, title: match[1], year: Number(match[2]), version: match[3], intensity: LEVEL[match[4]] });
    }
  });
  return out;
}

// ── Fixtures ──

function freshState() {
  return OH.defaultState();
}

function october(year, day) {
  return OH.localDateInfo(new Date(year, 9, day, 20, 0, 0));
}

function mini(specs) {
  return specs.map(([id, intensity]) => ({ id, title: id, year: 2000, calendarDay: 1, intensity, genres: ['ghost'], blurb: 'x' }));
}

function select(movies, seed, filters) {
  return OH.selectPicks({
    movies,
    filters: filters || OH.defaultFilters(),
    watchedIds: [],
    seed,
    catalogVersion: 'test'
  });
}

const byId = Object.fromEntries(OH.MOVIES.map((m) => [m.id, m]));

function memoryStorage(initial) {
  const data = Object.assign({}, initial);
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => { data[k] = String(v); },
    removeItem: (k) => { delete data[k]; }
  };
}

// ── Data contract ──

test('catalog matches the supplied 31 × 8 calendar exactly, in order', () => {
  const supplied = parseSupplied();
  assert.equal(supplied.length, 248);
  assert.equal(OH.MOVIES.length, 248);
  supplied.forEach((s, i) => {
    const m = OH.MOVIES[i];
    assert.equal(m.title, s.title, `row ${i}`);
    assert.equal(m.year, s.year, m.title);
    assert.equal(m.calendarDay, s.day, m.title);
    assert.equal(m.intensity, s.intensity, m.title);
    assert.equal(m.version, s.version, m.title);
  });
});

test('identities are unique, 8 per day, enums valid, blurbs ≤ 25 words', () => {
  const ids = new Set();
  const identities = new Set();
  const perDay = {};
  OH.MOVIES.forEach((m) => {
    assert.match(m.id, /^[a-z0-9-]+$/);
    assert.ok(!ids.has(m.id), 'duplicate id ' + m.id);
    ids.add(m.id);
    const identity = `${m.title}|${m.year}|${m.version || ''}`;
    assert.ok(!identities.has(identity), 'duplicate identity ' + identity);
    identities.add(identity);
    perDay[m.calendarDay] = (perDay[m.calendarDay] || 0) + 1;
    assert.ok(OH.INTENSITIES.includes(m.intensity));
    assert.ok(m.genres.length >= 1);
    m.genres.forEach((g) => assert.ok(OH.GENRES.includes(g), `${m.id}: ${g}`));
    assert.ok(m.blurb.trim().split(/\s+/).length <= 25, m.id);
    assert.equal(m.imdbUrl, undefined, 'no unverified direct links');
    assert.equal(m.rottenTomatoesUrl, undefined, 'no unverified direct links');
  });
  assert.equal(ids.size, 248);
  assert.equal(Object.keys(perDay).length, 31);
  Object.values(perDay).forEach((n) => assert.equal(n, 8));
});

test('October 22 has The Monster (2016) and The Final Girls appears once', () => {
  const day22 = OH.MOVIES.filter((m) => m.calendarDay === 22).map((m) => `${m.title} (${m.year})`);
  assert.ok(day22.includes('The Monster (2016)'));
  assert.equal(OH.MOVIES.filter((m) => m.title === 'The Final Girls').length, 1);
});

test('remakes and versions keep distinct ids and years', () => {
  const ids = OH.MOVIES.map((m) => m.id);
  ['the-blob-1958', 'the-blob-1988', 'suspiria-1977', 'suspiria-2018', 'the-evil-dead-1981', 'evil-dead-2013',
    'shutter-2004-thailand', 'the-host-2006-south-korea', 'host-2020', 'house-1985', 'house-hausu-1977']
    .forEach((id) => assert.ok(ids.includes(id), id));
});

// ── Reference links ──

test('fallback search links are encoded from title + year', () => {
  const byId = Object.fromEntries(OH.MOVIES.map((m) => [m.id, m]));
  const cases = {
    'bram-stokers-dracula-1992': "Bram%20Stoker's%20Dracula%201992",
    'tucker-and-dale-vs-evil-2010': 'Tucker%20%26%20Dale%20vs.%20Evil%202010',
    'veronica-2017': 'Ver%C3%B3nica%202017',
    'rec-2007': '%5BREC%5D%202007',
    'the-blob-1958': 'The%20Blob%201958',
    'the-blob-1988': 'The%20Blob%201988',
    'evil-dead-2013': 'Evil%20Dead%202013'
  };
  Object.entries(cases).forEach(([id, q]) => {
    const links = OH.referenceLinks(byId[id]);
    assert.equal(links.imdb.href, `https://www.imdb.com/find/?q=${q}&s=tt`);
    assert.equal(links.rt.href, `https://www.rottentomatoes.com/search?search=${q}`);
    assert.equal(links.imdb.direct, false);
    assert.equal(links.rt.direct, false);
    assert.equal(new URL(links.imdb.href).searchParams.get('q'), OH.searchQuery(byId[id]));
  });
});

test('direct reference URLs are only accepted for exact HTTPS film pages on expected hosts', () => {
  assert.ok(OH.isAllowedReferenceUrl('https://www.imdb.com/title/tt0000001/', 'imdb'));
  assert.ok(OH.isAllowedReferenceUrl('https://www.rottentomatoes.com/m/some_film', 'rt'));
  [
    'http://www.imdb.com/title/tt0000001/',
    'https://www.imdb.com.evil.example/title/tt0000001/',
    'https://www.imdb.com/title/tt0000001/?ref=aff',
    'https://www.imdb.com/find/?q=x',
    'https://bit.ly/abc',
    'javascript:alert(1)',
    'https://user@www.imdb.com/title/tt0000001/'
  ].forEach((url) => assert.equal(OH.isAllowedReferenceUrl(url, 'imdb'), false, url));
  assert.equal(OH.isAllowedReferenceUrl('https://www.imdb.com/title/tt0000001/', 'rt'), false);
  const direct = OH.referenceLinks({ title: 'X', year: 2000, imdbUrl: 'https://www.imdb.com/title/tt0000001/', rottenTomatoesUrl: 'https://evil.example/m/x' });
  assert.equal(direct.imdb.direct, true);
  assert.equal(direct.rt.direct, false);
});

// ── Filters & signatures ──

test('filters: case/accent-insensitive search, OR genres, AND across groups', () => {
  const f = OH.defaultFilters();
  assert.equal(OH.filterMovies(OH.MOVIES, f, []).length, 248);
  assert.deepEqual(OH.filterMovies(OH.MOVIES, { ...f, search: '  VERONICA ' }, []).map((m) => m.id), ['veronica-2017']);
  assert.deepEqual(OH.filterMovies(OH.MOVIES, { ...f, search: "bram stoker's" }, []).map((m) => m.id), ['bram-stokers-dracula-1992']);
  const vampOrZombie = OH.filterMovies(OH.MOVIES, { ...f, genres: ['vampire', 'zombie'] }, []);
  assert.ok(vampOrZombie.every((m) => m.genres.includes('vampire') || m.genres.includes('zombie')));
  const lightVamp = OH.filterMovies(OH.MOVIES, { ...f, genres: ['vampire'], intensities: ['light'] }, []);
  assert.ok(lightVamp.length > 0 && lightVamp.every((m) => m.intensity === 'light' && m.genres.includes('vampire')));
  const intenseOnly = OH.filterMovies(OH.MOVIES, { ...f, intensities: ['intense'] }, []);
  assert.equal(intenseOnly.length, OH.MOVIES.filter((m) => m.intensity === 'intense').length);
  assert.ok(intenseOnly.every((m) => m.intensity === 'intense'));
  const lightOrIntense = OH.filterMovies(OH.MOVIES, { ...f, intensities: ['light', 'intense'] }, []);
  assert.ok(lightOrIntense.length > intenseOnly.length && lightOrIntense.every((m) => m.intensity !== 'moderate'));
  const hidden = OH.filterMovies(OH.MOVIES, { ...f, hideWatched: true }, ['alien-1979']);
  assert.equal(hidden.length, 247);
});

test('legacy maxIntensity filters are converted to intensity selections', () => {
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'light' }).intensities, ['light']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'moderate' }).intensities, ['light', 'moderate']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'intense' }).intensities, []);
  assert.equal('maxIntensity' in OH.normalizeFilters({ maxIntensity: 'light' }), false);
});

test('signature is canonical and only includes watched IDs when Hide watched is on', () => {
  const a = OH.filterSignature({ search: ' Ghost ', genres: ['zombie', 'ghost'], intensities: ['moderate', 'light'], hideWatched: false }, ['b', 'a'], 'v1');
  const b = OH.filterSignature({ search: 'ghost', genres: ['ghost', 'zombie'], intensities: ['light', 'moderate'], hideWatched: false }, [], 'v1');
  assert.equal(a, b);
  const all = OH.filterSignature({ ...OH.defaultFilters(), intensities: ['intense', 'light', 'moderate'] }, [], 'v1');
  assert.equal(all, OH.filterSignature(OH.defaultFilters(), [], 'v1'), 'all three intensities == none selected');
  const c = OH.filterSignature({ ...OH.defaultFilters(), hideWatched: true }, ['b', 'a'], 'v1');
  const d = OH.filterSignature({ ...OH.defaultFilters(), hideWatched: true }, ['a', 'b'], 'v1');
  assert.equal(c, d);
  assert.deepEqual(JSON.parse(c).w, ['a', 'b']);
  assert.notEqual(OH.filterSignature(OH.defaultFilters(), [], 'v1'), OH.filterSignature(OH.defaultFilters(), [], 'v2'));
});

// ── Selection ──

test('identical inputs give identical picks; input order does not matter', () => {
  const one = select(OH.MOVIES, 'seed-1');
  const two = select(OH.MOVIES.slice().reverse(), 'seed-1');
  assert.deepEqual(one.ids, two.ids);
  assert.equal(new Set(one.ids).size, 3);
  assert.equal(one.eligibleCount, 248);
});

test('tonight’s picks come from that night’s calendar, mix intensities and never repeat across October', () => {
  const seen = new Set();
  for (let day = 1; day <= 31; day++) {
    const result = OH.tonightPicks(october(2026, day), OH.defaultFilters(), []);
    assert.equal(result.ids.length, 3);
    assert.equal(result.eligibleCount, 8);
    result.ids.forEach((id) => {
      assert.equal(byId[id].calendarDay, day, `${id} is scheduled for day ${day}`);
      assert.ok(!seen.has(id), `day ${day} repeated ${id}`);
      seen.add(id);
    });
    const levels = new Set(result.ids.map((id) => byId[id].intensity));
    const available = new Set(OH.MOVIES.filter((m) => m.calendarDay === day).map((m) => m.intensity));
    assert.equal(levels.size, Math.min(3, available.size), `day ${day} intensity mix`);
  }
});

test('tonight’s picks are stable for a date and follow the filters', () => {
  const morning = OH.localDateInfo(new Date(2026, 9, 13, 8));
  const night = OH.localDateInfo(new Date(2026, 9, 13, 23, 30));
  const f = OH.defaultFilters();
  assert.deepEqual(OH.tonightPicks(morning, f, []).ids, OH.tonightPicks(night, f, []).ids);

  const intense = OH.tonightPicks(night, { ...f, intensities: ['intense'] }, []);
  const day13Intense = OH.MOVIES.filter((m) => m.calendarDay === 13 && m.intensity === 'intense').length;
  assert.equal(intense.eligibleCount, day13Intense);
  assert.ok(intense.ids.every((id) => byId[id].calendarDay === 13 && byId[id].intensity === 'intense'));

  const hidden = OH.tonightPicks(night, { ...f, hideWatched: true }, OH.MOVIES.filter((m) => m.calendarDay === 13).map((m) => m.id).slice(0, 6));
  assert.equal(hidden.eligibleCount, 2);
  assert.equal(hidden.ids.length, 2);

  assert.deepEqual(OH.tonightPicks(night, { ...f, search: 'no such film' }, []).ids, []);
  assert.deepEqual(OH.tonightPicks(OH.localDateInfo(new Date(2026, 10, 3, 12)), f, []), { ids: [], eligibleCount: 0 });
});

test('randomizer draws from the whole filtered catalog and changes with the seed', () => {
  const f = OH.defaultFilters();
  assert.deepEqual(OH.randomPicks(f, [], 'a').ids, OH.randomPicks(f, [], 'a').ids);
  const draws = new Set();
  for (let i = 0; i < 20; i++) draws.add(OH.randomPicks(f, [], String(i)).ids.join());
  assert.ok(draws.size > 15, 'different seeds give different draws');
  const days = new Set();
  for (let i = 0; i < 20; i++) OH.randomPicks(f, [], 'd' + i).ids.forEach((id) => days.add(byId[id].calendarDay));
  assert.ok(days.size > 10, 'not limited to one night');

  const vampires = OH.randomPicks({ ...f, genres: ['vampire'] }, [], 'x');
  assert.ok(vampires.ids.every((id) => byId[id].genres.includes('vampire')));
  const watched = OH.MOVIES.filter((m) => m.genres.includes('vampire')).map((m) => m.id).slice(1);
  const one = OH.randomPicks({ ...f, genres: ['vampire'], hideWatched: true }, watched, 'x');
  assert.equal(one.ids.length, 1);
  assert.ok(!watched.includes(one.ids[0]));
});

test('zero, one, two and three eligible movies', () => {
  const movies = mini([['a', 'light'], ['b', 'moderate'], ['c', 'intense']]);
  const f = OH.defaultFilters();
  assert.deepEqual(select(movies, 's', { ...f, search: 'zzz' }).ids, []);
  assert.deepEqual(select(movies, 's', { ...f, search: 'a' }).ids, ['a']);
  assert.deepEqual(select(movies, 's', { ...f, intensities: ['light', 'moderate'] }).ids.sort(), ['a', 'b']);
  assert.deepEqual(select(movies, 's', f).ids.sort(), ['a', 'b', 'c']);
});

test('intensity mix uses available groups and never breaks filters', () => {
  const movies = mini([['l1', 'light'], ['l2', 'light'], ['m1', 'moderate'], ['m2', 'moderate'], ['i1', 'intense'], ['i2', 'intense']]);
  for (let d = 1; d <= 20; d++) {
    const ids = select(movies, OH.octoberKey(2026, d)).ids;
    assert.equal(new Set(ids.map((id) => id[0])).size, 3);
  }
  const twoGroups = mini([['l1', 'light'], ['l2', 'light'], ['l3', 'light'], ['m1', 'moderate']]);
  for (let d = 1; d <= 20; d++) {
    const ids = select(twoGroups, OH.octoberKey(2026, d)).ids;
    assert.ok(ids.includes('m1'));
    assert.equal(ids.length, 3);
  }
  const ids = select(movies, 's', { ...OH.defaultFilters(), intensities: ['light'] }).ids;
  assert.deepEqual(ids.sort(), ['l1', 'l2']);
});

// ── Dates ──

test('local date parts are used, including around UTC boundaries', () => {
  const original = process.env.TZ;
  try {
    process.env.TZ = 'America/Los_Angeles';
    let info = OH.localDateInfo(new Date('2026-10-01T05:00:00Z'));
    assert.equal(info.key, '2026-09-30');
    assert.equal(info.inOctober, false);
    info = OH.localDateInfo(new Date('2026-11-01T06:30:00Z'));
    assert.equal(info.key, '2026-10-31');
    assert.equal(info.inOctober, true);

    process.env.TZ = 'Pacific/Auckland';
    info = OH.localDateInfo(new Date('2026-09-30T12:00:00Z'));
    assert.equal(info.key, '2026-10-01');
    assert.equal(info.inOctober, true);
  } finally {
    process.env.TZ = original;
  }
  assert.equal(OH.localDateInfo(new Date(2026, 9, 1, 23, 59, 59)).key, '2026-10-01');
  assert.equal(OH.localDateInfo(new Date(2026, 9, 2, 0, 0, 0)).key, '2026-10-02');
  assert.equal(OH.localDateInfo(new Date(2026, 10, 1, 0, 0, 0)).inOctober, false);
  const nye = OH.localDateInfo(new Date(2027, 0, 1, 0, 0, 1));
  assert.equal(nye.year, 2027);
  assert.equal(OH.octoberWeekday(2026, 1), 4, 'Oct 1 2026 is a Thursday');
  assert.equal(OH.octoberWeekday(2027, 1), 5, 'Oct 1 2027 is a Friday');
});

test('seasons are partitioned by year', () => {
  const state = freshState();
  OH.setTracked(state, 2026, 'watched', 'alien-1979', true);
  assert.deepEqual(OH.getSeason(state, 2027).watchedIds, []);
  OH.setTracked(state, 2027, 'selected', 'scream-1996', true);
  OH.resetSeason(state, 2027);
  assert.deepEqual(OH.getSeason(state, 2026).watchedIds, ['alien-1979']);
  assert.ok(!state.seasons['2027']);
});

// ── Persistence ──

test('loadState handles missing, corrupt, unsupported and blocked storage', () => {
  assert.equal(OH.loadState(() => memoryStorage()).problem, null);
  assert.equal(OH.loadState(() => memoryStorage({ octoberHorror: '{not json' })).problem, 'corrupt');
  assert.equal(OH.loadState(() => memoryStorage({ octoberHorror: '[]' })).problem, 'corrupt');
  assert.equal(OH.loadState(() => memoryStorage({ octoberHorror: '{"schemaVersion":99}' })).problem, 'unsupported');
  const blocked = OH.loadState(() => { throw new Error('SecurityError'); });
  assert.equal(blocked.problem, 'unavailable');
  assert.equal(blocked.storage, null);
  const throwing = OH.loadState(() => ({ getItem() { throw new Error('denied'); } }));
  assert.equal(throwing.problem, 'unavailable');
  const full = { getItem: () => null, setItem() { throw new Error('QuotaExceededError'); } };
  assert.equal(OH.saveState(full, OH.defaultState()), false);
});

test('sanitizeState drops unknown ids, bad enums and old recommendation history', () => {
  const raw = {
    schemaVersion: 1,
    filters: { search: 42, genres: ['ghost', 'nope', 'ghost'], intensities: ['extreme', 'intense', 'intense'], hideWatched: 'yes' },
    sort: 'random',
    seasons: {
      '2026': {
        selectedIds: ['alien-1979', 'not-a-movie', 'alien-1979'],
        watchedIds: 'oops',
        days: { '2026-10-02': { activeSignature: 'sig', batches: { sig: ['alien-1979'] }, shownIds: ['scream-1996'] } }
      },
      'abcd': {}
    }
  };
  const { state, problem } = OH.sanitizeState(raw);
  assert.equal(problem, null);
  assert.deepEqual(state.filters, { search: '', genres: ['ghost'], intensities: ['intense'], hideWatched: false });
  assert.equal(state.sort, 'scheduled');
  assert.deepEqual(state.seasons, { '2026': { selectedIds: ['alien-1979'], watchedIds: [] } });
});

test('save/load round trip keeps filters and tracking; other keys untouched', () => {
  const storage = memoryStorage({ unrelated: 'keep me' });
  let { state } = OH.loadState(() => storage);
  OH.setTracked(state, 2026, 'selected', 'alien-1979', true);
  OH.setTracked(state, 2026, 'watched', 'scream-1996', true);
  state.filters = OH.normalizeFilters({ search: 'night' });
  assert.ok(OH.saveState(storage, state));
  state = OH.loadState(() => storage).state;
  assert.equal(state.filters.search, 'night');
  assert.deepEqual(OH.getSeason(state, 2026), { selectedIds: ['alien-1979'], watchedIds: ['scream-1996'] });
  assert.equal(storage.data.unrelated, 'keep me');
  assert.deepEqual(Object.keys(storage.data).sort(), ['octoberHorror', 'unrelated']);
});

test('resetSeason clears only that season and restores filter/sort defaults', () => {
  const state = freshState();
  OH.setTracked(state, 2025, 'watched', 'alien-1979', true);
  OH.setTracked(state, 2026, 'watched', 'alien-1979', true);
  state.filters = OH.normalizeFilters({ search: 'x', hideWatched: true });
  state.sort = 'year';
  OH.resetSeason(state, 2026);
  assert.deepEqual(Object.keys(state.seasons), ['2025']);
  assert.deepEqual(state.filters, OH.defaultFilters());
  assert.equal(state.sort, 'scheduled');
});

test('PRNG and shuffle are deterministic', () => {
  const r1 = OH.mulberry32(OH.hashString('seed'));
  const r2 = OH.mulberry32(OH.hashString('seed'));
  for (let i = 0; i < 5; i++) assert.equal(r1(), r2());
  assert.deepEqual(OH.seededShuffle(['c', 'a', 'b'], OH.mulberry32(1)), OH.seededShuffle(['b', 'c', 'a'], OH.mulberry32(1)));
});

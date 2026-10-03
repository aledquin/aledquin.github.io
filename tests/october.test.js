// Dependency-free tests for js/october.js + october/movies.json.
// Run with: node --test tests/october.test.js
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const catalog = require('../october/movies.json');
const OH = require('../js/october.js');

OH.loadCatalog(catalog);

function freshState() {
  return OH.defaultState();
}

function october(year, day) {
  return OH.localDateInfo(new Date(year, 9, day, 20, 0, 0));
}

function mini(specs) {
  return specs.map(([id, intensity]) => ({
    id, title: id, year: 2000, calendarDay: 1, dayOrder: 1, intensity, genres: [], blurb: '', aliases: []
  }));
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

function memoryStorage(initial) {
  const data = Object.assign({}, initial);
  return {
    data,
    getItem: (k) => (k in data ? data[k] : null),
    setItem: (k, v) => { data[k] = String(v); },
    removeItem: (k) => { delete data[k]; }
  };
}

const byId = Object.fromEntries(OH.MOVIES.map((m) => [m.id, m]));

// ── Catalog JSON ──

test('movies.json loads as the catalog: 279 films, 9 per day', () => {
  assert.equal(catalog.totalMovies, 279);
  assert.equal(OH.MOVIES.length, 279);
  assert.equal(OH.CATALOG_VERSION, 'october-279-v2');
  assert.equal(OH.FILMS_PER_DAY, 9);
  const perDay = {};
  OH.MOVIES.forEach((m) => { perDay[m.calendarDay] = (perDay[m.calendarDay] || 0) + 1; });
  assert.equal(Object.keys(perDay).length, 31);
  Object.values(perDay).forEach((n) => assert.equal(n, 9));
});

test('identities are unique and enums valid', () => {
  const ids = new Set();
  OH.MOVIES.forEach((m) => {
    assert.match(m.id, /^[a-z0-9-]+$/);
    assert.ok(!ids.has(m.id), 'duplicate id ' + m.id);
    ids.add(m.id);
    assert.ok(OH.INTENSITIES.includes(m.intensity));
    assert.ok(m.calendarDay >= 1 && m.calendarDay <= 31);
  });
  assert.equal(ids.size, 279);
});

test('October 22 has The Monster (2016); Coraline replaces The Haunted Mansion', () => {
  const day22 = OH.MOVIES.filter((m) => m.calendarDay === 22).map((m) => `${m.title} (${m.year})`);
  assert.ok(day22.includes('The Monster (2016)'));
  assert.ok(OH.MOVIES.some((m) => m.id === 'coraline-2009'));
  assert.equal(OH.MOVIES.filter((m) => m.title === 'The Haunted Mansion').length, 0);
});

test('aliases support search (Hausu → House 1977)', () => {
  const hits = OH.filterMovies(OH.MOVIES, { ...OH.defaultFilters(), search: 'hausu' }, []);
  assert.deepEqual(hits.map((m) => m.id), ['house-1977']);
});

// ── Reference links ──

test('catalog search URLs are used; RT movie pages count as direct when allowed', () => {
  const sleepy = byId['sleepy-hollow-1999'];
  const links = OH.referenceLinks(sleepy);
  assert.equal(links.imdb.direct, false);
  assert.ok(links.imdb.href.includes('imdb.com/find'));
  assert.equal(links.rt.direct, false);

  const cronos = byId['cronos-1993'];
  const c = OH.referenceLinks(cronos);
  assert.equal(c.rt.direct, true);
  assert.equal(c.rt.href, 'https://www.rottentomatoes.com/m/cronos');
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
    'javascript:alert(1)'
  ].forEach((url) => assert.equal(OH.isAllowedReferenceUrl(url, 'imdb'), false, url));
});

// ── Filters & signatures ──

test('filters: case/accent-insensitive search, genres, intensity, hide watched', () => {
  const f = OH.defaultFilters();
  assert.equal(OH.filterMovies(OH.MOVIES, f, []).length, 279);
  assert.deepEqual(f.genres, []);
  assert.deepEqual(OH.filterMovies(OH.MOVIES, { ...f, search: '  CORALINE ' }, []).map((m) => m.id), ['coraline-2009']);
  const ghost = OH.filterMovies(OH.MOVIES, { ...f, genres: ['ghost'] }, []);
  assert.ok(ghost.length > 0);
  assert.ok(ghost.every((m) => m.genres.includes('ghost')));
  const intenseOnly = OH.filterMovies(OH.MOVIES, { ...f, intensities: ['intense'] }, []);
  assert.equal(intenseOnly.length, OH.MOVIES.filter((m) => m.intensity === 'intense').length);
  const hidden = OH.filterMovies(OH.MOVIES, { ...f, hideWatched: true }, ['alien-1979']);
  assert.equal(hidden.length, 278);
});

test('most catalog titles keep editorial blurbs and genre tags in Details data', () => {
  const withBlurb = OH.MOVIES.filter((m) => m.blurb);
  const withGenres = OH.MOVIES.filter((m) => m.genres.length);
  assert.ok(withBlurb.length >= 240, 'expected blurbs on carried-over titles, got ' + withBlurb.length);
  assert.ok(withGenres.length >= 240, 'expected genres on carried-over titles, got ' + withGenres.length);
  const sleepy = byId['sleepy-hollow-1999'];
  assert.match(sleepy.blurb, /headless horseman/i);
  assert.deepEqual(sleepy.genres, ['gothic', 'supernatural']);
});

test('legacy maxIntensity filters are converted to intensity selections', () => {
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'light' }).intensities, ['light']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'moderate' }).intensities, ['light', 'moderate']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'intense' }).intensities, []);
});

test('signature is canonical and only includes watched IDs when Hide watched is on', () => {
  const a = OH.filterSignature({ search: ' Ghost ', intensities: ['moderate', 'light'], hideWatched: false }, ['b', 'a'], 'v1');
  const b = OH.filterSignature({ search: 'ghost', intensities: ['light', 'moderate'], hideWatched: false }, [], 'v1');
  assert.equal(a, b);
  const all = OH.filterSignature({ ...OH.defaultFilters(), intensities: ['intense', 'light', 'moderate'] }, [], 'v1');
  assert.equal(all, OH.filterSignature(OH.defaultFilters(), [], 'v1'));
  const c = OH.filterSignature({ ...OH.defaultFilters(), hideWatched: true }, ['b', 'a'], 'v1');
  assert.deepEqual(JSON.parse(c).w, ['a', 'b']);
});

// ── Selection ──

test('identical inputs give identical picks; input order does not matter', () => {
  const one = select(OH.MOVIES, 'seed-1');
  const two = select(OH.MOVIES.slice().reverse(), 'seed-1');
  assert.deepEqual(one.ids, two.ids);
  assert.equal(new Set(one.ids).size, 3);
});

test('tonight’s picks come from that night’s calendar and mix intensities', () => {
  for (let day = 1; day <= 31; day++) {
    const result = OH.tonightPicks(october(2026, day), OH.defaultFilters(), []);
    assert.equal(result.ids.length, 3);
    assert.equal(result.eligibleCount, 9);
    result.ids.forEach((id) => assert.equal(byId[id].calendarDay, day));
    const levels = new Set(result.ids.map((id) => byId[id].intensity));
    const available = new Set(OH.MOVIES.filter((m) => m.calendarDay === day).map((m) => m.intensity));
    assert.equal(levels.size, Math.min(3, available.size));
  }
});

test('tonight’s picks are stable for a date and follow the filters', () => {
  const morning = OH.localDateInfo(new Date(2026, 9, 13, 8));
  const night = OH.localDateInfo(new Date(2026, 9, 13, 23, 30));
  const f = OH.defaultFilters();
  assert.deepEqual(OH.tonightPicks(morning, f, []).ids, OH.tonightPicks(night, f, []).ids);
  const intense = OH.tonightPicks(night, { ...f, intensities: ['intense'] }, []);
  assert.ok(intense.ids.every((id) => byId[id].calendarDay === 13 && byId[id].intensity === 'intense'));
  assert.deepEqual(OH.tonightPicks(OH.localDateInfo(new Date(2026, 10, 3, 12)), f, []), { ids: [], eligibleCount: 0 });
});

test('randomizer draws from the whole filtered catalog and changes with the seed', () => {
  const f = OH.defaultFilters();
  assert.deepEqual(OH.randomPicks(f, [], 'a').ids, OH.randomPicks(f, [], 'a').ids);
  const draws = new Set();
  for (let i = 0; i < 20; i++) draws.add(OH.randomPicks(f, [], String(i)).ids.join());
  assert.ok(draws.size > 15);
  const mexico = OH.randomPicks({ ...f, search: 'mexico' }, [], 'x');
  assert.ok(mexico.ids.length >= 1);
  assert.ok(mexico.ids.every((id) => /mexico/i.test(byId[id].culturalFocus || '')));
});

test('zero, one, two and three eligible movies', () => {
  const movies = mini([['a', 'light'], ['b', 'moderate'], ['c', 'intense']]);
  const f = OH.defaultFilters();
  assert.deepEqual(select(movies, 's', { ...f, search: 'zzz' }).ids, []);
  assert.deepEqual(select(movies, 's', { ...f, search: 'a' }).ids, ['a']);
  assert.deepEqual(select(movies, 's', f).ids.sort(), ['a', 'b', 'c']);
});

test('intensity mix uses available groups and never breaks filters', () => {
  const movies = mini([['l1', 'light'], ['l2', 'light'], ['m1', 'moderate'], ['m2', 'moderate'], ['i1', 'intense'], ['i2', 'intense']]);
  for (let d = 1; d <= 20; d++) {
    const ids = select(movies, OH.octoberKey(2026, d)).ids;
    assert.equal(new Set(ids.map((id) => id[0])).size, 3);
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
    process.env.TZ = 'Pacific/Auckland';
    info = OH.localDateInfo(new Date('2026-09-30T12:00:00Z'));
    assert.equal(info.key, '2026-10-01');
    assert.equal(info.inOctober, true);
  } finally {
    process.env.TZ = original;
  }
  assert.equal(OH.octoberWeekday(2026, 1), 4);
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
  assert.equal(OH.loadState(() => memoryStorage({ octoberHorror: '{"schemaVersion":99}' })).problem, 'unsupported');
  const blocked = OH.loadState(() => { throw new Error('SecurityError'); });
  assert.equal(blocked.problem, 'unavailable');
});

test('sanitizeState drops unknown ids and keeps valid genre filters', () => {
  const raw = {
    schemaVersion: 1,
    filters: { search: 42, genres: ['ghost', 'not-a-genre'], intensities: ['extreme', 'intense'], hideWatched: 'yes' },
    sort: 'random',
    seasons: {
      '2026': {
        selectedIds: ['alien-1979', 'not-a-movie', 'alien-1979'],
        watchedIds: 'oops',
        days: { '2026-10-02': { batches: { sig: ['alien-1979'] } } }
      }
    }
  };
  const { state, problem } = OH.sanitizeState(raw);
  assert.equal(problem, null);
  assert.deepEqual(state.filters, { search: '', genres: ['ghost'], intensities: ['intense'], hideWatched: false });
  assert.deepEqual(state.seasons, { '2026': { selectedIds: ['alien-1979'], watchedIds: [] } });
});

test('save/load round trip keeps filters and tracking', () => {
  const storage = memoryStorage({ unrelated: 'keep me' });
  let { state } = OH.loadState(() => storage);
  OH.setTracked(state, 2026, 'selected', 'alien-1979', true);
  state.filters = OH.normalizeFilters({ search: 'night' });
  assert.ok(OH.saveState(storage, state));
  state = OH.loadState(() => storage).state;
  assert.equal(state.filters.search, 'night');
  assert.deepEqual(OH.getSeason(state, 2026).selectedIds, ['alien-1979']);
  assert.equal(storage.data.unrelated, 'keep me');
});

test('save files round trip all seasons and filters', () => {
  const state = freshState();
  OH.setTracked(state, 2025, 'watched', 'alien-1979', true);
  OH.setTracked(state, 2026, 'selected', 'scream-1996', true);
  state.filters = OH.normalizeFilters({ genres: ['ghost'], hideWatched: true });
  state.sort = 'year';
  const text = OH.exportState(state, '2026-10-02T20:00:00.000Z');
  assert.equal(JSON.parse(text).format, 'october-horror-save');
  const { state: loaded, problem } = OH.importState(text);
  assert.equal(problem, null);
  assert.deepEqual(loaded.seasons, state.seasons);
  assert.deepEqual(loaded.filters, state.filters);
  assert.equal(loaded.sort, 'year');
});

test('importState rejects non-saves, bad JSON, old versions and oversized files', () => {
  assert.equal(OH.importState('').problem, 'notASave');
  assert.equal(OH.importState('{oops').problem, 'corrupt');
  assert.equal(OH.importState(JSON.stringify(freshState())).problem, 'notASave');
  assert.equal(OH.importState(JSON.stringify({ format: 'october-horror-save', state: { schemaVersion: 99 } })).problem, 'unsupported');
  assert.equal(OH.importState('x'.repeat(OH.MAX_SAVE_BYTES + 1)).problem, 'tooLarge');
  const tampered = JSON.stringify({
    format: 'october-horror-save',
    state: { schemaVersion: 1, seasons: { '2026': { selectedIds: ['not-a-movie', 'alien-1979'] }, evil: {} } }
  });
  assert.deepEqual(OH.importState(tampered).state.seasons, { '2026': { selectedIds: ['alien-1979'], watchedIds: [] } });
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

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
    id, title: id, year: 2000, calendarDay: 1, dayOrder: 1, intensity, genres: [], blurb: '', aliases: [],
    streamingOffers: []
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
const SAMPLE_ID = 'beetlejuice-1988';
const SAMPLE_ID_2 = 'get-out-2017';

// ── Catalog JSON ──

test('movies.json loads the complete matrix: 124 films, 4 every day', () => {
  assert.equal(catalog.totalMovies, 124);
  assert.equal(OH.MOVIES.length, 124);
  assert.equal(OH.CATALOG_VERSION, 'october-horror-complete-matrix-v1');
  assert.equal(OH.FILMS_PER_DAY, 4);
  assert.equal(OH.PICK_COUNT, 4);
  const perDay = {};
  OH.MOVIES.forEach((m) => { perDay[m.calendarDay] = (perDay[m.calendarDay] || 0) + 1; });
  assert.equal(Object.keys(perDay).length, 31);
  Object.entries(perDay).forEach(([day, n]) => assert.equal(n, 4, 'day ' + day));
});

test('streaming services and four-track labels are present', () => {
  assert.deepEqual(OH.STREAMING_SERVICES.slice().sort(), ['Amazon Prime Video', 'Hulu', 'Netflix']);
  assert.deepEqual(OH.GENRES.slice(), []);
  const beetlejuice = byId[SAMPLE_ID];
  assert.equal(beetlejuice.calendarDay, 1);
  assert.equal(beetlejuice.dayOrder, 1);
  assert.equal(beetlejuice.track, 'Light / Fun');
  assert.deepEqual(beetlejuice.streamingOffers.map((o) => o.service), ['Netflix']);
  assert.equal(byId['barbarian-2022'].track, 'Intense / Disturbing');
});

test('identities are unique and enums valid', () => {
  const ids = new Set();
  OH.MOVIES.forEach((m) => {
    assert.match(m.id, /^[a-z0-9-]+$/);
    assert.ok(!ids.has(m.id), 'duplicate id ' + m.id);
    ids.add(m.id);
    assert.ok(OH.INTENSITIES.includes(m.intensity));
    assert.ok(m.calendarDay >= 1 && m.calendarDay <= 31);
    assert.ok(m.streamingOffers.length >= 1);
    assert.ok(m.track);
  });
  assert.equal(ids.size, 124);
});

test('October 1 opens with Beetlejuice and closes with Barbarian', () => {
  const day1 = OH.MOVIES.filter((m) => m.calendarDay === 1).map((m) => m.id);
  assert.deepEqual(day1, [
    'beetlejuice-1988',
    'get-out-2017',
    'it-follows-2014',
    'barbarian-2022'
  ]);
});

test('Halloween night includes Killer Klowns and Hereditary', () => {
  const day31 = OH.MOVIES.filter((m) => m.calendarDay === 31).map((m) => `${m.title} (${m.year})`);
  assert.ok(day31.includes('Killer Klowns from Outer Space (1988)'));
  assert.ok(day31.includes('Hereditary (2018)'));
});

// ── Reference & streaming links ──

test('catalog search URLs are used; missing watch URLs produce no streaming links', () => {
  const beetlejuice = byId[SAMPLE_ID];
  const links = OH.referenceLinks(beetlejuice);
  assert.equal(links.imdb.direct, false);
  assert.ok(links.imdb.href.includes('imdb.com/find'));
  assert.deepEqual(OH.streamingLinks(beetlejuice), []);
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

test('streaming watch URLs are only accepted for known service hosts over HTTPS', () => {
  assert.ok(OH.isAllowedStreamingUrl('https://www.netflix.com/title/290533', 'Netflix'));
  assert.ok(OH.isAllowedStreamingUrl('https://www.hulu.com/movie/barbarian', 'Hulu'));
  assert.ok(OH.isAllowedStreamingUrl('https://www.amazon.com/dp/B0CG7JCWP4', 'Amazon Prime Video'));
  assert.equal(OH.isAllowedStreamingUrl('https://evil.example/netflix', 'Netflix'), false);
  assert.equal(OH.isAllowedStreamingUrl('http://www.netflix.com/title/1', 'Netflix'), false);
  assert.equal(OH.isAllowedStreamingUrl('https://www.netflix.com/title/1', 'Hulu'), false);
});

// ── Filters & signatures ──

test('filters: search, intensity, streaming service, hide watched', () => {
  const f = OH.defaultFilters();
  assert.equal(OH.filterMovies(OH.MOVIES, f, []).length, 124);
  assert.deepEqual(f.genres, []);
  assert.deepEqual(f.services, []);
  assert.deepEqual(OH.filterMovies(OH.MOVIES, { ...f, search: '  BEETLEJUICE ' }, []).map((m) => m.id), [SAMPLE_ID]);
  const netflix = OH.filterMovies(OH.MOVIES, { ...f, services: ['Netflix'] }, []);
  assert.ok(netflix.length > 0);
  assert.ok(netflix.every((m) => m.streamingOffers.some((o) => o.service === 'Netflix')));
  assert.ok(OH.filterMovies(OH.MOVIES, { ...f, search: 'hulu' }, []).every((m) =>
    m.streamingOffers.some((o) => o.service === 'Hulu')));
  const intenseOnly = OH.filterMovies(OH.MOVIES, { ...f, intensities: ['intense'] }, []);
  assert.equal(intenseOnly.length, OH.MOVIES.filter((m) => m.intensity === 'intense').length);
  const hidden = OH.filterMovies(OH.MOVIES, { ...f, hideWatched: true }, [SAMPLE_ID]);
  assert.equal(hidden.length, 123);
});

test('each calendar night uses the four-track theme and shows all four as top picks', () => {
  for (let day = 1; day <= 31; day++) {
    assert.equal(OH.dayTheme(day), 'Light · creepy · atmospheric · intense');
  }
  const day1 = OH.MOVIES.filter((m) => m.calendarDay === 1).map((m) => m.id);
  const split = OH.splitDayMovies(day1);
  assert.deepEqual(split.topIds, day1);
  assert.deepEqual(split.moreIds, []);
  assert.equal(split.topIds.length, 4);
});

test('every catalog title has a blurb, track, and streaming service', () => {
  const missingBlurb = OH.MOVIES.filter((m) => !m.blurb).map((m) => m.id);
  const missingTrack = OH.MOVIES.filter((m) => !m.track).map((m) => m.id);
  const missingStream = OH.MOVIES.filter((m) => !m.streamingOffers.length).map((m) => m.id);
  assert.deepEqual(missingBlurb, []);
  assert.deepEqual(missingTrack, []);
  assert.deepEqual(missingStream, []);
  assert.match(byId[SAMPLE_ID].blurb, /bio-exorcist|newly dead/i);
});

test('legacy maxIntensity filters are converted to intensity selections', () => {
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'light' }).intensities, ['light']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'moderate' }).intensities, ['light', 'moderate']);
  assert.deepEqual(OH.normalizeFilters({ maxIntensity: 'intense' }).intensities, []);
});

test('signature is canonical and includes streaming services', () => {
  const a = OH.filterSignature({
    search: ' Ghost ',
    intensities: ['moderate', 'light'],
    services: ['Hulu', 'Netflix'],
    hideWatched: false
  }, ['b', 'a'], 'v1');
  const b = OH.filterSignature({
    search: 'ghost',
    intensities: ['light', 'moderate'],
    services: ['Netflix', 'Hulu'],
    hideWatched: false
  }, [], 'v1');
  assert.equal(a, b);
  const all = OH.filterSignature({ ...OH.defaultFilters(), intensities: ['intense', 'light', 'moderate'] }, [], 'v1');
  assert.equal(all, OH.filterSignature(OH.defaultFilters(), [], 'v1'));
  const c = OH.filterSignature({ ...OH.defaultFilters(), hideWatched: true }, ['b', 'a'], 'v1');
  assert.deepEqual(JSON.parse(c).w, ['a', 'b']);
  assert.deepEqual(JSON.parse(a).s, ['Hulu', 'Netflix']);
});

// ── Selection ──

test('identical inputs give identical picks; input order does not matter', () => {
  const one = select(OH.MOVIES, 'seed-1');
  const two = select(OH.MOVIES.slice().reverse(), 'seed-1');
  assert.deepEqual(one.ids, two.ids);
  assert.equal(new Set(one.ids).size, 4);
});

test('tonight’s picks come from that night’s calendar and mix intensities', () => {
  for (let day = 1; day <= 31; day++) {
    const result = OH.tonightPicks(october(2026, day), OH.defaultFilters(), []);
    assert.equal(result.ids.length, 4);
    assert.equal(result.eligibleCount, 4);
    result.ids.forEach((id) => assert.equal(byId[id].calendarDay, day));
    const levels = new Set(result.ids.map((id) => byId[id].intensity));
    const available = new Set(OH.MOVIES.filter((m) => m.calendarDay === day).map((m) => m.intensity));
    assert.equal(levels.size, Math.min(3, available.size));
  }
});

test('tonight’s picks are stable for a date and follow the filters', () => {
  const morning = OH.localDateInfo(new Date(2026, 9, 1, 8));
  const night = OH.localDateInfo(new Date(2026, 9, 1, 23, 30));
  const f = OH.defaultFilters();
  assert.deepEqual(OH.tonightPicks(morning, f, []).ids, OH.tonightPicks(night, f, []).ids);
  const netflix = OH.tonightPicks(night, { ...f, services: ['Netflix'] }, []);
  assert.ok(netflix.ids.every((id) =>
    byId[id].calendarDay === 1 && byId[id].streamingOffers.some((o) => o.service === 'Netflix')));
  assert.deepEqual(OH.tonightPicks(OH.localDateInfo(new Date(2026, 10, 3, 12)), f, []), { ids: [], eligibleCount: 0 });
});

test('randomizer draws from the whole filtered catalog and changes with the seed', () => {
  const f = OH.defaultFilters();
  assert.deepEqual(OH.randomPicks(f, [], 'a').ids, OH.randomPicks(f, [], 'a').ids);
  const draws = new Set();
  for (let i = 0; i < 20; i++) draws.add(OH.randomPicks(f, [], String(i)).ids.join());
  assert.ok(draws.size > 10);
  const hulu = OH.randomPicks({ ...f, services: ['Hulu'] }, [], 'x');
  assert.ok(hulu.ids.length >= 1);
  assert.ok(hulu.ids.every((id) => byId[id].streamingOffers.some((o) => o.service === 'Hulu')));
});

test('zero, one, two and four eligible movies', () => {
  const movies = mini([
    ['a', 'light'], ['b', 'moderate'], ['c', 'intense'], ['d', 'light']
  ]);
  const f = OH.defaultFilters();
  assert.deepEqual(select(movies, 's', { ...f, search: 'zzz' }).ids, []);
  assert.deepEqual(select(movies, 's', { ...f, search: 'a' }).ids, ['a']);
  assert.deepEqual(select(movies, 's', f).ids.sort(), ['a', 'b', 'c', 'd']);
});

test('intensity mix uses available groups and never breaks filters', () => {
  const movies = mini([
    ['l1', 'light'], ['l2', 'light'], ['m1', 'moderate'], ['m2', 'moderate'], ['i1', 'intense'], ['i2', 'intense']
  ]);
  for (let d = 1; d <= 20; d++) {
    const ids = select(movies, OH.octoberKey(2026, d)).ids;
    assert.equal(ids.length, 4);
    assert.ok(new Set(ids.map((id) => id[0])).size >= 3);
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
  OH.setTracked(state, 2026, 'watched', SAMPLE_ID, true);
  assert.deepEqual(OH.getSeason(state, 2027).watchedIds, []);
  OH.setTracked(state, 2027, 'selected', SAMPLE_ID_2, true);
  OH.resetSeason(state, 2027);
  assert.deepEqual(OH.getSeason(state, 2026).watchedIds, [SAMPLE_ID]);
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

test('sanitizeState drops unknown ids and keeps valid service filters', () => {
  const raw = {
    schemaVersion: 1,
    filters: {
      search: 42,
      genres: ['horror', 'not-a-genre'],
      intensities: ['extreme', 'intense'],
      services: ['Netflix', 'Disney+'],
      hideWatched: 'yes'
    },
    sort: 'random',
    seasons: {
      '2026': {
        selectedIds: [SAMPLE_ID, 'not-a-movie', SAMPLE_ID],
        watchedIds: 'oops',
        days: { '2026-10-01': { batches: { sig: [SAMPLE_ID] } } }
      }
    }
  };
  const { state, problem } = OH.sanitizeState(raw);
  assert.equal(problem, null);
  assert.deepEqual(state.filters, {
    search: '',
    genres: [],
    intensities: ['intense'],
    services: ['Netflix'],
    hideWatched: false
  });
  assert.deepEqual(state.seasons, { '2026': { selectedIds: [SAMPLE_ID], watchedIds: [] } });
});

test('save/load round trip keeps filters and tracking', () => {
  const storage = memoryStorage({ unrelated: 'keep me' });
  let { state } = OH.loadState(() => storage);
  OH.setTracked(state, 2026, 'selected', SAMPLE_ID, true);
  state.filters = OH.normalizeFilters({ search: 'night', services: ['Hulu'] });
  assert.ok(OH.saveState(storage, state));
  state = OH.loadState(() => storage).state;
  assert.equal(state.filters.search, 'night');
  assert.deepEqual(state.filters.services, ['Hulu']);
  assert.deepEqual(OH.getSeason(state, 2026).selectedIds, [SAMPLE_ID]);
  assert.equal(storage.data.unrelated, 'keep me');
});

test('save files round trip all seasons and filters', () => {
  const state = freshState();
  OH.setTracked(state, 2025, 'watched', SAMPLE_ID, true);
  OH.setTracked(state, 2026, 'selected', SAMPLE_ID_2, true);
  state.filters = OH.normalizeFilters({ services: ['Netflix'], hideWatched: true });
  state.sort = 'year';
  const text = OH.exportState(state, '2026-10-03T20:00:00.000Z');
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
    state: { schemaVersion: 1, seasons: { '2026': { selectedIds: ['not-a-movie', SAMPLE_ID] }, evil: {} } }
  });
  assert.deepEqual(OH.importState(tampered).state.seasons, { '2026': { selectedIds: [SAMPLE_ID], watchedIds: [] } });
});

test('resetSeason clears only that season and restores filter/sort defaults', () => {
  const state = freshState();
  OH.setTracked(state, 2025, 'watched', SAMPLE_ID, true);
  OH.setTracked(state, 2026, 'watched', SAMPLE_ID, true);
  state.filters = OH.normalizeFilters({ search: 'x', services: ['Netflix'], hideWatched: true });
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

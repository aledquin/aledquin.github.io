/* October Horror — catalog loader and page logic.
   Classic script. Movie data lives in october/movies.json (fetched at runtime).
   Optional deps.catalog / deps.catalogUrl let tests supply data without fetch. */

(function (global) {
  'use strict';

  var STORAGE_KEY = 'octoberHorror';
  var SCHEMA_VERSION = 1;
  var PICK_COUNT = 4;
  var MAX_SEARCH_LENGTH = 100;
  var DEFAULT_CATALOG_URL = 'movies.json';

  // Replaced from catalog metadata when movies.json loads.
  var GENRES = [];
  var TRACKS = [
    'Light / Fun',
    'Creepy / Moderate',
    'Atmospheric Suspense',
    'Intense / Disturbing'
  ];
  var STREAMING_SERVICES = ['Amazon Prime Video', 'Hulu', 'Netflix'];
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

  // Night themes come from movies.json (dayThemes) when present; fallback is the four-track frame.
  var DAY_THEMES = {};
  var DEFAULT_DAY_THEME = 'Light · creepy · atmospheric · intense';
  for (var themeDay = 1; themeDay <= 31; themeDay++) DAY_THEMES[themeDay] = DEFAULT_DAY_THEME;

  var MOVIES = [];
  var ORDER = {};
  var MOVIE_BY_ID = {};
  var CATALOG = null;
  var catalogMeta = { version: '', filmsPerDay: 0 };

  function dayTheme(day) {
    return DAY_THEMES[day] || DEFAULT_DAY_THEME;
  }

  // Split a night's filtered ids into editorial top picks (schedule order) and the rest.
  function splitDayMovies(ids) {
    var list = (ids || []).slice();
    return {
      topIds: list.slice(0, PICK_COUNT),
      moreIds: list.slice(PICK_COUNT)
    };
  }

  function slugifyGenre(value) {
    return String(value || '')
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  function normalizeStreamingOffer(raw) {
    if (!raw || typeof raw !== 'object') return null;
    var service = typeof raw.service === 'string' ? raw.service.trim() : '';
    if (!service) return null;
    return {
      service: service,
      region: typeof raw.region === 'string' ? raw.region : null,
      accessType: typeof raw.accessType === 'string' ? raw.accessType : null,
      includedWithExistingSubscription: !!raw.includedWithExistingSubscription,
      watchUrl: typeof raw.watchUrl === 'string' ? raw.watchUrl : null
    };
  }

  function normalizeMovie(raw, index) {
    var refs = raw && raw.references ? raw.references : {};
    var imdb = refs.imdb || {};
    var rt = refs.rottenTomatoes || {};
    var reception = raw && raw.reception ? raw.reception : {};
    var calendarDay = Number(raw.calendarDay);
    if ((!calendarDay || calendarDay < 1) && typeof raw.scheduledDate === 'string') {
      var parts = raw.scheduledDate.split('-');
      if (parts.length === 3) calendarDay = Number(parts[2]);
    }
    var dayOrder = Number(raw.dayOrder);
    if (!dayOrder && raw.dailyTrack != null) dayOrder = Number(raw.dailyTrack);
    var offers = Array.isArray(raw.streamingOffers)
      ? raw.streamingOffers.map(normalizeStreamingOffer).filter(Boolean)
      : [];
    var genres = Array.isArray(raw.genres)
      ? uniqueStrings(raw.genres.map(slugifyGenre).filter(Boolean))
      : [];
    return {
      id: String(raw.id || ''),
      title: String(raw.title || ''),
      aliases: Array.isArray(raw.aliases) ? raw.aliases.filter(function (a) { return typeof a === 'string'; }) : [],
      year: Number(raw.year) || 0,
      version: raw.versionLabel || raw.version || null,
      calendarDay: calendarDay || 0,
      dayOrder: dayOrder || (index + 1),
      scheduledDate: typeof raw.scheduledDate === 'string' ? raw.scheduledDate : null,
      intensity: INTENSITIES.indexOf(raw.intensity) !== -1 ? raw.intensity : 'moderate',
      genres: genres,
      culturalFocus: typeof raw.culturalFocus === 'string' ? raw.culturalFocus : null,
      viewingNote: typeof raw.viewingNote === 'string' && raw.viewingNote ? raw.viewingNote : null,
      blurb: typeof raw.blurb === 'string' ? raw.blurb : '',
      imdbUrl: typeof imdb.url === 'string' ? imdb.url : null,
      imdbType: imdb.type === 'movie' || imdb.type === 'title' ? 'direct' : 'search',
      rottenTomatoesUrl: typeof rt.url === 'string' ? rt.url : null,
      rtType: rt.type === 'movie' ? 'direct' : 'search',
      streamingOffers: offers,
      eligibilityStatus: typeof raw.eligibilityStatus === 'string' ? raw.eligibilityStatus : null,
      track: typeof raw.track === 'string' && raw.track ? raw.track : null,
      reception: {
        status: reception.status || 'unreviewed',
        criticPercent: typeof reception.criticPercent === 'number' ? reception.criticPercent : null,
        criticReviewCount: typeof reception.criticReviewCount === 'number' ? reception.criticReviewCount : null,
        source: reception.source || null,
        label: typeof reception.label === 'string' ? reception.label
          : (typeof raw.criticalReception === 'string' ? raw.criticalReception : null)
      }
    };
  }

  function replaceStringList(target, values) {
    target.length = 0;
    uniqueStrings(values || []).forEach(function (value) { target.push(value); });
  }

  function loadCatalog(raw) {
    if (!raw || typeof raw !== 'object' || !Array.isArray(raw.movies)) {
      throw new Error('Invalid October Horror catalog');
    }
    CATALOG = raw;
    catalogMeta.version = typeof raw.catalogVersion === 'string' ? raw.catalogVersion : 'october-json';
    catalogMeta.filmsPerDay = raw.calendar && Number(raw.calendar.moviesPerDay) || 0;
    if (raw.intensityLegend) {
      INTENSITIES.forEach(function (level) {
        if (typeof raw.intensityLegend[level] === 'string') INTENSITY_LABELS[level] = raw.intensityLegend[level];
      });
    }
    if (raw.dayThemes && typeof raw.dayThemes === 'object') {
      for (var d = 1; d <= 31; d++) {
        var key = String(d);
        if (typeof raw.dayThemes[key] === 'string' && raw.dayThemes[key]) DAY_THEMES[d] = raw.dayThemes[key];
        else if (typeof raw.dayThemes[d] === 'string' && raw.dayThemes[d]) DAY_THEMES[d] = raw.dayThemes[d];
      }
    }
    var normalized = raw.movies.map(normalizeMovie).filter(function (m) {
      return m.id && m.title && m.year && m.calendarDay >= 1 && m.calendarDay <= 31;
    });
    normalized.sort(function (a, b) {
      return a.calendarDay - b.calendarDay || a.dayOrder - b.dayOrder;
    });
    if (!catalogMeta.filmsPerDay) {
      var counts = {};
      normalized.forEach(function (m) { counts[m.calendarDay] = (counts[m.calendarDay] || 0) + 1; });
      catalogMeta.filmsPerDay = Math.max.apply(null, Object.keys(counts).map(function (k) { return counts[k]; }).concat([0]));
    }
    if (catalogMeta.filmsPerDay > 0) PICK_COUNT = catalogMeta.filmsPerDay;

    var genreSource = Array.isArray(raw.genreTaxonomy)
      ? raw.genreTaxonomy.map(slugifyGenre)
      : normalized.reduce(function (all, movie) { return all.concat(movie.genres); }, []);
    replaceStringList(GENRES, genreSource);

    var trackSource = raw.calendar && Array.isArray(raw.calendar.tracks) && raw.calendar.tracks.length
      ? raw.calendar.tracks
      : normalized.map(function (movie) { return movie.track; }).filter(Boolean);
    replaceStringList(TRACKS, trackSource);

    var serviceSource = Array.isArray(raw.streamingServices) && raw.streamingServices.length
      ? raw.streamingServices
      : normalized.reduce(function (all, movie) {
        return all.concat(movie.streamingOffers.map(function (offer) { return offer.service; }));
      }, []);
    replaceStringList(STREAMING_SERVICES, serviceSource);

    MOVIES.length = 0;
    Object.keys(ORDER).forEach(function (k) { delete ORDER[k]; });
    Object.keys(MOVIE_BY_ID).forEach(function (k) { delete MOVIE_BY_ID[k]; });
    normalized.forEach(function (movie, index) {
      movie.genres = movie.genres.filter(function (g) { return GENRES.indexOf(g) !== -1; });
      MOVIES.push(movie);
      ORDER[movie.id] = index;
      MOVIE_BY_ID[movie.id] = movie;
    });
    return {
      catalogVersion: catalogMeta.version,
      filmsPerDay: catalogMeta.filmsPerDay,
      movies: MOVIES
    };
  }

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
    return { search: '', genres: [], tracks: [], intensities: [], services: [], hideWatched: false };
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
      filters.genres = uniqueStrings(raw.genres.map(slugifyGenre)).filter(function (g) { return GENRES.indexOf(g) !== -1; });
    }
    if (Array.isArray(raw.tracks)) {
      filters.tracks = uniqueStrings(raw.tracks).filter(function (track) { return TRACKS.indexOf(track) !== -1; });
    }
    if (Array.isArray(raw.intensities)) {
      filters.intensities = INTENSITIES.filter(function (level) { return raw.intensities.indexOf(level) !== -1; });
    } else if (raw.maxIntensity === 'light' || raw.maxIntensity === 'moderate') {
      filters.intensities = INTENSITIES.slice(0, INTENSITY_RANK[raw.maxIntensity] + 1);
    }
    if (Array.isArray(raw.services)) {
      filters.services = uniqueStrings(raw.services).filter(function (service) {
        return STREAMING_SERVICES.indexOf(service) !== -1;
      });
    }
    if (typeof raw.hideWatched === 'boolean') filters.hideWatched = raw.hideWatched;
    return filters;
  }

  function movieServices(movie) {
    return (movie.streamingOffers || []).map(function (offer) { return offer.service; });
  }

  function movieSearchText(movie) {
    return [movie.title]
      .concat(movie.aliases || [])
      .concat(movie.version ? [movie.version] : [])
      .concat(movie.track ? [movie.track] : [])
      .concat(movie.culturalFocus ? [movie.culturalFocus] : [])
      .concat(movie.genres || [])
      .concat(movieServices(movie))
      .join(' ');
  }

  function movieMatches(movie, filters, watchedLookup) {
    var query = foldText(filters.search.trim());
    if (query && foldText(movieSearchText(movie)).indexOf(query) === -1) return false;
    if (filters.genres.length && !(movie.genres || []).some(function (g) { return filters.genres.indexOf(g) !== -1; })) {
      return false;
    }
    if (filters.tracks && filters.tracks.length && filters.tracks.indexOf(movie.track) === -1) return false;
    if (filters.intensities.length && filters.intensities.indexOf(movie.intensity) === -1) return false;
    if (filters.services && filters.services.length) {
      var services = movieServices(movie);
      if (!filters.services.some(function (service) { return services.indexOf(service) !== -1; })) return false;
    }
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
      v: catalogVersion || catalogMeta.version,
      q: filters.search.trim().toLowerCase(),
      g: (filters.genres || []).slice().sort(),
      t: (filters.tracks || []).slice().sort(),
      i: filters.intensities.length === INTENSITIES.length ? [] : INTENSITIES.filter(function (level) {
        return filters.intensities.indexOf(level) !== -1;
      }),
      s: (filters.services || []).slice().sort(),
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
      catalogVersion: catalogMeta.version
    });
  }

  function randomPicks(filters, watchedIds, seed) {
    return selectPicks({
      movies: MOVIES,
      filters: filters,
      watchedIds: watchedIds,
      seed: 'random|' + seed,
      catalogVersion: catalogMeta.version
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
      catalogVersion: catalogMeta.version,
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

  // ── Save files (download / load) ─────────────────────────────

  var SAVE_FORMAT = 'october-horror-save';
  var MAX_SAVE_BYTES = 512 * 1024;

  function exportState(state, savedAt) {
    return JSON.stringify({ format: SAVE_FORMAT, savedAt: savedAt || null, state: state }, null, 2) + '\n';
  }

  function importState(text) {
    if (typeof text !== 'string' || !text) return { state: null, problem: 'notASave' };
    if (text.length > MAX_SAVE_BYTES) return { state: null, problem: 'tooLarge' };
    var parsed;
    try {
      parsed = JSON.parse(text);
    } catch (err) {
      return { state: null, problem: 'corrupt' };
    }
    if (!isPlainObject(parsed) || parsed.format !== SAVE_FORMAT) return { state: null, problem: 'notASave' };
    var result = sanitizeState(parsed.state);
    return result.problem ? { state: null, problem: result.problem } : { state: result.state, problem: null };
  }

  // ── Reference links ──────────────────────────────────────────

  var REFERENCE_RULES = {
    imdb: { hosts: ['www.imdb.com', 'imdb.com', 'm.imdb.com'], path: /^\/title\/tt\d{7,9}\/?$/ },
    rt: { hosts: ['www.rottentomatoes.com', 'rottentomatoes.com'], path: /^\/m\/[a-z0-9_]+\/?$/ }
  };

  var STREAMING_HOSTS = {
    Netflix: ['www.netflix.com', 'netflix.com'],
    Hulu: ['www.hulu.com', 'hulu.com'],
    'Amazon Prime Video': ['www.amazon.com', 'amazon.com', 'www.primevideo.com', 'primevideo.com']
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

  function isAllowedStreamingUrl(url, service) {
    if (typeof url !== 'string' || typeof URL === 'undefined') return false;
    var hosts = STREAMING_HOSTS[service] || [];
    if (!hosts.length) return false;
    try {
      var parsed = new URL(url);
      return parsed.protocol === 'https:' && hosts.indexOf(parsed.hostname) !== -1 &&
        !parsed.username && !parsed.password && !parsed.port && !parsed.hash;
    } catch (err) {
      return false;
    }
  }

  function searchQuery(movie) {
    return movie.title.replace(/[\u2018\u2019]/g, '\'') + ' ' + movie.year;
  }

  function referenceLinks(movie) {
    var query = encodeURIComponent(searchQuery(movie));
    var imdbFallback = 'https://www.imdb.com/find/?q=' + query + '&s=tt';
    var rtFallback = 'https://www.rottentomatoes.com/search?search=' + query;
    var imdbDirect = isAllowedReferenceUrl(movie.imdbUrl, 'imdb');
    var rtDirect = isAllowedReferenceUrl(movie.rottenTomatoesUrl, 'rt');
    var imdbHref = imdbDirect ? movie.imdbUrl
      : (typeof movie.imdbUrl === 'string' && movie.imdbUrl.indexOf('https://www.imdb.com/find/') === 0 ? movie.imdbUrl : imdbFallback);
    var rtHref = rtDirect ? movie.rottenTomatoesUrl
      : (typeof movie.rottenTomatoesUrl === 'string' && movie.rottenTomatoesUrl.indexOf('https://www.rottentomatoes.com/') === 0 ? movie.rottenTomatoesUrl : rtFallback);
    return {
      imdb: { href: imdbHref, direct: imdbDirect },
      rt: { href: rtHref, direct: rtDirect }
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

  function streamingLinks(movie) {
    return (movie.streamingOffers || []).filter(function (offer) {
      return isAllowedStreamingUrl(offer.watchUrl, offer.service);
    });
  }

  function renderMovieCard(doc, movie, opts) {
    var links = referenceLinks(movie);
    var streams = streamingLinks(movie);
    var card = el(doc, 'article', 'oh-movie oh-movie--' + movie.intensity);
    card.setAttribute('data-movie-id', movie.id);

    var n = ++uid;
    var bodyId = 'oh-' + opts.context + '-' + movie.id + '-body-' + n;
    var expanded = !!opts.expanded;

    var top = el(doc, 'div', 'oh-movie__top');
    var heading = el(doc, opts.headingLevel || 'h3', 'oh-movie__title');
    heading.appendChild(el(doc, 'span', 'oh-movie__name', movie.title));
    heading.appendChild(doc.createTextNode(' '));
    heading.appendChild(el(doc, 'span', 'oh-movie__year', '(' + movie.year + (movie.version ? ', ' + movie.version : '') + ')'));
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
    if (movie.genres && movie.genres.length) {
      var tags = el(doc, 'ul', 'oh-tags');
      tags.setAttribute('aria-label', 'Genres');
      movie.genres.forEach(function (genre) { tags.appendChild(el(doc, 'li', 'oh-tag', genre)); });
      labels.appendChild(tags);
    }
    labels.appendChild(intensityBadge(doc, movie.intensity));
    if (movie.track) labels.appendChild(el(doc, 'span', 'oh-tag oh-tag--track', movie.track));
    if (movie.culturalFocus) labels.appendChild(el(doc, 'span', 'oh-tag oh-tag--focus', movie.culturalFocus));
    if (movie.reception && movie.reception.criticPercent != null) {
      labels.appendChild(el(doc, 'span', 'oh-tag oh-tag--score', movie.reception.criticPercent + '% critics'));
    }
    if (movieServices(movie).length) {
      var streamTags = el(doc, 'ul', 'oh-tags oh-tags--stream');
      streamTags.setAttribute('aria-label', 'Streaming');
      uniqueStrings(movieServices(movie)).forEach(function (service) {
        streamTags.appendChild(el(doc, 'li', 'oh-tag oh-tag--stream', service));
      });
      labels.appendChild(streamTags);
    }
    card.appendChild(labels);

    var body = el(doc, 'div', 'oh-movie__body');
    body.id = bodyId;
    body.hidden = !expanded;

    var meta = el(doc, 'p', 'oh-movie__meta');
    meta.appendChild(el(doc, 'span', '', String(movie.year)));
    if (movie.version) meta.appendChild(el(doc, 'span', '', movie.version));
    if (movie.aliases && movie.aliases.length) {
      meta.appendChild(el(doc, 'span', '', 'Also known as ' + movie.aliases.join(', ')));
    }
    meta.appendChild(el(doc, 'span', '', 'Scheduled Oct ' + movie.calendarDay));
    body.appendChild(meta);

    if (streams.length) {
      var streamRefs = el(doc, 'p', 'oh-movie__refs oh-movie__refs--stream');
      streams.forEach(function (offer) {
        var link = el(doc, 'a', 'oh-movie__stream');
        link.href = offer.watchUrl;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.appendChild(doc.createTextNode('Watch on ' + offer.service));
        link.appendChild(externalIcon(doc));
        link.setAttribute('aria-label', movie.title + ': watch on ' + offer.service + ' (opens in a new tab)');
        streamRefs.appendChild(link);
      });
      body.appendChild(streamRefs);
    }

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

    if (movie.blurb) body.appendChild(el(doc, 'p', 'oh-movie__blurb', movie.blurb));
    if (movie.reception && movie.reception.label) {
      body.appendChild(el(doc, 'p', 'oh-movie__note', movie.reception.label));
    }
    if (movie.viewingNote) body.appendChild(el(doc, 'p', 'oh-movie__note', movie.viewingNote));

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
    var dayMoreOpen = false;
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
      root.querySelectorAll('input[name="oh-track"]').forEach(function (box) {
        box.checked = (f.tracks || []).indexOf(box.value) !== -1;
      });
      root.querySelectorAll('input[name="oh-intensity"]').forEach(function (box) {
        box.checked = f.intensities.indexOf(box.value) !== -1;
      });
      root.querySelectorAll('input[name="oh-service"]').forEach(function (box) {
        box.checked = f.services.indexOf(box.value) !== -1;
      });
      $('#oh-hide-watched').checked = f.hideWatched;
      $('#oh-sort').value = state.sort;
      renderFilterSummary();
    }

    function renderFilterSummary() {
      var f = state.filters;
      var active = (f.search.trim() ? 1 : 0) + f.genres.length + (f.tracks ? f.tracks.length : 0) +
        f.intensities.length + (f.services ? f.services.length : 0) + (f.hideWatched ? 1 : 0);
      $('#oh-filters-active').textContent = active ? active + ' active' : 'none active';
    }

    function setSectionOpen(toggle, open) {
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      doc.getElementById(toggle.getAttribute('aria-controls')).hidden = !open;
    }

    function buildChipControls(box, values, namePrefix, idPrefix) {
      if (!box || box.getAttribute('data-built') === '1') return;
      values.forEach(function (value) {
        var id = idPrefix + value.toLowerCase().replace(/[^a-z0-9]+/g, '-');
        var label = el(doc, 'label', 'oh-check oh-chip');
        label.htmlFor = id;
        var input = doc.createElement('input');
        input.type = 'checkbox';
        input.name = namePrefix;
        input.id = id;
        input.value = value;
        label.appendChild(input);
        label.appendChild(doc.createTextNode(' ' + value));
        box.appendChild(label);
      });
      box.setAttribute('data-built', '1');
    }

    function buildGenreControls() {
      var box = $('#oh-genres');
      buildChipControls(box, GENRES, 'oh-genre', 'oh-genre-');
      var fieldset = box && box.closest('fieldset');
      if (fieldset) fieldset.hidden = GENRES.length === 0;
    }

    function buildTrackControls() {
      var box = $('#oh-tracks');
      buildChipControls(box, TRACKS, 'oh-track', 'oh-track-');
      var fieldset = box && box.closest('fieldset');
      if (fieldset) fieldset.hidden = TRACKS.length === 0;
    }

    function buildServiceControls() {
      buildChipControls($('#oh-services'), STREAMING_SERVICES, 'oh-service', 'oh-service-');
    }

    function readFilters() {
      var genres = [];
      root.querySelectorAll('input[name="oh-genre"]:checked').forEach(function (box) { genres.push(box.value); });
      var tracks = [];
      root.querySelectorAll('input[name="oh-track"]:checked').forEach(function (box) { tracks.push(box.value); });
      var intensities = [];
      root.querySelectorAll('input[name="oh-intensity"]:checked').forEach(function (box) { intensities.push(box.value); });
      var services = [];
      root.querySelectorAll('input[name="oh-service"]:checked').forEach(function (box) { services.push(box.value); });
      state.filters = normalizeFilters({
        search: $('#oh-search').value,
        genres: genres,
        tracks: tracks,
        intensities: intensities,
        services: services,
        hideWatched: $('#oh-hide-watched').checked
      });
    }

    function pickCountLabel(count) {
      return count === 1 ? 'one' : count === 2 ? 'two' : count === 3 ? 'three' : count === 4 ? 'four' : String(count);
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
        heading.textContent = formatLocalDate(today) + ' — ' + pickCountLabel(PICK_COUNT) +
          ' of tonight’s scheduled films.';
        status = filtersActive()
          ? result.eligibleCount + ' of tonight’s ' + moviesOnDay(today.day).length + ' films match your filters.'
          : '';
        if (result.eligibleCount > 0 && result.eligibleCount < PICK_COUNT) {
          status += ' Fewer than ' + pickCountLabel(PICK_COUNT) + ' match, so fewer picks are shown.';
        }
      }
      $('#oh-picks-status').textContent = status.trim();
      renderCards($('#oh-picks-list'), result.ids, 'pick', 'h3');
      $('#oh-picks-empty').hidden = !today.inOctober || result.ids.length !== 0;
    }

    function renderRandom() {
      var result = randomPicks(state.filters, season().watchedIds, randomSeed);
      var status = result.eligibleCount + (result.eligibleCount === 1 ? ' movie matches' : ' movies match') + ' your filters.';
      if (result.eligibleCount > 0 && result.eligibleCount < PICK_COUNT) {
        status += ' Fewer than ' + pickCountLabel(PICK_COUNT) + ' match, so fewer picks are shown.';
      }
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
      var totalByDay = {};
      MOVIES.forEach(function (m) { totalByDay[m.calendarDay] = (totalByDay[m.calendarDay] || 0) + 1; });
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
          (filtered ? ', ' + matchCount + ' of ' + (totalByDay[day] || 0) + ' films match' : ''));
        item.appendChild(button);
        list.appendChild(item);
      }
      $('#oh-day-heading').textContent = formatOctoberDate(year, selectedDay);
      var theme = dayTheme(selectedDay);
      var themeEl = $('#oh-day-theme');
      themeEl.textContent = theme;
      themeEl.hidden = !theme;
      var ids = matchesByDay[selectedDay] || [];
      var split = splitDayMovies(ids);
      var scheduledTotal = totalByDay[selectedDay] || 0;
      $('#oh-day-status').textContent = filtered
        ? ids.length + ' of ' + scheduledTotal + ' scheduled films match your filters.'
        : scheduledTotal + ' scheduled films.';
      renderCards($('#oh-day-list'), split.topIds, 'day', 'h4');
      $('#oh-day-picks-wrap').hidden = split.topIds.length === 0;
      var moreWrap = $('#oh-day-more-wrap');
      var moreToggle = $('#oh-day-more-toggle');
      if (split.moreIds.length) {
        moreWrap.hidden = false;
        $('#oh-day-more-count').textContent = String(split.moreIds.length);
        renderCards($('#oh-day-more-list'), split.moreIds, 'day-more', 'h5');
        setSectionOpen(moreToggle, dayMoreOpen);
      } else {
        moreWrap.hidden = true;
        dayMoreOpen = false;
        setSectionOpen(moreToggle, false);
        renderCards($('#oh-day-more-list'), [], 'day-more', 'h5');
      }
      $('#oh-day-empty').hidden = ids.length !== 0;
    }

    function filtersActive() {
      var f = state.filters;
      return !!(f.search.trim() || f.genres.length || (f.tracks && f.tracks.length) ||
        f.intensities.length || (f.services && f.services.length) || f.hideWatched);
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
      '#oh-day-more-list': '#oh-day-more-toggle',
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

    var LOAD_PROBLEMS = {
      tooLarge: 'That file is too large to be an October save.',
      corrupt: 'That file could not be read as an October save.',
      notASave: 'That file is not an October save. Use a file made with “Save my October”.',
      unsupported: 'That save came from an unsupported version, so it was not loaded.',
      unreadable: 'Your browser could not read that file.'
    };

    function seasonSummary(s) {
      return s.selectedIds.length + ' want to watch, ' + s.watchedIds.length + ' watched';
    }

    function saveMyOctober() {
      var status = $('#oh-mine-status');
      if (typeof win.Blob !== 'function' || !win.URL || typeof win.URL.createObjectURL !== 'function') {
        status.textContent = 'This browser cannot download files.';
        return;
      }
      var name = 'my-october-' + today.key + '.json';
      var url = win.URL.createObjectURL(new win.Blob([exportState(state, now().toISOString())], { type: 'application/json' }));
      var link = doc.createElement('a');
      link.href = url;
      link.download = name;
      link.hidden = true;
      doc.body.appendChild(link);
      link.click();
      link.remove();
      win.setTimeout(function () { win.URL.revokeObjectURL(url); }, 0);
      status.textContent = 'Saved ' + name + ' (' + seasonSummary(season()) + ' in ' + today.year + ').';
    }

    function applyLoaded(text, name) {
      var status = $('#oh-mine-status');
      var result = importState(text);
      if (result.problem) {
        status.textContent = LOAD_PROBLEMS[result.problem] || LOAD_PROBLEMS.corrupt;
        return;
      }
      var ok = confirmFn('Load ' + name + '? It replaces your Want to watch and Watched lists for every season, ' +
        'and your filters, in this browser.');
      if (!ok) return;
      state = result.state;
      syncFilterControls();
      persist();
      renderAll();
      status.textContent = 'Loaded ' + name + ' (' + seasonSummary(season()) + ' in ' + today.year + ').';
    }

    function loadMyOctober(input) {
      var file = input.files && input.files[0];
      input.value = '';
      if (!file) return;
      if (file.size > MAX_SAVE_BYTES) {
        $('#oh-mine-status').textContent = LOAD_PROBLEMS.tooLarge;
        return;
      }
      file.text().then(function (text) { applyLoaded(text, file.name); }, function () {
        $('#oh-mine-status').textContent = LOAD_PROBLEMS.unreadable;
      });
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
      else if (target.id === 'oh-load-file') loadMyOctober(target);
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
        var open = target.getAttribute('aria-expanded') !== 'true';
        setSectionOpen(target, open);
        if (target.id === 'oh-day-more-toggle') dayMoreOpen = open;
      } else if (target.matches('.oh-clear')) clearFilters();
      else if (target.id === 'oh-shuffle') shuffle();
      else if (target.id === 'oh-reset') resetMyOctober();
      else if (target.id === 'oh-save') saveMyOctober();
      else if (target.id === 'oh-load') $('#oh-load-file').click();
      else if (target.matches('.oh-cal__day')) {
        var nextDay = Number(target.getAttribute('data-day'));
        if (nextDay !== selectedDay) dayMoreOpen = false;
        selectedDay = nextDay;
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
    buildTrackControls();
    buildServiceControls();
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

  function defaultCatalogUrl(doc) {
    try {
      return new URL(DEFAULT_CATALOG_URL, doc.baseURI || (doc.defaultView && doc.defaultView.location && doc.defaultView.location.href) || DEFAULT_CATALOG_URL).href;
    } catch (err) {
      return DEFAULT_CATALOG_URL;
    }
  }

  function fetchCatalog(url, fetchFn) {
    return fetchFn(url, { credentials: 'same-origin' }).then(function (res) {
      if (!res.ok) throw new Error('Could not load movie catalog (' + res.status + ')');
      return res.json();
    }).then(function (data) {
      return loadCatalog(data);
    });
  }

  function startApp(root, deps) {
    deps = deps || {};
    var doc = root.ownerDocument;
    var win = doc.defaultView;
    var show = function (msg) {
      var box = root.querySelector('#oh-notice');
      if (!box) return;
      box.hidden = false;
      box.textContent = msg;
    };
    var ready = function () {
      try { api.createApp(root, deps); }
      catch (err) {
        show('October Horror could not start. ' + (err && err.message ? err.message : 'Please try again.'));
        if (win.console && win.console.error) win.console.error(err);
      }
    };
    if (deps.catalog) {
      loadCatalog(deps.catalog);
      ready();
      return;
    }
    if (MOVIES.length) {
      ready();
      return;
    }
    var fetchFn = deps.fetch || (win && win.fetch && win.fetch.bind(win));
    if (!fetchFn) {
      show('This page needs to load october/movies.json over HTTP (open it from the site, not as a local file).');
      return;
    }
    fetchCatalog(deps.catalogUrl || defaultCatalogUrl(doc), fetchFn).then(ready).catch(function (err) {
      show('Could not load the movie catalog. ' + (err && err.message ? err.message : 'Check that movies.json is available.'));
      if (win.console && win.console.error) win.console.error(err);
    });
  }

  var api = {
    get CATALOG_VERSION() { return catalogMeta.version; },
    get FILMS_PER_DAY() { return catalogMeta.filmsPerDay; },
    get PICK_COUNT() { return PICK_COUNT; },
    STORAGE_KEY: STORAGE_KEY,
    GENRES: GENRES,
    TRACKS: TRACKS,
    STREAMING_SERVICES: STREAMING_SERVICES,
    INTENSITIES: INTENSITIES,
    INTENSITY_LABELS: INTENSITY_LABELS,
    MOVIES: MOVIES,
    loadCatalog: loadCatalog,
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
    dayTheme: dayTheme,
    DAY_THEMES: DAY_THEMES,
    splitDayMovies: splitDayMovies,
    getSeason: getSeason,
    setTracked: setTracked,
    resetSeason: resetSeason,
    defaultState: defaultState,
    sanitizeState: sanitizeState,
    loadState: loadState,
    saveState: saveState,
    MAX_SAVE_BYTES: MAX_SAVE_BYTES,
    exportState: exportState,
    importState: importState,
    isAllowedReferenceUrl: isAllowedReferenceUrl,
    isAllowedStreamingUrl: isAllowedStreamingUrl,
    searchQuery: searchQuery,
    referenceLinks: referenceLinks,
    streamingLinks: streamingLinks,
    createApp: createApp,
    start: startApp
  };

  if (typeof module === 'object' && module.exports) {
    module.exports = api;
  } else {
    global.OctoberHorror = api;
    var boot = function () {
      var root = document.getElementById('october-horror');
      if (root && !root.hasAttribute('data-manual-init')) api.start(root, {});
    };
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot);
    else boot();
  }
})(typeof window !== 'undefined' ? window : this);

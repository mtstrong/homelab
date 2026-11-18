"""Import Sonarr/Radarr downloads that are stuck on checks a human would wave through.

Decluttarr leaves two kinds of completed download in the queue on purpose:
  - "release was matched to series/movie by ID": the release name doesn't parse to the
    title (e.g. "Cobra.Kai.(2021)" for Cobra Kai (2018)), but the app grabbed it for that ID.
  - "Unable to determine if file is a sample": the app couldn't compare runtimes.

For each such download this asks the app's manual-import endpoint what it would do and
only imports when every check passes:
  - the queue item has no other warning,
  - every file maps to the series/movie that was grabbed, and together the files cover
    exactly the grabbed episodes, each once,
  - no file has a rejection other than the sample check, and a file rejected only for that
    is the largest file in the download and above a size floor (smaller ones are treated
    as real samples and skipped, as long as another file covers their episodes),
  - no file has a negative custom format score (e.g. the TURG Turkish-audio-first format),
  - when the release name gives languages, the series/movie's original language is one of them.
Anything else is logged and left for the ArrQueueStuck alert.

Stdlib only. Config via env: SONARR_URL, SONARR_API_KEY, RADARR_URL, RADARR_API_KEY,
DRY_RUN ("true" logs what it would import without importing).
"""

import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

DRY_RUN = os.environ.get("DRY_RUN", "false").lower() == "true"

BY_ID = re.compile(r"matched to (series|movie) by ID", re.I)
SAMPLE = re.compile(r"Unable to determine if file is a sample", re.I)
ALLOWED_QUEUE_MESSAGES = (BY_ID, SAMPLE)

MB = 1024 * 1024
# Minimum size for a file that was rejected only by the sample check.
SAMPLE_FLOOR = {"sonarr": 150 * MB, "radarr": 500 * MB}  # Sonarr: per episode


def log(app, msg):
    print(f"[{app}] {msg}", flush=True)


class Arr:
    def __init__(self, app, url, key):
        self.app, self.url, self.key = app, url.rstrip("/"), key

    def call(self, method, path, params=None, body=None):
        url = f"{self.url}/api/v3/{path}"
        if params:
            url += "?" + urllib.parse.urlencode(params)
        data = json.dumps(body).encode() if body is not None else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("X-Api-Key", self.key)
        if data is not None:
            req.add_header("Content-Type", "application/json")
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read()
        return json.loads(raw) if raw else None

    def get(self, path, **params):
        return self.call("GET", path, params)


def queue_messages(record):
    msgs = []
    for sm in record.get("statusMessages") or []:
        msgs.extend(sm.get("messages") or [])
    return msgs


def rejection_reasons(item):
    out = []
    for r in item.get("rejections") or []:
        out.append(r.get("reason", "") if isinstance(r, dict) else str(r))
    return out


def language_names(langs):
    return {l.get("name") for l in langs or [] if l.get("name") and l.get("name") != "Unknown"}


def check_download(arr, records, target):
    """Return (files_to_import, None) or (None, reason_to_skip)."""
    first = records[0]
    app = arr.app
    msgs = [m for r in records for m in queue_messages(r)]
    if not msgs:
        return None, "no status message"
    other = [m for m in msgs if not any(p.search(m) for p in ALLOWED_QUEUE_MESSAGES)]
    if other:
        return None, f"other warning: {other[0]}"
    if not first.get("outputPath"):
        return None, "no output path"

    if app == "sonarr":
        target_id = first.get("seriesId")
        expected = {r.get("episodeId") for r in records}
        if not target_id or None in expected or any(r.get("seriesId") != target_id for r in records):
            return None, "queue item has no single series/episodes"
    else:
        target_id = first.get("movieId")
        if not target_id or any(r.get("movieId") != target_id for r in records):
            return None, "queue item has no single movie"

    # Pass only folder + downloadId: adding seriesId/movieId scans the library folder instead.
    items = arr.get(
        "manualimport",
        folder=first["outputPath"].rstrip("/"),
        downloadId=first["downloadId"],
        filterExistingFiles="true",
    ) or []
    if not items:
        return None, "manual import found no files"

    largest = max(i.get("size", 0) for i in items)
    real, samples = [], []
    for it in items:
        name = it.get("relativePath") or it.get("path")
        reasons = rejection_reasons(it)
        bad = [r for r in reasons if not SAMPLE.search(r)]
        if bad:
            return None, f"{name}: rejected: {bad[0]}"
        if app == "sonarr":
            owner = (it.get("series") or {}).get("id")
            eps = [e["id"] for e in it.get("episodes") or []]
        else:
            owner = (it.get("movie") or {}).get("id")
            eps = []
        if owner != target_id:
            return None, f"{name}: maps to a different {('series' if app == 'sonarr' else 'movie')} ({owner})"
        if app == "sonarr" and (not eps or not set(eps) <= expected):
            return None, f"{name}: maps to episodes that weren't grabbed"
        if reasons:  # only the sample check
            floor = SAMPLE_FLOOR[app] * max(len(eps), 1)
            if it.get("size", 0) < floor or it.get("size", 0) < largest:
                samples.append((it, eps))
                continue
        if (it.get("customFormatScore") or 0) < 0:
            return None, f"{name}: negative custom format score {it.get('customFormatScore')}"
        langs = language_names(it.get("languages"))
        orig = (target.get("originalLanguage") or {}).get("name")
        if langs and orig and orig != "Unknown" and orig not in langs:
            return None, f"{name}: languages {sorted(langs)} don't include original language {orig}"
        real.append((it, eps))

    if not real:
        return None, "only sample-sized files"
    if app == "sonarr":
        covered = [e for _, eps in real for e in eps]
        if len(covered) != len(set(covered)):
            return None, "two files map to the same episode"
        if set(covered) != expected:
            return None, f"files cover {len(set(covered))} of {len(expected)} grabbed episodes"
        if any(not set(eps) <= set(covered) for _, eps in samples):
            return None, "a sample-sized file covers an episode no other file does"
    elif len(real) != 1:
        return None, f"{len(real)} candidate movie files"

    files = []
    for it, eps in real:
        f = {
            "path": it["path"],
            "quality": it.get("quality"),
            "languages": it.get("languages"),
            "releaseGroup": it.get("releaseGroup"),
            "downloadId": first["downloadId"],
            "indexerFlags": it.get("indexerFlags", 0),
        }
        if app == "sonarr":
            f.update(seriesId=target_id, episodeIds=eps, releaseType=it.get("releaseType", "unknown"))
        else:
            f.update(movieId=target_id)
        files.append(f)
    return files, None


def run(arr):
    busy = [c for c in arr.get("command") or []
            if c.get("status") in ("queued", "started")
            and c.get("name") in ("ManualImport", "DownloadedEpisodesScan", "DownloadedMoviesScan")]
    if busy:
        log(arr.app, "an import is already running, skipping this run")
        return 0

    queue = arr.get("queue", page=1, pageSize=1000).get("records", [])
    stuck = {}
    for r in queue:
        if (r.get("status") == "completed"
                and r.get("trackedDownloadState") in ("importBlocked", "importPending")
                and r.get("trackedDownloadStatus") == "warning"
                and r.get("downloadId")):
            stuck.setdefault(r["downloadId"], []).append(r)

    cache = {}
    imported = 0
    for dl, records in stuck.items():
        title = records[0].get("title")
        msgs = [m for r in records for m in queue_messages(r)]
        if not any(p.search(m) for m in msgs for p in ALLOWED_QUEUE_MESSAGES):
            continue  # not ours; Decluttarr or a human handles it
        kind, tid = ("series", records[0].get("seriesId")) if arr.app == "sonarr" else ("movie", records[0].get("movieId"))
        if tid and (kind, tid) not in cache:
            cache[(kind, tid)] = arr.get(f"{kind}/{tid}")
        try:
            files, why = check_download(arr, records, cache.get((kind, tid)) or {})
        except urllib.error.HTTPError as e:
            files, why = None, f"API error {e.code}"
        if why:
            log(arr.app, f"SKIP {title}: {why}")
            continue
        names = ", ".join(os.path.basename(f["path"]) for f in files)
        if DRY_RUN:
            log(arr.app, f"WOULD IMPORT {title}: {names}")
            continue
        arr.call("POST", "command", body={"name": "ManualImport", "importMode": "auto", "files": files})
        log(arr.app, f"IMPORT {title}: {names}")
        imported += 1
    log(arr.app, f"{len(stuck)} stuck downloads, {imported} imported{' (dry run)' if DRY_RUN else ''}")
    return imported


def main():
    failed = False
    for app in ("sonarr", "radarr"):
        url, key = os.environ.get(f"{app.upper()}_URL"), os.environ.get(f"{app.upper()}_API_KEY")
        if not url or not key:
            continue
        try:
            run(Arr(app, url, key))
        except Exception as e:  # keep going so one app being down doesn't block the other
            log(app, f"ERROR {type(e).__name__}: {e}")
            failed = True
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Fetch album covers for the NFC card sheet.

  1. MusicBrainz: find the album (release group) for "Artist | Album"
  2. fanart.tv:   best-liked album cover (needs your free personal API key)
  3. Cover Art Archive: fallback / alternative when fanart.tv has nothing or a small image
Keeps whichever image is largest.  Writes art/<slug>.jpg and cards.json (for make_sheet.py).

Setup:   pip install pillow reportlab
Usage:   python3 fetch_covers.py                      # reads albums.txt
         python3 fetch_covers.py my-list.txt --key YOUR_FANART_KEY
         FANART_API_KEY=... python3 fetch_covers.py --force     # re-download everything
Get a fanart.tv key (free): create an account on fanart.tv, then Profile > "Your personal API key".
Without a key the script still works, using only the Cover Art Archive.
"""
import argparse, io, json, os, re, sys, time, unicodedata
import urllib.error, urllib.parse, urllib.request
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
UA = "nfc-album-cards/1.0 (personal homelab script; set MB_CONTACT=you@example.org to add contact info)"
if os.environ.get("MB_CONTACT"):
    UA = "nfc-album-cards/1.0 ( %s )" % os.environ["MB_CONTACT"]
MIN_PX = 600
_last_mb = [0.0]

def http_get(url, headers=None, timeout=30, tries=3):
    """GET with retries. Returns (bytes, content_type). Raises urllib.error.HTTPError on 4xx."""
    h = {"User-Agent": UA}
    h.update(headers or {})
    for attempt in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=h), timeout=timeout) as r:
                return r.read(), r.headers.get("Content-Type", "")
        except urllib.error.HTTPError as e:
            if e.code in (429, 503) and attempt < tries - 1:
                time.sleep(2 * (attempt + 1)); continue
            raise
        except urllib.error.URLError:
            if attempt < tries - 1:
                time.sleep(2); continue
            raise

def mb_get(path, **params):
    """MusicBrainz allows ~1 request per second."""
    wait = 1.1 - (time.time() - _last_mb[0])
    if wait > 0: time.sleep(wait)
    url = "https://musicbrainz.org/ws/2/%s?%s" % (path, urllib.parse.urlencode(dict(params, fmt="json")))
    data, _ = http_get(url)
    _last_mb[0] = time.time()
    return json.loads(data)

def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", " ", s.lower()).strip()

def slug(artist, album):
    return re.sub(r"\s+", "-", norm(artist + " " + album))

def parse_list(path):
    items = []
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#") or "|" not in line:
            continue
        a, b = line.split("|", 1)
        items.append((a.strip(), b.strip()))
    return items

def lucene(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')

def mb_find(artist, album):
    """Return (mbid, title) of the best matching album release group, or None."""
    variants = [album]
    plain = album.replace("’", "'")
    if plain != album: variants.append(plain)
    for title in variants:
        q = 'releasegroup:"%s" AND artist:"%s"' % (lucene(title), lucene(artist))
        res = mb_get("release-group", query=q, limit=10).get("release-groups", [])
        want = norm(album)
        def ok(r):
            t = norm(r.get("title", ""))
            return t == want or want in t or t in want
        def rank(r):
            clean = not r.get("secondary-types")
            is_album = r.get("primary-type") == "Album"
            exact = norm(r.get("title", "")) == want
            return (exact, is_album, clean, r.get("score", 0))
        good = sorted([r for r in res if ok(r) and r.get("score", 0) >= 80], key=rank, reverse=True)
        if good:
            return good[0]["id"], good[0]["title"]
    return None

def fanart_url(mbid, key):
    try:
        data, _ = http_get("https://webservice.fanart.tv/v3/music/albums/%s?api_key=%s" % (mbid, key))
    except urllib.error.HTTPError as e:
        if e.code == 404: return None
        raise
    albums = json.loads(data).get("albums", {})
    covers = (albums.get(mbid) or next(iter(albums.values()), {})).get("albumcover", [])
    if not covers: return None
    return max(covers, key=lambda c: int(c.get("likes", 0) or 0))["url"]

def caa_image(mbid):
    for size in ("front-1200", "front"):
        try:
            data, _ = http_get("https://coverartarchive.org/release-group/%s/%s" % (mbid, size))
            return data
        except urllib.error.HTTPError as e:
            if e.code not in (404, 307, 308): raise
    return None

def px(data):
    return min(Image.open(io.BytesIO(data)).size)

def fetch_one(artist, album, key):
    """Return (image_bytes, source, note) or (None, None, reason)."""
    found = mb_find(artist, album)
    if not found:
        return None, None, "not found on MusicBrainz"
    mbid, title = found
    best, src = None, None
    if key:
        try:
            url = fanart_url(mbid, key)
            if url:
                best, src = http_get(url)[0], "fanart.tv"
        except Exception as e:
            print("   fanart.tv error: %s" % e)
    if best is None or px(best) < MIN_PX:
        try:
            alt = caa_image(mbid)
        except Exception as e:
            alt = None; print("   cover art archive error: %s" % e)
        if alt and (best is None or px(alt) > px(best)):
            best, src = alt, "coverartarchive"
    if best is None:
        return None, None, "no cover on fanart.tv or the Cover Art Archive (mbid %s)" % mbid
    return best, src, "mbid %s" % mbid

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("list", nargs="?", default=os.path.join(HERE, "albums.txt"))
    ap.add_argument("--out", default=os.path.join(HERE, "art"))
    ap.add_argument("--cards", default=os.path.join(HERE, "cards.json"))
    ap.add_argument("--key", default=os.environ.get("FANART_API_KEY", ""))
    ap.add_argument("--force", action="store_true", help="download again even if the file exists")
    a = ap.parse_args()
    if not a.key:
        print("No fanart.tv key (--key or FANART_API_KEY): using the Cover Art Archive only.\n")
    os.makedirs(a.out, exist_ok=True)
    old = {}
    if os.path.exists(a.cards):
        for c in json.load(open(a.cards, encoding="utf-8")):
            old[norm(c["artist"] + " " + c["album"])] = c
    cards, problems = [], []
    for artist, album in parse_list(a.list):
        name = slug(artist, album); rel = "art/%s.jpg" % name
        path = os.path.join(a.out, name + ".jpg")
        label = "%s | %s" % (artist, album)
        if os.path.exists(path) and not a.force:
            print("%-55s already have it (%dpx)" % (label, px(open(path, "rb").read())))
        else:
            try:
                data, src, note = fetch_one(artist, album, a.key)
            except Exception as e:
                data, src, note = None, None, "error: %s" % e
            if data is None:
                print("%-55s MISSING - %s" % (label, note)); problems.append(label)
            else:
                Image.open(io.BytesIO(data)).convert("RGB").save(path, "JPEG", quality=95)
                size = px(data)
                flag = "" if size >= MIN_PX else "   <-- LOW RESOLUTION"
                print("%-55s %-16s %4dpx%s" % (label, src, size, flag))
                if size < MIN_PX: problems.append(label + " (low res)")
        prev = old.get(norm(artist + " " + album), {})
        cards.append({"uid": prev.get("uid", ""), "artist": artist, "album": album, "art": rel})
    json.dump(cards, open(a.cards, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("\nWrote %s (%d cards)." % (a.cards, len(cards)))
    if problems:
        print("\nCheck these by hand (save a cover as art/<slug>.jpg yourself):")
        for p in problems: print("  -", p)
    print("Next: python3 make_sheet.py")

if __name__ == "__main__":
    main()

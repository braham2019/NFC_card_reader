NFC album card kit
==================
1. pip install pillow reportlab
2. Get a free fanart.tv personal API key (fanart.tv > account > Profile). Optional: without it the
   script uses the Cover Art Archive only.
3. Edit albums.txt ("Artist | Album", one per line).
4. python3 fetch_covers.py --key YOUR_KEY        (or set FANART_API_KEY)
     -> art/<name>.jpg for every album, plus cards.json. It lists any album it could not find or
        where the cover is under 600 px; save those covers into art/ yourself with the name shown.
5. python3 make_sheet.py   ->  nfc-cards-sheet.pdf   (10 cards per A4 page, more pages if needed)
6. Print at 100% / actual size, on laser-rated label sheets (plain A4, not pre-cut). Test on paper first.

cards.json also has a "uid" field per card (empty by default); you can ignore it, or keep it to
remember which Mifare UID belongs to which album.

Recently discovered Music Assistant. It has helped me rediscover the music I used to play on CD (which I’ve since converted to MP3s and added to iTunes over the course of 30 years), rather than always relying on Spotify and it's algorithm. And the multi-room audio in Music Assistant is truly fantastic.

I wanted to revive the old days, when you would take a CD from the rack and play it. The principle is simple: I select a card from the removable NFC card holder, place it on the base plate to scan it, and the album then begins playing on the media players I have configured in Music Assistant.

<img width="426,66" height="421" alt="image" src="https://github.com/user-attachments/assets/775675c6-ed66-4ffb-b017-1d5da8ff34e8" />

# Hardware Prerequisites

- ESP32-C3 (https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html)
<img width="180" height="135" alt="image" src="https://github.com/user-attachments/assets/e014809e-b14b-42e4-9204-2eb67c7437bb" />

- PN532 NFC RFID reader (I got this one: Gerui PN532)
<img width="180" height="180" alt="image" src="https://github.com/user-attachments/assets/9dcb8ab0-cdd6-4e06-b7af-a7af7de31b2d" />

- NFC cards that support NTAG215. Those come quite cheap.
- Printable labels. I used DIN A4 labels and cut out the necessary labels.

# Software Prerequisites
- Music Assistant configured and set-up with local files. In my case a separate docker instance, not the Home Assistant integration.
- Home Assistant connected to Music Assistant. Music Assistant media players should be visible in Home Assistant
- ESPHome integration in Home Assistant
- NFC tag writer (small program on iPhone or Android)

# Tools needed
- 3D printer
- soldering iron
- USB cable (to power it and to put ESPHome basic config on there)

# Setup electronics
- ESP32-C3 gets it's 3V power from a USB-C cable. The PN532 needs to be connected to the ESP32-C3 in 4 ways: VCC, GND, SDA and SCL.
- The pinouts can be found here https://www.espboards.dev/esp32/xiao-esp32c3/
- The mapping is: VCC -> 3v3, GND -> GND, sda -> GPIO6, scl -> GPIO7
- PN532 needs to have the bottom DIP swith setup properly for I2C, otherwise it won't work. On the PN532 V3 DIP switch that is channel 1 ON and channel 2 OFF. Set it before powering up, because the mode is read at start-up. It needs a very fine ballpoint to flick it.
- End result will look like this. Take into account that the small antenna (included with the Xiao ESP32-C3) is really necessary to get a WiFi signal.
<img width="480" height="640" alt="IMG_1371" src="https://github.com/user-attachments/assets/597eb294-871e-44f7-9c27-ba903fc84fdc" />

# Setup software
## ESPHome
- Open Home Assistant with Chrome browser ! this way we can use USB connect to put software on there for first time. Afterwards, it will use WiFi to commit OTA (over the air) updates to the code.
- If not already done so, make sure you have ESPHome Device Builder added to your Home Assistant.
- Go into ESPHome Device Builder, go into Create Device menu and select "Seeed XIAO ESP32C3" as board. Or connect the device already through USB and it will detect it.
- Use the config found here in the repository (esphome.yaml).
## Home Assistant
- Create a new Automation
- Paste the automation.yaml found here in the repositpry.
- Make sure to edit your media player to the ones that you want. In the example yaml this is called "mediaplayer.fillin." In Music Assistant, you can group multiple media players for multiroom audio experience. That media player is automatically added to Home Assistant to be used in this Automation.
- The automation will start the music when the tag is scanned. When you scan the same one again, it will pause the music in Music Assistant.

 # 3D print and design

<img width="480" height="640" alt="image" src="https://github.com/user-attachments/assets/17f6b1b6-5b4e-4033-b4cd-b87927e25a62" />

Design reasoning and prototypes
- I started out with a small box, only to house the ESP32-C3 and the PN532. And a box to put the NFC tags into so I could flick through them.
- Second iteration was a small base plate to put both of the separate boxes onto.
- Third iteration was to integrate the ESP32-C3 part onto the base plate.
- Fourth iteration was a base plate with a round base. That helps for stability and is visually more attractive imho.
- Final interation was to "round" some of the edges.

The end result
 - The 3D print consists of a base plate, a removable card box and a lid to cover the electronics. I also embedded the MusicBrainz logo in there. I'm not reproducing it here (didn't check the copyright). You can find the SVG logo online and add it with a slicer as a negative volume where you want.
 - The 3D files were designed with the help of Claude. I used several iterations to get the perfect layout (see above).
 - The 3D files are in this repository, as well as on Printables "https://www.printables.com/model/1928064-nfc-card-reader-base-plate-to-house-esp32-c3-and-p".

# Album art on the cards
<img width="640" height="407" alt="image" src="https://github.com/user-attachments/assets/8ad5281b-2794-4d4a-9a31-d560d58813a1" />

- In order to put the art on the cards, I purchased full-page labels to be printed with my color laser printer. You can find labels like this online. 
- I asked Claude to write me a program to, based on a text file (albums.txt) that features Artist and Album, download the art files locally and create a PDF. Details on how this works are in the readme in the albumart folder.
- Every page has 10 albums on it, including artist and album name. That is for DIN A4 size. Not sure for Letter format.
- The python scripts to make this happen is also in this repository, in the folder "albumart".

To set it up (in Debian Linux)
- put the files in a separate folder
- create an albums.txt file with  "Artist | Album"  (one per line; lines starting with # are ignored)
```bash
pip install pillow reportlab
sudo apt install python3-venv
python3 -m venv .venv
.venv/bin/pip install pillow reportlab
# (possible nags about fonts, then do "sudo apt install fonts-dejavu-core")
.venv/bin/python fetch_covers.py 
.venv/bin/python make_sheet.py 
```
- The PDF also has cut lines printed on them. That helps. Most difficult part of this project was to put the labels on without them being skewed ;-)

# Configure the labels
- Use the NFC write software to write the artist and album to the NFC card. Use the format  "Artist | Album"

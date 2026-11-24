I wanted to revisit the "old" days when choosing a CD from the CD rack and playing it back to front. The principle is simple: I pick a card from the NFC card box, put it over the base plate to scan it, and it plays the album on the media players I configured.

<img width="305" height="315,75" alt="image" src="https://github.com/user-attachments/assets/e7271382-840d-45d1-9053-60400a2763a9" />

# Hardware Prerequisites

- ESP32-C3 (https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5431.html)
<img width="360" height="270" alt="image" src="https://github.com/user-attachments/assets/e014809e-b14b-42e4-9204-2eb67c7437bb" />

- PN532 NFC RFID reader (I got this one: Gerui PN532)
<img width="360" height="360" alt="image" src="https://github.com/user-attachments/assets/9dcb8ab0-cdd6-4e06-b7af-a7af7de31b2d" />

- NFC cards that support NTAG215. Those come quite cheap.
- Printable labels. I used DIN A4 labels and cut out the necessary labels.

# Software Prerequisites
- Music Assistant configured and set-up with local files. In my case a separate docker instance, not the Home Assistant integration.
- Home Assistant connected to Music Assistant. Music Assistant media players should be visible in Home Assistant
- ESPHome integration in Home Assistant

# Tools needed
- 3D printer
- soldering iron
- USB cable (to power it and to put ESPHome basic config on there)

# Setup electronics
- ESP32-C3 gets it's 3V power from a USB-C cable. The PN532 needs to be connected to the ESP32-C3 in 4 ways: VCC, GND, SDA and SCL.
- The pinouts can be found here https://www.espboards.dev/esp32/xiao-esp32c3/
- The mapping is: VCC -> 3v3, GND -> GND, sda -> GPIO6, scl -> GPIO7
- PN532 needs to have the bottom DIP swith setup properly for I2C, otherwise it won't work. On the PN532 V3 DIP switch that is channel 1 ON and channel 2 OFF. Set it before powering up, because the mode is read at start-up. It needs a very fine ballpoint to flick it.
- End result will look like this
<img width="480" height="640" alt="IMG_1371" src="https://github.com/user-attachments/assets/597eb294-871e-44f7-9c27-ba903fc84fdc" />

# Setup software
## ESPHome
- Open Home Assistant through Chrome browser ! this way we can use USB connect to put software on there for first time. Afterwards, it will use WiFi to commit OTA (over the air) updates.
- If not already done so, make sure you have ESPHome Device Builder added to your Home Assistant
- Go into ESPHome Device Builder, go into Create Device menu and select "Seeed XIAO ESP32C3" as board. Or connect the device already through USB and it will detect it.
- Use the config found here (esphome.yaml).
## Home Assistant
- Create a new Automation
- paste the automation.yaml found here.
- Make sure to edit your media player to the ones that you want. In Music Assistant, you can group multiple media players for multiroom audio experience. That media player is automatically added to Home Assistant to be used.

 # 3D print
 - The 3D print consists of a base plate, a card box and a lid to cover the electronics. I also embedded the MusicBrainz logo in there. But I'm not reproducing it here. You can find the SVG logo online and add it with a slicer as negative volume where you want.
 - The 3D files were designed with the help of Claude. I used several iterations to get the perfect layout.
 - The 3D files are here as well.

# Album art on the cards
<img width="640" height="407" alt="image" src="https://github.com/user-attachments/assets/8ad5281b-2794-4d4a-9a31-d560d58813a1" />

- In order to put the art on the cards, I purchased full-page labels to be printed with my color laser printer. You can find labels like this online. 
- I asked Claude to write me a program to, based on a text file that features Artist and Album, download the files locally and create a PDF.
- Every page has 10 albums on it, including artist and album name.
- The bash script to make this is also in this repository

To set it up (in Debian Linux)
- put the files in a separate folder
- create an albums.txt file with  "Artist | Album"  (one per line; lines starting with # are ignored)
- pip install pillow reportlab
- sudo apt install python3-venv
- python3 -m venv .venv
- .venv/bin/pip install pillow reportlab
- .venv/bin/python fetch_covers.py (possible nags about fonts, then do "sudo apt install fonts-dejavu-core")
- .venv/bin/python make_sheet.py 

- The PDF also has cut lines printed in them. That helps. Most difficult part of this project was to put the labels on without them being skewed ;-)

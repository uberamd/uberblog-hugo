+++
title = "recursive unrar script for windows"
description = ""
author = "Steve Morrissey"
tags = [
  "windows",
  "script",
  "tutorial"
]
date = "2016-11-19T14:25:19-06:00"

+++

This script, as well as similar scripts can be found on the internet but I tend to keep losing the pages that have it. So for my own archival reasons, as well as making it a little easier for others to find, here it is.

This script uses winrar to recursively extract rar archives. This is very useful if you legally download seasons of shows and don't want to extract each episode one by one.

### Step 1

Open up the Windows Command Prompt (Start -> Run -> cmd) or (Start -> Programs -> Accessories -> Command Prompt)

### Step 2

Change to the directory containing the folders for the episodes you want to extract. For example: 

```
cd "\Users\Steve\Downloads\My Favorite Show - Seasons 1-6\My Show - Season 1"
```

### Step 3

Now that we are in the folder containing all the sub-folders to each episode for your show, type in the following command to extract all of the episodes: 

```
for /R %i IN (.) do "c:\Program Files\WinRAR\Rar.exe" x "%i/*.rar"
```

That command is a recursive for loop that looks for .rar files in each folder and extracts them, placing the extracted file in your current folder. 

### Done

If all goes well you will have every episode in your current folder, extracted and ready to watch!

Note: If you installed the 32-bit WinRAR and are running 64-bit windows your command will look like this: 

```
for /R %i IN (.) do "c:\Program Files (x86)\WinRAR\Rar.exe" x "%i/*.rar"
```

It's that simple.

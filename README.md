# Overview

You can generate and compare emojis between iOS versions with the information below and playgrounds stored in the repository.

# Why?

Once, I noticed that one of the emojis has changed between iOS versions in a strange way. And it was Friday. So, I decided that I want to see all the changes in emojis for iOS 13.*. That's how this repository was born.

# How it works

There are two playgrounds in the repository. The first one for generating snapshots from emojis, the second to compare them and create previews.

## SnapshotProducer.playground

This one is iOS Playground. The main responsibility is to generate snapshots for all available emojis. 

It is tricky to convince iOS to tell you the truth about all the available emojis. To solve the problem, I took a shortcut and decided to use emojis from the Unicode standard. The current revision is [UTS #51 Unicode Emoji, Version 12.1](http://www.unicode.org/reports/tr51/tr51-16.html). There are [some files](https://unicode.org/Public/emoji/12.1/) with examples and for testing purposes, `emoji-test.txt` looked like a complete set of all variants. The playground uses the data as a source of truth.

How does it work:

* [The helper](https://github.com/dive/emojis-over-time/blob/master/SnapshotProducer.playground/Contents.swift#L59) parses the `emoji-test-12-1.txt` file (`EmojisExplorer.all`) as follows:
  * Ignore all comments and empty lines in the file;
  * Ignore all variations for skin tones (to reduce the number of snapshots, you can comment this check to generate all variations);
  * Parse the line with a simple regex and extract all valuable information (HEX, status, scalar and text representation);
  * Skip all unqualified & minimally-qualified (check the [emoji-test.txt](https://unicode.org/Public/emoji/12.1/emoji-test.txt) for explanation);
  * Return all qualified emojis;
* Then it enumerates all the emojis and produces images;
  * There is also a live preview if you want to see the progress;
* All images are stored in the temp directory, but this is an iOS playground, so, it is sandboxed. Check the log output; the final path will be printed there.

As a result, you will have snapshot images for all qualified emojis.

**Important Note**: Xcode Playgrounds for iOS use the default device support (iOS SDK version) shipped with Xcode. To generate emoji snapshots for different iOS versions, you have to install different Xcode versions and re-run the playground. All snapshots stored in the directory with the system version of iOS they were generated for.

## SnapshotComparison.playground

This one is the macOS Playground. The main responsibility is to compare snapshots generated with the playground above and produce images with diffs.

How does it work:

* You have to specify a working path and iOS versions for snapshots you want to compare (Check `Config` in [the source code](https://github.com/dive/emojis-over-time/blob/master/SnapshotComparison.playground/Contents.swift));
* The playground will skip all equal files (the algorithm is straightforward: read the data from files and compare them, no percentages or smart logic here);
* Image diffs will be produced for files that are not equal (see the example below);
* All the diffs will be stored in the temp directory inside the directory with the name like `13.1->13.2` that reflects the iOS versions you are comparing;
* The path to the directory will be printed to the log.

<img src="emojis_diff/13.1-%3E13.2/person_getting_haircut.png" width="250">

# How to generate and compare

You have to use both playgrounds to produce diffs:

* Generate snapshots for desired iOS versions with the `SnapshotProducer` playground;
* Copy directories with generated snapshots to a separate directory;
* Open the `SnapshotComparison` playground, change the `Config` to point to the directory you created above and specify iOS versions you want to compare;
* Run the `SnapshotComparison` playground and check the output.

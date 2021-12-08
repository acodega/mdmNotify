# mdmNotify
A generic script to use DEP Notify, an MDM (like Mosyle), and Installomator for initial Mac deployment with user feedback on screen.

mosyleNotify is based off of [Jamf's DEP Notify Starter script](https://github.com/jamf/DEPNotify-Starter).

This script is basically in alpha stage right now.

The script requires DEP Notify and Installomator to already be installed. Future logic will be added to handle waiting or self installing those components.

Core functionality comes at line 77:

```POLICY_ARRAY=(
    "Installing Chrome,googlechrome"
    "Installing Firefox,firefox"
    "Installing Zoom,zoom"
    )
```

`Installing Chrome` is the text that will be displayed above the DEP Notify progress bar, and `googlechrome` is the label Installomator will use.

When Installomator finishes running that label, DEP Notify will advance the progress bar, update the text, and run Installomator again with the next label.

# mdmNotify
A generic script to use DEP Notify, an MDM (like Mosyle), and Installomator for initial Mac deployment with user feedback on screen.

mdmNotify is based off of [Jamf's DEP Notify Starter script](https://github.com/jamf/DEPNotify-Starter).

This script is basically in alpha stage right now. It "works" to the extent that it runs when called with sudo from Terminal on a Mac with DEP Notify and Installomator already installed. Although the script does open DEP Notify as the logged in user, so arguably it's ready to be tested with MDM, which runs scripts as a different user.

The script requires DEP Notify and Installomator to already be installed. Future logic will be added to handle waiting or self installing those components.

Core functionality comes at the policy array function:

```POLICY_ARRAY=(
    "Installing Chrome,googlechrome"
    "Installing Firefox,firefox"
    "Installing Zoom,zoom"
    )
```

`Installing Chrome` is the text that will be displayed above the DEP Notify progress bar, and `googlechrome` is the label Installomator will use.

When Installomator finishes running that label, DEP Notify will advance the progress bar, update the text, and run Installomator again with the next label.

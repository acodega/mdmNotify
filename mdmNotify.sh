#!/bin/bash

# mdmNotify.sh
#
# A generic script to use DEP Notify, an MDM, and Installomator
# for initial Mac deployment with user feedback on screen.
#
# This requires a fair amount of customizing based on the
# enrollment workflow, but is fairly easy to do so.
# Many of the variables in this script, like TESTING_MODE,
# are used when DEP Notify runs.
#

TESTING_MODE=false

FULLSCREEN=false

# Banner image can be 600px wide by 100px high. Images will be scaled to fit
BANNER_IMAGE_PATH="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"

ORG_NAME="Contoso Inc"

BANNER_TITLE="Welcome to $ORG_NAME"

SUPPORT_CONTACT_DETAILS="email helpdesk@company.com"
  
MAIN_TEXT='Thanks for choosing a Mac at '$ORG_NAME'! We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 10 to 20 minutes to complete. \n \n If you need additional software or help, please visit the Self-Service app in your Applications folder or on your Dock.'

INITAL_START_STATUS="Initial Configuration Starting..."

INSTALL_COMPLETE_TEXT="Configuration Complete!"

# Complete messaging to the end user can ether be a button at the bottom of the
# app with a modification to the main window text or a dropdown alert box. Default
# value set to false and will use buttons instead of dropdown messages.
COMPLETE_METHOD_DROPDOWN_ALERT=false

# Script designed to automatically logout user to start FileVault process if
# deferred enablement is detected. Text displayed if deferred status is on.
  # Option for dropdown alert box
    FV_ALERT_TEXT="Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable while encryption takes place."
  # Options if not using dropdown alert box
    FV_COMPLETE_MAIN_TEXT='Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable while encryption takes place.'
    FV_COMPLETE_BUTTON_TEXT="Logout"

# Text that will display inside the alert once policies have finished
  # Option for dropdown alert box
    COMPLETE_ALERT_TEXT="Your Mac is now finished with initial setup and configuration. Press Quit to get started!"
  # Options if not using dropdown alert box
    COMPLETE_MAIN_TEXT='Your Mac is now finished with initial setup and configuration.'
    COMPLETE_BUTTON_TEXT="Get Started!"

STATUS_TEXT_ALIGN="center"

HELP_BUBBLE_TITLE="Need Help?"
HELP_BUBBLE_BODY="This tool at $ORG_NAME is designed to help with new employee onboarding. If you have issues, please $SUPPORT_CONTACT_DETAILS"

#########################################################################################
# Error Screen Text
#########################################################################################
# If testing mode is false and configuration files are present, this text will appear to
# the end user and asking them to contact IT. Limited window options here as the
# assumption is that they need to call IT. No continue or exit buttons will show for
# DEP Notify window and it will not show in fullscreen. IT staff will need to use Terminal
# or Activity Monitor to kill DEP Notify.

# Main heading that will be displayed under the image
  ERROR_BANNER_TITLE="Uh oh, Something Needs Fixing!"

# Paragraph text that will display under the main heading. For a new line, use \n
# If this variable is left blank, the generic message will appear. Leave single
# quotes below as double quotes will break the new lines.
	ERROR_MAIN_TEXT='We are sorry that you are experiencing this inconvenience with your new Mac. However, we have the nerds to get you back up and running in no time! \n \n Please contact IT right away and we will take a look at your computer ASAP. \n \n'	
	ERROR_MAIN_TEXT="$ERROR_MAIN_TEXT $SUPPORT_CONTACT_DETAILS"	
	  
# Error status message that is displayed under the progress bar
  ERROR_STATUS="Setup Failed"
  
POLICY_ARRAY=(
    "Installing Chrome,googlechrome"
    "Installing Firefox,firefox"
    "Installing Zoom,zoom"
    )

#########################################################################################
# Caffeinate / No Sleep Configuration
#########################################################################################
# Flag script to keep the computer from sleeping. BE VERY CAREFUL WITH THIS FLAG!
# This flag could expose your data to risk by leaving an unlocked computer wide open.
# Only recommended if you are using fullscreen mode and have a logout taking place at
# the end of configuration (like for FileVault). Some folks may use this in workflows
# where IT staff are the primary people setting up the device. The device will be
# allowed to sleep again once the DEPNotify app is quit as caffeinate is looking
# at DEPNotify's process ID.
  NO_SLEEP=true

#########################################################################################
# Customized Self-Service Branding
#########################################################################################
# Flag for using the custom branding icon from Self-Service and Jamf Pro
# This will override the banner image specified above. If you have changed the
# name of Self-Service, make sure to modify the Self-Service name below.
# Please note, custom branding is downloaded from Jamf Pro after Self-Service has opened
# at least one time. The script is designed to wait until the files have been downloaded.
# This could take a few minutes depending on server and network resources.
  SELF_SERVICE_CUSTOM_BRANDING=false # Set variable to true or false

# If using a name other than Self-Service with Custom branding. Change the
# name with the SELF_SERVICE_APP_NAME variable below. Keep .app on the end
  SELF_SERVICE_APP_NAME="Self-Service.app"
  
# Number of seconds to wait (seconds) for the Self-Service custon icon.
  SELF_SERVICE_CUSTOM_WAIT=20

#########################################################################################
#########################################################################################
# Core Script Logic - Don't Change Without Major Testing
#########################################################################################
#########################################################################################

# Variables for File Paths
  INST_BINARY="/usr/local/Installomator/Installomator.sh"
  FDE_SETUP_BINARY="/usr/bin/fdesetup"
  DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"
  DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
  DEP_NOTIFY_DEBUG="/var/tmp/depnotifyDebug.log"
  DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"

# Standard Testing Mode Enhancements
  if [ "$TESTING_MODE" = true ]; then
    # Removing old config file if present (Testing Mode Only)
      if [ -f "$DEP_NOTIFY_LOG" ]; then rm "$DEP_NOTIFY_LOG"; fi
      if [ -f "$DEP_NOTIFY_DONE" ]; then rm "$DEP_NOTIFY_DONE"; fi
      if [ -f "$DEP_NOTIFY_DEBUG" ]; then rm "$DEP_NOTIFY_DEBUG"; fi
    # Setting Quit Key set to command + control + x (Testing Mode Only)
      echo "Command: QuitKey: x" >> "$DEP_NOTIFY_LOG"
  fi

# Validating true/false flags
  if [ "$TESTING_MODE" != true ] && [ "$TESTING_MODE" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$FULLSCREEN" != true ] && [ "$FULLSCREEN" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$NO_SLEEP" != true ] && [ "$NO_SLEEP" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$SELF_SERVICE_CUSTOM_BRANDING" != true ] && [ "$SELF_SERVICE_CUSTOM_BRANDING" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Self-Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != true ] && [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$EULA_ENABLED" != true ] && [ "$EULA_ENABLED" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi
  if [ "$REGISTRATION_ENABLED" != true ] && [ "$REGISTRATION_ENABLED" != false ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
    exit 1
  fi

# Run DEP Notify will run after Apple Setup Assistant
  SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
  until [ "$SETUP_ASSISTANT_PROCESS" = "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Setup Assistant Still Running. PID $SETUP_ASSISTANT_PROCESS." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    SETUP_ASSISTANT_PROCESS=$(pgrep -l "Setup Assistant")
  done

# Checking to see if the Finder is running now before continuing. This can help
# in scenarios where an end user is not configuring the device.
  FINDER_PROCESS=$(pgrep -l "Finder")
  until [ "$FINDER_PROCESS" != "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Finder process not found. Assuming device is at login screen." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    FINDER_PROCESS=$(pgrep -l "Finder")
  done

# After the Apple Setup completed. Now safe to grab the current user and user ID
  CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
  CURRENT_USER_ID=$(id -u $CURRENT_USER)
  echo "$(date "+%a %h %d %H:%M:%S"): Current user set to $CURRENT_USER (id: $CURRENT_USER_ID)." >> "$DEP_NOTIFY_DEBUG"
 
# Adding Check and Warning if Testing Mode is off and BOM files exist
  if [[ ( -f "$DEP_NOTIFY_LOG" || -f "$DEP_NOTIFY_DONE" ) && "$TESTING_MODE" = false ]]; then
    echo "$(date "+%a %h %d %H:%M:%S"): TESTING_MODE set to false but config files were found in /var/tmp. Letting user know and exiting." >> "$DEP_NOTIFY_DEBUG"
    mv "$DEP_NOTIFY_LOG" "/var/tmp/depnotify_old.log"
    echo "Command: MainTitle: $ERROR_BANNER_TITLE" >> "$DEP_NOTIFY_LOG"
    echo "Command: MainText: $ERROR_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
    echo "Status: $ERROR_STATUS" >> "$DEP_NOTIFY_LOG"
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    sleep 5
    exit 1
  fi

# If SELF_SERVICE_CUSTOM_BRANDING is set to true. Loading the updated icon
  if [ "$SELF_SERVICE_CUSTOM_BRANDING" = true ]; then
    open -a "/Applications/$SELF_SERVICE_APP_NAME" --hide

  # Loop waiting on the branding image to properly show in the users library
	SELF_SERVICE_COUNTER=0
	CUSTOM_BRANDING_PNG="/Users/$CURRENT_USER/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
	
	until [ -f "$CUSTOM_BRANDING_PNG" ]; do
		echo "$(date "+%a %h %d %H:%M:%S"): Waiting for branding image from Jamf Pro." >> "$DEP_NOTIFY_DEBUG"
		sleep 1
		(( SELF_SERVICE_COUNTER++ ))
		if [ $SELF_SERVICE_COUNTER -gt $SELF_SERVICE_CUSTOM_WAIT ];then
		   CUSTOM_BRANDING_PNG="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
		   break
		fi
	done

  # Setting Banner Image for DEP Notify to Self-Service Custom Branding
    BANNER_IMAGE_PATH="$CUSTOM_BRANDING_PNG"

  # Closing Self-Service
    SELF_SERVICE_PID=$(pgrep -l "Self-Service" | cut -d' ' -f1)
    echo "$(date "+%a %h %d %H:%M:%S"): Self-Service custom branding icon has been loaded. Killing Self-Service PID $SELF_SERVICE_PID." >> "$DEP_NOTIFY_DEBUG"
    kill "$SELF_SERVICE_PID"
  elif [ ! -f "$BANNER_IMAGE_PATH" ];then
    BANNER_IMAGE_PATH="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
  fi

# Setting custom image if specified
  if [ "$BANNER_IMAGE_PATH" != "" ]; then  echo "Command: Image: $BANNER_IMAGE_PATH" >> "$DEP_NOTIFY_LOG"; fi

# Setting custom title if specified
  if [ "$BANNER_TITLE" != "" ]; then echo "Command: MainTitle: $BANNER_TITLE" >> "$DEP_NOTIFY_LOG"; fi

# Setting custom main text if specified
  if [ "$MAIN_TEXT" != "" ]; then echo "Command: MainText: $MAIN_TEXT" >> "$DEP_NOTIFY_LOG"; fi

# General Plist Configuration
  # Calling function to set the INFO_PLIST_PATH
    INFO_PLIST_WRAPPER

  # The plist information below
    DEP_NOTIFY_CONFIG_PLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotify.plist"

  # If testing mode is on, this will remove some old configuration files
    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_CONFIG_PLIST" ]; then rm "$DEP_NOTIFY_CONFIG_PLIST"; fi
    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_USER_INPUT_PLIST" ]; then rm "$DEP_NOTIFY_USER_INPUT_PLIST"; fi

  # Setting default path to the plist which stores all the user completed info
    /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" pathToPlistFile "$DEP_NOTIFY_USER_INPUT_PLIST"

  # Setting status text alignment
    /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" statusTextAlignment "$STATUS_TEXT_ALIGN"

  # Setting help button
    if [ "$HELP_BUBBLE_TITLE" != "" ]; then
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" helpBubble -array-add "$HELP_BUBBLE_TITLE"
      /usr/bin/defaults write "$DEP_NOTIFY_CONFIG_PLIST" helpBubble -array-add "$HELP_BUBBLE_BODY"
    fi

# Changing Ownership of the plist file
  chown "$CURRENT_USER":staff "$DEP_NOTIFY_CONFIG_PLIST"
  chmod 600 "$DEP_NOTIFY_CONFIG_PLIST"

# Opening the app after initial configuration
  if [ "$FULLSCREEN" = true ]; then
##    sudo -u "$CURRENT_USER" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen
  elif [ "$FULLSCREEN" = false ]; then
##    sudo -u "$CURRENT_USER" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    launchctl asuser $CURRENT_USER_ID open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
  fi

# Grabbing the DEP Notify Process ID for use later
  DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  until [ "$DEP_NOTIFY_PROCESS" != "" ]; do
    echo "$(date "+%a %h %d %H:%M:%S"): Waiting for DEPNotify to start to gather the process ID." >> "$DEP_NOTIFY_DEBUG"
    sleep 1
    DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)
  done

# Using Caffeinate binary to keep the computer awake if enabled
  if [ "$NO_SLEEP" = true ]; then
    echo "$(date "+%a %h %d %H:%M:%S"): Caffeinating DEP Notify process. Process ID: $DEP_NOTIFY_PROCESS" >> "$DEP_NOTIFY_DEBUG"
    caffeinate -disu -w "$DEP_NOTIFY_PROCESS"&
  fi

# Adding an alert prompt to let admins know that the script is in testing mode
  if [ "$TESTING_MODE" = true ]; then
    echo "Command: Alert: DEP Notify is in TESTING_MODE. Script will not run Policies or other commands that make change to this computer."  >> "$DEP_NOTIFY_LOG"
  fi

# Adding nice text and a brief pause for prettiness
  echo "Status: $INITAL_START_STATUS" >> "$DEP_NOTIFY_LOG"
  sleep 5

# Setting the status bar
  ADDITIONAL_OPTIONS_COUNTER=1
  # Checking policy array and adding the count from the additional options above.
    ARRAY_LENGTH="$((${#POLICY_ARRAY[@]}+ADDITIONAL_OPTIONS_COUNTER))"
    echo "Command: Determinate: $ARRAY_LENGTH" >> "$DEP_NOTIFY_LOG"

# Loop to run policies
  for POLICY in "${POLICY_ARRAY[@]}"; do
    echo "Status: $(echo "$POLICY" | cut -d ',' -f1)" >> "$DEP_NOTIFY_LOG"
    if [ "$TESTING_MODE" = true ]; then
      sleep 10
    elif [ "$TESTING_MODE" = false ]; then
      "$INST_BINARY" "$(echo "$POLICY" | cut -d ',' -f2)"
    fi
  done

# Nice completion text
  echo "Status: $INSTALL_COMPLETE_TEXT" >> "$DEP_NOTIFY_LOG"

# Check to see if FileVault Deferred enablement is active
  FV_DEFERRED_STATUS=$($FDE_SETUP_BINARY status | grep "Deferred" | cut -d ' ' -f6)

  # Logic to log user out if FileVault is detected. Otherwise, app will close.
    if [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = true ]; then
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Quit: This is typically where your FV_LOGOUT_TEXT would be displayed. However, TESTING_MODE is set to true and FileVault deferred status is on." >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: TESTING_MODE is set to true and FileVault deferred status is on. Button effect is quit instead of logout. \n \n $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButton: Test $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    elif [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = false ]; then
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Logout: $FV_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButtonLogout: $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    else
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Quit: $COMPLETE_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: $COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButton: $COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    fi

exit 0

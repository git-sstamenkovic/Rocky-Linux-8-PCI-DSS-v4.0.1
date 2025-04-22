#!/bin/bash

##################################################################################
#                                                                                #
#    Script Description:                                                         #
#                                                                                #
#    This script automates the installation, configuration, and                  #
#    periodic execution of AIDE (Advanced Intrusion Detection and                #
#    Examinations) software on Linux systems. AIDE is a host-based               #
#    intrusion detection system that monitors file integrity and                 #
#    can help detect unauthorized changes to system files.                       #
#                                                                                #
#    This script follows the configuration guidelines specified                  #
#    by the French cybersecurity agency (ANSSI) as outlined in                   #
#    the document "Linux Configuration" (https://cyber.gouv.fr).                 #
#                                                                                #
#    The script performs the following tasks:                                    #
#                                                                                #
#        1. Install AIDE software if it's not already installed.                 #
#        2. Initialize the AIDE database and perform integrity tests.            #
#        3. Schedule periodic checks of AIDE using cron.                         #
#                                                                                #
#    Note: It is important that system administrators verify                     #
#          system integrity and create backups before running this               #
#          script, as improper use could result in system issues.                #
#                                                                                #
#    Copyright (C) 2025, Sasa Stamenkovic | git@sasastamenkovic.com              #
#    | www.sasastamenkovic.com | All rights reserved.                            #
#                                                                                #
#    DISCLAIMER: This software is provided "as is" without any                   #
#                warranty of any kind, either express or implied, including      #
#                but not limited to the implied warranties of merchantability    #
#                and fitness for a particular purpose. The user assumes all      #
#                risks associated with its use. It is the responsibility of      #
#                the system administrator to ensure proper system backups        #
#                and minimize potential damage by using this program.            #
#                                                                                #
##################################################################################

# Function to prompt user for consent
prompt_user() {
    echo "################################################################"

    echo "WARNING: By using this script, you are acknowledging that you understand the following:"

    echo ""

    echo "    1. This script automates the installation, configuration, and periodic execution of AIDE 
    (Advanced Intrusion Detection and Examinations) software on Linux systems. AIDE is a 
    host-based intrusion detection system that monitors file integrity and can help detect 
    unauthorized changes to system files."

    echo ""

    echo "    2. This script follows the configuration guidelines specified by the French cybersecurity 
    agency (ANSSI) as outlined in the document 'Linux Configuration' (https://cyber.gouv.fr)."

    echo ""

    echo "    3. The script performs the following tasks:

        a) Install AIDE software if it's not already installed.
        b) Initialize the AIDE database and perform integrity tests.
        c) Schedule periodic checks of AIDE using cron."

    echo ""

    echo "    4. This script is provided 'as is' with no warranty of any kind."

    echo ""

    echo "Note: It is important that system administrators verify system integrity and create backups 
          before running this script, as improper use could result in data loss or system issues."

    echo "Do you agree to proceed with the installation and configuration? (yes/no)"

    read -r user_input

    if [[ "$user_input" != "yes" ]]; then
        echo "Exiting the script. Please ensure that you understand the implications of running this script."
        exit 1
    fi
}

# Call the prompt_user function to get user consent
prompt_user

# Spinner function to show progress
spinner() {
    local pid=$!
    local delay=0.2
    local spinstr='|/-\\'
    local temp

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        for i in `seq 0 3`; do
            temp=${spinstr:i:1}
            echo -n "$temp"
            echo -ne '\b'
            sleep $delay
        done
    done
    echo "✔️ Done!"
}

################################################################
# Step 1: Install AIDE                                         #
################################################################
echo "------------------------------------------------------------"
echo "Phase 1: Attempting to install AIDE software..."

# Check if AIDE is installed
if rpm --quiet -q kernel; then
    if ! rpm -q --quiet "aide"; then
        echo "AIDE is not installed. Installing AIDE..."
        yum install -y "aide" &
        spinner $!  # Show spinner during installation
        if [ $? -eq 0 ]; then
            echo "✔️ AIDE installation was successful."
        else
            echo "❌ Failed to install AIDE. Please check the error logs."
            exit 1
        fi
    else
        echo "✔️ AIDE is already installed."
    fi
else
    >&2 echo '❌ Remediation is not applicable: Kernel is not installed. Nothing was done.'
    exit 1
fi
echo "------------------------------------------------------------"

################################################################
# Step 2: Build/Test AIDE Database                             #
################################################################
echo "Phase 2: Initializing and testing AIDE database..."

if rpm --quiet -q kernel; then
    if rpm -q --quiet "aide"; then
        echo "Initializing AIDE database..."
        /usr/sbin/aide --init &
        spinner $!  # Show spinner during database initialization
        if [ $? -eq 0 ]; then
            echo "✔️ AIDE database initialized successfully."
        else
            echo "❌ Failed to initialize the AIDE database. Please check the error logs."
            exit 1
        fi

        # Backup the newly created database
        echo "Backing up the newly created AIDE database..."
        /bin/cp -p /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz &
        spinner $!  # Show spinner during backup
        if [ $? -eq 0 ]; then
            echo "✔️ AIDE database backup completed successfully."
        else
            echo "❌ Failed to backup the AIDE database. Please check the error logs."
            exit 1
        fi
    else
        echo "❌ AIDE is not installed. Please install AIDE first."
        exit 1
    fi
else
    >&2 echo '❌ Remediation is not applicable: Kernel is not installed. Nothing was done.'
    exit 1
fi
echo "------------------------------------------------------------"

################################################################
# Step 3: Configure Scheduled AIDE execution                   #
################################################################
echo "Phase 3: Configuring scheduled execution of AIDE..."

if rpm --quiet -q kernel; then
    if rpm -q --quiet "aide"; then
        echo "Checking if AIDE is scheduled to run daily..."

        # Check if AIDE cron job is already configured
        if ! grep -q "/usr/sbin/aide --check" /etc/crontab; then
            echo "Scheduling AIDE to run daily at 4:05 AM..."
            echo "05 4 * * * root /usr/sbin/aide --check" >> /etc/crontab &
            spinner $!  # Show spinner during cron job configuration
            if [ $? -eq 0 ]; then
                echo "✔️ AIDE cron job was successfully added to /etc/crontab."
            else
                echo "❌ Failed to add AIDE cron job. Please check the error logs."
                exit 1
            fi
        else
            echo "AIDE cron job is already scheduled. Updating the schedule..."
            sed -i '\!^.* --check.*$!d' /etc/crontab
            echo "05 4 * * * root /usr/sbin/aide --check" >> /etc/crontab &
            spinner $!  # Show spinner during cron job update
            if [ $? -eq 0 ]; then
                echo "✔️ AIDE cron job was successfully updated."
            else
                echo "❌ Failed to update AIDE cron job. Please check the error logs."
                exit 1
            fi
        fi
    else
        echo "❌ AIDE is not installed. Please install AIDE first."
        exit 1
    fi
else
    >&2 echo '❌ Remediation is not applicable: Kernel is not installed. Nothing was done.'
    exit 1
fi
echo "------------------------------------------------------------"

echo "✔️ Installation and configuration completed successfully!"

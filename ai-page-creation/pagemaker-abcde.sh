#!/bin/bash

# Copyright (c) 2025 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# This script reads topical information and several subtopical items to
# create a prompt and generate html suitable for insertion in live web
# pages. It uses golang based tgpt.

# This script is intended for creation of deep, thousand word pages, each
# on a specific topic but covering the "items"" in relation to the various
# main topics.
#
#  For example, a list of "pizza restaurants" for topics and a list of
#  pizza aspects for coverage on each page: pepperoni, supreme, corn-and-peppers,
#  and so forth.
#
#  To round out a website, you should prepare dozens of pairs of topic and items
#  files!

SITE_CODE="abcde"
PROV_NAME="pollinations"
PROMPT_SOURCES=(misc/"$SITE_CODE"-misc/group*)
OUTPUTPATH="finished-pages/$SITE_CODE"
TOPICS_FILE="topics"                          # broader subject to discuss
ITEMS_FILE="items"                            # more specific topics
TOP_DATA="misc/$SITE_CODE-misc/top"       # generic top of page
BOTTOM_DATA="misc/$SITE_CODE-misc/bottom" # generic bottom of page
TGPT_PATH="tgpt"
MAX_RETRIES=10
RETRY_DELAY=20

###############################################################################
# DRAGONS BELOW!
###############################################################################

# put a link to tgpt into the path if not already existing
[ -z "$(which tgpt)" ] && ln -sf $TGPT_PATH "$HOME"/.local/bin/tgpt
export TGPT="tgpt"

# create an output directory if it does not exist
[ -d "$OUTPUTPATH" ] || mkdir $OUTPUTPATH

for SOURCE in "${PROMPT_SOURCES[@]}"; do
    # read topics and items
    IFS=$'\n' read -rd '' -a TOPICS <<<"$(\cat "$SOURCE"/"$TOPICS_FILE")"
    IFS=$'\n' read -rd '' -a ITEMS <<<"$(\cat "$SOURCE"/"$ITEMS_FILE")"
    S=1 # sequence number
    for K in "${TOPICS[@]}"; do
        CONTENT=""
        TIME="$(date +"%Y-%m-%d_%H-%M-%S")" #timestamp
        SUMQ=""
        TARGETFILE="${OUTPUTPATH}/${TIME}-${S}.html"
        \cat "${TOP_DATA}" >"${TARGETFILE}"
        for Q in "${ITEMS[@]}"; do
            echo "Working on $K and $Q"
            # running list of items
            SUMQ="${SUMQ} ${Q}"
            # define prompt using heredoc
            PROMPT=$(cat << ZZZZZZZ
            Create HTML body text for an existing page; do not create any <head> or <h1>
            elements. Find recent information about $K with emphasis and details on $Q.
            Create HTML content in a narrative (storytelling) style. Use <h3> headers,
            bold <b>, and italic <i> elements for emphasis, as appropriate. Do not use
            emdashes or bullet points.
ZZZZZZZ
)
            # query for content and write it to the output file
            RETRY_COUNT=0
            while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
                # Submit the prompt to tgpt
                if CONTENT=$($TGPT --provider "${PROV_NAME}" "${PROMPT}" 2>/dev/null); then
                    # Check if the output contains error indicators (500/502)
                    if [[ $CONTENT =~ "error:.*status.*500" ]] || \
                        [[ $CONTENT =~ "error:.*status.*502" ]] || \
                        [[ $CONTENT =~ "500" ]] || \
                        [[ $CONTENT =~ "502" ]]; then
                        echo -e "\nError detected! Stand by $RETRY_DELAY for a retry...\n"
                        ((RETRY_COUNT++))
                        sleep $RETRY_DELAY
                        continue
                    fi
                    # If no error, break the loop
                    break
                else
                    # Command failed (non-zero exit code)
                    ((RETRY_COUNT++))
                    echo "Command failed. Retrying... ($RETRY_COUNT)"
                    sleep $RETRY_DELAY
                    continue
                fi
            done

            if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
                echo "Max retries reached."
            else
                echo "Success!"
                echo -e "\n$CONTENT\n" >>"${TARGETFILE}"
            fi

        done
        \cat "$BOTTOM_DATA" >>"${TARGETFILE}"
        ((S++))
        # put in a title and description
        sed -i "s|title=\"\"|title=\"${K}\"|g; \
            s|description=\"\"|description=\"${K} with consideration of several aspects, like ${SUMQ}.\"|g; \
            s|alt=\"\"|alt=\"${SUMQ}\"|g; \
            /^\r.*$/d" \
            "${TARGETFILE}"
    done
done

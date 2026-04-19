#!/bin/bash

# Copyright (c) 2025 by Philip Collier, github.com/AB9IL
# This script is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version. There is NO warranty; not even for
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# This script reads topical information, creates a prompt, and generates
# text suitable for assembly into books. It uses golang based tgpt.
#
# Note: Each chapter directory should contain sequentially numbered text
# files, each containing a markdown formatted outline snippet for one
# prompt for the ai provider. Format as a header follwed by short statements,
# questions, or list of topics. Keep each file concise and focused.

export PROV_NAME="pollinations"
export BOOKDATA=(book-*) # directories: book-01, book-02, etc
TGPT_PATH="tgpt"
export MAX_RETRIES=10
export RETRY_DELAY=20

###############################################################################
# DRAGONS BELOW!
###############################################################################

# put a link to tgpt into the path if not already existing
[ -z "$(which tgpt)" ] && ln -sf $TGPT_PATH "$HOME"/.local/bin/tgpt
export TGPT="tgpt"

make_chapter() {
    # 1 - book directories contain several chapter directories
    # 2 - sequentially read markdown notes within each chapter directory
    # 3 - create content and APPEND to the chapter text
    X=1
    for K in "$CHAPTER"/*; do
        DELAY="$((RANDOM % 9 + 1))"
        # TIME="$(date +"%Y-%m-%d_%H-%M-%S")"
        echo "Working on $CHAPTER and item $X"
        read -rd '' NOTE <<<"$(\cat "$K")"

        # define prompt using heredoc
        PROMPT=$(
            cat <<ZZZZZZZ
        Consider and discuss topics according to the following rules:
        1) format your answers in paragraphs; 2) avoid creating numbered or bullet
        pointed lists, but use markdown headers, bold, and italic text; 3) Discuss
        topics given in the following snippet of markdown text: $NOTE
ZZZZZZZ
        )
        # random delay before querying AI service
        sleep "$DELAY"
        # query for content and write it to the output file
        RETRY_COUNT=0
        CONTENT=""
        while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
            # Submit the prompt to tgpt
            if CONTENT=$($TGPT --provider "${PROV_NAME}" "${PROMPT}" 2>/dev/null); then
                # Check if the output contains error indicators (500/502)
                if [[ $CONTENT =~ "error:.*status.*500" ]] ||
                    [[ $CONTENT =~ "error:.*status.*502" ]] ||
                    [[ $CONTENT =~ "500" ]] ||
                    [[ $CONTENT =~ "502" ]]; then
                    ((RETRY_COUNT++))
                    echo -e "\nError detected! Stand by $RETRY_DELAY for a retry ($RETRY_COUNT)\n"
                    sleep $RETRY_DELAY
                    continue
                fi
                # If no error, break the loop
                break
            else
                # Command failed (non-zero exit code)
                ((RETRY_COUNT++))
                echo "Command failed! Stand by $RETRY_DELAY for a retry ($RETRY_COUNT)"
                sleep $RETRY_DELAY
                continue
            fi
        done

        if [[ $RETRY_COUNT -eq $MAX_RETRIES ]]; then
            echo "Max retries reached."
        else
            echo "Success!"
            # append results to the chapter
            echo -e "$CONTENT" | sed "/^\r.*$/d" > "output/${CHAPTER}".txt
        fi
        ((X++))
    done
}
export -f make_chapter

for BOOK in "${BOOKDATA[@]}"; do
    echo -e "\nWorking on $BOOK ...\n"
    CHAPTERS=("$BOOK"/*)
    for CHAPTER in "${CHAPTERS[@]}"; do
        export CHAPTER
        [ -d "output/$BOOK" ] || mkdir "output/$BOOK"
        sem --fg -j 4 make_chapter
    done
    echo -e "Book $BOOK complete!\n"
done
echo -e "All boks complete! \n"

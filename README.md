# tgpt_wordsmith

Scripts for using tgpt to create outline based web or book content using AI.

#### Description

These scripts are written in Bash. They read files containing data for building prompts, then run Terminal-GPT (tgpt) to create html or plaintext for use in web pages, books, or other prose.

Since the script builds the output file with many sequential queries to the AI service, you can probe topics in depth and produce multiple thousands of words of output.

These are a work in progress...

#### Requires:

- Bash
- [tgpt](https://github.com/aandrew-me/tgpt)

#### Suggestion:

- Know or have access to accurate knowledge about the topics. You need to create prompts focused on pertinent information in order to create good content. The AI models do not have judgement and will say silly or incorrect things, which you must find and correct in order to maintain your quality.
- The examples build multiple chapters or sets of web pages with raw data for prompts in book/chapter and group/misc directories.
  - For creating web pages, consider "topics" as pages, "items" as sectios within a page.
  - For creating books, content is broken down into subdirectories, with the most basic units set up in markdown.
- Be sure to edit the output and remove any junk text from the AI session.

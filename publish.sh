#!/bin/bash
#
# A script to copy the actually-for-the-template files to the `template`
# directory, to get it ready for the `publish.yml` GitHub workflow.

# Making `dist` do double-duty for Astro & for this, because:
#
# 1. this process isn't using `dist`
# 2. we don't want to clutter `.gitignore` with stuff that makes no sense in
#    the context of the template
rm -rf dist
mkdir -p dist

# Copy desired files into `dist`
rsync -av --progress .vscode .env.example .gitattributes .gitignore * \
  --include="src/contracts" \
  --exclude="dist" \
  --exclude="contracts" \
  --exclude="LICENSE" \
  --exclude="publish.sh" \
  --exclude="node_modules" \
  --exclude="target" \
  dist

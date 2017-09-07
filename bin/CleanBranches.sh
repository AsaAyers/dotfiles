#!/bin/bash

# Overview:
# 1. Update from all remotes
# 2. Checkout your default branch (usually master)
# 3. Pull updates for the default branch
# 4. If you pulled from an upstream, push default to origin
# 5. Remove local origin/BRANCH references to branches that have already been cleaned up
# 6. Delete your remote branches that have been merged into the remote default (master)
# 7. Delete your local branches that have been merged into local default (master)

PREFIX=$(git config --get CleanBranches.prefix)
DEFAULT_BRANCH=$(git config --get CleanBranches.defaultbranch)
UPSTREAM_REMOTE=$(git config --get CleanBranches.upstream)


# By default this script only shows the commands to clean up your branches.
# If you want this to actually delete your local and remote branches run:
# git config CleanBranches.removebranches true
REMOVE_BRANCHES=$(git config --get CleanBranches.removebranches)

BASE=$(basename $0)
if [ -z "$PREFIX" ]; then
  echo "$BASE will clean up branches that have already merged, but your branches"
  echo "need a prefix followed by a slash to know which ones are yours. ex: asa/my-feature"
  echo ""
  echo "Set your configuration with:"
  echo "git config CleanBranches.prefix your-prefix"
  exit 1
fi

if [ -z "$DEFAULT_BRANCH" ]; then
  DEFAULT_BRANCH="master"
fi

if [ -z "$UPSTREAM_REMOTE" ]; then
  UPSTREAM_REMOTE="upstream"
fi

if [ -z "$(git remote | grep $UPSTREAM_REMOTE)" ]; then
  if [ -z "$(git remote | grep origin)" ]; then
    echo "Unable to find remote $UPSTREAM_REMOTE"
    exit 1
  else
    UPSTREAM_REMOTE=origin
  fi
fi

if [ ! -z "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Commit or remove your changes first"
  git status
  exit 1
fi

if [ -z "$1" ]; then
  CHECKOUT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
else
  CHECKOUT_BRANCH=$1
fi

# if any of these commands fail, the whole process should abort
set -e
git remote update
git checkout $DEFAULT_BRANCH
git pull --ff-only $UPSTREAM_REMOTE $DEFAULT_BRANCH
set +e
if [ "$UPSTREAM_REMOTE" != "origin" ]; then
  git push origin $DEFAULT_BRANCH --no-verify
fi

# Remove local origin/BRANCH references to branches that have already been cleaned up
git remote prune origin

TARGET="$UPSTREAM_REMOTE/$DEFAULT_BRANCH"
# This uses `sed` instead of `cut` to remain compatible with branches that include slashes. ex: origin/asa/my-feature
BRANCHES=$(git branch --remote --merged $TARGET --list "origin/$PREFIX*" | sed s/"\s*origin\/"//g | grep --extended-regexp -v "(HEAD|dev|master)$")
echo "===== Finding remote branches that have merged into $TARGET"

if [ ! -z "$BRANCHES" ]; then
  DELETE_REMOTE="git push origin --no-verify"
  for B in $BRANCHES; do
    DELETE_REMOTE="$DELETE_REMOTE :$B"
  done
  if [ "$REMOVE_BRANCHES" == "true" ]; then
    $DELETE_REMOTE
  else
    echo "Run this to delete your remote branches:"
    echo "$DELETE_REMOTE"
  fi
fi

# The currently checked out branch is prefixed with a *.
# If it isn't removed, then it ends up getting expanded by bash.
BRANCHES=$(git branch --merged $TARGET | grep -v '^\*' | grep --extended-regexp -v "(HEAD|dev|master)$")
echo "===== Finding local branches that have merged into $TARGET"
for B in $BRANCHES; do
  DELETE_LOCAL="git branch --delete $B"
  if [ "$REMOVE_BRANCHES" == "true" ]; then
    $DELETE_LOCAL
  else
    echo "Run this to delete your local branches:"
    echo $DELETE_LOCAL
  fi
done

git branch -vv

if git branch | grep $CHECKOUT_BRANCH -q; then
  git checkout $CHECKOUT_BRANCH
fi

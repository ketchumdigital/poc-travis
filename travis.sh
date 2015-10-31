#!/bin/bash

LATEST_SHA="$(git log --format="%h" -n 1 | tr -d '\n' | tr -d ' ')"

LATEST_COMMIT="$(git diff-tree --no-commit-id --name-only --diff-filter=AM -r $LATEST_SHA | perl -ne 'print if /^sites\/all\/(?:themes|modules\/)(?!contrib).+?\.(?!css|gif|ico|info|jpg|jpeg|js|md|txt|patch|png|test)\w+$/')"

if [ -n "${LATEST_COMMIT}" ]; then 
  composer self-update
  composer global require drupal/coder
  composer global require squizlabs/PHP_CodeSniffer:\>=2
  ln -s ~/.composer/vendor/drupal/coder/coder_sniffer/Drupal ~/.composer/vendor/squizlabs/php_codesniffer/CodeSniffer/Standards/
  export PATH="$HOME/.composer/vendor/bin:$PATH"

  while read -r file; do

    IS_PHP="$(head -1 ${file} | perl -ne 'print "$&\n" if /(?<=\<\?)php/')"
    if [ -n "${IS_PHP}"  ]; then

      echo -e "[ \033[00;32mPHP\033[0m ] ${file}\n"

      phpcbf --colors --encoding=utf-8 --error-severity=1 --warning-severity=8 --standard=Drupal ${file}

    fi
    unset IS_PHP

  done <<< "${LATEST_COMMIT}"
  unset file


  git checkout -b $TRAVIS_BRANCH-amend
  git add --all &> /dev/null
  git commit --m "Amended: $LATEST_SHA $(git log --format="%s" -n 1 | tr -d '\n')"
  git remote add deploy git@github.com:$TRAVIS_REPO_SLUG.git

fi

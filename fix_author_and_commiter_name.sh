#!/bin/bash

git filter-branch --env-filter '

search_mail="krzysztof.wilczynski@linux.com"

new_name="Krzysztof Wilczynski"
new_mail="krzysztof.wilczynski@linux.com"

author_name="${GIT_AUTHOR_NAME}"
author_mail="${GIT_AUTHOR_EMAIL}"

commiter_name="${GIT_COMMITTER_NAME}"
commiter_mail="${GIT_COMMITTER_EMAIL}"

if [ "${GIT_AUTHOR_EMAIL}" = "${search_mail}" ] ; then

    author_name="${new_name}"
    author_mail="${new_mail}"
fi

if [ "${GIT_COMMITTER_EMAIL}" = "${search_mail}" ] ; then

    commiter_name="${new_name}"
    commiter_mail="${new_mail}"
fi

export GIT_AUTHOR_NAME="${author_name}"
export GIT_AUTHOR_EMAIL="${author_mail}"

export GIT_COMMITTER_NAME="${commiter_name}"
export GIT_COMMITTER_EMAIL="${commiter_mail}"
'

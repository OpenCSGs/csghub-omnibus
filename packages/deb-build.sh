#!/bin/bash

if [ -z "$CI_COMMIT_TAG" ]; then
  exit 0
fi

mkdir omnibus-csghub-${CI_COMMIT_TAG}

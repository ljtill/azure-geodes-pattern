#!/usr/bin/env bash

az stack sub delete \
    --name 'Microsoft.Patterns' \
    --action-on-unmanage 'deleteAll' \
    --yes \
    --debug

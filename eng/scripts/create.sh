#!/usr/bin/env bash

az stack sub create \
    --name 'Microsoft.Patterns' \
    --template-file './src/main.bicep' \
    --parameters './src/parameters/main.bicepparam' \
    --deny-settings-mode 'none' \
    --action-on-unmanage 'deleteAll' \
    --yes \
    --debug

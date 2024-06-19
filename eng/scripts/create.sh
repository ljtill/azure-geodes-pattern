#!/usr/bin/env bash

az stack sub create \
    --name 'Microsoft.Patterns' \
    --template-file './src/main.bicep' \
    --parameters './src/parameters/main.bicepparam' \
    --action-on-unmanage 'deleteAll' \
    --deny-settings-mode 'denyWriteAndDelete' \
    --yes

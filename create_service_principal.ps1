
# /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>

az ad sp create-for-rbac --name "github-actions-sp" --role contributor --scopes /subscriptions/b9144b57-a2c0-4fe8-80ab-10fe51d32287/resourceGroups/Test_IOC --json-auth


# Take the output, store it as a single string in GitHub as a secret





az ad sp create-for-rbac --name "github-actions-sp" --role Contributor --scopes /subscriptions/b9144b57-a2c0-4fe8-80ab-10fe51d32287 --json-auth

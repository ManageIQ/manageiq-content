# Contributing to manageiq-content

We typically have a use case to edit or add automate classes or instances into the ManageIQ domain when we are introducing a new provider or adding a new feature. After we make the changes to the Automate model we want to commit the changes to the git repository to create a pull request.

When we have to edit existing instances/classes or add new instances/classes to an Automate Domain like ManageIQ we have 2 options

1. Edit the Model using the Automate Explorer
2. Make the changes directly by manually editing the YAML files on the disk

Option 1 requires that you unlock the ManageIQ domain before you make the changes and lock it back after you have made the changes.

Option 2 is prone to editing errors and also flags unnecessary changes when trying to keep the files in sync on the disk with the data in the DB.

If we use Option 1 from above we will make all the changes using the Automate Explorer, this might be a slow process but it ensures that the data can stay in sync and prevents user errors. After we are satisfied with the changes we can export the ManageIQ domain to the disk so we can commit the changes to the repository.

1. Unlock the ManageIQ domain
2. Make the changes using the Automate Explorer
3. Test all your changes
4. Lock the ManageIQ domain
5. Export the ManageIQ domain
   `bin/rake evm:automate:export DOMAIN=ManageIQ EXPORT_DIR=/your_src_dir/manageiq/db/fixtures/ae_datastore/ OVERWRITE=true`
6. `git diff` (Should only list your changes)
7. Commit your changes to build the PR

If you use Option 2 where you have manually edited files on the disk, the steps would be

1. Make manual changes to the YAML files
2. Import it into the ManageIQ domain
3. Test and make sure your changes work
4. Export the ManageIQ domain using
   `bin/rake evm:automate:export DOMAIN=ManageIQ EXPORT_DIR=/your_src_dir/manageiq/db/fixtures/ae_datastore/ OVERWRITE=true`
5. `git diff` (should only show your changes)
6. Check in the changes into the git repository

Step 4 is very critical because it uses the consistent YAML export package to create the model files on the disk. So things like

* New Lines (Carriage Return, Line Feeds)
* Double Quotes versus Single Quotes
* Other escape sequences
* Inconsistent names, the filename on disk can be different from the internal name stored in the YAML files.

Are all consistent, when you hand edit these files you might not see these nuances.

To unlock the ManageIQ domain use the following command from a rails console:

```ruby
MiqAeDomain.find_by_name("ManageIQ").update_attribute(:source, "user")
```

To lock the ManageIQ domain use the following command from a rails console:

```ruby
MiqAeDomain.find_by_name("ManageIQ").update_attribute(:source, "system")
```

Please note that after you do a round trip of the ManageIQ domain you would still see that `db/fixtures/ae_datastore/ManageIQ/__domain__.yaml` would be different because it has the tenant_id which is different from appliance to appliance. The tenant_id is used only when a customer does a backup/restore, when doing normal imports the tenant_id is ignored and we use the actual tenant_id from the appliance where the import is being run.

The `__domain__.yaml` file from the ManageIQ folder should never be included in the PR.

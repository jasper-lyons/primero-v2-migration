These Scripts are for exporting and generating v2 compatible data migration scripts on a 1.7 system.
==================================================================================================


If this is the anonymized migration run, anonymize the production data before doing the migration
=================================================================================================
- Refer to the [Anonymization README](./anonymizers/README.md) for more detail.


Exporting the data on a v1 system
==================================

Copy the export scripts to the v1.7 system
-------------------------------------------
- check out the desired tag/branch of this repo
- scp the contents of the data directory to the target system.
  Sepcifically, you will need export_data.rb and everything under the exporters directory


Run the script on the v1.7 system
---------------------------------
- ssh to the 1.7 system
- $ sudo -Hu primero bash
- $ cd ~/application/
- $ $ RAILS_ENV=production bundle exec rails r /home/ubuntu/data/export_data.rb

(This will generate files in a record-data-files directory)


Tar up the record-data-files
----------------------------
- exit back to the ubuntu user
- $ cd /srv/primero/application
- $ sudo tar czvf record-data-files.tar.gz record-data-files
- $ cd
- $ sudo mv /srv/primero/application/record-data-files.tar.gz .



Load the generated data migration scripts on a v2 server
========================================================

Copy / scp the tar file to the target v2 server
-------------------------------------------------

Untar the tar file on the v2 server
----------------------------------------
$ tar -xzvf record-data-files.tar.gz


Copy the import script to the v2 server
-----------------------------------------
- If you haven't already, check out the desired tag/branch of this repo
- scp the import_data.rb script to the target system.
- the record-data-files directory should be at the same level as the import_data.rb script
  Ex:   /home/ubuntu/import_data.rb
        /home/ubuntu/record-data-files/*

Copy the users import script to the v2 server.
-------------------------------------------------------------------------------
- Refer to the [User Migration README](../users/README.md) for more detail.


If you have any implementation specific migrations, copy them to the v2 server
------------------------------------------------------------------------------
Some configurations require additional migration scripts that do not apply to all configurations.
Those migrations are to be created and stored in the configuration repository of your particular configuration.
- Create these under a migrations folder under your configuration root directory.
- Use naming format:  000_<script name>, 001_<second script name>, 002_<third script name>, etc.


ON THE v2 SERVER
----------------------

Run user migrations.
------------------------------------------------------
- Refer to the [User Migration README](../users/README.md) for more detail.


Copy the scripts to the application docker container
------------------------------------------------------
- $ docker ps   (to get the name of the application image)
- $ docker cp record-data-files primero_application_1:/srv/primero/application/tmp/.  (where primero_application_1 is the image name)
- $ docker cp import_data.rb primero_application_1:/srv/primero/application/tmp/.


If you have any implementation specific migrations, copy them to the docker container, same as above
----------------------------------------------------------------------------------------------------
EXAMPLE
- $ docker cp migrations primero_application_1:/srv/primero/application/tmp/.


Run the script in the docker container
---------------------------------------
- $ sudo docker exec -it primero_application_1 bash  (to access the docker container)
- $ cd /srv/primero/application
- $ rails r ./tmp/import_data.rb > import_data.out

If you have any implementation specific migrations, run them in the docker container
------------------------------------------------------------------------------------
EXAMPLE
- $ rails r tmp/migrations/000_migrate_incident_fields.rb


Still in the docker container, reindex solr
-------------------------------------------
- $ rake sunspot:remove_all
- $ rake sunspot:reindex
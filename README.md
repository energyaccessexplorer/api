# Energy Access Explorer Database API

The API is delegated [PostgREST](https://postgrest.org/en/stable/). Do check
their documentation on setting it up.

The logic is handled by the SQL code and the
[database](https://github.com/energyaccessexplorer/database) is assumed be
installed and running.

This repository only contains the tools to generate PostgREST's configuration
file and a couple shell scripts to start/check that it is running.

# Installing/Building

The installation of PostgREST is trivial since it is a single binary file.

Clone the project and edit the variables on the `makefile` to your needs. Then,
run:

	$ bmake pgrest.conf check.sh start.sh env=production

Then, copy (if necessary) those files respectively to the deployment server.

Other utilities are available to start/stop the PostREST instance remotely.

	$ bmake deploy env=production
	$ bmake apistart env=production
	$ bmake apistop env=production
	$ bmake apirestart env=production

# Bulk Secrets Manager extract/load tool

These rudimentary scripts allow for bulk editing of AWS Secrets Manager
secrets.

They make the process of setting the secrets in a new AWS account much less
time-consuming.

The local representation is tab-separated values (because comma-separated leads
to awkward quoting issues given that the secrets values are JSON).

The intended usage is to run `dump_secrets.py` on an existing account (for
example staging), edit the TSV file to change any secret values which need to
be different in the new account, then run `load_secrets.py` on the new account.

The `template.tsv` file lists all the secrets which are required (currently
only the frontend ones, for staging and production), without the actual secret
values. This is included to make it easier to tell which secrets to remove,
i.e. which ones are not related to Replatforming. At the time of writing there
are only a few of these.

See the scripts themselves for usage examples.

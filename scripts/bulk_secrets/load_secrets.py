#!/usr/bin/env python3
#
# Usage: gds aws govuk-staging-admin -- ./load_secrets.py < secrets.tsv

import csv
import pprint
import sys

import boto3

csv.register_dialect('tab-lazy-quoted', delimiter='\t', quoting=csv.QUOTE_MINIMAL)


def create_secrets(secrets):
    client = boto3.client('secretsmanager')
    tags = {
        'project': 'replatforming',
    }
    for secret in secrets:
        pprint.pp(secret)
        res = client.create_secret(
            Tags=[{'Key': k, 'Value': v} for k, v in tags.items()],
            **secret)
        pprint.pp(res)


if __name__ == '__main__':
    create_secrets(csv.DictReader(sys.stdin, dialect='tab-lazy-quoted'))

#!/usr/bin/env python3
#
# Usage: gds aws govuk-integration-admin -- ./dump_secrets.py >integration.tsv

import csv
import sys

import boto3

csv.register_dialect('tab-lazy-quoted', delimiter='\t', quoting=csv.QUOTE_MINIMAL)


def get_secrets(client):
    secrets = []
    res = client.list_secrets()
    secrets.extend(res['SecretList'])
    cursor = res['NextToken']
    while cursor:
        res = client.list_secrets(NextToken=cursor)
        secrets.extend(res['SecretList'])
        cursor = res.get('NextToken', '')
    return secrets


def get_secret_value(client, name):
    res = client.get_secret_value(SecretId=name)
    return res['SecretString']


def dump_secrets(fp):
    writer = csv.DictWriter(
            fp, ['Name', 'Description', 'SecretString'],
            dialect='tab-lazy-quoted')
    writer.writeheader()
    for s in secrets:
        secret = {
            'Name': s['Name'],
            'Description': s.get('Description', ''),
            'SecretString': get_secret_value(client, s['Name']),
        }
        writer.writerow(secret)


if __name__ == '__main__':
    client = boto3.client('secretsmanager')
    secrets = get_secrets(client)
    dump_secrets(sys.stdout)

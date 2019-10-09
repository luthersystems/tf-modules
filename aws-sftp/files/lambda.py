import os
import json
import boto3
import base64
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    resp_data = {}

    if 'username' not in event or 'serverId' not in event:
        print("Incoming username or serverId missing  - Unexpected")
        return response_data

    username = event['username']
    # not currently being used for verification
    server_id = event['serverId']
    print("Username: {}, ServerId: {}".format(username, server_id));

    if 'password' in event:
        password = event['password']
    else:
        print("No password, checking for SSH public key")
        password = ''

    # Lookup user's secret which can contain the password or SSH public keys
    key_prefix = os.environ['KeyPrefix']
    resp = get_secret(key_prefix + "/" + username)

    if resp != None:
        resp_dict = json.loads(resp)
    else:
        print("Secrets Manager exception thrown")
        return {}

    if password != '':
        if 'Password' in resp_dict:
            resp_password = resp_dict['Password']
        else:
            print("Unable to authenticate user - No field match in Secret for password")
            return {}

        if resp_password != password:
            print("Unable to authenticate user - Incoming password does not match stored")
            return {}
    else:
        # SSH Public Key Auth Flow - The incoming password was empty so we are trying ssh auth and need to return the public key data if we have it
        if 'PublicKey' in resp_dict:
            resp_data['PublicKeys'] = [resp_dict['PublicKey']]
        else:
            print("Unable to authenticate user - No public keys found")
            return {}

    # If we've got this far then we've either authenticated the user by password or we're using SSH public key auth and
    # we've begun constructing the data response. Check for each key value pair.
    # These are required so set to empty string if missing
    if 'Role' in resp_dict:
        resp_data['Role'] = resp_dict['Role']
    else:
        print("No field match for role - Set empty string in response")
        resp_data['Role'] = ''

    # These are optional so ignore if not present
    if 'Policy' in resp_dict:
        resp_data['Policy'] = resp_dict['Policy']


    if 'HomeDirectoryDetails' in resp_dict:
        if 'HomeDirectory' in resp_dict:
            print("HomeDirectory and HomeDirectoryDetails set.  Ignoring HomeDirectory")
        resp_data['HomeDirectoryDetails'] = resp_dict['HomeDirectoryDetails']
        resp_data['HomeDirectoryType'] = "LOGICAL"
    elif 'HomeDirectory' in resp_dict:
        resp_data['HomeDirectory'] = resp_dict['HomeDirectory']
    else:
        print("HomeDirectory / HomeDirectoryDetails not found - Defaulting to /")

    print("Completed Response Data: "+json.dumps(resp_data))
    return resp_data

def get_secret(id):
    region = os.environ['SecretsManagerRegion']
    client = boto3.session.Session().client(service_name='secretsmanager', region_name=region)

    try:
        resp = client.get_secret_value(SecretId=id)
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in resp:
            return resp['SecretString']
        else:
            return base64.b64decode(resp['SecretBinary'])
    except ClientError as err:
        print('Error Talking to SecretsManager: ' + err.response['Error']['Code'] + ', Message: ' + str(err))
        return None

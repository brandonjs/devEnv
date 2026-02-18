from elasticsearch import Elasticsearch, RequestsHttpConnection
from requests_aws4auth import AWS4Auth
import boto3
import json

host = 'search-varialo-esclus-1oig6smbl9yps-3ycbn6pxtjkrpklnfybiwuhgku.us-east-1.es.amazonaws.com' # For example, my-test-domain.us-east-1.es.amazonaws.com
region = 'us-east-1' # e.g. us-west-1

service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

es = Elasticsearch(
    hosts = [{'host': host, 'port': 443}],
    http_auth = awsauth,
    use_ssl = True,
    verify_certs = True,
    connection_class = RequestsHttpConnection
)

document = {
    "account": "971593487406"
}

#es.index(index="varia*", doc_type="_doc", id="5", body=document)
#result = es.search(q='ssm_execution_id=fbe9482e-b72b-490b-9692-afe5326a7b61')
result = es.search(index="varia-2020-06", body={"query": {"match": {"ssm_execution_id": "fbe9482e-b72b-490b-9692-afe5326a7b61"}}})
res = [x.get('_source') for x in result.get('hits').get('hits')]
command_id = next(x.get('ssm_command_id') for x in res if x.get('ssm_command_id'))
#command_result = es.search(q=f'ssm_command_id={command_id}')
command_result = es.search(index="varia-2020-06", body={"query": {"match": {"ssm_command_id": command_id}}})
res2 = [x.get('_source') for x in command_result.get('hits').get('hits')]
print(json.dumps(res2 + res))

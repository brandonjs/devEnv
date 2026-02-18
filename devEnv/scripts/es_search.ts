const AWSElasticSearchConnection = require('@amzn/aws-elasticsearch-connection');
const ElasticSearch = require('@elastic/elasticsearch');
const AWS = require('aws-sdk')
const region = 'us-east-1'
const accountId = '752742665648'

AWS.config.update({
  maxRetries: 3,
  retryDelayOptions: { base: 200 },
  stsRegionalEndpoints: 'regional',
  region: region
})

async function assumeRole(accountId) {
  const roleArn = `arn:aws:iam::${accountId}:role/VariaLogsInfrastructure-beta-us-KibanaRole51243B3F-OIMBWG5XIPH7`
  //const roleArn = `arn:${process.env.AWS_PARTITION}:iam::${accountId}:role/VariaLogsAuditorRole`
  const randomStr = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 8)
  const params = {
    ExternalId: `Kibana${accountId}`,
    RoleArn: roleArn,
    RoleSessionName: `Kibana-${randomStr}`
  }
  var sts = new AWS.STS({stsRegionalEndpoints: 'regional'})

  return new Promise((resolve, reject) => {
    sts.assumeRole(
      params,
      (err, data) => {
        if (err) {
          if (err.code === 'RegionDisabledException') {
            this.setFallbackEndpoint(this.sts)
          }
          return reject(err)
        } else {
          if (data.Credentials) {
            resolve(new AWS.Credentials({
              accessKeyId: data.Credentials.AccessKeyId,
              secretAccessKey: data.Credentials.SecretAccessKey,
              sessionToken: data.Credentials.SessionToken
            }))
          } else {
            const errMsg = 'Credentials were unable to be fetched.'
            console.error(errMsg)
            return reject(new Error(errMsg))
          }
       }
    })
  })
}

async function getDomainEndpoint(assumedCreds) {
  //var es = new AWS.ES({ credentials: assumedCreds})
  var es = new AWS.ES()
  return new Promise((resolve, reject) => {
    es.listDomainNames((err, data) => {
      if (err) console.log(err, err.stack); // an error occurred
      else {
        const domainName = data.DomainNames.find(r => { return r.DomainName.startsWith('varia') }).DomainName
        es.describeElasticsearchDomain({DomainName: domainName}, (err, data) => { 
          if (err) console.log(err, err.stack); // an error occurred
          else {
            resolve(data.DomainStatus.Endpoint)
          }
        })
      }
    })
  })
}


async function run () {
  const assumedCreds = 'nothing' // await assumeRole(accountId)
  const esEndpoint = await getDomainEndpoint(assumedCreds)

  const host = `https://${esEndpoint}`
  var esClient = new ElasticSearch.Client({node: host, Connection: AWSElasticSearchConnection})
  var query = { query: { match: { ssm_execution_id: "fbe9482e-b72b-490b-9692-afe5326a7b61" }}}
  var { body } = await esClient.search({
    index: 'varia-2020-06',
    body: query
  })
  var results = body.hits.hits.map(s => s._source)
  var command_id = results.find(e => { if (e.ssm_command_id) { return e.ssm_command_id }}).ssm_command_id
  query = { query: { match: {ssm_command_id: command_id}} }
  var { body } = await esClient.search({
    index: 'varia-2020-06',
    body: query
  })
  var command_res = body.hits.hits.map(s => s._source)
  console.log(results.concat(command_res))
}
run().catch(console.log)

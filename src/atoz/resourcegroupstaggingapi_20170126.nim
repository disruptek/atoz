
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Resource Groups Tagging API
## version: 2017-01-26
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Resource Groups Tagging API</fullname> <p>This guide describes the API operations for the resource groups tagging.</p> <p>A tag is a label that you assign to an AWS resource. A tag consists of a key and a value, both of which you define. For example, if you have two Amazon EC2 instances, you might assign both a tag key of "Stack." But the value of "Stack" might be "Testing" for one and "Production" for the other.</p> <p>Tagging can help you organize your resources and enables you to simplify resource management, access management and cost allocation. </p> <p>You can use the resource groups tagging API operations to complete the following tasks:</p> <ul> <li> <p>Tag and untag supported resources located in the specified region for the AWS account</p> </li> <li> <p>Use tag-based filters to search for resources located in the specified region for the AWS account</p> </li> <li> <p>List all existing tag keys in the specified region for the AWS account</p> </li> <li> <p>List all existing values for the specified key in the specified region for the AWS account</p> </li> </ul> <p/> <p>To use resource groups tagging API operations, you must add the following permissions to your IAM policy:</p> <ul> <li> <p> <code>tag:GetResources</code> </p> </li> <li> <p> <code>tag:TagResources</code> </p> </li> <li> <p> <code>tag:UntagResources</code> </p> </li> <li> <p> <code>tag:GetTagKeys</code> </p> </li> <li> <p> <code>tag:GetTagValues</code> </p> </li> </ul> <p>You'll also need permissions to access the resources of individual services so that you can tag and untag those resources.</p> <p>For more information on IAM policies, see <a href="http://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_manage.html">Managing IAM Policies</a> in the <i>IAM User Guide</i>.</p> <p>You can use the Resource Groups Tagging API to tag resources for the following AWS services.</p> <ul> <li> <p>Alexa for Business (a4b)</p> </li> <li> <p>API Gateway</p> </li> <li> <p>AWS AppStream</p> </li> <li> <p>AWS AppSync</p> </li> <li> <p>AWS App Mesh</p> </li> <li> <p>Amazon Athena</p> </li> <li> <p>Amazon Aurora</p> </li> <li> <p>AWS Backup</p> </li> <li> <p>AWS Certificate Manager</p> </li> <li> <p>AWS Certificate Manager Private CA</p> </li> <li> <p>Amazon Cloud Directory</p> </li> <li> <p>AWS CloudFormation</p> </li> <li> <p>Amazon CloudFront</p> </li> <li> <p>AWS CloudHSM</p> </li> <li> <p>AWS CloudTrail</p> </li> <li> <p>Amazon CloudWatch (alarms only)</p> </li> <li> <p>Amazon CloudWatch Events</p> </li> <li> <p>Amazon CloudWatch Logs</p> </li> <li> <p>AWS CodeBuild</p> </li> <li> <p>AWS CodeCommit</p> </li> <li> <p>AWS CodePipeline</p> </li> <li> <p>AWS CodeStar</p> </li> <li> <p>Amazon Cognito Identity</p> </li> <li> <p>Amazon Cognito User Pools</p> </li> <li> <p>Amazon Comprehend</p> </li> <li> <p>AWS Config</p> </li> <li> <p>AWS Data Pipeline</p> </li> <li> <p>AWS Database Migration Service</p> </li> <li> <p>AWS Datasync</p> </li> <li> <p>AWS Direct Connect</p> </li> <li> <p>AWS Directory Service</p> </li> <li> <p>Amazon DynamoDB</p> </li> <li> <p>Amazon EBS</p> </li> <li> <p>Amazon EC2</p> </li> <li> <p>Amazon ECR</p> </li> <li> <p>Amazon ECS</p> </li> <li> <p>AWS Elastic Beanstalk</p> </li> <li> <p>Amazon Elastic File System</p> </li> <li> <p>Elastic Load Balancing</p> </li> <li> <p>Amazon ElastiCache</p> </li> <li> <p>Amazon Elasticsearch Service</p> </li> <li> <p>AWS Elemental MediaLive</p> </li> <li> <p>AWS Elemental MediaPackage</p> </li> <li> <p>AWS Elemental MediaTailor</p> </li> <li> <p>Amazon EMR</p> </li> <li> <p>Amazon FSx</p> </li> <li> <p>Amazon Glacier</p> </li> <li> <p>AWS Glue</p> </li> <li> <p>Amazon Inspector</p> </li> <li> <p>AWS IoT Analytics</p> </li> <li> <p>AWS IoT Core</p> </li> <li> <p>AWS IoT Device Defender</p> </li> <li> <p>AWS IoT Device Management</p> </li> <li> <p>AWS IoT Greengrass</p> </li> <li> <p>AWS Key Management Service</p> </li> <li> <p>Amazon Kinesis</p> </li> <li> <p>Amazon Kinesis Data Analytics</p> </li> <li> <p>Amazon Kinesis Data Firehose</p> </li> <li> <p>AWS Lambda</p> </li> <li> <p>AWS License Manager</p> </li> <li> <p>Amazon Machine Learning</p> </li> <li> <p>Amazon MQ</p> </li> <li> <p>Amazon MSK</p> </li> <li> <p>Amazon Neptune</p> </li> <li> <p>AWS OpsWorks</p> </li> <li> <p>Amazon RDS</p> </li> <li> <p>Amazon Redshift</p> </li> <li> <p>AWS Resource Access Manager</p> </li> <li> <p>AWS Resource Groups</p> </li> <li> <p>AWS RoboMaker</p> </li> <li> <p>Amazon Route 53</p> </li> <li> <p>Amazon Route 53 Resolver</p> </li> <li> <p>Amazon S3 (buckets only)</p> </li> <li> <p>Amazon SageMaker</p> </li> <li> <p>AWS Secrets Manager</p> </li> <li> <p>AWS Service Catalog</p> </li> <li> <p>Amazon Simple Notification Service (SNS)</p> </li> <li> <p>Amazon Simple Queue Service (SQS)</p> </li> <li> <p>AWS Simple System Manager (SSM)</p> </li> <li> <p>AWS Step Functions</p> </li> <li> <p>AWS Storage Gateway</p> </li> <li> <p>AWS Transfer for SFTP</p> </li> <li> <p>Amazon VPC</p> </li> <li> <p>Amazon WorkSpaces</p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/tagging/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772588 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772588](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772588): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "tagging.ap-northeast-1.amazonaws.com", "ap-southeast-1": "tagging.ap-southeast-1.amazonaws.com",
                           "us-west-2": "tagging.us-west-2.amazonaws.com",
                           "eu-west-2": "tagging.eu-west-2.amazonaws.com", "ap-northeast-3": "tagging.ap-northeast-3.amazonaws.com", "eu-central-1": "tagging.eu-central-1.amazonaws.com",
                           "us-east-2": "tagging.us-east-2.amazonaws.com",
                           "us-east-1": "tagging.us-east-1.amazonaws.com", "cn-northwest-1": "tagging.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "tagging.ap-south-1.amazonaws.com",
                           "eu-north-1": "tagging.eu-north-1.amazonaws.com", "ap-northeast-2": "tagging.ap-northeast-2.amazonaws.com",
                           "us-west-1": "tagging.us-west-1.amazonaws.com", "us-gov-east-1": "tagging.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "tagging.eu-west-3.amazonaws.com",
                           "cn-north-1": "tagging.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "tagging.sa-east-1.amazonaws.com",
                           "eu-west-1": "tagging.eu-west-1.amazonaws.com", "us-gov-west-1": "tagging.us-gov-west-1.amazonaws.com", "ap-southeast-2": "tagging.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "tagging.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "tagging.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "tagging.ap-southeast-1.amazonaws.com",
      "us-west-2": "tagging.us-west-2.amazonaws.com",
      "eu-west-2": "tagging.eu-west-2.amazonaws.com",
      "ap-northeast-3": "tagging.ap-northeast-3.amazonaws.com",
      "eu-central-1": "tagging.eu-central-1.amazonaws.com",
      "us-east-2": "tagging.us-east-2.amazonaws.com",
      "us-east-1": "tagging.us-east-1.amazonaws.com",
      "cn-northwest-1": "tagging.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "tagging.ap-south-1.amazonaws.com",
      "eu-north-1": "tagging.eu-north-1.amazonaws.com",
      "ap-northeast-2": "tagging.ap-northeast-2.amazonaws.com",
      "us-west-1": "tagging.us-west-1.amazonaws.com",
      "us-gov-east-1": "tagging.us-gov-east-1.amazonaws.com",
      "eu-west-3": "tagging.eu-west-3.amazonaws.com",
      "cn-north-1": "tagging.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "tagging.sa-east-1.amazonaws.com",
      "eu-west-1": "tagging.eu-west-1.amazonaws.com",
      "us-gov-west-1": "tagging.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "tagging.ap-southeast-2.amazonaws.com",
      "ca-central-1": "tagging.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "resourcegroupstaggingapi"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_GetResources_772924 = ref object of OpenApiRestCall_772588
proc url_GetResources_772926(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetResources_772925(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourcesPerPage: JString
  ##                   : Pagination limit
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_773038 = query.getOrDefault("ResourcesPerPage")
  valid_773038 = validateParameter(valid_773038, JString, required = false,
                                 default = nil)
  if valid_773038 != nil:
    section.add "ResourcesPerPage", valid_773038
  var valid_773039 = query.getOrDefault("PaginationToken")
  valid_773039 = validateParameter(valid_773039, JString, required = false,
                                 default = nil)
  if valid_773039 != nil:
    section.add "PaginationToken", valid_773039
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773040 = header.getOrDefault("X-Amz-Date")
  valid_773040 = validateParameter(valid_773040, JString, required = false,
                                 default = nil)
  if valid_773040 != nil:
    section.add "X-Amz-Date", valid_773040
  var valid_773041 = header.getOrDefault("X-Amz-Security-Token")
  valid_773041 = validateParameter(valid_773041, JString, required = false,
                                 default = nil)
  if valid_773041 != nil:
    section.add "X-Amz-Security-Token", valid_773041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773055 = header.getOrDefault("X-Amz-Target")
  valid_773055 = validateParameter(valid_773055, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetResources"))
  if valid_773055 != nil:
    section.add "X-Amz-Target", valid_773055
  var valid_773056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773056 = validateParameter(valid_773056, JString, required = false,
                                 default = nil)
  if valid_773056 != nil:
    section.add "X-Amz-Content-Sha256", valid_773056
  var valid_773057 = header.getOrDefault("X-Amz-Algorithm")
  valid_773057 = validateParameter(valid_773057, JString, required = false,
                                 default = nil)
  if valid_773057 != nil:
    section.add "X-Amz-Algorithm", valid_773057
  var valid_773058 = header.getOrDefault("X-Amz-Signature")
  valid_773058 = validateParameter(valid_773058, JString, required = false,
                                 default = nil)
  if valid_773058 != nil:
    section.add "X-Amz-Signature", valid_773058
  var valid_773059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773059 = validateParameter(valid_773059, JString, required = false,
                                 default = nil)
  if valid_773059 != nil:
    section.add "X-Amz-SignedHeaders", valid_773059
  var valid_773060 = header.getOrDefault("X-Amz-Credential")
  valid_773060 = validateParameter(valid_773060, JString, required = false,
                                 default = nil)
  if valid_773060 != nil:
    section.add "X-Amz-Credential", valid_773060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773084: Call_GetResources_772924; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ## 
  let valid = call_773084.validator(path, query, header, formData, body)
  let scheme = call_773084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773084.url(scheme.get, call_773084.host, call_773084.base,
                         call_773084.route, valid.getOrDefault("path"))
  result = hook(call_773084, url, valid)

proc call*(call_773155: Call_GetResources_772924; body: JsonNode;
          ResourcesPerPage: string = ""; PaginationToken: string = ""): Recallable =
  ## getResources
  ## <p>Returns all the tagged or previously tagged resources that are located in the specified region for the AWS account. You can optionally specify <i>filters</i> (tags and resource types) in your request, depending on what information you want returned. The response includes all tags that are associated with the requested resources.</p> <note> <p>You can check the <code>PaginationToken</code> response parameter to determine if a query completed. Queries can occasionally return fewer results on a page than allowed. The <code>PaginationToken</code> response parameter value is <code>null</code> <i>only</i> when there are no more results to display. </p> </note>
  ##   ResourcesPerPage: string
  ##                   : Pagination limit
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_773156 = newJObject()
  var body_773158 = newJObject()
  add(query_773156, "ResourcesPerPage", newJString(ResourcesPerPage))
  add(query_773156, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_773158 = body
  result = call_773155.call(nil, query_773156, nil, nil, body_773158)

var getResources* = Call_GetResources_772924(name: "getResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetResources",
    validator: validate_GetResources_772925, base: "/", url: url_GetResources_772926,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagKeys_773197 = ref object of OpenApiRestCall_772588
proc url_GetTagKeys_773199(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagKeys_773198(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_773200 = query.getOrDefault("PaginationToken")
  valid_773200 = validateParameter(valid_773200, JString, required = false,
                                 default = nil)
  if valid_773200 != nil:
    section.add "PaginationToken", valid_773200
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773201 = header.getOrDefault("X-Amz-Date")
  valid_773201 = validateParameter(valid_773201, JString, required = false,
                                 default = nil)
  if valid_773201 != nil:
    section.add "X-Amz-Date", valid_773201
  var valid_773202 = header.getOrDefault("X-Amz-Security-Token")
  valid_773202 = validateParameter(valid_773202, JString, required = false,
                                 default = nil)
  if valid_773202 != nil:
    section.add "X-Amz-Security-Token", valid_773202
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773203 = header.getOrDefault("X-Amz-Target")
  valid_773203 = validateParameter(valid_773203, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagKeys"))
  if valid_773203 != nil:
    section.add "X-Amz-Target", valid_773203
  var valid_773204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773204 = validateParameter(valid_773204, JString, required = false,
                                 default = nil)
  if valid_773204 != nil:
    section.add "X-Amz-Content-Sha256", valid_773204
  var valid_773205 = header.getOrDefault("X-Amz-Algorithm")
  valid_773205 = validateParameter(valid_773205, JString, required = false,
                                 default = nil)
  if valid_773205 != nil:
    section.add "X-Amz-Algorithm", valid_773205
  var valid_773206 = header.getOrDefault("X-Amz-Signature")
  valid_773206 = validateParameter(valid_773206, JString, required = false,
                                 default = nil)
  if valid_773206 != nil:
    section.add "X-Amz-Signature", valid_773206
  var valid_773207 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773207 = validateParameter(valid_773207, JString, required = false,
                                 default = nil)
  if valid_773207 != nil:
    section.add "X-Amz-SignedHeaders", valid_773207
  var valid_773208 = header.getOrDefault("X-Amz-Credential")
  valid_773208 = validateParameter(valid_773208, JString, required = false,
                                 default = nil)
  if valid_773208 != nil:
    section.add "X-Amz-Credential", valid_773208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773210: Call_GetTagKeys_773197; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag keys in the specified region for the AWS account.
  ## 
  let valid = call_773210.validator(path, query, header, formData, body)
  let scheme = call_773210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773210.url(scheme.get, call_773210.host, call_773210.base,
                         call_773210.route, valid.getOrDefault("path"))
  result = hook(call_773210, url, valid)

proc call*(call_773211: Call_GetTagKeys_773197; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagKeys
  ## Returns all tag keys in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_773212 = newJObject()
  var body_773213 = newJObject()
  add(query_773212, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_773213 = body
  result = call_773211.call(nil, query_773212, nil, nil, body_773213)

var getTagKeys* = Call_GetTagKeys_773197(name: "getTagKeys",
                                      meth: HttpMethod.HttpPost,
                                      host: "tagging.amazonaws.com", route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagKeys",
                                      validator: validate_GetTagKeys_773198,
                                      base: "/", url: url_GetTagKeys_773199,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTagValues_773214 = ref object of OpenApiRestCall_772588
proc url_GetTagValues_773216(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetTagValues_773215(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PaginationToken: JString
  ##                  : Pagination token
  section = newJObject()
  var valid_773217 = query.getOrDefault("PaginationToken")
  valid_773217 = validateParameter(valid_773217, JString, required = false,
                                 default = nil)
  if valid_773217 != nil:
    section.add "PaginationToken", valid_773217
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773218 = header.getOrDefault("X-Amz-Date")
  valid_773218 = validateParameter(valid_773218, JString, required = false,
                                 default = nil)
  if valid_773218 != nil:
    section.add "X-Amz-Date", valid_773218
  var valid_773219 = header.getOrDefault("X-Amz-Security-Token")
  valid_773219 = validateParameter(valid_773219, JString, required = false,
                                 default = nil)
  if valid_773219 != nil:
    section.add "X-Amz-Security-Token", valid_773219
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773220 = header.getOrDefault("X-Amz-Target")
  valid_773220 = validateParameter(valid_773220, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.GetTagValues"))
  if valid_773220 != nil:
    section.add "X-Amz-Target", valid_773220
  var valid_773221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773221 = validateParameter(valid_773221, JString, required = false,
                                 default = nil)
  if valid_773221 != nil:
    section.add "X-Amz-Content-Sha256", valid_773221
  var valid_773222 = header.getOrDefault("X-Amz-Algorithm")
  valid_773222 = validateParameter(valid_773222, JString, required = false,
                                 default = nil)
  if valid_773222 != nil:
    section.add "X-Amz-Algorithm", valid_773222
  var valid_773223 = header.getOrDefault("X-Amz-Signature")
  valid_773223 = validateParameter(valid_773223, JString, required = false,
                                 default = nil)
  if valid_773223 != nil:
    section.add "X-Amz-Signature", valid_773223
  var valid_773224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "X-Amz-SignedHeaders", valid_773224
  var valid_773225 = header.getOrDefault("X-Amz-Credential")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "X-Amz-Credential", valid_773225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773227: Call_GetTagValues_773214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ## 
  let valid = call_773227.validator(path, query, header, formData, body)
  let scheme = call_773227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773227.url(scheme.get, call_773227.host, call_773227.base,
                         call_773227.route, valid.getOrDefault("path"))
  result = hook(call_773227, url, valid)

proc call*(call_773228: Call_GetTagValues_773214; body: JsonNode;
          PaginationToken: string = ""): Recallable =
  ## getTagValues
  ## Returns all tag values for the specified key in the specified region for the AWS account.
  ##   PaginationToken: string
  ##                  : Pagination token
  ##   body: JObject (required)
  var query_773229 = newJObject()
  var body_773230 = newJObject()
  add(query_773229, "PaginationToken", newJString(PaginationToken))
  if body != nil:
    body_773230 = body
  result = call_773228.call(nil, query_773229, nil, nil, body_773230)

var getTagValues* = Call_GetTagValues_773214(name: "getTagValues",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.GetTagValues",
    validator: validate_GetTagValues_773215, base: "/", url: url_GetTagValues_773216,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResources_773231 = ref object of OpenApiRestCall_772588
proc url_TagResources_773233(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResources_773232(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773234 = header.getOrDefault("X-Amz-Date")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Date", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Security-Token")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Security-Token", valid_773235
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773236 = header.getOrDefault("X-Amz-Target")
  valid_773236 = validateParameter(valid_773236, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.TagResources"))
  if valid_773236 != nil:
    section.add "X-Amz-Target", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Content-Sha256", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-Algorithm")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-Algorithm", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Signature")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Signature", valid_773239
  var valid_773240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773240 = validateParameter(valid_773240, JString, required = false,
                                 default = nil)
  if valid_773240 != nil:
    section.add "X-Amz-SignedHeaders", valid_773240
  var valid_773241 = header.getOrDefault("X-Amz-Credential")
  valid_773241 = validateParameter(valid_773241, JString, required = false,
                                 default = nil)
  if valid_773241 != nil:
    section.add "X-Amz-Credential", valid_773241
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773243: Call_TagResources_773231; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ## 
  let valid = call_773243.validator(path, query, header, formData, body)
  let scheme = call_773243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773243.url(scheme.get, call_773243.host, call_773243.base,
                         call_773243.route, valid.getOrDefault("path"))
  result = hook(call_773243, url, valid)

proc call*(call_773244: Call_TagResources_773231; body: JsonNode): Recallable =
  ## tagResources
  ## <p>Applies one or more tags to the specified resources. Note the following:</p> <ul> <li> <p>Not all resources can have tags. For a list of resources that support tagging, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/supported-resources.html">Supported Resources</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>Each resource can have up to 50 tags. For other limits, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#tag-restrictions">Tag Restrictions</a> in the <i>Amazon EC2 User Guide for Linux Instances</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> <li> <p>To add tags to a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for adding tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773245 = newJObject()
  if body != nil:
    body_773245 = body
  result = call_773244.call(nil, nil, nil, nil, body_773245)

var tagResources* = Call_TagResources_773231(name: "tagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.TagResources",
    validator: validate_TagResources_773232, base: "/", url: url_TagResources_773233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResources_773246 = ref object of OpenApiRestCall_772588
proc url_UntagResources_773248(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResources_773247(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773249 = header.getOrDefault("X-Amz-Date")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Date", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Security-Token")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Security-Token", valid_773250
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_773251 = header.getOrDefault("X-Amz-Target")
  valid_773251 = validateParameter(valid_773251, JString, required = true, default = newJString(
      "ResourceGroupsTaggingAPI_20170126.UntagResources"))
  if valid_773251 != nil:
    section.add "X-Amz-Target", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Content-Sha256", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-Algorithm")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-Algorithm", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Signature")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Signature", valid_773254
  var valid_773255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "X-Amz-SignedHeaders", valid_773255
  var valid_773256 = header.getOrDefault("X-Amz-Credential")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "X-Amz-Credential", valid_773256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_773258: Call_UntagResources_773246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ## 
  let valid = call_773258.validator(path, query, header, formData, body)
  let scheme = call_773258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773258.url(scheme.get, call_773258.host, call_773258.base,
                         call_773258.route, valid.getOrDefault("path"))
  result = hook(call_773258, url, valid)

proc call*(call_773259: Call_UntagResources_773246; body: JsonNode): Recallable =
  ## untagResources
  ## <p>Removes the specified tags from the specified resources. When you specify a tag key, the action removes both that key and its associated value. The operation succeeds even if you attempt to remove tags from a resource that were already removed. Note the following:</p> <ul> <li> <p>To remove tags from a resource, you need the necessary permissions for the service that the resource belongs to as well as permissions for removing tags. For more information, see <a href="http://docs.aws.amazon.com/ARG/latest/userguide/obtaining-permissions-for-tagging.html">Obtaining Permissions for Tagging</a> in the <i>AWS Resource Groups User Guide</i>.</p> </li> <li> <p>You can only tag resources that are located in the specified region for the AWS account.</p> </li> </ul>
  ##   body: JObject (required)
  var body_773260 = newJObject()
  if body != nil:
    body_773260 = body
  result = call_773259.call(nil, nil, nil, nil, body_773260)

var untagResources* = Call_UntagResources_773246(name: "untagResources",
    meth: HttpMethod.HttpPost, host: "tagging.amazonaws.com",
    route: "/#X-Amz-Target=ResourceGroupsTaggingAPI_20170126.UntagResources",
    validator: validate_UntagResources_773247, base: "/", url: url_UntagResources_773248,
    schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)

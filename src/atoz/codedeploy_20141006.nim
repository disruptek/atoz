
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS CodeDeploy
## version: 2014-10-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS CodeDeploy</fullname> <p>AWS CodeDeploy is a deployment service that automates application deployments to Amazon EC2 instances, on-premises instances running in your own facility, serverless AWS Lambda functions, or applications in an Amazon ECS service.</p> <p>You can deploy a nearly unlimited variety of application content, such as an updated Lambda function, updated applications in an Amazon ECS service, code, web and configuration files, executables, packages, scripts, multimedia files, and so on. AWS CodeDeploy can deploy application content stored in Amazon S3 buckets, GitHub repositories, or Bitbucket repositories. You do not need to make changes to your existing code before you can use AWS CodeDeploy.</p> <p>AWS CodeDeploy makes it easier for you to rapidly release new features, helps you avoid downtime during application deployment, and handles the complexity of updating your applications, without many of the risks associated with error-prone manual deployments.</p> <p> <b>AWS CodeDeploy Components</b> </p> <p>Use the information in this guide to help you work with the following AWS CodeDeploy components:</p> <ul> <li> <p> <b>Application</b>: A name that uniquely identifies the application you want to deploy. AWS CodeDeploy uses this name, which functions as a container, to ensure the correct combination of revision, deployment configuration, and deployment group are referenced during a deployment.</p> </li> <li> <p> <b>Deployment group</b>: A set of individual instances, CodeDeploy Lambda deployment configuration settings, or an Amazon ECS service and network details. A Lambda deployment group specifies how to route traffic to a new version of a Lambda function. An Amazon ECS deployment group specifies the service created in Amazon ECS to deploy, a load balancer, and a listener to reroute production traffic to an updated containerized application. An EC2/On-premises deployment group contains individually tagged instances, Amazon EC2 instances in Amazon EC2 Auto Scaling groups, or both. All deployment groups can specify optional trigger, alarm, and rollback settings.</p> </li> <li> <p> <b>Deployment configuration</b>: A set of deployment rules and deployment success and failure conditions used by AWS CodeDeploy during a deployment.</p> </li> <li> <p> <b>Deployment</b>: The process and the components used when updating a Lambda function, a containerized application in an Amazon ECS service, or of installing content on one or more instances. </p> </li> <li> <p> <b>Application revisions</b>: For an AWS Lambda deployment, this is an AppSpec file that specifies the Lambda function to be updated and one or more functions to validate deployment lifecycle events. For an Amazon ECS deployment, this is an AppSpec file that specifies the Amazon ECS task definition, container, and port where production traffic is rerouted. For an EC2/On-premises deployment, this is an archive file that contains source content—source code, webpages, executable files, and deployment scripts—along with an AppSpec file. Revisions are stored in Amazon S3 buckets or GitHub repositories. For Amazon S3, a revision is uniquely identified by its Amazon S3 object key and its ETag, version, or both. For GitHub, a revision is uniquely identified by its commit ID.</p> </li> </ul> <p>This guide also contains information to help you get details about the instances in your deployments, to make on-premises instances available for AWS CodeDeploy deployments, to get details about a Lambda function deployment, and to get details about Amazon ECS service deployments.</p> <p> <b>AWS CodeDeploy Information Resources</b> </p> <ul> <li> <p> <a href="https://docs.aws.amazon.com/codedeploy/latest/userguide">AWS CodeDeploy User Guide</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/codedeploy/latest/APIReference/">AWS CodeDeploy API Reference Guide</a> </p> </li> <li> <p> <a href="https://docs.aws.amazon.com/cli/latest/reference/deploy/index.html">AWS CLI Reference for AWS CodeDeploy</a> </p> </li> <li> <p> <a href="https://forums.aws.amazon.com/forum.jspa?forumID=179">AWS CodeDeploy Developer Forum</a> </p> </li> </ul>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codedeploy/
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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "codedeploy.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codedeploy.ap-southeast-1.amazonaws.com",
                           "us-west-2": "codedeploy.us-west-2.amazonaws.com",
                           "eu-west-2": "codedeploy.eu-west-2.amazonaws.com", "ap-northeast-3": "codedeploy.ap-northeast-3.amazonaws.com", "eu-central-1": "codedeploy.eu-central-1.amazonaws.com",
                           "us-east-2": "codedeploy.us-east-2.amazonaws.com",
                           "us-east-1": "codedeploy.us-east-1.amazonaws.com", "cn-northwest-1": "codedeploy.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "codedeploy.ap-south-1.amazonaws.com",
                           "eu-north-1": "codedeploy.eu-north-1.amazonaws.com", "ap-northeast-2": "codedeploy.ap-northeast-2.amazonaws.com",
                           "us-west-1": "codedeploy.us-west-1.amazonaws.com", "us-gov-east-1": "codedeploy.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "codedeploy.eu-west-3.amazonaws.com", "cn-north-1": "codedeploy.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "codedeploy.sa-east-1.amazonaws.com",
                           "eu-west-1": "codedeploy.eu-west-1.amazonaws.com", "us-gov-west-1": "codedeploy.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codedeploy.ap-southeast-2.amazonaws.com", "ca-central-1": "codedeploy.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "codedeploy.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codedeploy.ap-southeast-1.amazonaws.com",
      "us-west-2": "codedeploy.us-west-2.amazonaws.com",
      "eu-west-2": "codedeploy.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codedeploy.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codedeploy.eu-central-1.amazonaws.com",
      "us-east-2": "codedeploy.us-east-2.amazonaws.com",
      "us-east-1": "codedeploy.us-east-1.amazonaws.com",
      "cn-northwest-1": "codedeploy.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codedeploy.ap-south-1.amazonaws.com",
      "eu-north-1": "codedeploy.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codedeploy.ap-northeast-2.amazonaws.com",
      "us-west-1": "codedeploy.us-west-1.amazonaws.com",
      "us-gov-east-1": "codedeploy.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codedeploy.eu-west-3.amazonaws.com",
      "cn-north-1": "codedeploy.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codedeploy.sa-east-1.amazonaws.com",
      "eu-west-1": "codedeploy.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codedeploy.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codedeploy.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codedeploy.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codedeploy"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToOnPremisesInstances_605927 = ref object of OpenApiRestCall_605589
proc url_AddTagsToOnPremisesInstances_605929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToOnPremisesInstances_605928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to on-premises instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606054 = header.getOrDefault("X-Amz-Target")
  valid_606054 = validateParameter(valid_606054, JString, required = true, default = newJString(
      "CodeDeploy_20141006.AddTagsToOnPremisesInstances"))
  if valid_606054 != nil:
    section.add "X-Amz-Target", valid_606054
  var valid_606055 = header.getOrDefault("X-Amz-Signature")
  valid_606055 = validateParameter(valid_606055, JString, required = false,
                                 default = nil)
  if valid_606055 != nil:
    section.add "X-Amz-Signature", valid_606055
  var valid_606056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "X-Amz-Content-Sha256", valid_606056
  var valid_606057 = header.getOrDefault("X-Amz-Date")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Date", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Credential")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Credential", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Security-Token")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Security-Token", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Algorithm")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Algorithm", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-SignedHeaders", valid_606061
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606085: Call_AddTagsToOnPremisesInstances_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to on-premises instances.
  ## 
  let valid = call_606085.validator(path, query, header, formData, body)
  let scheme = call_606085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606085.url(scheme.get, call_606085.host, call_606085.base,
                         call_606085.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606085, url, valid)

proc call*(call_606156: Call_AddTagsToOnPremisesInstances_605927; body: JsonNode): Recallable =
  ## addTagsToOnPremisesInstances
  ## Adds tags to on-premises instances.
  ##   body: JObject (required)
  var body_606157 = newJObject()
  if body != nil:
    body_606157 = body
  result = call_606156.call(nil, nil, nil, nil, body_606157)

var addTagsToOnPremisesInstances* = Call_AddTagsToOnPremisesInstances_605927(
    name: "addTagsToOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.AddTagsToOnPremisesInstances",
    validator: validate_AddTagsToOnPremisesInstances_605928, base: "/",
    url: url_AddTagsToOnPremisesInstances_605929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplicationRevisions_606196 = ref object of OpenApiRestCall_605589
proc url_BatchGetApplicationRevisions_606198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetApplicationRevisions_606197(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606199 = header.getOrDefault("X-Amz-Target")
  valid_606199 = validateParameter(valid_606199, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplicationRevisions"))
  if valid_606199 != nil:
    section.add "X-Amz-Target", valid_606199
  var valid_606200 = header.getOrDefault("X-Amz-Signature")
  valid_606200 = validateParameter(valid_606200, JString, required = false,
                                 default = nil)
  if valid_606200 != nil:
    section.add "X-Amz-Signature", valid_606200
  var valid_606201 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606201 = validateParameter(valid_606201, JString, required = false,
                                 default = nil)
  if valid_606201 != nil:
    section.add "X-Amz-Content-Sha256", valid_606201
  var valid_606202 = header.getOrDefault("X-Amz-Date")
  valid_606202 = validateParameter(valid_606202, JString, required = false,
                                 default = nil)
  if valid_606202 != nil:
    section.add "X-Amz-Date", valid_606202
  var valid_606203 = header.getOrDefault("X-Amz-Credential")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Credential", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Security-Token")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Security-Token", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Algorithm")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Algorithm", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-SignedHeaders", valid_606206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606208: Call_BatchGetApplicationRevisions_606196; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ## 
  let valid = call_606208.validator(path, query, header, formData, body)
  let scheme = call_606208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606208.url(scheme.get, call_606208.host, call_606208.base,
                         call_606208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606208, url, valid)

proc call*(call_606209: Call_BatchGetApplicationRevisions_606196; body: JsonNode): Recallable =
  ## batchGetApplicationRevisions
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ##   body: JObject (required)
  var body_606210 = newJObject()
  if body != nil:
    body_606210 = body
  result = call_606209.call(nil, nil, nil, nil, body_606210)

var batchGetApplicationRevisions* = Call_BatchGetApplicationRevisions_606196(
    name: "batchGetApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplicationRevisions",
    validator: validate_BatchGetApplicationRevisions_606197, base: "/",
    url: url_BatchGetApplicationRevisions_606198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplications_606211 = ref object of OpenApiRestCall_605589
proc url_BatchGetApplications_606213(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetApplications_606212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606214 = header.getOrDefault("X-Amz-Target")
  valid_606214 = validateParameter(valid_606214, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplications"))
  if valid_606214 != nil:
    section.add "X-Amz-Target", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-Signature")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-Signature", valid_606215
  var valid_606216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606216 = validateParameter(valid_606216, JString, required = false,
                                 default = nil)
  if valid_606216 != nil:
    section.add "X-Amz-Content-Sha256", valid_606216
  var valid_606217 = header.getOrDefault("X-Amz-Date")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "X-Amz-Date", valid_606217
  var valid_606218 = header.getOrDefault("X-Amz-Credential")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "X-Amz-Credential", valid_606218
  var valid_606219 = header.getOrDefault("X-Amz-Security-Token")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Security-Token", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Algorithm")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Algorithm", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-SignedHeaders", valid_606221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606223: Call_BatchGetApplications_606211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ## 
  let valid = call_606223.validator(path, query, header, formData, body)
  let scheme = call_606223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606223.url(scheme.get, call_606223.host, call_606223.base,
                         call_606223.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606223, url, valid)

proc call*(call_606224: Call_BatchGetApplications_606211; body: JsonNode): Recallable =
  ## batchGetApplications
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ##   body: JObject (required)
  var body_606225 = newJObject()
  if body != nil:
    body_606225 = body
  result = call_606224.call(nil, nil, nil, nil, body_606225)

var batchGetApplications* = Call_BatchGetApplications_606211(
    name: "batchGetApplications", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplications",
    validator: validate_BatchGetApplications_606212, base: "/",
    url: url_BatchGetApplications_606213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentGroups_606226 = ref object of OpenApiRestCall_605589
proc url_BatchGetDeploymentGroups_606228(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentGroups_606227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more deployment groups.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606229 = header.getOrDefault("X-Amz-Target")
  valid_606229 = validateParameter(valid_606229, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentGroups"))
  if valid_606229 != nil:
    section.add "X-Amz-Target", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Signature")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Signature", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Content-Sha256", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Date")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Date", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-Credential")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-Credential", valid_606233
  var valid_606234 = header.getOrDefault("X-Amz-Security-Token")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Security-Token", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Algorithm")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Algorithm", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-SignedHeaders", valid_606236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606238: Call_BatchGetDeploymentGroups_606226; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployment groups.
  ## 
  let valid = call_606238.validator(path, query, header, formData, body)
  let scheme = call_606238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606238.url(scheme.get, call_606238.host, call_606238.base,
                         call_606238.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606238, url, valid)

proc call*(call_606239: Call_BatchGetDeploymentGroups_606226; body: JsonNode): Recallable =
  ## batchGetDeploymentGroups
  ## Gets information about one or more deployment groups.
  ##   body: JObject (required)
  var body_606240 = newJObject()
  if body != nil:
    body_606240 = body
  result = call_606239.call(nil, nil, nil, nil, body_606240)

var batchGetDeploymentGroups* = Call_BatchGetDeploymentGroups_606226(
    name: "batchGetDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentGroups",
    validator: validate_BatchGetDeploymentGroups_606227, base: "/",
    url: url_BatchGetDeploymentGroups_606228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentInstances_606241 = ref object of OpenApiRestCall_605589
proc url_BatchGetDeploymentInstances_606243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentInstances_606242(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606244 = header.getOrDefault("X-Amz-Target")
  valid_606244 = validateParameter(valid_606244, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentInstances"))
  if valid_606244 != nil:
    section.add "X-Amz-Target", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Signature")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Signature", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Content-Sha256", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Date")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Date", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-Credential")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-Credential", valid_606248
  var valid_606249 = header.getOrDefault("X-Amz-Security-Token")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "X-Amz-Security-Token", valid_606249
  var valid_606250 = header.getOrDefault("X-Amz-Algorithm")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "X-Amz-Algorithm", valid_606250
  var valid_606251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "X-Amz-SignedHeaders", valid_606251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606253: Call_BatchGetDeploymentInstances_606241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ## 
  let valid = call_606253.validator(path, query, header, formData, body)
  let scheme = call_606253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606253.url(scheme.get, call_606253.host, call_606253.base,
                         call_606253.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606253, url, valid)

proc call*(call_606254: Call_BatchGetDeploymentInstances_606241; body: JsonNode): Recallable =
  ## batchGetDeploymentInstances
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ##   body: JObject (required)
  var body_606255 = newJObject()
  if body != nil:
    body_606255 = body
  result = call_606254.call(nil, nil, nil, nil, body_606255)

var batchGetDeploymentInstances* = Call_BatchGetDeploymentInstances_606241(
    name: "batchGetDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentInstances",
    validator: validate_BatchGetDeploymentInstances_606242, base: "/",
    url: url_BatchGetDeploymentInstances_606243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentTargets_606256 = ref object of OpenApiRestCall_605589
proc url_BatchGetDeploymentTargets_606258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeploymentTargets_606257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606259 = header.getOrDefault("X-Amz-Target")
  valid_606259 = validateParameter(valid_606259, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentTargets"))
  if valid_606259 != nil:
    section.add "X-Amz-Target", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-Signature")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-Signature", valid_606260
  var valid_606261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606261 = validateParameter(valid_606261, JString, required = false,
                                 default = nil)
  if valid_606261 != nil:
    section.add "X-Amz-Content-Sha256", valid_606261
  var valid_606262 = header.getOrDefault("X-Amz-Date")
  valid_606262 = validateParameter(valid_606262, JString, required = false,
                                 default = nil)
  if valid_606262 != nil:
    section.add "X-Amz-Date", valid_606262
  var valid_606263 = header.getOrDefault("X-Amz-Credential")
  valid_606263 = validateParameter(valid_606263, JString, required = false,
                                 default = nil)
  if valid_606263 != nil:
    section.add "X-Amz-Credential", valid_606263
  var valid_606264 = header.getOrDefault("X-Amz-Security-Token")
  valid_606264 = validateParameter(valid_606264, JString, required = false,
                                 default = nil)
  if valid_606264 != nil:
    section.add "X-Amz-Security-Token", valid_606264
  var valid_606265 = header.getOrDefault("X-Amz-Algorithm")
  valid_606265 = validateParameter(valid_606265, JString, required = false,
                                 default = nil)
  if valid_606265 != nil:
    section.add "X-Amz-Algorithm", valid_606265
  var valid_606266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "X-Amz-SignedHeaders", valid_606266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606268: Call_BatchGetDeploymentTargets_606256; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ## 
  let valid = call_606268.validator(path, query, header, formData, body)
  let scheme = call_606268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606268.url(scheme.get, call_606268.host, call_606268.base,
                         call_606268.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606268, url, valid)

proc call*(call_606269: Call_BatchGetDeploymentTargets_606256; body: JsonNode): Recallable =
  ## batchGetDeploymentTargets
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ##   body: JObject (required)
  var body_606270 = newJObject()
  if body != nil:
    body_606270 = body
  result = call_606269.call(nil, nil, nil, nil, body_606270)

var batchGetDeploymentTargets* = Call_BatchGetDeploymentTargets_606256(
    name: "batchGetDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentTargets",
    validator: validate_BatchGetDeploymentTargets_606257, base: "/",
    url: url_BatchGetDeploymentTargets_606258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeployments_606271 = ref object of OpenApiRestCall_605589
proc url_BatchGetDeployments_606273(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetDeployments_606272(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606274 = header.getOrDefault("X-Amz-Target")
  valid_606274 = validateParameter(valid_606274, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeployments"))
  if valid_606274 != nil:
    section.add "X-Amz-Target", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Signature")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Signature", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-Content-Sha256", valid_606276
  var valid_606277 = header.getOrDefault("X-Amz-Date")
  valid_606277 = validateParameter(valid_606277, JString, required = false,
                                 default = nil)
  if valid_606277 != nil:
    section.add "X-Amz-Date", valid_606277
  var valid_606278 = header.getOrDefault("X-Amz-Credential")
  valid_606278 = validateParameter(valid_606278, JString, required = false,
                                 default = nil)
  if valid_606278 != nil:
    section.add "X-Amz-Credential", valid_606278
  var valid_606279 = header.getOrDefault("X-Amz-Security-Token")
  valid_606279 = validateParameter(valid_606279, JString, required = false,
                                 default = nil)
  if valid_606279 != nil:
    section.add "X-Amz-Security-Token", valid_606279
  var valid_606280 = header.getOrDefault("X-Amz-Algorithm")
  valid_606280 = validateParameter(valid_606280, JString, required = false,
                                 default = nil)
  if valid_606280 != nil:
    section.add "X-Amz-Algorithm", valid_606280
  var valid_606281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606281 = validateParameter(valid_606281, JString, required = false,
                                 default = nil)
  if valid_606281 != nil:
    section.add "X-Amz-SignedHeaders", valid_606281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606283: Call_BatchGetDeployments_606271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ## 
  let valid = call_606283.validator(path, query, header, formData, body)
  let scheme = call_606283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606283.url(scheme.get, call_606283.host, call_606283.base,
                         call_606283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606283, url, valid)

proc call*(call_606284: Call_BatchGetDeployments_606271; body: JsonNode): Recallable =
  ## batchGetDeployments
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ##   body: JObject (required)
  var body_606285 = newJObject()
  if body != nil:
    body_606285 = body
  result = call_606284.call(nil, nil, nil, nil, body_606285)

var batchGetDeployments* = Call_BatchGetDeployments_606271(
    name: "batchGetDeployments", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeployments",
    validator: validate_BatchGetDeployments_606272, base: "/",
    url: url_BatchGetDeployments_606273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetOnPremisesInstances_606286 = ref object of OpenApiRestCall_605589
proc url_BatchGetOnPremisesInstances_606288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetOnPremisesInstances_606287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606289 = header.getOrDefault("X-Amz-Target")
  valid_606289 = validateParameter(valid_606289, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetOnPremisesInstances"))
  if valid_606289 != nil:
    section.add "X-Amz-Target", valid_606289
  var valid_606290 = header.getOrDefault("X-Amz-Signature")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "X-Amz-Signature", valid_606290
  var valid_606291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "X-Amz-Content-Sha256", valid_606291
  var valid_606292 = header.getOrDefault("X-Amz-Date")
  valid_606292 = validateParameter(valid_606292, JString, required = false,
                                 default = nil)
  if valid_606292 != nil:
    section.add "X-Amz-Date", valid_606292
  var valid_606293 = header.getOrDefault("X-Amz-Credential")
  valid_606293 = validateParameter(valid_606293, JString, required = false,
                                 default = nil)
  if valid_606293 != nil:
    section.add "X-Amz-Credential", valid_606293
  var valid_606294 = header.getOrDefault("X-Amz-Security-Token")
  valid_606294 = validateParameter(valid_606294, JString, required = false,
                                 default = nil)
  if valid_606294 != nil:
    section.add "X-Amz-Security-Token", valid_606294
  var valid_606295 = header.getOrDefault("X-Amz-Algorithm")
  valid_606295 = validateParameter(valid_606295, JString, required = false,
                                 default = nil)
  if valid_606295 != nil:
    section.add "X-Amz-Algorithm", valid_606295
  var valid_606296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606296 = validateParameter(valid_606296, JString, required = false,
                                 default = nil)
  if valid_606296 != nil:
    section.add "X-Amz-SignedHeaders", valid_606296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606298: Call_BatchGetOnPremisesInstances_606286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ## 
  let valid = call_606298.validator(path, query, header, formData, body)
  let scheme = call_606298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606298.url(scheme.get, call_606298.host, call_606298.base,
                         call_606298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606298, url, valid)

proc call*(call_606299: Call_BatchGetOnPremisesInstances_606286; body: JsonNode): Recallable =
  ## batchGetOnPremisesInstances
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ##   body: JObject (required)
  var body_606300 = newJObject()
  if body != nil:
    body_606300 = body
  result = call_606299.call(nil, nil, nil, nil, body_606300)

var batchGetOnPremisesInstances* = Call_BatchGetOnPremisesInstances_606286(
    name: "batchGetOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetOnPremisesInstances",
    validator: validate_BatchGetOnPremisesInstances_606287, base: "/",
    url: url_BatchGetOnPremisesInstances_606288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ContinueDeployment_606301 = ref object of OpenApiRestCall_605589
proc url_ContinueDeployment_606303(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ContinueDeployment_606302(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606304 = header.getOrDefault("X-Amz-Target")
  valid_606304 = validateParameter(valid_606304, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ContinueDeployment"))
  if valid_606304 != nil:
    section.add "X-Amz-Target", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Signature")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Signature", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Content-Sha256", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Date")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Date", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Credential")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Credential", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-Security-Token")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-Security-Token", valid_606309
  var valid_606310 = header.getOrDefault("X-Amz-Algorithm")
  valid_606310 = validateParameter(valid_606310, JString, required = false,
                                 default = nil)
  if valid_606310 != nil:
    section.add "X-Amz-Algorithm", valid_606310
  var valid_606311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606311 = validateParameter(valid_606311, JString, required = false,
                                 default = nil)
  if valid_606311 != nil:
    section.add "X-Amz-SignedHeaders", valid_606311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606313: Call_ContinueDeployment_606301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ## 
  let valid = call_606313.validator(path, query, header, formData, body)
  let scheme = call_606313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606313.url(scheme.get, call_606313.host, call_606313.base,
                         call_606313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606313, url, valid)

proc call*(call_606314: Call_ContinueDeployment_606301; body: JsonNode): Recallable =
  ## continueDeployment
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ##   body: JObject (required)
  var body_606315 = newJObject()
  if body != nil:
    body_606315 = body
  result = call_606314.call(nil, nil, nil, nil, body_606315)

var continueDeployment* = Call_ContinueDeployment_606301(
    name: "continueDeployment", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ContinueDeployment",
    validator: validate_ContinueDeployment_606302, base: "/",
    url: url_ContinueDeployment_606303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_606316 = ref object of OpenApiRestCall_605589
proc url_CreateApplication_606318(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateApplication_606317(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Creates an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606319 = header.getOrDefault("X-Amz-Target")
  valid_606319 = validateParameter(valid_606319, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateApplication"))
  if valid_606319 != nil:
    section.add "X-Amz-Target", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Signature")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Signature", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Content-Sha256", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Date")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Date", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Credential")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Credential", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-Security-Token")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-Security-Token", valid_606324
  var valid_606325 = header.getOrDefault("X-Amz-Algorithm")
  valid_606325 = validateParameter(valid_606325, JString, required = false,
                                 default = nil)
  if valid_606325 != nil:
    section.add "X-Amz-Algorithm", valid_606325
  var valid_606326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606326 = validateParameter(valid_606326, JString, required = false,
                                 default = nil)
  if valid_606326 != nil:
    section.add "X-Amz-SignedHeaders", valid_606326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606328: Call_CreateApplication_606316; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application.
  ## 
  let valid = call_606328.validator(path, query, header, formData, body)
  let scheme = call_606328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606328.url(scheme.get, call_606328.host, call_606328.base,
                         call_606328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606328, url, valid)

proc call*(call_606329: Call_CreateApplication_606316; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application.
  ##   body: JObject (required)
  var body_606330 = newJObject()
  if body != nil:
    body_606330 = body
  result = call_606329.call(nil, nil, nil, nil, body_606330)

var createApplication* = Call_CreateApplication_606316(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateApplication",
    validator: validate_CreateApplication_606317, base: "/",
    url: url_CreateApplication_606318, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_606331 = ref object of OpenApiRestCall_605589
proc url_CreateDeployment_606333(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeployment_606332(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Deploys an application revision through the specified deployment group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606334 = header.getOrDefault("X-Amz-Target")
  valid_606334 = validateParameter(valid_606334, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeployment"))
  if valid_606334 != nil:
    section.add "X-Amz-Target", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Signature")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Signature", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Content-Sha256", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Date")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Date", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Credential")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Credential", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Security-Token")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Security-Token", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Algorithm")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Algorithm", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-SignedHeaders", valid_606341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606343: Call_CreateDeployment_606331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys an application revision through the specified deployment group.
  ## 
  let valid = call_606343.validator(path, query, header, formData, body)
  let scheme = call_606343.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606343.url(scheme.get, call_606343.host, call_606343.base,
                         call_606343.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606343, url, valid)

proc call*(call_606344: Call_CreateDeployment_606331; body: JsonNode): Recallable =
  ## createDeployment
  ## Deploys an application revision through the specified deployment group.
  ##   body: JObject (required)
  var body_606345 = newJObject()
  if body != nil:
    body_606345 = body
  result = call_606344.call(nil, nil, nil, nil, body_606345)

var createDeployment* = Call_CreateDeployment_606331(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeployment",
    validator: validate_CreateDeployment_606332, base: "/",
    url: url_CreateDeployment_606333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentConfig_606346 = ref object of OpenApiRestCall_605589
proc url_CreateDeploymentConfig_606348(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentConfig_606347(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Creates a deployment configuration. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606349 = header.getOrDefault("X-Amz-Target")
  valid_606349 = validateParameter(valid_606349, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentConfig"))
  if valid_606349 != nil:
    section.add "X-Amz-Target", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Signature")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Signature", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-Content-Sha256", valid_606351
  var valid_606352 = header.getOrDefault("X-Amz-Date")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Date", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Credential")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Credential", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Security-Token")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Security-Token", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Algorithm")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Algorithm", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-SignedHeaders", valid_606356
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606358: Call_CreateDeploymentConfig_606346; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a deployment configuration. 
  ## 
  let valid = call_606358.validator(path, query, header, formData, body)
  let scheme = call_606358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606358.url(scheme.get, call_606358.host, call_606358.base,
                         call_606358.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606358, url, valid)

proc call*(call_606359: Call_CreateDeploymentConfig_606346; body: JsonNode): Recallable =
  ## createDeploymentConfig
  ##  Creates a deployment configuration. 
  ##   body: JObject (required)
  var body_606360 = newJObject()
  if body != nil:
    body_606360 = body
  result = call_606359.call(nil, nil, nil, nil, body_606360)

var createDeploymentConfig* = Call_CreateDeploymentConfig_606346(
    name: "createDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentConfig",
    validator: validate_CreateDeploymentConfig_606347, base: "/",
    url: url_CreateDeploymentConfig_606348, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentGroup_606361 = ref object of OpenApiRestCall_605589
proc url_CreateDeploymentGroup_606363(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentGroup_606362(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a deployment group to which application revisions are deployed.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606364 = header.getOrDefault("X-Amz-Target")
  valid_606364 = validateParameter(valid_606364, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentGroup"))
  if valid_606364 != nil:
    section.add "X-Amz-Target", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Signature")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Signature", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Content-Sha256", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Date")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Date", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Credential")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Credential", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Security-Token")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Security-Token", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-Algorithm")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-Algorithm", valid_606370
  var valid_606371 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-SignedHeaders", valid_606371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606373: Call_CreateDeploymentGroup_606361; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment group to which application revisions are deployed.
  ## 
  let valid = call_606373.validator(path, query, header, formData, body)
  let scheme = call_606373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606373.url(scheme.get, call_606373.host, call_606373.base,
                         call_606373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606373, url, valid)

proc call*(call_606374: Call_CreateDeploymentGroup_606361; body: JsonNode): Recallable =
  ## createDeploymentGroup
  ## Creates a deployment group to which application revisions are deployed.
  ##   body: JObject (required)
  var body_606375 = newJObject()
  if body != nil:
    body_606375 = body
  result = call_606374.call(nil, nil, nil, nil, body_606375)

var createDeploymentGroup* = Call_CreateDeploymentGroup_606361(
    name: "createDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentGroup",
    validator: validate_CreateDeploymentGroup_606362, base: "/",
    url: url_CreateDeploymentGroup_606363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_606376 = ref object of OpenApiRestCall_605589
proc url_DeleteApplication_606378(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteApplication_606377(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Deletes an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606379 = header.getOrDefault("X-Amz-Target")
  valid_606379 = validateParameter(valid_606379, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteApplication"))
  if valid_606379 != nil:
    section.add "X-Amz-Target", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Signature")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Signature", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Content-Sha256", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Date")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Date", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Credential")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Credential", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Security-Token")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Security-Token", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-Algorithm")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Algorithm", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-SignedHeaders", valid_606386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606388: Call_DeleteApplication_606376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_606388.validator(path, query, header, formData, body)
  let scheme = call_606388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606388.url(scheme.get, call_606388.host, call_606388.base,
                         call_606388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606388, url, valid)

proc call*(call_606389: Call_DeleteApplication_606376; body: JsonNode): Recallable =
  ## deleteApplication
  ## Deletes an application.
  ##   body: JObject (required)
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  result = call_606389.call(nil, nil, nil, nil, body_606390)

var deleteApplication* = Call_DeleteApplication_606376(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteApplication",
    validator: validate_DeleteApplication_606377, base: "/",
    url: url_DeleteApplication_606378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentConfig_606391 = ref object of OpenApiRestCall_605589
proc url_DeleteDeploymentConfig_606393(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeploymentConfig_606392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606394 = header.getOrDefault("X-Amz-Target")
  valid_606394 = validateParameter(valid_606394, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentConfig"))
  if valid_606394 != nil:
    section.add "X-Amz-Target", valid_606394
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606403: Call_DeleteDeploymentConfig_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ## 
  let valid = call_606403.validator(path, query, header, formData, body)
  let scheme = call_606403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606403.url(scheme.get, call_606403.host, call_606403.base,
                         call_606403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606403, url, valid)

proc call*(call_606404: Call_DeleteDeploymentConfig_606391; body: JsonNode): Recallable =
  ## deleteDeploymentConfig
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ##   body: JObject (required)
  var body_606405 = newJObject()
  if body != nil:
    body_606405 = body
  result = call_606404.call(nil, nil, nil, nil, body_606405)

var deleteDeploymentConfig* = Call_DeleteDeploymentConfig_606391(
    name: "deleteDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentConfig",
    validator: validate_DeleteDeploymentConfig_606392, base: "/",
    url: url_DeleteDeploymentConfig_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentGroup_606406 = ref object of OpenApiRestCall_605589
proc url_DeleteDeploymentGroup_606408(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDeploymentGroup_606407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a deployment group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606409 = header.getOrDefault("X-Amz-Target")
  valid_606409 = validateParameter(valid_606409, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentGroup"))
  if valid_606409 != nil:
    section.add "X-Amz-Target", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Signature")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Signature", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Content-Sha256", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Date")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Date", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Credential")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Credential", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Security-Token")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Security-Token", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-Algorithm")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Algorithm", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-SignedHeaders", valid_606416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606418: Call_DeleteDeploymentGroup_606406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a deployment group.
  ## 
  let valid = call_606418.validator(path, query, header, formData, body)
  let scheme = call_606418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606418.url(scheme.get, call_606418.host, call_606418.base,
                         call_606418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606418, url, valid)

proc call*(call_606419: Call_DeleteDeploymentGroup_606406; body: JsonNode): Recallable =
  ## deleteDeploymentGroup
  ## Deletes a deployment group.
  ##   body: JObject (required)
  var body_606420 = newJObject()
  if body != nil:
    body_606420 = body
  result = call_606419.call(nil, nil, nil, nil, body_606420)

var deleteDeploymentGroup* = Call_DeleteDeploymentGroup_606406(
    name: "deleteDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentGroup",
    validator: validate_DeleteDeploymentGroup_606407, base: "/",
    url: url_DeleteDeploymentGroup_606408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGitHubAccountToken_606421 = ref object of OpenApiRestCall_605589
proc url_DeleteGitHubAccountToken_606423(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGitHubAccountToken_606422(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a GitHub account connection.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606424 = header.getOrDefault("X-Amz-Target")
  valid_606424 = validateParameter(valid_606424, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteGitHubAccountToken"))
  if valid_606424 != nil:
    section.add "X-Amz-Target", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606433: Call_DeleteGitHubAccountToken_606421; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a GitHub account connection.
  ## 
  let valid = call_606433.validator(path, query, header, formData, body)
  let scheme = call_606433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606433.url(scheme.get, call_606433.host, call_606433.base,
                         call_606433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606433, url, valid)

proc call*(call_606434: Call_DeleteGitHubAccountToken_606421; body: JsonNode): Recallable =
  ## deleteGitHubAccountToken
  ## Deletes a GitHub account connection.
  ##   body: JObject (required)
  var body_606435 = newJObject()
  if body != nil:
    body_606435 = body
  result = call_606434.call(nil, nil, nil, nil, body_606435)

var deleteGitHubAccountToken* = Call_DeleteGitHubAccountToken_606421(
    name: "deleteGitHubAccountToken", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteGitHubAccountToken",
    validator: validate_DeleteGitHubAccountToken_606422, base: "/",
    url: url_DeleteGitHubAccountToken_606423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterOnPremisesInstance_606436 = ref object of OpenApiRestCall_605589
proc url_DeregisterOnPremisesInstance_606438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterOnPremisesInstance_606437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deregisters an on-premises instance.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606439 = header.getOrDefault("X-Amz-Target")
  valid_606439 = validateParameter(valid_606439, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeregisterOnPremisesInstance"))
  if valid_606439 != nil:
    section.add "X-Amz-Target", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Signature")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Signature", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Content-Sha256", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Date")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Date", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Credential")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Credential", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Security-Token")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Security-Token", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-Algorithm")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Algorithm", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-SignedHeaders", valid_606446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606448: Call_DeregisterOnPremisesInstance_606436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an on-premises instance.
  ## 
  let valid = call_606448.validator(path, query, header, formData, body)
  let scheme = call_606448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606448.url(scheme.get, call_606448.host, call_606448.base,
                         call_606448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606448, url, valid)

proc call*(call_606449: Call_DeregisterOnPremisesInstance_606436; body: JsonNode): Recallable =
  ## deregisterOnPremisesInstance
  ## Deregisters an on-premises instance.
  ##   body: JObject (required)
  var body_606450 = newJObject()
  if body != nil:
    body_606450 = body
  result = call_606449.call(nil, nil, nil, nil, body_606450)

var deregisterOnPremisesInstance* = Call_DeregisterOnPremisesInstance_606436(
    name: "deregisterOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeregisterOnPremisesInstance",
    validator: validate_DeregisterOnPremisesInstance_606437, base: "/",
    url: url_DeregisterOnPremisesInstance_606438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_606451 = ref object of OpenApiRestCall_605589
proc url_GetApplication_606453(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplication_606452(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Gets information about an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606454 = header.getOrDefault("X-Amz-Target")
  valid_606454 = validateParameter(valid_606454, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplication"))
  if valid_606454 != nil:
    section.add "X-Amz-Target", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606463: Call_GetApplication_606451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application.
  ## 
  let valid = call_606463.validator(path, query, header, formData, body)
  let scheme = call_606463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606463.url(scheme.get, call_606463.host, call_606463.base,
                         call_606463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606463, url, valid)

proc call*(call_606464: Call_GetApplication_606451; body: JsonNode): Recallable =
  ## getApplication
  ## Gets information about an application.
  ##   body: JObject (required)
  var body_606465 = newJObject()
  if body != nil:
    body_606465 = body
  result = call_606464.call(nil, nil, nil, nil, body_606465)

var getApplication* = Call_GetApplication_606451(name: "getApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplication",
    validator: validate_GetApplication_606452, base: "/", url: url_GetApplication_606453,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationRevision_606466 = ref object of OpenApiRestCall_605589
proc url_GetApplicationRevision_606468(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetApplicationRevision_606467(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an application revision.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606469 = header.getOrDefault("X-Amz-Target")
  valid_606469 = validateParameter(valid_606469, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplicationRevision"))
  if valid_606469 != nil:
    section.add "X-Amz-Target", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Signature")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Signature", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Content-Sha256", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Date")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Date", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Credential")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Credential", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Security-Token")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Security-Token", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Algorithm")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Algorithm", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-SignedHeaders", valid_606476
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606478: Call_GetApplicationRevision_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application revision.
  ## 
  let valid = call_606478.validator(path, query, header, formData, body)
  let scheme = call_606478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606478.url(scheme.get, call_606478.host, call_606478.base,
                         call_606478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606478, url, valid)

proc call*(call_606479: Call_GetApplicationRevision_606466; body: JsonNode): Recallable =
  ## getApplicationRevision
  ## Gets information about an application revision.
  ##   body: JObject (required)
  var body_606480 = newJObject()
  if body != nil:
    body_606480 = body
  result = call_606479.call(nil, nil, nil, nil, body_606480)

var getApplicationRevision* = Call_GetApplicationRevision_606466(
    name: "getApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplicationRevision",
    validator: validate_GetApplicationRevision_606467, base: "/",
    url: url_GetApplicationRevision_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_606481 = ref object of OpenApiRestCall_605589
proc url_GetDeployment_606483(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeployment_606482(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606484 = header.getOrDefault("X-Amz-Target")
  valid_606484 = validateParameter(valid_606484, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeployment"))
  if valid_606484 != nil:
    section.add "X-Amz-Target", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_GetDeployment_606481; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_GetDeployment_606481; body: JsonNode): Recallable =
  ## getDeployment
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ##   body: JObject (required)
  var body_606495 = newJObject()
  if body != nil:
    body_606495 = body
  result = call_606494.call(nil, nil, nil, nil, body_606495)

var getDeployment* = Call_GetDeployment_606481(name: "getDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeployment",
    validator: validate_GetDeployment_606482, base: "/", url: url_GetDeployment_606483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentConfig_606496 = ref object of OpenApiRestCall_605589
proc url_GetDeploymentConfig_606498(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentConfig_606497(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about a deployment configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606499 = header.getOrDefault("X-Amz-Target")
  valid_606499 = validateParameter(valid_606499, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentConfig"))
  if valid_606499 != nil:
    section.add "X-Amz-Target", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Signature")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Signature", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Content-Sha256", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Date")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Date", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Credential")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Credential", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Security-Token")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Security-Token", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Algorithm")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Algorithm", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-SignedHeaders", valid_606506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606508: Call_GetDeploymentConfig_606496; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment configuration.
  ## 
  let valid = call_606508.validator(path, query, header, formData, body)
  let scheme = call_606508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606508.url(scheme.get, call_606508.host, call_606508.base,
                         call_606508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606508, url, valid)

proc call*(call_606509: Call_GetDeploymentConfig_606496; body: JsonNode): Recallable =
  ## getDeploymentConfig
  ## Gets information about a deployment configuration.
  ##   body: JObject (required)
  var body_606510 = newJObject()
  if body != nil:
    body_606510 = body
  result = call_606509.call(nil, nil, nil, nil, body_606510)

var getDeploymentConfig* = Call_GetDeploymentConfig_606496(
    name: "getDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentConfig",
    validator: validate_GetDeploymentConfig_606497, base: "/",
    url: url_GetDeploymentConfig_606498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentGroup_606511 = ref object of OpenApiRestCall_605589
proc url_GetDeploymentGroup_606513(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentGroup_606512(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about a deployment group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606514 = header.getOrDefault("X-Amz-Target")
  valid_606514 = validateParameter(valid_606514, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentGroup"))
  if valid_606514 != nil:
    section.add "X-Amz-Target", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Signature")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Signature", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Content-Sha256", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Date")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Date", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Credential")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Credential", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-Security-Token")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-Security-Token", valid_606519
  var valid_606520 = header.getOrDefault("X-Amz-Algorithm")
  valid_606520 = validateParameter(valid_606520, JString, required = false,
                                 default = nil)
  if valid_606520 != nil:
    section.add "X-Amz-Algorithm", valid_606520
  var valid_606521 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-SignedHeaders", valid_606521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606523: Call_GetDeploymentGroup_606511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment group.
  ## 
  let valid = call_606523.validator(path, query, header, formData, body)
  let scheme = call_606523.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606523.url(scheme.get, call_606523.host, call_606523.base,
                         call_606523.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606523, url, valid)

proc call*(call_606524: Call_GetDeploymentGroup_606511; body: JsonNode): Recallable =
  ## getDeploymentGroup
  ## Gets information about a deployment group.
  ##   body: JObject (required)
  var body_606525 = newJObject()
  if body != nil:
    body_606525 = body
  result = call_606524.call(nil, nil, nil, nil, body_606525)

var getDeploymentGroup* = Call_GetDeploymentGroup_606511(
    name: "getDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentGroup",
    validator: validate_GetDeploymentGroup_606512, base: "/",
    url: url_GetDeploymentGroup_606513, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentInstance_606526 = ref object of OpenApiRestCall_605589
proc url_GetDeploymentInstance_606528(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentInstance_606527(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about an instance as part of a deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606529 = header.getOrDefault("X-Amz-Target")
  valid_606529 = validateParameter(valid_606529, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentInstance"))
  if valid_606529 != nil:
    section.add "X-Amz-Target", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Signature")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Signature", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Content-Sha256", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Date")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Date", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-Credential")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-Credential", valid_606533
  var valid_606534 = header.getOrDefault("X-Amz-Security-Token")
  valid_606534 = validateParameter(valid_606534, JString, required = false,
                                 default = nil)
  if valid_606534 != nil:
    section.add "X-Amz-Security-Token", valid_606534
  var valid_606535 = header.getOrDefault("X-Amz-Algorithm")
  valid_606535 = validateParameter(valid_606535, JString, required = false,
                                 default = nil)
  if valid_606535 != nil:
    section.add "X-Amz-Algorithm", valid_606535
  var valid_606536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606536 = validateParameter(valid_606536, JString, required = false,
                                 default = nil)
  if valid_606536 != nil:
    section.add "X-Amz-SignedHeaders", valid_606536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606538: Call_GetDeploymentInstance_606526; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an instance as part of a deployment.
  ## 
  let valid = call_606538.validator(path, query, header, formData, body)
  let scheme = call_606538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606538.url(scheme.get, call_606538.host, call_606538.base,
                         call_606538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606538, url, valid)

proc call*(call_606539: Call_GetDeploymentInstance_606526; body: JsonNode): Recallable =
  ## getDeploymentInstance
  ## Gets information about an instance as part of a deployment.
  ##   body: JObject (required)
  var body_606540 = newJObject()
  if body != nil:
    body_606540 = body
  result = call_606539.call(nil, nil, nil, nil, body_606540)

var getDeploymentInstance* = Call_GetDeploymentInstance_606526(
    name: "getDeploymentInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentInstance",
    validator: validate_GetDeploymentInstance_606527, base: "/",
    url: url_GetDeploymentInstance_606528, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentTarget_606541 = ref object of OpenApiRestCall_605589
proc url_GetDeploymentTarget_606543(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeploymentTarget_606542(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Returns information about a deployment target. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606544 = header.getOrDefault("X-Amz-Target")
  valid_606544 = validateParameter(valid_606544, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentTarget"))
  if valid_606544 != nil:
    section.add "X-Amz-Target", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Signature")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Signature", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Content-Sha256", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Date")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Date", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Credential")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Credential", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-Security-Token")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-Security-Token", valid_606549
  var valid_606550 = header.getOrDefault("X-Amz-Algorithm")
  valid_606550 = validateParameter(valid_606550, JString, required = false,
                                 default = nil)
  if valid_606550 != nil:
    section.add "X-Amz-Algorithm", valid_606550
  var valid_606551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606551 = validateParameter(valid_606551, JString, required = false,
                                 default = nil)
  if valid_606551 != nil:
    section.add "X-Amz-SignedHeaders", valid_606551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606553: Call_GetDeploymentTarget_606541; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about a deployment target. 
  ## 
  let valid = call_606553.validator(path, query, header, formData, body)
  let scheme = call_606553.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606553.url(scheme.get, call_606553.host, call_606553.base,
                         call_606553.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606553, url, valid)

proc call*(call_606554: Call_GetDeploymentTarget_606541; body: JsonNode): Recallable =
  ## getDeploymentTarget
  ##  Returns information about a deployment target. 
  ##   body: JObject (required)
  var body_606555 = newJObject()
  if body != nil:
    body_606555 = body
  result = call_606554.call(nil, nil, nil, nil, body_606555)

var getDeploymentTarget* = Call_GetDeploymentTarget_606541(
    name: "getDeploymentTarget", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentTarget",
    validator: validate_GetDeploymentTarget_606542, base: "/",
    url: url_GetDeploymentTarget_606543, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOnPremisesInstance_606556 = ref object of OpenApiRestCall_605589
proc url_GetOnPremisesInstance_606558(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOnPremisesInstance_606557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Gets information about an on-premises instance. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606559 = header.getOrDefault("X-Amz-Target")
  valid_606559 = validateParameter(valid_606559, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetOnPremisesInstance"))
  if valid_606559 != nil:
    section.add "X-Amz-Target", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Signature")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Signature", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Content-Sha256", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Date")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Date", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-Credential")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-Credential", valid_606563
  var valid_606564 = header.getOrDefault("X-Amz-Security-Token")
  valid_606564 = validateParameter(valid_606564, JString, required = false,
                                 default = nil)
  if valid_606564 != nil:
    section.add "X-Amz-Security-Token", valid_606564
  var valid_606565 = header.getOrDefault("X-Amz-Algorithm")
  valid_606565 = validateParameter(valid_606565, JString, required = false,
                                 default = nil)
  if valid_606565 != nil:
    section.add "X-Amz-Algorithm", valid_606565
  var valid_606566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606566 = validateParameter(valid_606566, JString, required = false,
                                 default = nil)
  if valid_606566 != nil:
    section.add "X-Amz-SignedHeaders", valid_606566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606568: Call_GetOnPremisesInstance_606556; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets information about an on-premises instance. 
  ## 
  let valid = call_606568.validator(path, query, header, formData, body)
  let scheme = call_606568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606568.url(scheme.get, call_606568.host, call_606568.base,
                         call_606568.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606568, url, valid)

proc call*(call_606569: Call_GetOnPremisesInstance_606556; body: JsonNode): Recallable =
  ## getOnPremisesInstance
  ##  Gets information about an on-premises instance. 
  ##   body: JObject (required)
  var body_606570 = newJObject()
  if body != nil:
    body_606570 = body
  result = call_606569.call(nil, nil, nil, nil, body_606570)

var getOnPremisesInstance* = Call_GetOnPremisesInstance_606556(
    name: "getOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetOnPremisesInstance",
    validator: validate_GetOnPremisesInstance_606557, base: "/",
    url: url_GetOnPremisesInstance_606558, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationRevisions_606571 = ref object of OpenApiRestCall_605589
proc url_ListApplicationRevisions_606573(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplicationRevisions_606572(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists information about revisions for an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606574 = query.getOrDefault("nextToken")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "nextToken", valid_606574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606575 = header.getOrDefault("X-Amz-Target")
  valid_606575 = validateParameter(valid_606575, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplicationRevisions"))
  if valid_606575 != nil:
    section.add "X-Amz-Target", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Signature")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Signature", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Content-Sha256", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Date")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Date", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Credential")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Credential", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Security-Token")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Security-Token", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-Algorithm")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-Algorithm", valid_606581
  var valid_606582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606582 = validateParameter(valid_606582, JString, required = false,
                                 default = nil)
  if valid_606582 != nil:
    section.add "X-Amz-SignedHeaders", valid_606582
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606584: Call_ListApplicationRevisions_606571; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about revisions for an application.
  ## 
  let valid = call_606584.validator(path, query, header, formData, body)
  let scheme = call_606584.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606584.url(scheme.get, call_606584.host, call_606584.base,
                         call_606584.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606584, url, valid)

proc call*(call_606585: Call_ListApplicationRevisions_606571; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplicationRevisions
  ## Lists information about revisions for an application.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606586 = newJObject()
  var body_606587 = newJObject()
  add(query_606586, "nextToken", newJString(nextToken))
  if body != nil:
    body_606587 = body
  result = call_606585.call(nil, query_606586, nil, nil, body_606587)

var listApplicationRevisions* = Call_ListApplicationRevisions_606571(
    name: "listApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplicationRevisions",
    validator: validate_ListApplicationRevisions_606572, base: "/",
    url: url_ListApplicationRevisions_606573, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_606589 = ref object of OpenApiRestCall_605589
proc url_ListApplications_606591(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListApplications_606590(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606592 = query.getOrDefault("nextToken")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "nextToken", valid_606592
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606593 = header.getOrDefault("X-Amz-Target")
  valid_606593 = validateParameter(valid_606593, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplications"))
  if valid_606593 != nil:
    section.add "X-Amz-Target", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Signature")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Signature", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Content-Sha256", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-Date")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-Date", valid_606596
  var valid_606597 = header.getOrDefault("X-Amz-Credential")
  valid_606597 = validateParameter(valid_606597, JString, required = false,
                                 default = nil)
  if valid_606597 != nil:
    section.add "X-Amz-Credential", valid_606597
  var valid_606598 = header.getOrDefault("X-Amz-Security-Token")
  valid_606598 = validateParameter(valid_606598, JString, required = false,
                                 default = nil)
  if valid_606598 != nil:
    section.add "X-Amz-Security-Token", valid_606598
  var valid_606599 = header.getOrDefault("X-Amz-Algorithm")
  valid_606599 = validateParameter(valid_606599, JString, required = false,
                                 default = nil)
  if valid_606599 != nil:
    section.add "X-Amz-Algorithm", valid_606599
  var valid_606600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606600 = validateParameter(valid_606600, JString, required = false,
                                 default = nil)
  if valid_606600 != nil:
    section.add "X-Amz-SignedHeaders", valid_606600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606602: Call_ListApplications_606589; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  let valid = call_606602.validator(path, query, header, formData, body)
  let scheme = call_606602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606602.url(scheme.get, call_606602.host, call_606602.base,
                         call_606602.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606602, url, valid)

proc call*(call_606603: Call_ListApplications_606589; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the applications registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606604 = newJObject()
  var body_606605 = newJObject()
  add(query_606604, "nextToken", newJString(nextToken))
  if body != nil:
    body_606605 = body
  result = call_606603.call(nil, query_606604, nil, nil, body_606605)

var listApplications* = Call_ListApplications_606589(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplications",
    validator: validate_ListApplications_606590, base: "/",
    url: url_ListApplications_606591, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentConfigs_606606 = ref object of OpenApiRestCall_605589
proc url_ListDeploymentConfigs_606608(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentConfigs_606607(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606609 = query.getOrDefault("nextToken")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "nextToken", valid_606609
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606610 = header.getOrDefault("X-Amz-Target")
  valid_606610 = validateParameter(valid_606610, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentConfigs"))
  if valid_606610 != nil:
    section.add "X-Amz-Target", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Signature")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Signature", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Content-Sha256", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Date")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Date", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-Credential")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-Credential", valid_606614
  var valid_606615 = header.getOrDefault("X-Amz-Security-Token")
  valid_606615 = validateParameter(valid_606615, JString, required = false,
                                 default = nil)
  if valid_606615 != nil:
    section.add "X-Amz-Security-Token", valid_606615
  var valid_606616 = header.getOrDefault("X-Amz-Algorithm")
  valid_606616 = validateParameter(valid_606616, JString, required = false,
                                 default = nil)
  if valid_606616 != nil:
    section.add "X-Amz-Algorithm", valid_606616
  var valid_606617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-SignedHeaders", valid_606617
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606619: Call_ListDeploymentConfigs_606606; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  let valid = call_606619.validator(path, query, header, formData, body)
  let scheme = call_606619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606619.url(scheme.get, call_606619.host, call_606619.base,
                         call_606619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606619, url, valid)

proc call*(call_606620: Call_ListDeploymentConfigs_606606; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentConfigs
  ## Lists the deployment configurations with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606621 = newJObject()
  var body_606622 = newJObject()
  add(query_606621, "nextToken", newJString(nextToken))
  if body != nil:
    body_606622 = body
  result = call_606620.call(nil, query_606621, nil, nil, body_606622)

var listDeploymentConfigs* = Call_ListDeploymentConfigs_606606(
    name: "listDeploymentConfigs", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentConfigs",
    validator: validate_ListDeploymentConfigs_606607, base: "/",
    url: url_ListDeploymentConfigs_606608, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentGroups_606623 = ref object of OpenApiRestCall_605589
proc url_ListDeploymentGroups_606625(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentGroups_606624(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606626 = query.getOrDefault("nextToken")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "nextToken", valid_606626
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606627 = header.getOrDefault("X-Amz-Target")
  valid_606627 = validateParameter(valid_606627, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentGroups"))
  if valid_606627 != nil:
    section.add "X-Amz-Target", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Signature")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Signature", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-Content-Sha256", valid_606629
  var valid_606630 = header.getOrDefault("X-Amz-Date")
  valid_606630 = validateParameter(valid_606630, JString, required = false,
                                 default = nil)
  if valid_606630 != nil:
    section.add "X-Amz-Date", valid_606630
  var valid_606631 = header.getOrDefault("X-Amz-Credential")
  valid_606631 = validateParameter(valid_606631, JString, required = false,
                                 default = nil)
  if valid_606631 != nil:
    section.add "X-Amz-Credential", valid_606631
  var valid_606632 = header.getOrDefault("X-Amz-Security-Token")
  valid_606632 = validateParameter(valid_606632, JString, required = false,
                                 default = nil)
  if valid_606632 != nil:
    section.add "X-Amz-Security-Token", valid_606632
  var valid_606633 = header.getOrDefault("X-Amz-Algorithm")
  valid_606633 = validateParameter(valid_606633, JString, required = false,
                                 default = nil)
  if valid_606633 != nil:
    section.add "X-Amz-Algorithm", valid_606633
  var valid_606634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-SignedHeaders", valid_606634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606636: Call_ListDeploymentGroups_606623; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_606636.validator(path, query, header, formData, body)
  let scheme = call_606636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606636.url(scheme.get, call_606636.host, call_606636.base,
                         call_606636.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606636, url, valid)

proc call*(call_606637: Call_ListDeploymentGroups_606623; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentGroups
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606638 = newJObject()
  var body_606639 = newJObject()
  add(query_606638, "nextToken", newJString(nextToken))
  if body != nil:
    body_606639 = body
  result = call_606637.call(nil, query_606638, nil, nil, body_606639)

var listDeploymentGroups* = Call_ListDeploymentGroups_606623(
    name: "listDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentGroups",
    validator: validate_ListDeploymentGroups_606624, base: "/",
    url: url_ListDeploymentGroups_606625, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentInstances_606640 = ref object of OpenApiRestCall_605589
proc url_ListDeploymentInstances_606642(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentInstances_606641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606643 = query.getOrDefault("nextToken")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "nextToken", valid_606643
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606644 = header.getOrDefault("X-Amz-Target")
  valid_606644 = validateParameter(valid_606644, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentInstances"))
  if valid_606644 != nil:
    section.add "X-Amz-Target", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Signature")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Signature", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Content-Sha256", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-Date")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-Date", valid_606647
  var valid_606648 = header.getOrDefault("X-Amz-Credential")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Credential", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Security-Token")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Security-Token", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Algorithm")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Algorithm", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-SignedHeaders", valid_606651
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606653: Call_ListDeploymentInstances_606640; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  let valid = call_606653.validator(path, query, header, formData, body)
  let scheme = call_606653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606653.url(scheme.get, call_606653.host, call_606653.base,
                         call_606653.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606653, url, valid)

proc call*(call_606654: Call_ListDeploymentInstances_606640; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentInstances
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606655 = newJObject()
  var body_606656 = newJObject()
  add(query_606655, "nextToken", newJString(nextToken))
  if body != nil:
    body_606656 = body
  result = call_606654.call(nil, query_606655, nil, nil, body_606656)

var listDeploymentInstances* = Call_ListDeploymentInstances_606640(
    name: "listDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentInstances",
    validator: validate_ListDeploymentInstances_606641, base: "/",
    url: url_ListDeploymentInstances_606642, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentTargets_606657 = ref object of OpenApiRestCall_605589
proc url_ListDeploymentTargets_606659(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentTargets_606658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Returns an array of target IDs that are associated a deployment. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606660 = header.getOrDefault("X-Amz-Target")
  valid_606660 = validateParameter(valid_606660, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentTargets"))
  if valid_606660 != nil:
    section.add "X-Amz-Target", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Signature")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Signature", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Content-Sha256", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Date")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Date", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Credential")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Credential", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Security-Token")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Security-Token", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Algorithm")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Algorithm", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-SignedHeaders", valid_606667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606669: Call_ListDeploymentTargets_606657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of target IDs that are associated a deployment. 
  ## 
  let valid = call_606669.validator(path, query, header, formData, body)
  let scheme = call_606669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606669.url(scheme.get, call_606669.host, call_606669.base,
                         call_606669.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606669, url, valid)

proc call*(call_606670: Call_ListDeploymentTargets_606657; body: JsonNode): Recallable =
  ## listDeploymentTargets
  ##  Returns an array of target IDs that are associated a deployment. 
  ##   body: JObject (required)
  var body_606671 = newJObject()
  if body != nil:
    body_606671 = body
  result = call_606670.call(nil, nil, nil, nil, body_606671)

var listDeploymentTargets* = Call_ListDeploymentTargets_606657(
    name: "listDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentTargets",
    validator: validate_ListDeploymentTargets_606658, base: "/",
    url: url_ListDeploymentTargets_606659, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_606672 = ref object of OpenApiRestCall_605589
proc url_ListDeployments_606674(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeployments_606673(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_606675 = query.getOrDefault("nextToken")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "nextToken", valid_606675
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606676 = header.getOrDefault("X-Amz-Target")
  valid_606676 = validateParameter(valid_606676, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeployments"))
  if valid_606676 != nil:
    section.add "X-Amz-Target", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Signature")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Signature", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Content-Sha256", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Date")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Date", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Credential")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Credential", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Security-Token")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Security-Token", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Algorithm")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Algorithm", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-SignedHeaders", valid_606683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606685: Call_ListDeployments_606672; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_606685.validator(path, query, header, formData, body)
  let scheme = call_606685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606685.url(scheme.get, call_606685.host, call_606685.base,
                         call_606685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606685, url, valid)

proc call*(call_606686: Call_ListDeployments_606672; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_606687 = newJObject()
  var body_606688 = newJObject()
  add(query_606687, "nextToken", newJString(nextToken))
  if body != nil:
    body_606688 = body
  result = call_606686.call(nil, query_606687, nil, nil, body_606688)

var listDeployments* = Call_ListDeployments_606672(name: "listDeployments",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeployments",
    validator: validate_ListDeployments_606673, base: "/", url: url_ListDeployments_606674,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGitHubAccountTokenNames_606689 = ref object of OpenApiRestCall_605589
proc url_ListGitHubAccountTokenNames_606691(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGitHubAccountTokenNames_606690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the names of stored connections to GitHub accounts.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606692 = header.getOrDefault("X-Amz-Target")
  valid_606692 = validateParameter(valid_606692, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListGitHubAccountTokenNames"))
  if valid_606692 != nil:
    section.add "X-Amz-Target", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Signature")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Signature", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Content-Sha256", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Date")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Date", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Credential")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Credential", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Security-Token")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Security-Token", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Algorithm")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Algorithm", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-SignedHeaders", valid_606699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606701: Call_ListGitHubAccountTokenNames_606689; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the names of stored connections to GitHub accounts.
  ## 
  let valid = call_606701.validator(path, query, header, formData, body)
  let scheme = call_606701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606701.url(scheme.get, call_606701.host, call_606701.base,
                         call_606701.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606701, url, valid)

proc call*(call_606702: Call_ListGitHubAccountTokenNames_606689; body: JsonNode): Recallable =
  ## listGitHubAccountTokenNames
  ## Lists the names of stored connections to GitHub accounts.
  ##   body: JObject (required)
  var body_606703 = newJObject()
  if body != nil:
    body_606703 = body
  result = call_606702.call(nil, nil, nil, nil, body_606703)

var listGitHubAccountTokenNames* = Call_ListGitHubAccountTokenNames_606689(
    name: "listGitHubAccountTokenNames", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListGitHubAccountTokenNames",
    validator: validate_ListGitHubAccountTokenNames_606690, base: "/",
    url: url_ListGitHubAccountTokenNames_606691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOnPremisesInstances_606704 = ref object of OpenApiRestCall_605589
proc url_ListOnPremisesInstances_606706(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOnPremisesInstances_606705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606707 = header.getOrDefault("X-Amz-Target")
  valid_606707 = validateParameter(valid_606707, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListOnPremisesInstances"))
  if valid_606707 != nil:
    section.add "X-Amz-Target", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Signature")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Signature", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Content-Sha256", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Date")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Date", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Credential")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Credential", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Security-Token")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Security-Token", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Algorithm")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Algorithm", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-SignedHeaders", valid_606714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606716: Call_ListOnPremisesInstances_606704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ## 
  let valid = call_606716.validator(path, query, header, formData, body)
  let scheme = call_606716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606716.url(scheme.get, call_606716.host, call_606716.base,
                         call_606716.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606716, url, valid)

proc call*(call_606717: Call_ListOnPremisesInstances_606704; body: JsonNode): Recallable =
  ## listOnPremisesInstances
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ##   body: JObject (required)
  var body_606718 = newJObject()
  if body != nil:
    body_606718 = body
  result = call_606717.call(nil, nil, nil, nil, body_606718)

var listOnPremisesInstances* = Call_ListOnPremisesInstances_606704(
    name: "listOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListOnPremisesInstances",
    validator: validate_ListOnPremisesInstances_606705, base: "/",
    url: url_ListOnPremisesInstances_606706, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606719 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606721(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_606720(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606722 = header.getOrDefault("X-Amz-Target")
  valid_606722 = validateParameter(valid_606722, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListTagsForResource"))
  if valid_606722 != nil:
    section.add "X-Amz-Target", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Signature")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Signature", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Content-Sha256", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Date")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Date", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Credential")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Credential", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Security-Token")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Security-Token", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-Algorithm")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-Algorithm", valid_606728
  var valid_606729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "X-Amz-SignedHeaders", valid_606729
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606731: Call_ListTagsForResource_606719; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ## 
  let valid = call_606731.validator(path, query, header, formData, body)
  let scheme = call_606731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606731.url(scheme.get, call_606731.host, call_606731.base,
                         call_606731.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606731, url, valid)

proc call*(call_606732: Call_ListTagsForResource_606719; body: JsonNode): Recallable =
  ## listTagsForResource
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ##   body: JObject (required)
  var body_606733 = newJObject()
  if body != nil:
    body_606733 = body
  result = call_606732.call(nil, nil, nil, nil, body_606733)

var listTagsForResource* = Call_ListTagsForResource_606719(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListTagsForResource",
    validator: validate_ListTagsForResource_606720, base: "/",
    url: url_ListTagsForResource_606721, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleEventHookExecutionStatus_606734 = ref object of OpenApiRestCall_605589
proc url_PutLifecycleEventHookExecutionStatus_606736(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutLifecycleEventHookExecutionStatus_606735(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606737 = header.getOrDefault("X-Amz-Target")
  valid_606737 = validateParameter(valid_606737, JString, required = true, default = newJString(
      "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"))
  if valid_606737 != nil:
    section.add "X-Amz-Target", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Signature")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Signature", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Content-Sha256", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Date")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Date", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-Credential")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Credential", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Security-Token")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Security-Token", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Algorithm")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Algorithm", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-SignedHeaders", valid_606744
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606746: Call_PutLifecycleEventHookExecutionStatus_606734;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ## 
  let valid = call_606746.validator(path, query, header, formData, body)
  let scheme = call_606746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606746.url(scheme.get, call_606746.host, call_606746.base,
                         call_606746.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606746, url, valid)

proc call*(call_606747: Call_PutLifecycleEventHookExecutionStatus_606734;
          body: JsonNode): Recallable =
  ## putLifecycleEventHookExecutionStatus
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ##   body: JObject (required)
  var body_606748 = newJObject()
  if body != nil:
    body_606748 = body
  result = call_606747.call(nil, nil, nil, nil, body_606748)

var putLifecycleEventHookExecutionStatus* = Call_PutLifecycleEventHookExecutionStatus_606734(
    name: "putLifecycleEventHookExecutionStatus", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus",
    validator: validate_PutLifecycleEventHookExecutionStatus_606735, base: "/",
    url: url_PutLifecycleEventHookExecutionStatus_606736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterApplicationRevision_606749 = ref object of OpenApiRestCall_605589
proc url_RegisterApplicationRevision_606751(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterApplicationRevision_606750(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606752 = header.getOrDefault("X-Amz-Target")
  valid_606752 = validateParameter(valid_606752, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterApplicationRevision"))
  if valid_606752 != nil:
    section.add "X-Amz-Target", valid_606752
  var valid_606753 = header.getOrDefault("X-Amz-Signature")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "X-Amz-Signature", valid_606753
  var valid_606754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "X-Amz-Content-Sha256", valid_606754
  var valid_606755 = header.getOrDefault("X-Amz-Date")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "X-Amz-Date", valid_606755
  var valid_606756 = header.getOrDefault("X-Amz-Credential")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Credential", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Security-Token")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Security-Token", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Algorithm")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Algorithm", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-SignedHeaders", valid_606759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606761: Call_RegisterApplicationRevision_606749; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ## 
  let valid = call_606761.validator(path, query, header, formData, body)
  let scheme = call_606761.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606761.url(scheme.get, call_606761.host, call_606761.base,
                         call_606761.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606761, url, valid)

proc call*(call_606762: Call_RegisterApplicationRevision_606749; body: JsonNode): Recallable =
  ## registerApplicationRevision
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ##   body: JObject (required)
  var body_606763 = newJObject()
  if body != nil:
    body_606763 = body
  result = call_606762.call(nil, nil, nil, nil, body_606763)

var registerApplicationRevision* = Call_RegisterApplicationRevision_606749(
    name: "registerApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterApplicationRevision",
    validator: validate_RegisterApplicationRevision_606750, base: "/",
    url: url_RegisterApplicationRevision_606751,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterOnPremisesInstance_606764 = ref object of OpenApiRestCall_605589
proc url_RegisterOnPremisesInstance_606766(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterOnPremisesInstance_606765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606767 = header.getOrDefault("X-Amz-Target")
  valid_606767 = validateParameter(valid_606767, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterOnPremisesInstance"))
  if valid_606767 != nil:
    section.add "X-Amz-Target", valid_606767
  var valid_606768 = header.getOrDefault("X-Amz-Signature")
  valid_606768 = validateParameter(valid_606768, JString, required = false,
                                 default = nil)
  if valid_606768 != nil:
    section.add "X-Amz-Signature", valid_606768
  var valid_606769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606769 = validateParameter(valid_606769, JString, required = false,
                                 default = nil)
  if valid_606769 != nil:
    section.add "X-Amz-Content-Sha256", valid_606769
  var valid_606770 = header.getOrDefault("X-Amz-Date")
  valid_606770 = validateParameter(valid_606770, JString, required = false,
                                 default = nil)
  if valid_606770 != nil:
    section.add "X-Amz-Date", valid_606770
  var valid_606771 = header.getOrDefault("X-Amz-Credential")
  valid_606771 = validateParameter(valid_606771, JString, required = false,
                                 default = nil)
  if valid_606771 != nil:
    section.add "X-Amz-Credential", valid_606771
  var valid_606772 = header.getOrDefault("X-Amz-Security-Token")
  valid_606772 = validateParameter(valid_606772, JString, required = false,
                                 default = nil)
  if valid_606772 != nil:
    section.add "X-Amz-Security-Token", valid_606772
  var valid_606773 = header.getOrDefault("X-Amz-Algorithm")
  valid_606773 = validateParameter(valid_606773, JString, required = false,
                                 default = nil)
  if valid_606773 != nil:
    section.add "X-Amz-Algorithm", valid_606773
  var valid_606774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-SignedHeaders", valid_606774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606776: Call_RegisterOnPremisesInstance_606764; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ## 
  let valid = call_606776.validator(path, query, header, formData, body)
  let scheme = call_606776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606776.url(scheme.get, call_606776.host, call_606776.base,
                         call_606776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606776, url, valid)

proc call*(call_606777: Call_RegisterOnPremisesInstance_606764; body: JsonNode): Recallable =
  ## registerOnPremisesInstance
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ##   body: JObject (required)
  var body_606778 = newJObject()
  if body != nil:
    body_606778 = body
  result = call_606777.call(nil, nil, nil, nil, body_606778)

var registerOnPremisesInstance* = Call_RegisterOnPremisesInstance_606764(
    name: "registerOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterOnPremisesInstance",
    validator: validate_RegisterOnPremisesInstance_606765, base: "/",
    url: url_RegisterOnPremisesInstance_606766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromOnPremisesInstances_606779 = ref object of OpenApiRestCall_605589
proc url_RemoveTagsFromOnPremisesInstances_606781(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromOnPremisesInstances_606780(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes one or more tags from one or more on-premises instances.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606782 = header.getOrDefault("X-Amz-Target")
  valid_606782 = validateParameter(valid_606782, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"))
  if valid_606782 != nil:
    section.add "X-Amz-Target", valid_606782
  var valid_606783 = header.getOrDefault("X-Amz-Signature")
  valid_606783 = validateParameter(valid_606783, JString, required = false,
                                 default = nil)
  if valid_606783 != nil:
    section.add "X-Amz-Signature", valid_606783
  var valid_606784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606784 = validateParameter(valid_606784, JString, required = false,
                                 default = nil)
  if valid_606784 != nil:
    section.add "X-Amz-Content-Sha256", valid_606784
  var valid_606785 = header.getOrDefault("X-Amz-Date")
  valid_606785 = validateParameter(valid_606785, JString, required = false,
                                 default = nil)
  if valid_606785 != nil:
    section.add "X-Amz-Date", valid_606785
  var valid_606786 = header.getOrDefault("X-Amz-Credential")
  valid_606786 = validateParameter(valid_606786, JString, required = false,
                                 default = nil)
  if valid_606786 != nil:
    section.add "X-Amz-Credential", valid_606786
  var valid_606787 = header.getOrDefault("X-Amz-Security-Token")
  valid_606787 = validateParameter(valid_606787, JString, required = false,
                                 default = nil)
  if valid_606787 != nil:
    section.add "X-Amz-Security-Token", valid_606787
  var valid_606788 = header.getOrDefault("X-Amz-Algorithm")
  valid_606788 = validateParameter(valid_606788, JString, required = false,
                                 default = nil)
  if valid_606788 != nil:
    section.add "X-Amz-Algorithm", valid_606788
  var valid_606789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606789 = validateParameter(valid_606789, JString, required = false,
                                 default = nil)
  if valid_606789 != nil:
    section.add "X-Amz-SignedHeaders", valid_606789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606791: Call_RemoveTagsFromOnPremisesInstances_606779;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes one or more tags from one or more on-premises instances.
  ## 
  let valid = call_606791.validator(path, query, header, formData, body)
  let scheme = call_606791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606791.url(scheme.get, call_606791.host, call_606791.base,
                         call_606791.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606791, url, valid)

proc call*(call_606792: Call_RemoveTagsFromOnPremisesInstances_606779;
          body: JsonNode): Recallable =
  ## removeTagsFromOnPremisesInstances
  ## Removes one or more tags from one or more on-premises instances.
  ##   body: JObject (required)
  var body_606793 = newJObject()
  if body != nil:
    body_606793 = body
  result = call_606792.call(nil, nil, nil, nil, body_606793)

var removeTagsFromOnPremisesInstances* = Call_RemoveTagsFromOnPremisesInstances_606779(
    name: "removeTagsFromOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances",
    validator: validate_RemoveTagsFromOnPremisesInstances_606780, base: "/",
    url: url_RemoveTagsFromOnPremisesInstances_606781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SkipWaitTimeForInstanceTermination_606794 = ref object of OpenApiRestCall_605589
proc url_SkipWaitTimeForInstanceTermination_606796(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SkipWaitTimeForInstanceTermination_606795(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606797 = header.getOrDefault("X-Amz-Target")
  valid_606797 = validateParameter(valid_606797, JString, required = true, default = newJString(
      "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"))
  if valid_606797 != nil:
    section.add "X-Amz-Target", valid_606797
  var valid_606798 = header.getOrDefault("X-Amz-Signature")
  valid_606798 = validateParameter(valid_606798, JString, required = false,
                                 default = nil)
  if valid_606798 != nil:
    section.add "X-Amz-Signature", valid_606798
  var valid_606799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606799 = validateParameter(valid_606799, JString, required = false,
                                 default = nil)
  if valid_606799 != nil:
    section.add "X-Amz-Content-Sha256", valid_606799
  var valid_606800 = header.getOrDefault("X-Amz-Date")
  valid_606800 = validateParameter(valid_606800, JString, required = false,
                                 default = nil)
  if valid_606800 != nil:
    section.add "X-Amz-Date", valid_606800
  var valid_606801 = header.getOrDefault("X-Amz-Credential")
  valid_606801 = validateParameter(valid_606801, JString, required = false,
                                 default = nil)
  if valid_606801 != nil:
    section.add "X-Amz-Credential", valid_606801
  var valid_606802 = header.getOrDefault("X-Amz-Security-Token")
  valid_606802 = validateParameter(valid_606802, JString, required = false,
                                 default = nil)
  if valid_606802 != nil:
    section.add "X-Amz-Security-Token", valid_606802
  var valid_606803 = header.getOrDefault("X-Amz-Algorithm")
  valid_606803 = validateParameter(valid_606803, JString, required = false,
                                 default = nil)
  if valid_606803 != nil:
    section.add "X-Amz-Algorithm", valid_606803
  var valid_606804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-SignedHeaders", valid_606804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606806: Call_SkipWaitTimeForInstanceTermination_606794;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ## 
  let valid = call_606806.validator(path, query, header, formData, body)
  let scheme = call_606806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606806.url(scheme.get, call_606806.host, call_606806.base,
                         call_606806.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606806, url, valid)

proc call*(call_606807: Call_SkipWaitTimeForInstanceTermination_606794;
          body: JsonNode): Recallable =
  ## skipWaitTimeForInstanceTermination
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ##   body: JObject (required)
  var body_606808 = newJObject()
  if body != nil:
    body_606808 = body
  result = call_606807.call(nil, nil, nil, nil, body_606808)

var skipWaitTimeForInstanceTermination* = Call_SkipWaitTimeForInstanceTermination_606794(
    name: "skipWaitTimeForInstanceTermination", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.SkipWaitTimeForInstanceTermination",
    validator: validate_SkipWaitTimeForInstanceTermination_606795, base: "/",
    url: url_SkipWaitTimeForInstanceTermination_606796,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_606809 = ref object of OpenApiRestCall_605589
proc url_StopDeployment_606811(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopDeployment_606810(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Attempts to stop an ongoing deployment.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606812 = header.getOrDefault("X-Amz-Target")
  valid_606812 = validateParameter(valid_606812, JString, required = true, default = newJString(
      "CodeDeploy_20141006.StopDeployment"))
  if valid_606812 != nil:
    section.add "X-Amz-Target", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Signature")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Signature", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Content-Sha256", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Date")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Date", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Credential")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Credential", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-Security-Token")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-Security-Token", valid_606817
  var valid_606818 = header.getOrDefault("X-Amz-Algorithm")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Algorithm", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-SignedHeaders", valid_606819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606821: Call_StopDeployment_606809; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop an ongoing deployment.
  ## 
  let valid = call_606821.validator(path, query, header, formData, body)
  let scheme = call_606821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606821.url(scheme.get, call_606821.host, call_606821.base,
                         call_606821.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606821, url, valid)

proc call*(call_606822: Call_StopDeployment_606809; body: JsonNode): Recallable =
  ## stopDeployment
  ## Attempts to stop an ongoing deployment.
  ##   body: JObject (required)
  var body_606823 = newJObject()
  if body != nil:
    body_606823 = body
  result = call_606822.call(nil, nil, nil, nil, body_606823)

var stopDeployment* = Call_StopDeployment_606809(name: "stopDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.StopDeployment",
    validator: validate_StopDeployment_606810, base: "/", url: url_StopDeployment_606811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606824 = ref object of OpenApiRestCall_605589
proc url_TagResource_606826(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TagResource_606825(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606827 = header.getOrDefault("X-Amz-Target")
  valid_606827 = validateParameter(valid_606827, JString, required = true, default = newJString(
      "CodeDeploy_20141006.TagResource"))
  if valid_606827 != nil:
    section.add "X-Amz-Target", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Signature")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Signature", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Content-Sha256", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Date")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Date", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Credential")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Credential", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-Security-Token")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Security-Token", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Algorithm")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Algorithm", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-SignedHeaders", valid_606834
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606836: Call_TagResource_606824; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ## 
  let valid = call_606836.validator(path, query, header, formData, body)
  let scheme = call_606836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606836.url(scheme.get, call_606836.host, call_606836.base,
                         call_606836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606836, url, valid)

proc call*(call_606837: Call_TagResource_606824; body: JsonNode): Recallable =
  ## tagResource
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ##   body: JObject (required)
  var body_606838 = newJObject()
  if body != nil:
    body_606838 = body
  result = call_606837.call(nil, nil, nil, nil, body_606838)

var tagResource* = Call_TagResource_606824(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.TagResource",
                                        validator: validate_TagResource_606825,
                                        base: "/", url: url_TagResource_606826,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606839 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606841(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UntagResource_606840(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606842 = header.getOrDefault("X-Amz-Target")
  valid_606842 = validateParameter(valid_606842, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UntagResource"))
  if valid_606842 != nil:
    section.add "X-Amz-Target", valid_606842
  var valid_606843 = header.getOrDefault("X-Amz-Signature")
  valid_606843 = validateParameter(valid_606843, JString, required = false,
                                 default = nil)
  if valid_606843 != nil:
    section.add "X-Amz-Signature", valid_606843
  var valid_606844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606844 = validateParameter(valid_606844, JString, required = false,
                                 default = nil)
  if valid_606844 != nil:
    section.add "X-Amz-Content-Sha256", valid_606844
  var valid_606845 = header.getOrDefault("X-Amz-Date")
  valid_606845 = validateParameter(valid_606845, JString, required = false,
                                 default = nil)
  if valid_606845 != nil:
    section.add "X-Amz-Date", valid_606845
  var valid_606846 = header.getOrDefault("X-Amz-Credential")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Credential", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Security-Token")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Security-Token", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Algorithm")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Algorithm", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-SignedHeaders", valid_606849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606851: Call_UntagResource_606839; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ## 
  let valid = call_606851.validator(path, query, header, formData, body)
  let scheme = call_606851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606851.url(scheme.get, call_606851.host, call_606851.base,
                         call_606851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606851, url, valid)

proc call*(call_606852: Call_UntagResource_606839; body: JsonNode): Recallable =
  ## untagResource
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ##   body: JObject (required)
  var body_606853 = newJObject()
  if body != nil:
    body_606853 = body
  result = call_606852.call(nil, nil, nil, nil, body_606853)

var untagResource* = Call_UntagResource_606839(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UntagResource",
    validator: validate_UntagResource_606840, base: "/", url: url_UntagResource_606841,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_606854 = ref object of OpenApiRestCall_605589
proc url_UpdateApplication_606856(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateApplication_606855(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Changes the name of an application.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606857 = header.getOrDefault("X-Amz-Target")
  valid_606857 = validateParameter(valid_606857, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateApplication"))
  if valid_606857 != nil:
    section.add "X-Amz-Target", valid_606857
  var valid_606858 = header.getOrDefault("X-Amz-Signature")
  valid_606858 = validateParameter(valid_606858, JString, required = false,
                                 default = nil)
  if valid_606858 != nil:
    section.add "X-Amz-Signature", valid_606858
  var valid_606859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606859 = validateParameter(valid_606859, JString, required = false,
                                 default = nil)
  if valid_606859 != nil:
    section.add "X-Amz-Content-Sha256", valid_606859
  var valid_606860 = header.getOrDefault("X-Amz-Date")
  valid_606860 = validateParameter(valid_606860, JString, required = false,
                                 default = nil)
  if valid_606860 != nil:
    section.add "X-Amz-Date", valid_606860
  var valid_606861 = header.getOrDefault("X-Amz-Credential")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Credential", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Security-Token")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Security-Token", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Algorithm")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Algorithm", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-SignedHeaders", valid_606864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606866: Call_UpdateApplication_606854; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the name of an application.
  ## 
  let valid = call_606866.validator(path, query, header, formData, body)
  let scheme = call_606866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606866.url(scheme.get, call_606866.host, call_606866.base,
                         call_606866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606866, url, valid)

proc call*(call_606867: Call_UpdateApplication_606854; body: JsonNode): Recallable =
  ## updateApplication
  ## Changes the name of an application.
  ##   body: JObject (required)
  var body_606868 = newJObject()
  if body != nil:
    body_606868 = body
  result = call_606867.call(nil, nil, nil, nil, body_606868)

var updateApplication* = Call_UpdateApplication_606854(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateApplication",
    validator: validate_UpdateApplication_606855, base: "/",
    url: url_UpdateApplication_606856, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentGroup_606869 = ref object of OpenApiRestCall_605589
proc url_UpdateDeploymentGroup_606871(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDeploymentGroup_606870(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes information about a deployment group.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_606872 = header.getOrDefault("X-Amz-Target")
  valid_606872 = validateParameter(valid_606872, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateDeploymentGroup"))
  if valid_606872 != nil:
    section.add "X-Amz-Target", valid_606872
  var valid_606873 = header.getOrDefault("X-Amz-Signature")
  valid_606873 = validateParameter(valid_606873, JString, required = false,
                                 default = nil)
  if valid_606873 != nil:
    section.add "X-Amz-Signature", valid_606873
  var valid_606874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606874 = validateParameter(valid_606874, JString, required = false,
                                 default = nil)
  if valid_606874 != nil:
    section.add "X-Amz-Content-Sha256", valid_606874
  var valid_606875 = header.getOrDefault("X-Amz-Date")
  valid_606875 = validateParameter(valid_606875, JString, required = false,
                                 default = nil)
  if valid_606875 != nil:
    section.add "X-Amz-Date", valid_606875
  var valid_606876 = header.getOrDefault("X-Amz-Credential")
  valid_606876 = validateParameter(valid_606876, JString, required = false,
                                 default = nil)
  if valid_606876 != nil:
    section.add "X-Amz-Credential", valid_606876
  var valid_606877 = header.getOrDefault("X-Amz-Security-Token")
  valid_606877 = validateParameter(valid_606877, JString, required = false,
                                 default = nil)
  if valid_606877 != nil:
    section.add "X-Amz-Security-Token", valid_606877
  var valid_606878 = header.getOrDefault("X-Amz-Algorithm")
  valid_606878 = validateParameter(valid_606878, JString, required = false,
                                 default = nil)
  if valid_606878 != nil:
    section.add "X-Amz-Algorithm", valid_606878
  var valid_606879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606879 = validateParameter(valid_606879, JString, required = false,
                                 default = nil)
  if valid_606879 != nil:
    section.add "X-Amz-SignedHeaders", valid_606879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606881: Call_UpdateDeploymentGroup_606869; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a deployment group.
  ## 
  let valid = call_606881.validator(path, query, header, formData, body)
  let scheme = call_606881.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606881.url(scheme.get, call_606881.host, call_606881.base,
                         call_606881.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606881, url, valid)

proc call*(call_606882: Call_UpdateDeploymentGroup_606869; body: JsonNode): Recallable =
  ## updateDeploymentGroup
  ## Changes information about a deployment group.
  ##   body: JObject (required)
  var body_606883 = newJObject()
  if body != nil:
    body_606883 = body
  result = call_606882.call(nil, nil, nil, nil, body_606883)

var updateDeploymentGroup* = Call_UpdateDeploymentGroup_606869(
    name: "updateDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateDeploymentGroup",
    validator: validate_UpdateDeploymentGroup_606870, base: "/",
    url: url_UpdateDeploymentGroup_606871, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

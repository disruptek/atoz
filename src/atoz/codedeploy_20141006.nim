
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode): string

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddTagsToOnPremisesInstances_600768 = ref object of OpenApiRestCall_600426
proc url_AddTagsToOnPremisesInstances_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTagsToOnPremisesInstances_600769(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600882 = header.getOrDefault("X-Amz-Date")
  valid_600882 = validateParameter(valid_600882, JString, required = false,
                                 default = nil)
  if valid_600882 != nil:
    section.add "X-Amz-Date", valid_600882
  var valid_600883 = header.getOrDefault("X-Amz-Security-Token")
  valid_600883 = validateParameter(valid_600883, JString, required = false,
                                 default = nil)
  if valid_600883 != nil:
    section.add "X-Amz-Security-Token", valid_600883
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_600897 = header.getOrDefault("X-Amz-Target")
  valid_600897 = validateParameter(valid_600897, JString, required = true, default = newJString(
      "CodeDeploy_20141006.AddTagsToOnPremisesInstances"))
  if valid_600897 != nil:
    section.add "X-Amz-Target", valid_600897
  var valid_600898 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Content-Sha256", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Algorithm")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Algorithm", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Signature")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Signature", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-SignedHeaders", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Credential")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Credential", valid_600902
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600926: Call_AddTagsToOnPremisesInstances_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to on-premises instances.
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AddTagsToOnPremisesInstances_600768; body: JsonNode): Recallable =
  ## addTagsToOnPremisesInstances
  ## Adds tags to on-premises instances.
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var addTagsToOnPremisesInstances* = Call_AddTagsToOnPremisesInstances_600768(
    name: "addTagsToOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.AddTagsToOnPremisesInstances",
    validator: validate_AddTagsToOnPremisesInstances_600769, base: "/",
    url: url_AddTagsToOnPremisesInstances_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplicationRevisions_601037 = ref object of OpenApiRestCall_600426
proc url_BatchGetApplicationRevisions_601039(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetApplicationRevisions_601038(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601040 = header.getOrDefault("X-Amz-Date")
  valid_601040 = validateParameter(valid_601040, JString, required = false,
                                 default = nil)
  if valid_601040 != nil:
    section.add "X-Amz-Date", valid_601040
  var valid_601041 = header.getOrDefault("X-Amz-Security-Token")
  valid_601041 = validateParameter(valid_601041, JString, required = false,
                                 default = nil)
  if valid_601041 != nil:
    section.add "X-Amz-Security-Token", valid_601041
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601042 = header.getOrDefault("X-Amz-Target")
  valid_601042 = validateParameter(valid_601042, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplicationRevisions"))
  if valid_601042 != nil:
    section.add "X-Amz-Target", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Content-Sha256", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Algorithm")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Algorithm", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Signature")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Signature", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-SignedHeaders", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Credential")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Credential", valid_601047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601049: Call_BatchGetApplicationRevisions_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_BatchGetApplicationRevisions_601037; body: JsonNode): Recallable =
  ## batchGetApplicationRevisions
  ## Gets information about one or more application revisions. The maximum number of application revisions that can be returned is 25.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var batchGetApplicationRevisions* = Call_BatchGetApplicationRevisions_601037(
    name: "batchGetApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplicationRevisions",
    validator: validate_BatchGetApplicationRevisions_601038, base: "/",
    url: url_BatchGetApplicationRevisions_601039,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetApplications_601052 = ref object of OpenApiRestCall_600426
proc url_BatchGetApplications_601054(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetApplications_601053(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601055 = header.getOrDefault("X-Amz-Date")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Date", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Security-Token")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Security-Token", valid_601056
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601057 = header.getOrDefault("X-Amz-Target")
  valid_601057 = validateParameter(valid_601057, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetApplications"))
  if valid_601057 != nil:
    section.add "X-Amz-Target", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Content-Sha256", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-Algorithm")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-Algorithm", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Signature")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Signature", valid_601060
  var valid_601061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "X-Amz-SignedHeaders", valid_601061
  var valid_601062 = header.getOrDefault("X-Amz-Credential")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "X-Amz-Credential", valid_601062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601064: Call_BatchGetApplications_601052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_BatchGetApplications_601052; body: JsonNode): Recallable =
  ## batchGetApplications
  ## Gets information about one or more applications. The maximum number of applications that can be returned is 25.
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var batchGetApplications* = Call_BatchGetApplications_601052(
    name: "batchGetApplications", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetApplications",
    validator: validate_BatchGetApplications_601053, base: "/",
    url: url_BatchGetApplications_601054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentGroups_601067 = ref object of OpenApiRestCall_600426
proc url_BatchGetDeploymentGroups_601069(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetDeploymentGroups_601068(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601070 = header.getOrDefault("X-Amz-Date")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Date", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Security-Token")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Security-Token", valid_601071
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601072 = header.getOrDefault("X-Amz-Target")
  valid_601072 = validateParameter(valid_601072, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentGroups"))
  if valid_601072 != nil:
    section.add "X-Amz-Target", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-Content-Sha256", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Algorithm")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Algorithm", valid_601074
  var valid_601075 = header.getOrDefault("X-Amz-Signature")
  valid_601075 = validateParameter(valid_601075, JString, required = false,
                                 default = nil)
  if valid_601075 != nil:
    section.add "X-Amz-Signature", valid_601075
  var valid_601076 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601076 = validateParameter(valid_601076, JString, required = false,
                                 default = nil)
  if valid_601076 != nil:
    section.add "X-Amz-SignedHeaders", valid_601076
  var valid_601077 = header.getOrDefault("X-Amz-Credential")
  valid_601077 = validateParameter(valid_601077, JString, required = false,
                                 default = nil)
  if valid_601077 != nil:
    section.add "X-Amz-Credential", valid_601077
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601079: Call_BatchGetDeploymentGroups_601067; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployment groups.
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_BatchGetDeploymentGroups_601067; body: JsonNode): Recallable =
  ## batchGetDeploymentGroups
  ## Gets information about one or more deployment groups.
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var batchGetDeploymentGroups* = Call_BatchGetDeploymentGroups_601067(
    name: "batchGetDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentGroups",
    validator: validate_BatchGetDeploymentGroups_601068, base: "/",
    url: url_BatchGetDeploymentGroups_601069, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentInstances_601082 = ref object of OpenApiRestCall_600426
proc url_BatchGetDeploymentInstances_601084(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetDeploymentInstances_601083(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601085 = header.getOrDefault("X-Amz-Date")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Date", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Security-Token")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Security-Token", valid_601086
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601087 = header.getOrDefault("X-Amz-Target")
  valid_601087 = validateParameter(valid_601087, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentInstances"))
  if valid_601087 != nil:
    section.add "X-Amz-Target", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Content-Sha256", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Algorithm")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Algorithm", valid_601089
  var valid_601090 = header.getOrDefault("X-Amz-Signature")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "X-Amz-Signature", valid_601090
  var valid_601091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "X-Amz-SignedHeaders", valid_601091
  var valid_601092 = header.getOrDefault("X-Amz-Credential")
  valid_601092 = validateParameter(valid_601092, JString, required = false,
                                 default = nil)
  if valid_601092 != nil:
    section.add "X-Amz-Credential", valid_601092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601094: Call_BatchGetDeploymentInstances_601082; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_BatchGetDeploymentInstances_601082; body: JsonNode): Recallable =
  ## batchGetDeploymentInstances
  ## <note> <p> This method works, but is deprecated. Use <code>BatchGetDeploymentTargets</code> instead. </p> </note> <p> Returns an array of one or more instances associated with a deployment. This method works with EC2/On-premises and AWS Lambda compute platforms. The newer <code>BatchGetDeploymentTargets</code> works with all compute platforms. The maximum number of instances that can be returned is 25.</p>
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var batchGetDeploymentInstances* = Call_BatchGetDeploymentInstances_601082(
    name: "batchGetDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentInstances",
    validator: validate_BatchGetDeploymentInstances_601083, base: "/",
    url: url_BatchGetDeploymentInstances_601084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeploymentTargets_601097 = ref object of OpenApiRestCall_600426
proc url_BatchGetDeploymentTargets_601099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetDeploymentTargets_601098(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601100 = header.getOrDefault("X-Amz-Date")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Date", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-Security-Token")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-Security-Token", valid_601101
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601102 = header.getOrDefault("X-Amz-Target")
  valid_601102 = validateParameter(valid_601102, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeploymentTargets"))
  if valid_601102 != nil:
    section.add "X-Amz-Target", valid_601102
  var valid_601103 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601103 = validateParameter(valid_601103, JString, required = false,
                                 default = nil)
  if valid_601103 != nil:
    section.add "X-Amz-Content-Sha256", valid_601103
  var valid_601104 = header.getOrDefault("X-Amz-Algorithm")
  valid_601104 = validateParameter(valid_601104, JString, required = false,
                                 default = nil)
  if valid_601104 != nil:
    section.add "X-Amz-Algorithm", valid_601104
  var valid_601105 = header.getOrDefault("X-Amz-Signature")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "X-Amz-Signature", valid_601105
  var valid_601106 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "X-Amz-SignedHeaders", valid_601106
  var valid_601107 = header.getOrDefault("X-Amz-Credential")
  valid_601107 = validateParameter(valid_601107, JString, required = false,
                                 default = nil)
  if valid_601107 != nil:
    section.add "X-Amz-Credential", valid_601107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601109: Call_BatchGetDeploymentTargets_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_BatchGetDeploymentTargets_601097; body: JsonNode): Recallable =
  ## batchGetDeploymentTargets
  ## <p> Returns an array of one or more targets associated with a deployment. This method works with all compute types and should be used instead of the deprecated <code>BatchGetDeploymentInstances</code>. The maximum number of targets that can be returned is 25.</p> <p> The type of targets returned depends on the deployment's compute platform: </p> <ul> <li> <p> <b>EC2/On-premises</b>: Information about EC2 instance targets. </p> </li> <li> <p> <b>AWS Lambda</b>: Information about Lambda functions targets. </p> </li> <li> <p> <b>Amazon ECS</b>: Information about Amazon ECS service targets. </p> </li> </ul>
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var batchGetDeploymentTargets* = Call_BatchGetDeploymentTargets_601097(
    name: "batchGetDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeploymentTargets",
    validator: validate_BatchGetDeploymentTargets_601098, base: "/",
    url: url_BatchGetDeploymentTargets_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetDeployments_601112 = ref object of OpenApiRestCall_600426
proc url_BatchGetDeployments_601114(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetDeployments_601113(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601115 = header.getOrDefault("X-Amz-Date")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Date", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Security-Token")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Security-Token", valid_601116
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601117 = header.getOrDefault("X-Amz-Target")
  valid_601117 = validateParameter(valid_601117, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetDeployments"))
  if valid_601117 != nil:
    section.add "X-Amz-Target", valid_601117
  var valid_601118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601118 = validateParameter(valid_601118, JString, required = false,
                                 default = nil)
  if valid_601118 != nil:
    section.add "X-Amz-Content-Sha256", valid_601118
  var valid_601119 = header.getOrDefault("X-Amz-Algorithm")
  valid_601119 = validateParameter(valid_601119, JString, required = false,
                                 default = nil)
  if valid_601119 != nil:
    section.add "X-Amz-Algorithm", valid_601119
  var valid_601120 = header.getOrDefault("X-Amz-Signature")
  valid_601120 = validateParameter(valid_601120, JString, required = false,
                                 default = nil)
  if valid_601120 != nil:
    section.add "X-Amz-Signature", valid_601120
  var valid_601121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601121 = validateParameter(valid_601121, JString, required = false,
                                 default = nil)
  if valid_601121 != nil:
    section.add "X-Amz-SignedHeaders", valid_601121
  var valid_601122 = header.getOrDefault("X-Amz-Credential")
  valid_601122 = validateParameter(valid_601122, JString, required = false,
                                 default = nil)
  if valid_601122 != nil:
    section.add "X-Amz-Credential", valid_601122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601124: Call_BatchGetDeployments_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_BatchGetDeployments_601112; body: JsonNode): Recallable =
  ## batchGetDeployments
  ## Gets information about one or more deployments. The maximum number of deployments that can be returned is 25.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var batchGetDeployments* = Call_BatchGetDeployments_601112(
    name: "batchGetDeployments", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetDeployments",
    validator: validate_BatchGetDeployments_601113, base: "/",
    url: url_BatchGetDeployments_601114, schemes: {Scheme.Https, Scheme.Http})
type
  Call_BatchGetOnPremisesInstances_601127 = ref object of OpenApiRestCall_600426
proc url_BatchGetOnPremisesInstances_601129(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchGetOnPremisesInstances_601128(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601130 = header.getOrDefault("X-Amz-Date")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Date", valid_601130
  var valid_601131 = header.getOrDefault("X-Amz-Security-Token")
  valid_601131 = validateParameter(valid_601131, JString, required = false,
                                 default = nil)
  if valid_601131 != nil:
    section.add "X-Amz-Security-Token", valid_601131
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601132 = header.getOrDefault("X-Amz-Target")
  valid_601132 = validateParameter(valid_601132, JString, required = true, default = newJString(
      "CodeDeploy_20141006.BatchGetOnPremisesInstances"))
  if valid_601132 != nil:
    section.add "X-Amz-Target", valid_601132
  var valid_601133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "X-Amz-Content-Sha256", valid_601133
  var valid_601134 = header.getOrDefault("X-Amz-Algorithm")
  valid_601134 = validateParameter(valid_601134, JString, required = false,
                                 default = nil)
  if valid_601134 != nil:
    section.add "X-Amz-Algorithm", valid_601134
  var valid_601135 = header.getOrDefault("X-Amz-Signature")
  valid_601135 = validateParameter(valid_601135, JString, required = false,
                                 default = nil)
  if valid_601135 != nil:
    section.add "X-Amz-Signature", valid_601135
  var valid_601136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601136 = validateParameter(valid_601136, JString, required = false,
                                 default = nil)
  if valid_601136 != nil:
    section.add "X-Amz-SignedHeaders", valid_601136
  var valid_601137 = header.getOrDefault("X-Amz-Credential")
  valid_601137 = validateParameter(valid_601137, JString, required = false,
                                 default = nil)
  if valid_601137 != nil:
    section.add "X-Amz-Credential", valid_601137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601139: Call_BatchGetOnPremisesInstances_601127; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_BatchGetOnPremisesInstances_601127; body: JsonNode): Recallable =
  ## batchGetOnPremisesInstances
  ## Gets information about one or more on-premises instances. The maximum number of on-premises instances that can be returned is 25.
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var batchGetOnPremisesInstances* = Call_BatchGetOnPremisesInstances_601127(
    name: "batchGetOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.BatchGetOnPremisesInstances",
    validator: validate_BatchGetOnPremisesInstances_601128, base: "/",
    url: url_BatchGetOnPremisesInstances_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ContinueDeployment_601142 = ref object of OpenApiRestCall_600426
proc url_ContinueDeployment_601144(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ContinueDeployment_601143(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601145 = header.getOrDefault("X-Amz-Date")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Date", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Security-Token")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Security-Token", valid_601146
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601147 = header.getOrDefault("X-Amz-Target")
  valid_601147 = validateParameter(valid_601147, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ContinueDeployment"))
  if valid_601147 != nil:
    section.add "X-Amz-Target", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Content-Sha256", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-Algorithm")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-Algorithm", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Signature")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Signature", valid_601150
  var valid_601151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601151 = validateParameter(valid_601151, JString, required = false,
                                 default = nil)
  if valid_601151 != nil:
    section.add "X-Amz-SignedHeaders", valid_601151
  var valid_601152 = header.getOrDefault("X-Amz-Credential")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Credential", valid_601152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601154: Call_ContinueDeployment_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_ContinueDeployment_601142; body: JsonNode): Recallable =
  ## continueDeployment
  ## For a blue/green deployment, starts the process of rerouting traffic from instances in the original environment to instances in the replacement environment without waiting for a specified wait time to elapse. (Traffic rerouting, which is achieved by registering instances in the replacement environment with the load balancer, can start as soon as all instances have a status of Ready.) 
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var continueDeployment* = Call_ContinueDeployment_601142(
    name: "continueDeployment", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ContinueDeployment",
    validator: validate_ContinueDeployment_601143, base: "/",
    url: url_ContinueDeployment_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateApplication_601157 = ref object of OpenApiRestCall_600426
proc url_CreateApplication_601159(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateApplication_601158(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601160 = header.getOrDefault("X-Amz-Date")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Date", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Security-Token")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Security-Token", valid_601161
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601162 = header.getOrDefault("X-Amz-Target")
  valid_601162 = validateParameter(valid_601162, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateApplication"))
  if valid_601162 != nil:
    section.add "X-Amz-Target", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Content-Sha256", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-Algorithm")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-Algorithm", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Signature")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Signature", valid_601165
  var valid_601166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-SignedHeaders", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Credential")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Credential", valid_601167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601169: Call_CreateApplication_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an application.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_CreateApplication_601157; body: JsonNode): Recallable =
  ## createApplication
  ## Creates an application.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var createApplication* = Call_CreateApplication_601157(name: "createApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateApplication",
    validator: validate_CreateApplication_601158, base: "/",
    url: url_CreateApplication_601159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeployment_601172 = ref object of OpenApiRestCall_600426
proc url_CreateDeployment_601174(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeployment_601173(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601175 = header.getOrDefault("X-Amz-Date")
  valid_601175 = validateParameter(valid_601175, JString, required = false,
                                 default = nil)
  if valid_601175 != nil:
    section.add "X-Amz-Date", valid_601175
  var valid_601176 = header.getOrDefault("X-Amz-Security-Token")
  valid_601176 = validateParameter(valid_601176, JString, required = false,
                                 default = nil)
  if valid_601176 != nil:
    section.add "X-Amz-Security-Token", valid_601176
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601177 = header.getOrDefault("X-Amz-Target")
  valid_601177 = validateParameter(valid_601177, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeployment"))
  if valid_601177 != nil:
    section.add "X-Amz-Target", valid_601177
  var valid_601178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Content-Sha256", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Algorithm")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Algorithm", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Signature")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Signature", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-SignedHeaders", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Credential")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Credential", valid_601182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601184: Call_CreateDeployment_601172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deploys an application revision through the specified deployment group.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_CreateDeployment_601172; body: JsonNode): Recallable =
  ## createDeployment
  ## Deploys an application revision through the specified deployment group.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var createDeployment* = Call_CreateDeployment_601172(name: "createDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeployment",
    validator: validate_CreateDeployment_601173, base: "/",
    url: url_CreateDeployment_601174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentConfig_601187 = ref object of OpenApiRestCall_600426
proc url_CreateDeploymentConfig_601189(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeploymentConfig_601188(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601190 = header.getOrDefault("X-Amz-Date")
  valid_601190 = validateParameter(valid_601190, JString, required = false,
                                 default = nil)
  if valid_601190 != nil:
    section.add "X-Amz-Date", valid_601190
  var valid_601191 = header.getOrDefault("X-Amz-Security-Token")
  valid_601191 = validateParameter(valid_601191, JString, required = false,
                                 default = nil)
  if valid_601191 != nil:
    section.add "X-Amz-Security-Token", valid_601191
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601192 = header.getOrDefault("X-Amz-Target")
  valid_601192 = validateParameter(valid_601192, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentConfig"))
  if valid_601192 != nil:
    section.add "X-Amz-Target", valid_601192
  var valid_601193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Content-Sha256", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Algorithm")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Algorithm", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Signature")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Signature", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-SignedHeaders", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Credential")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Credential", valid_601197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601199: Call_CreateDeploymentConfig_601187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Creates a deployment configuration. 
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_CreateDeploymentConfig_601187; body: JsonNode): Recallable =
  ## createDeploymentConfig
  ##  Creates a deployment configuration. 
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var createDeploymentConfig* = Call_CreateDeploymentConfig_601187(
    name: "createDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentConfig",
    validator: validate_CreateDeploymentConfig_601188, base: "/",
    url: url_CreateDeploymentConfig_601189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentGroup_601202 = ref object of OpenApiRestCall_600426
proc url_CreateDeploymentGroup_601204(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeploymentGroup_601203(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601205 = header.getOrDefault("X-Amz-Date")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "X-Amz-Date", valid_601205
  var valid_601206 = header.getOrDefault("X-Amz-Security-Token")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Security-Token", valid_601206
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601207 = header.getOrDefault("X-Amz-Target")
  valid_601207 = validateParameter(valid_601207, JString, required = true, default = newJString(
      "CodeDeploy_20141006.CreateDeploymentGroup"))
  if valid_601207 != nil:
    section.add "X-Amz-Target", valid_601207
  var valid_601208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Content-Sha256", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Algorithm")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Algorithm", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Signature")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Signature", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-SignedHeaders", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Credential")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Credential", valid_601212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601214: Call_CreateDeploymentGroup_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a deployment group to which application revisions are deployed.
  ## 
  let valid = call_601214.validator(path, query, header, formData, body)
  let scheme = call_601214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601214.url(scheme.get, call_601214.host, call_601214.base,
                         call_601214.route, valid.getOrDefault("path"))
  result = hook(call_601214, url, valid)

proc call*(call_601215: Call_CreateDeploymentGroup_601202; body: JsonNode): Recallable =
  ## createDeploymentGroup
  ## Creates a deployment group to which application revisions are deployed.
  ##   body: JObject (required)
  var body_601216 = newJObject()
  if body != nil:
    body_601216 = body
  result = call_601215.call(nil, nil, nil, nil, body_601216)

var createDeploymentGroup* = Call_CreateDeploymentGroup_601202(
    name: "createDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.CreateDeploymentGroup",
    validator: validate_CreateDeploymentGroup_601203, base: "/",
    url: url_CreateDeploymentGroup_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteApplication_601217 = ref object of OpenApiRestCall_600426
proc url_DeleteApplication_601219(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteApplication_601218(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601220 = header.getOrDefault("X-Amz-Date")
  valid_601220 = validateParameter(valid_601220, JString, required = false,
                                 default = nil)
  if valid_601220 != nil:
    section.add "X-Amz-Date", valid_601220
  var valid_601221 = header.getOrDefault("X-Amz-Security-Token")
  valid_601221 = validateParameter(valid_601221, JString, required = false,
                                 default = nil)
  if valid_601221 != nil:
    section.add "X-Amz-Security-Token", valid_601221
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601222 = header.getOrDefault("X-Amz-Target")
  valid_601222 = validateParameter(valid_601222, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteApplication"))
  if valid_601222 != nil:
    section.add "X-Amz-Target", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Content-Sha256", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Algorithm")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Algorithm", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Signature")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Signature", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-SignedHeaders", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Credential")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Credential", valid_601227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601229: Call_DeleteApplication_601217; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an application.
  ## 
  let valid = call_601229.validator(path, query, header, formData, body)
  let scheme = call_601229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601229.url(scheme.get, call_601229.host, call_601229.base,
                         call_601229.route, valid.getOrDefault("path"))
  result = hook(call_601229, url, valid)

proc call*(call_601230: Call_DeleteApplication_601217; body: JsonNode): Recallable =
  ## deleteApplication
  ## Deletes an application.
  ##   body: JObject (required)
  var body_601231 = newJObject()
  if body != nil:
    body_601231 = body
  result = call_601230.call(nil, nil, nil, nil, body_601231)

var deleteApplication* = Call_DeleteApplication_601217(name: "deleteApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteApplication",
    validator: validate_DeleteApplication_601218, base: "/",
    url: url_DeleteApplication_601219, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentConfig_601232 = ref object of OpenApiRestCall_600426
proc url_DeleteDeploymentConfig_601234(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDeploymentConfig_601233(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601235 = header.getOrDefault("X-Amz-Date")
  valid_601235 = validateParameter(valid_601235, JString, required = false,
                                 default = nil)
  if valid_601235 != nil:
    section.add "X-Amz-Date", valid_601235
  var valid_601236 = header.getOrDefault("X-Amz-Security-Token")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Security-Token", valid_601236
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601237 = header.getOrDefault("X-Amz-Target")
  valid_601237 = validateParameter(valid_601237, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentConfig"))
  if valid_601237 != nil:
    section.add "X-Amz-Target", valid_601237
  var valid_601238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601238 = validateParameter(valid_601238, JString, required = false,
                                 default = nil)
  if valid_601238 != nil:
    section.add "X-Amz-Content-Sha256", valid_601238
  var valid_601239 = header.getOrDefault("X-Amz-Algorithm")
  valid_601239 = validateParameter(valid_601239, JString, required = false,
                                 default = nil)
  if valid_601239 != nil:
    section.add "X-Amz-Algorithm", valid_601239
  var valid_601240 = header.getOrDefault("X-Amz-Signature")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "X-Amz-Signature", valid_601240
  var valid_601241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-SignedHeaders", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Credential")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Credential", valid_601242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601244: Call_DeleteDeploymentConfig_601232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DeleteDeploymentConfig_601232; body: JsonNode): Recallable =
  ## deleteDeploymentConfig
  ## <p>Deletes a deployment configuration.</p> <note> <p>A deployment configuration cannot be deleted if it is currently in use. Predefined configurations cannot be deleted.</p> </note>
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var deleteDeploymentConfig* = Call_DeleteDeploymentConfig_601232(
    name: "deleteDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentConfig",
    validator: validate_DeleteDeploymentConfig_601233, base: "/",
    url: url_DeleteDeploymentConfig_601234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDeploymentGroup_601247 = ref object of OpenApiRestCall_600426
proc url_DeleteDeploymentGroup_601249(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteDeploymentGroup_601248(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601250 = header.getOrDefault("X-Amz-Date")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Date", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Security-Token")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Security-Token", valid_601251
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601252 = header.getOrDefault("X-Amz-Target")
  valid_601252 = validateParameter(valid_601252, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteDeploymentGroup"))
  if valid_601252 != nil:
    section.add "X-Amz-Target", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Content-Sha256", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Algorithm")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Algorithm", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-Signature")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-Signature", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-SignedHeaders", valid_601256
  var valid_601257 = header.getOrDefault("X-Amz-Credential")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "X-Amz-Credential", valid_601257
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601259: Call_DeleteDeploymentGroup_601247; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a deployment group.
  ## 
  let valid = call_601259.validator(path, query, header, formData, body)
  let scheme = call_601259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601259.url(scheme.get, call_601259.host, call_601259.base,
                         call_601259.route, valid.getOrDefault("path"))
  result = hook(call_601259, url, valid)

proc call*(call_601260: Call_DeleteDeploymentGroup_601247; body: JsonNode): Recallable =
  ## deleteDeploymentGroup
  ## Deletes a deployment group.
  ##   body: JObject (required)
  var body_601261 = newJObject()
  if body != nil:
    body_601261 = body
  result = call_601260.call(nil, nil, nil, nil, body_601261)

var deleteDeploymentGroup* = Call_DeleteDeploymentGroup_601247(
    name: "deleteDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteDeploymentGroup",
    validator: validate_DeleteDeploymentGroup_601248, base: "/",
    url: url_DeleteDeploymentGroup_601249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGitHubAccountToken_601262 = ref object of OpenApiRestCall_600426
proc url_DeleteGitHubAccountToken_601264(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteGitHubAccountToken_601263(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601265 = header.getOrDefault("X-Amz-Date")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Date", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Security-Token")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Security-Token", valid_601266
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601267 = header.getOrDefault("X-Amz-Target")
  valid_601267 = validateParameter(valid_601267, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeleteGitHubAccountToken"))
  if valid_601267 != nil:
    section.add "X-Amz-Target", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Content-Sha256", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-Algorithm")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-Algorithm", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Signature")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Signature", valid_601270
  var valid_601271 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601271 = validateParameter(valid_601271, JString, required = false,
                                 default = nil)
  if valid_601271 != nil:
    section.add "X-Amz-SignedHeaders", valid_601271
  var valid_601272 = header.getOrDefault("X-Amz-Credential")
  valid_601272 = validateParameter(valid_601272, JString, required = false,
                                 default = nil)
  if valid_601272 != nil:
    section.add "X-Amz-Credential", valid_601272
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601274: Call_DeleteGitHubAccountToken_601262; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a GitHub account connection.
  ## 
  let valid = call_601274.validator(path, query, header, formData, body)
  let scheme = call_601274.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601274.url(scheme.get, call_601274.host, call_601274.base,
                         call_601274.route, valid.getOrDefault("path"))
  result = hook(call_601274, url, valid)

proc call*(call_601275: Call_DeleteGitHubAccountToken_601262; body: JsonNode): Recallable =
  ## deleteGitHubAccountToken
  ## Deletes a GitHub account connection.
  ##   body: JObject (required)
  var body_601276 = newJObject()
  if body != nil:
    body_601276 = body
  result = call_601275.call(nil, nil, nil, nil, body_601276)

var deleteGitHubAccountToken* = Call_DeleteGitHubAccountToken_601262(
    name: "deleteGitHubAccountToken", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeleteGitHubAccountToken",
    validator: validate_DeleteGitHubAccountToken_601263, base: "/",
    url: url_DeleteGitHubAccountToken_601264, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterOnPremisesInstance_601277 = ref object of OpenApiRestCall_600426
proc url_DeregisterOnPremisesInstance_601279(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterOnPremisesInstance_601278(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601282 = header.getOrDefault("X-Amz-Target")
  valid_601282 = validateParameter(valid_601282, JString, required = true, default = newJString(
      "CodeDeploy_20141006.DeregisterOnPremisesInstance"))
  if valid_601282 != nil:
    section.add "X-Amz-Target", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Content-Sha256", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Algorithm")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Algorithm", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-Signature")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-Signature", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-SignedHeaders", valid_601286
  var valid_601287 = header.getOrDefault("X-Amz-Credential")
  valid_601287 = validateParameter(valid_601287, JString, required = false,
                                 default = nil)
  if valid_601287 != nil:
    section.add "X-Amz-Credential", valid_601287
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601289: Call_DeregisterOnPremisesInstance_601277; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters an on-premises instance.
  ## 
  let valid = call_601289.validator(path, query, header, formData, body)
  let scheme = call_601289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601289.url(scheme.get, call_601289.host, call_601289.base,
                         call_601289.route, valid.getOrDefault("path"))
  result = hook(call_601289, url, valid)

proc call*(call_601290: Call_DeregisterOnPremisesInstance_601277; body: JsonNode): Recallable =
  ## deregisterOnPremisesInstance
  ## Deregisters an on-premises instance.
  ##   body: JObject (required)
  var body_601291 = newJObject()
  if body != nil:
    body_601291 = body
  result = call_601290.call(nil, nil, nil, nil, body_601291)

var deregisterOnPremisesInstance* = Call_DeregisterOnPremisesInstance_601277(
    name: "deregisterOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.DeregisterOnPremisesInstance",
    validator: validate_DeregisterOnPremisesInstance_601278, base: "/",
    url: url_DeregisterOnPremisesInstance_601279,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplication_601292 = ref object of OpenApiRestCall_600426
proc url_GetApplication_601294(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplication_601293(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601297 = header.getOrDefault("X-Amz-Target")
  valid_601297 = validateParameter(valid_601297, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplication"))
  if valid_601297 != nil:
    section.add "X-Amz-Target", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Content-Sha256", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Algorithm")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Algorithm", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-Signature")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-Signature", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-SignedHeaders", valid_601301
  var valid_601302 = header.getOrDefault("X-Amz-Credential")
  valid_601302 = validateParameter(valid_601302, JString, required = false,
                                 default = nil)
  if valid_601302 != nil:
    section.add "X-Amz-Credential", valid_601302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601304: Call_GetApplication_601292; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application.
  ## 
  let valid = call_601304.validator(path, query, header, formData, body)
  let scheme = call_601304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601304.url(scheme.get, call_601304.host, call_601304.base,
                         call_601304.route, valid.getOrDefault("path"))
  result = hook(call_601304, url, valid)

proc call*(call_601305: Call_GetApplication_601292; body: JsonNode): Recallable =
  ## getApplication
  ## Gets information about an application.
  ##   body: JObject (required)
  var body_601306 = newJObject()
  if body != nil:
    body_601306 = body
  result = call_601305.call(nil, nil, nil, nil, body_601306)

var getApplication* = Call_GetApplication_601292(name: "getApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplication",
    validator: validate_GetApplication_601293, base: "/", url: url_GetApplication_601294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetApplicationRevision_601307 = ref object of OpenApiRestCall_600426
proc url_GetApplicationRevision_601309(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetApplicationRevision_601308(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601310 = header.getOrDefault("X-Amz-Date")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Date", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-Security-Token")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-Security-Token", valid_601311
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601312 = header.getOrDefault("X-Amz-Target")
  valid_601312 = validateParameter(valid_601312, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetApplicationRevision"))
  if valid_601312 != nil:
    section.add "X-Amz-Target", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Content-Sha256", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Algorithm")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Algorithm", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Signature")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Signature", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-SignedHeaders", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Credential")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Credential", valid_601317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601319: Call_GetApplicationRevision_601307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an application revision.
  ## 
  let valid = call_601319.validator(path, query, header, formData, body)
  let scheme = call_601319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601319.url(scheme.get, call_601319.host, call_601319.base,
                         call_601319.route, valid.getOrDefault("path"))
  result = hook(call_601319, url, valid)

proc call*(call_601320: Call_GetApplicationRevision_601307; body: JsonNode): Recallable =
  ## getApplicationRevision
  ## Gets information about an application revision.
  ##   body: JObject (required)
  var body_601321 = newJObject()
  if body != nil:
    body_601321 = body
  result = call_601320.call(nil, nil, nil, nil, body_601321)

var getApplicationRevision* = Call_GetApplicationRevision_601307(
    name: "getApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetApplicationRevision",
    validator: validate_GetApplicationRevision_601308, base: "/",
    url: url_GetApplicationRevision_601309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployment_601322 = ref object of OpenApiRestCall_600426
proc url_GetDeployment_601324(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeployment_601323(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601325 = header.getOrDefault("X-Amz-Date")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Date", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Security-Token")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Security-Token", valid_601326
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601327 = header.getOrDefault("X-Amz-Target")
  valid_601327 = validateParameter(valid_601327, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeployment"))
  if valid_601327 != nil:
    section.add "X-Amz-Target", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Content-Sha256", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Algorithm")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Algorithm", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Signature")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Signature", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-SignedHeaders", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Credential")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Credential", valid_601332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601334: Call_GetDeployment_601322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_GetDeployment_601322; body: JsonNode): Recallable =
  ## getDeployment
  ## <p>Gets information about a deployment.</p> <note> <p> The <code>content</code> property of the <code>appSpecContent</code> object in the returned revision is always null. Use <code>GetApplicationRevision</code> and the <code>sha256</code> property of the returned <code>appSpecContent</code> object to get the content of the deployment’s AppSpec file. </p> </note>
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var getDeployment* = Call_GetDeployment_601322(name: "getDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeployment",
    validator: validate_GetDeployment_601323, base: "/", url: url_GetDeployment_601324,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentConfig_601337 = ref object of OpenApiRestCall_600426
proc url_GetDeploymentConfig_601339(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeploymentConfig_601338(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601340 = header.getOrDefault("X-Amz-Date")
  valid_601340 = validateParameter(valid_601340, JString, required = false,
                                 default = nil)
  if valid_601340 != nil:
    section.add "X-Amz-Date", valid_601340
  var valid_601341 = header.getOrDefault("X-Amz-Security-Token")
  valid_601341 = validateParameter(valid_601341, JString, required = false,
                                 default = nil)
  if valid_601341 != nil:
    section.add "X-Amz-Security-Token", valid_601341
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601342 = header.getOrDefault("X-Amz-Target")
  valid_601342 = validateParameter(valid_601342, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentConfig"))
  if valid_601342 != nil:
    section.add "X-Amz-Target", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Content-Sha256", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Algorithm")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Algorithm", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-Signature")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-Signature", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-SignedHeaders", valid_601346
  var valid_601347 = header.getOrDefault("X-Amz-Credential")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Credential", valid_601347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601349: Call_GetDeploymentConfig_601337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment configuration.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_GetDeploymentConfig_601337; body: JsonNode): Recallable =
  ## getDeploymentConfig
  ## Gets information about a deployment configuration.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var getDeploymentConfig* = Call_GetDeploymentConfig_601337(
    name: "getDeploymentConfig", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentConfig",
    validator: validate_GetDeploymentConfig_601338, base: "/",
    url: url_GetDeploymentConfig_601339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentGroup_601352 = ref object of OpenApiRestCall_600426
proc url_GetDeploymentGroup_601354(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeploymentGroup_601353(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601355 = header.getOrDefault("X-Amz-Date")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "X-Amz-Date", valid_601355
  var valid_601356 = header.getOrDefault("X-Amz-Security-Token")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "X-Amz-Security-Token", valid_601356
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601357 = header.getOrDefault("X-Amz-Target")
  valid_601357 = validateParameter(valid_601357, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentGroup"))
  if valid_601357 != nil:
    section.add "X-Amz-Target", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Content-Sha256", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Algorithm")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Algorithm", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Signature")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Signature", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-SignedHeaders", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-Credential")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Credential", valid_601362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601364: Call_GetDeploymentGroup_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about a deployment group.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_GetDeploymentGroup_601352; body: JsonNode): Recallable =
  ## getDeploymentGroup
  ## Gets information about a deployment group.
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var getDeploymentGroup* = Call_GetDeploymentGroup_601352(
    name: "getDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentGroup",
    validator: validate_GetDeploymentGroup_601353, base: "/",
    url: url_GetDeploymentGroup_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentInstance_601367 = ref object of OpenApiRestCall_600426
proc url_GetDeploymentInstance_601369(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeploymentInstance_601368(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601370 = header.getOrDefault("X-Amz-Date")
  valid_601370 = validateParameter(valid_601370, JString, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "X-Amz-Date", valid_601370
  var valid_601371 = header.getOrDefault("X-Amz-Security-Token")
  valid_601371 = validateParameter(valid_601371, JString, required = false,
                                 default = nil)
  if valid_601371 != nil:
    section.add "X-Amz-Security-Token", valid_601371
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601372 = header.getOrDefault("X-Amz-Target")
  valid_601372 = validateParameter(valid_601372, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentInstance"))
  if valid_601372 != nil:
    section.add "X-Amz-Target", valid_601372
  var valid_601373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "X-Amz-Content-Sha256", valid_601373
  var valid_601374 = header.getOrDefault("X-Amz-Algorithm")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Algorithm", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Signature")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Signature", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-SignedHeaders", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Credential")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Credential", valid_601377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601379: Call_GetDeploymentInstance_601367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about an instance as part of a deployment.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_GetDeploymentInstance_601367; body: JsonNode): Recallable =
  ## getDeploymentInstance
  ## Gets information about an instance as part of a deployment.
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var getDeploymentInstance* = Call_GetDeploymentInstance_601367(
    name: "getDeploymentInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentInstance",
    validator: validate_GetDeploymentInstance_601368, base: "/",
    url: url_GetDeploymentInstance_601369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeploymentTarget_601382 = ref object of OpenApiRestCall_600426
proc url_GetDeploymentTarget_601384(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeploymentTarget_601383(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601385 = header.getOrDefault("X-Amz-Date")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Date", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Security-Token")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Security-Token", valid_601386
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601387 = header.getOrDefault("X-Amz-Target")
  valid_601387 = validateParameter(valid_601387, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetDeploymentTarget"))
  if valid_601387 != nil:
    section.add "X-Amz-Target", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Content-Sha256", valid_601388
  var valid_601389 = header.getOrDefault("X-Amz-Algorithm")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "X-Amz-Algorithm", valid_601389
  var valid_601390 = header.getOrDefault("X-Amz-Signature")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "X-Amz-Signature", valid_601390
  var valid_601391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-SignedHeaders", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Credential")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Credential", valid_601392
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601394: Call_GetDeploymentTarget_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns information about a deployment target. 
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_GetDeploymentTarget_601382; body: JsonNode): Recallable =
  ## getDeploymentTarget
  ##  Returns information about a deployment target. 
  ##   body: JObject (required)
  var body_601396 = newJObject()
  if body != nil:
    body_601396 = body
  result = call_601395.call(nil, nil, nil, nil, body_601396)

var getDeploymentTarget* = Call_GetDeploymentTarget_601382(
    name: "getDeploymentTarget", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetDeploymentTarget",
    validator: validate_GetDeploymentTarget_601383, base: "/",
    url: url_GetDeploymentTarget_601384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOnPremisesInstance_601397 = ref object of OpenApiRestCall_600426
proc url_GetOnPremisesInstance_601399(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetOnPremisesInstance_601398(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601400 = header.getOrDefault("X-Amz-Date")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Date", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Security-Token")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Security-Token", valid_601401
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601402 = header.getOrDefault("X-Amz-Target")
  valid_601402 = validateParameter(valid_601402, JString, required = true, default = newJString(
      "CodeDeploy_20141006.GetOnPremisesInstance"))
  if valid_601402 != nil:
    section.add "X-Amz-Target", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Content-Sha256", valid_601403
  var valid_601404 = header.getOrDefault("X-Amz-Algorithm")
  valid_601404 = validateParameter(valid_601404, JString, required = false,
                                 default = nil)
  if valid_601404 != nil:
    section.add "X-Amz-Algorithm", valid_601404
  var valid_601405 = header.getOrDefault("X-Amz-Signature")
  valid_601405 = validateParameter(valid_601405, JString, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "X-Amz-Signature", valid_601405
  var valid_601406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "X-Amz-SignedHeaders", valid_601406
  var valid_601407 = header.getOrDefault("X-Amz-Credential")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "X-Amz-Credential", valid_601407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601409: Call_GetOnPremisesInstance_601397; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Gets information about an on-premises instance. 
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"))
  result = hook(call_601409, url, valid)

proc call*(call_601410: Call_GetOnPremisesInstance_601397; body: JsonNode): Recallable =
  ## getOnPremisesInstance
  ##  Gets information about an on-premises instance. 
  ##   body: JObject (required)
  var body_601411 = newJObject()
  if body != nil:
    body_601411 = body
  result = call_601410.call(nil, nil, nil, nil, body_601411)

var getOnPremisesInstance* = Call_GetOnPremisesInstance_601397(
    name: "getOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.GetOnPremisesInstance",
    validator: validate_GetOnPremisesInstance_601398, base: "/",
    url: url_GetOnPremisesInstance_601399, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplicationRevisions_601412 = ref object of OpenApiRestCall_600426
proc url_ListApplicationRevisions_601414(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApplicationRevisions_601413(path: JsonNode; query: JsonNode;
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
  var valid_601415 = query.getOrDefault("nextToken")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "nextToken", valid_601415
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
  var valid_601416 = header.getOrDefault("X-Amz-Date")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Date", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Security-Token")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Security-Token", valid_601417
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601418 = header.getOrDefault("X-Amz-Target")
  valid_601418 = validateParameter(valid_601418, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplicationRevisions"))
  if valid_601418 != nil:
    section.add "X-Amz-Target", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Content-Sha256", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Algorithm")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Algorithm", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-Signature")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-Signature", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-SignedHeaders", valid_601422
  var valid_601423 = header.getOrDefault("X-Amz-Credential")
  valid_601423 = validateParameter(valid_601423, JString, required = false,
                                 default = nil)
  if valid_601423 != nil:
    section.add "X-Amz-Credential", valid_601423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601425: Call_ListApplicationRevisions_601412; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists information about revisions for an application.
  ## 
  let valid = call_601425.validator(path, query, header, formData, body)
  let scheme = call_601425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601425.url(scheme.get, call_601425.host, call_601425.base,
                         call_601425.route, valid.getOrDefault("path"))
  result = hook(call_601425, url, valid)

proc call*(call_601426: Call_ListApplicationRevisions_601412; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplicationRevisions
  ## Lists information about revisions for an application.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601427 = newJObject()
  var body_601428 = newJObject()
  add(query_601427, "nextToken", newJString(nextToken))
  if body != nil:
    body_601428 = body
  result = call_601426.call(nil, query_601427, nil, nil, body_601428)

var listApplicationRevisions* = Call_ListApplicationRevisions_601412(
    name: "listApplicationRevisions", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplicationRevisions",
    validator: validate_ListApplicationRevisions_601413, base: "/",
    url: url_ListApplicationRevisions_601414, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListApplications_601430 = ref object of OpenApiRestCall_600426
proc url_ListApplications_601432(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListApplications_601431(path: JsonNode; query: JsonNode;
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
  var valid_601433 = query.getOrDefault("nextToken")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "nextToken", valid_601433
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
  var valid_601434 = header.getOrDefault("X-Amz-Date")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Date", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Security-Token")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Security-Token", valid_601435
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601436 = header.getOrDefault("X-Amz-Target")
  valid_601436 = validateParameter(valid_601436, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListApplications"))
  if valid_601436 != nil:
    section.add "X-Amz-Target", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Content-Sha256", valid_601437
  var valid_601438 = header.getOrDefault("X-Amz-Algorithm")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Algorithm", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Signature")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Signature", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-SignedHeaders", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Credential")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Credential", valid_601441
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601443: Call_ListApplications_601430; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the applications registered with the IAM user or AWS account.
  ## 
  let valid = call_601443.validator(path, query, header, formData, body)
  let scheme = call_601443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601443.url(scheme.get, call_601443.host, call_601443.base,
                         call_601443.route, valid.getOrDefault("path"))
  result = hook(call_601443, url, valid)

proc call*(call_601444: Call_ListApplications_601430; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listApplications
  ## Lists the applications registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601445 = newJObject()
  var body_601446 = newJObject()
  add(query_601445, "nextToken", newJString(nextToken))
  if body != nil:
    body_601446 = body
  result = call_601444.call(nil, query_601445, nil, nil, body_601446)

var listApplications* = Call_ListApplications_601430(name: "listApplications",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListApplications",
    validator: validate_ListApplications_601431, base: "/",
    url: url_ListApplications_601432, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentConfigs_601447 = ref object of OpenApiRestCall_600426
proc url_ListDeploymentConfigs_601449(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeploymentConfigs_601448(path: JsonNode; query: JsonNode;
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
  var valid_601450 = query.getOrDefault("nextToken")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "nextToken", valid_601450
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
  var valid_601451 = header.getOrDefault("X-Amz-Date")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Date", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Security-Token")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Security-Token", valid_601452
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601453 = header.getOrDefault("X-Amz-Target")
  valid_601453 = validateParameter(valid_601453, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentConfigs"))
  if valid_601453 != nil:
    section.add "X-Amz-Target", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-Content-Sha256", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Algorithm")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Algorithm", valid_601455
  var valid_601456 = header.getOrDefault("X-Amz-Signature")
  valid_601456 = validateParameter(valid_601456, JString, required = false,
                                 default = nil)
  if valid_601456 != nil:
    section.add "X-Amz-Signature", valid_601456
  var valid_601457 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601457 = validateParameter(valid_601457, JString, required = false,
                                 default = nil)
  if valid_601457 != nil:
    section.add "X-Amz-SignedHeaders", valid_601457
  var valid_601458 = header.getOrDefault("X-Amz-Credential")
  valid_601458 = validateParameter(valid_601458, JString, required = false,
                                 default = nil)
  if valid_601458 != nil:
    section.add "X-Amz-Credential", valid_601458
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601460: Call_ListDeploymentConfigs_601447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment configurations with the IAM user or AWS account.
  ## 
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_ListDeploymentConfigs_601447; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentConfigs
  ## Lists the deployment configurations with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601462 = newJObject()
  var body_601463 = newJObject()
  add(query_601462, "nextToken", newJString(nextToken))
  if body != nil:
    body_601463 = body
  result = call_601461.call(nil, query_601462, nil, nil, body_601463)

var listDeploymentConfigs* = Call_ListDeploymentConfigs_601447(
    name: "listDeploymentConfigs", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentConfigs",
    validator: validate_ListDeploymentConfigs_601448, base: "/",
    url: url_ListDeploymentConfigs_601449, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentGroups_601464 = ref object of OpenApiRestCall_600426
proc url_ListDeploymentGroups_601466(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeploymentGroups_601465(path: JsonNode; query: JsonNode;
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
  var valid_601467 = query.getOrDefault("nextToken")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "nextToken", valid_601467
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
  var valid_601468 = header.getOrDefault("X-Amz-Date")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Date", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Security-Token")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Security-Token", valid_601469
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601470 = header.getOrDefault("X-Amz-Target")
  valid_601470 = validateParameter(valid_601470, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentGroups"))
  if valid_601470 != nil:
    section.add "X-Amz-Target", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Content-Sha256", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-Algorithm")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-Algorithm", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Signature")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Signature", valid_601473
  var valid_601474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601474 = validateParameter(valid_601474, JString, required = false,
                                 default = nil)
  if valid_601474 != nil:
    section.add "X-Amz-SignedHeaders", valid_601474
  var valid_601475 = header.getOrDefault("X-Amz-Credential")
  valid_601475 = validateParameter(valid_601475, JString, required = false,
                                 default = nil)
  if valid_601475 != nil:
    section.add "X-Amz-Credential", valid_601475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601477: Call_ListDeploymentGroups_601464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_601477.validator(path, query, header, formData, body)
  let scheme = call_601477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601477.url(scheme.get, call_601477.host, call_601477.base,
                         call_601477.route, valid.getOrDefault("path"))
  result = hook(call_601477, url, valid)

proc call*(call_601478: Call_ListDeploymentGroups_601464; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentGroups
  ## Lists the deployment groups for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601479 = newJObject()
  var body_601480 = newJObject()
  add(query_601479, "nextToken", newJString(nextToken))
  if body != nil:
    body_601480 = body
  result = call_601478.call(nil, query_601479, nil, nil, body_601480)

var listDeploymentGroups* = Call_ListDeploymentGroups_601464(
    name: "listDeploymentGroups", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentGroups",
    validator: validate_ListDeploymentGroups_601465, base: "/",
    url: url_ListDeploymentGroups_601466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentInstances_601481 = ref object of OpenApiRestCall_600426
proc url_ListDeploymentInstances_601483(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeploymentInstances_601482(path: JsonNode; query: JsonNode;
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
  var valid_601484 = query.getOrDefault("nextToken")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "nextToken", valid_601484
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
  var valid_601485 = header.getOrDefault("X-Amz-Date")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Date", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Security-Token")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Security-Token", valid_601486
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601487 = header.getOrDefault("X-Amz-Target")
  valid_601487 = validateParameter(valid_601487, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentInstances"))
  if valid_601487 != nil:
    section.add "X-Amz-Target", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Content-Sha256", valid_601488
  var valid_601489 = header.getOrDefault("X-Amz-Algorithm")
  valid_601489 = validateParameter(valid_601489, JString, required = false,
                                 default = nil)
  if valid_601489 != nil:
    section.add "X-Amz-Algorithm", valid_601489
  var valid_601490 = header.getOrDefault("X-Amz-Signature")
  valid_601490 = validateParameter(valid_601490, JString, required = false,
                                 default = nil)
  if valid_601490 != nil:
    section.add "X-Amz-Signature", valid_601490
  var valid_601491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601491 = validateParameter(valid_601491, JString, required = false,
                                 default = nil)
  if valid_601491 != nil:
    section.add "X-Amz-SignedHeaders", valid_601491
  var valid_601492 = header.getOrDefault("X-Amz-Credential")
  valid_601492 = validateParameter(valid_601492, JString, required = false,
                                 default = nil)
  if valid_601492 != nil:
    section.add "X-Amz-Credential", valid_601492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601494: Call_ListDeploymentInstances_601481; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ## 
  let valid = call_601494.validator(path, query, header, formData, body)
  let scheme = call_601494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601494.url(scheme.get, call_601494.host, call_601494.base,
                         call_601494.route, valid.getOrDefault("path"))
  result = hook(call_601494, url, valid)

proc call*(call_601495: Call_ListDeploymentInstances_601481; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeploymentInstances
  ## <note> <p> The newer BatchGetDeploymentTargets should be used instead because it works with all compute types. <code>ListDeploymentInstances</code> throws an exception if it is used with a compute platform other than EC2/On-premises or AWS Lambda. </p> </note> <p> Lists the instance for a deployment associated with the IAM user or AWS account. </p>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601496 = newJObject()
  var body_601497 = newJObject()
  add(query_601496, "nextToken", newJString(nextToken))
  if body != nil:
    body_601497 = body
  result = call_601495.call(nil, query_601496, nil, nil, body_601497)

var listDeploymentInstances* = Call_ListDeploymentInstances_601481(
    name: "listDeploymentInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentInstances",
    validator: validate_ListDeploymentInstances_601482, base: "/",
    url: url_ListDeploymentInstances_601483, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentTargets_601498 = ref object of OpenApiRestCall_600426
proc url_ListDeploymentTargets_601500(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeploymentTargets_601499(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601501 = header.getOrDefault("X-Amz-Date")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Date", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-Security-Token")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-Security-Token", valid_601502
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601503 = header.getOrDefault("X-Amz-Target")
  valid_601503 = validateParameter(valid_601503, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeploymentTargets"))
  if valid_601503 != nil:
    section.add "X-Amz-Target", valid_601503
  var valid_601504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601504 = validateParameter(valid_601504, JString, required = false,
                                 default = nil)
  if valid_601504 != nil:
    section.add "X-Amz-Content-Sha256", valid_601504
  var valid_601505 = header.getOrDefault("X-Amz-Algorithm")
  valid_601505 = validateParameter(valid_601505, JString, required = false,
                                 default = nil)
  if valid_601505 != nil:
    section.add "X-Amz-Algorithm", valid_601505
  var valid_601506 = header.getOrDefault("X-Amz-Signature")
  valid_601506 = validateParameter(valid_601506, JString, required = false,
                                 default = nil)
  if valid_601506 != nil:
    section.add "X-Amz-Signature", valid_601506
  var valid_601507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601507 = validateParameter(valid_601507, JString, required = false,
                                 default = nil)
  if valid_601507 != nil:
    section.add "X-Amz-SignedHeaders", valid_601507
  var valid_601508 = header.getOrDefault("X-Amz-Credential")
  valid_601508 = validateParameter(valid_601508, JString, required = false,
                                 default = nil)
  if valid_601508 != nil:
    section.add "X-Amz-Credential", valid_601508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601510: Call_ListDeploymentTargets_601498; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns an array of target IDs that are associated a deployment. 
  ## 
  let valid = call_601510.validator(path, query, header, formData, body)
  let scheme = call_601510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601510.url(scheme.get, call_601510.host, call_601510.base,
                         call_601510.route, valid.getOrDefault("path"))
  result = hook(call_601510, url, valid)

proc call*(call_601511: Call_ListDeploymentTargets_601498; body: JsonNode): Recallable =
  ## listDeploymentTargets
  ##  Returns an array of target IDs that are associated a deployment. 
  ##   body: JObject (required)
  var body_601512 = newJObject()
  if body != nil:
    body_601512 = body
  result = call_601511.call(nil, nil, nil, nil, body_601512)

var listDeploymentTargets* = Call_ListDeploymentTargets_601498(
    name: "listDeploymentTargets", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeploymentTargets",
    validator: validate_ListDeploymentTargets_601499, base: "/",
    url: url_ListDeploymentTargets_601500, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeployments_601513 = ref object of OpenApiRestCall_600426
proc url_ListDeployments_601515(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeployments_601514(path: JsonNode; query: JsonNode;
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
  var valid_601516 = query.getOrDefault("nextToken")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "nextToken", valid_601516
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
  var valid_601517 = header.getOrDefault("X-Amz-Date")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Date", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Security-Token")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Security-Token", valid_601518
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601519 = header.getOrDefault("X-Amz-Target")
  valid_601519 = validateParameter(valid_601519, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListDeployments"))
  if valid_601519 != nil:
    section.add "X-Amz-Target", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-Content-Sha256", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Algorithm")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Algorithm", valid_601521
  var valid_601522 = header.getOrDefault("X-Amz-Signature")
  valid_601522 = validateParameter(valid_601522, JString, required = false,
                                 default = nil)
  if valid_601522 != nil:
    section.add "X-Amz-Signature", valid_601522
  var valid_601523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601523 = validateParameter(valid_601523, JString, required = false,
                                 default = nil)
  if valid_601523 != nil:
    section.add "X-Amz-SignedHeaders", valid_601523
  var valid_601524 = header.getOrDefault("X-Amz-Credential")
  valid_601524 = validateParameter(valid_601524, JString, required = false,
                                 default = nil)
  if valid_601524 != nil:
    section.add "X-Amz-Credential", valid_601524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601526: Call_ListDeployments_601513; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ## 
  let valid = call_601526.validator(path, query, header, formData, body)
  let scheme = call_601526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601526.url(scheme.get, call_601526.host, call_601526.base,
                         call_601526.route, valid.getOrDefault("path"))
  result = hook(call_601526, url, valid)

proc call*(call_601527: Call_ListDeployments_601513; body: JsonNode;
          nextToken: string = ""): Recallable =
  ## listDeployments
  ## Lists the deployments in a deployment group for an application registered with the IAM user or AWS account.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601528 = newJObject()
  var body_601529 = newJObject()
  add(query_601528, "nextToken", newJString(nextToken))
  if body != nil:
    body_601529 = body
  result = call_601527.call(nil, query_601528, nil, nil, body_601529)

var listDeployments* = Call_ListDeployments_601513(name: "listDeployments",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListDeployments",
    validator: validate_ListDeployments_601514, base: "/", url: url_ListDeployments_601515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGitHubAccountTokenNames_601530 = ref object of OpenApiRestCall_600426
proc url_ListGitHubAccountTokenNames_601532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListGitHubAccountTokenNames_601531(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601533 = header.getOrDefault("X-Amz-Date")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Date", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Security-Token")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Security-Token", valid_601534
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601535 = header.getOrDefault("X-Amz-Target")
  valid_601535 = validateParameter(valid_601535, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListGitHubAccountTokenNames"))
  if valid_601535 != nil:
    section.add "X-Amz-Target", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Content-Sha256", valid_601536
  var valid_601537 = header.getOrDefault("X-Amz-Algorithm")
  valid_601537 = validateParameter(valid_601537, JString, required = false,
                                 default = nil)
  if valid_601537 != nil:
    section.add "X-Amz-Algorithm", valid_601537
  var valid_601538 = header.getOrDefault("X-Amz-Signature")
  valid_601538 = validateParameter(valid_601538, JString, required = false,
                                 default = nil)
  if valid_601538 != nil:
    section.add "X-Amz-Signature", valid_601538
  var valid_601539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-SignedHeaders", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Credential")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Credential", valid_601540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601542: Call_ListGitHubAccountTokenNames_601530; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the names of stored connections to GitHub accounts.
  ## 
  let valid = call_601542.validator(path, query, header, formData, body)
  let scheme = call_601542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601542.url(scheme.get, call_601542.host, call_601542.base,
                         call_601542.route, valid.getOrDefault("path"))
  result = hook(call_601542, url, valid)

proc call*(call_601543: Call_ListGitHubAccountTokenNames_601530; body: JsonNode): Recallable =
  ## listGitHubAccountTokenNames
  ## Lists the names of stored connections to GitHub accounts.
  ##   body: JObject (required)
  var body_601544 = newJObject()
  if body != nil:
    body_601544 = body
  result = call_601543.call(nil, nil, nil, nil, body_601544)

var listGitHubAccountTokenNames* = Call_ListGitHubAccountTokenNames_601530(
    name: "listGitHubAccountTokenNames", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListGitHubAccountTokenNames",
    validator: validate_ListGitHubAccountTokenNames_601531, base: "/",
    url: url_ListGitHubAccountTokenNames_601532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOnPremisesInstances_601545 = ref object of OpenApiRestCall_600426
proc url_ListOnPremisesInstances_601547(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListOnPremisesInstances_601546(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601548 = header.getOrDefault("X-Amz-Date")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Date", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Security-Token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Security-Token", valid_601549
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601550 = header.getOrDefault("X-Amz-Target")
  valid_601550 = validateParameter(valid_601550, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListOnPremisesInstances"))
  if valid_601550 != nil:
    section.add "X-Amz-Target", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Content-Sha256", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Algorithm")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Algorithm", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-Signature")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-Signature", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-SignedHeaders", valid_601554
  var valid_601555 = header.getOrDefault("X-Amz-Credential")
  valid_601555 = validateParameter(valid_601555, JString, required = false,
                                 default = nil)
  if valid_601555 != nil:
    section.add "X-Amz-Credential", valid_601555
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601557: Call_ListOnPremisesInstances_601545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ## 
  let valid = call_601557.validator(path, query, header, formData, body)
  let scheme = call_601557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601557.url(scheme.get, call_601557.host, call_601557.base,
                         call_601557.route, valid.getOrDefault("path"))
  result = hook(call_601557, url, valid)

proc call*(call_601558: Call_ListOnPremisesInstances_601545; body: JsonNode): Recallable =
  ## listOnPremisesInstances
  ## <p>Gets a list of names for one or more on-premises instances.</p> <p>Unless otherwise specified, both registered and deregistered on-premises instance names are listed. To list only registered or deregistered on-premises instance names, use the registration status parameter.</p>
  ##   body: JObject (required)
  var body_601559 = newJObject()
  if body != nil:
    body_601559 = body
  result = call_601558.call(nil, nil, nil, nil, body_601559)

var listOnPremisesInstances* = Call_ListOnPremisesInstances_601545(
    name: "listOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListOnPremisesInstances",
    validator: validate_ListOnPremisesInstances_601546, base: "/",
    url: url_ListOnPremisesInstances_601547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601560 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601562(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListTagsForResource_601561(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601563 = header.getOrDefault("X-Amz-Date")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Date", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Security-Token")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Security-Token", valid_601564
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601565 = header.getOrDefault("X-Amz-Target")
  valid_601565 = validateParameter(valid_601565, JString, required = true, default = newJString(
      "CodeDeploy_20141006.ListTagsForResource"))
  if valid_601565 != nil:
    section.add "X-Amz-Target", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Content-Sha256", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Algorithm")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Algorithm", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-Signature")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-Signature", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-SignedHeaders", valid_601569
  var valid_601570 = header.getOrDefault("X-Amz-Credential")
  valid_601570 = validateParameter(valid_601570, JString, required = false,
                                 default = nil)
  if valid_601570 != nil:
    section.add "X-Amz-Credential", valid_601570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601572: Call_ListTagsForResource_601560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ## 
  let valid = call_601572.validator(path, query, header, formData, body)
  let scheme = call_601572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601572.url(scheme.get, call_601572.host, call_601572.base,
                         call_601572.route, valid.getOrDefault("path"))
  result = hook(call_601572, url, valid)

proc call*(call_601573: Call_ListTagsForResource_601560; body: JsonNode): Recallable =
  ## listTagsForResource
  ##  Returns a list of tags for the resource identified by a specified ARN. Tags are used to organize and categorize your CodeDeploy resources. 
  ##   body: JObject (required)
  var body_601574 = newJObject()
  if body != nil:
    body_601574 = body
  result = call_601573.call(nil, nil, nil, nil, body_601574)

var listTagsForResource* = Call_ListTagsForResource_601560(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.ListTagsForResource",
    validator: validate_ListTagsForResource_601561, base: "/",
    url: url_ListTagsForResource_601562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutLifecycleEventHookExecutionStatus_601575 = ref object of OpenApiRestCall_600426
proc url_PutLifecycleEventHookExecutionStatus_601577(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutLifecycleEventHookExecutionStatus_601576(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601578 = header.getOrDefault("X-Amz-Date")
  valid_601578 = validateParameter(valid_601578, JString, required = false,
                                 default = nil)
  if valid_601578 != nil:
    section.add "X-Amz-Date", valid_601578
  var valid_601579 = header.getOrDefault("X-Amz-Security-Token")
  valid_601579 = validateParameter(valid_601579, JString, required = false,
                                 default = nil)
  if valid_601579 != nil:
    section.add "X-Amz-Security-Token", valid_601579
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601580 = header.getOrDefault("X-Amz-Target")
  valid_601580 = validateParameter(valid_601580, JString, required = true, default = newJString(
      "CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus"))
  if valid_601580 != nil:
    section.add "X-Amz-Target", valid_601580
  var valid_601581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601581 = validateParameter(valid_601581, JString, required = false,
                                 default = nil)
  if valid_601581 != nil:
    section.add "X-Amz-Content-Sha256", valid_601581
  var valid_601582 = header.getOrDefault("X-Amz-Algorithm")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Algorithm", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Signature")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Signature", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-SignedHeaders", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Credential")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Credential", valid_601585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601587: Call_PutLifecycleEventHookExecutionStatus_601575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ## 
  let valid = call_601587.validator(path, query, header, formData, body)
  let scheme = call_601587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601587.url(scheme.get, call_601587.host, call_601587.base,
                         call_601587.route, valid.getOrDefault("path"))
  result = hook(call_601587, url, valid)

proc call*(call_601588: Call_PutLifecycleEventHookExecutionStatus_601575;
          body: JsonNode): Recallable =
  ## putLifecycleEventHookExecutionStatus
  ##  Sets the result of a Lambda validation function. The function validates one or both lifecycle events (<code>BeforeAllowTraffic</code> and <code>AfterAllowTraffic</code>) and returns <code>Succeeded</code> or <code>Failed</code>. 
  ##   body: JObject (required)
  var body_601589 = newJObject()
  if body != nil:
    body_601589 = body
  result = call_601588.call(nil, nil, nil, nil, body_601589)

var putLifecycleEventHookExecutionStatus* = Call_PutLifecycleEventHookExecutionStatus_601575(
    name: "putLifecycleEventHookExecutionStatus", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.PutLifecycleEventHookExecutionStatus",
    validator: validate_PutLifecycleEventHookExecutionStatus_601576, base: "/",
    url: url_PutLifecycleEventHookExecutionStatus_601577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterApplicationRevision_601590 = ref object of OpenApiRestCall_600426
proc url_RegisterApplicationRevision_601592(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterApplicationRevision_601591(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601593 = header.getOrDefault("X-Amz-Date")
  valid_601593 = validateParameter(valid_601593, JString, required = false,
                                 default = nil)
  if valid_601593 != nil:
    section.add "X-Amz-Date", valid_601593
  var valid_601594 = header.getOrDefault("X-Amz-Security-Token")
  valid_601594 = validateParameter(valid_601594, JString, required = false,
                                 default = nil)
  if valid_601594 != nil:
    section.add "X-Amz-Security-Token", valid_601594
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601595 = header.getOrDefault("X-Amz-Target")
  valid_601595 = validateParameter(valid_601595, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterApplicationRevision"))
  if valid_601595 != nil:
    section.add "X-Amz-Target", valid_601595
  var valid_601596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601596 = validateParameter(valid_601596, JString, required = false,
                                 default = nil)
  if valid_601596 != nil:
    section.add "X-Amz-Content-Sha256", valid_601596
  var valid_601597 = header.getOrDefault("X-Amz-Algorithm")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Algorithm", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Signature")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Signature", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-SignedHeaders", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Credential")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Credential", valid_601600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601602: Call_RegisterApplicationRevision_601590; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ## 
  let valid = call_601602.validator(path, query, header, formData, body)
  let scheme = call_601602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601602.url(scheme.get, call_601602.host, call_601602.base,
                         call_601602.route, valid.getOrDefault("path"))
  result = hook(call_601602, url, valid)

proc call*(call_601603: Call_RegisterApplicationRevision_601590; body: JsonNode): Recallable =
  ## registerApplicationRevision
  ## Registers with AWS CodeDeploy a revision for the specified application.
  ##   body: JObject (required)
  var body_601604 = newJObject()
  if body != nil:
    body_601604 = body
  result = call_601603.call(nil, nil, nil, nil, body_601604)

var registerApplicationRevision* = Call_RegisterApplicationRevision_601590(
    name: "registerApplicationRevision", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterApplicationRevision",
    validator: validate_RegisterApplicationRevision_601591, base: "/",
    url: url_RegisterApplicationRevision_601592,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterOnPremisesInstance_601605 = ref object of OpenApiRestCall_600426
proc url_RegisterOnPremisesInstance_601607(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterOnPremisesInstance_601606(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601608 = header.getOrDefault("X-Amz-Date")
  valid_601608 = validateParameter(valid_601608, JString, required = false,
                                 default = nil)
  if valid_601608 != nil:
    section.add "X-Amz-Date", valid_601608
  var valid_601609 = header.getOrDefault("X-Amz-Security-Token")
  valid_601609 = validateParameter(valid_601609, JString, required = false,
                                 default = nil)
  if valid_601609 != nil:
    section.add "X-Amz-Security-Token", valid_601609
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601610 = header.getOrDefault("X-Amz-Target")
  valid_601610 = validateParameter(valid_601610, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RegisterOnPremisesInstance"))
  if valid_601610 != nil:
    section.add "X-Amz-Target", valid_601610
  var valid_601611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601611 = validateParameter(valid_601611, JString, required = false,
                                 default = nil)
  if valid_601611 != nil:
    section.add "X-Amz-Content-Sha256", valid_601611
  var valid_601612 = header.getOrDefault("X-Amz-Algorithm")
  valid_601612 = validateParameter(valid_601612, JString, required = false,
                                 default = nil)
  if valid_601612 != nil:
    section.add "X-Amz-Algorithm", valid_601612
  var valid_601613 = header.getOrDefault("X-Amz-Signature")
  valid_601613 = validateParameter(valid_601613, JString, required = false,
                                 default = nil)
  if valid_601613 != nil:
    section.add "X-Amz-Signature", valid_601613
  var valid_601614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601614 = validateParameter(valid_601614, JString, required = false,
                                 default = nil)
  if valid_601614 != nil:
    section.add "X-Amz-SignedHeaders", valid_601614
  var valid_601615 = header.getOrDefault("X-Amz-Credential")
  valid_601615 = validateParameter(valid_601615, JString, required = false,
                                 default = nil)
  if valid_601615 != nil:
    section.add "X-Amz-Credential", valid_601615
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601617: Call_RegisterOnPremisesInstance_601605; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ## 
  let valid = call_601617.validator(path, query, header, formData, body)
  let scheme = call_601617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601617.url(scheme.get, call_601617.host, call_601617.base,
                         call_601617.route, valid.getOrDefault("path"))
  result = hook(call_601617, url, valid)

proc call*(call_601618: Call_RegisterOnPremisesInstance_601605; body: JsonNode): Recallable =
  ## registerOnPremisesInstance
  ## <p>Registers an on-premises instance.</p> <note> <p>Only one IAM ARN (an IAM session ARN or IAM user ARN) is supported in the request. You cannot use both.</p> </note>
  ##   body: JObject (required)
  var body_601619 = newJObject()
  if body != nil:
    body_601619 = body
  result = call_601618.call(nil, nil, nil, nil, body_601619)

var registerOnPremisesInstance* = Call_RegisterOnPremisesInstance_601605(
    name: "registerOnPremisesInstance", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.RegisterOnPremisesInstance",
    validator: validate_RegisterOnPremisesInstance_601606, base: "/",
    url: url_RegisterOnPremisesInstance_601607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromOnPremisesInstances_601620 = ref object of OpenApiRestCall_600426
proc url_RemoveTagsFromOnPremisesInstances_601622(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTagsFromOnPremisesInstances_601621(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601623 = header.getOrDefault("X-Amz-Date")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Date", valid_601623
  var valid_601624 = header.getOrDefault("X-Amz-Security-Token")
  valid_601624 = validateParameter(valid_601624, JString, required = false,
                                 default = nil)
  if valid_601624 != nil:
    section.add "X-Amz-Security-Token", valid_601624
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601625 = header.getOrDefault("X-Amz-Target")
  valid_601625 = validateParameter(valid_601625, JString, required = true, default = newJString(
      "CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances"))
  if valid_601625 != nil:
    section.add "X-Amz-Target", valid_601625
  var valid_601626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601626 = validateParameter(valid_601626, JString, required = false,
                                 default = nil)
  if valid_601626 != nil:
    section.add "X-Amz-Content-Sha256", valid_601626
  var valid_601627 = header.getOrDefault("X-Amz-Algorithm")
  valid_601627 = validateParameter(valid_601627, JString, required = false,
                                 default = nil)
  if valid_601627 != nil:
    section.add "X-Amz-Algorithm", valid_601627
  var valid_601628 = header.getOrDefault("X-Amz-Signature")
  valid_601628 = validateParameter(valid_601628, JString, required = false,
                                 default = nil)
  if valid_601628 != nil:
    section.add "X-Amz-Signature", valid_601628
  var valid_601629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601629 = validateParameter(valid_601629, JString, required = false,
                                 default = nil)
  if valid_601629 != nil:
    section.add "X-Amz-SignedHeaders", valid_601629
  var valid_601630 = header.getOrDefault("X-Amz-Credential")
  valid_601630 = validateParameter(valid_601630, JString, required = false,
                                 default = nil)
  if valid_601630 != nil:
    section.add "X-Amz-Credential", valid_601630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601632: Call_RemoveTagsFromOnPremisesInstances_601620;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Removes one or more tags from one or more on-premises instances.
  ## 
  let valid = call_601632.validator(path, query, header, formData, body)
  let scheme = call_601632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601632.url(scheme.get, call_601632.host, call_601632.base,
                         call_601632.route, valid.getOrDefault("path"))
  result = hook(call_601632, url, valid)

proc call*(call_601633: Call_RemoveTagsFromOnPremisesInstances_601620;
          body: JsonNode): Recallable =
  ## removeTagsFromOnPremisesInstances
  ## Removes one or more tags from one or more on-premises instances.
  ##   body: JObject (required)
  var body_601634 = newJObject()
  if body != nil:
    body_601634 = body
  result = call_601633.call(nil, nil, nil, nil, body_601634)

var removeTagsFromOnPremisesInstances* = Call_RemoveTagsFromOnPremisesInstances_601620(
    name: "removeTagsFromOnPremisesInstances", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.RemoveTagsFromOnPremisesInstances",
    validator: validate_RemoveTagsFromOnPremisesInstances_601621, base: "/",
    url: url_RemoveTagsFromOnPremisesInstances_601622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SkipWaitTimeForInstanceTermination_601635 = ref object of OpenApiRestCall_600426
proc url_SkipWaitTimeForInstanceTermination_601637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SkipWaitTimeForInstanceTermination_601636(path: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601638 = header.getOrDefault("X-Amz-Date")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Date", valid_601638
  var valid_601639 = header.getOrDefault("X-Amz-Security-Token")
  valid_601639 = validateParameter(valid_601639, JString, required = false,
                                 default = nil)
  if valid_601639 != nil:
    section.add "X-Amz-Security-Token", valid_601639
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601640 = header.getOrDefault("X-Amz-Target")
  valid_601640 = validateParameter(valid_601640, JString, required = true, default = newJString(
      "CodeDeploy_20141006.SkipWaitTimeForInstanceTermination"))
  if valid_601640 != nil:
    section.add "X-Amz-Target", valid_601640
  var valid_601641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601641 = validateParameter(valid_601641, JString, required = false,
                                 default = nil)
  if valid_601641 != nil:
    section.add "X-Amz-Content-Sha256", valid_601641
  var valid_601642 = header.getOrDefault("X-Amz-Algorithm")
  valid_601642 = validateParameter(valid_601642, JString, required = false,
                                 default = nil)
  if valid_601642 != nil:
    section.add "X-Amz-Algorithm", valid_601642
  var valid_601643 = header.getOrDefault("X-Amz-Signature")
  valid_601643 = validateParameter(valid_601643, JString, required = false,
                                 default = nil)
  if valid_601643 != nil:
    section.add "X-Amz-Signature", valid_601643
  var valid_601644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601644 = validateParameter(valid_601644, JString, required = false,
                                 default = nil)
  if valid_601644 != nil:
    section.add "X-Amz-SignedHeaders", valid_601644
  var valid_601645 = header.getOrDefault("X-Amz-Credential")
  valid_601645 = validateParameter(valid_601645, JString, required = false,
                                 default = nil)
  if valid_601645 != nil:
    section.add "X-Amz-Credential", valid_601645
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601647: Call_SkipWaitTimeForInstanceTermination_601635;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ## 
  let valid = call_601647.validator(path, query, header, formData, body)
  let scheme = call_601647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601647.url(scheme.get, call_601647.host, call_601647.base,
                         call_601647.route, valid.getOrDefault("path"))
  result = hook(call_601647, url, valid)

proc call*(call_601648: Call_SkipWaitTimeForInstanceTermination_601635;
          body: JsonNode): Recallable =
  ## skipWaitTimeForInstanceTermination
  ## In a blue/green deployment, overrides any specified wait time and starts terminating instances immediately after the traffic routing is complete.
  ##   body: JObject (required)
  var body_601649 = newJObject()
  if body != nil:
    body_601649 = body
  result = call_601648.call(nil, nil, nil, nil, body_601649)

var skipWaitTimeForInstanceTermination* = Call_SkipWaitTimeForInstanceTermination_601635(
    name: "skipWaitTimeForInstanceTermination", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.SkipWaitTimeForInstanceTermination",
    validator: validate_SkipWaitTimeForInstanceTermination_601636, base: "/",
    url: url_SkipWaitTimeForInstanceTermination_601637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopDeployment_601650 = ref object of OpenApiRestCall_600426
proc url_StopDeployment_601652(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_StopDeployment_601651(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601653 = header.getOrDefault("X-Amz-Date")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Date", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Security-Token")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Security-Token", valid_601654
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601655 = header.getOrDefault("X-Amz-Target")
  valid_601655 = validateParameter(valid_601655, JString, required = true, default = newJString(
      "CodeDeploy_20141006.StopDeployment"))
  if valid_601655 != nil:
    section.add "X-Amz-Target", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Content-Sha256", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-Algorithm")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-Algorithm", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Signature")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Signature", valid_601658
  var valid_601659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601659 = validateParameter(valid_601659, JString, required = false,
                                 default = nil)
  if valid_601659 != nil:
    section.add "X-Amz-SignedHeaders", valid_601659
  var valid_601660 = header.getOrDefault("X-Amz-Credential")
  valid_601660 = validateParameter(valid_601660, JString, required = false,
                                 default = nil)
  if valid_601660 != nil:
    section.add "X-Amz-Credential", valid_601660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601662: Call_StopDeployment_601650; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Attempts to stop an ongoing deployment.
  ## 
  let valid = call_601662.validator(path, query, header, formData, body)
  let scheme = call_601662.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601662.url(scheme.get, call_601662.host, call_601662.base,
                         call_601662.route, valid.getOrDefault("path"))
  result = hook(call_601662, url, valid)

proc call*(call_601663: Call_StopDeployment_601650; body: JsonNode): Recallable =
  ## stopDeployment
  ## Attempts to stop an ongoing deployment.
  ##   body: JObject (required)
  var body_601664 = newJObject()
  if body != nil:
    body_601664 = body
  result = call_601663.call(nil, nil, nil, nil, body_601664)

var stopDeployment* = Call_StopDeployment_601650(name: "stopDeployment",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.StopDeployment",
    validator: validate_StopDeployment_601651, base: "/", url: url_StopDeployment_601652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601665 = ref object of OpenApiRestCall_600426
proc url_TagResource_601667(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TagResource_601666(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601668 = header.getOrDefault("X-Amz-Date")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Date", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Security-Token")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Security-Token", valid_601669
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601670 = header.getOrDefault("X-Amz-Target")
  valid_601670 = validateParameter(valid_601670, JString, required = true, default = newJString(
      "CodeDeploy_20141006.TagResource"))
  if valid_601670 != nil:
    section.add "X-Amz-Target", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Content-Sha256", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-Algorithm")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-Algorithm", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Signature")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Signature", valid_601673
  var valid_601674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601674 = validateParameter(valid_601674, JString, required = false,
                                 default = nil)
  if valid_601674 != nil:
    section.add "X-Amz-SignedHeaders", valid_601674
  var valid_601675 = header.getOrDefault("X-Amz-Credential")
  valid_601675 = validateParameter(valid_601675, JString, required = false,
                                 default = nil)
  if valid_601675 != nil:
    section.add "X-Amz-Credential", valid_601675
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601677: Call_TagResource_601665; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ## 
  let valid = call_601677.validator(path, query, header, formData, body)
  let scheme = call_601677.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601677.url(scheme.get, call_601677.host, call_601677.base,
                         call_601677.route, valid.getOrDefault("path"))
  result = hook(call_601677, url, valid)

proc call*(call_601678: Call_TagResource_601665; body: JsonNode): Recallable =
  ## tagResource
  ##  Associates the list of tags in the input <code>Tags</code> parameter with the resource identified by the <code>ResourceArn</code> input parameter. 
  ##   body: JObject (required)
  var body_601679 = newJObject()
  if body != nil:
    body_601679 = body
  result = call_601678.call(nil, nil, nil, nil, body_601679)

var tagResource* = Call_TagResource_601665(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "codedeploy.amazonaws.com", route: "/#X-Amz-Target=CodeDeploy_20141006.TagResource",
                                        validator: validate_TagResource_601666,
                                        base: "/", url: url_TagResource_601667,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601680 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601682(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UntagResource_601681(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601683 = header.getOrDefault("X-Amz-Date")
  valid_601683 = validateParameter(valid_601683, JString, required = false,
                                 default = nil)
  if valid_601683 != nil:
    section.add "X-Amz-Date", valid_601683
  var valid_601684 = header.getOrDefault("X-Amz-Security-Token")
  valid_601684 = validateParameter(valid_601684, JString, required = false,
                                 default = nil)
  if valid_601684 != nil:
    section.add "X-Amz-Security-Token", valid_601684
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601685 = header.getOrDefault("X-Amz-Target")
  valid_601685 = validateParameter(valid_601685, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UntagResource"))
  if valid_601685 != nil:
    section.add "X-Amz-Target", valid_601685
  var valid_601686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601686 = validateParameter(valid_601686, JString, required = false,
                                 default = nil)
  if valid_601686 != nil:
    section.add "X-Amz-Content-Sha256", valid_601686
  var valid_601687 = header.getOrDefault("X-Amz-Algorithm")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Algorithm", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Signature")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Signature", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-SignedHeaders", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Credential")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Credential", valid_601690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601692: Call_UntagResource_601680; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ## 
  let valid = call_601692.validator(path, query, header, formData, body)
  let scheme = call_601692.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601692.url(scheme.get, call_601692.host, call_601692.base,
                         call_601692.route, valid.getOrDefault("path"))
  result = hook(call_601692, url, valid)

proc call*(call_601693: Call_UntagResource_601680; body: JsonNode): Recallable =
  ## untagResource
  ##  Disassociates a resource from a list of tags. The resource is identified by the <code>ResourceArn</code> input parameter. The tags are identfied by the list of keys in the <code>TagKeys</code> input parameter. 
  ##   body: JObject (required)
  var body_601694 = newJObject()
  if body != nil:
    body_601694 = body
  result = call_601693.call(nil, nil, nil, nil, body_601694)

var untagResource* = Call_UntagResource_601680(name: "untagResource",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UntagResource",
    validator: validate_UntagResource_601681, base: "/", url: url_UntagResource_601682,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateApplication_601695 = ref object of OpenApiRestCall_600426
proc url_UpdateApplication_601697(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateApplication_601696(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601698 = header.getOrDefault("X-Amz-Date")
  valid_601698 = validateParameter(valid_601698, JString, required = false,
                                 default = nil)
  if valid_601698 != nil:
    section.add "X-Amz-Date", valid_601698
  var valid_601699 = header.getOrDefault("X-Amz-Security-Token")
  valid_601699 = validateParameter(valid_601699, JString, required = false,
                                 default = nil)
  if valid_601699 != nil:
    section.add "X-Amz-Security-Token", valid_601699
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601700 = header.getOrDefault("X-Amz-Target")
  valid_601700 = validateParameter(valid_601700, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateApplication"))
  if valid_601700 != nil:
    section.add "X-Amz-Target", valid_601700
  var valid_601701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601701 = validateParameter(valid_601701, JString, required = false,
                                 default = nil)
  if valid_601701 != nil:
    section.add "X-Amz-Content-Sha256", valid_601701
  var valid_601702 = header.getOrDefault("X-Amz-Algorithm")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Algorithm", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Signature")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Signature", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-SignedHeaders", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Credential")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Credential", valid_601705
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601707: Call_UpdateApplication_601695; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the name of an application.
  ## 
  let valid = call_601707.validator(path, query, header, formData, body)
  let scheme = call_601707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601707.url(scheme.get, call_601707.host, call_601707.base,
                         call_601707.route, valid.getOrDefault("path"))
  result = hook(call_601707, url, valid)

proc call*(call_601708: Call_UpdateApplication_601695; body: JsonNode): Recallable =
  ## updateApplication
  ## Changes the name of an application.
  ##   body: JObject (required)
  var body_601709 = newJObject()
  if body != nil:
    body_601709 = body
  result = call_601708.call(nil, nil, nil, nil, body_601709)

var updateApplication* = Call_UpdateApplication_601695(name: "updateApplication",
    meth: HttpMethod.HttpPost, host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateApplication",
    validator: validate_UpdateApplication_601696, base: "/",
    url: url_UpdateApplication_601697, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDeploymentGroup_601710 = ref object of OpenApiRestCall_600426
proc url_UpdateDeploymentGroup_601712(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateDeploymentGroup_601711(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601713 = header.getOrDefault("X-Amz-Date")
  valid_601713 = validateParameter(valid_601713, JString, required = false,
                                 default = nil)
  if valid_601713 != nil:
    section.add "X-Amz-Date", valid_601713
  var valid_601714 = header.getOrDefault("X-Amz-Security-Token")
  valid_601714 = validateParameter(valid_601714, JString, required = false,
                                 default = nil)
  if valid_601714 != nil:
    section.add "X-Amz-Security-Token", valid_601714
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601715 = header.getOrDefault("X-Amz-Target")
  valid_601715 = validateParameter(valid_601715, JString, required = true, default = newJString(
      "CodeDeploy_20141006.UpdateDeploymentGroup"))
  if valid_601715 != nil:
    section.add "X-Amz-Target", valid_601715
  var valid_601716 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601716 = validateParameter(valid_601716, JString, required = false,
                                 default = nil)
  if valid_601716 != nil:
    section.add "X-Amz-Content-Sha256", valid_601716
  var valid_601717 = header.getOrDefault("X-Amz-Algorithm")
  valid_601717 = validateParameter(valid_601717, JString, required = false,
                                 default = nil)
  if valid_601717 != nil:
    section.add "X-Amz-Algorithm", valid_601717
  var valid_601718 = header.getOrDefault("X-Amz-Signature")
  valid_601718 = validateParameter(valid_601718, JString, required = false,
                                 default = nil)
  if valid_601718 != nil:
    section.add "X-Amz-Signature", valid_601718
  var valid_601719 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601719 = validateParameter(valid_601719, JString, required = false,
                                 default = nil)
  if valid_601719 != nil:
    section.add "X-Amz-SignedHeaders", valid_601719
  var valid_601720 = header.getOrDefault("X-Amz-Credential")
  valid_601720 = validateParameter(valid_601720, JString, required = false,
                                 default = nil)
  if valid_601720 != nil:
    section.add "X-Amz-Credential", valid_601720
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601722: Call_UpdateDeploymentGroup_601710; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes information about a deployment group.
  ## 
  let valid = call_601722.validator(path, query, header, formData, body)
  let scheme = call_601722.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601722.url(scheme.get, call_601722.host, call_601722.base,
                         call_601722.route, valid.getOrDefault("path"))
  result = hook(call_601722, url, valid)

proc call*(call_601723: Call_UpdateDeploymentGroup_601710; body: JsonNode): Recallable =
  ## updateDeploymentGroup
  ## Changes information about a deployment group.
  ##   body: JObject (required)
  var body_601724 = newJObject()
  if body != nil:
    body_601724 = body
  result = call_601723.call(nil, nil, nil, nil, body_601724)

var updateDeploymentGroup* = Call_UpdateDeploymentGroup_601710(
    name: "updateDeploymentGroup", meth: HttpMethod.HttpPost,
    host: "codedeploy.amazonaws.com",
    route: "/#X-Amz-Target=CodeDeploy_20141006.UpdateDeploymentGroup",
    validator: validate_UpdateDeploymentGroup_601711, base: "/",
    url: url_UpdateDeploymentGroup_601712, schemes: {Scheme.Https, Scheme.Http})
export
  rest

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

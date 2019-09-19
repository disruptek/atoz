
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic MapReduce
## version: 2009-03-31
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Amazon EMR is a web service that makes it easy to process large amounts of data efficiently. Amazon EMR uses Hadoop processing combined with several AWS products to do tasks such as web indexing, data mining, log file analysis, machine learning, scientific simulation, and data warehousing.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elasticmapreduce/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "elasticmapreduce.ap-northeast-1.amazonaws.com", "ap-southeast-1": "elasticmapreduce.ap-southeast-1.amazonaws.com", "us-west-2": "elasticmapreduce.us-west-2.amazonaws.com", "eu-west-2": "elasticmapreduce.eu-west-2.amazonaws.com", "ap-northeast-3": "elasticmapreduce.ap-northeast-3.amazonaws.com", "eu-central-1": "elasticmapreduce.eu-central-1.amazonaws.com", "us-east-2": "elasticmapreduce.us-east-2.amazonaws.com", "us-east-1": "elasticmapreduce.us-east-1.amazonaws.com", "cn-northwest-1": "elasticmapreduce.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "elasticmapreduce.ap-south-1.amazonaws.com", "eu-north-1": "elasticmapreduce.eu-north-1.amazonaws.com", "ap-northeast-2": "elasticmapreduce.ap-northeast-2.amazonaws.com", "us-west-1": "elasticmapreduce.us-west-1.amazonaws.com", "us-gov-east-1": "elasticmapreduce.us-gov-east-1.amazonaws.com", "eu-west-3": "elasticmapreduce.eu-west-3.amazonaws.com", "cn-north-1": "elasticmapreduce.cn-north-1.amazonaws.com.cn", "sa-east-1": "elasticmapreduce.sa-east-1.amazonaws.com", "eu-west-1": "elasticmapreduce.eu-west-1.amazonaws.com", "us-gov-west-1": "elasticmapreduce.us-gov-west-1.amazonaws.com", "ap-southeast-2": "elasticmapreduce.ap-southeast-2.amazonaws.com", "ca-central-1": "elasticmapreduce.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "elasticmapreduce.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "elasticmapreduce.ap-southeast-1.amazonaws.com",
      "us-west-2": "elasticmapreduce.us-west-2.amazonaws.com",
      "eu-west-2": "elasticmapreduce.eu-west-2.amazonaws.com",
      "ap-northeast-3": "elasticmapreduce.ap-northeast-3.amazonaws.com",
      "eu-central-1": "elasticmapreduce.eu-central-1.amazonaws.com",
      "us-east-2": "elasticmapreduce.us-east-2.amazonaws.com",
      "us-east-1": "elasticmapreduce.us-east-1.amazonaws.com",
      "cn-northwest-1": "elasticmapreduce.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "elasticmapreduce.ap-south-1.amazonaws.com",
      "eu-north-1": "elasticmapreduce.eu-north-1.amazonaws.com",
      "ap-northeast-2": "elasticmapreduce.ap-northeast-2.amazonaws.com",
      "us-west-1": "elasticmapreduce.us-west-1.amazonaws.com",
      "us-gov-east-1": "elasticmapreduce.us-gov-east-1.amazonaws.com",
      "eu-west-3": "elasticmapreduce.eu-west-3.amazonaws.com",
      "cn-north-1": "elasticmapreduce.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "elasticmapreduce.sa-east-1.amazonaws.com",
      "eu-west-1": "elasticmapreduce.eu-west-1.amazonaws.com",
      "us-gov-west-1": "elasticmapreduce.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "elasticmapreduce.ap-southeast-2.amazonaws.com",
      "ca-central-1": "elasticmapreduce.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elasticmapreduce"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_AddInstanceFleet_600768 = ref object of OpenApiRestCall_600426
proc url_AddInstanceFleet_600770(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddInstanceFleet_600769(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Adds an instance fleet to a running cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x.</p> </note>
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
      "ElasticMapReduce.AddInstanceFleet"))
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

proc call*(call_600926: Call_AddInstanceFleet_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds an instance fleet to a running cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x.</p> </note>
  ## 
  let valid = call_600926.validator(path, query, header, formData, body)
  let scheme = call_600926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600926.url(scheme.get, call_600926.host, call_600926.base,
                         call_600926.route, valid.getOrDefault("path"))
  result = hook(call_600926, url, valid)

proc call*(call_600997: Call_AddInstanceFleet_600768; body: JsonNode): Recallable =
  ## addInstanceFleet
  ## <p>Adds an instance fleet to a running cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x.</p> </note>
  ##   body: JObject (required)
  var body_600998 = newJObject()
  if body != nil:
    body_600998 = body
  result = call_600997.call(nil, nil, nil, nil, body_600998)

var addInstanceFleet* = Call_AddInstanceFleet_600768(name: "addInstanceFleet",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.AddInstanceFleet",
    validator: validate_AddInstanceFleet_600769, base: "/",
    url: url_AddInstanceFleet_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddInstanceGroups_601037 = ref object of OpenApiRestCall_600426
proc url_AddInstanceGroups_601039(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddInstanceGroups_601038(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Adds one or more instance groups to a running cluster.
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
      "ElasticMapReduce.AddInstanceGroups"))
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

proc call*(call_601049: Call_AddInstanceGroups_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds one or more instance groups to a running cluster.
  ## 
  let valid = call_601049.validator(path, query, header, formData, body)
  let scheme = call_601049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601049.url(scheme.get, call_601049.host, call_601049.base,
                         call_601049.route, valid.getOrDefault("path"))
  result = hook(call_601049, url, valid)

proc call*(call_601050: Call_AddInstanceGroups_601037; body: JsonNode): Recallable =
  ## addInstanceGroups
  ## Adds one or more instance groups to a running cluster.
  ##   body: JObject (required)
  var body_601051 = newJObject()
  if body != nil:
    body_601051 = body
  result = call_601050.call(nil, nil, nil, nil, body_601051)

var addInstanceGroups* = Call_AddInstanceGroups_601037(name: "addInstanceGroups",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.AddInstanceGroups",
    validator: validate_AddInstanceGroups_601038, base: "/",
    url: url_AddInstanceGroups_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddJobFlowSteps_601052 = ref object of OpenApiRestCall_600426
proc url_AddJobFlowSteps_601054(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddJobFlowSteps_601053(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>AddJobFlowSteps adds new steps to a running cluster. A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using SSH to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>A step specifies the location of a JAR file stored either on the master node of the cluster or in Amazon S3. Each step is performed by the main function of the main class of the JAR file. The main class can be specified either in the manifest of the JAR or by using the MainFunction parameter of the step.</p> <p>Amazon EMR executes each step in the order listed. For a step to be considered complete, the main function must exit with a zero exit code and all Hadoop jobs started while the step was running must have completed and run successfully.</p> <p>You can only add steps to a cluster that is in one of the following states: STARTING, BOOTSTRAPPING, RUNNING, or WAITING.</p>
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
      "ElasticMapReduce.AddJobFlowSteps"))
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

proc call*(call_601064: Call_AddJobFlowSteps_601052; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>AddJobFlowSteps adds new steps to a running cluster. A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using SSH to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>A step specifies the location of a JAR file stored either on the master node of the cluster or in Amazon S3. Each step is performed by the main function of the main class of the JAR file. The main class can be specified either in the manifest of the JAR or by using the MainFunction parameter of the step.</p> <p>Amazon EMR executes each step in the order listed. For a step to be considered complete, the main function must exit with a zero exit code and all Hadoop jobs started while the step was running must have completed and run successfully.</p> <p>You can only add steps to a cluster that is in one of the following states: STARTING, BOOTSTRAPPING, RUNNING, or WAITING.</p>
  ## 
  let valid = call_601064.validator(path, query, header, formData, body)
  let scheme = call_601064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601064.url(scheme.get, call_601064.host, call_601064.base,
                         call_601064.route, valid.getOrDefault("path"))
  result = hook(call_601064, url, valid)

proc call*(call_601065: Call_AddJobFlowSteps_601052; body: JsonNode): Recallable =
  ## addJobFlowSteps
  ## <p>AddJobFlowSteps adds new steps to a running cluster. A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using SSH to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>A step specifies the location of a JAR file stored either on the master node of the cluster or in Amazon S3. Each step is performed by the main function of the main class of the JAR file. The main class can be specified either in the manifest of the JAR or by using the MainFunction parameter of the step.</p> <p>Amazon EMR executes each step in the order listed. For a step to be considered complete, the main function must exit with a zero exit code and all Hadoop jobs started while the step was running must have completed and run successfully.</p> <p>You can only add steps to a cluster that is in one of the following states: STARTING, BOOTSTRAPPING, RUNNING, or WAITING.</p>
  ##   body: JObject (required)
  var body_601066 = newJObject()
  if body != nil:
    body_601066 = body
  result = call_601065.call(nil, nil, nil, nil, body_601066)

var addJobFlowSteps* = Call_AddJobFlowSteps_601052(name: "addJobFlowSteps",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.AddJobFlowSteps",
    validator: validate_AddJobFlowSteps_601053, base: "/", url: url_AddJobFlowSteps_601054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_AddTags_601067 = ref object of OpenApiRestCall_600426
proc url_AddTags_601069(protocol: Scheme; host: string; base: string; route: string;
                       path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_AddTags_601068(path: JsonNode; query: JsonNode; header: JsonNode;
                            formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds tags to an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. 
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
      "ElasticMapReduce.AddTags"))
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

proc call*(call_601079: Call_AddTags_601067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds tags to an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. 
  ## 
  let valid = call_601079.validator(path, query, header, formData, body)
  let scheme = call_601079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601079.url(scheme.get, call_601079.host, call_601079.base,
                         call_601079.route, valid.getOrDefault("path"))
  result = hook(call_601079, url, valid)

proc call*(call_601080: Call_AddTags_601067; body: JsonNode): Recallable =
  ## addTags
  ## Adds tags to an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. 
  ##   body: JObject (required)
  var body_601081 = newJObject()
  if body != nil:
    body_601081 = body
  result = call_601080.call(nil, nil, nil, nil, body_601081)

var addTags* = Call_AddTags_601067(name: "addTags", meth: HttpMethod.HttpPost,
                                host: "elasticmapreduce.amazonaws.com", route: "/#X-Amz-Target=ElasticMapReduce.AddTags",
                                validator: validate_AddTags_601068, base: "/",
                                url: url_AddTags_601069,
                                schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSteps_601082 = ref object of OpenApiRestCall_600426
proc url_CancelSteps_601084(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelSteps_601083(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a pending step or steps in a running cluster. Available only in Amazon EMR versions 4.8.0 and later, excluding version 5.0.0. A maximum of 256 steps are allowed in each CancelSteps request. CancelSteps is idempotent but asynchronous; it does not guarantee a step will be canceled, even if the request is successfully submitted. You can only cancel steps that are in a <code>PENDING</code> state.
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
      "ElasticMapReduce.CancelSteps"))
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

proc call*(call_601094: Call_CancelSteps_601082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a pending step or steps in a running cluster. Available only in Amazon EMR versions 4.8.0 and later, excluding version 5.0.0. A maximum of 256 steps are allowed in each CancelSteps request. CancelSteps is idempotent but asynchronous; it does not guarantee a step will be canceled, even if the request is successfully submitted. You can only cancel steps that are in a <code>PENDING</code> state.
  ## 
  let valid = call_601094.validator(path, query, header, formData, body)
  let scheme = call_601094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601094.url(scheme.get, call_601094.host, call_601094.base,
                         call_601094.route, valid.getOrDefault("path"))
  result = hook(call_601094, url, valid)

proc call*(call_601095: Call_CancelSteps_601082; body: JsonNode): Recallable =
  ## cancelSteps
  ## Cancels a pending step or steps in a running cluster. Available only in Amazon EMR versions 4.8.0 and later, excluding version 5.0.0. A maximum of 256 steps are allowed in each CancelSteps request. CancelSteps is idempotent but asynchronous; it does not guarantee a step will be canceled, even if the request is successfully submitted. You can only cancel steps that are in a <code>PENDING</code> state.
  ##   body: JObject (required)
  var body_601096 = newJObject()
  if body != nil:
    body_601096 = body
  result = call_601095.call(nil, nil, nil, nil, body_601096)

var cancelSteps* = Call_CancelSteps_601082(name: "cancelSteps",
                                        meth: HttpMethod.HttpPost,
                                        host: "elasticmapreduce.amazonaws.com", route: "/#X-Amz-Target=ElasticMapReduce.CancelSteps",
                                        validator: validate_CancelSteps_601083,
                                        base: "/", url: url_CancelSteps_601084,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSecurityConfiguration_601097 = ref object of OpenApiRestCall_600426
proc url_CreateSecurityConfiguration_601099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSecurityConfiguration_601098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a security configuration, which is stored in the service and can be specified when a cluster is created.
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
      "ElasticMapReduce.CreateSecurityConfiguration"))
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

proc call*(call_601109: Call_CreateSecurityConfiguration_601097; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a security configuration, which is stored in the service and can be specified when a cluster is created.
  ## 
  let valid = call_601109.validator(path, query, header, formData, body)
  let scheme = call_601109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601109.url(scheme.get, call_601109.host, call_601109.base,
                         call_601109.route, valid.getOrDefault("path"))
  result = hook(call_601109, url, valid)

proc call*(call_601110: Call_CreateSecurityConfiguration_601097; body: JsonNode): Recallable =
  ## createSecurityConfiguration
  ## Creates a security configuration, which is stored in the service and can be specified when a cluster is created.
  ##   body: JObject (required)
  var body_601111 = newJObject()
  if body != nil:
    body_601111 = body
  result = call_601110.call(nil, nil, nil, nil, body_601111)

var createSecurityConfiguration* = Call_CreateSecurityConfiguration_601097(
    name: "createSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.CreateSecurityConfiguration",
    validator: validate_CreateSecurityConfiguration_601098, base: "/",
    url: url_CreateSecurityConfiguration_601099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSecurityConfiguration_601112 = ref object of OpenApiRestCall_600426
proc url_DeleteSecurityConfiguration_601114(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSecurityConfiguration_601113(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a security configuration.
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
      "ElasticMapReduce.DeleteSecurityConfiguration"))
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

proc call*(call_601124: Call_DeleteSecurityConfiguration_601112; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a security configuration.
  ## 
  let valid = call_601124.validator(path, query, header, formData, body)
  let scheme = call_601124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601124.url(scheme.get, call_601124.host, call_601124.base,
                         call_601124.route, valid.getOrDefault("path"))
  result = hook(call_601124, url, valid)

proc call*(call_601125: Call_DeleteSecurityConfiguration_601112; body: JsonNode): Recallable =
  ## deleteSecurityConfiguration
  ## Deletes a security configuration.
  ##   body: JObject (required)
  var body_601126 = newJObject()
  if body != nil:
    body_601126 = body
  result = call_601125.call(nil, nil, nil, nil, body_601126)

var deleteSecurityConfiguration* = Call_DeleteSecurityConfiguration_601112(
    name: "deleteSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.DeleteSecurityConfiguration",
    validator: validate_DeleteSecurityConfiguration_601113, base: "/",
    url: url_DeleteSecurityConfiguration_601114,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_601127 = ref object of OpenApiRestCall_600426
proc url_DescribeCluster_601129(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeCluster_601128(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Provides cluster-level details including status, hardware and software configuration, VPC settings, and so on. 
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
      "ElasticMapReduce.DescribeCluster"))
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

proc call*(call_601139: Call_DescribeCluster_601127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides cluster-level details including status, hardware and software configuration, VPC settings, and so on. 
  ## 
  let valid = call_601139.validator(path, query, header, formData, body)
  let scheme = call_601139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601139.url(scheme.get, call_601139.host, call_601139.base,
                         call_601139.route, valid.getOrDefault("path"))
  result = hook(call_601139, url, valid)

proc call*(call_601140: Call_DescribeCluster_601127; body: JsonNode): Recallable =
  ## describeCluster
  ## Provides cluster-level details including status, hardware and software configuration, VPC settings, and so on. 
  ##   body: JObject (required)
  var body_601141 = newJObject()
  if body != nil:
    body_601141 = body
  result = call_601140.call(nil, nil, nil, nil, body_601141)

var describeCluster* = Call_DescribeCluster_601127(name: "describeCluster",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.DescribeCluster",
    validator: validate_DescribeCluster_601128, base: "/", url: url_DescribeCluster_601129,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeJobFlows_601142 = ref object of OpenApiRestCall_600426
proc url_DescribeJobFlows_601144(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeJobFlows_601143(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>This API is deprecated and will eventually be removed. We recommend you use <a>ListClusters</a>, <a>DescribeCluster</a>, <a>ListSteps</a>, <a>ListInstanceGroups</a> and <a>ListBootstrapActions</a> instead.</p> <p>DescribeJobFlows returns a list of job flows that match all of the supplied parameters. The parameters can include a list of job flow IDs, job flow states, and restrictions on job flow creation date and time.</p> <p>Regardless of supplied parameters, only job flows created within the last two months are returned.</p> <p>If no parameters are supplied, then job flows matching either of the following criteria are returned:</p> <ul> <li> <p>Job flows created and completed in the last two weeks</p> </li> <li> <p> Job flows created within the last two months that are in one of the following states: <code>RUNNING</code>, <code>WAITING</code>, <code>SHUTTING_DOWN</code>, <code>STARTING</code> </p> </li> </ul> <p>Amazon EMR can return a maximum of 512 job flow descriptions.</p>
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
      "ElasticMapReduce.DescribeJobFlows"))
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

proc call*(call_601154: Call_DescribeJobFlows_601142; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>This API is deprecated and will eventually be removed. We recommend you use <a>ListClusters</a>, <a>DescribeCluster</a>, <a>ListSteps</a>, <a>ListInstanceGroups</a> and <a>ListBootstrapActions</a> instead.</p> <p>DescribeJobFlows returns a list of job flows that match all of the supplied parameters. The parameters can include a list of job flow IDs, job flow states, and restrictions on job flow creation date and time.</p> <p>Regardless of supplied parameters, only job flows created within the last two months are returned.</p> <p>If no parameters are supplied, then job flows matching either of the following criteria are returned:</p> <ul> <li> <p>Job flows created and completed in the last two weeks</p> </li> <li> <p> Job flows created within the last two months that are in one of the following states: <code>RUNNING</code>, <code>WAITING</code>, <code>SHUTTING_DOWN</code>, <code>STARTING</code> </p> </li> </ul> <p>Amazon EMR can return a maximum of 512 job flow descriptions.</p>
  ## 
  let valid = call_601154.validator(path, query, header, formData, body)
  let scheme = call_601154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601154.url(scheme.get, call_601154.host, call_601154.base,
                         call_601154.route, valid.getOrDefault("path"))
  result = hook(call_601154, url, valid)

proc call*(call_601155: Call_DescribeJobFlows_601142; body: JsonNode): Recallable =
  ## describeJobFlows
  ## <p>This API is deprecated and will eventually be removed. We recommend you use <a>ListClusters</a>, <a>DescribeCluster</a>, <a>ListSteps</a>, <a>ListInstanceGroups</a> and <a>ListBootstrapActions</a> instead.</p> <p>DescribeJobFlows returns a list of job flows that match all of the supplied parameters. The parameters can include a list of job flow IDs, job flow states, and restrictions on job flow creation date and time.</p> <p>Regardless of supplied parameters, only job flows created within the last two months are returned.</p> <p>If no parameters are supplied, then job flows matching either of the following criteria are returned:</p> <ul> <li> <p>Job flows created and completed in the last two weeks</p> </li> <li> <p> Job flows created within the last two months that are in one of the following states: <code>RUNNING</code>, <code>WAITING</code>, <code>SHUTTING_DOWN</code>, <code>STARTING</code> </p> </li> </ul> <p>Amazon EMR can return a maximum of 512 job flow descriptions.</p>
  ##   body: JObject (required)
  var body_601156 = newJObject()
  if body != nil:
    body_601156 = body
  result = call_601155.call(nil, nil, nil, nil, body_601156)

var describeJobFlows* = Call_DescribeJobFlows_601142(name: "describeJobFlows",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.DescribeJobFlows",
    validator: validate_DescribeJobFlows_601143, base: "/",
    url: url_DescribeJobFlows_601144, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSecurityConfiguration_601157 = ref object of OpenApiRestCall_600426
proc url_DescribeSecurityConfiguration_601159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSecurityConfiguration_601158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides the details of a security configuration by returning the configuration JSON.
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
      "ElasticMapReduce.DescribeSecurityConfiguration"))
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

proc call*(call_601169: Call_DescribeSecurityConfiguration_601157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the details of a security configuration by returning the configuration JSON.
  ## 
  let valid = call_601169.validator(path, query, header, formData, body)
  let scheme = call_601169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601169.url(scheme.get, call_601169.host, call_601169.base,
                         call_601169.route, valid.getOrDefault("path"))
  result = hook(call_601169, url, valid)

proc call*(call_601170: Call_DescribeSecurityConfiguration_601157; body: JsonNode): Recallable =
  ## describeSecurityConfiguration
  ## Provides the details of a security configuration by returning the configuration JSON.
  ##   body: JObject (required)
  var body_601171 = newJObject()
  if body != nil:
    body_601171 = body
  result = call_601170.call(nil, nil, nil, nil, body_601171)

var describeSecurityConfiguration* = Call_DescribeSecurityConfiguration_601157(
    name: "describeSecurityConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.DescribeSecurityConfiguration",
    validator: validate_DescribeSecurityConfiguration_601158, base: "/",
    url: url_DescribeSecurityConfiguration_601159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeStep_601172 = ref object of OpenApiRestCall_600426
proc url_DescribeStep_601174(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeStep_601173(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides more detail about the cluster step.
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
      "ElasticMapReduce.DescribeStep"))
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

proc call*(call_601184: Call_DescribeStep_601172; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides more detail about the cluster step.
  ## 
  let valid = call_601184.validator(path, query, header, formData, body)
  let scheme = call_601184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601184.url(scheme.get, call_601184.host, call_601184.base,
                         call_601184.route, valid.getOrDefault("path"))
  result = hook(call_601184, url, valid)

proc call*(call_601185: Call_DescribeStep_601172; body: JsonNode): Recallable =
  ## describeStep
  ## Provides more detail about the cluster step.
  ##   body: JObject (required)
  var body_601186 = newJObject()
  if body != nil:
    body_601186 = body
  result = call_601185.call(nil, nil, nil, nil, body_601186)

var describeStep* = Call_DescribeStep_601172(name: "describeStep",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.DescribeStep",
    validator: validate_DescribeStep_601173, base: "/", url: url_DescribeStep_601174,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetBlockPublicAccessConfiguration_601187 = ref object of OpenApiRestCall_600426
proc url_GetBlockPublicAccessConfiguration_601189(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetBlockPublicAccessConfiguration_601188(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns the Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
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
      "ElasticMapReduce.GetBlockPublicAccessConfiguration"))
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

proc call*(call_601199: Call_GetBlockPublicAccessConfiguration_601187;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Returns the Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
  ## 
  let valid = call_601199.validator(path, query, header, formData, body)
  let scheme = call_601199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601199.url(scheme.get, call_601199.host, call_601199.base,
                         call_601199.route, valid.getOrDefault("path"))
  result = hook(call_601199, url, valid)

proc call*(call_601200: Call_GetBlockPublicAccessConfiguration_601187;
          body: JsonNode): Recallable =
  ## getBlockPublicAccessConfiguration
  ## Returns the Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
  ##   body: JObject (required)
  var body_601201 = newJObject()
  if body != nil:
    body_601201 = body
  result = call_601200.call(nil, nil, nil, nil, body_601201)

var getBlockPublicAccessConfiguration* = Call_GetBlockPublicAccessConfiguration_601187(
    name: "getBlockPublicAccessConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.GetBlockPublicAccessConfiguration",
    validator: validate_GetBlockPublicAccessConfiguration_601188, base: "/",
    url: url_GetBlockPublicAccessConfiguration_601189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListBootstrapActions_601202 = ref object of OpenApiRestCall_600426
proc url_ListBootstrapActions_601204(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListBootstrapActions_601203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information about the bootstrap actions associated with a cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601205 = query.getOrDefault("Marker")
  valid_601205 = validateParameter(valid_601205, JString, required = false,
                                 default = nil)
  if valid_601205 != nil:
    section.add "Marker", valid_601205
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
  var valid_601206 = header.getOrDefault("X-Amz-Date")
  valid_601206 = validateParameter(valid_601206, JString, required = false,
                                 default = nil)
  if valid_601206 != nil:
    section.add "X-Amz-Date", valid_601206
  var valid_601207 = header.getOrDefault("X-Amz-Security-Token")
  valid_601207 = validateParameter(valid_601207, JString, required = false,
                                 default = nil)
  if valid_601207 != nil:
    section.add "X-Amz-Security-Token", valid_601207
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601208 = header.getOrDefault("X-Amz-Target")
  valid_601208 = validateParameter(valid_601208, JString, required = true, default = newJString(
      "ElasticMapReduce.ListBootstrapActions"))
  if valid_601208 != nil:
    section.add "X-Amz-Target", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Content-Sha256", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Algorithm")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Algorithm", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Signature")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Signature", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-SignedHeaders", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-Credential")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Credential", valid_601213
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601215: Call_ListBootstrapActions_601202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information about the bootstrap actions associated with a cluster.
  ## 
  let valid = call_601215.validator(path, query, header, formData, body)
  let scheme = call_601215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601215.url(scheme.get, call_601215.host, call_601215.base,
                         call_601215.route, valid.getOrDefault("path"))
  result = hook(call_601215, url, valid)

proc call*(call_601216: Call_ListBootstrapActions_601202; body: JsonNode;
          Marker: string = ""): Recallable =
  ## listBootstrapActions
  ## Provides information about the bootstrap actions associated with a cluster.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601217 = newJObject()
  var body_601218 = newJObject()
  add(query_601217, "Marker", newJString(Marker))
  if body != nil:
    body_601218 = body
  result = call_601216.call(nil, query_601217, nil, nil, body_601218)

var listBootstrapActions* = Call_ListBootstrapActions_601202(
    name: "listBootstrapActions", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListBootstrapActions",
    validator: validate_ListBootstrapActions_601203, base: "/",
    url: url_ListBootstrapActions_601204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_601220 = ref object of OpenApiRestCall_600426
proc url_ListClusters_601222(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListClusters_601221(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides the status of all clusters visible to this AWS account. Allows you to filter the list of clusters based on certain criteria; for example, filtering by cluster creation date and time or by status. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListClusters calls.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601223 = query.getOrDefault("Marker")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "Marker", valid_601223
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
  var valid_601224 = header.getOrDefault("X-Amz-Date")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Date", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Security-Token")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Security-Token", valid_601225
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601226 = header.getOrDefault("X-Amz-Target")
  valid_601226 = validateParameter(valid_601226, JString, required = true, default = newJString(
      "ElasticMapReduce.ListClusters"))
  if valid_601226 != nil:
    section.add "X-Amz-Target", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-Content-Sha256", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Algorithm")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Algorithm", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Signature")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Signature", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-SignedHeaders", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Credential")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Credential", valid_601231
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601233: Call_ListClusters_601220; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides the status of all clusters visible to this AWS account. Allows you to filter the list of clusters based on certain criteria; for example, filtering by cluster creation date and time or by status. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListClusters calls.
  ## 
  let valid = call_601233.validator(path, query, header, formData, body)
  let scheme = call_601233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601233.url(scheme.get, call_601233.host, call_601233.base,
                         call_601233.route, valid.getOrDefault("path"))
  result = hook(call_601233, url, valid)

proc call*(call_601234: Call_ListClusters_601220; body: JsonNode; Marker: string = ""): Recallable =
  ## listClusters
  ## Provides the status of all clusters visible to this AWS account. Allows you to filter the list of clusters based on certain criteria; for example, filtering by cluster creation date and time or by status. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListClusters calls.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601235 = newJObject()
  var body_601236 = newJObject()
  add(query_601235, "Marker", newJString(Marker))
  if body != nil:
    body_601236 = body
  result = call_601234.call(nil, query_601235, nil, nil, body_601236)

var listClusters* = Call_ListClusters_601220(name: "listClusters",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListClusters",
    validator: validate_ListClusters_601221, base: "/", url: url_ListClusters_601222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceFleets_601237 = ref object of OpenApiRestCall_600426
proc url_ListInstanceFleets_601239(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInstanceFleets_601238(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Lists all available details about the instance fleets in a cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601240 = query.getOrDefault("Marker")
  valid_601240 = validateParameter(valid_601240, JString, required = false,
                                 default = nil)
  if valid_601240 != nil:
    section.add "Marker", valid_601240
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
  var valid_601241 = header.getOrDefault("X-Amz-Date")
  valid_601241 = validateParameter(valid_601241, JString, required = false,
                                 default = nil)
  if valid_601241 != nil:
    section.add "X-Amz-Date", valid_601241
  var valid_601242 = header.getOrDefault("X-Amz-Security-Token")
  valid_601242 = validateParameter(valid_601242, JString, required = false,
                                 default = nil)
  if valid_601242 != nil:
    section.add "X-Amz-Security-Token", valid_601242
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601243 = header.getOrDefault("X-Amz-Target")
  valid_601243 = validateParameter(valid_601243, JString, required = true, default = newJString(
      "ElasticMapReduce.ListInstanceFleets"))
  if valid_601243 != nil:
    section.add "X-Amz-Target", valid_601243
  var valid_601244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601244 = validateParameter(valid_601244, JString, required = false,
                                 default = nil)
  if valid_601244 != nil:
    section.add "X-Amz-Content-Sha256", valid_601244
  var valid_601245 = header.getOrDefault("X-Amz-Algorithm")
  valid_601245 = validateParameter(valid_601245, JString, required = false,
                                 default = nil)
  if valid_601245 != nil:
    section.add "X-Amz-Algorithm", valid_601245
  var valid_601246 = header.getOrDefault("X-Amz-Signature")
  valid_601246 = validateParameter(valid_601246, JString, required = false,
                                 default = nil)
  if valid_601246 != nil:
    section.add "X-Amz-Signature", valid_601246
  var valid_601247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-SignedHeaders", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Credential")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Credential", valid_601248
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601250: Call_ListInstanceFleets_601237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Lists all available details about the instance fleets in a cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
  ## 
  let valid = call_601250.validator(path, query, header, formData, body)
  let scheme = call_601250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601250.url(scheme.get, call_601250.host, call_601250.base,
                         call_601250.route, valid.getOrDefault("path"))
  result = hook(call_601250, url, valid)

proc call*(call_601251: Call_ListInstanceFleets_601237; body: JsonNode;
          Marker: string = ""): Recallable =
  ## listInstanceFleets
  ## <p>Lists all available details about the instance fleets in a cluster.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601252 = newJObject()
  var body_601253 = newJObject()
  add(query_601252, "Marker", newJString(Marker))
  if body != nil:
    body_601253 = body
  result = call_601251.call(nil, query_601252, nil, nil, body_601253)

var listInstanceFleets* = Call_ListInstanceFleets_601237(
    name: "listInstanceFleets", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListInstanceFleets",
    validator: validate_ListInstanceFleets_601238, base: "/",
    url: url_ListInstanceFleets_601239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstanceGroups_601254 = ref object of OpenApiRestCall_600426
proc url_ListInstanceGroups_601256(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInstanceGroups_601255(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Provides all available details about the instance groups in a cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601257 = query.getOrDefault("Marker")
  valid_601257 = validateParameter(valid_601257, JString, required = false,
                                 default = nil)
  if valid_601257 != nil:
    section.add "Marker", valid_601257
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
  var valid_601258 = header.getOrDefault("X-Amz-Date")
  valid_601258 = validateParameter(valid_601258, JString, required = false,
                                 default = nil)
  if valid_601258 != nil:
    section.add "X-Amz-Date", valid_601258
  var valid_601259 = header.getOrDefault("X-Amz-Security-Token")
  valid_601259 = validateParameter(valid_601259, JString, required = false,
                                 default = nil)
  if valid_601259 != nil:
    section.add "X-Amz-Security-Token", valid_601259
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601260 = header.getOrDefault("X-Amz-Target")
  valid_601260 = validateParameter(valid_601260, JString, required = true, default = newJString(
      "ElasticMapReduce.ListInstanceGroups"))
  if valid_601260 != nil:
    section.add "X-Amz-Target", valid_601260
  var valid_601261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601261 = validateParameter(valid_601261, JString, required = false,
                                 default = nil)
  if valid_601261 != nil:
    section.add "X-Amz-Content-Sha256", valid_601261
  var valid_601262 = header.getOrDefault("X-Amz-Algorithm")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Algorithm", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Signature")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Signature", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-SignedHeaders", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Credential")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Credential", valid_601265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601267: Call_ListInstanceGroups_601254; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides all available details about the instance groups in a cluster.
  ## 
  let valid = call_601267.validator(path, query, header, formData, body)
  let scheme = call_601267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601267.url(scheme.get, call_601267.host, call_601267.base,
                         call_601267.route, valid.getOrDefault("path"))
  result = hook(call_601267, url, valid)

proc call*(call_601268: Call_ListInstanceGroups_601254; body: JsonNode;
          Marker: string = ""): Recallable =
  ## listInstanceGroups
  ## Provides all available details about the instance groups in a cluster.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601269 = newJObject()
  var body_601270 = newJObject()
  add(query_601269, "Marker", newJString(Marker))
  if body != nil:
    body_601270 = body
  result = call_601268.call(nil, query_601269, nil, nil, body_601270)

var listInstanceGroups* = Call_ListInstanceGroups_601254(
    name: "listInstanceGroups", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListInstanceGroups",
    validator: validate_ListInstanceGroups_601255, base: "/",
    url: url_ListInstanceGroups_601256, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInstances_601271 = ref object of OpenApiRestCall_600426
proc url_ListInstances_601273(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListInstances_601272(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides information for all active EC2 instances and EC2 instances terminated in the last 30 days, up to a maximum of 2,000. EC2 instances in any of the following states are considered active: AWAITING_FULFILLMENT, PROVISIONING, BOOTSTRAPPING, RUNNING.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601274 = query.getOrDefault("Marker")
  valid_601274 = validateParameter(valid_601274, JString, required = false,
                                 default = nil)
  if valid_601274 != nil:
    section.add "Marker", valid_601274
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
  var valid_601275 = header.getOrDefault("X-Amz-Date")
  valid_601275 = validateParameter(valid_601275, JString, required = false,
                                 default = nil)
  if valid_601275 != nil:
    section.add "X-Amz-Date", valid_601275
  var valid_601276 = header.getOrDefault("X-Amz-Security-Token")
  valid_601276 = validateParameter(valid_601276, JString, required = false,
                                 default = nil)
  if valid_601276 != nil:
    section.add "X-Amz-Security-Token", valid_601276
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601277 = header.getOrDefault("X-Amz-Target")
  valid_601277 = validateParameter(valid_601277, JString, required = true, default = newJString(
      "ElasticMapReduce.ListInstances"))
  if valid_601277 != nil:
    section.add "X-Amz-Target", valid_601277
  var valid_601278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Content-Sha256", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Algorithm")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Algorithm", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Signature")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Signature", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-SignedHeaders", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Credential")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Credential", valid_601282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601284: Call_ListInstances_601271; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides information for all active EC2 instances and EC2 instances terminated in the last 30 days, up to a maximum of 2,000. EC2 instances in any of the following states are considered active: AWAITING_FULFILLMENT, PROVISIONING, BOOTSTRAPPING, RUNNING.
  ## 
  let valid = call_601284.validator(path, query, header, formData, body)
  let scheme = call_601284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601284.url(scheme.get, call_601284.host, call_601284.base,
                         call_601284.route, valid.getOrDefault("path"))
  result = hook(call_601284, url, valid)

proc call*(call_601285: Call_ListInstances_601271; body: JsonNode;
          Marker: string = ""): Recallable =
  ## listInstances
  ## Provides information for all active EC2 instances and EC2 instances terminated in the last 30 days, up to a maximum of 2,000. EC2 instances in any of the following states are considered active: AWAITING_FULFILLMENT, PROVISIONING, BOOTSTRAPPING, RUNNING.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601286 = newJObject()
  var body_601287 = newJObject()
  add(query_601286, "Marker", newJString(Marker))
  if body != nil:
    body_601287 = body
  result = call_601285.call(nil, query_601286, nil, nil, body_601287)

var listInstances* = Call_ListInstances_601271(name: "listInstances",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListInstances",
    validator: validate_ListInstances_601272, base: "/", url: url_ListInstances_601273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSecurityConfigurations_601288 = ref object of OpenApiRestCall_600426
proc url_ListSecurityConfigurations_601290(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSecurityConfigurations_601289(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists all the security configurations visible to this account, providing their creation dates and times, and their names. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListSecurityConfigurations calls.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601291 = query.getOrDefault("Marker")
  valid_601291 = validateParameter(valid_601291, JString, required = false,
                                 default = nil)
  if valid_601291 != nil:
    section.add "Marker", valid_601291
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
  var valid_601292 = header.getOrDefault("X-Amz-Date")
  valid_601292 = validateParameter(valid_601292, JString, required = false,
                                 default = nil)
  if valid_601292 != nil:
    section.add "X-Amz-Date", valid_601292
  var valid_601293 = header.getOrDefault("X-Amz-Security-Token")
  valid_601293 = validateParameter(valid_601293, JString, required = false,
                                 default = nil)
  if valid_601293 != nil:
    section.add "X-Amz-Security-Token", valid_601293
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601294 = header.getOrDefault("X-Amz-Target")
  valid_601294 = validateParameter(valid_601294, JString, required = true, default = newJString(
      "ElasticMapReduce.ListSecurityConfigurations"))
  if valid_601294 != nil:
    section.add "X-Amz-Target", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Content-Sha256", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Algorithm")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Algorithm", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Signature")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Signature", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-SignedHeaders", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Credential")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Credential", valid_601299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601301: Call_ListSecurityConfigurations_601288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all the security configurations visible to this account, providing their creation dates and times, and their names. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListSecurityConfigurations calls.
  ## 
  let valid = call_601301.validator(path, query, header, formData, body)
  let scheme = call_601301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601301.url(scheme.get, call_601301.host, call_601301.base,
                         call_601301.route, valid.getOrDefault("path"))
  result = hook(call_601301, url, valid)

proc call*(call_601302: Call_ListSecurityConfigurations_601288; body: JsonNode;
          Marker: string = ""): Recallable =
  ## listSecurityConfigurations
  ## Lists all the security configurations visible to this account, providing their creation dates and times, and their names. This call returns a maximum of 50 clusters per call, but returns a marker to track the paging of the cluster list across multiple ListSecurityConfigurations calls.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601303 = newJObject()
  var body_601304 = newJObject()
  add(query_601303, "Marker", newJString(Marker))
  if body != nil:
    body_601304 = body
  result = call_601302.call(nil, query_601303, nil, nil, body_601304)

var listSecurityConfigurations* = Call_ListSecurityConfigurations_601288(
    name: "listSecurityConfigurations", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ListSecurityConfigurations",
    validator: validate_ListSecurityConfigurations_601289, base: "/",
    url: url_ListSecurityConfigurations_601290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSteps_601305 = ref object of OpenApiRestCall_600426
proc url_ListSteps_601307(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSteps_601306(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Provides a list of steps for the cluster in reverse order unless you specify stepIds with the request.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Marker: JString
  ##         : Pagination token
  section = newJObject()
  var valid_601308 = query.getOrDefault("Marker")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "Marker", valid_601308
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
  var valid_601309 = header.getOrDefault("X-Amz-Date")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Date", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Security-Token")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Security-Token", valid_601310
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601311 = header.getOrDefault("X-Amz-Target")
  valid_601311 = validateParameter(valid_601311, JString, required = true, default = newJString(
      "ElasticMapReduce.ListSteps"))
  if valid_601311 != nil:
    section.add "X-Amz-Target", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Content-Sha256", valid_601312
  var valid_601313 = header.getOrDefault("X-Amz-Algorithm")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Algorithm", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Signature")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Signature", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-SignedHeaders", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Credential")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Credential", valid_601316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601318: Call_ListSteps_601305; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Provides a list of steps for the cluster in reverse order unless you specify stepIds with the request.
  ## 
  let valid = call_601318.validator(path, query, header, formData, body)
  let scheme = call_601318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601318.url(scheme.get, call_601318.host, call_601318.base,
                         call_601318.route, valid.getOrDefault("path"))
  result = hook(call_601318, url, valid)

proc call*(call_601319: Call_ListSteps_601305; body: JsonNode; Marker: string = ""): Recallable =
  ## listSteps
  ## Provides a list of steps for the cluster in reverse order unless you specify stepIds with the request.
  ##   Marker: string
  ##         : Pagination token
  ##   body: JObject (required)
  var query_601320 = newJObject()
  var body_601321 = newJObject()
  add(query_601320, "Marker", newJString(Marker))
  if body != nil:
    body_601321 = body
  result = call_601319.call(nil, query_601320, nil, nil, body_601321)

var listSteps* = Call_ListSteps_601305(name: "listSteps", meth: HttpMethod.HttpPost,
                                    host: "elasticmapreduce.amazonaws.com", route: "/#X-Amz-Target=ElasticMapReduce.ListSteps",
                                    validator: validate_ListSteps_601306,
                                    base: "/", url: url_ListSteps_601307,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyInstanceFleet_601322 = ref object of OpenApiRestCall_600426
proc url_ModifyInstanceFleet_601324(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyInstanceFleet_601323(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Modifies the target On-Demand and target Spot capacities for the instance fleet with the specified InstanceFleetID within the cluster specified using ClusterID. The call either succeeds or fails atomically.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
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
      "ElasticMapReduce.ModifyInstanceFleet"))
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

proc call*(call_601334: Call_ModifyInstanceFleet_601322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Modifies the target On-Demand and target Spot capacities for the instance fleet with the specified InstanceFleetID within the cluster specified using ClusterID. The call either succeeds or fails atomically.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
  ## 
  let valid = call_601334.validator(path, query, header, formData, body)
  let scheme = call_601334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601334.url(scheme.get, call_601334.host, call_601334.base,
                         call_601334.route, valid.getOrDefault("path"))
  result = hook(call_601334, url, valid)

proc call*(call_601335: Call_ModifyInstanceFleet_601322; body: JsonNode): Recallable =
  ## modifyInstanceFleet
  ## <p>Modifies the target On-Demand and target Spot capacities for the instance fleet with the specified InstanceFleetID within the cluster specified using ClusterID. The call either succeeds or fails atomically.</p> <note> <p>The instance fleet configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions.</p> </note>
  ##   body: JObject (required)
  var body_601336 = newJObject()
  if body != nil:
    body_601336 = body
  result = call_601335.call(nil, nil, nil, nil, body_601336)

var modifyInstanceFleet* = Call_ModifyInstanceFleet_601322(
    name: "modifyInstanceFleet", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ModifyInstanceFleet",
    validator: validate_ModifyInstanceFleet_601323, base: "/",
    url: url_ModifyInstanceFleet_601324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyInstanceGroups_601337 = ref object of OpenApiRestCall_600426
proc url_ModifyInstanceGroups_601339(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ModifyInstanceGroups_601338(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## ModifyInstanceGroups modifies the number of nodes and configuration settings of an instance group. The input parameters include the new target instance count for the group and the instance group ID. The call will either succeed or fail atomically.
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
      "ElasticMapReduce.ModifyInstanceGroups"))
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

proc call*(call_601349: Call_ModifyInstanceGroups_601337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## ModifyInstanceGroups modifies the number of nodes and configuration settings of an instance group. The input parameters include the new target instance count for the group and the instance group ID. The call will either succeed or fail atomically.
  ## 
  let valid = call_601349.validator(path, query, header, formData, body)
  let scheme = call_601349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601349.url(scheme.get, call_601349.host, call_601349.base,
                         call_601349.route, valid.getOrDefault("path"))
  result = hook(call_601349, url, valid)

proc call*(call_601350: Call_ModifyInstanceGroups_601337; body: JsonNode): Recallable =
  ## modifyInstanceGroups
  ## ModifyInstanceGroups modifies the number of nodes and configuration settings of an instance group. The input parameters include the new target instance count for the group and the instance group ID. The call will either succeed or fail atomically.
  ##   body: JObject (required)
  var body_601351 = newJObject()
  if body != nil:
    body_601351 = body
  result = call_601350.call(nil, nil, nil, nil, body_601351)

var modifyInstanceGroups* = Call_ModifyInstanceGroups_601337(
    name: "modifyInstanceGroups", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.ModifyInstanceGroups",
    validator: validate_ModifyInstanceGroups_601338, base: "/",
    url: url_ModifyInstanceGroups_601339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutAutoScalingPolicy_601352 = ref object of OpenApiRestCall_600426
proc url_PutAutoScalingPolicy_601354(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutAutoScalingPolicy_601353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates an automatic scaling policy for a core instance group or task instance group in an Amazon EMR cluster. The automatic scaling policy defines how an instance group dynamically adds and terminates EC2 instances in response to the value of a CloudWatch metric.
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
      "ElasticMapReduce.PutAutoScalingPolicy"))
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

proc call*(call_601364: Call_PutAutoScalingPolicy_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates or updates an automatic scaling policy for a core instance group or task instance group in an Amazon EMR cluster. The automatic scaling policy defines how an instance group dynamically adds and terminates EC2 instances in response to the value of a CloudWatch metric.
  ## 
  let valid = call_601364.validator(path, query, header, formData, body)
  let scheme = call_601364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601364.url(scheme.get, call_601364.host, call_601364.base,
                         call_601364.route, valid.getOrDefault("path"))
  result = hook(call_601364, url, valid)

proc call*(call_601365: Call_PutAutoScalingPolicy_601352; body: JsonNode): Recallable =
  ## putAutoScalingPolicy
  ## Creates or updates an automatic scaling policy for a core instance group or task instance group in an Amazon EMR cluster. The automatic scaling policy defines how an instance group dynamically adds and terminates EC2 instances in response to the value of a CloudWatch metric.
  ##   body: JObject (required)
  var body_601366 = newJObject()
  if body != nil:
    body_601366 = body
  result = call_601365.call(nil, nil, nil, nil, body_601366)

var putAutoScalingPolicy* = Call_PutAutoScalingPolicy_601352(
    name: "putAutoScalingPolicy", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.PutAutoScalingPolicy",
    validator: validate_PutAutoScalingPolicy_601353, base: "/",
    url: url_PutAutoScalingPolicy_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutBlockPublicAccessConfiguration_601367 = ref object of OpenApiRestCall_600426
proc url_PutBlockPublicAccessConfiguration_601369(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PutBlockPublicAccessConfiguration_601368(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates or updates an Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
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
      "ElasticMapReduce.PutBlockPublicAccessConfiguration"))
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

proc call*(call_601379: Call_PutBlockPublicAccessConfiguration_601367;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates or updates an Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
  ## 
  let valid = call_601379.validator(path, query, header, formData, body)
  let scheme = call_601379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601379.url(scheme.get, call_601379.host, call_601379.base,
                         call_601379.route, valid.getOrDefault("path"))
  result = hook(call_601379, url, valid)

proc call*(call_601380: Call_PutBlockPublicAccessConfiguration_601367;
          body: JsonNode): Recallable =
  ## putBlockPublicAccessConfiguration
  ## Creates or updates an Amazon EMR block public access configuration for your AWS account in the current Region. For more information see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/configure-block-public-access.html">Configure Block Public Access for Amazon EMR</a> in the <i>Amazon EMR Management Guide</i>.
  ##   body: JObject (required)
  var body_601381 = newJObject()
  if body != nil:
    body_601381 = body
  result = call_601380.call(nil, nil, nil, nil, body_601381)

var putBlockPublicAccessConfiguration* = Call_PutBlockPublicAccessConfiguration_601367(
    name: "putBlockPublicAccessConfiguration", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.PutBlockPublicAccessConfiguration",
    validator: validate_PutBlockPublicAccessConfiguration_601368, base: "/",
    url: url_PutBlockPublicAccessConfiguration_601369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveAutoScalingPolicy_601382 = ref object of OpenApiRestCall_600426
proc url_RemoveAutoScalingPolicy_601384(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveAutoScalingPolicy_601383(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an automatic scaling policy from a specified instance group within an EMR cluster.
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
      "ElasticMapReduce.RemoveAutoScalingPolicy"))
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

proc call*(call_601394: Call_RemoveAutoScalingPolicy_601382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an automatic scaling policy from a specified instance group within an EMR cluster.
  ## 
  let valid = call_601394.validator(path, query, header, formData, body)
  let scheme = call_601394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601394.url(scheme.get, call_601394.host, call_601394.base,
                         call_601394.route, valid.getOrDefault("path"))
  result = hook(call_601394, url, valid)

proc call*(call_601395: Call_RemoveAutoScalingPolicy_601382; body: JsonNode): Recallable =
  ## removeAutoScalingPolicy
  ## Removes an automatic scaling policy from a specified instance group within an EMR cluster.
  ##   body: JObject (required)
  var body_601396 = newJObject()
  if body != nil:
    body_601396 = body
  result = call_601395.call(nil, nil, nil, nil, body_601396)

var removeAutoScalingPolicy* = Call_RemoveAutoScalingPolicy_601382(
    name: "removeAutoScalingPolicy", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.RemoveAutoScalingPolicy",
    validator: validate_RemoveAutoScalingPolicy_601383, base: "/",
    url: url_RemoveAutoScalingPolicy_601384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTags_601397 = ref object of OpenApiRestCall_600426
proc url_RemoveTags_601399(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RemoveTags_601398(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes tags from an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. </p> <p>The following example removes the stack tag with value Prod from a cluster:</p>
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
      "ElasticMapReduce.RemoveTags"))
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

proc call*(call_601409: Call_RemoveTags_601397; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes tags from an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. </p> <p>The following example removes the stack tag with value Prod from a cluster:</p>
  ## 
  let valid = call_601409.validator(path, query, header, formData, body)
  let scheme = call_601409.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601409.url(scheme.get, call_601409.host, call_601409.base,
                         call_601409.route, valid.getOrDefault("path"))
  result = hook(call_601409, url, valid)

proc call*(call_601410: Call_RemoveTags_601397; body: JsonNode): Recallable =
  ## removeTags
  ## <p>Removes tags from an Amazon EMR resource. Tags make it easier to associate clusters in various ways, such as grouping clusters to track your Amazon EMR resource allocation costs. For more information, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-tags.html">Tag Clusters</a>. </p> <p>The following example removes the stack tag with value Prod from a cluster:</p>
  ##   body: JObject (required)
  var body_601411 = newJObject()
  if body != nil:
    body_601411 = body
  result = call_601410.call(nil, nil, nil, nil, body_601411)

var removeTags* = Call_RemoveTags_601397(name: "removeTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticmapreduce.amazonaws.com", route: "/#X-Amz-Target=ElasticMapReduce.RemoveTags",
                                      validator: validate_RemoveTags_601398,
                                      base: "/", url: url_RemoveTags_601399,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_RunJobFlow_601412 = ref object of OpenApiRestCall_600426
proc url_RunJobFlow_601414(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RunJobFlow_601413(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>RunJobFlow creates and starts running a new cluster (job flow). The cluster runs the steps specified. After the steps complete, the cluster stops and the HDFS partition is lost. To prevent loss of data, configure the last step of the job flow to store results in Amazon S3. If the <a>JobFlowInstancesConfig</a> <code>KeepJobFlowAliveWhenNoSteps</code> parameter is set to <code>TRUE</code>, the cluster transitions to the WAITING state rather than shutting down after the steps have completed. </p> <p>For additional protection, you can set the <a>JobFlowInstancesConfig</a> <code>TerminationProtected</code> parameter to <code>TRUE</code> to lock the cluster and prevent it from being terminated by API call, user intervention, or in the event of a job flow error.</p> <p>A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using the SSH shell to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>For long running clusters, we recommend that you periodically store your results.</p> <note> <p>The instance fleets configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. The RunJobFlow request can contain InstanceFleets parameters or InstanceGroups parameters, but not both.</p> </note>
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
  var valid_601415 = header.getOrDefault("X-Amz-Date")
  valid_601415 = validateParameter(valid_601415, JString, required = false,
                                 default = nil)
  if valid_601415 != nil:
    section.add "X-Amz-Date", valid_601415
  var valid_601416 = header.getOrDefault("X-Amz-Security-Token")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Security-Token", valid_601416
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601417 = header.getOrDefault("X-Amz-Target")
  valid_601417 = validateParameter(valid_601417, JString, required = true, default = newJString(
      "ElasticMapReduce.RunJobFlow"))
  if valid_601417 != nil:
    section.add "X-Amz-Target", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Content-Sha256", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Algorithm")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Algorithm", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Signature")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Signature", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-SignedHeaders", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Credential")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Credential", valid_601422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601424: Call_RunJobFlow_601412; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>RunJobFlow creates and starts running a new cluster (job flow). The cluster runs the steps specified. After the steps complete, the cluster stops and the HDFS partition is lost. To prevent loss of data, configure the last step of the job flow to store results in Amazon S3. If the <a>JobFlowInstancesConfig</a> <code>KeepJobFlowAliveWhenNoSteps</code> parameter is set to <code>TRUE</code>, the cluster transitions to the WAITING state rather than shutting down after the steps have completed. </p> <p>For additional protection, you can set the <a>JobFlowInstancesConfig</a> <code>TerminationProtected</code> parameter to <code>TRUE</code> to lock the cluster and prevent it from being terminated by API call, user intervention, or in the event of a job flow error.</p> <p>A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using the SSH shell to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>For long running clusters, we recommend that you periodically store your results.</p> <note> <p>The instance fleets configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. The RunJobFlow request can contain InstanceFleets parameters or InstanceGroups parameters, but not both.</p> </note>
  ## 
  let valid = call_601424.validator(path, query, header, formData, body)
  let scheme = call_601424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601424.url(scheme.get, call_601424.host, call_601424.base,
                         call_601424.route, valid.getOrDefault("path"))
  result = hook(call_601424, url, valid)

proc call*(call_601425: Call_RunJobFlow_601412; body: JsonNode): Recallable =
  ## runJobFlow
  ## <p>RunJobFlow creates and starts running a new cluster (job flow). The cluster runs the steps specified. After the steps complete, the cluster stops and the HDFS partition is lost. To prevent loss of data, configure the last step of the job flow to store results in Amazon S3. If the <a>JobFlowInstancesConfig</a> <code>KeepJobFlowAliveWhenNoSteps</code> parameter is set to <code>TRUE</code>, the cluster transitions to the WAITING state rather than shutting down after the steps have completed. </p> <p>For additional protection, you can set the <a>JobFlowInstancesConfig</a> <code>TerminationProtected</code> parameter to <code>TRUE</code> to lock the cluster and prevent it from being terminated by API call, user intervention, or in the event of a job flow error.</p> <p>A maximum of 256 steps are allowed in each job flow.</p> <p>If your cluster is long-running (such as a Hive data warehouse) or complex, you may require more than 256 steps to process your data. You can bypass the 256-step limitation in various ways, including using the SSH shell to connect to the master node and submitting queries directly to the software running on the master node, such as Hive and Hadoop. For more information on how to do this, see <a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/AddMoreThan256Steps.html">Add More than 256 Steps to a Cluster</a> in the <i>Amazon EMR Management Guide</i>.</p> <p>For long running clusters, we recommend that you periodically store your results.</p> <note> <p>The instance fleets configuration is available only in Amazon EMR versions 4.8.0 and later, excluding 5.0.x versions. The RunJobFlow request can contain InstanceFleets parameters or InstanceGroups parameters, but not both.</p> </note>
  ##   body: JObject (required)
  var body_601426 = newJObject()
  if body != nil:
    body_601426 = body
  result = call_601425.call(nil, nil, nil, nil, body_601426)

var runJobFlow* = Call_RunJobFlow_601412(name: "runJobFlow",
                                      meth: HttpMethod.HttpPost,
                                      host: "elasticmapreduce.amazonaws.com", route: "/#X-Amz-Target=ElasticMapReduce.RunJobFlow",
                                      validator: validate_RunJobFlow_601413,
                                      base: "/", url: url_RunJobFlow_601414,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetTerminationProtection_601427 = ref object of OpenApiRestCall_600426
proc url_SetTerminationProtection_601429(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetTerminationProtection_601428(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>SetTerminationProtection locks a cluster (job flow) so the EC2 instances in the cluster cannot be terminated by user intervention, an API call, or in the event of a job-flow error. The cluster still terminates upon successful completion of the job flow. Calling <code>SetTerminationProtection</code> on a cluster is similar to calling the Amazon EC2 <code>DisableAPITermination</code> API on all EC2 instances in a cluster.</p> <p> <code>SetTerminationProtection</code> is used to prevent accidental termination of a cluster and to ensure that in the event of an error, the instances persist so that you can recover any data stored in their ephemeral instance storage.</p> <p> To terminate a cluster that has been locked by setting <code>SetTerminationProtection</code> to <code>true</code>, you must first unlock the job flow by a subsequent call to <code>SetTerminationProtection</code> in which you set the value to <code>false</code>. </p> <p> For more information, see<a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/UsingEMR_TerminationProtection.html">Managing Cluster Termination</a> in the <i>Amazon EMR Management Guide</i>. </p>
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
  var valid_601430 = header.getOrDefault("X-Amz-Date")
  valid_601430 = validateParameter(valid_601430, JString, required = false,
                                 default = nil)
  if valid_601430 != nil:
    section.add "X-Amz-Date", valid_601430
  var valid_601431 = header.getOrDefault("X-Amz-Security-Token")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Security-Token", valid_601431
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601432 = header.getOrDefault("X-Amz-Target")
  valid_601432 = validateParameter(valid_601432, JString, required = true, default = newJString(
      "ElasticMapReduce.SetTerminationProtection"))
  if valid_601432 != nil:
    section.add "X-Amz-Target", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Content-Sha256", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Algorithm")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Algorithm", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Signature")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Signature", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-SignedHeaders", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Credential")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Credential", valid_601437
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_SetTerminationProtection_601427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>SetTerminationProtection locks a cluster (job flow) so the EC2 instances in the cluster cannot be terminated by user intervention, an API call, or in the event of a job-flow error. The cluster still terminates upon successful completion of the job flow. Calling <code>SetTerminationProtection</code> on a cluster is similar to calling the Amazon EC2 <code>DisableAPITermination</code> API on all EC2 instances in a cluster.</p> <p> <code>SetTerminationProtection</code> is used to prevent accidental termination of a cluster and to ensure that in the event of an error, the instances persist so that you can recover any data stored in their ephemeral instance storage.</p> <p> To terminate a cluster that has been locked by setting <code>SetTerminationProtection</code> to <code>true</code>, you must first unlock the job flow by a subsequent call to <code>SetTerminationProtection</code> in which you set the value to <code>false</code>. </p> <p> For more information, see<a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/UsingEMR_TerminationProtection.html">Managing Cluster Termination</a> in the <i>Amazon EMR Management Guide</i>. </p>
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_SetTerminationProtection_601427; body: JsonNode): Recallable =
  ## setTerminationProtection
  ## <p>SetTerminationProtection locks a cluster (job flow) so the EC2 instances in the cluster cannot be terminated by user intervention, an API call, or in the event of a job-flow error. The cluster still terminates upon successful completion of the job flow. Calling <code>SetTerminationProtection</code> on a cluster is similar to calling the Amazon EC2 <code>DisableAPITermination</code> API on all EC2 instances in a cluster.</p> <p> <code>SetTerminationProtection</code> is used to prevent accidental termination of a cluster and to ensure that in the event of an error, the instances persist so that you can recover any data stored in their ephemeral instance storage.</p> <p> To terminate a cluster that has been locked by setting <code>SetTerminationProtection</code> to <code>true</code>, you must first unlock the job flow by a subsequent call to <code>SetTerminationProtection</code> in which you set the value to <code>false</code>. </p> <p> For more information, see<a href="https://docs.aws.amazon.com/emr/latest/ManagementGuide/UsingEMR_TerminationProtection.html">Managing Cluster Termination</a> in the <i>Amazon EMR Management Guide</i>. </p>
  ##   body: JObject (required)
  var body_601441 = newJObject()
  if body != nil:
    body_601441 = body
  result = call_601440.call(nil, nil, nil, nil, body_601441)

var setTerminationProtection* = Call_SetTerminationProtection_601427(
    name: "setTerminationProtection", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.SetTerminationProtection",
    validator: validate_SetTerminationProtection_601428, base: "/",
    url: url_SetTerminationProtection_601429, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SetVisibleToAllUsers_601442 = ref object of OpenApiRestCall_600426
proc url_SetVisibleToAllUsers_601444(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SetVisibleToAllUsers_601443(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p> <i>This member will be deprecated.</i> </p> <p>Sets whether all AWS Identity and Access Management (IAM) users under your account can access the specified clusters (job flows). This action works on running clusters. You can also set the visibility of a cluster when you launch it using the <code>VisibleToAllUsers</code> parameter of <a>RunJobFlow</a>. The SetVisibleToAllUsers action can be called only by an IAM user who created the cluster or the AWS account that owns the cluster.</p>
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
  var valid_601445 = header.getOrDefault("X-Amz-Date")
  valid_601445 = validateParameter(valid_601445, JString, required = false,
                                 default = nil)
  if valid_601445 != nil:
    section.add "X-Amz-Date", valid_601445
  var valid_601446 = header.getOrDefault("X-Amz-Security-Token")
  valid_601446 = validateParameter(valid_601446, JString, required = false,
                                 default = nil)
  if valid_601446 != nil:
    section.add "X-Amz-Security-Token", valid_601446
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601447 = header.getOrDefault("X-Amz-Target")
  valid_601447 = validateParameter(valid_601447, JString, required = true, default = newJString(
      "ElasticMapReduce.SetVisibleToAllUsers"))
  if valid_601447 != nil:
    section.add "X-Amz-Target", valid_601447
  var valid_601448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601448 = validateParameter(valid_601448, JString, required = false,
                                 default = nil)
  if valid_601448 != nil:
    section.add "X-Amz-Content-Sha256", valid_601448
  var valid_601449 = header.getOrDefault("X-Amz-Algorithm")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Algorithm", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Signature")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Signature", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-SignedHeaders", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Credential")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Credential", valid_601452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601454: Call_SetVisibleToAllUsers_601442; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p> <i>This member will be deprecated.</i> </p> <p>Sets whether all AWS Identity and Access Management (IAM) users under your account can access the specified clusters (job flows). This action works on running clusters. You can also set the visibility of a cluster when you launch it using the <code>VisibleToAllUsers</code> parameter of <a>RunJobFlow</a>. The SetVisibleToAllUsers action can be called only by an IAM user who created the cluster or the AWS account that owns the cluster.</p>
  ## 
  let valid = call_601454.validator(path, query, header, formData, body)
  let scheme = call_601454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601454.url(scheme.get, call_601454.host, call_601454.base,
                         call_601454.route, valid.getOrDefault("path"))
  result = hook(call_601454, url, valid)

proc call*(call_601455: Call_SetVisibleToAllUsers_601442; body: JsonNode): Recallable =
  ## setVisibleToAllUsers
  ## <p> <i>This member will be deprecated.</i> </p> <p>Sets whether all AWS Identity and Access Management (IAM) users under your account can access the specified clusters (job flows). This action works on running clusters. You can also set the visibility of a cluster when you launch it using the <code>VisibleToAllUsers</code> parameter of <a>RunJobFlow</a>. The SetVisibleToAllUsers action can be called only by an IAM user who created the cluster or the AWS account that owns the cluster.</p>
  ##   body: JObject (required)
  var body_601456 = newJObject()
  if body != nil:
    body_601456 = body
  result = call_601455.call(nil, nil, nil, nil, body_601456)

var setVisibleToAllUsers* = Call_SetVisibleToAllUsers_601442(
    name: "setVisibleToAllUsers", meth: HttpMethod.HttpPost,
    host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.SetVisibleToAllUsers",
    validator: validate_SetVisibleToAllUsers_601443, base: "/",
    url: url_SetVisibleToAllUsers_601444, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateJobFlows_601457 = ref object of OpenApiRestCall_600426
proc url_TerminateJobFlows_601459(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_TerminateJobFlows_601458(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>TerminateJobFlows shuts a list of clusters (job flows) down. When a job flow is shut down, any step not yet completed is canceled and the EC2 instances on which the cluster is running are stopped. Any log files not already saved are uploaded to Amazon S3 if a LogUri was specified when the cluster was created.</p> <p>The maximum number of clusters allowed is 10. The call to <code>TerminateJobFlows</code> is asynchronous. Depending on the configuration of the cluster, it may take up to 1-5 minutes for the cluster to completely terminate and release allocated resources, such as Amazon EC2 instances.</p>
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
  var valid_601460 = header.getOrDefault("X-Amz-Date")
  valid_601460 = validateParameter(valid_601460, JString, required = false,
                                 default = nil)
  if valid_601460 != nil:
    section.add "X-Amz-Date", valid_601460
  var valid_601461 = header.getOrDefault("X-Amz-Security-Token")
  valid_601461 = validateParameter(valid_601461, JString, required = false,
                                 default = nil)
  if valid_601461 != nil:
    section.add "X-Amz-Security-Token", valid_601461
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601462 = header.getOrDefault("X-Amz-Target")
  valid_601462 = validateParameter(valid_601462, JString, required = true, default = newJString(
      "ElasticMapReduce.TerminateJobFlows"))
  if valid_601462 != nil:
    section.add "X-Amz-Target", valid_601462
  var valid_601463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601463 = validateParameter(valid_601463, JString, required = false,
                                 default = nil)
  if valid_601463 != nil:
    section.add "X-Amz-Content-Sha256", valid_601463
  var valid_601464 = header.getOrDefault("X-Amz-Algorithm")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Algorithm", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Signature")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Signature", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-SignedHeaders", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Credential")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Credential", valid_601467
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601469: Call_TerminateJobFlows_601457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>TerminateJobFlows shuts a list of clusters (job flows) down. When a job flow is shut down, any step not yet completed is canceled and the EC2 instances on which the cluster is running are stopped. Any log files not already saved are uploaded to Amazon S3 if a LogUri was specified when the cluster was created.</p> <p>The maximum number of clusters allowed is 10. The call to <code>TerminateJobFlows</code> is asynchronous. Depending on the configuration of the cluster, it may take up to 1-5 minutes for the cluster to completely terminate and release allocated resources, such as Amazon EC2 instances.</p>
  ## 
  let valid = call_601469.validator(path, query, header, formData, body)
  let scheme = call_601469.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601469.url(scheme.get, call_601469.host, call_601469.base,
                         call_601469.route, valid.getOrDefault("path"))
  result = hook(call_601469, url, valid)

proc call*(call_601470: Call_TerminateJobFlows_601457; body: JsonNode): Recallable =
  ## terminateJobFlows
  ## <p>TerminateJobFlows shuts a list of clusters (job flows) down. When a job flow is shut down, any step not yet completed is canceled and the EC2 instances on which the cluster is running are stopped. Any log files not already saved are uploaded to Amazon S3 if a LogUri was specified when the cluster was created.</p> <p>The maximum number of clusters allowed is 10. The call to <code>TerminateJobFlows</code> is asynchronous. Depending on the configuration of the cluster, it may take up to 1-5 minutes for the cluster to completely terminate and release allocated resources, such as Amazon EC2 instances.</p>
  ##   body: JObject (required)
  var body_601471 = newJObject()
  if body != nil:
    body_601471 = body
  result = call_601470.call(nil, nil, nil, nil, body_601471)

var terminateJobFlows* = Call_TerminateJobFlows_601457(name: "terminateJobFlows",
    meth: HttpMethod.HttpPost, host: "elasticmapreduce.amazonaws.com",
    route: "/#X-Amz-Target=ElasticMapReduce.TerminateJobFlows",
    validator: validate_TerminateJobFlows_601458, base: "/",
    url: url_TerminateJobFlows_601459, schemes: {Scheme.Https, Scheme.Http})
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

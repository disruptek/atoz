
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS RoboMaker
## version: 2018-06-29
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## This section provides documentation for the AWS RoboMaker API operations.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/robomaker/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com", "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com",
                           "us-west-2": "robomaker.us-west-2.amazonaws.com",
                           "eu-west-2": "robomaker.eu-west-2.amazonaws.com", "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com", "eu-central-1": "robomaker.eu-central-1.amazonaws.com",
                           "us-east-2": "robomaker.us-east-2.amazonaws.com",
                           "us-east-1": "robomaker.us-east-1.amazonaws.com", "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "robomaker.ap-south-1.amazonaws.com",
                           "eu-north-1": "robomaker.eu-north-1.amazonaws.com", "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com",
                           "us-west-1": "robomaker.us-west-1.amazonaws.com", "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "robomaker.eu-west-3.amazonaws.com", "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "robomaker.sa-east-1.amazonaws.com",
                           "eu-west-1": "robomaker.eu-west-1.amazonaws.com", "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com", "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com", "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "robomaker.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "robomaker.ap-southeast-1.amazonaws.com",
      "us-west-2": "robomaker.us-west-2.amazonaws.com",
      "eu-west-2": "robomaker.eu-west-2.amazonaws.com",
      "ap-northeast-3": "robomaker.ap-northeast-3.amazonaws.com",
      "eu-central-1": "robomaker.eu-central-1.amazonaws.com",
      "us-east-2": "robomaker.us-east-2.amazonaws.com",
      "us-east-1": "robomaker.us-east-1.amazonaws.com",
      "cn-northwest-1": "robomaker.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "robomaker.ap-south-1.amazonaws.com",
      "eu-north-1": "robomaker.eu-north-1.amazonaws.com",
      "ap-northeast-2": "robomaker.ap-northeast-2.amazonaws.com",
      "us-west-1": "robomaker.us-west-1.amazonaws.com",
      "us-gov-east-1": "robomaker.us-gov-east-1.amazonaws.com",
      "eu-west-3": "robomaker.eu-west-3.amazonaws.com",
      "cn-north-1": "robomaker.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "robomaker.sa-east-1.amazonaws.com",
      "eu-west-1": "robomaker.eu-west-1.amazonaws.com",
      "us-gov-west-1": "robomaker.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "robomaker.ap-southeast-2.amazonaws.com",
      "ca-central-1": "robomaker.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "robomaker"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeSimulationJob_600768 = ref object of OpenApiRestCall_600426
proc url_BatchDescribeSimulationJob_600770(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_BatchDescribeSimulationJob_600769(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes one or more simulation jobs.
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
  var valid_600884 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600884 = validateParameter(valid_600884, JString, required = false,
                                 default = nil)
  if valid_600884 != nil:
    section.add "X-Amz-Content-Sha256", valid_600884
  var valid_600885 = header.getOrDefault("X-Amz-Algorithm")
  valid_600885 = validateParameter(valid_600885, JString, required = false,
                                 default = nil)
  if valid_600885 != nil:
    section.add "X-Amz-Algorithm", valid_600885
  var valid_600886 = header.getOrDefault("X-Amz-Signature")
  valid_600886 = validateParameter(valid_600886, JString, required = false,
                                 default = nil)
  if valid_600886 != nil:
    section.add "X-Amz-Signature", valid_600886
  var valid_600887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600887 = validateParameter(valid_600887, JString, required = false,
                                 default = nil)
  if valid_600887 != nil:
    section.add "X-Amz-SignedHeaders", valid_600887
  var valid_600888 = header.getOrDefault("X-Amz-Credential")
  valid_600888 = validateParameter(valid_600888, JString, required = false,
                                 default = nil)
  if valid_600888 != nil:
    section.add "X-Amz-Credential", valid_600888
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600912: Call_BatchDescribeSimulationJob_600768; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more simulation jobs.
  ## 
  let valid = call_600912.validator(path, query, header, formData, body)
  let scheme = call_600912.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600912.url(scheme.get, call_600912.host, call_600912.base,
                         call_600912.route, valid.getOrDefault("path"))
  result = hook(call_600912, url, valid)

proc call*(call_600983: Call_BatchDescribeSimulationJob_600768; body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_600984 = newJObject()
  if body != nil:
    body_600984 = body
  result = call_600983.call(nil, nil, nil, nil, body_600984)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_600768(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_600769, base: "/",
    url: url_BatchDescribeSimulationJob_600770,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_601023 = ref object of OpenApiRestCall_600426
proc url_CancelDeploymentJob_601025(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelDeploymentJob_601024(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Cancels the specified deployment job.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601026 = header.getOrDefault("X-Amz-Date")
  valid_601026 = validateParameter(valid_601026, JString, required = false,
                                 default = nil)
  if valid_601026 != nil:
    section.add "X-Amz-Date", valid_601026
  var valid_601027 = header.getOrDefault("X-Amz-Security-Token")
  valid_601027 = validateParameter(valid_601027, JString, required = false,
                                 default = nil)
  if valid_601027 != nil:
    section.add "X-Amz-Security-Token", valid_601027
  var valid_601028 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601028 = validateParameter(valid_601028, JString, required = false,
                                 default = nil)
  if valid_601028 != nil:
    section.add "X-Amz-Content-Sha256", valid_601028
  var valid_601029 = header.getOrDefault("X-Amz-Algorithm")
  valid_601029 = validateParameter(valid_601029, JString, required = false,
                                 default = nil)
  if valid_601029 != nil:
    section.add "X-Amz-Algorithm", valid_601029
  var valid_601030 = header.getOrDefault("X-Amz-Signature")
  valid_601030 = validateParameter(valid_601030, JString, required = false,
                                 default = nil)
  if valid_601030 != nil:
    section.add "X-Amz-Signature", valid_601030
  var valid_601031 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601031 = validateParameter(valid_601031, JString, required = false,
                                 default = nil)
  if valid_601031 != nil:
    section.add "X-Amz-SignedHeaders", valid_601031
  var valid_601032 = header.getOrDefault("X-Amz-Credential")
  valid_601032 = validateParameter(valid_601032, JString, required = false,
                                 default = nil)
  if valid_601032 != nil:
    section.add "X-Amz-Credential", valid_601032
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601034: Call_CancelDeploymentJob_601023; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified deployment job.
  ## 
  let valid = call_601034.validator(path, query, header, formData, body)
  let scheme = call_601034.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601034.url(scheme.get, call_601034.host, call_601034.base,
                         call_601034.route, valid.getOrDefault("path"))
  result = hook(call_601034, url, valid)

proc call*(call_601035: Call_CancelDeploymentJob_601023; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_601036 = newJObject()
  if body != nil:
    body_601036 = body
  result = call_601035.call(nil, nil, nil, nil, body_601036)

var cancelDeploymentJob* = Call_CancelDeploymentJob_601023(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_601024, base: "/",
    url: url_CancelDeploymentJob_601025, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_601037 = ref object of OpenApiRestCall_600426
proc url_CancelSimulationJob_601039(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CancelSimulationJob_601038(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Cancels the specified simulation job.
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
  var valid_601042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601042 = validateParameter(valid_601042, JString, required = false,
                                 default = nil)
  if valid_601042 != nil:
    section.add "X-Amz-Content-Sha256", valid_601042
  var valid_601043 = header.getOrDefault("X-Amz-Algorithm")
  valid_601043 = validateParameter(valid_601043, JString, required = false,
                                 default = nil)
  if valid_601043 != nil:
    section.add "X-Amz-Algorithm", valid_601043
  var valid_601044 = header.getOrDefault("X-Amz-Signature")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Signature", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-SignedHeaders", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Credential")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Credential", valid_601046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601048: Call_CancelSimulationJob_601037; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified simulation job.
  ## 
  let valid = call_601048.validator(path, query, header, formData, body)
  let scheme = call_601048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601048.url(scheme.get, call_601048.host, call_601048.base,
                         call_601048.route, valid.getOrDefault("path"))
  result = hook(call_601048, url, valid)

proc call*(call_601049: Call_CancelSimulationJob_601037; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_601050 = newJObject()
  if body != nil:
    body_601050 = body
  result = call_601049.call(nil, nil, nil, nil, body_601050)

var cancelSimulationJob* = Call_CancelSimulationJob_601037(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_601038, base: "/",
    url: url_CancelSimulationJob_601039, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_601051 = ref object of OpenApiRestCall_600426
proc url_CreateDeploymentJob_601053(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateDeploymentJob_601052(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601054 = header.getOrDefault("X-Amz-Date")
  valid_601054 = validateParameter(valid_601054, JString, required = false,
                                 default = nil)
  if valid_601054 != nil:
    section.add "X-Amz-Date", valid_601054
  var valid_601055 = header.getOrDefault("X-Amz-Security-Token")
  valid_601055 = validateParameter(valid_601055, JString, required = false,
                                 default = nil)
  if valid_601055 != nil:
    section.add "X-Amz-Security-Token", valid_601055
  var valid_601056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601056 = validateParameter(valid_601056, JString, required = false,
                                 default = nil)
  if valid_601056 != nil:
    section.add "X-Amz-Content-Sha256", valid_601056
  var valid_601057 = header.getOrDefault("X-Amz-Algorithm")
  valid_601057 = validateParameter(valid_601057, JString, required = false,
                                 default = nil)
  if valid_601057 != nil:
    section.add "X-Amz-Algorithm", valid_601057
  var valid_601058 = header.getOrDefault("X-Amz-Signature")
  valid_601058 = validateParameter(valid_601058, JString, required = false,
                                 default = nil)
  if valid_601058 != nil:
    section.add "X-Amz-Signature", valid_601058
  var valid_601059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "X-Amz-SignedHeaders", valid_601059
  var valid_601060 = header.getOrDefault("X-Amz-Credential")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "X-Amz-Credential", valid_601060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601062: Call_CreateDeploymentJob_601051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_601062.validator(path, query, header, formData, body)
  let scheme = call_601062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601062.url(scheme.get, call_601062.host, call_601062.base,
                         call_601062.route, valid.getOrDefault("path"))
  result = hook(call_601062, url, valid)

proc call*(call_601063: Call_CreateDeploymentJob_601051; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_601064 = newJObject()
  if body != nil:
    body_601064 = body
  result = call_601063.call(nil, nil, nil, nil, body_601064)

var createDeploymentJob* = Call_CreateDeploymentJob_601051(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_601052, base: "/",
    url: url_CreateDeploymentJob_601053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_601065 = ref object of OpenApiRestCall_600426
proc url_CreateFleet_601067(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateFleet_601066(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a fleet, a logical group of robots running the same robot application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601076: Call_CreateFleet_601065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  let valid = call_601076.validator(path, query, header, formData, body)
  let scheme = call_601076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601076.url(scheme.get, call_601076.host, call_601076.base,
                         call_601076.route, valid.getOrDefault("path"))
  result = hook(call_601076, url, valid)

proc call*(call_601077: Call_CreateFleet_601065; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   body: JObject (required)
  var body_601078 = newJObject()
  if body != nil:
    body_601078 = body
  result = call_601077.call(nil, nil, nil, nil, body_601078)

var createFleet* = Call_CreateFleet_601065(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_601066,
                                        base: "/", url: url_CreateFleet_601067,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_601079 = ref object of OpenApiRestCall_600426
proc url_CreateRobot_601081(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRobot_601080(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a robot.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601082 = header.getOrDefault("X-Amz-Date")
  valid_601082 = validateParameter(valid_601082, JString, required = false,
                                 default = nil)
  if valid_601082 != nil:
    section.add "X-Amz-Date", valid_601082
  var valid_601083 = header.getOrDefault("X-Amz-Security-Token")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Security-Token", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Content-Sha256", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Algorithm")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Algorithm", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Signature")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Signature", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-SignedHeaders", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-Credential")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-Credential", valid_601088
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601090: Call_CreateRobot_601079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot.
  ## 
  let valid = call_601090.validator(path, query, header, formData, body)
  let scheme = call_601090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601090.url(scheme.get, call_601090.host, call_601090.base,
                         call_601090.route, valid.getOrDefault("path"))
  result = hook(call_601090, url, valid)

proc call*(call_601091: Call_CreateRobot_601079; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_601092 = newJObject()
  if body != nil:
    body_601092 = body
  result = call_601091.call(nil, nil, nil, nil, body_601092)

var createRobot* = Call_CreateRobot_601079(name: "createRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createRobot",
                                        validator: validate_CreateRobot_601080,
                                        base: "/", url: url_CreateRobot_601081,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_601093 = ref object of OpenApiRestCall_600426
proc url_CreateRobotApplication_601095(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRobotApplication_601094(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a robot application. 
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601096 = header.getOrDefault("X-Amz-Date")
  valid_601096 = validateParameter(valid_601096, JString, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "X-Amz-Date", valid_601096
  var valid_601097 = header.getOrDefault("X-Amz-Security-Token")
  valid_601097 = validateParameter(valid_601097, JString, required = false,
                                 default = nil)
  if valid_601097 != nil:
    section.add "X-Amz-Security-Token", valid_601097
  var valid_601098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601098 = validateParameter(valid_601098, JString, required = false,
                                 default = nil)
  if valid_601098 != nil:
    section.add "X-Amz-Content-Sha256", valid_601098
  var valid_601099 = header.getOrDefault("X-Amz-Algorithm")
  valid_601099 = validateParameter(valid_601099, JString, required = false,
                                 default = nil)
  if valid_601099 != nil:
    section.add "X-Amz-Algorithm", valid_601099
  var valid_601100 = header.getOrDefault("X-Amz-Signature")
  valid_601100 = validateParameter(valid_601100, JString, required = false,
                                 default = nil)
  if valid_601100 != nil:
    section.add "X-Amz-Signature", valid_601100
  var valid_601101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601101 = validateParameter(valid_601101, JString, required = false,
                                 default = nil)
  if valid_601101 != nil:
    section.add "X-Amz-SignedHeaders", valid_601101
  var valid_601102 = header.getOrDefault("X-Amz-Credential")
  valid_601102 = validateParameter(valid_601102, JString, required = false,
                                 default = nil)
  if valid_601102 != nil:
    section.add "X-Amz-Credential", valid_601102
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601104: Call_CreateRobotApplication_601093; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot application. 
  ## 
  let valid = call_601104.validator(path, query, header, formData, body)
  let scheme = call_601104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601104.url(scheme.get, call_601104.host, call_601104.base,
                         call_601104.route, valid.getOrDefault("path"))
  result = hook(call_601104, url, valid)

proc call*(call_601105: Call_CreateRobotApplication_601093; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_601106 = newJObject()
  if body != nil:
    body_601106 = body
  result = call_601105.call(nil, nil, nil, nil, body_601106)

var createRobotApplication* = Call_CreateRobotApplication_601093(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_601094, base: "/",
    url: url_CreateRobotApplication_601095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_601107 = ref object of OpenApiRestCall_600426
proc url_CreateRobotApplicationVersion_601109(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateRobotApplicationVersion_601108(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a version of a robot application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601110 = header.getOrDefault("X-Amz-Date")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Date", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Security-Token")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Security-Token", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Content-Sha256", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Algorithm")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Algorithm", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-Signature")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-Signature", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-SignedHeaders", valid_601115
  var valid_601116 = header.getOrDefault("X-Amz-Credential")
  valid_601116 = validateParameter(valid_601116, JString, required = false,
                                 default = nil)
  if valid_601116 != nil:
    section.add "X-Amz-Credential", valid_601116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601118: Call_CreateRobotApplicationVersion_601107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a robot application.
  ## 
  let valid = call_601118.validator(path, query, header, formData, body)
  let scheme = call_601118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601118.url(scheme.get, call_601118.host, call_601118.base,
                         call_601118.route, valid.getOrDefault("path"))
  result = hook(call_601118, url, valid)

proc call*(call_601119: Call_CreateRobotApplicationVersion_601107; body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_601120 = newJObject()
  if body != nil:
    body_601120 = body
  result = call_601119.call(nil, nil, nil, nil, body_601120)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_601107(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_601108, base: "/",
    url: url_CreateRobotApplicationVersion_601109,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_601121 = ref object of OpenApiRestCall_600426
proc url_CreateSimulationApplication_601123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSimulationApplication_601122(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a simulation application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601124 = header.getOrDefault("X-Amz-Date")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Date", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Security-Token")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Security-Token", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Content-Sha256", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Algorithm")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Algorithm", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Signature")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Signature", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-SignedHeaders", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Credential")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Credential", valid_601130
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601132: Call_CreateSimulationApplication_601121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a simulation application.
  ## 
  let valid = call_601132.validator(path, query, header, formData, body)
  let scheme = call_601132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601132.url(scheme.get, call_601132.host, call_601132.base,
                         call_601132.route, valid.getOrDefault("path"))
  result = hook(call_601132, url, valid)

proc call*(call_601133: Call_CreateSimulationApplication_601121; body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_601134 = newJObject()
  if body != nil:
    body_601134 = body
  result = call_601133.call(nil, nil, nil, nil, body_601134)

var createSimulationApplication* = Call_CreateSimulationApplication_601121(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_601122, base: "/",
    url: url_CreateSimulationApplication_601123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_601135 = ref object of OpenApiRestCall_600426
proc url_CreateSimulationApplicationVersion_601137(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSimulationApplicationVersion_601136(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a simulation application with a specific revision id.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601138 = header.getOrDefault("X-Amz-Date")
  valid_601138 = validateParameter(valid_601138, JString, required = false,
                                 default = nil)
  if valid_601138 != nil:
    section.add "X-Amz-Date", valid_601138
  var valid_601139 = header.getOrDefault("X-Amz-Security-Token")
  valid_601139 = validateParameter(valid_601139, JString, required = false,
                                 default = nil)
  if valid_601139 != nil:
    section.add "X-Amz-Security-Token", valid_601139
  var valid_601140 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601140 = validateParameter(valid_601140, JString, required = false,
                                 default = nil)
  if valid_601140 != nil:
    section.add "X-Amz-Content-Sha256", valid_601140
  var valid_601141 = header.getOrDefault("X-Amz-Algorithm")
  valid_601141 = validateParameter(valid_601141, JString, required = false,
                                 default = nil)
  if valid_601141 != nil:
    section.add "X-Amz-Algorithm", valid_601141
  var valid_601142 = header.getOrDefault("X-Amz-Signature")
  valid_601142 = validateParameter(valid_601142, JString, required = false,
                                 default = nil)
  if valid_601142 != nil:
    section.add "X-Amz-Signature", valid_601142
  var valid_601143 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601143 = validateParameter(valid_601143, JString, required = false,
                                 default = nil)
  if valid_601143 != nil:
    section.add "X-Amz-SignedHeaders", valid_601143
  var valid_601144 = header.getOrDefault("X-Amz-Credential")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Credential", valid_601144
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601146: Call_CreateSimulationApplicationVersion_601135;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a simulation application with a specific revision id.
  ## 
  let valid = call_601146.validator(path, query, header, formData, body)
  let scheme = call_601146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601146.url(scheme.get, call_601146.host, call_601146.base,
                         call_601146.route, valid.getOrDefault("path"))
  result = hook(call_601146, url, valid)

proc call*(call_601147: Call_CreateSimulationApplicationVersion_601135;
          body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_601148 = newJObject()
  if body != nil:
    body_601148 = body
  result = call_601147.call(nil, nil, nil, nil, body_601148)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_601135(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_601136, base: "/",
    url: url_CreateSimulationApplicationVersion_601137,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_601149 = ref object of OpenApiRestCall_600426
proc url_CreateSimulationJob_601151(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_CreateSimulationJob_601150(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601152 = header.getOrDefault("X-Amz-Date")
  valid_601152 = validateParameter(valid_601152, JString, required = false,
                                 default = nil)
  if valid_601152 != nil:
    section.add "X-Amz-Date", valid_601152
  var valid_601153 = header.getOrDefault("X-Amz-Security-Token")
  valid_601153 = validateParameter(valid_601153, JString, required = false,
                                 default = nil)
  if valid_601153 != nil:
    section.add "X-Amz-Security-Token", valid_601153
  var valid_601154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601154 = validateParameter(valid_601154, JString, required = false,
                                 default = nil)
  if valid_601154 != nil:
    section.add "X-Amz-Content-Sha256", valid_601154
  var valid_601155 = header.getOrDefault("X-Amz-Algorithm")
  valid_601155 = validateParameter(valid_601155, JString, required = false,
                                 default = nil)
  if valid_601155 != nil:
    section.add "X-Amz-Algorithm", valid_601155
  var valid_601156 = header.getOrDefault("X-Amz-Signature")
  valid_601156 = validateParameter(valid_601156, JString, required = false,
                                 default = nil)
  if valid_601156 != nil:
    section.add "X-Amz-Signature", valid_601156
  var valid_601157 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601157 = validateParameter(valid_601157, JString, required = false,
                                 default = nil)
  if valid_601157 != nil:
    section.add "X-Amz-SignedHeaders", valid_601157
  var valid_601158 = header.getOrDefault("X-Amz-Credential")
  valid_601158 = validateParameter(valid_601158, JString, required = false,
                                 default = nil)
  if valid_601158 != nil:
    section.add "X-Amz-Credential", valid_601158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601160: Call_CreateSimulationJob_601149; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_601160.validator(path, query, header, formData, body)
  let scheme = call_601160.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601160.url(scheme.get, call_601160.host, call_601160.base,
                         call_601160.route, valid.getOrDefault("path"))
  result = hook(call_601160, url, valid)

proc call*(call_601161: Call_CreateSimulationJob_601149; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_601162 = newJObject()
  if body != nil:
    body_601162 = body
  result = call_601161.call(nil, nil, nil, nil, body_601162)

var createSimulationJob* = Call_CreateSimulationJob_601149(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_601150, base: "/",
    url: url_CreateSimulationJob_601151, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_601163 = ref object of OpenApiRestCall_600426
proc url_DeleteFleet_601165(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteFleet_601164(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a fleet.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601166 = header.getOrDefault("X-Amz-Date")
  valid_601166 = validateParameter(valid_601166, JString, required = false,
                                 default = nil)
  if valid_601166 != nil:
    section.add "X-Amz-Date", valid_601166
  var valid_601167 = header.getOrDefault("X-Amz-Security-Token")
  valid_601167 = validateParameter(valid_601167, JString, required = false,
                                 default = nil)
  if valid_601167 != nil:
    section.add "X-Amz-Security-Token", valid_601167
  var valid_601168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601168 = validateParameter(valid_601168, JString, required = false,
                                 default = nil)
  if valid_601168 != nil:
    section.add "X-Amz-Content-Sha256", valid_601168
  var valid_601169 = header.getOrDefault("X-Amz-Algorithm")
  valid_601169 = validateParameter(valid_601169, JString, required = false,
                                 default = nil)
  if valid_601169 != nil:
    section.add "X-Amz-Algorithm", valid_601169
  var valid_601170 = header.getOrDefault("X-Amz-Signature")
  valid_601170 = validateParameter(valid_601170, JString, required = false,
                                 default = nil)
  if valid_601170 != nil:
    section.add "X-Amz-Signature", valid_601170
  var valid_601171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601171 = validateParameter(valid_601171, JString, required = false,
                                 default = nil)
  if valid_601171 != nil:
    section.add "X-Amz-SignedHeaders", valid_601171
  var valid_601172 = header.getOrDefault("X-Amz-Credential")
  valid_601172 = validateParameter(valid_601172, JString, required = false,
                                 default = nil)
  if valid_601172 != nil:
    section.add "X-Amz-Credential", valid_601172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601174: Call_DeleteFleet_601163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet.
  ## 
  let valid = call_601174.validator(path, query, header, formData, body)
  let scheme = call_601174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601174.url(scheme.get, call_601174.host, call_601174.base,
                         call_601174.route, valid.getOrDefault("path"))
  result = hook(call_601174, url, valid)

proc call*(call_601175: Call_DeleteFleet_601163; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_601176 = newJObject()
  if body != nil:
    body_601176 = body
  result = call_601175.call(nil, nil, nil, nil, body_601176)

var deleteFleet* = Call_DeleteFleet_601163(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_601164,
                                        base: "/", url: url_DeleteFleet_601165,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_601177 = ref object of OpenApiRestCall_600426
proc url_DeleteRobot_601179(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRobot_601178(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a robot.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601180 = header.getOrDefault("X-Amz-Date")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Date", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Security-Token")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Security-Token", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Content-Sha256", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-Algorithm")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-Algorithm", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Signature")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Signature", valid_601184
  var valid_601185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601185 = validateParameter(valid_601185, JString, required = false,
                                 default = nil)
  if valid_601185 != nil:
    section.add "X-Amz-SignedHeaders", valid_601185
  var valid_601186 = header.getOrDefault("X-Amz-Credential")
  valid_601186 = validateParameter(valid_601186, JString, required = false,
                                 default = nil)
  if valid_601186 != nil:
    section.add "X-Amz-Credential", valid_601186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601188: Call_DeleteRobot_601177; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot.
  ## 
  let valid = call_601188.validator(path, query, header, formData, body)
  let scheme = call_601188.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601188.url(scheme.get, call_601188.host, call_601188.base,
                         call_601188.route, valid.getOrDefault("path"))
  result = hook(call_601188, url, valid)

proc call*(call_601189: Call_DeleteRobot_601177; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_601190 = newJObject()
  if body != nil:
    body_601190 = body
  result = call_601189.call(nil, nil, nil, nil, body_601190)

var deleteRobot* = Call_DeleteRobot_601177(name: "deleteRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteRobot",
                                        validator: validate_DeleteRobot_601178,
                                        base: "/", url: url_DeleteRobot_601179,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_601191 = ref object of OpenApiRestCall_600426
proc url_DeleteRobotApplication_601193(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteRobotApplication_601192(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a robot application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601194 = header.getOrDefault("X-Amz-Date")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Date", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Security-Token")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Security-Token", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Content-Sha256", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Algorithm")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Algorithm", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-Signature")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-Signature", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-SignedHeaders", valid_601199
  var valid_601200 = header.getOrDefault("X-Amz-Credential")
  valid_601200 = validateParameter(valid_601200, JString, required = false,
                                 default = nil)
  if valid_601200 != nil:
    section.add "X-Amz-Credential", valid_601200
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_DeleteRobotApplication_601191; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot application.
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_DeleteRobotApplication_601191; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_601204 = newJObject()
  if body != nil:
    body_601204 = body
  result = call_601203.call(nil, nil, nil, nil, body_601204)

var deleteRobotApplication* = Call_DeleteRobotApplication_601191(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_601192, base: "/",
    url: url_DeleteRobotApplication_601193, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_601205 = ref object of OpenApiRestCall_600426
proc url_DeleteSimulationApplication_601207(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeleteSimulationApplication_601206(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a simulation application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601208 = header.getOrDefault("X-Amz-Date")
  valid_601208 = validateParameter(valid_601208, JString, required = false,
                                 default = nil)
  if valid_601208 != nil:
    section.add "X-Amz-Date", valid_601208
  var valid_601209 = header.getOrDefault("X-Amz-Security-Token")
  valid_601209 = validateParameter(valid_601209, JString, required = false,
                                 default = nil)
  if valid_601209 != nil:
    section.add "X-Amz-Security-Token", valid_601209
  var valid_601210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601210 = validateParameter(valid_601210, JString, required = false,
                                 default = nil)
  if valid_601210 != nil:
    section.add "X-Amz-Content-Sha256", valid_601210
  var valid_601211 = header.getOrDefault("X-Amz-Algorithm")
  valid_601211 = validateParameter(valid_601211, JString, required = false,
                                 default = nil)
  if valid_601211 != nil:
    section.add "X-Amz-Algorithm", valid_601211
  var valid_601212 = header.getOrDefault("X-Amz-Signature")
  valid_601212 = validateParameter(valid_601212, JString, required = false,
                                 default = nil)
  if valid_601212 != nil:
    section.add "X-Amz-Signature", valid_601212
  var valid_601213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-SignedHeaders", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Credential")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Credential", valid_601214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601216: Call_DeleteSimulationApplication_601205; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a simulation application.
  ## 
  let valid = call_601216.validator(path, query, header, formData, body)
  let scheme = call_601216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601216.url(scheme.get, call_601216.host, call_601216.base,
                         call_601216.route, valid.getOrDefault("path"))
  result = hook(call_601216, url, valid)

proc call*(call_601217: Call_DeleteSimulationApplication_601205; body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_601218 = newJObject()
  if body != nil:
    body_601218 = body
  result = call_601217.call(nil, nil, nil, nil, body_601218)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_601205(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_601206, base: "/",
    url: url_DeleteSimulationApplication_601207,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_601219 = ref object of OpenApiRestCall_600426
proc url_DeregisterRobot_601221(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DeregisterRobot_601220(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deregisters a robot.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601222 = header.getOrDefault("X-Amz-Date")
  valid_601222 = validateParameter(valid_601222, JString, required = false,
                                 default = nil)
  if valid_601222 != nil:
    section.add "X-Amz-Date", valid_601222
  var valid_601223 = header.getOrDefault("X-Amz-Security-Token")
  valid_601223 = validateParameter(valid_601223, JString, required = false,
                                 default = nil)
  if valid_601223 != nil:
    section.add "X-Amz-Security-Token", valid_601223
  var valid_601224 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601224 = validateParameter(valid_601224, JString, required = false,
                                 default = nil)
  if valid_601224 != nil:
    section.add "X-Amz-Content-Sha256", valid_601224
  var valid_601225 = header.getOrDefault("X-Amz-Algorithm")
  valid_601225 = validateParameter(valid_601225, JString, required = false,
                                 default = nil)
  if valid_601225 != nil:
    section.add "X-Amz-Algorithm", valid_601225
  var valid_601226 = header.getOrDefault("X-Amz-Signature")
  valid_601226 = validateParameter(valid_601226, JString, required = false,
                                 default = nil)
  if valid_601226 != nil:
    section.add "X-Amz-Signature", valid_601226
  var valid_601227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601227 = validateParameter(valid_601227, JString, required = false,
                                 default = nil)
  if valid_601227 != nil:
    section.add "X-Amz-SignedHeaders", valid_601227
  var valid_601228 = header.getOrDefault("X-Amz-Credential")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Credential", valid_601228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601230: Call_DeregisterRobot_601219; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a robot.
  ## 
  let valid = call_601230.validator(path, query, header, formData, body)
  let scheme = call_601230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601230.url(scheme.get, call_601230.host, call_601230.base,
                         call_601230.route, valid.getOrDefault("path"))
  result = hook(call_601230, url, valid)

proc call*(call_601231: Call_DeregisterRobot_601219; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_601232 = newJObject()
  if body != nil:
    body_601232 = body
  result = call_601231.call(nil, nil, nil, nil, body_601232)

var deregisterRobot* = Call_DeregisterRobot_601219(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_601220,
    base: "/", url: url_DeregisterRobot_601221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_601233 = ref object of OpenApiRestCall_600426
proc url_DescribeDeploymentJob_601235(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeDeploymentJob_601234(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a deployment job.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601236 = header.getOrDefault("X-Amz-Date")
  valid_601236 = validateParameter(valid_601236, JString, required = false,
                                 default = nil)
  if valid_601236 != nil:
    section.add "X-Amz-Date", valid_601236
  var valid_601237 = header.getOrDefault("X-Amz-Security-Token")
  valid_601237 = validateParameter(valid_601237, JString, required = false,
                                 default = nil)
  if valid_601237 != nil:
    section.add "X-Amz-Security-Token", valid_601237
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

proc call*(call_601244: Call_DescribeDeploymentJob_601233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a deployment job.
  ## 
  let valid = call_601244.validator(path, query, header, formData, body)
  let scheme = call_601244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601244.url(scheme.get, call_601244.host, call_601244.base,
                         call_601244.route, valid.getOrDefault("path"))
  result = hook(call_601244, url, valid)

proc call*(call_601245: Call_DescribeDeploymentJob_601233; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_601246 = newJObject()
  if body != nil:
    body_601246 = body
  result = call_601245.call(nil, nil, nil, nil, body_601246)

var describeDeploymentJob* = Call_DescribeDeploymentJob_601233(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_601234, base: "/",
    url: url_DescribeDeploymentJob_601235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_601247 = ref object of OpenApiRestCall_600426
proc url_DescribeFleet_601249(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeFleet_601248(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a fleet.
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
  var valid_601252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-Content-Sha256", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Algorithm")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Algorithm", valid_601253
  var valid_601254 = header.getOrDefault("X-Amz-Signature")
  valid_601254 = validateParameter(valid_601254, JString, required = false,
                                 default = nil)
  if valid_601254 != nil:
    section.add "X-Amz-Signature", valid_601254
  var valid_601255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601255 = validateParameter(valid_601255, JString, required = false,
                                 default = nil)
  if valid_601255 != nil:
    section.add "X-Amz-SignedHeaders", valid_601255
  var valid_601256 = header.getOrDefault("X-Amz-Credential")
  valid_601256 = validateParameter(valid_601256, JString, required = false,
                                 default = nil)
  if valid_601256 != nil:
    section.add "X-Amz-Credential", valid_601256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601258: Call_DescribeFleet_601247; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a fleet.
  ## 
  let valid = call_601258.validator(path, query, header, formData, body)
  let scheme = call_601258.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601258.url(scheme.get, call_601258.host, call_601258.base,
                         call_601258.route, valid.getOrDefault("path"))
  result = hook(call_601258, url, valid)

proc call*(call_601259: Call_DescribeFleet_601247; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_601260 = newJObject()
  if body != nil:
    body_601260 = body
  result = call_601259.call(nil, nil, nil, nil, body_601260)

var describeFleet* = Call_DescribeFleet_601247(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_601248, base: "/",
    url: url_DescribeFleet_601249, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_601261 = ref object of OpenApiRestCall_600426
proc url_DescribeRobot_601263(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRobot_601262(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a robot.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601264 = header.getOrDefault("X-Amz-Date")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Date", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Security-Token")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Security-Token", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Content-Sha256", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-Algorithm")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-Algorithm", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Signature")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Signature", valid_601268
  var valid_601269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601269 = validateParameter(valid_601269, JString, required = false,
                                 default = nil)
  if valid_601269 != nil:
    section.add "X-Amz-SignedHeaders", valid_601269
  var valid_601270 = header.getOrDefault("X-Amz-Credential")
  valid_601270 = validateParameter(valid_601270, JString, required = false,
                                 default = nil)
  if valid_601270 != nil:
    section.add "X-Amz-Credential", valid_601270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601272: Call_DescribeRobot_601261; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot.
  ## 
  let valid = call_601272.validator(path, query, header, formData, body)
  let scheme = call_601272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601272.url(scheme.get, call_601272.host, call_601272.base,
                         call_601272.route, valid.getOrDefault("path"))
  result = hook(call_601272, url, valid)

proc call*(call_601273: Call_DescribeRobot_601261; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_601274 = newJObject()
  if body != nil:
    body_601274 = body
  result = call_601273.call(nil, nil, nil, nil, body_601274)

var describeRobot* = Call_DescribeRobot_601261(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_601262, base: "/",
    url: url_DescribeRobot_601263, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_601275 = ref object of OpenApiRestCall_600426
proc url_DescribeRobotApplication_601277(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeRobotApplication_601276(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a robot application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601278 = header.getOrDefault("X-Amz-Date")
  valid_601278 = validateParameter(valid_601278, JString, required = false,
                                 default = nil)
  if valid_601278 != nil:
    section.add "X-Amz-Date", valid_601278
  var valid_601279 = header.getOrDefault("X-Amz-Security-Token")
  valid_601279 = validateParameter(valid_601279, JString, required = false,
                                 default = nil)
  if valid_601279 != nil:
    section.add "X-Amz-Security-Token", valid_601279
  var valid_601280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Content-Sha256", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Algorithm")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Algorithm", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Signature")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Signature", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-SignedHeaders", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Credential")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Credential", valid_601284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601286: Call_DescribeRobotApplication_601275; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot application.
  ## 
  let valid = call_601286.validator(path, query, header, formData, body)
  let scheme = call_601286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601286.url(scheme.get, call_601286.host, call_601286.base,
                         call_601286.route, valid.getOrDefault("path"))
  result = hook(call_601286, url, valid)

proc call*(call_601287: Call_DescribeRobotApplication_601275; body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_601288 = newJObject()
  if body != nil:
    body_601288 = body
  result = call_601287.call(nil, nil, nil, nil, body_601288)

var describeRobotApplication* = Call_DescribeRobotApplication_601275(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_601276, base: "/",
    url: url_DescribeRobotApplication_601277, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_601289 = ref object of OpenApiRestCall_600426
proc url_DescribeSimulationApplication_601291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSimulationApplication_601290(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a simulation application.
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
  var valid_601294 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601294 = validateParameter(valid_601294, JString, required = false,
                                 default = nil)
  if valid_601294 != nil:
    section.add "X-Amz-Content-Sha256", valid_601294
  var valid_601295 = header.getOrDefault("X-Amz-Algorithm")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Algorithm", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Signature")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Signature", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-SignedHeaders", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Credential")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Credential", valid_601298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601300: Call_DescribeSimulationApplication_601289; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation application.
  ## 
  let valid = call_601300.validator(path, query, header, formData, body)
  let scheme = call_601300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601300.url(scheme.get, call_601300.host, call_601300.base,
                         call_601300.route, valid.getOrDefault("path"))
  result = hook(call_601300, url, valid)

proc call*(call_601301: Call_DescribeSimulationApplication_601289; body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_601302 = newJObject()
  if body != nil:
    body_601302 = body
  result = call_601301.call(nil, nil, nil, nil, body_601302)

var describeSimulationApplication* = Call_DescribeSimulationApplication_601289(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_601290, base: "/",
    url: url_DescribeSimulationApplication_601291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_601303 = ref object of OpenApiRestCall_600426
proc url_DescribeSimulationJob_601305(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_DescribeSimulationJob_601304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a simulation job.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601306 = header.getOrDefault("X-Amz-Date")
  valid_601306 = validateParameter(valid_601306, JString, required = false,
                                 default = nil)
  if valid_601306 != nil:
    section.add "X-Amz-Date", valid_601306
  var valid_601307 = header.getOrDefault("X-Amz-Security-Token")
  valid_601307 = validateParameter(valid_601307, JString, required = false,
                                 default = nil)
  if valid_601307 != nil:
    section.add "X-Amz-Security-Token", valid_601307
  var valid_601308 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601308 = validateParameter(valid_601308, JString, required = false,
                                 default = nil)
  if valid_601308 != nil:
    section.add "X-Amz-Content-Sha256", valid_601308
  var valid_601309 = header.getOrDefault("X-Amz-Algorithm")
  valid_601309 = validateParameter(valid_601309, JString, required = false,
                                 default = nil)
  if valid_601309 != nil:
    section.add "X-Amz-Algorithm", valid_601309
  var valid_601310 = header.getOrDefault("X-Amz-Signature")
  valid_601310 = validateParameter(valid_601310, JString, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "X-Amz-Signature", valid_601310
  var valid_601311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601311 = validateParameter(valid_601311, JString, required = false,
                                 default = nil)
  if valid_601311 != nil:
    section.add "X-Amz-SignedHeaders", valid_601311
  var valid_601312 = header.getOrDefault("X-Amz-Credential")
  valid_601312 = validateParameter(valid_601312, JString, required = false,
                                 default = nil)
  if valid_601312 != nil:
    section.add "X-Amz-Credential", valid_601312
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601314: Call_DescribeSimulationJob_601303; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job.
  ## 
  let valid = call_601314.validator(path, query, header, formData, body)
  let scheme = call_601314.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601314.url(scheme.get, call_601314.host, call_601314.base,
                         call_601314.route, valid.getOrDefault("path"))
  result = hook(call_601314, url, valid)

proc call*(call_601315: Call_DescribeSimulationJob_601303; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_601316 = newJObject()
  if body != nil:
    body_601316 = body
  result = call_601315.call(nil, nil, nil, nil, body_601316)

var describeSimulationJob* = Call_DescribeSimulationJob_601303(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_601304, base: "/",
    url: url_DescribeSimulationJob_601305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_601317 = ref object of OpenApiRestCall_600426
proc url_ListDeploymentJobs_601319(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListDeploymentJobs_601318(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601320 = query.getOrDefault("maxResults")
  valid_601320 = validateParameter(valid_601320, JString, required = false,
                                 default = nil)
  if valid_601320 != nil:
    section.add "maxResults", valid_601320
  var valid_601321 = query.getOrDefault("nextToken")
  valid_601321 = validateParameter(valid_601321, JString, required = false,
                                 default = nil)
  if valid_601321 != nil:
    section.add "nextToken", valid_601321
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601322 = header.getOrDefault("X-Amz-Date")
  valid_601322 = validateParameter(valid_601322, JString, required = false,
                                 default = nil)
  if valid_601322 != nil:
    section.add "X-Amz-Date", valid_601322
  var valid_601323 = header.getOrDefault("X-Amz-Security-Token")
  valid_601323 = validateParameter(valid_601323, JString, required = false,
                                 default = nil)
  if valid_601323 != nil:
    section.add "X-Amz-Security-Token", valid_601323
  var valid_601324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601324 = validateParameter(valid_601324, JString, required = false,
                                 default = nil)
  if valid_601324 != nil:
    section.add "X-Amz-Content-Sha256", valid_601324
  var valid_601325 = header.getOrDefault("X-Amz-Algorithm")
  valid_601325 = validateParameter(valid_601325, JString, required = false,
                                 default = nil)
  if valid_601325 != nil:
    section.add "X-Amz-Algorithm", valid_601325
  var valid_601326 = header.getOrDefault("X-Amz-Signature")
  valid_601326 = validateParameter(valid_601326, JString, required = false,
                                 default = nil)
  if valid_601326 != nil:
    section.add "X-Amz-Signature", valid_601326
  var valid_601327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601327 = validateParameter(valid_601327, JString, required = false,
                                 default = nil)
  if valid_601327 != nil:
    section.add "X-Amz-SignedHeaders", valid_601327
  var valid_601328 = header.getOrDefault("X-Amz-Credential")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Credential", valid_601328
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601330: Call_ListDeploymentJobs_601317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  let valid = call_601330.validator(path, query, header, formData, body)
  let scheme = call_601330.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601330.url(scheme.get, call_601330.host, call_601330.base,
                         call_601330.route, valid.getOrDefault("path"))
  result = hook(call_601330, url, valid)

proc call*(call_601331: Call_ListDeploymentJobs_601317; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listDeploymentJobs
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601332 = newJObject()
  var body_601333 = newJObject()
  add(query_601332, "maxResults", newJString(maxResults))
  add(query_601332, "nextToken", newJString(nextToken))
  if body != nil:
    body_601333 = body
  result = call_601331.call(nil, query_601332, nil, nil, body_601333)

var listDeploymentJobs* = Call_ListDeploymentJobs_601317(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_601318, base: "/",
    url: url_ListDeploymentJobs_601319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_601335 = ref object of OpenApiRestCall_600426
proc url_ListFleets_601337(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListFleets_601336(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601338 = query.getOrDefault("maxResults")
  valid_601338 = validateParameter(valid_601338, JString, required = false,
                                 default = nil)
  if valid_601338 != nil:
    section.add "maxResults", valid_601338
  var valid_601339 = query.getOrDefault("nextToken")
  valid_601339 = validateParameter(valid_601339, JString, required = false,
                                 default = nil)
  if valid_601339 != nil:
    section.add "nextToken", valid_601339
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
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
  var valid_601342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601342 = validateParameter(valid_601342, JString, required = false,
                                 default = nil)
  if valid_601342 != nil:
    section.add "X-Amz-Content-Sha256", valid_601342
  var valid_601343 = header.getOrDefault("X-Amz-Algorithm")
  valid_601343 = validateParameter(valid_601343, JString, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "X-Amz-Algorithm", valid_601343
  var valid_601344 = header.getOrDefault("X-Amz-Signature")
  valid_601344 = validateParameter(valid_601344, JString, required = false,
                                 default = nil)
  if valid_601344 != nil:
    section.add "X-Amz-Signature", valid_601344
  var valid_601345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601345 = validateParameter(valid_601345, JString, required = false,
                                 default = nil)
  if valid_601345 != nil:
    section.add "X-Amz-SignedHeaders", valid_601345
  var valid_601346 = header.getOrDefault("X-Amz-Credential")
  valid_601346 = validateParameter(valid_601346, JString, required = false,
                                 default = nil)
  if valid_601346 != nil:
    section.add "X-Amz-Credential", valid_601346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601348: Call_ListFleets_601335; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  let valid = call_601348.validator(path, query, header, formData, body)
  let scheme = call_601348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601348.url(scheme.get, call_601348.host, call_601348.base,
                         call_601348.route, valid.getOrDefault("path"))
  result = hook(call_601348, url, valid)

proc call*(call_601349: Call_ListFleets_601335; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601350 = newJObject()
  var body_601351 = newJObject()
  add(query_601350, "maxResults", newJString(maxResults))
  add(query_601350, "nextToken", newJString(nextToken))
  if body != nil:
    body_601351 = body
  result = call_601349.call(nil, query_601350, nil, nil, body_601351)

var listFleets* = Call_ListFleets_601335(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_601336,
                                      base: "/", url: url_ListFleets_601337,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_601352 = ref object of OpenApiRestCall_600426
proc url_ListRobotApplications_601354(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRobotApplications_601353(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601355 = query.getOrDefault("maxResults")
  valid_601355 = validateParameter(valid_601355, JString, required = false,
                                 default = nil)
  if valid_601355 != nil:
    section.add "maxResults", valid_601355
  var valid_601356 = query.getOrDefault("nextToken")
  valid_601356 = validateParameter(valid_601356, JString, required = false,
                                 default = nil)
  if valid_601356 != nil:
    section.add "nextToken", valid_601356
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601357 = header.getOrDefault("X-Amz-Date")
  valid_601357 = validateParameter(valid_601357, JString, required = false,
                                 default = nil)
  if valid_601357 != nil:
    section.add "X-Amz-Date", valid_601357
  var valid_601358 = header.getOrDefault("X-Amz-Security-Token")
  valid_601358 = validateParameter(valid_601358, JString, required = false,
                                 default = nil)
  if valid_601358 != nil:
    section.add "X-Amz-Security-Token", valid_601358
  var valid_601359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601359 = validateParameter(valid_601359, JString, required = false,
                                 default = nil)
  if valid_601359 != nil:
    section.add "X-Amz-Content-Sha256", valid_601359
  var valid_601360 = header.getOrDefault("X-Amz-Algorithm")
  valid_601360 = validateParameter(valid_601360, JString, required = false,
                                 default = nil)
  if valid_601360 != nil:
    section.add "X-Amz-Algorithm", valid_601360
  var valid_601361 = header.getOrDefault("X-Amz-Signature")
  valid_601361 = validateParameter(valid_601361, JString, required = false,
                                 default = nil)
  if valid_601361 != nil:
    section.add "X-Amz-Signature", valid_601361
  var valid_601362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-SignedHeaders", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Credential")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Credential", valid_601363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601365: Call_ListRobotApplications_601352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  let valid = call_601365.validator(path, query, header, formData, body)
  let scheme = call_601365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601365.url(scheme.get, call_601365.host, call_601365.base,
                         call_601365.route, valid.getOrDefault("path"))
  result = hook(call_601365, url, valid)

proc call*(call_601366: Call_ListRobotApplications_601352; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601367 = newJObject()
  var body_601368 = newJObject()
  add(query_601367, "maxResults", newJString(maxResults))
  add(query_601367, "nextToken", newJString(nextToken))
  if body != nil:
    body_601368 = body
  result = call_601366.call(nil, query_601367, nil, nil, body_601368)

var listRobotApplications* = Call_ListRobotApplications_601352(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_601353, base: "/",
    url: url_ListRobotApplications_601354, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_601369 = ref object of OpenApiRestCall_600426
proc url_ListRobots_601371(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListRobots_601370(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601372 = query.getOrDefault("maxResults")
  valid_601372 = validateParameter(valid_601372, JString, required = false,
                                 default = nil)
  if valid_601372 != nil:
    section.add "maxResults", valid_601372
  var valid_601373 = query.getOrDefault("nextToken")
  valid_601373 = validateParameter(valid_601373, JString, required = false,
                                 default = nil)
  if valid_601373 != nil:
    section.add "nextToken", valid_601373
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601374 = header.getOrDefault("X-Amz-Date")
  valid_601374 = validateParameter(valid_601374, JString, required = false,
                                 default = nil)
  if valid_601374 != nil:
    section.add "X-Amz-Date", valid_601374
  var valid_601375 = header.getOrDefault("X-Amz-Security-Token")
  valid_601375 = validateParameter(valid_601375, JString, required = false,
                                 default = nil)
  if valid_601375 != nil:
    section.add "X-Amz-Security-Token", valid_601375
  var valid_601376 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601376 = validateParameter(valid_601376, JString, required = false,
                                 default = nil)
  if valid_601376 != nil:
    section.add "X-Amz-Content-Sha256", valid_601376
  var valid_601377 = header.getOrDefault("X-Amz-Algorithm")
  valid_601377 = validateParameter(valid_601377, JString, required = false,
                                 default = nil)
  if valid_601377 != nil:
    section.add "X-Amz-Algorithm", valid_601377
  var valid_601378 = header.getOrDefault("X-Amz-Signature")
  valid_601378 = validateParameter(valid_601378, JString, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "X-Amz-Signature", valid_601378
  var valid_601379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601379 = validateParameter(valid_601379, JString, required = false,
                                 default = nil)
  if valid_601379 != nil:
    section.add "X-Amz-SignedHeaders", valid_601379
  var valid_601380 = header.getOrDefault("X-Amz-Credential")
  valid_601380 = validateParameter(valid_601380, JString, required = false,
                                 default = nil)
  if valid_601380 != nil:
    section.add "X-Amz-Credential", valid_601380
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601382: Call_ListRobots_601369; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  let valid = call_601382.validator(path, query, header, formData, body)
  let scheme = call_601382.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601382.url(scheme.get, call_601382.host, call_601382.base,
                         call_601382.route, valid.getOrDefault("path"))
  result = hook(call_601382, url, valid)

proc call*(call_601383: Call_ListRobots_601369; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601384 = newJObject()
  var body_601385 = newJObject()
  add(query_601384, "maxResults", newJString(maxResults))
  add(query_601384, "nextToken", newJString(nextToken))
  if body != nil:
    body_601385 = body
  result = call_601383.call(nil, query_601384, nil, nil, body_601385)

var listRobots* = Call_ListRobots_601369(name: "listRobots",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listRobots",
                                      validator: validate_ListRobots_601370,
                                      base: "/", url: url_ListRobots_601371,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_601386 = ref object of OpenApiRestCall_600426
proc url_ListSimulationApplications_601388(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSimulationApplications_601387(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601389 = query.getOrDefault("maxResults")
  valid_601389 = validateParameter(valid_601389, JString, required = false,
                                 default = nil)
  if valid_601389 != nil:
    section.add "maxResults", valid_601389
  var valid_601390 = query.getOrDefault("nextToken")
  valid_601390 = validateParameter(valid_601390, JString, required = false,
                                 default = nil)
  if valid_601390 != nil:
    section.add "nextToken", valid_601390
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601391 = header.getOrDefault("X-Amz-Date")
  valid_601391 = validateParameter(valid_601391, JString, required = false,
                                 default = nil)
  if valid_601391 != nil:
    section.add "X-Amz-Date", valid_601391
  var valid_601392 = header.getOrDefault("X-Amz-Security-Token")
  valid_601392 = validateParameter(valid_601392, JString, required = false,
                                 default = nil)
  if valid_601392 != nil:
    section.add "X-Amz-Security-Token", valid_601392
  var valid_601393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601393 = validateParameter(valid_601393, JString, required = false,
                                 default = nil)
  if valid_601393 != nil:
    section.add "X-Amz-Content-Sha256", valid_601393
  var valid_601394 = header.getOrDefault("X-Amz-Algorithm")
  valid_601394 = validateParameter(valid_601394, JString, required = false,
                                 default = nil)
  if valid_601394 != nil:
    section.add "X-Amz-Algorithm", valid_601394
  var valid_601395 = header.getOrDefault("X-Amz-Signature")
  valid_601395 = validateParameter(valid_601395, JString, required = false,
                                 default = nil)
  if valid_601395 != nil:
    section.add "X-Amz-Signature", valid_601395
  var valid_601396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601396 = validateParameter(valid_601396, JString, required = false,
                                 default = nil)
  if valid_601396 != nil:
    section.add "X-Amz-SignedHeaders", valid_601396
  var valid_601397 = header.getOrDefault("X-Amz-Credential")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Credential", valid_601397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601399: Call_ListSimulationApplications_601386; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  let valid = call_601399.validator(path, query, header, formData, body)
  let scheme = call_601399.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601399.url(scheme.get, call_601399.host, call_601399.base,
                         call_601399.route, valid.getOrDefault("path"))
  result = hook(call_601399, url, valid)

proc call*(call_601400: Call_ListSimulationApplications_601386; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601401 = newJObject()
  var body_601402 = newJObject()
  add(query_601401, "maxResults", newJString(maxResults))
  add(query_601401, "nextToken", newJString(nextToken))
  if body != nil:
    body_601402 = body
  result = call_601400.call(nil, query_601401, nil, nil, body_601402)

var listSimulationApplications* = Call_ListSimulationApplications_601386(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_601387, base: "/",
    url: url_ListSimulationApplications_601388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_601403 = ref object of OpenApiRestCall_600426
proc url_ListSimulationJobs_601405(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_ListSimulationJobs_601404(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JString
  ##             : Pagination limit
  ##   nextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_601406 = query.getOrDefault("maxResults")
  valid_601406 = validateParameter(valid_601406, JString, required = false,
                                 default = nil)
  if valid_601406 != nil:
    section.add "maxResults", valid_601406
  var valid_601407 = query.getOrDefault("nextToken")
  valid_601407 = validateParameter(valid_601407, JString, required = false,
                                 default = nil)
  if valid_601407 != nil:
    section.add "nextToken", valid_601407
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601408 = header.getOrDefault("X-Amz-Date")
  valid_601408 = validateParameter(valid_601408, JString, required = false,
                                 default = nil)
  if valid_601408 != nil:
    section.add "X-Amz-Date", valid_601408
  var valid_601409 = header.getOrDefault("X-Amz-Security-Token")
  valid_601409 = validateParameter(valid_601409, JString, required = false,
                                 default = nil)
  if valid_601409 != nil:
    section.add "X-Amz-Security-Token", valid_601409
  var valid_601410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601410 = validateParameter(valid_601410, JString, required = false,
                                 default = nil)
  if valid_601410 != nil:
    section.add "X-Amz-Content-Sha256", valid_601410
  var valid_601411 = header.getOrDefault("X-Amz-Algorithm")
  valid_601411 = validateParameter(valid_601411, JString, required = false,
                                 default = nil)
  if valid_601411 != nil:
    section.add "X-Amz-Algorithm", valid_601411
  var valid_601412 = header.getOrDefault("X-Amz-Signature")
  valid_601412 = validateParameter(valid_601412, JString, required = false,
                                 default = nil)
  if valid_601412 != nil:
    section.add "X-Amz-Signature", valid_601412
  var valid_601413 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601413 = validateParameter(valid_601413, JString, required = false,
                                 default = nil)
  if valid_601413 != nil:
    section.add "X-Amz-SignedHeaders", valid_601413
  var valid_601414 = header.getOrDefault("X-Amz-Credential")
  valid_601414 = validateParameter(valid_601414, JString, required = false,
                                 default = nil)
  if valid_601414 != nil:
    section.add "X-Amz-Credential", valid_601414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601416: Call_ListSimulationJobs_601403; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  let valid = call_601416.validator(path, query, header, formData, body)
  let scheme = call_601416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601416.url(scheme.get, call_601416.host, call_601416.base,
                         call_601416.route, valid.getOrDefault("path"))
  result = hook(call_601416, url, valid)

proc call*(call_601417: Call_ListSimulationJobs_601403; body: JsonNode;
          maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   maxResults: string
  ##             : Pagination limit
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_601418 = newJObject()
  var body_601419 = newJObject()
  add(query_601418, "maxResults", newJString(maxResults))
  add(query_601418, "nextToken", newJString(nextToken))
  if body != nil:
    body_601419 = body
  result = call_601417.call(nil, query_601418, nil, nil, body_601419)

var listSimulationJobs* = Call_ListSimulationJobs_601403(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_601404, base: "/",
    url: url_ListSimulationJobs_601405, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_601448 = ref object of OpenApiRestCall_600426
proc url_TagResource_601450(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_TagResource_601449(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_601451 = path.getOrDefault("resourceArn")
  valid_601451 = validateParameter(valid_601451, JString, required = true,
                                 default = nil)
  if valid_601451 != nil:
    section.add "resourceArn", valid_601451
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601452 = header.getOrDefault("X-Amz-Date")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Date", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Security-Token")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Security-Token", valid_601453
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

proc call*(call_601460: Call_TagResource_601448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  let valid = call_601460.validator(path, query, header, formData, body)
  let scheme = call_601460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601460.url(scheme.get, call_601460.host, call_601460.base,
                         call_601460.route, valid.getOrDefault("path"))
  result = hook(call_601460, url, valid)

proc call*(call_601461: Call_TagResource_601448; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  var path_601462 = newJObject()
  var body_601463 = newJObject()
  if body != nil:
    body_601463 = body
  add(path_601462, "resourceArn", newJString(resourceArn))
  result = call_601461.call(path_601462, nil, nil, nil, body_601463)

var tagResource* = Call_TagResource_601448(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_601449,
                                        base: "/", url: url_TagResource_601450,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_601420 = ref object of OpenApiRestCall_600426
proc url_ListTagsForResource_601422(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_ListTagsForResource_601421(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_601437 = path.getOrDefault("resourceArn")
  valid_601437 = validateParameter(valid_601437, JString, required = true,
                                 default = nil)
  if valid_601437 != nil:
    section.add "resourceArn", valid_601437
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601438 = header.getOrDefault("X-Amz-Date")
  valid_601438 = validateParameter(valid_601438, JString, required = false,
                                 default = nil)
  if valid_601438 != nil:
    section.add "X-Amz-Date", valid_601438
  var valid_601439 = header.getOrDefault("X-Amz-Security-Token")
  valid_601439 = validateParameter(valid_601439, JString, required = false,
                                 default = nil)
  if valid_601439 != nil:
    section.add "X-Amz-Security-Token", valid_601439
  var valid_601440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601440 = validateParameter(valid_601440, JString, required = false,
                                 default = nil)
  if valid_601440 != nil:
    section.add "X-Amz-Content-Sha256", valid_601440
  var valid_601441 = header.getOrDefault("X-Amz-Algorithm")
  valid_601441 = validateParameter(valid_601441, JString, required = false,
                                 default = nil)
  if valid_601441 != nil:
    section.add "X-Amz-Algorithm", valid_601441
  var valid_601442 = header.getOrDefault("X-Amz-Signature")
  valid_601442 = validateParameter(valid_601442, JString, required = false,
                                 default = nil)
  if valid_601442 != nil:
    section.add "X-Amz-Signature", valid_601442
  var valid_601443 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601443 = validateParameter(valid_601443, JString, required = false,
                                 default = nil)
  if valid_601443 != nil:
    section.add "X-Amz-SignedHeaders", valid_601443
  var valid_601444 = header.getOrDefault("X-Amz-Credential")
  valid_601444 = validateParameter(valid_601444, JString, required = false,
                                 default = nil)
  if valid_601444 != nil:
    section.add "X-Amz-Credential", valid_601444
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601445: Call_ListTagsForResource_601420; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  let valid = call_601445.validator(path, query, header, formData, body)
  let scheme = call_601445.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601445.url(scheme.get, call_601445.host, call_601445.base,
                         call_601445.route, valid.getOrDefault("path"))
  result = hook(call_601445, url, valid)

proc call*(call_601446: Call_ListTagsForResource_601420; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_601447 = newJObject()
  add(path_601447, "resourceArn", newJString(resourceArn))
  result = call_601446.call(path_601447, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_601420(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_601421, base: "/",
    url: url_ListTagsForResource_601422, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_601464 = ref object of OpenApiRestCall_600426
proc url_RegisterRobot_601466(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RegisterRobot_601465(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Registers a robot with a fleet.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601467 = header.getOrDefault("X-Amz-Date")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Date", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Security-Token")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Security-Token", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-Content-Sha256", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Algorithm")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Algorithm", valid_601470
  var valid_601471 = header.getOrDefault("X-Amz-Signature")
  valid_601471 = validateParameter(valid_601471, JString, required = false,
                                 default = nil)
  if valid_601471 != nil:
    section.add "X-Amz-Signature", valid_601471
  var valid_601472 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601472 = validateParameter(valid_601472, JString, required = false,
                                 default = nil)
  if valid_601472 != nil:
    section.add "X-Amz-SignedHeaders", valid_601472
  var valid_601473 = header.getOrDefault("X-Amz-Credential")
  valid_601473 = validateParameter(valid_601473, JString, required = false,
                                 default = nil)
  if valid_601473 != nil:
    section.add "X-Amz-Credential", valid_601473
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601475: Call_RegisterRobot_601464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a robot with a fleet.
  ## 
  let valid = call_601475.validator(path, query, header, formData, body)
  let scheme = call_601475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601475.url(scheme.get, call_601475.host, call_601475.base,
                         call_601475.route, valid.getOrDefault("path"))
  result = hook(call_601475, url, valid)

proc call*(call_601476: Call_RegisterRobot_601464; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_601477 = newJObject()
  if body != nil:
    body_601477 = body
  result = call_601476.call(nil, nil, nil, nil, body_601477)

var registerRobot* = Call_RegisterRobot_601464(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_601465, base: "/",
    url: url_RegisterRobot_601466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_601478 = ref object of OpenApiRestCall_600426
proc url_RestartSimulationJob_601480(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_RestartSimulationJob_601479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Restarts a running simulation job.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601481 = header.getOrDefault("X-Amz-Date")
  valid_601481 = validateParameter(valid_601481, JString, required = false,
                                 default = nil)
  if valid_601481 != nil:
    section.add "X-Amz-Date", valid_601481
  var valid_601482 = header.getOrDefault("X-Amz-Security-Token")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Security-Token", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Content-Sha256", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Algorithm")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Algorithm", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Signature")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Signature", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-SignedHeaders", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-Credential")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-Credential", valid_601487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601489: Call_RestartSimulationJob_601478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts a running simulation job.
  ## 
  let valid = call_601489.validator(path, query, header, formData, body)
  let scheme = call_601489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601489.url(scheme.get, call_601489.host, call_601489.base,
                         call_601489.route, valid.getOrDefault("path"))
  result = hook(call_601489, url, valid)

proc call*(call_601490: Call_RestartSimulationJob_601478; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_601491 = newJObject()
  if body != nil:
    body_601491 = body
  result = call_601490.call(nil, nil, nil, nil, body_601491)

var restartSimulationJob* = Call_RestartSimulationJob_601478(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_601479, base: "/",
    url: url_RestartSimulationJob_601480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_601492 = ref object of OpenApiRestCall_600426
proc url_SyncDeploymentJob_601494(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_SyncDeploymentJob_601493(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601495 = header.getOrDefault("X-Amz-Date")
  valid_601495 = validateParameter(valid_601495, JString, required = false,
                                 default = nil)
  if valid_601495 != nil:
    section.add "X-Amz-Date", valid_601495
  var valid_601496 = header.getOrDefault("X-Amz-Security-Token")
  valid_601496 = validateParameter(valid_601496, JString, required = false,
                                 default = nil)
  if valid_601496 != nil:
    section.add "X-Amz-Security-Token", valid_601496
  var valid_601497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Content-Sha256", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Algorithm")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Algorithm", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Signature")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Signature", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-SignedHeaders", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Credential")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Credential", valid_601501
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601503: Call_SyncDeploymentJob_601492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  let valid = call_601503.validator(path, query, header, formData, body)
  let scheme = call_601503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601503.url(scheme.get, call_601503.host, call_601503.base,
                         call_601503.route, valid.getOrDefault("path"))
  result = hook(call_601503, url, valid)

proc call*(call_601504: Call_SyncDeploymentJob_601492; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   body: JObject (required)
  var body_601505 = newJObject()
  if body != nil:
    body_601505 = body
  result = call_601504.call(nil, nil, nil, nil, body_601505)

var syncDeploymentJob* = Call_SyncDeploymentJob_601492(name: "syncDeploymentJob",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/syncDeploymentJob", validator: validate_SyncDeploymentJob_601493,
    base: "/", url: url_SyncDeploymentJob_601494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_601506 = ref object of OpenApiRestCall_600426
proc url_UntagResource_601508(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode): string =
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result = $protocol & "://" & host & base & hydrated.get()

proc validate_UntagResource_601507(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_601509 = path.getOrDefault("resourceArn")
  valid_601509 = validateParameter(valid_601509, JString, required = true,
                                 default = nil)
  if valid_601509 != nil:
    section.add "resourceArn", valid_601509
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_601510 = query.getOrDefault("tagKeys")
  valid_601510 = validateParameter(valid_601510, JArray, required = true, default = nil)
  if valid_601510 != nil:
    section.add "tagKeys", valid_601510
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601511 = header.getOrDefault("X-Amz-Date")
  valid_601511 = validateParameter(valid_601511, JString, required = false,
                                 default = nil)
  if valid_601511 != nil:
    section.add "X-Amz-Date", valid_601511
  var valid_601512 = header.getOrDefault("X-Amz-Security-Token")
  valid_601512 = validateParameter(valid_601512, JString, required = false,
                                 default = nil)
  if valid_601512 != nil:
    section.add "X-Amz-Security-Token", valid_601512
  var valid_601513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601513 = validateParameter(valid_601513, JString, required = false,
                                 default = nil)
  if valid_601513 != nil:
    section.add "X-Amz-Content-Sha256", valid_601513
  var valid_601514 = header.getOrDefault("X-Amz-Algorithm")
  valid_601514 = validateParameter(valid_601514, JString, required = false,
                                 default = nil)
  if valid_601514 != nil:
    section.add "X-Amz-Algorithm", valid_601514
  var valid_601515 = header.getOrDefault("X-Amz-Signature")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Signature", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-SignedHeaders", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Credential")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Credential", valid_601517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601518: Call_UntagResource_601506; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  let valid = call_601518.validator(path, query, header, formData, body)
  let scheme = call_601518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601518.url(scheme.get, call_601518.host, call_601518.base,
                         call_601518.route, valid.getOrDefault("path"))
  result = hook(call_601518, url, valid)

proc call*(call_601519: Call_UntagResource_601506; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  var path_601520 = newJObject()
  var query_601521 = newJObject()
  if tagKeys != nil:
    query_601521.add "tagKeys", tagKeys
  add(path_601520, "resourceArn", newJString(resourceArn))
  result = call_601519.call(path_601520, query_601521, nil, nil, nil)

var untagResource* = Call_UntagResource_601506(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_601507,
    base: "/", url: url_UntagResource_601508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_601522 = ref object of OpenApiRestCall_600426
proc url_UpdateRobotApplication_601524(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateRobotApplication_601523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a robot application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601525 = header.getOrDefault("X-Amz-Date")
  valid_601525 = validateParameter(valid_601525, JString, required = false,
                                 default = nil)
  if valid_601525 != nil:
    section.add "X-Amz-Date", valid_601525
  var valid_601526 = header.getOrDefault("X-Amz-Security-Token")
  valid_601526 = validateParameter(valid_601526, JString, required = false,
                                 default = nil)
  if valid_601526 != nil:
    section.add "X-Amz-Security-Token", valid_601526
  var valid_601527 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601527 = validateParameter(valid_601527, JString, required = false,
                                 default = nil)
  if valid_601527 != nil:
    section.add "X-Amz-Content-Sha256", valid_601527
  var valid_601528 = header.getOrDefault("X-Amz-Algorithm")
  valid_601528 = validateParameter(valid_601528, JString, required = false,
                                 default = nil)
  if valid_601528 != nil:
    section.add "X-Amz-Algorithm", valid_601528
  var valid_601529 = header.getOrDefault("X-Amz-Signature")
  valid_601529 = validateParameter(valid_601529, JString, required = false,
                                 default = nil)
  if valid_601529 != nil:
    section.add "X-Amz-Signature", valid_601529
  var valid_601530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-SignedHeaders", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Credential")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Credential", valid_601531
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601533: Call_UpdateRobotApplication_601522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a robot application.
  ## 
  let valid = call_601533.validator(path, query, header, formData, body)
  let scheme = call_601533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601533.url(scheme.get, call_601533.host, call_601533.base,
                         call_601533.route, valid.getOrDefault("path"))
  result = hook(call_601533, url, valid)

proc call*(call_601534: Call_UpdateRobotApplication_601522; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_601535 = newJObject()
  if body != nil:
    body_601535 = body
  result = call_601534.call(nil, nil, nil, nil, body_601535)

var updateRobotApplication* = Call_UpdateRobotApplication_601522(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_601523, base: "/",
    url: url_UpdateRobotApplication_601524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_601536 = ref object of OpenApiRestCall_600426
proc url_UpdateSimulationApplication_601538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_UpdateSimulationApplication_601537(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a simulation application.
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
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_601539 = header.getOrDefault("X-Amz-Date")
  valid_601539 = validateParameter(valid_601539, JString, required = false,
                                 default = nil)
  if valid_601539 != nil:
    section.add "X-Amz-Date", valid_601539
  var valid_601540 = header.getOrDefault("X-Amz-Security-Token")
  valid_601540 = validateParameter(valid_601540, JString, required = false,
                                 default = nil)
  if valid_601540 != nil:
    section.add "X-Amz-Security-Token", valid_601540
  var valid_601541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601541 = validateParameter(valid_601541, JString, required = false,
                                 default = nil)
  if valid_601541 != nil:
    section.add "X-Amz-Content-Sha256", valid_601541
  var valid_601542 = header.getOrDefault("X-Amz-Algorithm")
  valid_601542 = validateParameter(valid_601542, JString, required = false,
                                 default = nil)
  if valid_601542 != nil:
    section.add "X-Amz-Algorithm", valid_601542
  var valid_601543 = header.getOrDefault("X-Amz-Signature")
  valid_601543 = validateParameter(valid_601543, JString, required = false,
                                 default = nil)
  if valid_601543 != nil:
    section.add "X-Amz-Signature", valid_601543
  var valid_601544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601544 = validateParameter(valid_601544, JString, required = false,
                                 default = nil)
  if valid_601544 != nil:
    section.add "X-Amz-SignedHeaders", valid_601544
  var valid_601545 = header.getOrDefault("X-Amz-Credential")
  valid_601545 = validateParameter(valid_601545, JString, required = false,
                                 default = nil)
  if valid_601545 != nil:
    section.add "X-Amz-Credential", valid_601545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601547: Call_UpdateSimulationApplication_601536; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a simulation application.
  ## 
  let valid = call_601547.validator(path, query, header, formData, body)
  let scheme = call_601547.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601547.url(scheme.get, call_601547.host, call_601547.base,
                         call_601547.route, valid.getOrDefault("path"))
  result = hook(call_601547, url, valid)

proc call*(call_601548: Call_UpdateSimulationApplication_601536; body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_601549 = newJObject()
  if body != nil:
    body_601549 = body
  result = call_601548.call(nil, nil, nil, nil, body_601549)

var updateSimulationApplication* = Call_UpdateSimulationApplication_601536(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_601537, base: "/",
    url: url_UpdateSimulationApplication_601538,
    schemes: {Scheme.Https, Scheme.Http})
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

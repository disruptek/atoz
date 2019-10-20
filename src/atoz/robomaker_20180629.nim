
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeSimulationJob_592703 = ref object of OpenApiRestCall_592364
proc url_BatchDescribeSimulationJob_592705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDescribeSimulationJob_592704(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592817 = header.getOrDefault("X-Amz-Signature")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "X-Amz-Signature", valid_592817
  var valid_592818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "X-Amz-Content-Sha256", valid_592818
  var valid_592819 = header.getOrDefault("X-Amz-Date")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "X-Amz-Date", valid_592819
  var valid_592820 = header.getOrDefault("X-Amz-Credential")
  valid_592820 = validateParameter(valid_592820, JString, required = false,
                                 default = nil)
  if valid_592820 != nil:
    section.add "X-Amz-Credential", valid_592820
  var valid_592821 = header.getOrDefault("X-Amz-Security-Token")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Security-Token", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Algorithm")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Algorithm", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-SignedHeaders", valid_592823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592847: Call_BatchDescribeSimulationJob_592703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more simulation jobs.
  ## 
  let valid = call_592847.validator(path, query, header, formData, body)
  let scheme = call_592847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592847.url(scheme.get, call_592847.host, call_592847.base,
                         call_592847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592847, url, valid)

proc call*(call_592918: Call_BatchDescribeSimulationJob_592703; body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_592919 = newJObject()
  if body != nil:
    body_592919 = body
  result = call_592918.call(nil, nil, nil, nil, body_592919)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_592703(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_592704, base: "/",
    url: url_BatchDescribeSimulationJob_592705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_592958 = ref object of OpenApiRestCall_592364
proc url_CancelDeploymentJob_592960(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelDeploymentJob_592959(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592961 = header.getOrDefault("X-Amz-Signature")
  valid_592961 = validateParameter(valid_592961, JString, required = false,
                                 default = nil)
  if valid_592961 != nil:
    section.add "X-Amz-Signature", valid_592961
  var valid_592962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592962 = validateParameter(valid_592962, JString, required = false,
                                 default = nil)
  if valid_592962 != nil:
    section.add "X-Amz-Content-Sha256", valid_592962
  var valid_592963 = header.getOrDefault("X-Amz-Date")
  valid_592963 = validateParameter(valid_592963, JString, required = false,
                                 default = nil)
  if valid_592963 != nil:
    section.add "X-Amz-Date", valid_592963
  var valid_592964 = header.getOrDefault("X-Amz-Credential")
  valid_592964 = validateParameter(valid_592964, JString, required = false,
                                 default = nil)
  if valid_592964 != nil:
    section.add "X-Amz-Credential", valid_592964
  var valid_592965 = header.getOrDefault("X-Amz-Security-Token")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Security-Token", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Algorithm")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Algorithm", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-SignedHeaders", valid_592967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592969: Call_CancelDeploymentJob_592958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified deployment job.
  ## 
  let valid = call_592969.validator(path, query, header, formData, body)
  let scheme = call_592969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592969.url(scheme.get, call_592969.host, call_592969.base,
                         call_592969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592969, url, valid)

proc call*(call_592970: Call_CancelDeploymentJob_592958; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_592971 = newJObject()
  if body != nil:
    body_592971 = body
  result = call_592970.call(nil, nil, nil, nil, body_592971)

var cancelDeploymentJob* = Call_CancelDeploymentJob_592958(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_592959, base: "/",
    url: url_CancelDeploymentJob_592960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_592972 = ref object of OpenApiRestCall_592364
proc url_CancelSimulationJob_592974(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelSimulationJob_592973(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592975 = header.getOrDefault("X-Amz-Signature")
  valid_592975 = validateParameter(valid_592975, JString, required = false,
                                 default = nil)
  if valid_592975 != nil:
    section.add "X-Amz-Signature", valid_592975
  var valid_592976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592976 = validateParameter(valid_592976, JString, required = false,
                                 default = nil)
  if valid_592976 != nil:
    section.add "X-Amz-Content-Sha256", valid_592976
  var valid_592977 = header.getOrDefault("X-Amz-Date")
  valid_592977 = validateParameter(valid_592977, JString, required = false,
                                 default = nil)
  if valid_592977 != nil:
    section.add "X-Amz-Date", valid_592977
  var valid_592978 = header.getOrDefault("X-Amz-Credential")
  valid_592978 = validateParameter(valid_592978, JString, required = false,
                                 default = nil)
  if valid_592978 != nil:
    section.add "X-Amz-Credential", valid_592978
  var valid_592979 = header.getOrDefault("X-Amz-Security-Token")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "X-Amz-Security-Token", valid_592979
  var valid_592980 = header.getOrDefault("X-Amz-Algorithm")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "X-Amz-Algorithm", valid_592980
  var valid_592981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "X-Amz-SignedHeaders", valid_592981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592983: Call_CancelSimulationJob_592972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified simulation job.
  ## 
  let valid = call_592983.validator(path, query, header, formData, body)
  let scheme = call_592983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592983.url(scheme.get, call_592983.host, call_592983.base,
                         call_592983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592983, url, valid)

proc call*(call_592984: Call_CancelSimulationJob_592972; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_592985 = newJObject()
  if body != nil:
    body_592985 = body
  result = call_592984.call(nil, nil, nil, nil, body_592985)

var cancelSimulationJob* = Call_CancelSimulationJob_592972(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_592973, base: "/",
    url: url_CancelSimulationJob_592974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_592986 = ref object of OpenApiRestCall_592364
proc url_CreateDeploymentJob_592988(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeploymentJob_592987(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_592989 = header.getOrDefault("X-Amz-Signature")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Signature", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Content-Sha256", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-Date")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-Date", valid_592991
  var valid_592992 = header.getOrDefault("X-Amz-Credential")
  valid_592992 = validateParameter(valid_592992, JString, required = false,
                                 default = nil)
  if valid_592992 != nil:
    section.add "X-Amz-Credential", valid_592992
  var valid_592993 = header.getOrDefault("X-Amz-Security-Token")
  valid_592993 = validateParameter(valid_592993, JString, required = false,
                                 default = nil)
  if valid_592993 != nil:
    section.add "X-Amz-Security-Token", valid_592993
  var valid_592994 = header.getOrDefault("X-Amz-Algorithm")
  valid_592994 = validateParameter(valid_592994, JString, required = false,
                                 default = nil)
  if valid_592994 != nil:
    section.add "X-Amz-Algorithm", valid_592994
  var valid_592995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592995 = validateParameter(valid_592995, JString, required = false,
                                 default = nil)
  if valid_592995 != nil:
    section.add "X-Amz-SignedHeaders", valid_592995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592997: Call_CreateDeploymentJob_592986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_592997.validator(path, query, header, formData, body)
  let scheme = call_592997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592997.url(scheme.get, call_592997.host, call_592997.base,
                         call_592997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592997, url, valid)

proc call*(call_592998: Call_CreateDeploymentJob_592986; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_592999 = newJObject()
  if body != nil:
    body_592999 = body
  result = call_592998.call(nil, nil, nil, nil, body_592999)

var createDeploymentJob* = Call_CreateDeploymentJob_592986(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_592987, base: "/",
    url: url_CreateDeploymentJob_592988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_593000 = ref object of OpenApiRestCall_592364
proc url_CreateFleet_593002(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_593001(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593003 = header.getOrDefault("X-Amz-Signature")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Signature", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-Content-Sha256", valid_593004
  var valid_593005 = header.getOrDefault("X-Amz-Date")
  valid_593005 = validateParameter(valid_593005, JString, required = false,
                                 default = nil)
  if valid_593005 != nil:
    section.add "X-Amz-Date", valid_593005
  var valid_593006 = header.getOrDefault("X-Amz-Credential")
  valid_593006 = validateParameter(valid_593006, JString, required = false,
                                 default = nil)
  if valid_593006 != nil:
    section.add "X-Amz-Credential", valid_593006
  var valid_593007 = header.getOrDefault("X-Amz-Security-Token")
  valid_593007 = validateParameter(valid_593007, JString, required = false,
                                 default = nil)
  if valid_593007 != nil:
    section.add "X-Amz-Security-Token", valid_593007
  var valid_593008 = header.getOrDefault("X-Amz-Algorithm")
  valid_593008 = validateParameter(valid_593008, JString, required = false,
                                 default = nil)
  if valid_593008 != nil:
    section.add "X-Amz-Algorithm", valid_593008
  var valid_593009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593009 = validateParameter(valid_593009, JString, required = false,
                                 default = nil)
  if valid_593009 != nil:
    section.add "X-Amz-SignedHeaders", valid_593009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593011: Call_CreateFleet_593000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  let valid = call_593011.validator(path, query, header, formData, body)
  let scheme = call_593011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593011.url(scheme.get, call_593011.host, call_593011.base,
                         call_593011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593011, url, valid)

proc call*(call_593012: Call_CreateFleet_593000; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   body: JObject (required)
  var body_593013 = newJObject()
  if body != nil:
    body_593013 = body
  result = call_593012.call(nil, nil, nil, nil, body_593013)

var createFleet* = Call_CreateFleet_593000(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_593001,
                                        base: "/", url: url_CreateFleet_593002,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_593014 = ref object of OpenApiRestCall_592364
proc url_CreateRobot_593016(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobot_593015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593017 = header.getOrDefault("X-Amz-Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Signature", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Content-Sha256", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Date")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Date", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Credential")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Credential", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593025: Call_CreateRobot_593014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot.
  ## 
  let valid = call_593025.validator(path, query, header, formData, body)
  let scheme = call_593025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593025.url(scheme.get, call_593025.host, call_593025.base,
                         call_593025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593025, url, valid)

proc call*(call_593026: Call_CreateRobot_593014; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_593027 = newJObject()
  if body != nil:
    body_593027 = body
  result = call_593026.call(nil, nil, nil, nil, body_593027)

var createRobot* = Call_CreateRobot_593014(name: "createRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createRobot",
                                        validator: validate_CreateRobot_593015,
                                        base: "/", url: url_CreateRobot_593016,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_593028 = ref object of OpenApiRestCall_592364
proc url_CreateRobotApplication_593030(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobotApplication_593029(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593031 = header.getOrDefault("X-Amz-Signature")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Signature", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Content-Sha256", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Date")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Date", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Credential")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Credential", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Security-Token")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Security-Token", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-Algorithm")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-Algorithm", valid_593036
  var valid_593037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593037 = validateParameter(valid_593037, JString, required = false,
                                 default = nil)
  if valid_593037 != nil:
    section.add "X-Amz-SignedHeaders", valid_593037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593039: Call_CreateRobotApplication_593028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot application. 
  ## 
  let valid = call_593039.validator(path, query, header, formData, body)
  let scheme = call_593039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593039.url(scheme.get, call_593039.host, call_593039.base,
                         call_593039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593039, url, valid)

proc call*(call_593040: Call_CreateRobotApplication_593028; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_593041 = newJObject()
  if body != nil:
    body_593041 = body
  result = call_593040.call(nil, nil, nil, nil, body_593041)

var createRobotApplication* = Call_CreateRobotApplication_593028(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_593029, base: "/",
    url: url_CreateRobotApplication_593030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_593042 = ref object of OpenApiRestCall_592364
proc url_CreateRobotApplicationVersion_593044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobotApplicationVersion_593043(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593045 = header.getOrDefault("X-Amz-Signature")
  valid_593045 = validateParameter(valid_593045, JString, required = false,
                                 default = nil)
  if valid_593045 != nil:
    section.add "X-Amz-Signature", valid_593045
  var valid_593046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593046 = validateParameter(valid_593046, JString, required = false,
                                 default = nil)
  if valid_593046 != nil:
    section.add "X-Amz-Content-Sha256", valid_593046
  var valid_593047 = header.getOrDefault("X-Amz-Date")
  valid_593047 = validateParameter(valid_593047, JString, required = false,
                                 default = nil)
  if valid_593047 != nil:
    section.add "X-Amz-Date", valid_593047
  var valid_593048 = header.getOrDefault("X-Amz-Credential")
  valid_593048 = validateParameter(valid_593048, JString, required = false,
                                 default = nil)
  if valid_593048 != nil:
    section.add "X-Amz-Credential", valid_593048
  var valid_593049 = header.getOrDefault("X-Amz-Security-Token")
  valid_593049 = validateParameter(valid_593049, JString, required = false,
                                 default = nil)
  if valid_593049 != nil:
    section.add "X-Amz-Security-Token", valid_593049
  var valid_593050 = header.getOrDefault("X-Amz-Algorithm")
  valid_593050 = validateParameter(valid_593050, JString, required = false,
                                 default = nil)
  if valid_593050 != nil:
    section.add "X-Amz-Algorithm", valid_593050
  var valid_593051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593051 = validateParameter(valid_593051, JString, required = false,
                                 default = nil)
  if valid_593051 != nil:
    section.add "X-Amz-SignedHeaders", valid_593051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593053: Call_CreateRobotApplicationVersion_593042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a robot application.
  ## 
  let valid = call_593053.validator(path, query, header, formData, body)
  let scheme = call_593053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593053.url(scheme.get, call_593053.host, call_593053.base,
                         call_593053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593053, url, valid)

proc call*(call_593054: Call_CreateRobotApplicationVersion_593042; body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_593055 = newJObject()
  if body != nil:
    body_593055 = body
  result = call_593054.call(nil, nil, nil, nil, body_593055)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_593042(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_593043, base: "/",
    url: url_CreateRobotApplicationVersion_593044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_593056 = ref object of OpenApiRestCall_592364
proc url_CreateSimulationApplication_593058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationApplication_593057(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593067: Call_CreateSimulationApplication_593056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a simulation application.
  ## 
  let valid = call_593067.validator(path, query, header, formData, body)
  let scheme = call_593067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593067.url(scheme.get, call_593067.host, call_593067.base,
                         call_593067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593067, url, valid)

proc call*(call_593068: Call_CreateSimulationApplication_593056; body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_593069 = newJObject()
  if body != nil:
    body_593069 = body
  result = call_593068.call(nil, nil, nil, nil, body_593069)

var createSimulationApplication* = Call_CreateSimulationApplication_593056(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_593057, base: "/",
    url: url_CreateSimulationApplication_593058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_593070 = ref object of OpenApiRestCall_592364
proc url_CreateSimulationApplicationVersion_593072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationApplicationVersion_593071(path: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593073 = header.getOrDefault("X-Amz-Signature")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Signature", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Content-Sha256", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Date")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Date", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Credential")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Credential", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Security-Token")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Security-Token", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Algorithm")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Algorithm", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-SignedHeaders", valid_593079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_CreateSimulationApplicationVersion_593070;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a simulation application with a specific revision id.
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_CreateSimulationApplicationVersion_593070;
          body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_593083 = newJObject()
  if body != nil:
    body_593083 = body
  result = call_593082.call(nil, nil, nil, nil, body_593083)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_593070(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_593071, base: "/",
    url: url_CreateSimulationApplicationVersion_593072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_593084 = ref object of OpenApiRestCall_592364
proc url_CreateSimulationJob_593086(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationJob_593085(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593087 = header.getOrDefault("X-Amz-Signature")
  valid_593087 = validateParameter(valid_593087, JString, required = false,
                                 default = nil)
  if valid_593087 != nil:
    section.add "X-Amz-Signature", valid_593087
  var valid_593088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593088 = validateParameter(valid_593088, JString, required = false,
                                 default = nil)
  if valid_593088 != nil:
    section.add "X-Amz-Content-Sha256", valid_593088
  var valid_593089 = header.getOrDefault("X-Amz-Date")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Date", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Credential")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Credential", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Security-Token")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Security-Token", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Algorithm")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Algorithm", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-SignedHeaders", valid_593093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593095: Call_CreateSimulationJob_593084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_593095.validator(path, query, header, formData, body)
  let scheme = call_593095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593095.url(scheme.get, call_593095.host, call_593095.base,
                         call_593095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593095, url, valid)

proc call*(call_593096: Call_CreateSimulationJob_593084; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_593097 = newJObject()
  if body != nil:
    body_593097 = body
  result = call_593096.call(nil, nil, nil, nil, body_593097)

var createSimulationJob* = Call_CreateSimulationJob_593084(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_593085, base: "/",
    url: url_CreateSimulationJob_593086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_593098 = ref object of OpenApiRestCall_592364
proc url_DeleteFleet_593100(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_593099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593101 = header.getOrDefault("X-Amz-Signature")
  valid_593101 = validateParameter(valid_593101, JString, required = false,
                                 default = nil)
  if valid_593101 != nil:
    section.add "X-Amz-Signature", valid_593101
  var valid_593102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593102 = validateParameter(valid_593102, JString, required = false,
                                 default = nil)
  if valid_593102 != nil:
    section.add "X-Amz-Content-Sha256", valid_593102
  var valid_593103 = header.getOrDefault("X-Amz-Date")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Date", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Credential")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Credential", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Security-Token")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Security-Token", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Algorithm")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Algorithm", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-SignedHeaders", valid_593107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593109: Call_DeleteFleet_593098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet.
  ## 
  let valid = call_593109.validator(path, query, header, formData, body)
  let scheme = call_593109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593109.url(scheme.get, call_593109.host, call_593109.base,
                         call_593109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593109, url, valid)

proc call*(call_593110: Call_DeleteFleet_593098; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_593111 = newJObject()
  if body != nil:
    body_593111 = body
  result = call_593110.call(nil, nil, nil, nil, body_593111)

var deleteFleet* = Call_DeleteFleet_593098(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_593099,
                                        base: "/", url: url_DeleteFleet_593100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_593112 = ref object of OpenApiRestCall_592364
proc url_DeleteRobot_593114(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRobot_593113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593115 = header.getOrDefault("X-Amz-Signature")
  valid_593115 = validateParameter(valid_593115, JString, required = false,
                                 default = nil)
  if valid_593115 != nil:
    section.add "X-Amz-Signature", valid_593115
  var valid_593116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593116 = validateParameter(valid_593116, JString, required = false,
                                 default = nil)
  if valid_593116 != nil:
    section.add "X-Amz-Content-Sha256", valid_593116
  var valid_593117 = header.getOrDefault("X-Amz-Date")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Date", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Credential")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Credential", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Security-Token")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Security-Token", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Algorithm")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Algorithm", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-SignedHeaders", valid_593121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593123: Call_DeleteRobot_593112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot.
  ## 
  let valid = call_593123.validator(path, query, header, formData, body)
  let scheme = call_593123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593123.url(scheme.get, call_593123.host, call_593123.base,
                         call_593123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593123, url, valid)

proc call*(call_593124: Call_DeleteRobot_593112; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_593125 = newJObject()
  if body != nil:
    body_593125 = body
  result = call_593124.call(nil, nil, nil, nil, body_593125)

var deleteRobot* = Call_DeleteRobot_593112(name: "deleteRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteRobot",
                                        validator: validate_DeleteRobot_593113,
                                        base: "/", url: url_DeleteRobot_593114,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_593126 = ref object of OpenApiRestCall_592364
proc url_DeleteRobotApplication_593128(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRobotApplication_593127(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593129 = header.getOrDefault("X-Amz-Signature")
  valid_593129 = validateParameter(valid_593129, JString, required = false,
                                 default = nil)
  if valid_593129 != nil:
    section.add "X-Amz-Signature", valid_593129
  var valid_593130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593130 = validateParameter(valid_593130, JString, required = false,
                                 default = nil)
  if valid_593130 != nil:
    section.add "X-Amz-Content-Sha256", valid_593130
  var valid_593131 = header.getOrDefault("X-Amz-Date")
  valid_593131 = validateParameter(valid_593131, JString, required = false,
                                 default = nil)
  if valid_593131 != nil:
    section.add "X-Amz-Date", valid_593131
  var valid_593132 = header.getOrDefault("X-Amz-Credential")
  valid_593132 = validateParameter(valid_593132, JString, required = false,
                                 default = nil)
  if valid_593132 != nil:
    section.add "X-Amz-Credential", valid_593132
  var valid_593133 = header.getOrDefault("X-Amz-Security-Token")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Security-Token", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Algorithm")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Algorithm", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-SignedHeaders", valid_593135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593137: Call_DeleteRobotApplication_593126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot application.
  ## 
  let valid = call_593137.validator(path, query, header, formData, body)
  let scheme = call_593137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593137.url(scheme.get, call_593137.host, call_593137.base,
                         call_593137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593137, url, valid)

proc call*(call_593138: Call_DeleteRobotApplication_593126; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_593139 = newJObject()
  if body != nil:
    body_593139 = body
  result = call_593138.call(nil, nil, nil, nil, body_593139)

var deleteRobotApplication* = Call_DeleteRobotApplication_593126(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_593127, base: "/",
    url: url_DeleteRobotApplication_593128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_593140 = ref object of OpenApiRestCall_592364
proc url_DeleteSimulationApplication_593142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSimulationApplication_593141(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593143 = header.getOrDefault("X-Amz-Signature")
  valid_593143 = validateParameter(valid_593143, JString, required = false,
                                 default = nil)
  if valid_593143 != nil:
    section.add "X-Amz-Signature", valid_593143
  var valid_593144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593144 = validateParameter(valid_593144, JString, required = false,
                                 default = nil)
  if valid_593144 != nil:
    section.add "X-Amz-Content-Sha256", valid_593144
  var valid_593145 = header.getOrDefault("X-Amz-Date")
  valid_593145 = validateParameter(valid_593145, JString, required = false,
                                 default = nil)
  if valid_593145 != nil:
    section.add "X-Amz-Date", valid_593145
  var valid_593146 = header.getOrDefault("X-Amz-Credential")
  valid_593146 = validateParameter(valid_593146, JString, required = false,
                                 default = nil)
  if valid_593146 != nil:
    section.add "X-Amz-Credential", valid_593146
  var valid_593147 = header.getOrDefault("X-Amz-Security-Token")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Security-Token", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Algorithm")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Algorithm", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-SignedHeaders", valid_593149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593151: Call_DeleteSimulationApplication_593140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a simulation application.
  ## 
  let valid = call_593151.validator(path, query, header, formData, body)
  let scheme = call_593151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593151.url(scheme.get, call_593151.host, call_593151.base,
                         call_593151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593151, url, valid)

proc call*(call_593152: Call_DeleteSimulationApplication_593140; body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_593153 = newJObject()
  if body != nil:
    body_593153 = body
  result = call_593152.call(nil, nil, nil, nil, body_593153)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_593140(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_593141, base: "/",
    url: url_DeleteSimulationApplication_593142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_593154 = ref object of OpenApiRestCall_592364
proc url_DeregisterRobot_593156(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterRobot_593155(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593157 = header.getOrDefault("X-Amz-Signature")
  valid_593157 = validateParameter(valid_593157, JString, required = false,
                                 default = nil)
  if valid_593157 != nil:
    section.add "X-Amz-Signature", valid_593157
  var valid_593158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593158 = validateParameter(valid_593158, JString, required = false,
                                 default = nil)
  if valid_593158 != nil:
    section.add "X-Amz-Content-Sha256", valid_593158
  var valid_593159 = header.getOrDefault("X-Amz-Date")
  valid_593159 = validateParameter(valid_593159, JString, required = false,
                                 default = nil)
  if valid_593159 != nil:
    section.add "X-Amz-Date", valid_593159
  var valid_593160 = header.getOrDefault("X-Amz-Credential")
  valid_593160 = validateParameter(valid_593160, JString, required = false,
                                 default = nil)
  if valid_593160 != nil:
    section.add "X-Amz-Credential", valid_593160
  var valid_593161 = header.getOrDefault("X-Amz-Security-Token")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Security-Token", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Algorithm")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Algorithm", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-SignedHeaders", valid_593163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593165: Call_DeregisterRobot_593154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a robot.
  ## 
  let valid = call_593165.validator(path, query, header, formData, body)
  let scheme = call_593165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593165.url(scheme.get, call_593165.host, call_593165.base,
                         call_593165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593165, url, valid)

proc call*(call_593166: Call_DeregisterRobot_593154; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_593167 = newJObject()
  if body != nil:
    body_593167 = body
  result = call_593166.call(nil, nil, nil, nil, body_593167)

var deregisterRobot* = Call_DeregisterRobot_593154(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_593155,
    base: "/", url: url_DeregisterRobot_593156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_593168 = ref object of OpenApiRestCall_592364
proc url_DescribeDeploymentJob_593170(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDeploymentJob_593169(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593171 = header.getOrDefault("X-Amz-Signature")
  valid_593171 = validateParameter(valid_593171, JString, required = false,
                                 default = nil)
  if valid_593171 != nil:
    section.add "X-Amz-Signature", valid_593171
  var valid_593172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593172 = validateParameter(valid_593172, JString, required = false,
                                 default = nil)
  if valid_593172 != nil:
    section.add "X-Amz-Content-Sha256", valid_593172
  var valid_593173 = header.getOrDefault("X-Amz-Date")
  valid_593173 = validateParameter(valid_593173, JString, required = false,
                                 default = nil)
  if valid_593173 != nil:
    section.add "X-Amz-Date", valid_593173
  var valid_593174 = header.getOrDefault("X-Amz-Credential")
  valid_593174 = validateParameter(valid_593174, JString, required = false,
                                 default = nil)
  if valid_593174 != nil:
    section.add "X-Amz-Credential", valid_593174
  var valid_593175 = header.getOrDefault("X-Amz-Security-Token")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Security-Token", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Algorithm")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Algorithm", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-SignedHeaders", valid_593177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593179: Call_DescribeDeploymentJob_593168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a deployment job.
  ## 
  let valid = call_593179.validator(path, query, header, formData, body)
  let scheme = call_593179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593179.url(scheme.get, call_593179.host, call_593179.base,
                         call_593179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593179, url, valid)

proc call*(call_593180: Call_DescribeDeploymentJob_593168; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_593181 = newJObject()
  if body != nil:
    body_593181 = body
  result = call_593180.call(nil, nil, nil, nil, body_593181)

var describeDeploymentJob* = Call_DescribeDeploymentJob_593168(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_593169, base: "/",
    url: url_DescribeDeploymentJob_593170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_593182 = ref object of OpenApiRestCall_592364
proc url_DescribeFleet_593184(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleet_593183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593185 = header.getOrDefault("X-Amz-Signature")
  valid_593185 = validateParameter(valid_593185, JString, required = false,
                                 default = nil)
  if valid_593185 != nil:
    section.add "X-Amz-Signature", valid_593185
  var valid_593186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593186 = validateParameter(valid_593186, JString, required = false,
                                 default = nil)
  if valid_593186 != nil:
    section.add "X-Amz-Content-Sha256", valid_593186
  var valid_593187 = header.getOrDefault("X-Amz-Date")
  valid_593187 = validateParameter(valid_593187, JString, required = false,
                                 default = nil)
  if valid_593187 != nil:
    section.add "X-Amz-Date", valid_593187
  var valid_593188 = header.getOrDefault("X-Amz-Credential")
  valid_593188 = validateParameter(valid_593188, JString, required = false,
                                 default = nil)
  if valid_593188 != nil:
    section.add "X-Amz-Credential", valid_593188
  var valid_593189 = header.getOrDefault("X-Amz-Security-Token")
  valid_593189 = validateParameter(valid_593189, JString, required = false,
                                 default = nil)
  if valid_593189 != nil:
    section.add "X-Amz-Security-Token", valid_593189
  var valid_593190 = header.getOrDefault("X-Amz-Algorithm")
  valid_593190 = validateParameter(valid_593190, JString, required = false,
                                 default = nil)
  if valid_593190 != nil:
    section.add "X-Amz-Algorithm", valid_593190
  var valid_593191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-SignedHeaders", valid_593191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593193: Call_DescribeFleet_593182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a fleet.
  ## 
  let valid = call_593193.validator(path, query, header, formData, body)
  let scheme = call_593193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593193.url(scheme.get, call_593193.host, call_593193.base,
                         call_593193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593193, url, valid)

proc call*(call_593194: Call_DescribeFleet_593182; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_593195 = newJObject()
  if body != nil:
    body_593195 = body
  result = call_593194.call(nil, nil, nil, nil, body_593195)

var describeFleet* = Call_DescribeFleet_593182(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_593183, base: "/",
    url: url_DescribeFleet_593184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_593196 = ref object of OpenApiRestCall_592364
proc url_DescribeRobot_593198(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRobot_593197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593199 = header.getOrDefault("X-Amz-Signature")
  valid_593199 = validateParameter(valid_593199, JString, required = false,
                                 default = nil)
  if valid_593199 != nil:
    section.add "X-Amz-Signature", valid_593199
  var valid_593200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593200 = validateParameter(valid_593200, JString, required = false,
                                 default = nil)
  if valid_593200 != nil:
    section.add "X-Amz-Content-Sha256", valid_593200
  var valid_593201 = header.getOrDefault("X-Amz-Date")
  valid_593201 = validateParameter(valid_593201, JString, required = false,
                                 default = nil)
  if valid_593201 != nil:
    section.add "X-Amz-Date", valid_593201
  var valid_593202 = header.getOrDefault("X-Amz-Credential")
  valid_593202 = validateParameter(valid_593202, JString, required = false,
                                 default = nil)
  if valid_593202 != nil:
    section.add "X-Amz-Credential", valid_593202
  var valid_593203 = header.getOrDefault("X-Amz-Security-Token")
  valid_593203 = validateParameter(valid_593203, JString, required = false,
                                 default = nil)
  if valid_593203 != nil:
    section.add "X-Amz-Security-Token", valid_593203
  var valid_593204 = header.getOrDefault("X-Amz-Algorithm")
  valid_593204 = validateParameter(valid_593204, JString, required = false,
                                 default = nil)
  if valid_593204 != nil:
    section.add "X-Amz-Algorithm", valid_593204
  var valid_593205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593205 = validateParameter(valid_593205, JString, required = false,
                                 default = nil)
  if valid_593205 != nil:
    section.add "X-Amz-SignedHeaders", valid_593205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593207: Call_DescribeRobot_593196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot.
  ## 
  let valid = call_593207.validator(path, query, header, formData, body)
  let scheme = call_593207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593207.url(scheme.get, call_593207.host, call_593207.base,
                         call_593207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593207, url, valid)

proc call*(call_593208: Call_DescribeRobot_593196; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_593209 = newJObject()
  if body != nil:
    body_593209 = body
  result = call_593208.call(nil, nil, nil, nil, body_593209)

var describeRobot* = Call_DescribeRobot_593196(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_593197, base: "/",
    url: url_DescribeRobot_593198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_593210 = ref object of OpenApiRestCall_592364
proc url_DescribeRobotApplication_593212(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRobotApplication_593211(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593213 = header.getOrDefault("X-Amz-Signature")
  valid_593213 = validateParameter(valid_593213, JString, required = false,
                                 default = nil)
  if valid_593213 != nil:
    section.add "X-Amz-Signature", valid_593213
  var valid_593214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593214 = validateParameter(valid_593214, JString, required = false,
                                 default = nil)
  if valid_593214 != nil:
    section.add "X-Amz-Content-Sha256", valid_593214
  var valid_593215 = header.getOrDefault("X-Amz-Date")
  valid_593215 = validateParameter(valid_593215, JString, required = false,
                                 default = nil)
  if valid_593215 != nil:
    section.add "X-Amz-Date", valid_593215
  var valid_593216 = header.getOrDefault("X-Amz-Credential")
  valid_593216 = validateParameter(valid_593216, JString, required = false,
                                 default = nil)
  if valid_593216 != nil:
    section.add "X-Amz-Credential", valid_593216
  var valid_593217 = header.getOrDefault("X-Amz-Security-Token")
  valid_593217 = validateParameter(valid_593217, JString, required = false,
                                 default = nil)
  if valid_593217 != nil:
    section.add "X-Amz-Security-Token", valid_593217
  var valid_593218 = header.getOrDefault("X-Amz-Algorithm")
  valid_593218 = validateParameter(valid_593218, JString, required = false,
                                 default = nil)
  if valid_593218 != nil:
    section.add "X-Amz-Algorithm", valid_593218
  var valid_593219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593219 = validateParameter(valid_593219, JString, required = false,
                                 default = nil)
  if valid_593219 != nil:
    section.add "X-Amz-SignedHeaders", valid_593219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593221: Call_DescribeRobotApplication_593210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot application.
  ## 
  let valid = call_593221.validator(path, query, header, formData, body)
  let scheme = call_593221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593221.url(scheme.get, call_593221.host, call_593221.base,
                         call_593221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593221, url, valid)

proc call*(call_593222: Call_DescribeRobotApplication_593210; body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_593223 = newJObject()
  if body != nil:
    body_593223 = body
  result = call_593222.call(nil, nil, nil, nil, body_593223)

var describeRobotApplication* = Call_DescribeRobotApplication_593210(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_593211, base: "/",
    url: url_DescribeRobotApplication_593212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_593224 = ref object of OpenApiRestCall_592364
proc url_DescribeSimulationApplication_593226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSimulationApplication_593225(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593227 = header.getOrDefault("X-Amz-Signature")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-Signature", valid_593227
  var valid_593228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593228 = validateParameter(valid_593228, JString, required = false,
                                 default = nil)
  if valid_593228 != nil:
    section.add "X-Amz-Content-Sha256", valid_593228
  var valid_593229 = header.getOrDefault("X-Amz-Date")
  valid_593229 = validateParameter(valid_593229, JString, required = false,
                                 default = nil)
  if valid_593229 != nil:
    section.add "X-Amz-Date", valid_593229
  var valid_593230 = header.getOrDefault("X-Amz-Credential")
  valid_593230 = validateParameter(valid_593230, JString, required = false,
                                 default = nil)
  if valid_593230 != nil:
    section.add "X-Amz-Credential", valid_593230
  var valid_593231 = header.getOrDefault("X-Amz-Security-Token")
  valid_593231 = validateParameter(valid_593231, JString, required = false,
                                 default = nil)
  if valid_593231 != nil:
    section.add "X-Amz-Security-Token", valid_593231
  var valid_593232 = header.getOrDefault("X-Amz-Algorithm")
  valid_593232 = validateParameter(valid_593232, JString, required = false,
                                 default = nil)
  if valid_593232 != nil:
    section.add "X-Amz-Algorithm", valid_593232
  var valid_593233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593233 = validateParameter(valid_593233, JString, required = false,
                                 default = nil)
  if valid_593233 != nil:
    section.add "X-Amz-SignedHeaders", valid_593233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593235: Call_DescribeSimulationApplication_593224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation application.
  ## 
  let valid = call_593235.validator(path, query, header, formData, body)
  let scheme = call_593235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593235.url(scheme.get, call_593235.host, call_593235.base,
                         call_593235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593235, url, valid)

proc call*(call_593236: Call_DescribeSimulationApplication_593224; body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_593237 = newJObject()
  if body != nil:
    body_593237 = body
  result = call_593236.call(nil, nil, nil, nil, body_593237)

var describeSimulationApplication* = Call_DescribeSimulationApplication_593224(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_593225, base: "/",
    url: url_DescribeSimulationApplication_593226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_593238 = ref object of OpenApiRestCall_592364
proc url_DescribeSimulationJob_593240(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSimulationJob_593239(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593241 = header.getOrDefault("X-Amz-Signature")
  valid_593241 = validateParameter(valid_593241, JString, required = false,
                                 default = nil)
  if valid_593241 != nil:
    section.add "X-Amz-Signature", valid_593241
  var valid_593242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593242 = validateParameter(valid_593242, JString, required = false,
                                 default = nil)
  if valid_593242 != nil:
    section.add "X-Amz-Content-Sha256", valid_593242
  var valid_593243 = header.getOrDefault("X-Amz-Date")
  valid_593243 = validateParameter(valid_593243, JString, required = false,
                                 default = nil)
  if valid_593243 != nil:
    section.add "X-Amz-Date", valid_593243
  var valid_593244 = header.getOrDefault("X-Amz-Credential")
  valid_593244 = validateParameter(valid_593244, JString, required = false,
                                 default = nil)
  if valid_593244 != nil:
    section.add "X-Amz-Credential", valid_593244
  var valid_593245 = header.getOrDefault("X-Amz-Security-Token")
  valid_593245 = validateParameter(valid_593245, JString, required = false,
                                 default = nil)
  if valid_593245 != nil:
    section.add "X-Amz-Security-Token", valid_593245
  var valid_593246 = header.getOrDefault("X-Amz-Algorithm")
  valid_593246 = validateParameter(valid_593246, JString, required = false,
                                 default = nil)
  if valid_593246 != nil:
    section.add "X-Amz-Algorithm", valid_593246
  var valid_593247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593247 = validateParameter(valid_593247, JString, required = false,
                                 default = nil)
  if valid_593247 != nil:
    section.add "X-Amz-SignedHeaders", valid_593247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593249: Call_DescribeSimulationJob_593238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job.
  ## 
  let valid = call_593249.validator(path, query, header, formData, body)
  let scheme = call_593249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593249.url(scheme.get, call_593249.host, call_593249.base,
                         call_593249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593249, url, valid)

proc call*(call_593250: Call_DescribeSimulationJob_593238; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_593251 = newJObject()
  if body != nil:
    body_593251 = body
  result = call_593250.call(nil, nil, nil, nil, body_593251)

var describeSimulationJob* = Call_DescribeSimulationJob_593238(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_593239, base: "/",
    url: url_DescribeSimulationJob_593240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_593252 = ref object of OpenApiRestCall_592364
proc url_ListDeploymentJobs_593254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentJobs_593253(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593255 = query.getOrDefault("nextToken")
  valid_593255 = validateParameter(valid_593255, JString, required = false,
                                 default = nil)
  if valid_593255 != nil:
    section.add "nextToken", valid_593255
  var valid_593256 = query.getOrDefault("maxResults")
  valid_593256 = validateParameter(valid_593256, JString, required = false,
                                 default = nil)
  if valid_593256 != nil:
    section.add "maxResults", valid_593256
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593257 = header.getOrDefault("X-Amz-Signature")
  valid_593257 = validateParameter(valid_593257, JString, required = false,
                                 default = nil)
  if valid_593257 != nil:
    section.add "X-Amz-Signature", valid_593257
  var valid_593258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593258 = validateParameter(valid_593258, JString, required = false,
                                 default = nil)
  if valid_593258 != nil:
    section.add "X-Amz-Content-Sha256", valid_593258
  var valid_593259 = header.getOrDefault("X-Amz-Date")
  valid_593259 = validateParameter(valid_593259, JString, required = false,
                                 default = nil)
  if valid_593259 != nil:
    section.add "X-Amz-Date", valid_593259
  var valid_593260 = header.getOrDefault("X-Amz-Credential")
  valid_593260 = validateParameter(valid_593260, JString, required = false,
                                 default = nil)
  if valid_593260 != nil:
    section.add "X-Amz-Credential", valid_593260
  var valid_593261 = header.getOrDefault("X-Amz-Security-Token")
  valid_593261 = validateParameter(valid_593261, JString, required = false,
                                 default = nil)
  if valid_593261 != nil:
    section.add "X-Amz-Security-Token", valid_593261
  var valid_593262 = header.getOrDefault("X-Amz-Algorithm")
  valid_593262 = validateParameter(valid_593262, JString, required = false,
                                 default = nil)
  if valid_593262 != nil:
    section.add "X-Amz-Algorithm", valid_593262
  var valid_593263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593263 = validateParameter(valid_593263, JString, required = false,
                                 default = nil)
  if valid_593263 != nil:
    section.add "X-Amz-SignedHeaders", valid_593263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593265: Call_ListDeploymentJobs_593252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  let valid = call_593265.validator(path, query, header, formData, body)
  let scheme = call_593265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593265.url(scheme.get, call_593265.host, call_593265.base,
                         call_593265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593265, url, valid)

proc call*(call_593266: Call_ListDeploymentJobs_593252; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDeploymentJobs
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593267 = newJObject()
  var body_593268 = newJObject()
  add(query_593267, "nextToken", newJString(nextToken))
  if body != nil:
    body_593268 = body
  add(query_593267, "maxResults", newJString(maxResults))
  result = call_593266.call(nil, query_593267, nil, nil, body_593268)

var listDeploymentJobs* = Call_ListDeploymentJobs_593252(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_593253, base: "/",
    url: url_ListDeploymentJobs_593254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_593270 = ref object of OpenApiRestCall_592364
proc url_ListFleets_593272(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFleets_593271(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593273 = query.getOrDefault("nextToken")
  valid_593273 = validateParameter(valid_593273, JString, required = false,
                                 default = nil)
  if valid_593273 != nil:
    section.add "nextToken", valid_593273
  var valid_593274 = query.getOrDefault("maxResults")
  valid_593274 = validateParameter(valid_593274, JString, required = false,
                                 default = nil)
  if valid_593274 != nil:
    section.add "maxResults", valid_593274
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593275 = header.getOrDefault("X-Amz-Signature")
  valid_593275 = validateParameter(valid_593275, JString, required = false,
                                 default = nil)
  if valid_593275 != nil:
    section.add "X-Amz-Signature", valid_593275
  var valid_593276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593276 = validateParameter(valid_593276, JString, required = false,
                                 default = nil)
  if valid_593276 != nil:
    section.add "X-Amz-Content-Sha256", valid_593276
  var valid_593277 = header.getOrDefault("X-Amz-Date")
  valid_593277 = validateParameter(valid_593277, JString, required = false,
                                 default = nil)
  if valid_593277 != nil:
    section.add "X-Amz-Date", valid_593277
  var valid_593278 = header.getOrDefault("X-Amz-Credential")
  valid_593278 = validateParameter(valid_593278, JString, required = false,
                                 default = nil)
  if valid_593278 != nil:
    section.add "X-Amz-Credential", valid_593278
  var valid_593279 = header.getOrDefault("X-Amz-Security-Token")
  valid_593279 = validateParameter(valid_593279, JString, required = false,
                                 default = nil)
  if valid_593279 != nil:
    section.add "X-Amz-Security-Token", valid_593279
  var valid_593280 = header.getOrDefault("X-Amz-Algorithm")
  valid_593280 = validateParameter(valid_593280, JString, required = false,
                                 default = nil)
  if valid_593280 != nil:
    section.add "X-Amz-Algorithm", valid_593280
  var valid_593281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593281 = validateParameter(valid_593281, JString, required = false,
                                 default = nil)
  if valid_593281 != nil:
    section.add "X-Amz-SignedHeaders", valid_593281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593283: Call_ListFleets_593270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  let valid = call_593283.validator(path, query, header, formData, body)
  let scheme = call_593283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593283.url(scheme.get, call_593283.host, call_593283.base,
                         call_593283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593283, url, valid)

proc call*(call_593284: Call_ListFleets_593270; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593285 = newJObject()
  var body_593286 = newJObject()
  add(query_593285, "nextToken", newJString(nextToken))
  if body != nil:
    body_593286 = body
  add(query_593285, "maxResults", newJString(maxResults))
  result = call_593284.call(nil, query_593285, nil, nil, body_593286)

var listFleets* = Call_ListFleets_593270(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_593271,
                                      base: "/", url: url_ListFleets_593272,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_593287 = ref object of OpenApiRestCall_592364
proc url_ListRobotApplications_593289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRobotApplications_593288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593290 = query.getOrDefault("nextToken")
  valid_593290 = validateParameter(valid_593290, JString, required = false,
                                 default = nil)
  if valid_593290 != nil:
    section.add "nextToken", valid_593290
  var valid_593291 = query.getOrDefault("maxResults")
  valid_593291 = validateParameter(valid_593291, JString, required = false,
                                 default = nil)
  if valid_593291 != nil:
    section.add "maxResults", valid_593291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593292 = header.getOrDefault("X-Amz-Signature")
  valid_593292 = validateParameter(valid_593292, JString, required = false,
                                 default = nil)
  if valid_593292 != nil:
    section.add "X-Amz-Signature", valid_593292
  var valid_593293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593293 = validateParameter(valid_593293, JString, required = false,
                                 default = nil)
  if valid_593293 != nil:
    section.add "X-Amz-Content-Sha256", valid_593293
  var valid_593294 = header.getOrDefault("X-Amz-Date")
  valid_593294 = validateParameter(valid_593294, JString, required = false,
                                 default = nil)
  if valid_593294 != nil:
    section.add "X-Amz-Date", valid_593294
  var valid_593295 = header.getOrDefault("X-Amz-Credential")
  valid_593295 = validateParameter(valid_593295, JString, required = false,
                                 default = nil)
  if valid_593295 != nil:
    section.add "X-Amz-Credential", valid_593295
  var valid_593296 = header.getOrDefault("X-Amz-Security-Token")
  valid_593296 = validateParameter(valid_593296, JString, required = false,
                                 default = nil)
  if valid_593296 != nil:
    section.add "X-Amz-Security-Token", valid_593296
  var valid_593297 = header.getOrDefault("X-Amz-Algorithm")
  valid_593297 = validateParameter(valid_593297, JString, required = false,
                                 default = nil)
  if valid_593297 != nil:
    section.add "X-Amz-Algorithm", valid_593297
  var valid_593298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593298 = validateParameter(valid_593298, JString, required = false,
                                 default = nil)
  if valid_593298 != nil:
    section.add "X-Amz-SignedHeaders", valid_593298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593300: Call_ListRobotApplications_593287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  let valid = call_593300.validator(path, query, header, formData, body)
  let scheme = call_593300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593300.url(scheme.get, call_593300.host, call_593300.base,
                         call_593300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593300, url, valid)

proc call*(call_593301: Call_ListRobotApplications_593287; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593302 = newJObject()
  var body_593303 = newJObject()
  add(query_593302, "nextToken", newJString(nextToken))
  if body != nil:
    body_593303 = body
  add(query_593302, "maxResults", newJString(maxResults))
  result = call_593301.call(nil, query_593302, nil, nil, body_593303)

var listRobotApplications* = Call_ListRobotApplications_593287(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_593288, base: "/",
    url: url_ListRobotApplications_593289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_593304 = ref object of OpenApiRestCall_592364
proc url_ListRobots_593306(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRobots_593305(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593307 = query.getOrDefault("nextToken")
  valid_593307 = validateParameter(valid_593307, JString, required = false,
                                 default = nil)
  if valid_593307 != nil:
    section.add "nextToken", valid_593307
  var valid_593308 = query.getOrDefault("maxResults")
  valid_593308 = validateParameter(valid_593308, JString, required = false,
                                 default = nil)
  if valid_593308 != nil:
    section.add "maxResults", valid_593308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593309 = header.getOrDefault("X-Amz-Signature")
  valid_593309 = validateParameter(valid_593309, JString, required = false,
                                 default = nil)
  if valid_593309 != nil:
    section.add "X-Amz-Signature", valid_593309
  var valid_593310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593310 = validateParameter(valid_593310, JString, required = false,
                                 default = nil)
  if valid_593310 != nil:
    section.add "X-Amz-Content-Sha256", valid_593310
  var valid_593311 = header.getOrDefault("X-Amz-Date")
  valid_593311 = validateParameter(valid_593311, JString, required = false,
                                 default = nil)
  if valid_593311 != nil:
    section.add "X-Amz-Date", valid_593311
  var valid_593312 = header.getOrDefault("X-Amz-Credential")
  valid_593312 = validateParameter(valid_593312, JString, required = false,
                                 default = nil)
  if valid_593312 != nil:
    section.add "X-Amz-Credential", valid_593312
  var valid_593313 = header.getOrDefault("X-Amz-Security-Token")
  valid_593313 = validateParameter(valid_593313, JString, required = false,
                                 default = nil)
  if valid_593313 != nil:
    section.add "X-Amz-Security-Token", valid_593313
  var valid_593314 = header.getOrDefault("X-Amz-Algorithm")
  valid_593314 = validateParameter(valid_593314, JString, required = false,
                                 default = nil)
  if valid_593314 != nil:
    section.add "X-Amz-Algorithm", valid_593314
  var valid_593315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593315 = validateParameter(valid_593315, JString, required = false,
                                 default = nil)
  if valid_593315 != nil:
    section.add "X-Amz-SignedHeaders", valid_593315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593317: Call_ListRobots_593304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  let valid = call_593317.validator(path, query, header, formData, body)
  let scheme = call_593317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593317.url(scheme.get, call_593317.host, call_593317.base,
                         call_593317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593317, url, valid)

proc call*(call_593318: Call_ListRobots_593304; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593319 = newJObject()
  var body_593320 = newJObject()
  add(query_593319, "nextToken", newJString(nextToken))
  if body != nil:
    body_593320 = body
  add(query_593319, "maxResults", newJString(maxResults))
  result = call_593318.call(nil, query_593319, nil, nil, body_593320)

var listRobots* = Call_ListRobots_593304(name: "listRobots",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listRobots",
                                      validator: validate_ListRobots_593305,
                                      base: "/", url: url_ListRobots_593306,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_593321 = ref object of OpenApiRestCall_592364
proc url_ListSimulationApplications_593323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSimulationApplications_593322(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593324 = query.getOrDefault("nextToken")
  valid_593324 = validateParameter(valid_593324, JString, required = false,
                                 default = nil)
  if valid_593324 != nil:
    section.add "nextToken", valid_593324
  var valid_593325 = query.getOrDefault("maxResults")
  valid_593325 = validateParameter(valid_593325, JString, required = false,
                                 default = nil)
  if valid_593325 != nil:
    section.add "maxResults", valid_593325
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593326 = header.getOrDefault("X-Amz-Signature")
  valid_593326 = validateParameter(valid_593326, JString, required = false,
                                 default = nil)
  if valid_593326 != nil:
    section.add "X-Amz-Signature", valid_593326
  var valid_593327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593327 = validateParameter(valid_593327, JString, required = false,
                                 default = nil)
  if valid_593327 != nil:
    section.add "X-Amz-Content-Sha256", valid_593327
  var valid_593328 = header.getOrDefault("X-Amz-Date")
  valid_593328 = validateParameter(valid_593328, JString, required = false,
                                 default = nil)
  if valid_593328 != nil:
    section.add "X-Amz-Date", valid_593328
  var valid_593329 = header.getOrDefault("X-Amz-Credential")
  valid_593329 = validateParameter(valid_593329, JString, required = false,
                                 default = nil)
  if valid_593329 != nil:
    section.add "X-Amz-Credential", valid_593329
  var valid_593330 = header.getOrDefault("X-Amz-Security-Token")
  valid_593330 = validateParameter(valid_593330, JString, required = false,
                                 default = nil)
  if valid_593330 != nil:
    section.add "X-Amz-Security-Token", valid_593330
  var valid_593331 = header.getOrDefault("X-Amz-Algorithm")
  valid_593331 = validateParameter(valid_593331, JString, required = false,
                                 default = nil)
  if valid_593331 != nil:
    section.add "X-Amz-Algorithm", valid_593331
  var valid_593332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593332 = validateParameter(valid_593332, JString, required = false,
                                 default = nil)
  if valid_593332 != nil:
    section.add "X-Amz-SignedHeaders", valid_593332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593334: Call_ListSimulationApplications_593321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  let valid = call_593334.validator(path, query, header, formData, body)
  let scheme = call_593334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593334.url(scheme.get, call_593334.host, call_593334.base,
                         call_593334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593334, url, valid)

proc call*(call_593335: Call_ListSimulationApplications_593321; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593336 = newJObject()
  var body_593337 = newJObject()
  add(query_593336, "nextToken", newJString(nextToken))
  if body != nil:
    body_593337 = body
  add(query_593336, "maxResults", newJString(maxResults))
  result = call_593335.call(nil, query_593336, nil, nil, body_593337)

var listSimulationApplications* = Call_ListSimulationApplications_593321(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_593322, base: "/",
    url: url_ListSimulationApplications_593323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_593338 = ref object of OpenApiRestCall_592364
proc url_ListSimulationJobs_593340(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSimulationJobs_593339(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Pagination token
  ##   maxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_593341 = query.getOrDefault("nextToken")
  valid_593341 = validateParameter(valid_593341, JString, required = false,
                                 default = nil)
  if valid_593341 != nil:
    section.add "nextToken", valid_593341
  var valid_593342 = query.getOrDefault("maxResults")
  valid_593342 = validateParameter(valid_593342, JString, required = false,
                                 default = nil)
  if valid_593342 != nil:
    section.add "maxResults", valid_593342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593343 = header.getOrDefault("X-Amz-Signature")
  valid_593343 = validateParameter(valid_593343, JString, required = false,
                                 default = nil)
  if valid_593343 != nil:
    section.add "X-Amz-Signature", valid_593343
  var valid_593344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593344 = validateParameter(valid_593344, JString, required = false,
                                 default = nil)
  if valid_593344 != nil:
    section.add "X-Amz-Content-Sha256", valid_593344
  var valid_593345 = header.getOrDefault("X-Amz-Date")
  valid_593345 = validateParameter(valid_593345, JString, required = false,
                                 default = nil)
  if valid_593345 != nil:
    section.add "X-Amz-Date", valid_593345
  var valid_593346 = header.getOrDefault("X-Amz-Credential")
  valid_593346 = validateParameter(valid_593346, JString, required = false,
                                 default = nil)
  if valid_593346 != nil:
    section.add "X-Amz-Credential", valid_593346
  var valid_593347 = header.getOrDefault("X-Amz-Security-Token")
  valid_593347 = validateParameter(valid_593347, JString, required = false,
                                 default = nil)
  if valid_593347 != nil:
    section.add "X-Amz-Security-Token", valid_593347
  var valid_593348 = header.getOrDefault("X-Amz-Algorithm")
  valid_593348 = validateParameter(valid_593348, JString, required = false,
                                 default = nil)
  if valid_593348 != nil:
    section.add "X-Amz-Algorithm", valid_593348
  var valid_593349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593349 = validateParameter(valid_593349, JString, required = false,
                                 default = nil)
  if valid_593349 != nil:
    section.add "X-Amz-SignedHeaders", valid_593349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593351: Call_ListSimulationJobs_593338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  let valid = call_593351.validator(path, query, header, formData, body)
  let scheme = call_593351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593351.url(scheme.get, call_593351.host, call_593351.base,
                         call_593351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593351, url, valid)

proc call*(call_593352: Call_ListSimulationJobs_593338; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_593353 = newJObject()
  var body_593354 = newJObject()
  add(query_593353, "nextToken", newJString(nextToken))
  if body != nil:
    body_593354 = body
  add(query_593353, "maxResults", newJString(maxResults))
  result = call_593352.call(nil, query_593353, nil, nil, body_593354)

var listSimulationJobs* = Call_ListSimulationJobs_593338(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_593339, base: "/",
    url: url_ListSimulationJobs_593340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593383 = ref object of OpenApiRestCall_592364
proc url_TagResource_593385(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_TagResource_593384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593386 = path.getOrDefault("resourceArn")
  valid_593386 = validateParameter(valid_593386, JString, required = true,
                                 default = nil)
  if valid_593386 != nil:
    section.add "resourceArn", valid_593386
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593387 = header.getOrDefault("X-Amz-Signature")
  valid_593387 = validateParameter(valid_593387, JString, required = false,
                                 default = nil)
  if valid_593387 != nil:
    section.add "X-Amz-Signature", valid_593387
  var valid_593388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593388 = validateParameter(valid_593388, JString, required = false,
                                 default = nil)
  if valid_593388 != nil:
    section.add "X-Amz-Content-Sha256", valid_593388
  var valid_593389 = header.getOrDefault("X-Amz-Date")
  valid_593389 = validateParameter(valid_593389, JString, required = false,
                                 default = nil)
  if valid_593389 != nil:
    section.add "X-Amz-Date", valid_593389
  var valid_593390 = header.getOrDefault("X-Amz-Credential")
  valid_593390 = validateParameter(valid_593390, JString, required = false,
                                 default = nil)
  if valid_593390 != nil:
    section.add "X-Amz-Credential", valid_593390
  var valid_593391 = header.getOrDefault("X-Amz-Security-Token")
  valid_593391 = validateParameter(valid_593391, JString, required = false,
                                 default = nil)
  if valid_593391 != nil:
    section.add "X-Amz-Security-Token", valid_593391
  var valid_593392 = header.getOrDefault("X-Amz-Algorithm")
  valid_593392 = validateParameter(valid_593392, JString, required = false,
                                 default = nil)
  if valid_593392 != nil:
    section.add "X-Amz-Algorithm", valid_593392
  var valid_593393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593393 = validateParameter(valid_593393, JString, required = false,
                                 default = nil)
  if valid_593393 != nil:
    section.add "X-Amz-SignedHeaders", valid_593393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593395: Call_TagResource_593383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  let valid = call_593395.validator(path, query, header, formData, body)
  let scheme = call_593395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593395.url(scheme.get, call_593395.host, call_593395.base,
                         call_593395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593395, url, valid)

proc call*(call_593396: Call_TagResource_593383; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  ##   body: JObject (required)
  var path_593397 = newJObject()
  var body_593398 = newJObject()
  add(path_593397, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_593398 = body
  result = call_593396.call(path_593397, nil, nil, nil, body_593398)

var tagResource* = Call_TagResource_593383(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_593384,
                                        base: "/", url: url_TagResource_593385,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593355 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593357(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_ListTagsForResource_593356(path: JsonNode; query: JsonNode;
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
  var valid_593372 = path.getOrDefault("resourceArn")
  valid_593372 = validateParameter(valid_593372, JString, required = true,
                                 default = nil)
  if valid_593372 != nil:
    section.add "resourceArn", valid_593372
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593373 = header.getOrDefault("X-Amz-Signature")
  valid_593373 = validateParameter(valid_593373, JString, required = false,
                                 default = nil)
  if valid_593373 != nil:
    section.add "X-Amz-Signature", valid_593373
  var valid_593374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593374 = validateParameter(valid_593374, JString, required = false,
                                 default = nil)
  if valid_593374 != nil:
    section.add "X-Amz-Content-Sha256", valid_593374
  var valid_593375 = header.getOrDefault("X-Amz-Date")
  valid_593375 = validateParameter(valid_593375, JString, required = false,
                                 default = nil)
  if valid_593375 != nil:
    section.add "X-Amz-Date", valid_593375
  var valid_593376 = header.getOrDefault("X-Amz-Credential")
  valid_593376 = validateParameter(valid_593376, JString, required = false,
                                 default = nil)
  if valid_593376 != nil:
    section.add "X-Amz-Credential", valid_593376
  var valid_593377 = header.getOrDefault("X-Amz-Security-Token")
  valid_593377 = validateParameter(valid_593377, JString, required = false,
                                 default = nil)
  if valid_593377 != nil:
    section.add "X-Amz-Security-Token", valid_593377
  var valid_593378 = header.getOrDefault("X-Amz-Algorithm")
  valid_593378 = validateParameter(valid_593378, JString, required = false,
                                 default = nil)
  if valid_593378 != nil:
    section.add "X-Amz-Algorithm", valid_593378
  var valid_593379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593379 = validateParameter(valid_593379, JString, required = false,
                                 default = nil)
  if valid_593379 != nil:
    section.add "X-Amz-SignedHeaders", valid_593379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593380: Call_ListTagsForResource_593355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  let valid = call_593380.validator(path, query, header, formData, body)
  let scheme = call_593380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593380.url(scheme.get, call_593380.host, call_593380.base,
                         call_593380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593380, url, valid)

proc call*(call_593381: Call_ListTagsForResource_593355; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_593382 = newJObject()
  add(path_593382, "resourceArn", newJString(resourceArn))
  result = call_593381.call(path_593382, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593355(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_593356, base: "/",
    url: url_ListTagsForResource_593357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_593399 = ref object of OpenApiRestCall_592364
proc url_RegisterRobot_593401(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterRobot_593400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593402 = header.getOrDefault("X-Amz-Signature")
  valid_593402 = validateParameter(valid_593402, JString, required = false,
                                 default = nil)
  if valid_593402 != nil:
    section.add "X-Amz-Signature", valid_593402
  var valid_593403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593403 = validateParameter(valid_593403, JString, required = false,
                                 default = nil)
  if valid_593403 != nil:
    section.add "X-Amz-Content-Sha256", valid_593403
  var valid_593404 = header.getOrDefault("X-Amz-Date")
  valid_593404 = validateParameter(valid_593404, JString, required = false,
                                 default = nil)
  if valid_593404 != nil:
    section.add "X-Amz-Date", valid_593404
  var valid_593405 = header.getOrDefault("X-Amz-Credential")
  valid_593405 = validateParameter(valid_593405, JString, required = false,
                                 default = nil)
  if valid_593405 != nil:
    section.add "X-Amz-Credential", valid_593405
  var valid_593406 = header.getOrDefault("X-Amz-Security-Token")
  valid_593406 = validateParameter(valid_593406, JString, required = false,
                                 default = nil)
  if valid_593406 != nil:
    section.add "X-Amz-Security-Token", valid_593406
  var valid_593407 = header.getOrDefault("X-Amz-Algorithm")
  valid_593407 = validateParameter(valid_593407, JString, required = false,
                                 default = nil)
  if valid_593407 != nil:
    section.add "X-Amz-Algorithm", valid_593407
  var valid_593408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593408 = validateParameter(valid_593408, JString, required = false,
                                 default = nil)
  if valid_593408 != nil:
    section.add "X-Amz-SignedHeaders", valid_593408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593410: Call_RegisterRobot_593399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a robot with a fleet.
  ## 
  let valid = call_593410.validator(path, query, header, formData, body)
  let scheme = call_593410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593410.url(scheme.get, call_593410.host, call_593410.base,
                         call_593410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593410, url, valid)

proc call*(call_593411: Call_RegisterRobot_593399; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_593412 = newJObject()
  if body != nil:
    body_593412 = body
  result = call_593411.call(nil, nil, nil, nil, body_593412)

var registerRobot* = Call_RegisterRobot_593399(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_593400, base: "/",
    url: url_RegisterRobot_593401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_593413 = ref object of OpenApiRestCall_592364
proc url_RestartSimulationJob_593415(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestartSimulationJob_593414(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593416 = header.getOrDefault("X-Amz-Signature")
  valid_593416 = validateParameter(valid_593416, JString, required = false,
                                 default = nil)
  if valid_593416 != nil:
    section.add "X-Amz-Signature", valid_593416
  var valid_593417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593417 = validateParameter(valid_593417, JString, required = false,
                                 default = nil)
  if valid_593417 != nil:
    section.add "X-Amz-Content-Sha256", valid_593417
  var valid_593418 = header.getOrDefault("X-Amz-Date")
  valid_593418 = validateParameter(valid_593418, JString, required = false,
                                 default = nil)
  if valid_593418 != nil:
    section.add "X-Amz-Date", valid_593418
  var valid_593419 = header.getOrDefault("X-Amz-Credential")
  valid_593419 = validateParameter(valid_593419, JString, required = false,
                                 default = nil)
  if valid_593419 != nil:
    section.add "X-Amz-Credential", valid_593419
  var valid_593420 = header.getOrDefault("X-Amz-Security-Token")
  valid_593420 = validateParameter(valid_593420, JString, required = false,
                                 default = nil)
  if valid_593420 != nil:
    section.add "X-Amz-Security-Token", valid_593420
  var valid_593421 = header.getOrDefault("X-Amz-Algorithm")
  valid_593421 = validateParameter(valid_593421, JString, required = false,
                                 default = nil)
  if valid_593421 != nil:
    section.add "X-Amz-Algorithm", valid_593421
  var valid_593422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593422 = validateParameter(valid_593422, JString, required = false,
                                 default = nil)
  if valid_593422 != nil:
    section.add "X-Amz-SignedHeaders", valid_593422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593424: Call_RestartSimulationJob_593413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts a running simulation job.
  ## 
  let valid = call_593424.validator(path, query, header, formData, body)
  let scheme = call_593424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593424.url(scheme.get, call_593424.host, call_593424.base,
                         call_593424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593424, url, valid)

proc call*(call_593425: Call_RestartSimulationJob_593413; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_593426 = newJObject()
  if body != nil:
    body_593426 = body
  result = call_593425.call(nil, nil, nil, nil, body_593426)

var restartSimulationJob* = Call_RestartSimulationJob_593413(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_593414, base: "/",
    url: url_RestartSimulationJob_593415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_593427 = ref object of OpenApiRestCall_592364
proc url_SyncDeploymentJob_593429(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SyncDeploymentJob_593428(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593430 = header.getOrDefault("X-Amz-Signature")
  valid_593430 = validateParameter(valid_593430, JString, required = false,
                                 default = nil)
  if valid_593430 != nil:
    section.add "X-Amz-Signature", valid_593430
  var valid_593431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593431 = validateParameter(valid_593431, JString, required = false,
                                 default = nil)
  if valid_593431 != nil:
    section.add "X-Amz-Content-Sha256", valid_593431
  var valid_593432 = header.getOrDefault("X-Amz-Date")
  valid_593432 = validateParameter(valid_593432, JString, required = false,
                                 default = nil)
  if valid_593432 != nil:
    section.add "X-Amz-Date", valid_593432
  var valid_593433 = header.getOrDefault("X-Amz-Credential")
  valid_593433 = validateParameter(valid_593433, JString, required = false,
                                 default = nil)
  if valid_593433 != nil:
    section.add "X-Amz-Credential", valid_593433
  var valid_593434 = header.getOrDefault("X-Amz-Security-Token")
  valid_593434 = validateParameter(valid_593434, JString, required = false,
                                 default = nil)
  if valid_593434 != nil:
    section.add "X-Amz-Security-Token", valid_593434
  var valid_593435 = header.getOrDefault("X-Amz-Algorithm")
  valid_593435 = validateParameter(valid_593435, JString, required = false,
                                 default = nil)
  if valid_593435 != nil:
    section.add "X-Amz-Algorithm", valid_593435
  var valid_593436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593436 = validateParameter(valid_593436, JString, required = false,
                                 default = nil)
  if valid_593436 != nil:
    section.add "X-Amz-SignedHeaders", valid_593436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593438: Call_SyncDeploymentJob_593427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  let valid = call_593438.validator(path, query, header, formData, body)
  let scheme = call_593438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593438.url(scheme.get, call_593438.host, call_593438.base,
                         call_593438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593438, url, valid)

proc call*(call_593439: Call_SyncDeploymentJob_593427; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   body: JObject (required)
  var body_593440 = newJObject()
  if body != nil:
    body_593440 = body
  result = call_593439.call(nil, nil, nil, nil, body_593440)

var syncDeploymentJob* = Call_SyncDeploymentJob_593427(name: "syncDeploymentJob",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/syncDeploymentJob", validator: validate_SyncDeploymentJob_593428,
    base: "/", url: url_SyncDeploymentJob_593429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593441 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593443(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  result.path = base & hydrated.get

proc validate_UntagResource_593442(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593444 = path.getOrDefault("resourceArn")
  valid_593444 = validateParameter(valid_593444, JString, required = true,
                                 default = nil)
  if valid_593444 != nil:
    section.add "resourceArn", valid_593444
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593445 = query.getOrDefault("tagKeys")
  valid_593445 = validateParameter(valid_593445, JArray, required = true, default = nil)
  if valid_593445 != nil:
    section.add "tagKeys", valid_593445
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593446 = header.getOrDefault("X-Amz-Signature")
  valid_593446 = validateParameter(valid_593446, JString, required = false,
                                 default = nil)
  if valid_593446 != nil:
    section.add "X-Amz-Signature", valid_593446
  var valid_593447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593447 = validateParameter(valid_593447, JString, required = false,
                                 default = nil)
  if valid_593447 != nil:
    section.add "X-Amz-Content-Sha256", valid_593447
  var valid_593448 = header.getOrDefault("X-Amz-Date")
  valid_593448 = validateParameter(valid_593448, JString, required = false,
                                 default = nil)
  if valid_593448 != nil:
    section.add "X-Amz-Date", valid_593448
  var valid_593449 = header.getOrDefault("X-Amz-Credential")
  valid_593449 = validateParameter(valid_593449, JString, required = false,
                                 default = nil)
  if valid_593449 != nil:
    section.add "X-Amz-Credential", valid_593449
  var valid_593450 = header.getOrDefault("X-Amz-Security-Token")
  valid_593450 = validateParameter(valid_593450, JString, required = false,
                                 default = nil)
  if valid_593450 != nil:
    section.add "X-Amz-Security-Token", valid_593450
  var valid_593451 = header.getOrDefault("X-Amz-Algorithm")
  valid_593451 = validateParameter(valid_593451, JString, required = false,
                                 default = nil)
  if valid_593451 != nil:
    section.add "X-Amz-Algorithm", valid_593451
  var valid_593452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593452 = validateParameter(valid_593452, JString, required = false,
                                 default = nil)
  if valid_593452 != nil:
    section.add "X-Amz-SignedHeaders", valid_593452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593453: Call_UntagResource_593441; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  let valid = call_593453.validator(path, query, header, formData, body)
  let scheme = call_593453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593453.url(scheme.get, call_593453.host, call_593453.base,
                         call_593453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593453, url, valid)

proc call*(call_593454: Call_UntagResource_593441; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  var path_593455 = newJObject()
  var query_593456 = newJObject()
  add(path_593455, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_593456.add "tagKeys", tagKeys
  result = call_593454.call(path_593455, query_593456, nil, nil, nil)

var untagResource* = Call_UntagResource_593441(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_593442,
    base: "/", url: url_UntagResource_593443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_593457 = ref object of OpenApiRestCall_592364
proc url_UpdateRobotApplication_593459(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRobotApplication_593458(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593460 = header.getOrDefault("X-Amz-Signature")
  valid_593460 = validateParameter(valid_593460, JString, required = false,
                                 default = nil)
  if valid_593460 != nil:
    section.add "X-Amz-Signature", valid_593460
  var valid_593461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593461 = validateParameter(valid_593461, JString, required = false,
                                 default = nil)
  if valid_593461 != nil:
    section.add "X-Amz-Content-Sha256", valid_593461
  var valid_593462 = header.getOrDefault("X-Amz-Date")
  valid_593462 = validateParameter(valid_593462, JString, required = false,
                                 default = nil)
  if valid_593462 != nil:
    section.add "X-Amz-Date", valid_593462
  var valid_593463 = header.getOrDefault("X-Amz-Credential")
  valid_593463 = validateParameter(valid_593463, JString, required = false,
                                 default = nil)
  if valid_593463 != nil:
    section.add "X-Amz-Credential", valid_593463
  var valid_593464 = header.getOrDefault("X-Amz-Security-Token")
  valid_593464 = validateParameter(valid_593464, JString, required = false,
                                 default = nil)
  if valid_593464 != nil:
    section.add "X-Amz-Security-Token", valid_593464
  var valid_593465 = header.getOrDefault("X-Amz-Algorithm")
  valid_593465 = validateParameter(valid_593465, JString, required = false,
                                 default = nil)
  if valid_593465 != nil:
    section.add "X-Amz-Algorithm", valid_593465
  var valid_593466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593466 = validateParameter(valid_593466, JString, required = false,
                                 default = nil)
  if valid_593466 != nil:
    section.add "X-Amz-SignedHeaders", valid_593466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593468: Call_UpdateRobotApplication_593457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a robot application.
  ## 
  let valid = call_593468.validator(path, query, header, formData, body)
  let scheme = call_593468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593468.url(scheme.get, call_593468.host, call_593468.base,
                         call_593468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593468, url, valid)

proc call*(call_593469: Call_UpdateRobotApplication_593457; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_593470 = newJObject()
  if body != nil:
    body_593470 = body
  result = call_593469.call(nil, nil, nil, nil, body_593470)

var updateRobotApplication* = Call_UpdateRobotApplication_593457(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_593458, base: "/",
    url: url_UpdateRobotApplication_593459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_593471 = ref object of OpenApiRestCall_592364
proc url_UpdateSimulationApplication_593473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSimulationApplication_593472(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_593474 = header.getOrDefault("X-Amz-Signature")
  valid_593474 = validateParameter(valid_593474, JString, required = false,
                                 default = nil)
  if valid_593474 != nil:
    section.add "X-Amz-Signature", valid_593474
  var valid_593475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593475 = validateParameter(valid_593475, JString, required = false,
                                 default = nil)
  if valid_593475 != nil:
    section.add "X-Amz-Content-Sha256", valid_593475
  var valid_593476 = header.getOrDefault("X-Amz-Date")
  valid_593476 = validateParameter(valid_593476, JString, required = false,
                                 default = nil)
  if valid_593476 != nil:
    section.add "X-Amz-Date", valid_593476
  var valid_593477 = header.getOrDefault("X-Amz-Credential")
  valid_593477 = validateParameter(valid_593477, JString, required = false,
                                 default = nil)
  if valid_593477 != nil:
    section.add "X-Amz-Credential", valid_593477
  var valid_593478 = header.getOrDefault("X-Amz-Security-Token")
  valid_593478 = validateParameter(valid_593478, JString, required = false,
                                 default = nil)
  if valid_593478 != nil:
    section.add "X-Amz-Security-Token", valid_593478
  var valid_593479 = header.getOrDefault("X-Amz-Algorithm")
  valid_593479 = validateParameter(valid_593479, JString, required = false,
                                 default = nil)
  if valid_593479 != nil:
    section.add "X-Amz-Algorithm", valid_593479
  var valid_593480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593480 = validateParameter(valid_593480, JString, required = false,
                                 default = nil)
  if valid_593480 != nil:
    section.add "X-Amz-SignedHeaders", valid_593480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593482: Call_UpdateSimulationApplication_593471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a simulation application.
  ## 
  let valid = call_593482.validator(path, query, header, formData, body)
  let scheme = call_593482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593482.url(scheme.get, call_593482.host, call_593482.base,
                         call_593482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593482, url, valid)

proc call*(call_593483: Call_UpdateSimulationApplication_593471; body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_593484 = newJObject()
  if body != nil:
    body_593484 = body
  result = call_593483.call(nil, nil, nil, nil, body_593484)

var updateSimulationApplication* = Call_UpdateSimulationApplication_593471(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_593472, base: "/",
    url: url_UpdateSimulationApplication_593473,
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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)

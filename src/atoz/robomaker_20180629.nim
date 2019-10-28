
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

  OpenApiRestCall_590364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_590364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_590364): Option[Scheme] {.used.} =
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
  Call_BatchDescribeSimulationJob_590703 = ref object of OpenApiRestCall_590364
proc url_BatchDescribeSimulationJob_590705(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_BatchDescribeSimulationJob_590704(path: JsonNode; query: JsonNode;
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
  var valid_590817 = header.getOrDefault("X-Amz-Signature")
  valid_590817 = validateParameter(valid_590817, JString, required = false,
                                 default = nil)
  if valid_590817 != nil:
    section.add "X-Amz-Signature", valid_590817
  var valid_590818 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590818 = validateParameter(valid_590818, JString, required = false,
                                 default = nil)
  if valid_590818 != nil:
    section.add "X-Amz-Content-Sha256", valid_590818
  var valid_590819 = header.getOrDefault("X-Amz-Date")
  valid_590819 = validateParameter(valid_590819, JString, required = false,
                                 default = nil)
  if valid_590819 != nil:
    section.add "X-Amz-Date", valid_590819
  var valid_590820 = header.getOrDefault("X-Amz-Credential")
  valid_590820 = validateParameter(valid_590820, JString, required = false,
                                 default = nil)
  if valid_590820 != nil:
    section.add "X-Amz-Credential", valid_590820
  var valid_590821 = header.getOrDefault("X-Amz-Security-Token")
  valid_590821 = validateParameter(valid_590821, JString, required = false,
                                 default = nil)
  if valid_590821 != nil:
    section.add "X-Amz-Security-Token", valid_590821
  var valid_590822 = header.getOrDefault("X-Amz-Algorithm")
  valid_590822 = validateParameter(valid_590822, JString, required = false,
                                 default = nil)
  if valid_590822 != nil:
    section.add "X-Amz-Algorithm", valid_590822
  var valid_590823 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590823 = validateParameter(valid_590823, JString, required = false,
                                 default = nil)
  if valid_590823 != nil:
    section.add "X-Amz-SignedHeaders", valid_590823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590847: Call_BatchDescribeSimulationJob_590703; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more simulation jobs.
  ## 
  let valid = call_590847.validator(path, query, header, formData, body)
  let scheme = call_590847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590847.url(scheme.get, call_590847.host, call_590847.base,
                         call_590847.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590847, url, valid)

proc call*(call_590918: Call_BatchDescribeSimulationJob_590703; body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_590919 = newJObject()
  if body != nil:
    body_590919 = body
  result = call_590918.call(nil, nil, nil, nil, body_590919)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_590703(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_590704, base: "/",
    url: url_BatchDescribeSimulationJob_590705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_590958 = ref object of OpenApiRestCall_590364
proc url_CancelDeploymentJob_590960(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelDeploymentJob_590959(path: JsonNode; query: JsonNode;
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
  var valid_590961 = header.getOrDefault("X-Amz-Signature")
  valid_590961 = validateParameter(valid_590961, JString, required = false,
                                 default = nil)
  if valid_590961 != nil:
    section.add "X-Amz-Signature", valid_590961
  var valid_590962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590962 = validateParameter(valid_590962, JString, required = false,
                                 default = nil)
  if valid_590962 != nil:
    section.add "X-Amz-Content-Sha256", valid_590962
  var valid_590963 = header.getOrDefault("X-Amz-Date")
  valid_590963 = validateParameter(valid_590963, JString, required = false,
                                 default = nil)
  if valid_590963 != nil:
    section.add "X-Amz-Date", valid_590963
  var valid_590964 = header.getOrDefault("X-Amz-Credential")
  valid_590964 = validateParameter(valid_590964, JString, required = false,
                                 default = nil)
  if valid_590964 != nil:
    section.add "X-Amz-Credential", valid_590964
  var valid_590965 = header.getOrDefault("X-Amz-Security-Token")
  valid_590965 = validateParameter(valid_590965, JString, required = false,
                                 default = nil)
  if valid_590965 != nil:
    section.add "X-Amz-Security-Token", valid_590965
  var valid_590966 = header.getOrDefault("X-Amz-Algorithm")
  valid_590966 = validateParameter(valid_590966, JString, required = false,
                                 default = nil)
  if valid_590966 != nil:
    section.add "X-Amz-Algorithm", valid_590966
  var valid_590967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590967 = validateParameter(valid_590967, JString, required = false,
                                 default = nil)
  if valid_590967 != nil:
    section.add "X-Amz-SignedHeaders", valid_590967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590969: Call_CancelDeploymentJob_590958; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified deployment job.
  ## 
  let valid = call_590969.validator(path, query, header, formData, body)
  let scheme = call_590969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590969.url(scheme.get, call_590969.host, call_590969.base,
                         call_590969.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590969, url, valid)

proc call*(call_590970: Call_CancelDeploymentJob_590958; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_590971 = newJObject()
  if body != nil:
    body_590971 = body
  result = call_590970.call(nil, nil, nil, nil, body_590971)

var cancelDeploymentJob* = Call_CancelDeploymentJob_590958(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_590959, base: "/",
    url: url_CancelDeploymentJob_590960, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_590972 = ref object of OpenApiRestCall_590364
proc url_CancelSimulationJob_590974(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CancelSimulationJob_590973(path: JsonNode; query: JsonNode;
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
  var valid_590975 = header.getOrDefault("X-Amz-Signature")
  valid_590975 = validateParameter(valid_590975, JString, required = false,
                                 default = nil)
  if valid_590975 != nil:
    section.add "X-Amz-Signature", valid_590975
  var valid_590976 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590976 = validateParameter(valid_590976, JString, required = false,
                                 default = nil)
  if valid_590976 != nil:
    section.add "X-Amz-Content-Sha256", valid_590976
  var valid_590977 = header.getOrDefault("X-Amz-Date")
  valid_590977 = validateParameter(valid_590977, JString, required = false,
                                 default = nil)
  if valid_590977 != nil:
    section.add "X-Amz-Date", valid_590977
  var valid_590978 = header.getOrDefault("X-Amz-Credential")
  valid_590978 = validateParameter(valid_590978, JString, required = false,
                                 default = nil)
  if valid_590978 != nil:
    section.add "X-Amz-Credential", valid_590978
  var valid_590979 = header.getOrDefault("X-Amz-Security-Token")
  valid_590979 = validateParameter(valid_590979, JString, required = false,
                                 default = nil)
  if valid_590979 != nil:
    section.add "X-Amz-Security-Token", valid_590979
  var valid_590980 = header.getOrDefault("X-Amz-Algorithm")
  valid_590980 = validateParameter(valid_590980, JString, required = false,
                                 default = nil)
  if valid_590980 != nil:
    section.add "X-Amz-Algorithm", valid_590980
  var valid_590981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590981 = validateParameter(valid_590981, JString, required = false,
                                 default = nil)
  if valid_590981 != nil:
    section.add "X-Amz-SignedHeaders", valid_590981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590983: Call_CancelSimulationJob_590972; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified simulation job.
  ## 
  let valid = call_590983.validator(path, query, header, formData, body)
  let scheme = call_590983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590983.url(scheme.get, call_590983.host, call_590983.base,
                         call_590983.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590983, url, valid)

proc call*(call_590984: Call_CancelSimulationJob_590972; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_590985 = newJObject()
  if body != nil:
    body_590985 = body
  result = call_590984.call(nil, nil, nil, nil, body_590985)

var cancelSimulationJob* = Call_CancelSimulationJob_590972(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_590973, base: "/",
    url: url_CancelSimulationJob_590974, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_590986 = ref object of OpenApiRestCall_590364
proc url_CreateDeploymentJob_590988(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateDeploymentJob_590987(path: JsonNode; query: JsonNode;
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
  var valid_590989 = header.getOrDefault("X-Amz-Signature")
  valid_590989 = validateParameter(valid_590989, JString, required = false,
                                 default = nil)
  if valid_590989 != nil:
    section.add "X-Amz-Signature", valid_590989
  var valid_590990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_590990 = validateParameter(valid_590990, JString, required = false,
                                 default = nil)
  if valid_590990 != nil:
    section.add "X-Amz-Content-Sha256", valid_590990
  var valid_590991 = header.getOrDefault("X-Amz-Date")
  valid_590991 = validateParameter(valid_590991, JString, required = false,
                                 default = nil)
  if valid_590991 != nil:
    section.add "X-Amz-Date", valid_590991
  var valid_590992 = header.getOrDefault("X-Amz-Credential")
  valid_590992 = validateParameter(valid_590992, JString, required = false,
                                 default = nil)
  if valid_590992 != nil:
    section.add "X-Amz-Credential", valid_590992
  var valid_590993 = header.getOrDefault("X-Amz-Security-Token")
  valid_590993 = validateParameter(valid_590993, JString, required = false,
                                 default = nil)
  if valid_590993 != nil:
    section.add "X-Amz-Security-Token", valid_590993
  var valid_590994 = header.getOrDefault("X-Amz-Algorithm")
  valid_590994 = validateParameter(valid_590994, JString, required = false,
                                 default = nil)
  if valid_590994 != nil:
    section.add "X-Amz-Algorithm", valid_590994
  var valid_590995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_590995 = validateParameter(valid_590995, JString, required = false,
                                 default = nil)
  if valid_590995 != nil:
    section.add "X-Amz-SignedHeaders", valid_590995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_590997: Call_CreateDeploymentJob_590986; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_590997.validator(path, query, header, formData, body)
  let scheme = call_590997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_590997.url(scheme.get, call_590997.host, call_590997.base,
                         call_590997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_590997, url, valid)

proc call*(call_590998: Call_CreateDeploymentJob_590986; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_590999 = newJObject()
  if body != nil:
    body_590999 = body
  result = call_590998.call(nil, nil, nil, nil, body_590999)

var createDeploymentJob* = Call_CreateDeploymentJob_590986(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_590987, base: "/",
    url: url_CreateDeploymentJob_590988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_591000 = ref object of OpenApiRestCall_590364
proc url_CreateFleet_591002(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateFleet_591001(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591003 = header.getOrDefault("X-Amz-Signature")
  valid_591003 = validateParameter(valid_591003, JString, required = false,
                                 default = nil)
  if valid_591003 != nil:
    section.add "X-Amz-Signature", valid_591003
  var valid_591004 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591004 = validateParameter(valid_591004, JString, required = false,
                                 default = nil)
  if valid_591004 != nil:
    section.add "X-Amz-Content-Sha256", valid_591004
  var valid_591005 = header.getOrDefault("X-Amz-Date")
  valid_591005 = validateParameter(valid_591005, JString, required = false,
                                 default = nil)
  if valid_591005 != nil:
    section.add "X-Amz-Date", valid_591005
  var valid_591006 = header.getOrDefault("X-Amz-Credential")
  valid_591006 = validateParameter(valid_591006, JString, required = false,
                                 default = nil)
  if valid_591006 != nil:
    section.add "X-Amz-Credential", valid_591006
  var valid_591007 = header.getOrDefault("X-Amz-Security-Token")
  valid_591007 = validateParameter(valid_591007, JString, required = false,
                                 default = nil)
  if valid_591007 != nil:
    section.add "X-Amz-Security-Token", valid_591007
  var valid_591008 = header.getOrDefault("X-Amz-Algorithm")
  valid_591008 = validateParameter(valid_591008, JString, required = false,
                                 default = nil)
  if valid_591008 != nil:
    section.add "X-Amz-Algorithm", valid_591008
  var valid_591009 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591009 = validateParameter(valid_591009, JString, required = false,
                                 default = nil)
  if valid_591009 != nil:
    section.add "X-Amz-SignedHeaders", valid_591009
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591011: Call_CreateFleet_591000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  let valid = call_591011.validator(path, query, header, formData, body)
  let scheme = call_591011.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591011.url(scheme.get, call_591011.host, call_591011.base,
                         call_591011.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591011, url, valid)

proc call*(call_591012: Call_CreateFleet_591000; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   body: JObject (required)
  var body_591013 = newJObject()
  if body != nil:
    body_591013 = body
  result = call_591012.call(nil, nil, nil, nil, body_591013)

var createFleet* = Call_CreateFleet_591000(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_591001,
                                        base: "/", url: url_CreateFleet_591002,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_591014 = ref object of OpenApiRestCall_590364
proc url_CreateRobot_591016(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobot_591015(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591017 = header.getOrDefault("X-Amz-Signature")
  valid_591017 = validateParameter(valid_591017, JString, required = false,
                                 default = nil)
  if valid_591017 != nil:
    section.add "X-Amz-Signature", valid_591017
  var valid_591018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591018 = validateParameter(valid_591018, JString, required = false,
                                 default = nil)
  if valid_591018 != nil:
    section.add "X-Amz-Content-Sha256", valid_591018
  var valid_591019 = header.getOrDefault("X-Amz-Date")
  valid_591019 = validateParameter(valid_591019, JString, required = false,
                                 default = nil)
  if valid_591019 != nil:
    section.add "X-Amz-Date", valid_591019
  var valid_591020 = header.getOrDefault("X-Amz-Credential")
  valid_591020 = validateParameter(valid_591020, JString, required = false,
                                 default = nil)
  if valid_591020 != nil:
    section.add "X-Amz-Credential", valid_591020
  var valid_591021 = header.getOrDefault("X-Amz-Security-Token")
  valid_591021 = validateParameter(valid_591021, JString, required = false,
                                 default = nil)
  if valid_591021 != nil:
    section.add "X-Amz-Security-Token", valid_591021
  var valid_591022 = header.getOrDefault("X-Amz-Algorithm")
  valid_591022 = validateParameter(valid_591022, JString, required = false,
                                 default = nil)
  if valid_591022 != nil:
    section.add "X-Amz-Algorithm", valid_591022
  var valid_591023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591023 = validateParameter(valid_591023, JString, required = false,
                                 default = nil)
  if valid_591023 != nil:
    section.add "X-Amz-SignedHeaders", valid_591023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591025: Call_CreateRobot_591014; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot.
  ## 
  let valid = call_591025.validator(path, query, header, formData, body)
  let scheme = call_591025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591025.url(scheme.get, call_591025.host, call_591025.base,
                         call_591025.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591025, url, valid)

proc call*(call_591026: Call_CreateRobot_591014; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_591027 = newJObject()
  if body != nil:
    body_591027 = body
  result = call_591026.call(nil, nil, nil, nil, body_591027)

var createRobot* = Call_CreateRobot_591014(name: "createRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createRobot",
                                        validator: validate_CreateRobot_591015,
                                        base: "/", url: url_CreateRobot_591016,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_591028 = ref object of OpenApiRestCall_590364
proc url_CreateRobotApplication_591030(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobotApplication_591029(path: JsonNode; query: JsonNode;
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
  var valid_591031 = header.getOrDefault("X-Amz-Signature")
  valid_591031 = validateParameter(valid_591031, JString, required = false,
                                 default = nil)
  if valid_591031 != nil:
    section.add "X-Amz-Signature", valid_591031
  var valid_591032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591032 = validateParameter(valid_591032, JString, required = false,
                                 default = nil)
  if valid_591032 != nil:
    section.add "X-Amz-Content-Sha256", valid_591032
  var valid_591033 = header.getOrDefault("X-Amz-Date")
  valid_591033 = validateParameter(valid_591033, JString, required = false,
                                 default = nil)
  if valid_591033 != nil:
    section.add "X-Amz-Date", valid_591033
  var valid_591034 = header.getOrDefault("X-Amz-Credential")
  valid_591034 = validateParameter(valid_591034, JString, required = false,
                                 default = nil)
  if valid_591034 != nil:
    section.add "X-Amz-Credential", valid_591034
  var valid_591035 = header.getOrDefault("X-Amz-Security-Token")
  valid_591035 = validateParameter(valid_591035, JString, required = false,
                                 default = nil)
  if valid_591035 != nil:
    section.add "X-Amz-Security-Token", valid_591035
  var valid_591036 = header.getOrDefault("X-Amz-Algorithm")
  valid_591036 = validateParameter(valid_591036, JString, required = false,
                                 default = nil)
  if valid_591036 != nil:
    section.add "X-Amz-Algorithm", valid_591036
  var valid_591037 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591037 = validateParameter(valid_591037, JString, required = false,
                                 default = nil)
  if valid_591037 != nil:
    section.add "X-Amz-SignedHeaders", valid_591037
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591039: Call_CreateRobotApplication_591028; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot application. 
  ## 
  let valid = call_591039.validator(path, query, header, formData, body)
  let scheme = call_591039.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591039.url(scheme.get, call_591039.host, call_591039.base,
                         call_591039.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591039, url, valid)

proc call*(call_591040: Call_CreateRobotApplication_591028; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_591041 = newJObject()
  if body != nil:
    body_591041 = body
  result = call_591040.call(nil, nil, nil, nil, body_591041)

var createRobotApplication* = Call_CreateRobotApplication_591028(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_591029, base: "/",
    url: url_CreateRobotApplication_591030, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_591042 = ref object of OpenApiRestCall_590364
proc url_CreateRobotApplicationVersion_591044(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateRobotApplicationVersion_591043(path: JsonNode; query: JsonNode;
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
  var valid_591045 = header.getOrDefault("X-Amz-Signature")
  valid_591045 = validateParameter(valid_591045, JString, required = false,
                                 default = nil)
  if valid_591045 != nil:
    section.add "X-Amz-Signature", valid_591045
  var valid_591046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591046 = validateParameter(valid_591046, JString, required = false,
                                 default = nil)
  if valid_591046 != nil:
    section.add "X-Amz-Content-Sha256", valid_591046
  var valid_591047 = header.getOrDefault("X-Amz-Date")
  valid_591047 = validateParameter(valid_591047, JString, required = false,
                                 default = nil)
  if valid_591047 != nil:
    section.add "X-Amz-Date", valid_591047
  var valid_591048 = header.getOrDefault("X-Amz-Credential")
  valid_591048 = validateParameter(valid_591048, JString, required = false,
                                 default = nil)
  if valid_591048 != nil:
    section.add "X-Amz-Credential", valid_591048
  var valid_591049 = header.getOrDefault("X-Amz-Security-Token")
  valid_591049 = validateParameter(valid_591049, JString, required = false,
                                 default = nil)
  if valid_591049 != nil:
    section.add "X-Amz-Security-Token", valid_591049
  var valid_591050 = header.getOrDefault("X-Amz-Algorithm")
  valid_591050 = validateParameter(valid_591050, JString, required = false,
                                 default = nil)
  if valid_591050 != nil:
    section.add "X-Amz-Algorithm", valid_591050
  var valid_591051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591051 = validateParameter(valid_591051, JString, required = false,
                                 default = nil)
  if valid_591051 != nil:
    section.add "X-Amz-SignedHeaders", valid_591051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591053: Call_CreateRobotApplicationVersion_591042; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a robot application.
  ## 
  let valid = call_591053.validator(path, query, header, formData, body)
  let scheme = call_591053.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591053.url(scheme.get, call_591053.host, call_591053.base,
                         call_591053.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591053, url, valid)

proc call*(call_591054: Call_CreateRobotApplicationVersion_591042; body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_591055 = newJObject()
  if body != nil:
    body_591055 = body
  result = call_591054.call(nil, nil, nil, nil, body_591055)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_591042(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_591043, base: "/",
    url: url_CreateRobotApplicationVersion_591044,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_591056 = ref object of OpenApiRestCall_590364
proc url_CreateSimulationApplication_591058(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationApplication_591057(path: JsonNode; query: JsonNode;
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
  var valid_591059 = header.getOrDefault("X-Amz-Signature")
  valid_591059 = validateParameter(valid_591059, JString, required = false,
                                 default = nil)
  if valid_591059 != nil:
    section.add "X-Amz-Signature", valid_591059
  var valid_591060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591060 = validateParameter(valid_591060, JString, required = false,
                                 default = nil)
  if valid_591060 != nil:
    section.add "X-Amz-Content-Sha256", valid_591060
  var valid_591061 = header.getOrDefault("X-Amz-Date")
  valid_591061 = validateParameter(valid_591061, JString, required = false,
                                 default = nil)
  if valid_591061 != nil:
    section.add "X-Amz-Date", valid_591061
  var valid_591062 = header.getOrDefault("X-Amz-Credential")
  valid_591062 = validateParameter(valid_591062, JString, required = false,
                                 default = nil)
  if valid_591062 != nil:
    section.add "X-Amz-Credential", valid_591062
  var valid_591063 = header.getOrDefault("X-Amz-Security-Token")
  valid_591063 = validateParameter(valid_591063, JString, required = false,
                                 default = nil)
  if valid_591063 != nil:
    section.add "X-Amz-Security-Token", valid_591063
  var valid_591064 = header.getOrDefault("X-Amz-Algorithm")
  valid_591064 = validateParameter(valid_591064, JString, required = false,
                                 default = nil)
  if valid_591064 != nil:
    section.add "X-Amz-Algorithm", valid_591064
  var valid_591065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591065 = validateParameter(valid_591065, JString, required = false,
                                 default = nil)
  if valid_591065 != nil:
    section.add "X-Amz-SignedHeaders", valid_591065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591067: Call_CreateSimulationApplication_591056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a simulation application.
  ## 
  let valid = call_591067.validator(path, query, header, formData, body)
  let scheme = call_591067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591067.url(scheme.get, call_591067.host, call_591067.base,
                         call_591067.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591067, url, valid)

proc call*(call_591068: Call_CreateSimulationApplication_591056; body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_591069 = newJObject()
  if body != nil:
    body_591069 = body
  result = call_591068.call(nil, nil, nil, nil, body_591069)

var createSimulationApplication* = Call_CreateSimulationApplication_591056(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_591057, base: "/",
    url: url_CreateSimulationApplication_591058,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_591070 = ref object of OpenApiRestCall_590364
proc url_CreateSimulationApplicationVersion_591072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationApplicationVersion_591071(path: JsonNode;
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
  var valid_591073 = header.getOrDefault("X-Amz-Signature")
  valid_591073 = validateParameter(valid_591073, JString, required = false,
                                 default = nil)
  if valid_591073 != nil:
    section.add "X-Amz-Signature", valid_591073
  var valid_591074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591074 = validateParameter(valid_591074, JString, required = false,
                                 default = nil)
  if valid_591074 != nil:
    section.add "X-Amz-Content-Sha256", valid_591074
  var valid_591075 = header.getOrDefault("X-Amz-Date")
  valid_591075 = validateParameter(valid_591075, JString, required = false,
                                 default = nil)
  if valid_591075 != nil:
    section.add "X-Amz-Date", valid_591075
  var valid_591076 = header.getOrDefault("X-Amz-Credential")
  valid_591076 = validateParameter(valid_591076, JString, required = false,
                                 default = nil)
  if valid_591076 != nil:
    section.add "X-Amz-Credential", valid_591076
  var valid_591077 = header.getOrDefault("X-Amz-Security-Token")
  valid_591077 = validateParameter(valid_591077, JString, required = false,
                                 default = nil)
  if valid_591077 != nil:
    section.add "X-Amz-Security-Token", valid_591077
  var valid_591078 = header.getOrDefault("X-Amz-Algorithm")
  valid_591078 = validateParameter(valid_591078, JString, required = false,
                                 default = nil)
  if valid_591078 != nil:
    section.add "X-Amz-Algorithm", valid_591078
  var valid_591079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591079 = validateParameter(valid_591079, JString, required = false,
                                 default = nil)
  if valid_591079 != nil:
    section.add "X-Amz-SignedHeaders", valid_591079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591081: Call_CreateSimulationApplicationVersion_591070;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a simulation application with a specific revision id.
  ## 
  let valid = call_591081.validator(path, query, header, formData, body)
  let scheme = call_591081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591081.url(scheme.get, call_591081.host, call_591081.base,
                         call_591081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591081, url, valid)

proc call*(call_591082: Call_CreateSimulationApplicationVersion_591070;
          body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_591083 = newJObject()
  if body != nil:
    body_591083 = body
  result = call_591082.call(nil, nil, nil, nil, body_591083)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_591070(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_591071, base: "/",
    url: url_CreateSimulationApplicationVersion_591072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_591084 = ref object of OpenApiRestCall_590364
proc url_CreateSimulationJob_591086(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateSimulationJob_591085(path: JsonNode; query: JsonNode;
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
  var valid_591087 = header.getOrDefault("X-Amz-Signature")
  valid_591087 = validateParameter(valid_591087, JString, required = false,
                                 default = nil)
  if valid_591087 != nil:
    section.add "X-Amz-Signature", valid_591087
  var valid_591088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591088 = validateParameter(valid_591088, JString, required = false,
                                 default = nil)
  if valid_591088 != nil:
    section.add "X-Amz-Content-Sha256", valid_591088
  var valid_591089 = header.getOrDefault("X-Amz-Date")
  valid_591089 = validateParameter(valid_591089, JString, required = false,
                                 default = nil)
  if valid_591089 != nil:
    section.add "X-Amz-Date", valid_591089
  var valid_591090 = header.getOrDefault("X-Amz-Credential")
  valid_591090 = validateParameter(valid_591090, JString, required = false,
                                 default = nil)
  if valid_591090 != nil:
    section.add "X-Amz-Credential", valid_591090
  var valid_591091 = header.getOrDefault("X-Amz-Security-Token")
  valid_591091 = validateParameter(valid_591091, JString, required = false,
                                 default = nil)
  if valid_591091 != nil:
    section.add "X-Amz-Security-Token", valid_591091
  var valid_591092 = header.getOrDefault("X-Amz-Algorithm")
  valid_591092 = validateParameter(valid_591092, JString, required = false,
                                 default = nil)
  if valid_591092 != nil:
    section.add "X-Amz-Algorithm", valid_591092
  var valid_591093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591093 = validateParameter(valid_591093, JString, required = false,
                                 default = nil)
  if valid_591093 != nil:
    section.add "X-Amz-SignedHeaders", valid_591093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591095: Call_CreateSimulationJob_591084; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_591095.validator(path, query, header, formData, body)
  let scheme = call_591095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591095.url(scheme.get, call_591095.host, call_591095.base,
                         call_591095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591095, url, valid)

proc call*(call_591096: Call_CreateSimulationJob_591084; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_591097 = newJObject()
  if body != nil:
    body_591097 = body
  result = call_591096.call(nil, nil, nil, nil, body_591097)

var createSimulationJob* = Call_CreateSimulationJob_591084(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_591085, base: "/",
    url: url_CreateSimulationJob_591086, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_591098 = ref object of OpenApiRestCall_590364
proc url_DeleteFleet_591100(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteFleet_591099(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591101 = header.getOrDefault("X-Amz-Signature")
  valid_591101 = validateParameter(valid_591101, JString, required = false,
                                 default = nil)
  if valid_591101 != nil:
    section.add "X-Amz-Signature", valid_591101
  var valid_591102 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591102 = validateParameter(valid_591102, JString, required = false,
                                 default = nil)
  if valid_591102 != nil:
    section.add "X-Amz-Content-Sha256", valid_591102
  var valid_591103 = header.getOrDefault("X-Amz-Date")
  valid_591103 = validateParameter(valid_591103, JString, required = false,
                                 default = nil)
  if valid_591103 != nil:
    section.add "X-Amz-Date", valid_591103
  var valid_591104 = header.getOrDefault("X-Amz-Credential")
  valid_591104 = validateParameter(valid_591104, JString, required = false,
                                 default = nil)
  if valid_591104 != nil:
    section.add "X-Amz-Credential", valid_591104
  var valid_591105 = header.getOrDefault("X-Amz-Security-Token")
  valid_591105 = validateParameter(valid_591105, JString, required = false,
                                 default = nil)
  if valid_591105 != nil:
    section.add "X-Amz-Security-Token", valid_591105
  var valid_591106 = header.getOrDefault("X-Amz-Algorithm")
  valid_591106 = validateParameter(valid_591106, JString, required = false,
                                 default = nil)
  if valid_591106 != nil:
    section.add "X-Amz-Algorithm", valid_591106
  var valid_591107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591107 = validateParameter(valid_591107, JString, required = false,
                                 default = nil)
  if valid_591107 != nil:
    section.add "X-Amz-SignedHeaders", valid_591107
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591109: Call_DeleteFleet_591098; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet.
  ## 
  let valid = call_591109.validator(path, query, header, formData, body)
  let scheme = call_591109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591109.url(scheme.get, call_591109.host, call_591109.base,
                         call_591109.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591109, url, valid)

proc call*(call_591110: Call_DeleteFleet_591098; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_591111 = newJObject()
  if body != nil:
    body_591111 = body
  result = call_591110.call(nil, nil, nil, nil, body_591111)

var deleteFleet* = Call_DeleteFleet_591098(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_591099,
                                        base: "/", url: url_DeleteFleet_591100,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_591112 = ref object of OpenApiRestCall_590364
proc url_DeleteRobot_591114(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRobot_591113(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591115 = header.getOrDefault("X-Amz-Signature")
  valid_591115 = validateParameter(valid_591115, JString, required = false,
                                 default = nil)
  if valid_591115 != nil:
    section.add "X-Amz-Signature", valid_591115
  var valid_591116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591116 = validateParameter(valid_591116, JString, required = false,
                                 default = nil)
  if valid_591116 != nil:
    section.add "X-Amz-Content-Sha256", valid_591116
  var valid_591117 = header.getOrDefault("X-Amz-Date")
  valid_591117 = validateParameter(valid_591117, JString, required = false,
                                 default = nil)
  if valid_591117 != nil:
    section.add "X-Amz-Date", valid_591117
  var valid_591118 = header.getOrDefault("X-Amz-Credential")
  valid_591118 = validateParameter(valid_591118, JString, required = false,
                                 default = nil)
  if valid_591118 != nil:
    section.add "X-Amz-Credential", valid_591118
  var valid_591119 = header.getOrDefault("X-Amz-Security-Token")
  valid_591119 = validateParameter(valid_591119, JString, required = false,
                                 default = nil)
  if valid_591119 != nil:
    section.add "X-Amz-Security-Token", valid_591119
  var valid_591120 = header.getOrDefault("X-Amz-Algorithm")
  valid_591120 = validateParameter(valid_591120, JString, required = false,
                                 default = nil)
  if valid_591120 != nil:
    section.add "X-Amz-Algorithm", valid_591120
  var valid_591121 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591121 = validateParameter(valid_591121, JString, required = false,
                                 default = nil)
  if valid_591121 != nil:
    section.add "X-Amz-SignedHeaders", valid_591121
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591123: Call_DeleteRobot_591112; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot.
  ## 
  let valid = call_591123.validator(path, query, header, formData, body)
  let scheme = call_591123.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591123.url(scheme.get, call_591123.host, call_591123.base,
                         call_591123.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591123, url, valid)

proc call*(call_591124: Call_DeleteRobot_591112; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_591125 = newJObject()
  if body != nil:
    body_591125 = body
  result = call_591124.call(nil, nil, nil, nil, body_591125)

var deleteRobot* = Call_DeleteRobot_591112(name: "deleteRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteRobot",
                                        validator: validate_DeleteRobot_591113,
                                        base: "/", url: url_DeleteRobot_591114,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_591126 = ref object of OpenApiRestCall_590364
proc url_DeleteRobotApplication_591128(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteRobotApplication_591127(path: JsonNode; query: JsonNode;
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
  var valid_591129 = header.getOrDefault("X-Amz-Signature")
  valid_591129 = validateParameter(valid_591129, JString, required = false,
                                 default = nil)
  if valid_591129 != nil:
    section.add "X-Amz-Signature", valid_591129
  var valid_591130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591130 = validateParameter(valid_591130, JString, required = false,
                                 default = nil)
  if valid_591130 != nil:
    section.add "X-Amz-Content-Sha256", valid_591130
  var valid_591131 = header.getOrDefault("X-Amz-Date")
  valid_591131 = validateParameter(valid_591131, JString, required = false,
                                 default = nil)
  if valid_591131 != nil:
    section.add "X-Amz-Date", valid_591131
  var valid_591132 = header.getOrDefault("X-Amz-Credential")
  valid_591132 = validateParameter(valid_591132, JString, required = false,
                                 default = nil)
  if valid_591132 != nil:
    section.add "X-Amz-Credential", valid_591132
  var valid_591133 = header.getOrDefault("X-Amz-Security-Token")
  valid_591133 = validateParameter(valid_591133, JString, required = false,
                                 default = nil)
  if valid_591133 != nil:
    section.add "X-Amz-Security-Token", valid_591133
  var valid_591134 = header.getOrDefault("X-Amz-Algorithm")
  valid_591134 = validateParameter(valid_591134, JString, required = false,
                                 default = nil)
  if valid_591134 != nil:
    section.add "X-Amz-Algorithm", valid_591134
  var valid_591135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591135 = validateParameter(valid_591135, JString, required = false,
                                 default = nil)
  if valid_591135 != nil:
    section.add "X-Amz-SignedHeaders", valid_591135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591137: Call_DeleteRobotApplication_591126; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot application.
  ## 
  let valid = call_591137.validator(path, query, header, formData, body)
  let scheme = call_591137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591137.url(scheme.get, call_591137.host, call_591137.base,
                         call_591137.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591137, url, valid)

proc call*(call_591138: Call_DeleteRobotApplication_591126; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_591139 = newJObject()
  if body != nil:
    body_591139 = body
  result = call_591138.call(nil, nil, nil, nil, body_591139)

var deleteRobotApplication* = Call_DeleteRobotApplication_591126(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_591127, base: "/",
    url: url_DeleteRobotApplication_591128, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_591140 = ref object of OpenApiRestCall_590364
proc url_DeleteSimulationApplication_591142(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeleteSimulationApplication_591141(path: JsonNode; query: JsonNode;
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
  var valid_591143 = header.getOrDefault("X-Amz-Signature")
  valid_591143 = validateParameter(valid_591143, JString, required = false,
                                 default = nil)
  if valid_591143 != nil:
    section.add "X-Amz-Signature", valid_591143
  var valid_591144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591144 = validateParameter(valid_591144, JString, required = false,
                                 default = nil)
  if valid_591144 != nil:
    section.add "X-Amz-Content-Sha256", valid_591144
  var valid_591145 = header.getOrDefault("X-Amz-Date")
  valid_591145 = validateParameter(valid_591145, JString, required = false,
                                 default = nil)
  if valid_591145 != nil:
    section.add "X-Amz-Date", valid_591145
  var valid_591146 = header.getOrDefault("X-Amz-Credential")
  valid_591146 = validateParameter(valid_591146, JString, required = false,
                                 default = nil)
  if valid_591146 != nil:
    section.add "X-Amz-Credential", valid_591146
  var valid_591147 = header.getOrDefault("X-Amz-Security-Token")
  valid_591147 = validateParameter(valid_591147, JString, required = false,
                                 default = nil)
  if valid_591147 != nil:
    section.add "X-Amz-Security-Token", valid_591147
  var valid_591148 = header.getOrDefault("X-Amz-Algorithm")
  valid_591148 = validateParameter(valid_591148, JString, required = false,
                                 default = nil)
  if valid_591148 != nil:
    section.add "X-Amz-Algorithm", valid_591148
  var valid_591149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591149 = validateParameter(valid_591149, JString, required = false,
                                 default = nil)
  if valid_591149 != nil:
    section.add "X-Amz-SignedHeaders", valid_591149
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591151: Call_DeleteSimulationApplication_591140; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a simulation application.
  ## 
  let valid = call_591151.validator(path, query, header, formData, body)
  let scheme = call_591151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591151.url(scheme.get, call_591151.host, call_591151.base,
                         call_591151.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591151, url, valid)

proc call*(call_591152: Call_DeleteSimulationApplication_591140; body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_591153 = newJObject()
  if body != nil:
    body_591153 = body
  result = call_591152.call(nil, nil, nil, nil, body_591153)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_591140(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_591141, base: "/",
    url: url_DeleteSimulationApplication_591142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_591154 = ref object of OpenApiRestCall_590364
proc url_DeregisterRobot_591156(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DeregisterRobot_591155(path: JsonNode; query: JsonNode;
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
  var valid_591157 = header.getOrDefault("X-Amz-Signature")
  valid_591157 = validateParameter(valid_591157, JString, required = false,
                                 default = nil)
  if valid_591157 != nil:
    section.add "X-Amz-Signature", valid_591157
  var valid_591158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591158 = validateParameter(valid_591158, JString, required = false,
                                 default = nil)
  if valid_591158 != nil:
    section.add "X-Amz-Content-Sha256", valid_591158
  var valid_591159 = header.getOrDefault("X-Amz-Date")
  valid_591159 = validateParameter(valid_591159, JString, required = false,
                                 default = nil)
  if valid_591159 != nil:
    section.add "X-Amz-Date", valid_591159
  var valid_591160 = header.getOrDefault("X-Amz-Credential")
  valid_591160 = validateParameter(valid_591160, JString, required = false,
                                 default = nil)
  if valid_591160 != nil:
    section.add "X-Amz-Credential", valid_591160
  var valid_591161 = header.getOrDefault("X-Amz-Security-Token")
  valid_591161 = validateParameter(valid_591161, JString, required = false,
                                 default = nil)
  if valid_591161 != nil:
    section.add "X-Amz-Security-Token", valid_591161
  var valid_591162 = header.getOrDefault("X-Amz-Algorithm")
  valid_591162 = validateParameter(valid_591162, JString, required = false,
                                 default = nil)
  if valid_591162 != nil:
    section.add "X-Amz-Algorithm", valid_591162
  var valid_591163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591163 = validateParameter(valid_591163, JString, required = false,
                                 default = nil)
  if valid_591163 != nil:
    section.add "X-Amz-SignedHeaders", valid_591163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591165: Call_DeregisterRobot_591154; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a robot.
  ## 
  let valid = call_591165.validator(path, query, header, formData, body)
  let scheme = call_591165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591165.url(scheme.get, call_591165.host, call_591165.base,
                         call_591165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591165, url, valid)

proc call*(call_591166: Call_DeregisterRobot_591154; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_591167 = newJObject()
  if body != nil:
    body_591167 = body
  result = call_591166.call(nil, nil, nil, nil, body_591167)

var deregisterRobot* = Call_DeregisterRobot_591154(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_591155,
    base: "/", url: url_DeregisterRobot_591156, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_591168 = ref object of OpenApiRestCall_590364
proc url_DescribeDeploymentJob_591170(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeDeploymentJob_591169(path: JsonNode; query: JsonNode;
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
  var valid_591171 = header.getOrDefault("X-Amz-Signature")
  valid_591171 = validateParameter(valid_591171, JString, required = false,
                                 default = nil)
  if valid_591171 != nil:
    section.add "X-Amz-Signature", valid_591171
  var valid_591172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591172 = validateParameter(valid_591172, JString, required = false,
                                 default = nil)
  if valid_591172 != nil:
    section.add "X-Amz-Content-Sha256", valid_591172
  var valid_591173 = header.getOrDefault("X-Amz-Date")
  valid_591173 = validateParameter(valid_591173, JString, required = false,
                                 default = nil)
  if valid_591173 != nil:
    section.add "X-Amz-Date", valid_591173
  var valid_591174 = header.getOrDefault("X-Amz-Credential")
  valid_591174 = validateParameter(valid_591174, JString, required = false,
                                 default = nil)
  if valid_591174 != nil:
    section.add "X-Amz-Credential", valid_591174
  var valid_591175 = header.getOrDefault("X-Amz-Security-Token")
  valid_591175 = validateParameter(valid_591175, JString, required = false,
                                 default = nil)
  if valid_591175 != nil:
    section.add "X-Amz-Security-Token", valid_591175
  var valid_591176 = header.getOrDefault("X-Amz-Algorithm")
  valid_591176 = validateParameter(valid_591176, JString, required = false,
                                 default = nil)
  if valid_591176 != nil:
    section.add "X-Amz-Algorithm", valid_591176
  var valid_591177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591177 = validateParameter(valid_591177, JString, required = false,
                                 default = nil)
  if valid_591177 != nil:
    section.add "X-Amz-SignedHeaders", valid_591177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591179: Call_DescribeDeploymentJob_591168; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a deployment job.
  ## 
  let valid = call_591179.validator(path, query, header, formData, body)
  let scheme = call_591179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591179.url(scheme.get, call_591179.host, call_591179.base,
                         call_591179.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591179, url, valid)

proc call*(call_591180: Call_DescribeDeploymentJob_591168; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_591181 = newJObject()
  if body != nil:
    body_591181 = body
  result = call_591180.call(nil, nil, nil, nil, body_591181)

var describeDeploymentJob* = Call_DescribeDeploymentJob_591168(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_591169, base: "/",
    url: url_DescribeDeploymentJob_591170, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_591182 = ref object of OpenApiRestCall_590364
proc url_DescribeFleet_591184(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeFleet_591183(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591185 = header.getOrDefault("X-Amz-Signature")
  valid_591185 = validateParameter(valid_591185, JString, required = false,
                                 default = nil)
  if valid_591185 != nil:
    section.add "X-Amz-Signature", valid_591185
  var valid_591186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591186 = validateParameter(valid_591186, JString, required = false,
                                 default = nil)
  if valid_591186 != nil:
    section.add "X-Amz-Content-Sha256", valid_591186
  var valid_591187 = header.getOrDefault("X-Amz-Date")
  valid_591187 = validateParameter(valid_591187, JString, required = false,
                                 default = nil)
  if valid_591187 != nil:
    section.add "X-Amz-Date", valid_591187
  var valid_591188 = header.getOrDefault("X-Amz-Credential")
  valid_591188 = validateParameter(valid_591188, JString, required = false,
                                 default = nil)
  if valid_591188 != nil:
    section.add "X-Amz-Credential", valid_591188
  var valid_591189 = header.getOrDefault("X-Amz-Security-Token")
  valid_591189 = validateParameter(valid_591189, JString, required = false,
                                 default = nil)
  if valid_591189 != nil:
    section.add "X-Amz-Security-Token", valid_591189
  var valid_591190 = header.getOrDefault("X-Amz-Algorithm")
  valid_591190 = validateParameter(valid_591190, JString, required = false,
                                 default = nil)
  if valid_591190 != nil:
    section.add "X-Amz-Algorithm", valid_591190
  var valid_591191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591191 = validateParameter(valid_591191, JString, required = false,
                                 default = nil)
  if valid_591191 != nil:
    section.add "X-Amz-SignedHeaders", valid_591191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591193: Call_DescribeFleet_591182; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a fleet.
  ## 
  let valid = call_591193.validator(path, query, header, formData, body)
  let scheme = call_591193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591193.url(scheme.get, call_591193.host, call_591193.base,
                         call_591193.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591193, url, valid)

proc call*(call_591194: Call_DescribeFleet_591182; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_591195 = newJObject()
  if body != nil:
    body_591195 = body
  result = call_591194.call(nil, nil, nil, nil, body_591195)

var describeFleet* = Call_DescribeFleet_591182(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_591183, base: "/",
    url: url_DescribeFleet_591184, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_591196 = ref object of OpenApiRestCall_590364
proc url_DescribeRobot_591198(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRobot_591197(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591199 = header.getOrDefault("X-Amz-Signature")
  valid_591199 = validateParameter(valid_591199, JString, required = false,
                                 default = nil)
  if valid_591199 != nil:
    section.add "X-Amz-Signature", valid_591199
  var valid_591200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591200 = validateParameter(valid_591200, JString, required = false,
                                 default = nil)
  if valid_591200 != nil:
    section.add "X-Amz-Content-Sha256", valid_591200
  var valid_591201 = header.getOrDefault("X-Amz-Date")
  valid_591201 = validateParameter(valid_591201, JString, required = false,
                                 default = nil)
  if valid_591201 != nil:
    section.add "X-Amz-Date", valid_591201
  var valid_591202 = header.getOrDefault("X-Amz-Credential")
  valid_591202 = validateParameter(valid_591202, JString, required = false,
                                 default = nil)
  if valid_591202 != nil:
    section.add "X-Amz-Credential", valid_591202
  var valid_591203 = header.getOrDefault("X-Amz-Security-Token")
  valid_591203 = validateParameter(valid_591203, JString, required = false,
                                 default = nil)
  if valid_591203 != nil:
    section.add "X-Amz-Security-Token", valid_591203
  var valid_591204 = header.getOrDefault("X-Amz-Algorithm")
  valid_591204 = validateParameter(valid_591204, JString, required = false,
                                 default = nil)
  if valid_591204 != nil:
    section.add "X-Amz-Algorithm", valid_591204
  var valid_591205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591205 = validateParameter(valid_591205, JString, required = false,
                                 default = nil)
  if valid_591205 != nil:
    section.add "X-Amz-SignedHeaders", valid_591205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591207: Call_DescribeRobot_591196; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot.
  ## 
  let valid = call_591207.validator(path, query, header, formData, body)
  let scheme = call_591207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591207.url(scheme.get, call_591207.host, call_591207.base,
                         call_591207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591207, url, valid)

proc call*(call_591208: Call_DescribeRobot_591196; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_591209 = newJObject()
  if body != nil:
    body_591209 = body
  result = call_591208.call(nil, nil, nil, nil, body_591209)

var describeRobot* = Call_DescribeRobot_591196(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_591197, base: "/",
    url: url_DescribeRobot_591198, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_591210 = ref object of OpenApiRestCall_590364
proc url_DescribeRobotApplication_591212(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeRobotApplication_591211(path: JsonNode; query: JsonNode;
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
  var valid_591213 = header.getOrDefault("X-Amz-Signature")
  valid_591213 = validateParameter(valid_591213, JString, required = false,
                                 default = nil)
  if valid_591213 != nil:
    section.add "X-Amz-Signature", valid_591213
  var valid_591214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591214 = validateParameter(valid_591214, JString, required = false,
                                 default = nil)
  if valid_591214 != nil:
    section.add "X-Amz-Content-Sha256", valid_591214
  var valid_591215 = header.getOrDefault("X-Amz-Date")
  valid_591215 = validateParameter(valid_591215, JString, required = false,
                                 default = nil)
  if valid_591215 != nil:
    section.add "X-Amz-Date", valid_591215
  var valid_591216 = header.getOrDefault("X-Amz-Credential")
  valid_591216 = validateParameter(valid_591216, JString, required = false,
                                 default = nil)
  if valid_591216 != nil:
    section.add "X-Amz-Credential", valid_591216
  var valid_591217 = header.getOrDefault("X-Amz-Security-Token")
  valid_591217 = validateParameter(valid_591217, JString, required = false,
                                 default = nil)
  if valid_591217 != nil:
    section.add "X-Amz-Security-Token", valid_591217
  var valid_591218 = header.getOrDefault("X-Amz-Algorithm")
  valid_591218 = validateParameter(valid_591218, JString, required = false,
                                 default = nil)
  if valid_591218 != nil:
    section.add "X-Amz-Algorithm", valid_591218
  var valid_591219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591219 = validateParameter(valid_591219, JString, required = false,
                                 default = nil)
  if valid_591219 != nil:
    section.add "X-Amz-SignedHeaders", valid_591219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591221: Call_DescribeRobotApplication_591210; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot application.
  ## 
  let valid = call_591221.validator(path, query, header, formData, body)
  let scheme = call_591221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591221.url(scheme.get, call_591221.host, call_591221.base,
                         call_591221.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591221, url, valid)

proc call*(call_591222: Call_DescribeRobotApplication_591210; body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_591223 = newJObject()
  if body != nil:
    body_591223 = body
  result = call_591222.call(nil, nil, nil, nil, body_591223)

var describeRobotApplication* = Call_DescribeRobotApplication_591210(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_591211, base: "/",
    url: url_DescribeRobotApplication_591212, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_591224 = ref object of OpenApiRestCall_590364
proc url_DescribeSimulationApplication_591226(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSimulationApplication_591225(path: JsonNode; query: JsonNode;
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
  var valid_591227 = header.getOrDefault("X-Amz-Signature")
  valid_591227 = validateParameter(valid_591227, JString, required = false,
                                 default = nil)
  if valid_591227 != nil:
    section.add "X-Amz-Signature", valid_591227
  var valid_591228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591228 = validateParameter(valid_591228, JString, required = false,
                                 default = nil)
  if valid_591228 != nil:
    section.add "X-Amz-Content-Sha256", valid_591228
  var valid_591229 = header.getOrDefault("X-Amz-Date")
  valid_591229 = validateParameter(valid_591229, JString, required = false,
                                 default = nil)
  if valid_591229 != nil:
    section.add "X-Amz-Date", valid_591229
  var valid_591230 = header.getOrDefault("X-Amz-Credential")
  valid_591230 = validateParameter(valid_591230, JString, required = false,
                                 default = nil)
  if valid_591230 != nil:
    section.add "X-Amz-Credential", valid_591230
  var valid_591231 = header.getOrDefault("X-Amz-Security-Token")
  valid_591231 = validateParameter(valid_591231, JString, required = false,
                                 default = nil)
  if valid_591231 != nil:
    section.add "X-Amz-Security-Token", valid_591231
  var valid_591232 = header.getOrDefault("X-Amz-Algorithm")
  valid_591232 = validateParameter(valid_591232, JString, required = false,
                                 default = nil)
  if valid_591232 != nil:
    section.add "X-Amz-Algorithm", valid_591232
  var valid_591233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591233 = validateParameter(valid_591233, JString, required = false,
                                 default = nil)
  if valid_591233 != nil:
    section.add "X-Amz-SignedHeaders", valid_591233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591235: Call_DescribeSimulationApplication_591224; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation application.
  ## 
  let valid = call_591235.validator(path, query, header, formData, body)
  let scheme = call_591235.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591235.url(scheme.get, call_591235.host, call_591235.base,
                         call_591235.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591235, url, valid)

proc call*(call_591236: Call_DescribeSimulationApplication_591224; body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_591237 = newJObject()
  if body != nil:
    body_591237 = body
  result = call_591236.call(nil, nil, nil, nil, body_591237)

var describeSimulationApplication* = Call_DescribeSimulationApplication_591224(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_591225, base: "/",
    url: url_DescribeSimulationApplication_591226,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_591238 = ref object of OpenApiRestCall_590364
proc url_DescribeSimulationJob_591240(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_DescribeSimulationJob_591239(path: JsonNode; query: JsonNode;
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
  var valid_591241 = header.getOrDefault("X-Amz-Signature")
  valid_591241 = validateParameter(valid_591241, JString, required = false,
                                 default = nil)
  if valid_591241 != nil:
    section.add "X-Amz-Signature", valid_591241
  var valid_591242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591242 = validateParameter(valid_591242, JString, required = false,
                                 default = nil)
  if valid_591242 != nil:
    section.add "X-Amz-Content-Sha256", valid_591242
  var valid_591243 = header.getOrDefault("X-Amz-Date")
  valid_591243 = validateParameter(valid_591243, JString, required = false,
                                 default = nil)
  if valid_591243 != nil:
    section.add "X-Amz-Date", valid_591243
  var valid_591244 = header.getOrDefault("X-Amz-Credential")
  valid_591244 = validateParameter(valid_591244, JString, required = false,
                                 default = nil)
  if valid_591244 != nil:
    section.add "X-Amz-Credential", valid_591244
  var valid_591245 = header.getOrDefault("X-Amz-Security-Token")
  valid_591245 = validateParameter(valid_591245, JString, required = false,
                                 default = nil)
  if valid_591245 != nil:
    section.add "X-Amz-Security-Token", valid_591245
  var valid_591246 = header.getOrDefault("X-Amz-Algorithm")
  valid_591246 = validateParameter(valid_591246, JString, required = false,
                                 default = nil)
  if valid_591246 != nil:
    section.add "X-Amz-Algorithm", valid_591246
  var valid_591247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591247 = validateParameter(valid_591247, JString, required = false,
                                 default = nil)
  if valid_591247 != nil:
    section.add "X-Amz-SignedHeaders", valid_591247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591249: Call_DescribeSimulationJob_591238; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job.
  ## 
  let valid = call_591249.validator(path, query, header, formData, body)
  let scheme = call_591249.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591249.url(scheme.get, call_591249.host, call_591249.base,
                         call_591249.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591249, url, valid)

proc call*(call_591250: Call_DescribeSimulationJob_591238; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_591251 = newJObject()
  if body != nil:
    body_591251 = body
  result = call_591250.call(nil, nil, nil, nil, body_591251)

var describeSimulationJob* = Call_DescribeSimulationJob_591238(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_591239, base: "/",
    url: url_DescribeSimulationJob_591240, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_591252 = ref object of OpenApiRestCall_590364
proc url_ListDeploymentJobs_591254(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListDeploymentJobs_591253(path: JsonNode; query: JsonNode;
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
  var valid_591255 = query.getOrDefault("nextToken")
  valid_591255 = validateParameter(valid_591255, JString, required = false,
                                 default = nil)
  if valid_591255 != nil:
    section.add "nextToken", valid_591255
  var valid_591256 = query.getOrDefault("maxResults")
  valid_591256 = validateParameter(valid_591256, JString, required = false,
                                 default = nil)
  if valid_591256 != nil:
    section.add "maxResults", valid_591256
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
  var valid_591257 = header.getOrDefault("X-Amz-Signature")
  valid_591257 = validateParameter(valid_591257, JString, required = false,
                                 default = nil)
  if valid_591257 != nil:
    section.add "X-Amz-Signature", valid_591257
  var valid_591258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591258 = validateParameter(valid_591258, JString, required = false,
                                 default = nil)
  if valid_591258 != nil:
    section.add "X-Amz-Content-Sha256", valid_591258
  var valid_591259 = header.getOrDefault("X-Amz-Date")
  valid_591259 = validateParameter(valid_591259, JString, required = false,
                                 default = nil)
  if valid_591259 != nil:
    section.add "X-Amz-Date", valid_591259
  var valid_591260 = header.getOrDefault("X-Amz-Credential")
  valid_591260 = validateParameter(valid_591260, JString, required = false,
                                 default = nil)
  if valid_591260 != nil:
    section.add "X-Amz-Credential", valid_591260
  var valid_591261 = header.getOrDefault("X-Amz-Security-Token")
  valid_591261 = validateParameter(valid_591261, JString, required = false,
                                 default = nil)
  if valid_591261 != nil:
    section.add "X-Amz-Security-Token", valid_591261
  var valid_591262 = header.getOrDefault("X-Amz-Algorithm")
  valid_591262 = validateParameter(valid_591262, JString, required = false,
                                 default = nil)
  if valid_591262 != nil:
    section.add "X-Amz-Algorithm", valid_591262
  var valid_591263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591263 = validateParameter(valid_591263, JString, required = false,
                                 default = nil)
  if valid_591263 != nil:
    section.add "X-Amz-SignedHeaders", valid_591263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591265: Call_ListDeploymentJobs_591252; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ## 
  let valid = call_591265.validator(path, query, header, formData, body)
  let scheme = call_591265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591265.url(scheme.get, call_591265.host, call_591265.base,
                         call_591265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591265, url, valid)

proc call*(call_591266: Call_ListDeploymentJobs_591252; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDeploymentJobs
  ## <p>Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. </p> <note> <p> </p> </note>
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591267 = newJObject()
  var body_591268 = newJObject()
  add(query_591267, "nextToken", newJString(nextToken))
  if body != nil:
    body_591268 = body
  add(query_591267, "maxResults", newJString(maxResults))
  result = call_591266.call(nil, query_591267, nil, nil, body_591268)

var listDeploymentJobs* = Call_ListDeploymentJobs_591252(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_591253, base: "/",
    url: url_ListDeploymentJobs_591254, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_591270 = ref object of OpenApiRestCall_590364
proc url_ListFleets_591272(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListFleets_591271(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591273 = query.getOrDefault("nextToken")
  valid_591273 = validateParameter(valid_591273, JString, required = false,
                                 default = nil)
  if valid_591273 != nil:
    section.add "nextToken", valid_591273
  var valid_591274 = query.getOrDefault("maxResults")
  valid_591274 = validateParameter(valid_591274, JString, required = false,
                                 default = nil)
  if valid_591274 != nil:
    section.add "maxResults", valid_591274
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
  var valid_591275 = header.getOrDefault("X-Amz-Signature")
  valid_591275 = validateParameter(valid_591275, JString, required = false,
                                 default = nil)
  if valid_591275 != nil:
    section.add "X-Amz-Signature", valid_591275
  var valid_591276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591276 = validateParameter(valid_591276, JString, required = false,
                                 default = nil)
  if valid_591276 != nil:
    section.add "X-Amz-Content-Sha256", valid_591276
  var valid_591277 = header.getOrDefault("X-Amz-Date")
  valid_591277 = validateParameter(valid_591277, JString, required = false,
                                 default = nil)
  if valid_591277 != nil:
    section.add "X-Amz-Date", valid_591277
  var valid_591278 = header.getOrDefault("X-Amz-Credential")
  valid_591278 = validateParameter(valid_591278, JString, required = false,
                                 default = nil)
  if valid_591278 != nil:
    section.add "X-Amz-Credential", valid_591278
  var valid_591279 = header.getOrDefault("X-Amz-Security-Token")
  valid_591279 = validateParameter(valid_591279, JString, required = false,
                                 default = nil)
  if valid_591279 != nil:
    section.add "X-Amz-Security-Token", valid_591279
  var valid_591280 = header.getOrDefault("X-Amz-Algorithm")
  valid_591280 = validateParameter(valid_591280, JString, required = false,
                                 default = nil)
  if valid_591280 != nil:
    section.add "X-Amz-Algorithm", valid_591280
  var valid_591281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591281 = validateParameter(valid_591281, JString, required = false,
                                 default = nil)
  if valid_591281 != nil:
    section.add "X-Amz-SignedHeaders", valid_591281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591283: Call_ListFleets_591270; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  let valid = call_591283.validator(path, query, header, formData, body)
  let scheme = call_591283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591283.url(scheme.get, call_591283.host, call_591283.base,
                         call_591283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591283, url, valid)

proc call*(call_591284: Call_ListFleets_591270; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591285 = newJObject()
  var body_591286 = newJObject()
  add(query_591285, "nextToken", newJString(nextToken))
  if body != nil:
    body_591286 = body
  add(query_591285, "maxResults", newJString(maxResults))
  result = call_591284.call(nil, query_591285, nil, nil, body_591286)

var listFleets* = Call_ListFleets_591270(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_591271,
                                      base: "/", url: url_ListFleets_591272,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_591287 = ref object of OpenApiRestCall_590364
proc url_ListRobotApplications_591289(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRobotApplications_591288(path: JsonNode; query: JsonNode;
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
  var valid_591290 = query.getOrDefault("nextToken")
  valid_591290 = validateParameter(valid_591290, JString, required = false,
                                 default = nil)
  if valid_591290 != nil:
    section.add "nextToken", valid_591290
  var valid_591291 = query.getOrDefault("maxResults")
  valid_591291 = validateParameter(valid_591291, JString, required = false,
                                 default = nil)
  if valid_591291 != nil:
    section.add "maxResults", valid_591291
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
  var valid_591292 = header.getOrDefault("X-Amz-Signature")
  valid_591292 = validateParameter(valid_591292, JString, required = false,
                                 default = nil)
  if valid_591292 != nil:
    section.add "X-Amz-Signature", valid_591292
  var valid_591293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591293 = validateParameter(valid_591293, JString, required = false,
                                 default = nil)
  if valid_591293 != nil:
    section.add "X-Amz-Content-Sha256", valid_591293
  var valid_591294 = header.getOrDefault("X-Amz-Date")
  valid_591294 = validateParameter(valid_591294, JString, required = false,
                                 default = nil)
  if valid_591294 != nil:
    section.add "X-Amz-Date", valid_591294
  var valid_591295 = header.getOrDefault("X-Amz-Credential")
  valid_591295 = validateParameter(valid_591295, JString, required = false,
                                 default = nil)
  if valid_591295 != nil:
    section.add "X-Amz-Credential", valid_591295
  var valid_591296 = header.getOrDefault("X-Amz-Security-Token")
  valid_591296 = validateParameter(valid_591296, JString, required = false,
                                 default = nil)
  if valid_591296 != nil:
    section.add "X-Amz-Security-Token", valid_591296
  var valid_591297 = header.getOrDefault("X-Amz-Algorithm")
  valid_591297 = validateParameter(valid_591297, JString, required = false,
                                 default = nil)
  if valid_591297 != nil:
    section.add "X-Amz-Algorithm", valid_591297
  var valid_591298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591298 = validateParameter(valid_591298, JString, required = false,
                                 default = nil)
  if valid_591298 != nil:
    section.add "X-Amz-SignedHeaders", valid_591298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591300: Call_ListRobotApplications_591287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  let valid = call_591300.validator(path, query, header, formData, body)
  let scheme = call_591300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591300.url(scheme.get, call_591300.host, call_591300.base,
                         call_591300.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591300, url, valid)

proc call*(call_591301: Call_ListRobotApplications_591287; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591302 = newJObject()
  var body_591303 = newJObject()
  add(query_591302, "nextToken", newJString(nextToken))
  if body != nil:
    body_591303 = body
  add(query_591302, "maxResults", newJString(maxResults))
  result = call_591301.call(nil, query_591302, nil, nil, body_591303)

var listRobotApplications* = Call_ListRobotApplications_591287(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_591288, base: "/",
    url: url_ListRobotApplications_591289, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_591304 = ref object of OpenApiRestCall_590364
proc url_ListRobots_591306(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListRobots_591305(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591307 = query.getOrDefault("nextToken")
  valid_591307 = validateParameter(valid_591307, JString, required = false,
                                 default = nil)
  if valid_591307 != nil:
    section.add "nextToken", valid_591307
  var valid_591308 = query.getOrDefault("maxResults")
  valid_591308 = validateParameter(valid_591308, JString, required = false,
                                 default = nil)
  if valid_591308 != nil:
    section.add "maxResults", valid_591308
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
  var valid_591309 = header.getOrDefault("X-Amz-Signature")
  valid_591309 = validateParameter(valid_591309, JString, required = false,
                                 default = nil)
  if valid_591309 != nil:
    section.add "X-Amz-Signature", valid_591309
  var valid_591310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591310 = validateParameter(valid_591310, JString, required = false,
                                 default = nil)
  if valid_591310 != nil:
    section.add "X-Amz-Content-Sha256", valid_591310
  var valid_591311 = header.getOrDefault("X-Amz-Date")
  valid_591311 = validateParameter(valid_591311, JString, required = false,
                                 default = nil)
  if valid_591311 != nil:
    section.add "X-Amz-Date", valid_591311
  var valid_591312 = header.getOrDefault("X-Amz-Credential")
  valid_591312 = validateParameter(valid_591312, JString, required = false,
                                 default = nil)
  if valid_591312 != nil:
    section.add "X-Amz-Credential", valid_591312
  var valid_591313 = header.getOrDefault("X-Amz-Security-Token")
  valid_591313 = validateParameter(valid_591313, JString, required = false,
                                 default = nil)
  if valid_591313 != nil:
    section.add "X-Amz-Security-Token", valid_591313
  var valid_591314 = header.getOrDefault("X-Amz-Algorithm")
  valid_591314 = validateParameter(valid_591314, JString, required = false,
                                 default = nil)
  if valid_591314 != nil:
    section.add "X-Amz-Algorithm", valid_591314
  var valid_591315 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591315 = validateParameter(valid_591315, JString, required = false,
                                 default = nil)
  if valid_591315 != nil:
    section.add "X-Amz-SignedHeaders", valid_591315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591317: Call_ListRobots_591304; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  let valid = call_591317.validator(path, query, header, formData, body)
  let scheme = call_591317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591317.url(scheme.get, call_591317.host, call_591317.base,
                         call_591317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591317, url, valid)

proc call*(call_591318: Call_ListRobots_591304; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591319 = newJObject()
  var body_591320 = newJObject()
  add(query_591319, "nextToken", newJString(nextToken))
  if body != nil:
    body_591320 = body
  add(query_591319, "maxResults", newJString(maxResults))
  result = call_591318.call(nil, query_591319, nil, nil, body_591320)

var listRobots* = Call_ListRobots_591304(name: "listRobots",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listRobots",
                                      validator: validate_ListRobots_591305,
                                      base: "/", url: url_ListRobots_591306,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_591321 = ref object of OpenApiRestCall_590364
proc url_ListSimulationApplications_591323(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSimulationApplications_591322(path: JsonNode; query: JsonNode;
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
  var valid_591324 = query.getOrDefault("nextToken")
  valid_591324 = validateParameter(valid_591324, JString, required = false,
                                 default = nil)
  if valid_591324 != nil:
    section.add "nextToken", valid_591324
  var valid_591325 = query.getOrDefault("maxResults")
  valid_591325 = validateParameter(valid_591325, JString, required = false,
                                 default = nil)
  if valid_591325 != nil:
    section.add "maxResults", valid_591325
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
  var valid_591326 = header.getOrDefault("X-Amz-Signature")
  valid_591326 = validateParameter(valid_591326, JString, required = false,
                                 default = nil)
  if valid_591326 != nil:
    section.add "X-Amz-Signature", valid_591326
  var valid_591327 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591327 = validateParameter(valid_591327, JString, required = false,
                                 default = nil)
  if valid_591327 != nil:
    section.add "X-Amz-Content-Sha256", valid_591327
  var valid_591328 = header.getOrDefault("X-Amz-Date")
  valid_591328 = validateParameter(valid_591328, JString, required = false,
                                 default = nil)
  if valid_591328 != nil:
    section.add "X-Amz-Date", valid_591328
  var valid_591329 = header.getOrDefault("X-Amz-Credential")
  valid_591329 = validateParameter(valid_591329, JString, required = false,
                                 default = nil)
  if valid_591329 != nil:
    section.add "X-Amz-Credential", valid_591329
  var valid_591330 = header.getOrDefault("X-Amz-Security-Token")
  valid_591330 = validateParameter(valid_591330, JString, required = false,
                                 default = nil)
  if valid_591330 != nil:
    section.add "X-Amz-Security-Token", valid_591330
  var valid_591331 = header.getOrDefault("X-Amz-Algorithm")
  valid_591331 = validateParameter(valid_591331, JString, required = false,
                                 default = nil)
  if valid_591331 != nil:
    section.add "X-Amz-Algorithm", valid_591331
  var valid_591332 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591332 = validateParameter(valid_591332, JString, required = false,
                                 default = nil)
  if valid_591332 != nil:
    section.add "X-Amz-SignedHeaders", valid_591332
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591334: Call_ListSimulationApplications_591321; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  let valid = call_591334.validator(path, query, header, formData, body)
  let scheme = call_591334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591334.url(scheme.get, call_591334.host, call_591334.base,
                         call_591334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591334, url, valid)

proc call*(call_591335: Call_ListSimulationApplications_591321; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591336 = newJObject()
  var body_591337 = newJObject()
  add(query_591336, "nextToken", newJString(nextToken))
  if body != nil:
    body_591337 = body
  add(query_591336, "maxResults", newJString(maxResults))
  result = call_591335.call(nil, query_591336, nil, nil, body_591337)

var listSimulationApplications* = Call_ListSimulationApplications_591321(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_591322, base: "/",
    url: url_ListSimulationApplications_591323,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_591338 = ref object of OpenApiRestCall_590364
proc url_ListSimulationJobs_591340(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListSimulationJobs_591339(path: JsonNode; query: JsonNode;
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
  var valid_591341 = query.getOrDefault("nextToken")
  valid_591341 = validateParameter(valid_591341, JString, required = false,
                                 default = nil)
  if valid_591341 != nil:
    section.add "nextToken", valid_591341
  var valid_591342 = query.getOrDefault("maxResults")
  valid_591342 = validateParameter(valid_591342, JString, required = false,
                                 default = nil)
  if valid_591342 != nil:
    section.add "maxResults", valid_591342
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
  var valid_591343 = header.getOrDefault("X-Amz-Signature")
  valid_591343 = validateParameter(valid_591343, JString, required = false,
                                 default = nil)
  if valid_591343 != nil:
    section.add "X-Amz-Signature", valid_591343
  var valid_591344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591344 = validateParameter(valid_591344, JString, required = false,
                                 default = nil)
  if valid_591344 != nil:
    section.add "X-Amz-Content-Sha256", valid_591344
  var valid_591345 = header.getOrDefault("X-Amz-Date")
  valid_591345 = validateParameter(valid_591345, JString, required = false,
                                 default = nil)
  if valid_591345 != nil:
    section.add "X-Amz-Date", valid_591345
  var valid_591346 = header.getOrDefault("X-Amz-Credential")
  valid_591346 = validateParameter(valid_591346, JString, required = false,
                                 default = nil)
  if valid_591346 != nil:
    section.add "X-Amz-Credential", valid_591346
  var valid_591347 = header.getOrDefault("X-Amz-Security-Token")
  valid_591347 = validateParameter(valid_591347, JString, required = false,
                                 default = nil)
  if valid_591347 != nil:
    section.add "X-Amz-Security-Token", valid_591347
  var valid_591348 = header.getOrDefault("X-Amz-Algorithm")
  valid_591348 = validateParameter(valid_591348, JString, required = false,
                                 default = nil)
  if valid_591348 != nil:
    section.add "X-Amz-Algorithm", valid_591348
  var valid_591349 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591349 = validateParameter(valid_591349, JString, required = false,
                                 default = nil)
  if valid_591349 != nil:
    section.add "X-Amz-SignedHeaders", valid_591349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591351: Call_ListSimulationJobs_591338; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  let valid = call_591351.validator(path, query, header, formData, body)
  let scheme = call_591351.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591351.url(scheme.get, call_591351.host, call_591351.base,
                         call_591351.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591351, url, valid)

proc call*(call_591352: Call_ListSimulationJobs_591338; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_591353 = newJObject()
  var body_591354 = newJObject()
  add(query_591353, "nextToken", newJString(nextToken))
  if body != nil:
    body_591354 = body
  add(query_591353, "maxResults", newJString(maxResults))
  result = call_591352.call(nil, query_591353, nil, nil, body_591354)

var listSimulationJobs* = Call_ListSimulationJobs_591338(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_591339, base: "/",
    url: url_ListSimulationJobs_591340, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_591383 = ref object of OpenApiRestCall_590364
proc url_TagResource_591385(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_591384(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591386 = path.getOrDefault("resourceArn")
  valid_591386 = validateParameter(valid_591386, JString, required = true,
                                 default = nil)
  if valid_591386 != nil:
    section.add "resourceArn", valid_591386
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
  var valid_591387 = header.getOrDefault("X-Amz-Signature")
  valid_591387 = validateParameter(valid_591387, JString, required = false,
                                 default = nil)
  if valid_591387 != nil:
    section.add "X-Amz-Signature", valid_591387
  var valid_591388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591388 = validateParameter(valid_591388, JString, required = false,
                                 default = nil)
  if valid_591388 != nil:
    section.add "X-Amz-Content-Sha256", valid_591388
  var valid_591389 = header.getOrDefault("X-Amz-Date")
  valid_591389 = validateParameter(valid_591389, JString, required = false,
                                 default = nil)
  if valid_591389 != nil:
    section.add "X-Amz-Date", valid_591389
  var valid_591390 = header.getOrDefault("X-Amz-Credential")
  valid_591390 = validateParameter(valid_591390, JString, required = false,
                                 default = nil)
  if valid_591390 != nil:
    section.add "X-Amz-Credential", valid_591390
  var valid_591391 = header.getOrDefault("X-Amz-Security-Token")
  valid_591391 = validateParameter(valid_591391, JString, required = false,
                                 default = nil)
  if valid_591391 != nil:
    section.add "X-Amz-Security-Token", valid_591391
  var valid_591392 = header.getOrDefault("X-Amz-Algorithm")
  valid_591392 = validateParameter(valid_591392, JString, required = false,
                                 default = nil)
  if valid_591392 != nil:
    section.add "X-Amz-Algorithm", valid_591392
  var valid_591393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591393 = validateParameter(valid_591393, JString, required = false,
                                 default = nil)
  if valid_591393 != nil:
    section.add "X-Amz-SignedHeaders", valid_591393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591395: Call_TagResource_591383; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  let valid = call_591395.validator(path, query, header, formData, body)
  let scheme = call_591395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591395.url(scheme.get, call_591395.host, call_591395.base,
                         call_591395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591395, url, valid)

proc call*(call_591396: Call_TagResource_591383; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  ##   body: JObject (required)
  var path_591397 = newJObject()
  var body_591398 = newJObject()
  add(path_591397, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_591398 = body
  result = call_591396.call(path_591397, nil, nil, nil, body_591398)

var tagResource* = Call_TagResource_591383(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_591384,
                                        base: "/", url: url_TagResource_591385,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_591355 = ref object of OpenApiRestCall_590364
proc url_ListTagsForResource_591357(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_591356(path: JsonNode; query: JsonNode;
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
  var valid_591372 = path.getOrDefault("resourceArn")
  valid_591372 = validateParameter(valid_591372, JString, required = true,
                                 default = nil)
  if valid_591372 != nil:
    section.add "resourceArn", valid_591372
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
  var valid_591373 = header.getOrDefault("X-Amz-Signature")
  valid_591373 = validateParameter(valid_591373, JString, required = false,
                                 default = nil)
  if valid_591373 != nil:
    section.add "X-Amz-Signature", valid_591373
  var valid_591374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591374 = validateParameter(valid_591374, JString, required = false,
                                 default = nil)
  if valid_591374 != nil:
    section.add "X-Amz-Content-Sha256", valid_591374
  var valid_591375 = header.getOrDefault("X-Amz-Date")
  valid_591375 = validateParameter(valid_591375, JString, required = false,
                                 default = nil)
  if valid_591375 != nil:
    section.add "X-Amz-Date", valid_591375
  var valid_591376 = header.getOrDefault("X-Amz-Credential")
  valid_591376 = validateParameter(valid_591376, JString, required = false,
                                 default = nil)
  if valid_591376 != nil:
    section.add "X-Amz-Credential", valid_591376
  var valid_591377 = header.getOrDefault("X-Amz-Security-Token")
  valid_591377 = validateParameter(valid_591377, JString, required = false,
                                 default = nil)
  if valid_591377 != nil:
    section.add "X-Amz-Security-Token", valid_591377
  var valid_591378 = header.getOrDefault("X-Amz-Algorithm")
  valid_591378 = validateParameter(valid_591378, JString, required = false,
                                 default = nil)
  if valid_591378 != nil:
    section.add "X-Amz-Algorithm", valid_591378
  var valid_591379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591379 = validateParameter(valid_591379, JString, required = false,
                                 default = nil)
  if valid_591379 != nil:
    section.add "X-Amz-SignedHeaders", valid_591379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591380: Call_ListTagsForResource_591355; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  let valid = call_591380.validator(path, query, header, formData, body)
  let scheme = call_591380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591380.url(scheme.get, call_591380.host, call_591380.base,
                         call_591380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591380, url, valid)

proc call*(call_591381: Call_ListTagsForResource_591355; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_591382 = newJObject()
  add(path_591382, "resourceArn", newJString(resourceArn))
  result = call_591381.call(path_591382, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_591355(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_591356, base: "/",
    url: url_ListTagsForResource_591357, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_591399 = ref object of OpenApiRestCall_590364
proc url_RegisterRobot_591401(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RegisterRobot_591400(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591402 = header.getOrDefault("X-Amz-Signature")
  valid_591402 = validateParameter(valid_591402, JString, required = false,
                                 default = nil)
  if valid_591402 != nil:
    section.add "X-Amz-Signature", valid_591402
  var valid_591403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591403 = validateParameter(valid_591403, JString, required = false,
                                 default = nil)
  if valid_591403 != nil:
    section.add "X-Amz-Content-Sha256", valid_591403
  var valid_591404 = header.getOrDefault("X-Amz-Date")
  valid_591404 = validateParameter(valid_591404, JString, required = false,
                                 default = nil)
  if valid_591404 != nil:
    section.add "X-Amz-Date", valid_591404
  var valid_591405 = header.getOrDefault("X-Amz-Credential")
  valid_591405 = validateParameter(valid_591405, JString, required = false,
                                 default = nil)
  if valid_591405 != nil:
    section.add "X-Amz-Credential", valid_591405
  var valid_591406 = header.getOrDefault("X-Amz-Security-Token")
  valid_591406 = validateParameter(valid_591406, JString, required = false,
                                 default = nil)
  if valid_591406 != nil:
    section.add "X-Amz-Security-Token", valid_591406
  var valid_591407 = header.getOrDefault("X-Amz-Algorithm")
  valid_591407 = validateParameter(valid_591407, JString, required = false,
                                 default = nil)
  if valid_591407 != nil:
    section.add "X-Amz-Algorithm", valid_591407
  var valid_591408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591408 = validateParameter(valid_591408, JString, required = false,
                                 default = nil)
  if valid_591408 != nil:
    section.add "X-Amz-SignedHeaders", valid_591408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591410: Call_RegisterRobot_591399; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a robot with a fleet.
  ## 
  let valid = call_591410.validator(path, query, header, formData, body)
  let scheme = call_591410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591410.url(scheme.get, call_591410.host, call_591410.base,
                         call_591410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591410, url, valid)

proc call*(call_591411: Call_RegisterRobot_591399; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_591412 = newJObject()
  if body != nil:
    body_591412 = body
  result = call_591411.call(nil, nil, nil, nil, body_591412)

var registerRobot* = Call_RegisterRobot_591399(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_591400, base: "/",
    url: url_RegisterRobot_591401, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_591413 = ref object of OpenApiRestCall_590364
proc url_RestartSimulationJob_591415(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_RestartSimulationJob_591414(path: JsonNode; query: JsonNode;
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
  var valid_591416 = header.getOrDefault("X-Amz-Signature")
  valid_591416 = validateParameter(valid_591416, JString, required = false,
                                 default = nil)
  if valid_591416 != nil:
    section.add "X-Amz-Signature", valid_591416
  var valid_591417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591417 = validateParameter(valid_591417, JString, required = false,
                                 default = nil)
  if valid_591417 != nil:
    section.add "X-Amz-Content-Sha256", valid_591417
  var valid_591418 = header.getOrDefault("X-Amz-Date")
  valid_591418 = validateParameter(valid_591418, JString, required = false,
                                 default = nil)
  if valid_591418 != nil:
    section.add "X-Amz-Date", valid_591418
  var valid_591419 = header.getOrDefault("X-Amz-Credential")
  valid_591419 = validateParameter(valid_591419, JString, required = false,
                                 default = nil)
  if valid_591419 != nil:
    section.add "X-Amz-Credential", valid_591419
  var valid_591420 = header.getOrDefault("X-Amz-Security-Token")
  valid_591420 = validateParameter(valid_591420, JString, required = false,
                                 default = nil)
  if valid_591420 != nil:
    section.add "X-Amz-Security-Token", valid_591420
  var valid_591421 = header.getOrDefault("X-Amz-Algorithm")
  valid_591421 = validateParameter(valid_591421, JString, required = false,
                                 default = nil)
  if valid_591421 != nil:
    section.add "X-Amz-Algorithm", valid_591421
  var valid_591422 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591422 = validateParameter(valid_591422, JString, required = false,
                                 default = nil)
  if valid_591422 != nil:
    section.add "X-Amz-SignedHeaders", valid_591422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591424: Call_RestartSimulationJob_591413; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts a running simulation job.
  ## 
  let valid = call_591424.validator(path, query, header, formData, body)
  let scheme = call_591424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591424.url(scheme.get, call_591424.host, call_591424.base,
                         call_591424.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591424, url, valid)

proc call*(call_591425: Call_RestartSimulationJob_591413; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_591426 = newJObject()
  if body != nil:
    body_591426 = body
  result = call_591425.call(nil, nil, nil, nil, body_591426)

var restartSimulationJob* = Call_RestartSimulationJob_591413(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_591414, base: "/",
    url: url_RestartSimulationJob_591415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_591427 = ref object of OpenApiRestCall_590364
proc url_SyncDeploymentJob_591429(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_SyncDeploymentJob_591428(path: JsonNode; query: JsonNode;
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
  var valid_591430 = header.getOrDefault("X-Amz-Signature")
  valid_591430 = validateParameter(valid_591430, JString, required = false,
                                 default = nil)
  if valid_591430 != nil:
    section.add "X-Amz-Signature", valid_591430
  var valid_591431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591431 = validateParameter(valid_591431, JString, required = false,
                                 default = nil)
  if valid_591431 != nil:
    section.add "X-Amz-Content-Sha256", valid_591431
  var valid_591432 = header.getOrDefault("X-Amz-Date")
  valid_591432 = validateParameter(valid_591432, JString, required = false,
                                 default = nil)
  if valid_591432 != nil:
    section.add "X-Amz-Date", valid_591432
  var valid_591433 = header.getOrDefault("X-Amz-Credential")
  valid_591433 = validateParameter(valid_591433, JString, required = false,
                                 default = nil)
  if valid_591433 != nil:
    section.add "X-Amz-Credential", valid_591433
  var valid_591434 = header.getOrDefault("X-Amz-Security-Token")
  valid_591434 = validateParameter(valid_591434, JString, required = false,
                                 default = nil)
  if valid_591434 != nil:
    section.add "X-Amz-Security-Token", valid_591434
  var valid_591435 = header.getOrDefault("X-Amz-Algorithm")
  valid_591435 = validateParameter(valid_591435, JString, required = false,
                                 default = nil)
  if valid_591435 != nil:
    section.add "X-Amz-Algorithm", valid_591435
  var valid_591436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591436 = validateParameter(valid_591436, JString, required = false,
                                 default = nil)
  if valid_591436 != nil:
    section.add "X-Amz-SignedHeaders", valid_591436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591438: Call_SyncDeploymentJob_591427; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  let valid = call_591438.validator(path, query, header, formData, body)
  let scheme = call_591438.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591438.url(scheme.get, call_591438.host, call_591438.base,
                         call_591438.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591438, url, valid)

proc call*(call_591439: Call_SyncDeploymentJob_591427; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   body: JObject (required)
  var body_591440 = newJObject()
  if body != nil:
    body_591440 = body
  result = call_591439.call(nil, nil, nil, nil, body_591440)

var syncDeploymentJob* = Call_SyncDeploymentJob_591427(name: "syncDeploymentJob",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/syncDeploymentJob", validator: validate_SyncDeploymentJob_591428,
    base: "/", url: url_SyncDeploymentJob_591429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_591441 = ref object of OpenApiRestCall_590364
proc url_UntagResource_591443(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_591442(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_591444 = path.getOrDefault("resourceArn")
  valid_591444 = validateParameter(valid_591444, JString, required = true,
                                 default = nil)
  if valid_591444 != nil:
    section.add "resourceArn", valid_591444
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_591445 = query.getOrDefault("tagKeys")
  valid_591445 = validateParameter(valid_591445, JArray, required = true, default = nil)
  if valid_591445 != nil:
    section.add "tagKeys", valid_591445
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
  var valid_591446 = header.getOrDefault("X-Amz-Signature")
  valid_591446 = validateParameter(valid_591446, JString, required = false,
                                 default = nil)
  if valid_591446 != nil:
    section.add "X-Amz-Signature", valid_591446
  var valid_591447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591447 = validateParameter(valid_591447, JString, required = false,
                                 default = nil)
  if valid_591447 != nil:
    section.add "X-Amz-Content-Sha256", valid_591447
  var valid_591448 = header.getOrDefault("X-Amz-Date")
  valid_591448 = validateParameter(valid_591448, JString, required = false,
                                 default = nil)
  if valid_591448 != nil:
    section.add "X-Amz-Date", valid_591448
  var valid_591449 = header.getOrDefault("X-Amz-Credential")
  valid_591449 = validateParameter(valid_591449, JString, required = false,
                                 default = nil)
  if valid_591449 != nil:
    section.add "X-Amz-Credential", valid_591449
  var valid_591450 = header.getOrDefault("X-Amz-Security-Token")
  valid_591450 = validateParameter(valid_591450, JString, required = false,
                                 default = nil)
  if valid_591450 != nil:
    section.add "X-Amz-Security-Token", valid_591450
  var valid_591451 = header.getOrDefault("X-Amz-Algorithm")
  valid_591451 = validateParameter(valid_591451, JString, required = false,
                                 default = nil)
  if valid_591451 != nil:
    section.add "X-Amz-Algorithm", valid_591451
  var valid_591452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591452 = validateParameter(valid_591452, JString, required = false,
                                 default = nil)
  if valid_591452 != nil:
    section.add "X-Amz-SignedHeaders", valid_591452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_591453: Call_UntagResource_591441; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  let valid = call_591453.validator(path, query, header, formData, body)
  let scheme = call_591453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591453.url(scheme.get, call_591453.host, call_591453.base,
                         call_591453.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591453, url, valid)

proc call*(call_591454: Call_UntagResource_591441; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  var path_591455 = newJObject()
  var query_591456 = newJObject()
  add(path_591455, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_591456.add "tagKeys", tagKeys
  result = call_591454.call(path_591455, query_591456, nil, nil, nil)

var untagResource* = Call_UntagResource_591441(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_591442,
    base: "/", url: url_UntagResource_591443, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_591457 = ref object of OpenApiRestCall_590364
proc url_UpdateRobotApplication_591459(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateRobotApplication_591458(path: JsonNode; query: JsonNode;
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
  var valid_591460 = header.getOrDefault("X-Amz-Signature")
  valid_591460 = validateParameter(valid_591460, JString, required = false,
                                 default = nil)
  if valid_591460 != nil:
    section.add "X-Amz-Signature", valid_591460
  var valid_591461 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591461 = validateParameter(valid_591461, JString, required = false,
                                 default = nil)
  if valid_591461 != nil:
    section.add "X-Amz-Content-Sha256", valid_591461
  var valid_591462 = header.getOrDefault("X-Amz-Date")
  valid_591462 = validateParameter(valid_591462, JString, required = false,
                                 default = nil)
  if valid_591462 != nil:
    section.add "X-Amz-Date", valid_591462
  var valid_591463 = header.getOrDefault("X-Amz-Credential")
  valid_591463 = validateParameter(valid_591463, JString, required = false,
                                 default = nil)
  if valid_591463 != nil:
    section.add "X-Amz-Credential", valid_591463
  var valid_591464 = header.getOrDefault("X-Amz-Security-Token")
  valid_591464 = validateParameter(valid_591464, JString, required = false,
                                 default = nil)
  if valid_591464 != nil:
    section.add "X-Amz-Security-Token", valid_591464
  var valid_591465 = header.getOrDefault("X-Amz-Algorithm")
  valid_591465 = validateParameter(valid_591465, JString, required = false,
                                 default = nil)
  if valid_591465 != nil:
    section.add "X-Amz-Algorithm", valid_591465
  var valid_591466 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591466 = validateParameter(valid_591466, JString, required = false,
                                 default = nil)
  if valid_591466 != nil:
    section.add "X-Amz-SignedHeaders", valid_591466
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591468: Call_UpdateRobotApplication_591457; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a robot application.
  ## 
  let valid = call_591468.validator(path, query, header, formData, body)
  let scheme = call_591468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591468.url(scheme.get, call_591468.host, call_591468.base,
                         call_591468.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591468, url, valid)

proc call*(call_591469: Call_UpdateRobotApplication_591457; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_591470 = newJObject()
  if body != nil:
    body_591470 = body
  result = call_591469.call(nil, nil, nil, nil, body_591470)

var updateRobotApplication* = Call_UpdateRobotApplication_591457(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_591458, base: "/",
    url: url_UpdateRobotApplication_591459, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_591471 = ref object of OpenApiRestCall_590364
proc url_UpdateSimulationApplication_591473(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_UpdateSimulationApplication_591472(path: JsonNode; query: JsonNode;
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
  var valid_591474 = header.getOrDefault("X-Amz-Signature")
  valid_591474 = validateParameter(valid_591474, JString, required = false,
                                 default = nil)
  if valid_591474 != nil:
    section.add "X-Amz-Signature", valid_591474
  var valid_591475 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_591475 = validateParameter(valid_591475, JString, required = false,
                                 default = nil)
  if valid_591475 != nil:
    section.add "X-Amz-Content-Sha256", valid_591475
  var valid_591476 = header.getOrDefault("X-Amz-Date")
  valid_591476 = validateParameter(valid_591476, JString, required = false,
                                 default = nil)
  if valid_591476 != nil:
    section.add "X-Amz-Date", valid_591476
  var valid_591477 = header.getOrDefault("X-Amz-Credential")
  valid_591477 = validateParameter(valid_591477, JString, required = false,
                                 default = nil)
  if valid_591477 != nil:
    section.add "X-Amz-Credential", valid_591477
  var valid_591478 = header.getOrDefault("X-Amz-Security-Token")
  valid_591478 = validateParameter(valid_591478, JString, required = false,
                                 default = nil)
  if valid_591478 != nil:
    section.add "X-Amz-Security-Token", valid_591478
  var valid_591479 = header.getOrDefault("X-Amz-Algorithm")
  valid_591479 = validateParameter(valid_591479, JString, required = false,
                                 default = nil)
  if valid_591479 != nil:
    section.add "X-Amz-Algorithm", valid_591479
  var valid_591480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_591480 = validateParameter(valid_591480, JString, required = false,
                                 default = nil)
  if valid_591480 != nil:
    section.add "X-Amz-SignedHeaders", valid_591480
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_591482: Call_UpdateSimulationApplication_591471; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a simulation application.
  ## 
  let valid = call_591482.validator(path, query, header, formData, body)
  let scheme = call_591482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_591482.url(scheme.get, call_591482.host, call_591482.base,
                         call_591482.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_591482, url, valid)

proc call*(call_591483: Call_UpdateSimulationApplication_591471; body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_591484 = newJObject()
  if body != nil:
    body_591484 = body
  result = call_591483.call(nil, nil, nil, nil, body_591484)

var updateSimulationApplication* = Call_UpdateSimulationApplication_591471(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_591472, base: "/",
    url: url_UpdateSimulationApplication_591473,
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

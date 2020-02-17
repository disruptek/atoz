
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchDescribeSimulationJob_610996 = ref object of OpenApiRestCall_610658
proc url_BatchDescribeSimulationJob_610998(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchDescribeSimulationJob_610997(path: JsonNode; query: JsonNode;
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
  var valid_611110 = header.getOrDefault("X-Amz-Signature")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "X-Amz-Signature", valid_611110
  var valid_611111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "X-Amz-Content-Sha256", valid_611111
  var valid_611112 = header.getOrDefault("X-Amz-Date")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "X-Amz-Date", valid_611112
  var valid_611113 = header.getOrDefault("X-Amz-Credential")
  valid_611113 = validateParameter(valid_611113, JString, required = false,
                                 default = nil)
  if valid_611113 != nil:
    section.add "X-Amz-Credential", valid_611113
  var valid_611114 = header.getOrDefault("X-Amz-Security-Token")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Security-Token", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Algorithm")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Algorithm", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-SignedHeaders", valid_611116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611140: Call_BatchDescribeSimulationJob_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes one or more simulation jobs.
  ## 
  let valid = call_611140.validator(path, query, header, formData, body)
  let scheme = call_611140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611140.url(scheme.get, call_611140.host, call_611140.base,
                         call_611140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611140, url, valid)

proc call*(call_611211: Call_BatchDescribeSimulationJob_610996; body: JsonNode): Recallable =
  ## batchDescribeSimulationJob
  ## Describes one or more simulation jobs.
  ##   body: JObject (required)
  var body_611212 = newJObject()
  if body != nil:
    body_611212 = body
  result = call_611211.call(nil, nil, nil, nil, body_611212)

var batchDescribeSimulationJob* = Call_BatchDescribeSimulationJob_610996(
    name: "batchDescribeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/batchDescribeSimulationJob",
    validator: validate_BatchDescribeSimulationJob_610997, base: "/",
    url: url_BatchDescribeSimulationJob_610998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelDeploymentJob_611251 = ref object of OpenApiRestCall_610658
proc url_CancelDeploymentJob_611253(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelDeploymentJob_611252(path: JsonNode; query: JsonNode;
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
  var valid_611254 = header.getOrDefault("X-Amz-Signature")
  valid_611254 = validateParameter(valid_611254, JString, required = false,
                                 default = nil)
  if valid_611254 != nil:
    section.add "X-Amz-Signature", valid_611254
  var valid_611255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611255 = validateParameter(valid_611255, JString, required = false,
                                 default = nil)
  if valid_611255 != nil:
    section.add "X-Amz-Content-Sha256", valid_611255
  var valid_611256 = header.getOrDefault("X-Amz-Date")
  valid_611256 = validateParameter(valid_611256, JString, required = false,
                                 default = nil)
  if valid_611256 != nil:
    section.add "X-Amz-Date", valid_611256
  var valid_611257 = header.getOrDefault("X-Amz-Credential")
  valid_611257 = validateParameter(valid_611257, JString, required = false,
                                 default = nil)
  if valid_611257 != nil:
    section.add "X-Amz-Credential", valid_611257
  var valid_611258 = header.getOrDefault("X-Amz-Security-Token")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Security-Token", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Algorithm")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Algorithm", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-SignedHeaders", valid_611260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611262: Call_CancelDeploymentJob_611251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified deployment job.
  ## 
  let valid = call_611262.validator(path, query, header, formData, body)
  let scheme = call_611262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611262.url(scheme.get, call_611262.host, call_611262.base,
                         call_611262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611262, url, valid)

proc call*(call_611263: Call_CancelDeploymentJob_611251; body: JsonNode): Recallable =
  ## cancelDeploymentJob
  ## Cancels the specified deployment job.
  ##   body: JObject (required)
  var body_611264 = newJObject()
  if body != nil:
    body_611264 = body
  result = call_611263.call(nil, nil, nil, nil, body_611264)

var cancelDeploymentJob* = Call_CancelDeploymentJob_611251(
    name: "cancelDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelDeploymentJob",
    validator: validate_CancelDeploymentJob_611252, base: "/",
    url: url_CancelDeploymentJob_611253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJob_611265 = ref object of OpenApiRestCall_610658
proc url_CancelSimulationJob_611267(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelSimulationJob_611266(path: JsonNode; query: JsonNode;
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
  var valid_611268 = header.getOrDefault("X-Amz-Signature")
  valid_611268 = validateParameter(valid_611268, JString, required = false,
                                 default = nil)
  if valid_611268 != nil:
    section.add "X-Amz-Signature", valid_611268
  var valid_611269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611269 = validateParameter(valid_611269, JString, required = false,
                                 default = nil)
  if valid_611269 != nil:
    section.add "X-Amz-Content-Sha256", valid_611269
  var valid_611270 = header.getOrDefault("X-Amz-Date")
  valid_611270 = validateParameter(valid_611270, JString, required = false,
                                 default = nil)
  if valid_611270 != nil:
    section.add "X-Amz-Date", valid_611270
  var valid_611271 = header.getOrDefault("X-Amz-Credential")
  valid_611271 = validateParameter(valid_611271, JString, required = false,
                                 default = nil)
  if valid_611271 != nil:
    section.add "X-Amz-Credential", valid_611271
  var valid_611272 = header.getOrDefault("X-Amz-Security-Token")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "X-Amz-Security-Token", valid_611272
  var valid_611273 = header.getOrDefault("X-Amz-Algorithm")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "X-Amz-Algorithm", valid_611273
  var valid_611274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "X-Amz-SignedHeaders", valid_611274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611276: Call_CancelSimulationJob_611265; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels the specified simulation job.
  ## 
  let valid = call_611276.validator(path, query, header, formData, body)
  let scheme = call_611276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611276.url(scheme.get, call_611276.host, call_611276.base,
                         call_611276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611276, url, valid)

proc call*(call_611277: Call_CancelSimulationJob_611265; body: JsonNode): Recallable =
  ## cancelSimulationJob
  ## Cancels the specified simulation job.
  ##   body: JObject (required)
  var body_611278 = newJObject()
  if body != nil:
    body_611278 = body
  result = call_611277.call(nil, nil, nil, nil, body_611278)

var cancelSimulationJob* = Call_CancelSimulationJob_611265(
    name: "cancelSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJob",
    validator: validate_CancelSimulationJob_611266, base: "/",
    url: url_CancelSimulationJob_611267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelSimulationJobBatch_611279 = ref object of OpenApiRestCall_610658
proc url_CancelSimulationJobBatch_611281(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelSimulationJobBatch_611280(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
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
  var valid_611282 = header.getOrDefault("X-Amz-Signature")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Signature", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Content-Sha256", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-Date")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-Date", valid_611284
  var valid_611285 = header.getOrDefault("X-Amz-Credential")
  valid_611285 = validateParameter(valid_611285, JString, required = false,
                                 default = nil)
  if valid_611285 != nil:
    section.add "X-Amz-Credential", valid_611285
  var valid_611286 = header.getOrDefault("X-Amz-Security-Token")
  valid_611286 = validateParameter(valid_611286, JString, required = false,
                                 default = nil)
  if valid_611286 != nil:
    section.add "X-Amz-Security-Token", valid_611286
  var valid_611287 = header.getOrDefault("X-Amz-Algorithm")
  valid_611287 = validateParameter(valid_611287, JString, required = false,
                                 default = nil)
  if valid_611287 != nil:
    section.add "X-Amz-Algorithm", valid_611287
  var valid_611288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611288 = validateParameter(valid_611288, JString, required = false,
                                 default = nil)
  if valid_611288 != nil:
    section.add "X-Amz-SignedHeaders", valid_611288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611290: Call_CancelSimulationJobBatch_611279; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
  ## 
  let valid = call_611290.validator(path, query, header, formData, body)
  let scheme = call_611290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611290.url(scheme.get, call_611290.host, call_611290.base,
                         call_611290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611290, url, valid)

proc call*(call_611291: Call_CancelSimulationJobBatch_611279; body: JsonNode): Recallable =
  ## cancelSimulationJobBatch
  ## Cancels a simulation job batch. When you cancel a simulation job batch, you are also cancelling all of the active simulation jobs created as part of the batch. 
  ##   body: JObject (required)
  var body_611292 = newJObject()
  if body != nil:
    body_611292 = body
  result = call_611291.call(nil, nil, nil, nil, body_611292)

var cancelSimulationJobBatch* = Call_CancelSimulationJobBatch_611279(
    name: "cancelSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/cancelSimulationJobBatch",
    validator: validate_CancelSimulationJobBatch_611280, base: "/",
    url: url_CancelSimulationJobBatch_611281, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDeploymentJob_611293 = ref object of OpenApiRestCall_610658
proc url_CreateDeploymentJob_611295(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDeploymentJob_611294(path: JsonNode; query: JsonNode;
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
  var valid_611296 = header.getOrDefault("X-Amz-Signature")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Signature", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Content-Sha256", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-Date")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-Date", valid_611298
  var valid_611299 = header.getOrDefault("X-Amz-Credential")
  valid_611299 = validateParameter(valid_611299, JString, required = false,
                                 default = nil)
  if valid_611299 != nil:
    section.add "X-Amz-Credential", valid_611299
  var valid_611300 = header.getOrDefault("X-Amz-Security-Token")
  valid_611300 = validateParameter(valid_611300, JString, required = false,
                                 default = nil)
  if valid_611300 != nil:
    section.add "X-Amz-Security-Token", valid_611300
  var valid_611301 = header.getOrDefault("X-Amz-Algorithm")
  valid_611301 = validateParameter(valid_611301, JString, required = false,
                                 default = nil)
  if valid_611301 != nil:
    section.add "X-Amz-Algorithm", valid_611301
  var valid_611302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611302 = validateParameter(valid_611302, JString, required = false,
                                 default = nil)
  if valid_611302 != nil:
    section.add "X-Amz-SignedHeaders", valid_611302
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611304: Call_CreateDeploymentJob_611293; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_611304.validator(path, query, header, formData, body)
  let scheme = call_611304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611304.url(scheme.get, call_611304.host, call_611304.base,
                         call_611304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611304, url, valid)

proc call*(call_611305: Call_CreateDeploymentJob_611293; body: JsonNode): Recallable =
  ## createDeploymentJob
  ## <p>Deploys a specific version of a robot application to robots in a fleet.</p> <p>The robot application must have a numbered <code>applicationVersion</code> for consistency reasons. To create a new version, use <code>CreateRobotApplicationVersion</code> or see <a href="https://docs.aws.amazon.com/robomaker/latest/dg/create-robot-application-version.html">Creating a Robot Application Version</a>. </p> <note> <p>After 90 days, deployment jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_611306 = newJObject()
  if body != nil:
    body_611306 = body
  result = call_611305.call(nil, nil, nil, nil, body_611306)

var createDeploymentJob* = Call_CreateDeploymentJob_611293(
    name: "createDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createDeploymentJob",
    validator: validate_CreateDeploymentJob_611294, base: "/",
    url: url_CreateDeploymentJob_611295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFleet_611307 = ref object of OpenApiRestCall_610658
proc url_CreateFleet_611309(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFleet_611308(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611310 = header.getOrDefault("X-Amz-Signature")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Signature", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Content-Sha256", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Date")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Date", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Credential")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Credential", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Security-Token")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Security-Token", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Algorithm")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Algorithm", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-SignedHeaders", valid_611316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611318: Call_CreateFleet_611307; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a fleet, a logical group of robots running the same robot application.
  ## 
  let valid = call_611318.validator(path, query, header, formData, body)
  let scheme = call_611318.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611318.url(scheme.get, call_611318.host, call_611318.base,
                         call_611318.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611318, url, valid)

proc call*(call_611319: Call_CreateFleet_611307; body: JsonNode): Recallable =
  ## createFleet
  ## Creates a fleet, a logical group of robots running the same robot application.
  ##   body: JObject (required)
  var body_611320 = newJObject()
  if body != nil:
    body_611320 = body
  result = call_611319.call(nil, nil, nil, nil, body_611320)

var createFleet* = Call_CreateFleet_611307(name: "createFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createFleet",
                                        validator: validate_CreateFleet_611308,
                                        base: "/", url: url_CreateFleet_611309,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobot_611321 = ref object of OpenApiRestCall_610658
proc url_CreateRobot_611323(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobot_611322(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611324 = header.getOrDefault("X-Amz-Signature")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Signature", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Content-Sha256", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Date")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Date", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Credential")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Credential", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Security-Token")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Security-Token", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-Algorithm")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-Algorithm", valid_611329
  var valid_611330 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611330 = validateParameter(valid_611330, JString, required = false,
                                 default = nil)
  if valid_611330 != nil:
    section.add "X-Amz-SignedHeaders", valid_611330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611332: Call_CreateRobot_611321; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot.
  ## 
  let valid = call_611332.validator(path, query, header, formData, body)
  let scheme = call_611332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611332.url(scheme.get, call_611332.host, call_611332.base,
                         call_611332.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611332, url, valid)

proc call*(call_611333: Call_CreateRobot_611321; body: JsonNode): Recallable =
  ## createRobot
  ## Creates a robot.
  ##   body: JObject (required)
  var body_611334 = newJObject()
  if body != nil:
    body_611334 = body
  result = call_611333.call(nil, nil, nil, nil, body_611334)

var createRobot* = Call_CreateRobot_611321(name: "createRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/createRobot",
                                        validator: validate_CreateRobot_611322,
                                        base: "/", url: url_CreateRobot_611323,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplication_611335 = ref object of OpenApiRestCall_610658
proc url_CreateRobotApplication_611337(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobotApplication_611336(path: JsonNode; query: JsonNode;
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
  var valid_611338 = header.getOrDefault("X-Amz-Signature")
  valid_611338 = validateParameter(valid_611338, JString, required = false,
                                 default = nil)
  if valid_611338 != nil:
    section.add "X-Amz-Signature", valid_611338
  var valid_611339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Content-Sha256", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Date")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Date", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Credential")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Credential", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Security-Token")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Security-Token", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Algorithm")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Algorithm", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-SignedHeaders", valid_611344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611346: Call_CreateRobotApplication_611335; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a robot application. 
  ## 
  let valid = call_611346.validator(path, query, header, formData, body)
  let scheme = call_611346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611346.url(scheme.get, call_611346.host, call_611346.base,
                         call_611346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611346, url, valid)

proc call*(call_611347: Call_CreateRobotApplication_611335; body: JsonNode): Recallable =
  ## createRobotApplication
  ## Creates a robot application. 
  ##   body: JObject (required)
  var body_611348 = newJObject()
  if body != nil:
    body_611348 = body
  result = call_611347.call(nil, nil, nil, nil, body_611348)

var createRobotApplication* = Call_CreateRobotApplication_611335(
    name: "createRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplication",
    validator: validate_CreateRobotApplication_611336, base: "/",
    url: url_CreateRobotApplication_611337, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateRobotApplicationVersion_611349 = ref object of OpenApiRestCall_610658
proc url_CreateRobotApplicationVersion_611351(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateRobotApplicationVersion_611350(path: JsonNode; query: JsonNode;
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_CreateRobotApplicationVersion_611349; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a version of a robot application.
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_CreateRobotApplicationVersion_611349; body: JsonNode): Recallable =
  ## createRobotApplicationVersion
  ## Creates a version of a robot application.
  ##   body: JObject (required)
  var body_611362 = newJObject()
  if body != nil:
    body_611362 = body
  result = call_611361.call(nil, nil, nil, nil, body_611362)

var createRobotApplicationVersion* = Call_CreateRobotApplicationVersion_611349(
    name: "createRobotApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createRobotApplicationVersion",
    validator: validate_CreateRobotApplicationVersion_611350, base: "/",
    url: url_CreateRobotApplicationVersion_611351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplication_611363 = ref object of OpenApiRestCall_610658
proc url_CreateSimulationApplication_611365(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationApplication_611364(path: JsonNode; query: JsonNode;
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
  var valid_611366 = header.getOrDefault("X-Amz-Signature")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Signature", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Content-Sha256", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Date")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Date", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Credential")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Credential", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Security-Token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Security-Token", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Algorithm")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Algorithm", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-SignedHeaders", valid_611372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_CreateSimulationApplication_611363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a simulation application.
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_CreateSimulationApplication_611363; body: JsonNode): Recallable =
  ## createSimulationApplication
  ## Creates a simulation application.
  ##   body: JObject (required)
  var body_611376 = newJObject()
  if body != nil:
    body_611376 = body
  result = call_611375.call(nil, nil, nil, nil, body_611376)

var createSimulationApplication* = Call_CreateSimulationApplication_611363(
    name: "createSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplication",
    validator: validate_CreateSimulationApplication_611364, base: "/",
    url: url_CreateSimulationApplication_611365,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationApplicationVersion_611377 = ref object of OpenApiRestCall_610658
proc url_CreateSimulationApplicationVersion_611379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationApplicationVersion_611378(path: JsonNode;
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
  var valid_611380 = header.getOrDefault("X-Amz-Signature")
  valid_611380 = validateParameter(valid_611380, JString, required = false,
                                 default = nil)
  if valid_611380 != nil:
    section.add "X-Amz-Signature", valid_611380
  var valid_611381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611381 = validateParameter(valid_611381, JString, required = false,
                                 default = nil)
  if valid_611381 != nil:
    section.add "X-Amz-Content-Sha256", valid_611381
  var valid_611382 = header.getOrDefault("X-Amz-Date")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Date", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Credential")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Credential", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Security-Token")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Security-Token", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Algorithm")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Algorithm", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-SignedHeaders", valid_611386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611388: Call_CreateSimulationApplicationVersion_611377;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Creates a simulation application with a specific revision id.
  ## 
  let valid = call_611388.validator(path, query, header, formData, body)
  let scheme = call_611388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611388.url(scheme.get, call_611388.host, call_611388.base,
                         call_611388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611388, url, valid)

proc call*(call_611389: Call_CreateSimulationApplicationVersion_611377;
          body: JsonNode): Recallable =
  ## createSimulationApplicationVersion
  ## Creates a simulation application with a specific revision id.
  ##   body: JObject (required)
  var body_611390 = newJObject()
  if body != nil:
    body_611390 = body
  result = call_611389.call(nil, nil, nil, nil, body_611390)

var createSimulationApplicationVersion* = Call_CreateSimulationApplicationVersion_611377(
    name: "createSimulationApplicationVersion", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationApplicationVersion",
    validator: validate_CreateSimulationApplicationVersion_611378, base: "/",
    url: url_CreateSimulationApplicationVersion_611379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSimulationJob_611391 = ref object of OpenApiRestCall_610658
proc url_CreateSimulationJob_611393(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSimulationJob_611392(path: JsonNode; query: JsonNode;
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
  var valid_611394 = header.getOrDefault("X-Amz-Signature")
  valid_611394 = validateParameter(valid_611394, JString, required = false,
                                 default = nil)
  if valid_611394 != nil:
    section.add "X-Amz-Signature", valid_611394
  var valid_611395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611395 = validateParameter(valid_611395, JString, required = false,
                                 default = nil)
  if valid_611395 != nil:
    section.add "X-Amz-Content-Sha256", valid_611395
  var valid_611396 = header.getOrDefault("X-Amz-Date")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Date", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Credential")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Credential", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Security-Token")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Security-Token", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Algorithm")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Algorithm", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-SignedHeaders", valid_611400
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611402: Call_CreateSimulationJob_611391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ## 
  let valid = call_611402.validator(path, query, header, formData, body)
  let scheme = call_611402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611402.url(scheme.get, call_611402.host, call_611402.base,
                         call_611402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611402, url, valid)

proc call*(call_611403: Call_CreateSimulationJob_611391; body: JsonNode): Recallable =
  ## createSimulationJob
  ## <p>Creates a simulation job.</p> <note> <p>After 90 days, simulation jobs expire and will be deleted. They will no longer be accessible. </p> </note>
  ##   body: JObject (required)
  var body_611404 = newJObject()
  if body != nil:
    body_611404 = body
  result = call_611403.call(nil, nil, nil, nil, body_611404)

var createSimulationJob* = Call_CreateSimulationJob_611391(
    name: "createSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/createSimulationJob",
    validator: validate_CreateSimulationJob_611392, base: "/",
    url: url_CreateSimulationJob_611393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFleet_611405 = ref object of OpenApiRestCall_610658
proc url_DeleteFleet_611407(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteFleet_611406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611408 = header.getOrDefault("X-Amz-Signature")
  valid_611408 = validateParameter(valid_611408, JString, required = false,
                                 default = nil)
  if valid_611408 != nil:
    section.add "X-Amz-Signature", valid_611408
  var valid_611409 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611409 = validateParameter(valid_611409, JString, required = false,
                                 default = nil)
  if valid_611409 != nil:
    section.add "X-Amz-Content-Sha256", valid_611409
  var valid_611410 = header.getOrDefault("X-Amz-Date")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Date", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Credential")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Credential", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Security-Token")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Security-Token", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Algorithm")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Algorithm", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-SignedHeaders", valid_611414
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611416: Call_DeleteFleet_611405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a fleet.
  ## 
  let valid = call_611416.validator(path, query, header, formData, body)
  let scheme = call_611416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611416.url(scheme.get, call_611416.host, call_611416.base,
                         call_611416.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611416, url, valid)

proc call*(call_611417: Call_DeleteFleet_611405; body: JsonNode): Recallable =
  ## deleteFleet
  ## Deletes a fleet.
  ##   body: JObject (required)
  var body_611418 = newJObject()
  if body != nil:
    body_611418 = body
  result = call_611417.call(nil, nil, nil, nil, body_611418)

var deleteFleet* = Call_DeleteFleet_611405(name: "deleteFleet",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteFleet",
                                        validator: validate_DeleteFleet_611406,
                                        base: "/", url: url_DeleteFleet_611407,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobot_611419 = ref object of OpenApiRestCall_610658
proc url_DeleteRobot_611421(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRobot_611420(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611422 = header.getOrDefault("X-Amz-Signature")
  valid_611422 = validateParameter(valid_611422, JString, required = false,
                                 default = nil)
  if valid_611422 != nil:
    section.add "X-Amz-Signature", valid_611422
  var valid_611423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611423 = validateParameter(valid_611423, JString, required = false,
                                 default = nil)
  if valid_611423 != nil:
    section.add "X-Amz-Content-Sha256", valid_611423
  var valid_611424 = header.getOrDefault("X-Amz-Date")
  valid_611424 = validateParameter(valid_611424, JString, required = false,
                                 default = nil)
  if valid_611424 != nil:
    section.add "X-Amz-Date", valid_611424
  var valid_611425 = header.getOrDefault("X-Amz-Credential")
  valid_611425 = validateParameter(valid_611425, JString, required = false,
                                 default = nil)
  if valid_611425 != nil:
    section.add "X-Amz-Credential", valid_611425
  var valid_611426 = header.getOrDefault("X-Amz-Security-Token")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Security-Token", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Algorithm")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Algorithm", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-SignedHeaders", valid_611428
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611430: Call_DeleteRobot_611419; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot.
  ## 
  let valid = call_611430.validator(path, query, header, formData, body)
  let scheme = call_611430.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611430.url(scheme.get, call_611430.host, call_611430.base,
                         call_611430.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611430, url, valid)

proc call*(call_611431: Call_DeleteRobot_611419; body: JsonNode): Recallable =
  ## deleteRobot
  ## Deletes a robot.
  ##   body: JObject (required)
  var body_611432 = newJObject()
  if body != nil:
    body_611432 = body
  result = call_611431.call(nil, nil, nil, nil, body_611432)

var deleteRobot* = Call_DeleteRobot_611419(name: "deleteRobot",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/deleteRobot",
                                        validator: validate_DeleteRobot_611420,
                                        base: "/", url: url_DeleteRobot_611421,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteRobotApplication_611433 = ref object of OpenApiRestCall_610658
proc url_DeleteRobotApplication_611435(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteRobotApplication_611434(path: JsonNode; query: JsonNode;
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
  var valid_611436 = header.getOrDefault("X-Amz-Signature")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Signature", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Content-Sha256", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Date")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Date", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-Credential")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-Credential", valid_611439
  var valid_611440 = header.getOrDefault("X-Amz-Security-Token")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Security-Token", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Algorithm")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Algorithm", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-SignedHeaders", valid_611442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611444: Call_DeleteRobotApplication_611433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a robot application.
  ## 
  let valid = call_611444.validator(path, query, header, formData, body)
  let scheme = call_611444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611444.url(scheme.get, call_611444.host, call_611444.base,
                         call_611444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611444, url, valid)

proc call*(call_611445: Call_DeleteRobotApplication_611433; body: JsonNode): Recallable =
  ## deleteRobotApplication
  ## Deletes a robot application.
  ##   body: JObject (required)
  var body_611446 = newJObject()
  if body != nil:
    body_611446 = body
  result = call_611445.call(nil, nil, nil, nil, body_611446)

var deleteRobotApplication* = Call_DeleteRobotApplication_611433(
    name: "deleteRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteRobotApplication",
    validator: validate_DeleteRobotApplication_611434, base: "/",
    url: url_DeleteRobotApplication_611435, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSimulationApplication_611447 = ref object of OpenApiRestCall_610658
proc url_DeleteSimulationApplication_611449(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSimulationApplication_611448(path: JsonNode; query: JsonNode;
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
  var valid_611450 = header.getOrDefault("X-Amz-Signature")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Signature", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Content-Sha256", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Date")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Date", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Credential")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Credential", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-Security-Token")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Security-Token", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Algorithm")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Algorithm", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-SignedHeaders", valid_611456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611458: Call_DeleteSimulationApplication_611447; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a simulation application.
  ## 
  let valid = call_611458.validator(path, query, header, formData, body)
  let scheme = call_611458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611458.url(scheme.get, call_611458.host, call_611458.base,
                         call_611458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611458, url, valid)

proc call*(call_611459: Call_DeleteSimulationApplication_611447; body: JsonNode): Recallable =
  ## deleteSimulationApplication
  ## Deletes a simulation application.
  ##   body: JObject (required)
  var body_611460 = newJObject()
  if body != nil:
    body_611460 = body
  result = call_611459.call(nil, nil, nil, nil, body_611460)

var deleteSimulationApplication* = Call_DeleteSimulationApplication_611447(
    name: "deleteSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/deleteSimulationApplication",
    validator: validate_DeleteSimulationApplication_611448, base: "/",
    url: url_DeleteSimulationApplication_611449,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterRobot_611461 = ref object of OpenApiRestCall_610658
proc url_DeregisterRobot_611463(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterRobot_611462(path: JsonNode; query: JsonNode;
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
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611472: Call_DeregisterRobot_611461; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deregisters a robot.
  ## 
  let valid = call_611472.validator(path, query, header, formData, body)
  let scheme = call_611472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611472.url(scheme.get, call_611472.host, call_611472.base,
                         call_611472.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611472, url, valid)

proc call*(call_611473: Call_DeregisterRobot_611461; body: JsonNode): Recallable =
  ## deregisterRobot
  ## Deregisters a robot.
  ##   body: JObject (required)
  var body_611474 = newJObject()
  if body != nil:
    body_611474 = body
  result = call_611473.call(nil, nil, nil, nil, body_611474)

var deregisterRobot* = Call_DeregisterRobot_611461(name: "deregisterRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/deregisterRobot", validator: validate_DeregisterRobot_611462,
    base: "/", url: url_DeregisterRobot_611463, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDeploymentJob_611475 = ref object of OpenApiRestCall_610658
proc url_DescribeDeploymentJob_611477(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDeploymentJob_611476(path: JsonNode; query: JsonNode;
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
  var valid_611478 = header.getOrDefault("X-Amz-Signature")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Signature", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Content-Sha256", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Date")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Date", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Credential")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Credential", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Security-Token")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Security-Token", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Algorithm")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Algorithm", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-SignedHeaders", valid_611484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611486: Call_DescribeDeploymentJob_611475; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a deployment job.
  ## 
  let valid = call_611486.validator(path, query, header, formData, body)
  let scheme = call_611486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611486.url(scheme.get, call_611486.host, call_611486.base,
                         call_611486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611486, url, valid)

proc call*(call_611487: Call_DescribeDeploymentJob_611475; body: JsonNode): Recallable =
  ## describeDeploymentJob
  ## Describes a deployment job.
  ##   body: JObject (required)
  var body_611488 = newJObject()
  if body != nil:
    body_611488 = body
  result = call_611487.call(nil, nil, nil, nil, body_611488)

var describeDeploymentJob* = Call_DescribeDeploymentJob_611475(
    name: "describeDeploymentJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeDeploymentJob",
    validator: validate_DescribeDeploymentJob_611476, base: "/",
    url: url_DescribeDeploymentJob_611477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFleet_611489 = ref object of OpenApiRestCall_610658
proc url_DescribeFleet_611491(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeFleet_611490(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611492 = header.getOrDefault("X-Amz-Signature")
  valid_611492 = validateParameter(valid_611492, JString, required = false,
                                 default = nil)
  if valid_611492 != nil:
    section.add "X-Amz-Signature", valid_611492
  var valid_611493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611493 = validateParameter(valid_611493, JString, required = false,
                                 default = nil)
  if valid_611493 != nil:
    section.add "X-Amz-Content-Sha256", valid_611493
  var valid_611494 = header.getOrDefault("X-Amz-Date")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Date", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Credential")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Credential", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Security-Token")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Security-Token", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Algorithm")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Algorithm", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-SignedHeaders", valid_611498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611500: Call_DescribeFleet_611489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a fleet.
  ## 
  let valid = call_611500.validator(path, query, header, formData, body)
  let scheme = call_611500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611500.url(scheme.get, call_611500.host, call_611500.base,
                         call_611500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611500, url, valid)

proc call*(call_611501: Call_DescribeFleet_611489; body: JsonNode): Recallable =
  ## describeFleet
  ## Describes a fleet.
  ##   body: JObject (required)
  var body_611502 = newJObject()
  if body != nil:
    body_611502 = body
  result = call_611501.call(nil, nil, nil, nil, body_611502)

var describeFleet* = Call_DescribeFleet_611489(name: "describeFleet",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeFleet", validator: validate_DescribeFleet_611490, base: "/",
    url: url_DescribeFleet_611491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobot_611503 = ref object of OpenApiRestCall_610658
proc url_DescribeRobot_611505(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRobot_611504(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611506 = header.getOrDefault("X-Amz-Signature")
  valid_611506 = validateParameter(valid_611506, JString, required = false,
                                 default = nil)
  if valid_611506 != nil:
    section.add "X-Amz-Signature", valid_611506
  var valid_611507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611507 = validateParameter(valid_611507, JString, required = false,
                                 default = nil)
  if valid_611507 != nil:
    section.add "X-Amz-Content-Sha256", valid_611507
  var valid_611508 = header.getOrDefault("X-Amz-Date")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Date", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Credential")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Credential", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Security-Token")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Security-Token", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Algorithm")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Algorithm", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-SignedHeaders", valid_611512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611514: Call_DescribeRobot_611503; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot.
  ## 
  let valid = call_611514.validator(path, query, header, formData, body)
  let scheme = call_611514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611514.url(scheme.get, call_611514.host, call_611514.base,
                         call_611514.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611514, url, valid)

proc call*(call_611515: Call_DescribeRobot_611503; body: JsonNode): Recallable =
  ## describeRobot
  ## Describes a robot.
  ##   body: JObject (required)
  var body_611516 = newJObject()
  if body != nil:
    body_611516 = body
  result = call_611515.call(nil, nil, nil, nil, body_611516)

var describeRobot* = Call_DescribeRobot_611503(name: "describeRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/describeRobot", validator: validate_DescribeRobot_611504, base: "/",
    url: url_DescribeRobot_611505, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeRobotApplication_611517 = ref object of OpenApiRestCall_610658
proc url_DescribeRobotApplication_611519(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeRobotApplication_611518(path: JsonNode; query: JsonNode;
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
  var valid_611520 = header.getOrDefault("X-Amz-Signature")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-Signature", valid_611520
  var valid_611521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611521 = validateParameter(valid_611521, JString, required = false,
                                 default = nil)
  if valid_611521 != nil:
    section.add "X-Amz-Content-Sha256", valid_611521
  var valid_611522 = header.getOrDefault("X-Amz-Date")
  valid_611522 = validateParameter(valid_611522, JString, required = false,
                                 default = nil)
  if valid_611522 != nil:
    section.add "X-Amz-Date", valid_611522
  var valid_611523 = header.getOrDefault("X-Amz-Credential")
  valid_611523 = validateParameter(valid_611523, JString, required = false,
                                 default = nil)
  if valid_611523 != nil:
    section.add "X-Amz-Credential", valid_611523
  var valid_611524 = header.getOrDefault("X-Amz-Security-Token")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Security-Token", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Algorithm")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Algorithm", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-SignedHeaders", valid_611526
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611528: Call_DescribeRobotApplication_611517; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a robot application.
  ## 
  let valid = call_611528.validator(path, query, header, formData, body)
  let scheme = call_611528.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611528.url(scheme.get, call_611528.host, call_611528.base,
                         call_611528.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611528, url, valid)

proc call*(call_611529: Call_DescribeRobotApplication_611517; body: JsonNode): Recallable =
  ## describeRobotApplication
  ## Describes a robot application.
  ##   body: JObject (required)
  var body_611530 = newJObject()
  if body != nil:
    body_611530 = body
  result = call_611529.call(nil, nil, nil, nil, body_611530)

var describeRobotApplication* = Call_DescribeRobotApplication_611517(
    name: "describeRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeRobotApplication",
    validator: validate_DescribeRobotApplication_611518, base: "/",
    url: url_DescribeRobotApplication_611519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationApplication_611531 = ref object of OpenApiRestCall_610658
proc url_DescribeSimulationApplication_611533(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationApplication_611532(path: JsonNode; query: JsonNode;
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
  var valid_611534 = header.getOrDefault("X-Amz-Signature")
  valid_611534 = validateParameter(valid_611534, JString, required = false,
                                 default = nil)
  if valid_611534 != nil:
    section.add "X-Amz-Signature", valid_611534
  var valid_611535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611535 = validateParameter(valid_611535, JString, required = false,
                                 default = nil)
  if valid_611535 != nil:
    section.add "X-Amz-Content-Sha256", valid_611535
  var valid_611536 = header.getOrDefault("X-Amz-Date")
  valid_611536 = validateParameter(valid_611536, JString, required = false,
                                 default = nil)
  if valid_611536 != nil:
    section.add "X-Amz-Date", valid_611536
  var valid_611537 = header.getOrDefault("X-Amz-Credential")
  valid_611537 = validateParameter(valid_611537, JString, required = false,
                                 default = nil)
  if valid_611537 != nil:
    section.add "X-Amz-Credential", valid_611537
  var valid_611538 = header.getOrDefault("X-Amz-Security-Token")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Security-Token", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Algorithm")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Algorithm", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-SignedHeaders", valid_611540
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611542: Call_DescribeSimulationApplication_611531; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation application.
  ## 
  let valid = call_611542.validator(path, query, header, formData, body)
  let scheme = call_611542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611542.url(scheme.get, call_611542.host, call_611542.base,
                         call_611542.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611542, url, valid)

proc call*(call_611543: Call_DescribeSimulationApplication_611531; body: JsonNode): Recallable =
  ## describeSimulationApplication
  ## Describes a simulation application.
  ##   body: JObject (required)
  var body_611544 = newJObject()
  if body != nil:
    body_611544 = body
  result = call_611543.call(nil, nil, nil, nil, body_611544)

var describeSimulationApplication* = Call_DescribeSimulationApplication_611531(
    name: "describeSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationApplication",
    validator: validate_DescribeSimulationApplication_611532, base: "/",
    url: url_DescribeSimulationApplication_611533,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJob_611545 = ref object of OpenApiRestCall_610658
proc url_DescribeSimulationJob_611547(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationJob_611546(path: JsonNode; query: JsonNode;
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
  var valid_611548 = header.getOrDefault("X-Amz-Signature")
  valid_611548 = validateParameter(valid_611548, JString, required = false,
                                 default = nil)
  if valid_611548 != nil:
    section.add "X-Amz-Signature", valid_611548
  var valid_611549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611549 = validateParameter(valid_611549, JString, required = false,
                                 default = nil)
  if valid_611549 != nil:
    section.add "X-Amz-Content-Sha256", valid_611549
  var valid_611550 = header.getOrDefault("X-Amz-Date")
  valid_611550 = validateParameter(valid_611550, JString, required = false,
                                 default = nil)
  if valid_611550 != nil:
    section.add "X-Amz-Date", valid_611550
  var valid_611551 = header.getOrDefault("X-Amz-Credential")
  valid_611551 = validateParameter(valid_611551, JString, required = false,
                                 default = nil)
  if valid_611551 != nil:
    section.add "X-Amz-Credential", valid_611551
  var valid_611552 = header.getOrDefault("X-Amz-Security-Token")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Security-Token", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Algorithm")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Algorithm", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-SignedHeaders", valid_611554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611556: Call_DescribeSimulationJob_611545; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job.
  ## 
  let valid = call_611556.validator(path, query, header, formData, body)
  let scheme = call_611556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611556.url(scheme.get, call_611556.host, call_611556.base,
                         call_611556.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611556, url, valid)

proc call*(call_611557: Call_DescribeSimulationJob_611545; body: JsonNode): Recallable =
  ## describeSimulationJob
  ## Describes a simulation job.
  ##   body: JObject (required)
  var body_611558 = newJObject()
  if body != nil:
    body_611558 = body
  result = call_611557.call(nil, nil, nil, nil, body_611558)

var describeSimulationJob* = Call_DescribeSimulationJob_611545(
    name: "describeSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJob",
    validator: validate_DescribeSimulationJob_611546, base: "/",
    url: url_DescribeSimulationJob_611547, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSimulationJobBatch_611559 = ref object of OpenApiRestCall_610658
proc url_DescribeSimulationJobBatch_611561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSimulationJobBatch_611560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Describes a simulation job batch.
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
  var valid_611562 = header.getOrDefault("X-Amz-Signature")
  valid_611562 = validateParameter(valid_611562, JString, required = false,
                                 default = nil)
  if valid_611562 != nil:
    section.add "X-Amz-Signature", valid_611562
  var valid_611563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611563 = validateParameter(valid_611563, JString, required = false,
                                 default = nil)
  if valid_611563 != nil:
    section.add "X-Amz-Content-Sha256", valid_611563
  var valid_611564 = header.getOrDefault("X-Amz-Date")
  valid_611564 = validateParameter(valid_611564, JString, required = false,
                                 default = nil)
  if valid_611564 != nil:
    section.add "X-Amz-Date", valid_611564
  var valid_611565 = header.getOrDefault("X-Amz-Credential")
  valid_611565 = validateParameter(valid_611565, JString, required = false,
                                 default = nil)
  if valid_611565 != nil:
    section.add "X-Amz-Credential", valid_611565
  var valid_611566 = header.getOrDefault("X-Amz-Security-Token")
  valid_611566 = validateParameter(valid_611566, JString, required = false,
                                 default = nil)
  if valid_611566 != nil:
    section.add "X-Amz-Security-Token", valid_611566
  var valid_611567 = header.getOrDefault("X-Amz-Algorithm")
  valid_611567 = validateParameter(valid_611567, JString, required = false,
                                 default = nil)
  if valid_611567 != nil:
    section.add "X-Amz-Algorithm", valid_611567
  var valid_611568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-SignedHeaders", valid_611568
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611570: Call_DescribeSimulationJobBatch_611559; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Describes a simulation job batch.
  ## 
  let valid = call_611570.validator(path, query, header, formData, body)
  let scheme = call_611570.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611570.url(scheme.get, call_611570.host, call_611570.base,
                         call_611570.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611570, url, valid)

proc call*(call_611571: Call_DescribeSimulationJobBatch_611559; body: JsonNode): Recallable =
  ## describeSimulationJobBatch
  ## Describes a simulation job batch.
  ##   body: JObject (required)
  var body_611572 = newJObject()
  if body != nil:
    body_611572 = body
  result = call_611571.call(nil, nil, nil, nil, body_611572)

var describeSimulationJobBatch* = Call_DescribeSimulationJobBatch_611559(
    name: "describeSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/describeSimulationJobBatch",
    validator: validate_DescribeSimulationJobBatch_611560, base: "/",
    url: url_DescribeSimulationJobBatch_611561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDeploymentJobs_611573 = ref object of OpenApiRestCall_610658
proc url_ListDeploymentJobs_611575(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDeploymentJobs_611574(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
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
  var valid_611576 = query.getOrDefault("nextToken")
  valid_611576 = validateParameter(valid_611576, JString, required = false,
                                 default = nil)
  if valid_611576 != nil:
    section.add "nextToken", valid_611576
  var valid_611577 = query.getOrDefault("maxResults")
  valid_611577 = validateParameter(valid_611577, JString, required = false,
                                 default = nil)
  if valid_611577 != nil:
    section.add "maxResults", valid_611577
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
  var valid_611578 = header.getOrDefault("X-Amz-Signature")
  valid_611578 = validateParameter(valid_611578, JString, required = false,
                                 default = nil)
  if valid_611578 != nil:
    section.add "X-Amz-Signature", valid_611578
  var valid_611579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611579 = validateParameter(valid_611579, JString, required = false,
                                 default = nil)
  if valid_611579 != nil:
    section.add "X-Amz-Content-Sha256", valid_611579
  var valid_611580 = header.getOrDefault("X-Amz-Date")
  valid_611580 = validateParameter(valid_611580, JString, required = false,
                                 default = nil)
  if valid_611580 != nil:
    section.add "X-Amz-Date", valid_611580
  var valid_611581 = header.getOrDefault("X-Amz-Credential")
  valid_611581 = validateParameter(valid_611581, JString, required = false,
                                 default = nil)
  if valid_611581 != nil:
    section.add "X-Amz-Credential", valid_611581
  var valid_611582 = header.getOrDefault("X-Amz-Security-Token")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Security-Token", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Algorithm")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Algorithm", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-SignedHeaders", valid_611584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611586: Call_ListDeploymentJobs_611573; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
  ## 
  let valid = call_611586.validator(path, query, header, formData, body)
  let scheme = call_611586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611586.url(scheme.get, call_611586.host, call_611586.base,
                         call_611586.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611586, url, valid)

proc call*(call_611587: Call_ListDeploymentJobs_611573; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listDeploymentJobs
  ## Returns a list of deployment jobs for a fleet. You can optionally provide filters to retrieve specific deployment jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611588 = newJObject()
  var body_611589 = newJObject()
  add(query_611588, "nextToken", newJString(nextToken))
  if body != nil:
    body_611589 = body
  add(query_611588, "maxResults", newJString(maxResults))
  result = call_611587.call(nil, query_611588, nil, nil, body_611589)

var listDeploymentJobs* = Call_ListDeploymentJobs_611573(
    name: "listDeploymentJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listDeploymentJobs",
    validator: validate_ListDeploymentJobs_611574, base: "/",
    url: url_ListDeploymentJobs_611575, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFleets_611591 = ref object of OpenApiRestCall_610658
proc url_ListFleets_611593(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFleets_611592(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611594 = query.getOrDefault("nextToken")
  valid_611594 = validateParameter(valid_611594, JString, required = false,
                                 default = nil)
  if valid_611594 != nil:
    section.add "nextToken", valid_611594
  var valid_611595 = query.getOrDefault("maxResults")
  valid_611595 = validateParameter(valid_611595, JString, required = false,
                                 default = nil)
  if valid_611595 != nil:
    section.add "maxResults", valid_611595
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
  var valid_611596 = header.getOrDefault("X-Amz-Signature")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Signature", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Content-Sha256", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Date")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Date", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Credential")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Credential", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Algorithm")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Algorithm", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-SignedHeaders", valid_611602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_ListFleets_611591; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_ListFleets_611591; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listFleets
  ## Returns a list of fleets. You can optionally provide filters to retrieve specific fleets. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611606 = newJObject()
  var body_611607 = newJObject()
  add(query_611606, "nextToken", newJString(nextToken))
  if body != nil:
    body_611607 = body
  add(query_611606, "maxResults", newJString(maxResults))
  result = call_611605.call(nil, query_611606, nil, nil, body_611607)

var listFleets* = Call_ListFleets_611591(name: "listFleets",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listFleets",
                                      validator: validate_ListFleets_611592,
                                      base: "/", url: url_ListFleets_611593,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobotApplications_611608 = ref object of OpenApiRestCall_610658
proc url_ListRobotApplications_611610(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRobotApplications_611609(path: JsonNode; query: JsonNode;
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
  var valid_611611 = query.getOrDefault("nextToken")
  valid_611611 = validateParameter(valid_611611, JString, required = false,
                                 default = nil)
  if valid_611611 != nil:
    section.add "nextToken", valid_611611
  var valid_611612 = query.getOrDefault("maxResults")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "maxResults", valid_611612
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
  var valid_611613 = header.getOrDefault("X-Amz-Signature")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Signature", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Content-Sha256", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Date")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Date", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Credential")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Credential", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Security-Token")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Security-Token", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-Algorithm")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-Algorithm", valid_611618
  var valid_611619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611619 = validateParameter(valid_611619, JString, required = false,
                                 default = nil)
  if valid_611619 != nil:
    section.add "X-Amz-SignedHeaders", valid_611619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611621: Call_ListRobotApplications_611608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ## 
  let valid = call_611621.validator(path, query, header, formData, body)
  let scheme = call_611621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611621.url(scheme.get, call_611621.host, call_611621.base,
                         call_611621.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611621, url, valid)

proc call*(call_611622: Call_ListRobotApplications_611608; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobotApplications
  ## Returns a list of robot application. You can optionally provide filters to retrieve specific robot applications.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611623 = newJObject()
  var body_611624 = newJObject()
  add(query_611623, "nextToken", newJString(nextToken))
  if body != nil:
    body_611624 = body
  add(query_611623, "maxResults", newJString(maxResults))
  result = call_611622.call(nil, query_611623, nil, nil, body_611624)

var listRobotApplications* = Call_ListRobotApplications_611608(
    name: "listRobotApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listRobotApplications",
    validator: validate_ListRobotApplications_611609, base: "/",
    url: url_ListRobotApplications_611610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListRobots_611625 = ref object of OpenApiRestCall_610658
proc url_ListRobots_611627(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListRobots_611626(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611628 = query.getOrDefault("nextToken")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "nextToken", valid_611628
  var valid_611629 = query.getOrDefault("maxResults")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "maxResults", valid_611629
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
  var valid_611630 = header.getOrDefault("X-Amz-Signature")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Signature", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Content-Sha256", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-Date")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-Date", valid_611632
  var valid_611633 = header.getOrDefault("X-Amz-Credential")
  valid_611633 = validateParameter(valid_611633, JString, required = false,
                                 default = nil)
  if valid_611633 != nil:
    section.add "X-Amz-Credential", valid_611633
  var valid_611634 = header.getOrDefault("X-Amz-Security-Token")
  valid_611634 = validateParameter(valid_611634, JString, required = false,
                                 default = nil)
  if valid_611634 != nil:
    section.add "X-Amz-Security-Token", valid_611634
  var valid_611635 = header.getOrDefault("X-Amz-Algorithm")
  valid_611635 = validateParameter(valid_611635, JString, required = false,
                                 default = nil)
  if valid_611635 != nil:
    section.add "X-Amz-Algorithm", valid_611635
  var valid_611636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611636 = validateParameter(valid_611636, JString, required = false,
                                 default = nil)
  if valid_611636 != nil:
    section.add "X-Amz-SignedHeaders", valid_611636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611638: Call_ListRobots_611625; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ## 
  let valid = call_611638.validator(path, query, header, formData, body)
  let scheme = call_611638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611638.url(scheme.get, call_611638.host, call_611638.base,
                         call_611638.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611638, url, valid)

proc call*(call_611639: Call_ListRobots_611625; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listRobots
  ## Returns a list of robots. You can optionally provide filters to retrieve specific robots.
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611640 = newJObject()
  var body_611641 = newJObject()
  add(query_611640, "nextToken", newJString(nextToken))
  if body != nil:
    body_611641 = body
  add(query_611640, "maxResults", newJString(maxResults))
  result = call_611639.call(nil, query_611640, nil, nil, body_611641)

var listRobots* = Call_ListRobots_611625(name: "listRobots",
                                      meth: HttpMethod.HttpPost,
                                      host: "robomaker.amazonaws.com",
                                      route: "/listRobots",
                                      validator: validate_ListRobots_611626,
                                      base: "/", url: url_ListRobots_611627,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationApplications_611642 = ref object of OpenApiRestCall_610658
proc url_ListSimulationApplications_611644(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationApplications_611643(path: JsonNode; query: JsonNode;
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
  var valid_611645 = query.getOrDefault("nextToken")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "nextToken", valid_611645
  var valid_611646 = query.getOrDefault("maxResults")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "maxResults", valid_611646
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
  var valid_611647 = header.getOrDefault("X-Amz-Signature")
  valid_611647 = validateParameter(valid_611647, JString, required = false,
                                 default = nil)
  if valid_611647 != nil:
    section.add "X-Amz-Signature", valid_611647
  var valid_611648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611648 = validateParameter(valid_611648, JString, required = false,
                                 default = nil)
  if valid_611648 != nil:
    section.add "X-Amz-Content-Sha256", valid_611648
  var valid_611649 = header.getOrDefault("X-Amz-Date")
  valid_611649 = validateParameter(valid_611649, JString, required = false,
                                 default = nil)
  if valid_611649 != nil:
    section.add "X-Amz-Date", valid_611649
  var valid_611650 = header.getOrDefault("X-Amz-Credential")
  valid_611650 = validateParameter(valid_611650, JString, required = false,
                                 default = nil)
  if valid_611650 != nil:
    section.add "X-Amz-Credential", valid_611650
  var valid_611651 = header.getOrDefault("X-Amz-Security-Token")
  valid_611651 = validateParameter(valid_611651, JString, required = false,
                                 default = nil)
  if valid_611651 != nil:
    section.add "X-Amz-Security-Token", valid_611651
  var valid_611652 = header.getOrDefault("X-Amz-Algorithm")
  valid_611652 = validateParameter(valid_611652, JString, required = false,
                                 default = nil)
  if valid_611652 != nil:
    section.add "X-Amz-Algorithm", valid_611652
  var valid_611653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611653 = validateParameter(valid_611653, JString, required = false,
                                 default = nil)
  if valid_611653 != nil:
    section.add "X-Amz-SignedHeaders", valid_611653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611655: Call_ListSimulationApplications_611642; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ## 
  let valid = call_611655.validator(path, query, header, formData, body)
  let scheme = call_611655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611655.url(scheme.get, call_611655.host, call_611655.base,
                         call_611655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611655, url, valid)

proc call*(call_611656: Call_ListSimulationApplications_611642; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationApplications
  ## Returns a list of simulation applications. You can optionally provide filters to retrieve specific simulation applications. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611657 = newJObject()
  var body_611658 = newJObject()
  add(query_611657, "nextToken", newJString(nextToken))
  if body != nil:
    body_611658 = body
  add(query_611657, "maxResults", newJString(maxResults))
  result = call_611656.call(nil, query_611657, nil, nil, body_611658)

var listSimulationApplications* = Call_ListSimulationApplications_611642(
    name: "listSimulationApplications", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationApplications",
    validator: validate_ListSimulationApplications_611643, base: "/",
    url: url_ListSimulationApplications_611644,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobBatches_611659 = ref object of OpenApiRestCall_610658
proc url_ListSimulationJobBatches_611661(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationJobBatches_611660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
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
  var valid_611662 = query.getOrDefault("nextToken")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "nextToken", valid_611662
  var valid_611663 = query.getOrDefault("maxResults")
  valid_611663 = validateParameter(valid_611663, JString, required = false,
                                 default = nil)
  if valid_611663 != nil:
    section.add "maxResults", valid_611663
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
  var valid_611664 = header.getOrDefault("X-Amz-Signature")
  valid_611664 = validateParameter(valid_611664, JString, required = false,
                                 default = nil)
  if valid_611664 != nil:
    section.add "X-Amz-Signature", valid_611664
  var valid_611665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611665 = validateParameter(valid_611665, JString, required = false,
                                 default = nil)
  if valid_611665 != nil:
    section.add "X-Amz-Content-Sha256", valid_611665
  var valid_611666 = header.getOrDefault("X-Amz-Date")
  valid_611666 = validateParameter(valid_611666, JString, required = false,
                                 default = nil)
  if valid_611666 != nil:
    section.add "X-Amz-Date", valid_611666
  var valid_611667 = header.getOrDefault("X-Amz-Credential")
  valid_611667 = validateParameter(valid_611667, JString, required = false,
                                 default = nil)
  if valid_611667 != nil:
    section.add "X-Amz-Credential", valid_611667
  var valid_611668 = header.getOrDefault("X-Amz-Security-Token")
  valid_611668 = validateParameter(valid_611668, JString, required = false,
                                 default = nil)
  if valid_611668 != nil:
    section.add "X-Amz-Security-Token", valid_611668
  var valid_611669 = header.getOrDefault("X-Amz-Algorithm")
  valid_611669 = validateParameter(valid_611669, JString, required = false,
                                 default = nil)
  if valid_611669 != nil:
    section.add "X-Amz-Algorithm", valid_611669
  var valid_611670 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611670 = validateParameter(valid_611670, JString, required = false,
                                 default = nil)
  if valid_611670 != nil:
    section.add "X-Amz-SignedHeaders", valid_611670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611672: Call_ListSimulationJobBatches_611659; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
  ## 
  let valid = call_611672.validator(path, query, header, formData, body)
  let scheme = call_611672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611672.url(scheme.get, call_611672.host, call_611672.base,
                         call_611672.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611672, url, valid)

proc call*(call_611673: Call_ListSimulationJobBatches_611659; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationJobBatches
  ## Returns a list simulation job batches. You can optionally provide filters to retrieve specific simulation batch jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611674 = newJObject()
  var body_611675 = newJObject()
  add(query_611674, "nextToken", newJString(nextToken))
  if body != nil:
    body_611675 = body
  add(query_611674, "maxResults", newJString(maxResults))
  result = call_611673.call(nil, query_611674, nil, nil, body_611675)

var listSimulationJobBatches* = Call_ListSimulationJobBatches_611659(
    name: "listSimulationJobBatches", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobBatches",
    validator: validate_ListSimulationJobBatches_611660, base: "/",
    url: url_ListSimulationJobBatches_611661, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSimulationJobs_611676 = ref object of OpenApiRestCall_610658
proc url_ListSimulationJobs_611678(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSimulationJobs_611677(path: JsonNode; query: JsonNode;
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
  var valid_611679 = query.getOrDefault("nextToken")
  valid_611679 = validateParameter(valid_611679, JString, required = false,
                                 default = nil)
  if valid_611679 != nil:
    section.add "nextToken", valid_611679
  var valid_611680 = query.getOrDefault("maxResults")
  valid_611680 = validateParameter(valid_611680, JString, required = false,
                                 default = nil)
  if valid_611680 != nil:
    section.add "maxResults", valid_611680
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
  var valid_611681 = header.getOrDefault("X-Amz-Signature")
  valid_611681 = validateParameter(valid_611681, JString, required = false,
                                 default = nil)
  if valid_611681 != nil:
    section.add "X-Amz-Signature", valid_611681
  var valid_611682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611682 = validateParameter(valid_611682, JString, required = false,
                                 default = nil)
  if valid_611682 != nil:
    section.add "X-Amz-Content-Sha256", valid_611682
  var valid_611683 = header.getOrDefault("X-Amz-Date")
  valid_611683 = validateParameter(valid_611683, JString, required = false,
                                 default = nil)
  if valid_611683 != nil:
    section.add "X-Amz-Date", valid_611683
  var valid_611684 = header.getOrDefault("X-Amz-Credential")
  valid_611684 = validateParameter(valid_611684, JString, required = false,
                                 default = nil)
  if valid_611684 != nil:
    section.add "X-Amz-Credential", valid_611684
  var valid_611685 = header.getOrDefault("X-Amz-Security-Token")
  valid_611685 = validateParameter(valid_611685, JString, required = false,
                                 default = nil)
  if valid_611685 != nil:
    section.add "X-Amz-Security-Token", valid_611685
  var valid_611686 = header.getOrDefault("X-Amz-Algorithm")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Algorithm", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-SignedHeaders", valid_611687
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611689: Call_ListSimulationJobs_611676; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ## 
  let valid = call_611689.validator(path, query, header, formData, body)
  let scheme = call_611689.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611689.url(scheme.get, call_611689.host, call_611689.base,
                         call_611689.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611689, url, valid)

proc call*(call_611690: Call_ListSimulationJobs_611676; body: JsonNode;
          nextToken: string = ""; maxResults: string = ""): Recallable =
  ## listSimulationJobs
  ## Returns a list of simulation jobs. You can optionally provide filters to retrieve specific simulation jobs. 
  ##   nextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  ##   maxResults: string
  ##             : Pagination limit
  var query_611691 = newJObject()
  var body_611692 = newJObject()
  add(query_611691, "nextToken", newJString(nextToken))
  if body != nil:
    body_611692 = body
  add(query_611691, "maxResults", newJString(maxResults))
  result = call_611690.call(nil, query_611691, nil, nil, body_611692)

var listSimulationJobs* = Call_ListSimulationJobs_611676(
    name: "listSimulationJobs", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/listSimulationJobs",
    validator: validate_ListSimulationJobs_611677, base: "/",
    url: url_ListSimulationJobs_611678, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611721 = ref object of OpenApiRestCall_610658
proc url_TagResource_611723(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611722(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611724 = path.getOrDefault("resourceArn")
  valid_611724 = validateParameter(valid_611724, JString, required = true,
                                 default = nil)
  if valid_611724 != nil:
    section.add "resourceArn", valid_611724
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
  var valid_611725 = header.getOrDefault("X-Amz-Signature")
  valid_611725 = validateParameter(valid_611725, JString, required = false,
                                 default = nil)
  if valid_611725 != nil:
    section.add "X-Amz-Signature", valid_611725
  var valid_611726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611726 = validateParameter(valid_611726, JString, required = false,
                                 default = nil)
  if valid_611726 != nil:
    section.add "X-Amz-Content-Sha256", valid_611726
  var valid_611727 = header.getOrDefault("X-Amz-Date")
  valid_611727 = validateParameter(valid_611727, JString, required = false,
                                 default = nil)
  if valid_611727 != nil:
    section.add "X-Amz-Date", valid_611727
  var valid_611728 = header.getOrDefault("X-Amz-Credential")
  valid_611728 = validateParameter(valid_611728, JString, required = false,
                                 default = nil)
  if valid_611728 != nil:
    section.add "X-Amz-Credential", valid_611728
  var valid_611729 = header.getOrDefault("X-Amz-Security-Token")
  valid_611729 = validateParameter(valid_611729, JString, required = false,
                                 default = nil)
  if valid_611729 != nil:
    section.add "X-Amz-Security-Token", valid_611729
  var valid_611730 = header.getOrDefault("X-Amz-Algorithm")
  valid_611730 = validateParameter(valid_611730, JString, required = false,
                                 default = nil)
  if valid_611730 != nil:
    section.add "X-Amz-Algorithm", valid_611730
  var valid_611731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-SignedHeaders", valid_611731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611733: Call_TagResource_611721; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ## 
  let valid = call_611733.validator(path, query, header, formData, body)
  let scheme = call_611733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611733.url(scheme.get, call_611733.host, call_611733.base,
                         call_611733.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611733, url, valid)

proc call*(call_611734: Call_TagResource_611721; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## <p>Adds or edits tags for a AWS RoboMaker resource.</p> <p>Each tag consists of a tag key and a tag value. Tag keys and tag values are both required, but tag values can be empty strings. </p> <p>For information about the rules that apply to tag keys and tag values, see <a href="https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/allocation-tag-restrictions.html">User-Defined Tag Restrictions</a> in the <i>AWS Billing and Cost Management User Guide</i>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are tagging.
  ##   body: JObject (required)
  var path_611735 = newJObject()
  var body_611736 = newJObject()
  add(path_611735, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_611736 = body
  result = call_611734.call(path_611735, nil, nil, nil, body_611736)

var tagResource* = Call_TagResource_611721(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "robomaker.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_611722,
                                        base: "/", url: url_TagResource_611723,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611693 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611695(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611694(path: JsonNode; query: JsonNode;
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
  var valid_611710 = path.getOrDefault("resourceArn")
  valid_611710 = validateParameter(valid_611710, JString, required = true,
                                 default = nil)
  if valid_611710 != nil:
    section.add "resourceArn", valid_611710
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
  var valid_611711 = header.getOrDefault("X-Amz-Signature")
  valid_611711 = validateParameter(valid_611711, JString, required = false,
                                 default = nil)
  if valid_611711 != nil:
    section.add "X-Amz-Signature", valid_611711
  var valid_611712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611712 = validateParameter(valid_611712, JString, required = false,
                                 default = nil)
  if valid_611712 != nil:
    section.add "X-Amz-Content-Sha256", valid_611712
  var valid_611713 = header.getOrDefault("X-Amz-Date")
  valid_611713 = validateParameter(valid_611713, JString, required = false,
                                 default = nil)
  if valid_611713 != nil:
    section.add "X-Amz-Date", valid_611713
  var valid_611714 = header.getOrDefault("X-Amz-Credential")
  valid_611714 = validateParameter(valid_611714, JString, required = false,
                                 default = nil)
  if valid_611714 != nil:
    section.add "X-Amz-Credential", valid_611714
  var valid_611715 = header.getOrDefault("X-Amz-Security-Token")
  valid_611715 = validateParameter(valid_611715, JString, required = false,
                                 default = nil)
  if valid_611715 != nil:
    section.add "X-Amz-Security-Token", valid_611715
  var valid_611716 = header.getOrDefault("X-Amz-Algorithm")
  valid_611716 = validateParameter(valid_611716, JString, required = false,
                                 default = nil)
  if valid_611716 != nil:
    section.add "X-Amz-Algorithm", valid_611716
  var valid_611717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-SignedHeaders", valid_611717
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611718: Call_ListTagsForResource_611693; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists all tags on a AWS RoboMaker resource.
  ## 
  let valid = call_611718.validator(path, query, header, formData, body)
  let scheme = call_611718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611718.url(scheme.get, call_611718.host, call_611718.base,
                         call_611718.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611718, url, valid)

proc call*(call_611719: Call_ListTagsForResource_611693; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Lists all tags on a AWS RoboMaker resource.
  ##   resourceArn: string (required)
  ##              : The AWS RoboMaker Amazon Resource Name (ARN) with tags to be listed.
  var path_611720 = newJObject()
  add(path_611720, "resourceArn", newJString(resourceArn))
  result = call_611719.call(path_611720, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611693(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "robomaker.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_611694, base: "/",
    url: url_ListTagsForResource_611695, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterRobot_611737 = ref object of OpenApiRestCall_610658
proc url_RegisterRobot_611739(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterRobot_611738(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611740 = header.getOrDefault("X-Amz-Signature")
  valid_611740 = validateParameter(valid_611740, JString, required = false,
                                 default = nil)
  if valid_611740 != nil:
    section.add "X-Amz-Signature", valid_611740
  var valid_611741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611741 = validateParameter(valid_611741, JString, required = false,
                                 default = nil)
  if valid_611741 != nil:
    section.add "X-Amz-Content-Sha256", valid_611741
  var valid_611742 = header.getOrDefault("X-Amz-Date")
  valid_611742 = validateParameter(valid_611742, JString, required = false,
                                 default = nil)
  if valid_611742 != nil:
    section.add "X-Amz-Date", valid_611742
  var valid_611743 = header.getOrDefault("X-Amz-Credential")
  valid_611743 = validateParameter(valid_611743, JString, required = false,
                                 default = nil)
  if valid_611743 != nil:
    section.add "X-Amz-Credential", valid_611743
  var valid_611744 = header.getOrDefault("X-Amz-Security-Token")
  valid_611744 = validateParameter(valid_611744, JString, required = false,
                                 default = nil)
  if valid_611744 != nil:
    section.add "X-Amz-Security-Token", valid_611744
  var valid_611745 = header.getOrDefault("X-Amz-Algorithm")
  valid_611745 = validateParameter(valid_611745, JString, required = false,
                                 default = nil)
  if valid_611745 != nil:
    section.add "X-Amz-Algorithm", valid_611745
  var valid_611746 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611746 = validateParameter(valid_611746, JString, required = false,
                                 default = nil)
  if valid_611746 != nil:
    section.add "X-Amz-SignedHeaders", valid_611746
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611748: Call_RegisterRobot_611737; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Registers a robot with a fleet.
  ## 
  let valid = call_611748.validator(path, query, header, formData, body)
  let scheme = call_611748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611748.url(scheme.get, call_611748.host, call_611748.base,
                         call_611748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611748, url, valid)

proc call*(call_611749: Call_RegisterRobot_611737; body: JsonNode): Recallable =
  ## registerRobot
  ## Registers a robot with a fleet.
  ##   body: JObject (required)
  var body_611750 = newJObject()
  if body != nil:
    body_611750 = body
  result = call_611749.call(nil, nil, nil, nil, body_611750)

var registerRobot* = Call_RegisterRobot_611737(name: "registerRobot",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/registerRobot", validator: validate_RegisterRobot_611738, base: "/",
    url: url_RegisterRobot_611739, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RestartSimulationJob_611751 = ref object of OpenApiRestCall_610658
proc url_RestartSimulationJob_611753(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RestartSimulationJob_611752(path: JsonNode; query: JsonNode;
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
  var valid_611754 = header.getOrDefault("X-Amz-Signature")
  valid_611754 = validateParameter(valid_611754, JString, required = false,
                                 default = nil)
  if valid_611754 != nil:
    section.add "X-Amz-Signature", valid_611754
  var valid_611755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611755 = validateParameter(valid_611755, JString, required = false,
                                 default = nil)
  if valid_611755 != nil:
    section.add "X-Amz-Content-Sha256", valid_611755
  var valid_611756 = header.getOrDefault("X-Amz-Date")
  valid_611756 = validateParameter(valid_611756, JString, required = false,
                                 default = nil)
  if valid_611756 != nil:
    section.add "X-Amz-Date", valid_611756
  var valid_611757 = header.getOrDefault("X-Amz-Credential")
  valid_611757 = validateParameter(valid_611757, JString, required = false,
                                 default = nil)
  if valid_611757 != nil:
    section.add "X-Amz-Credential", valid_611757
  var valid_611758 = header.getOrDefault("X-Amz-Security-Token")
  valid_611758 = validateParameter(valid_611758, JString, required = false,
                                 default = nil)
  if valid_611758 != nil:
    section.add "X-Amz-Security-Token", valid_611758
  var valid_611759 = header.getOrDefault("X-Amz-Algorithm")
  valid_611759 = validateParameter(valid_611759, JString, required = false,
                                 default = nil)
  if valid_611759 != nil:
    section.add "X-Amz-Algorithm", valid_611759
  var valid_611760 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611760 = validateParameter(valid_611760, JString, required = false,
                                 default = nil)
  if valid_611760 != nil:
    section.add "X-Amz-SignedHeaders", valid_611760
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611762: Call_RestartSimulationJob_611751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Restarts a running simulation job.
  ## 
  let valid = call_611762.validator(path, query, header, formData, body)
  let scheme = call_611762.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611762.url(scheme.get, call_611762.host, call_611762.base,
                         call_611762.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611762, url, valid)

proc call*(call_611763: Call_RestartSimulationJob_611751; body: JsonNode): Recallable =
  ## restartSimulationJob
  ## Restarts a running simulation job.
  ##   body: JObject (required)
  var body_611764 = newJObject()
  if body != nil:
    body_611764 = body
  result = call_611763.call(nil, nil, nil, nil, body_611764)

var restartSimulationJob* = Call_RestartSimulationJob_611751(
    name: "restartSimulationJob", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/restartSimulationJob",
    validator: validate_RestartSimulationJob_611752, base: "/",
    url: url_RestartSimulationJob_611753, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSimulationJobBatch_611765 = ref object of OpenApiRestCall_610658
proc url_StartSimulationJobBatch_611767(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSimulationJobBatch_611766(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
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
  var valid_611768 = header.getOrDefault("X-Amz-Signature")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-Signature", valid_611768
  var valid_611769 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611769 = validateParameter(valid_611769, JString, required = false,
                                 default = nil)
  if valid_611769 != nil:
    section.add "X-Amz-Content-Sha256", valid_611769
  var valid_611770 = header.getOrDefault("X-Amz-Date")
  valid_611770 = validateParameter(valid_611770, JString, required = false,
                                 default = nil)
  if valid_611770 != nil:
    section.add "X-Amz-Date", valid_611770
  var valid_611771 = header.getOrDefault("X-Amz-Credential")
  valid_611771 = validateParameter(valid_611771, JString, required = false,
                                 default = nil)
  if valid_611771 != nil:
    section.add "X-Amz-Credential", valid_611771
  var valid_611772 = header.getOrDefault("X-Amz-Security-Token")
  valid_611772 = validateParameter(valid_611772, JString, required = false,
                                 default = nil)
  if valid_611772 != nil:
    section.add "X-Amz-Security-Token", valid_611772
  var valid_611773 = header.getOrDefault("X-Amz-Algorithm")
  valid_611773 = validateParameter(valid_611773, JString, required = false,
                                 default = nil)
  if valid_611773 != nil:
    section.add "X-Amz-Algorithm", valid_611773
  var valid_611774 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611774 = validateParameter(valid_611774, JString, required = false,
                                 default = nil)
  if valid_611774 != nil:
    section.add "X-Amz-SignedHeaders", valid_611774
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611776: Call_StartSimulationJobBatch_611765; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
  ## 
  let valid = call_611776.validator(path, query, header, formData, body)
  let scheme = call_611776.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611776.url(scheme.get, call_611776.host, call_611776.base,
                         call_611776.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611776, url, valid)

proc call*(call_611777: Call_StartSimulationJobBatch_611765; body: JsonNode): Recallable =
  ## startSimulationJobBatch
  ## Starts a new simulation job batch. The batch is defined using one or more <code>SimulationJobRequest</code> objects. 
  ##   body: JObject (required)
  var body_611778 = newJObject()
  if body != nil:
    body_611778 = body
  result = call_611777.call(nil, nil, nil, nil, body_611778)

var startSimulationJobBatch* = Call_StartSimulationJobBatch_611765(
    name: "startSimulationJobBatch", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/startSimulationJobBatch",
    validator: validate_StartSimulationJobBatch_611766, base: "/",
    url: url_StartSimulationJobBatch_611767, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SyncDeploymentJob_611779 = ref object of OpenApiRestCall_610658
proc url_SyncDeploymentJob_611781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SyncDeploymentJob_611780(path: JsonNode; query: JsonNode;
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
  var valid_611782 = header.getOrDefault("X-Amz-Signature")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Signature", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-Content-Sha256", valid_611783
  var valid_611784 = header.getOrDefault("X-Amz-Date")
  valid_611784 = validateParameter(valid_611784, JString, required = false,
                                 default = nil)
  if valid_611784 != nil:
    section.add "X-Amz-Date", valid_611784
  var valid_611785 = header.getOrDefault("X-Amz-Credential")
  valid_611785 = validateParameter(valid_611785, JString, required = false,
                                 default = nil)
  if valid_611785 != nil:
    section.add "X-Amz-Credential", valid_611785
  var valid_611786 = header.getOrDefault("X-Amz-Security-Token")
  valid_611786 = validateParameter(valid_611786, JString, required = false,
                                 default = nil)
  if valid_611786 != nil:
    section.add "X-Amz-Security-Token", valid_611786
  var valid_611787 = header.getOrDefault("X-Amz-Algorithm")
  valid_611787 = validateParameter(valid_611787, JString, required = false,
                                 default = nil)
  if valid_611787 != nil:
    section.add "X-Amz-Algorithm", valid_611787
  var valid_611788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611788 = validateParameter(valid_611788, JString, required = false,
                                 default = nil)
  if valid_611788 != nil:
    section.add "X-Amz-SignedHeaders", valid_611788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611790: Call_SyncDeploymentJob_611779; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ## 
  let valid = call_611790.validator(path, query, header, formData, body)
  let scheme = call_611790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611790.url(scheme.get, call_611790.host, call_611790.base,
                         call_611790.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611790, url, valid)

proc call*(call_611791: Call_SyncDeploymentJob_611779; body: JsonNode): Recallable =
  ## syncDeploymentJob
  ## Syncrhonizes robots in a fleet to the latest deployment. This is helpful if robots were added after a deployment.
  ##   body: JObject (required)
  var body_611792 = newJObject()
  if body != nil:
    body_611792 = body
  result = call_611791.call(nil, nil, nil, nil, body_611792)

var syncDeploymentJob* = Call_SyncDeploymentJob_611779(name: "syncDeploymentJob",
    meth: HttpMethod.HttpPost, host: "robomaker.amazonaws.com",
    route: "/syncDeploymentJob", validator: validate_SyncDeploymentJob_611780,
    base: "/", url: url_SyncDeploymentJob_611781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611793 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611795(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611794(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611796 = path.getOrDefault("resourceArn")
  valid_611796 = validateParameter(valid_611796, JString, required = true,
                                 default = nil)
  if valid_611796 != nil:
    section.add "resourceArn", valid_611796
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611797 = query.getOrDefault("tagKeys")
  valid_611797 = validateParameter(valid_611797, JArray, required = true, default = nil)
  if valid_611797 != nil:
    section.add "tagKeys", valid_611797
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
  var valid_611798 = header.getOrDefault("X-Amz-Signature")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "X-Amz-Signature", valid_611798
  var valid_611799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "X-Amz-Content-Sha256", valid_611799
  var valid_611800 = header.getOrDefault("X-Amz-Date")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "X-Amz-Date", valid_611800
  var valid_611801 = header.getOrDefault("X-Amz-Credential")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "X-Amz-Credential", valid_611801
  var valid_611802 = header.getOrDefault("X-Amz-Security-Token")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "X-Amz-Security-Token", valid_611802
  var valid_611803 = header.getOrDefault("X-Amz-Algorithm")
  valid_611803 = validateParameter(valid_611803, JString, required = false,
                                 default = nil)
  if valid_611803 != nil:
    section.add "X-Amz-Algorithm", valid_611803
  var valid_611804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-SignedHeaders", valid_611804
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611805: Call_UntagResource_611793; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ## 
  let valid = call_611805.validator(path, query, header, formData, body)
  let scheme = call_611805.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611805.url(scheme.get, call_611805.host, call_611805.base,
                         call_611805.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611805, url, valid)

proc call*(call_611806: Call_UntagResource_611793; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## <p>Removes the specified tags from the specified AWS RoboMaker resource.</p> <p>To remove a tag, specify the tag key. To change the tag value of an existing tag key, use <a href="https://docs.aws.amazon.com/robomaker/latest/dg/API_TagResource.html"> <code>TagResource</code> </a>. </p>
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the AWS RoboMaker resource you are removing tags.
  ##   tagKeys: JArray (required)
  ##          : A map that contains tag keys and tag values that will be unattached from the resource.
  var path_611807 = newJObject()
  var query_611808 = newJObject()
  add(path_611807, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_611808.add "tagKeys", tagKeys
  result = call_611806.call(path_611807, query_611808, nil, nil, nil)

var untagResource* = Call_UntagResource_611793(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "robomaker.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_611794,
    base: "/", url: url_UntagResource_611795, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateRobotApplication_611809 = ref object of OpenApiRestCall_610658
proc url_UpdateRobotApplication_611811(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateRobotApplication_611810(path: JsonNode; query: JsonNode;
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
  var valid_611812 = header.getOrDefault("X-Amz-Signature")
  valid_611812 = validateParameter(valid_611812, JString, required = false,
                                 default = nil)
  if valid_611812 != nil:
    section.add "X-Amz-Signature", valid_611812
  var valid_611813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611813 = validateParameter(valid_611813, JString, required = false,
                                 default = nil)
  if valid_611813 != nil:
    section.add "X-Amz-Content-Sha256", valid_611813
  var valid_611814 = header.getOrDefault("X-Amz-Date")
  valid_611814 = validateParameter(valid_611814, JString, required = false,
                                 default = nil)
  if valid_611814 != nil:
    section.add "X-Amz-Date", valid_611814
  var valid_611815 = header.getOrDefault("X-Amz-Credential")
  valid_611815 = validateParameter(valid_611815, JString, required = false,
                                 default = nil)
  if valid_611815 != nil:
    section.add "X-Amz-Credential", valid_611815
  var valid_611816 = header.getOrDefault("X-Amz-Security-Token")
  valid_611816 = validateParameter(valid_611816, JString, required = false,
                                 default = nil)
  if valid_611816 != nil:
    section.add "X-Amz-Security-Token", valid_611816
  var valid_611817 = header.getOrDefault("X-Amz-Algorithm")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "X-Amz-Algorithm", valid_611817
  var valid_611818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "X-Amz-SignedHeaders", valid_611818
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611820: Call_UpdateRobotApplication_611809; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a robot application.
  ## 
  let valid = call_611820.validator(path, query, header, formData, body)
  let scheme = call_611820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611820.url(scheme.get, call_611820.host, call_611820.base,
                         call_611820.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611820, url, valid)

proc call*(call_611821: Call_UpdateRobotApplication_611809; body: JsonNode): Recallable =
  ## updateRobotApplication
  ## Updates a robot application.
  ##   body: JObject (required)
  var body_611822 = newJObject()
  if body != nil:
    body_611822 = body
  result = call_611821.call(nil, nil, nil, nil, body_611822)

var updateRobotApplication* = Call_UpdateRobotApplication_611809(
    name: "updateRobotApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateRobotApplication",
    validator: validate_UpdateRobotApplication_611810, base: "/",
    url: url_UpdateRobotApplication_611811, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSimulationApplication_611823 = ref object of OpenApiRestCall_610658
proc url_UpdateSimulationApplication_611825(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSimulationApplication_611824(path: JsonNode; query: JsonNode;
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
  var valid_611826 = header.getOrDefault("X-Amz-Signature")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "X-Amz-Signature", valid_611826
  var valid_611827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "X-Amz-Content-Sha256", valid_611827
  var valid_611828 = header.getOrDefault("X-Amz-Date")
  valid_611828 = validateParameter(valid_611828, JString, required = false,
                                 default = nil)
  if valid_611828 != nil:
    section.add "X-Amz-Date", valid_611828
  var valid_611829 = header.getOrDefault("X-Amz-Credential")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Credential", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Security-Token")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Security-Token", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Algorithm")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Algorithm", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-SignedHeaders", valid_611832
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611834: Call_UpdateSimulationApplication_611823; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a simulation application.
  ## 
  let valid = call_611834.validator(path, query, header, formData, body)
  let scheme = call_611834.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611834.url(scheme.get, call_611834.host, call_611834.base,
                         call_611834.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611834, url, valid)

proc call*(call_611835: Call_UpdateSimulationApplication_611823; body: JsonNode): Recallable =
  ## updateSimulationApplication
  ## Updates a simulation application.
  ##   body: JObject (required)
  var body_611836 = newJObject()
  if body != nil:
    body_611836 = body
  result = call_611835.call(nil, nil, nil, nil, body_611836)

var updateSimulationApplication* = Call_UpdateSimulationApplication_611823(
    name: "updateSimulationApplication", meth: HttpMethod.HttpPost,
    host: "robomaker.amazonaws.com", route: "/updateSimulationApplication",
    validator: validate_UpdateSimulationApplication_611824, base: "/",
    url: url_UpdateSimulationApplication_611825,
    schemes: {Scheme.Https, Scheme.Http})
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

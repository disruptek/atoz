
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS X-Ray
## version: 2016-04-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS X-Ray provides APIs for managing debug traces and retrieving service maps and other data created by processing those traces.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/xray/
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "xray.ap-northeast-1.amazonaws.com", "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
                           "us-west-2": "xray.us-west-2.amazonaws.com",
                           "eu-west-2": "xray.eu-west-2.amazonaws.com", "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "xray.eu-central-1.amazonaws.com",
                           "us-east-2": "xray.us-east-2.amazonaws.com",
                           "us-east-1": "xray.us-east-1.amazonaws.com", "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "xray.ap-south-1.amazonaws.com",
                           "eu-north-1": "xray.eu-north-1.amazonaws.com", "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
                           "us-west-1": "xray.us-west-1.amazonaws.com",
                           "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "xray.eu-west-3.amazonaws.com",
                           "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "xray.sa-east-1.amazonaws.com",
                           "eu-west-1": "xray.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com", "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "xray.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
      "us-west-2": "xray.us-west-2.amazonaws.com",
      "eu-west-2": "xray.eu-west-2.amazonaws.com",
      "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com",
      "eu-central-1": "xray.eu-central-1.amazonaws.com",
      "us-east-2": "xray.us-east-2.amazonaws.com",
      "us-east-1": "xray.us-east-1.amazonaws.com",
      "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "xray.ap-south-1.amazonaws.com",
      "eu-north-1": "xray.eu-north-1.amazonaws.com",
      "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
      "us-west-1": "xray.us-west-1.amazonaws.com",
      "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
      "eu-west-3": "xray.eu-west-3.amazonaws.com",
      "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "xray.sa-east-1.amazonaws.com",
      "eu-west-1": "xray.eu-west-1.amazonaws.com",
      "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com",
      "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "xray"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchGetTraces_612996 = ref object of OpenApiRestCall_612658
proc url_BatchGetTraces_612998(protocol: Scheme; host: string; base: string;
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

proc validate_BatchGetTraces_612997(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613110 = query.getOrDefault("NextToken")
  valid_613110 = validateParameter(valid_613110, JString, required = false,
                                 default = nil)
  if valid_613110 != nil:
    section.add "NextToken", valid_613110
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
  var valid_613111 = header.getOrDefault("X-Amz-Signature")
  valid_613111 = validateParameter(valid_613111, JString, required = false,
                                 default = nil)
  if valid_613111 != nil:
    section.add "X-Amz-Signature", valid_613111
  var valid_613112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613112 = validateParameter(valid_613112, JString, required = false,
                                 default = nil)
  if valid_613112 != nil:
    section.add "X-Amz-Content-Sha256", valid_613112
  var valid_613113 = header.getOrDefault("X-Amz-Date")
  valid_613113 = validateParameter(valid_613113, JString, required = false,
                                 default = nil)
  if valid_613113 != nil:
    section.add "X-Amz-Date", valid_613113
  var valid_613114 = header.getOrDefault("X-Amz-Credential")
  valid_613114 = validateParameter(valid_613114, JString, required = false,
                                 default = nil)
  if valid_613114 != nil:
    section.add "X-Amz-Credential", valid_613114
  var valid_613115 = header.getOrDefault("X-Amz-Security-Token")
  valid_613115 = validateParameter(valid_613115, JString, required = false,
                                 default = nil)
  if valid_613115 != nil:
    section.add "X-Amz-Security-Token", valid_613115
  var valid_613116 = header.getOrDefault("X-Amz-Algorithm")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Algorithm", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-SignedHeaders", valid_613117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613141: Call_BatchGetTraces_612996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ## 
  let valid = call_613141.validator(path, query, header, formData, body)
  let scheme = call_613141.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613141.url(scheme.get, call_613141.host, call_613141.base,
                         call_613141.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613141, url, valid)

proc call*(call_613212: Call_BatchGetTraces_612996; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## batchGetTraces
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613213 = newJObject()
  var body_613215 = newJObject()
  add(query_613213, "NextToken", newJString(NextToken))
  if body != nil:
    body_613215 = body
  result = call_613212.call(nil, query_613213, nil, nil, body_613215)

var batchGetTraces* = Call_BatchGetTraces_612996(name: "batchGetTraces",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/Traces",
    validator: validate_BatchGetTraces_612997, base: "/", url: url_BatchGetTraces_612998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_613254 = ref object of OpenApiRestCall_612658
proc url_CreateGroup_613256(protocol: Scheme; host: string; base: string;
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

proc validate_CreateGroup_613255(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a group resource with a name and a filter expression. 
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
  var valid_613257 = header.getOrDefault("X-Amz-Signature")
  valid_613257 = validateParameter(valid_613257, JString, required = false,
                                 default = nil)
  if valid_613257 != nil:
    section.add "X-Amz-Signature", valid_613257
  var valid_613258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613258 = validateParameter(valid_613258, JString, required = false,
                                 default = nil)
  if valid_613258 != nil:
    section.add "X-Amz-Content-Sha256", valid_613258
  var valid_613259 = header.getOrDefault("X-Amz-Date")
  valid_613259 = validateParameter(valid_613259, JString, required = false,
                                 default = nil)
  if valid_613259 != nil:
    section.add "X-Amz-Date", valid_613259
  var valid_613260 = header.getOrDefault("X-Amz-Credential")
  valid_613260 = validateParameter(valid_613260, JString, required = false,
                                 default = nil)
  if valid_613260 != nil:
    section.add "X-Amz-Credential", valid_613260
  var valid_613261 = header.getOrDefault("X-Amz-Security-Token")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Security-Token", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Algorithm")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Algorithm", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-SignedHeaders", valid_613263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613265: Call_CreateGroup_613254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a group resource with a name and a filter expression. 
  ## 
  let valid = call_613265.validator(path, query, header, formData, body)
  let scheme = call_613265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613265.url(scheme.get, call_613265.host, call_613265.base,
                         call_613265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613265, url, valid)

proc call*(call_613266: Call_CreateGroup_613254; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group resource with a name and a filter expression. 
  ##   body: JObject (required)
  var body_613267 = newJObject()
  if body != nil:
    body_613267 = body
  result = call_613266.call(nil, nil, nil, nil, body_613267)

var createGroup* = Call_CreateGroup_613254(name: "createGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/CreateGroup",
                                        validator: validate_CreateGroup_613255,
                                        base: "/", url: url_CreateGroup_613256,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSamplingRule_613268 = ref object of OpenApiRestCall_612658
proc url_CreateSamplingRule_613270(protocol: Scheme; host: string; base: string;
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

proc validate_CreateSamplingRule_613269(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
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
  var valid_613271 = header.getOrDefault("X-Amz-Signature")
  valid_613271 = validateParameter(valid_613271, JString, required = false,
                                 default = nil)
  if valid_613271 != nil:
    section.add "X-Amz-Signature", valid_613271
  var valid_613272 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613272 = validateParameter(valid_613272, JString, required = false,
                                 default = nil)
  if valid_613272 != nil:
    section.add "X-Amz-Content-Sha256", valid_613272
  var valid_613273 = header.getOrDefault("X-Amz-Date")
  valid_613273 = validateParameter(valid_613273, JString, required = false,
                                 default = nil)
  if valid_613273 != nil:
    section.add "X-Amz-Date", valid_613273
  var valid_613274 = header.getOrDefault("X-Amz-Credential")
  valid_613274 = validateParameter(valid_613274, JString, required = false,
                                 default = nil)
  if valid_613274 != nil:
    section.add "X-Amz-Credential", valid_613274
  var valid_613275 = header.getOrDefault("X-Amz-Security-Token")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Security-Token", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Algorithm")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Algorithm", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-SignedHeaders", valid_613277
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613279: Call_CreateSamplingRule_613268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ## 
  let valid = call_613279.validator(path, query, header, formData, body)
  let scheme = call_613279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613279.url(scheme.get, call_613279.host, call_613279.base,
                         call_613279.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613279, url, valid)

proc call*(call_613280: Call_CreateSamplingRule_613268; body: JsonNode): Recallable =
  ## createSamplingRule
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ##   body: JObject (required)
  var body_613281 = newJObject()
  if body != nil:
    body_613281 = body
  result = call_613280.call(nil, nil, nil, nil, body_613281)

var createSamplingRule* = Call_CreateSamplingRule_613268(
    name: "createSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/CreateSamplingRule",
    validator: validate_CreateSamplingRule_613269, base: "/",
    url: url_CreateSamplingRule_613270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_613282 = ref object of OpenApiRestCall_612658
proc url_DeleteGroup_613284(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteGroup_613283(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes a group resource.
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
  var valid_613285 = header.getOrDefault("X-Amz-Signature")
  valid_613285 = validateParameter(valid_613285, JString, required = false,
                                 default = nil)
  if valid_613285 != nil:
    section.add "X-Amz-Signature", valid_613285
  var valid_613286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613286 = validateParameter(valid_613286, JString, required = false,
                                 default = nil)
  if valid_613286 != nil:
    section.add "X-Amz-Content-Sha256", valid_613286
  var valid_613287 = header.getOrDefault("X-Amz-Date")
  valid_613287 = validateParameter(valid_613287, JString, required = false,
                                 default = nil)
  if valid_613287 != nil:
    section.add "X-Amz-Date", valid_613287
  var valid_613288 = header.getOrDefault("X-Amz-Credential")
  valid_613288 = validateParameter(valid_613288, JString, required = false,
                                 default = nil)
  if valid_613288 != nil:
    section.add "X-Amz-Credential", valid_613288
  var valid_613289 = header.getOrDefault("X-Amz-Security-Token")
  valid_613289 = validateParameter(valid_613289, JString, required = false,
                                 default = nil)
  if valid_613289 != nil:
    section.add "X-Amz-Security-Token", valid_613289
  var valid_613290 = header.getOrDefault("X-Amz-Algorithm")
  valid_613290 = validateParameter(valid_613290, JString, required = false,
                                 default = nil)
  if valid_613290 != nil:
    section.add "X-Amz-Algorithm", valid_613290
  var valid_613291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-SignedHeaders", valid_613291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613293: Call_DeleteGroup_613282; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a group resource.
  ## 
  let valid = call_613293.validator(path, query, header, formData, body)
  let scheme = call_613293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613293.url(scheme.get, call_613293.host, call_613293.base,
                         call_613293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613293, url, valid)

proc call*(call_613294: Call_DeleteGroup_613282; body: JsonNode): Recallable =
  ## deleteGroup
  ## Deletes a group resource.
  ##   body: JObject (required)
  var body_613295 = newJObject()
  if body != nil:
    body_613295 = body
  result = call_613294.call(nil, nil, nil, nil, body_613295)

var deleteGroup* = Call_DeleteGroup_613282(name: "deleteGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/DeleteGroup",
                                        validator: validate_DeleteGroup_613283,
                                        base: "/", url: url_DeleteGroup_613284,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSamplingRule_613296 = ref object of OpenApiRestCall_612658
proc url_DeleteSamplingRule_613298(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSamplingRule_613297(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Deletes a sampling rule.
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
  var valid_613299 = header.getOrDefault("X-Amz-Signature")
  valid_613299 = validateParameter(valid_613299, JString, required = false,
                                 default = nil)
  if valid_613299 != nil:
    section.add "X-Amz-Signature", valid_613299
  var valid_613300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613300 = validateParameter(valid_613300, JString, required = false,
                                 default = nil)
  if valid_613300 != nil:
    section.add "X-Amz-Content-Sha256", valid_613300
  var valid_613301 = header.getOrDefault("X-Amz-Date")
  valid_613301 = validateParameter(valid_613301, JString, required = false,
                                 default = nil)
  if valid_613301 != nil:
    section.add "X-Amz-Date", valid_613301
  var valid_613302 = header.getOrDefault("X-Amz-Credential")
  valid_613302 = validateParameter(valid_613302, JString, required = false,
                                 default = nil)
  if valid_613302 != nil:
    section.add "X-Amz-Credential", valid_613302
  var valid_613303 = header.getOrDefault("X-Amz-Security-Token")
  valid_613303 = validateParameter(valid_613303, JString, required = false,
                                 default = nil)
  if valid_613303 != nil:
    section.add "X-Amz-Security-Token", valid_613303
  var valid_613304 = header.getOrDefault("X-Amz-Algorithm")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "X-Amz-Algorithm", valid_613304
  var valid_613305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "X-Amz-SignedHeaders", valid_613305
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613307: Call_DeleteSamplingRule_613296; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes a sampling rule.
  ## 
  let valid = call_613307.validator(path, query, header, formData, body)
  let scheme = call_613307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613307.url(scheme.get, call_613307.host, call_613307.base,
                         call_613307.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613307, url, valid)

proc call*(call_613308: Call_DeleteSamplingRule_613296; body: JsonNode): Recallable =
  ## deleteSamplingRule
  ## Deletes a sampling rule.
  ##   body: JObject (required)
  var body_613309 = newJObject()
  if body != nil:
    body_613309 = body
  result = call_613308.call(nil, nil, nil, nil, body_613309)

var deleteSamplingRule* = Call_DeleteSamplingRule_613296(
    name: "deleteSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/DeleteSamplingRule",
    validator: validate_DeleteSamplingRule_613297, base: "/",
    url: url_DeleteSamplingRule_613298, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEncryptionConfig_613310 = ref object of OpenApiRestCall_612658
proc url_GetEncryptionConfig_613312(protocol: Scheme; host: string; base: string;
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

proc validate_GetEncryptionConfig_613311(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Retrieves the current encryption configuration for X-Ray data.
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
  var valid_613313 = header.getOrDefault("X-Amz-Signature")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Signature", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-Content-Sha256", valid_613314
  var valid_613315 = header.getOrDefault("X-Amz-Date")
  valid_613315 = validateParameter(valid_613315, JString, required = false,
                                 default = nil)
  if valid_613315 != nil:
    section.add "X-Amz-Date", valid_613315
  var valid_613316 = header.getOrDefault("X-Amz-Credential")
  valid_613316 = validateParameter(valid_613316, JString, required = false,
                                 default = nil)
  if valid_613316 != nil:
    section.add "X-Amz-Credential", valid_613316
  var valid_613317 = header.getOrDefault("X-Amz-Security-Token")
  valid_613317 = validateParameter(valid_613317, JString, required = false,
                                 default = nil)
  if valid_613317 != nil:
    section.add "X-Amz-Security-Token", valid_613317
  var valid_613318 = header.getOrDefault("X-Amz-Algorithm")
  valid_613318 = validateParameter(valid_613318, JString, required = false,
                                 default = nil)
  if valid_613318 != nil:
    section.add "X-Amz-Algorithm", valid_613318
  var valid_613319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613319 = validateParameter(valid_613319, JString, required = false,
                                 default = nil)
  if valid_613319 != nil:
    section.add "X-Amz-SignedHeaders", valid_613319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613320: Call_GetEncryptionConfig_613310; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves the current encryption configuration for X-Ray data.
  ## 
  let valid = call_613320.validator(path, query, header, formData, body)
  let scheme = call_613320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613320.url(scheme.get, call_613320.host, call_613320.base,
                         call_613320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613320, url, valid)

proc call*(call_613321: Call_GetEncryptionConfig_613310): Recallable =
  ## getEncryptionConfig
  ## Retrieves the current encryption configuration for X-Ray data.
  result = call_613321.call(nil, nil, nil, nil, nil)

var getEncryptionConfig* = Call_GetEncryptionConfig_613310(
    name: "getEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/EncryptionConfig",
    validator: validate_GetEncryptionConfig_613311, base: "/",
    url: url_GetEncryptionConfig_613312, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_613322 = ref object of OpenApiRestCall_612658
proc url_GetGroup_613324(protocol: Scheme; host: string; base: string; route: string;
                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_613323(path: JsonNode; query: JsonNode; header: JsonNode;
                             formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves group resource details.
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
  var valid_613325 = header.getOrDefault("X-Amz-Signature")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Signature", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Content-Sha256", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-Date")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-Date", valid_613327
  var valid_613328 = header.getOrDefault("X-Amz-Credential")
  valid_613328 = validateParameter(valid_613328, JString, required = false,
                                 default = nil)
  if valid_613328 != nil:
    section.add "X-Amz-Credential", valid_613328
  var valid_613329 = header.getOrDefault("X-Amz-Security-Token")
  valid_613329 = validateParameter(valid_613329, JString, required = false,
                                 default = nil)
  if valid_613329 != nil:
    section.add "X-Amz-Security-Token", valid_613329
  var valid_613330 = header.getOrDefault("X-Amz-Algorithm")
  valid_613330 = validateParameter(valid_613330, JString, required = false,
                                 default = nil)
  if valid_613330 != nil:
    section.add "X-Amz-Algorithm", valid_613330
  var valid_613331 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613331 = validateParameter(valid_613331, JString, required = false,
                                 default = nil)
  if valid_613331 != nil:
    section.add "X-Amz-SignedHeaders", valid_613331
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613333: Call_GetGroup_613322; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves group resource details.
  ## 
  let valid = call_613333.validator(path, query, header, formData, body)
  let scheme = call_613333.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613333.url(scheme.get, call_613333.host, call_613333.base,
                         call_613333.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613333, url, valid)

proc call*(call_613334: Call_GetGroup_613322; body: JsonNode): Recallable =
  ## getGroup
  ## Retrieves group resource details.
  ##   body: JObject (required)
  var body_613335 = newJObject()
  if body != nil:
    body_613335 = body
  result = call_613334.call(nil, nil, nil, nil, body_613335)

var getGroup* = Call_GetGroup_613322(name: "getGroup", meth: HttpMethod.HttpPost,
                                  host: "xray.amazonaws.com", route: "/GetGroup",
                                  validator: validate_GetGroup_613323, base: "/",
                                  url: url_GetGroup_613324,
                                  schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroups_613336 = ref object of OpenApiRestCall_612658
proc url_GetGroups_613338(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroups_613337(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves all active group details.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613339 = query.getOrDefault("NextToken")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "NextToken", valid_613339
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
  var valid_613340 = header.getOrDefault("X-Amz-Signature")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Signature", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Content-Sha256", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Date")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Date", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Credential")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Credential", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Security-Token")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Security-Token", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-Algorithm")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-Algorithm", valid_613345
  var valid_613346 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613346 = validateParameter(valid_613346, JString, required = false,
                                 default = nil)
  if valid_613346 != nil:
    section.add "X-Amz-SignedHeaders", valid_613346
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613348: Call_GetGroups_613336; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all active group details.
  ## 
  let valid = call_613348.validator(path, query, header, formData, body)
  let scheme = call_613348.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613348.url(scheme.get, call_613348.host, call_613348.base,
                         call_613348.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613348, url, valid)

proc call*(call_613349: Call_GetGroups_613336; body: JsonNode; NextToken: string = ""): Recallable =
  ## getGroups
  ## Retrieves all active group details.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613350 = newJObject()
  var body_613351 = newJObject()
  add(query_613350, "NextToken", newJString(NextToken))
  if body != nil:
    body_613351 = body
  result = call_613349.call(nil, query_613350, nil, nil, body_613351)

var getGroups* = Call_GetGroups_613336(name: "getGroups", meth: HttpMethod.HttpPost,
                                    host: "xray.amazonaws.com", route: "/Groups",
                                    validator: validate_GetGroups_613337,
                                    base: "/", url: url_GetGroups_613338,
                                    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingRules_613352 = ref object of OpenApiRestCall_612658
proc url_GetSamplingRules_613354(protocol: Scheme; host: string; base: string;
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

proc validate_GetSamplingRules_613353(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Retrieves all sampling rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613355 = query.getOrDefault("NextToken")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "NextToken", valid_613355
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
  var valid_613356 = header.getOrDefault("X-Amz-Signature")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Signature", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Content-Sha256", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-Date")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-Date", valid_613358
  var valid_613359 = header.getOrDefault("X-Amz-Credential")
  valid_613359 = validateParameter(valid_613359, JString, required = false,
                                 default = nil)
  if valid_613359 != nil:
    section.add "X-Amz-Credential", valid_613359
  var valid_613360 = header.getOrDefault("X-Amz-Security-Token")
  valid_613360 = validateParameter(valid_613360, JString, required = false,
                                 default = nil)
  if valid_613360 != nil:
    section.add "X-Amz-Security-Token", valid_613360
  var valid_613361 = header.getOrDefault("X-Amz-Algorithm")
  valid_613361 = validateParameter(valid_613361, JString, required = false,
                                 default = nil)
  if valid_613361 != nil:
    section.add "X-Amz-Algorithm", valid_613361
  var valid_613362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613362 = validateParameter(valid_613362, JString, required = false,
                                 default = nil)
  if valid_613362 != nil:
    section.add "X-Amz-SignedHeaders", valid_613362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613364: Call_GetSamplingRules_613352; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves all sampling rules.
  ## 
  let valid = call_613364.validator(path, query, header, formData, body)
  let scheme = call_613364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613364.url(scheme.get, call_613364.host, call_613364.base,
                         call_613364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613364, url, valid)

proc call*(call_613365: Call_GetSamplingRules_613352; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getSamplingRules
  ## Retrieves all sampling rules.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613366 = newJObject()
  var body_613367 = newJObject()
  add(query_613366, "NextToken", newJString(NextToken))
  if body != nil:
    body_613367 = body
  result = call_613365.call(nil, query_613366, nil, nil, body_613367)

var getSamplingRules* = Call_GetSamplingRules_613352(name: "getSamplingRules",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/GetSamplingRules", validator: validate_GetSamplingRules_613353,
    base: "/", url: url_GetSamplingRules_613354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingStatisticSummaries_613368 = ref object of OpenApiRestCall_612658
proc url_GetSamplingStatisticSummaries_613370(protocol: Scheme; host: string;
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

proc validate_GetSamplingStatisticSummaries_613369(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves information about recent sampling results for all sampling rules.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613371 = query.getOrDefault("NextToken")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "NextToken", valid_613371
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
  var valid_613372 = header.getOrDefault("X-Amz-Signature")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Signature", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Content-Sha256", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Date")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Date", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Credential")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Credential", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-Security-Token")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-Security-Token", valid_613376
  var valid_613377 = header.getOrDefault("X-Amz-Algorithm")
  valid_613377 = validateParameter(valid_613377, JString, required = false,
                                 default = nil)
  if valid_613377 != nil:
    section.add "X-Amz-Algorithm", valid_613377
  var valid_613378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613378 = validateParameter(valid_613378, JString, required = false,
                                 default = nil)
  if valid_613378 != nil:
    section.add "X-Amz-SignedHeaders", valid_613378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613380: Call_GetSamplingStatisticSummaries_613368; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves information about recent sampling results for all sampling rules.
  ## 
  let valid = call_613380.validator(path, query, header, formData, body)
  let scheme = call_613380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613380.url(scheme.get, call_613380.host, call_613380.base,
                         call_613380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613380, url, valid)

proc call*(call_613381: Call_GetSamplingStatisticSummaries_613368; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getSamplingStatisticSummaries
  ## Retrieves information about recent sampling results for all sampling rules.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613382 = newJObject()
  var body_613383 = newJObject()
  add(query_613382, "NextToken", newJString(NextToken))
  if body != nil:
    body_613383 = body
  result = call_613381.call(nil, query_613382, nil, nil, body_613383)

var getSamplingStatisticSummaries* = Call_GetSamplingStatisticSummaries_613368(
    name: "getSamplingStatisticSummaries", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingStatisticSummaries",
    validator: validate_GetSamplingStatisticSummaries_613369, base: "/",
    url: url_GetSamplingStatisticSummaries_613370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingTargets_613384 = ref object of OpenApiRestCall_612658
proc url_GetSamplingTargets_613386(protocol: Scheme; host: string; base: string;
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

proc validate_GetSamplingTargets_613385(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
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
  var valid_613387 = header.getOrDefault("X-Amz-Signature")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Signature", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Content-Sha256", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-Date")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-Date", valid_613389
  var valid_613390 = header.getOrDefault("X-Amz-Credential")
  valid_613390 = validateParameter(valid_613390, JString, required = false,
                                 default = nil)
  if valid_613390 != nil:
    section.add "X-Amz-Credential", valid_613390
  var valid_613391 = header.getOrDefault("X-Amz-Security-Token")
  valid_613391 = validateParameter(valid_613391, JString, required = false,
                                 default = nil)
  if valid_613391 != nil:
    section.add "X-Amz-Security-Token", valid_613391
  var valid_613392 = header.getOrDefault("X-Amz-Algorithm")
  valid_613392 = validateParameter(valid_613392, JString, required = false,
                                 default = nil)
  if valid_613392 != nil:
    section.add "X-Amz-Algorithm", valid_613392
  var valid_613393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613393 = validateParameter(valid_613393, JString, required = false,
                                 default = nil)
  if valid_613393 != nil:
    section.add "X-Amz-SignedHeaders", valid_613393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613395: Call_GetSamplingTargets_613384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ## 
  let valid = call_613395.validator(path, query, header, formData, body)
  let scheme = call_613395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613395.url(scheme.get, call_613395.host, call_613395.base,
                         call_613395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613395, url, valid)

proc call*(call_613396: Call_GetSamplingTargets_613384; body: JsonNode): Recallable =
  ## getSamplingTargets
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ##   body: JObject (required)
  var body_613397 = newJObject()
  if body != nil:
    body_613397 = body
  result = call_613396.call(nil, nil, nil, nil, body_613397)

var getSamplingTargets* = Call_GetSamplingTargets_613384(
    name: "getSamplingTargets", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingTargets",
    validator: validate_GetSamplingTargets_613385, base: "/",
    url: url_GetSamplingTargets_613386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceGraph_613398 = ref object of OpenApiRestCall_612658
proc url_GetServiceGraph_613400(protocol: Scheme; host: string; base: string;
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

proc validate_GetServiceGraph_613399(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613401 = query.getOrDefault("NextToken")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "NextToken", valid_613401
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
  var valid_613402 = header.getOrDefault("X-Amz-Signature")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Signature", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Content-Sha256", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Date")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Date", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Credential")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Credential", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Security-Token")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Security-Token", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-Algorithm")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-Algorithm", valid_613407
  var valid_613408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613408 = validateParameter(valid_613408, JString, required = false,
                                 default = nil)
  if valid_613408 != nil:
    section.add "X-Amz-SignedHeaders", valid_613408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613410: Call_GetServiceGraph_613398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ## 
  let valid = call_613410.validator(path, query, header, formData, body)
  let scheme = call_613410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613410.url(scheme.get, call_613410.host, call_613410.base,
                         call_613410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613410, url, valid)

proc call*(call_613411: Call_GetServiceGraph_613398; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getServiceGraph
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613412 = newJObject()
  var body_613413 = newJObject()
  add(query_613412, "NextToken", newJString(NextToken))
  if body != nil:
    body_613413 = body
  result = call_613411.call(nil, query_613412, nil, nil, body_613413)

var getServiceGraph* = Call_GetServiceGraph_613398(name: "getServiceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/ServiceGraph",
    validator: validate_GetServiceGraph_613399, base: "/", url: url_GetServiceGraph_613400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTimeSeriesServiceStatistics_613414 = ref object of OpenApiRestCall_612658
proc url_GetTimeSeriesServiceStatistics_613416(protocol: Scheme; host: string;
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

proc validate_GetTimeSeriesServiceStatistics_613415(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Get an aggregation of service statistics defined by a specific time range.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613417 = query.getOrDefault("NextToken")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "NextToken", valid_613417
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
  var valid_613418 = header.getOrDefault("X-Amz-Signature")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Signature", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Content-Sha256", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-Date")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-Date", valid_613420
  var valid_613421 = header.getOrDefault("X-Amz-Credential")
  valid_613421 = validateParameter(valid_613421, JString, required = false,
                                 default = nil)
  if valid_613421 != nil:
    section.add "X-Amz-Credential", valid_613421
  var valid_613422 = header.getOrDefault("X-Amz-Security-Token")
  valid_613422 = validateParameter(valid_613422, JString, required = false,
                                 default = nil)
  if valid_613422 != nil:
    section.add "X-Amz-Security-Token", valid_613422
  var valid_613423 = header.getOrDefault("X-Amz-Algorithm")
  valid_613423 = validateParameter(valid_613423, JString, required = false,
                                 default = nil)
  if valid_613423 != nil:
    section.add "X-Amz-Algorithm", valid_613423
  var valid_613424 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613424 = validateParameter(valid_613424, JString, required = false,
                                 default = nil)
  if valid_613424 != nil:
    section.add "X-Amz-SignedHeaders", valid_613424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613426: Call_GetTimeSeriesServiceStatistics_613414; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get an aggregation of service statistics defined by a specific time range.
  ## 
  let valid = call_613426.validator(path, query, header, formData, body)
  let scheme = call_613426.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613426.url(scheme.get, call_613426.host, call_613426.base,
                         call_613426.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613426, url, valid)

proc call*(call_613427: Call_GetTimeSeriesServiceStatistics_613414; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTimeSeriesServiceStatistics
  ## Get an aggregation of service statistics defined by a specific time range.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613428 = newJObject()
  var body_613429 = newJObject()
  add(query_613428, "NextToken", newJString(NextToken))
  if body != nil:
    body_613429 = body
  result = call_613427.call(nil, query_613428, nil, nil, body_613429)

var getTimeSeriesServiceStatistics* = Call_GetTimeSeriesServiceStatistics_613414(
    name: "getTimeSeriesServiceStatistics", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TimeSeriesServiceStatistics",
    validator: validate_GetTimeSeriesServiceStatistics_613415, base: "/",
    url: url_GetTimeSeriesServiceStatistics_613416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceGraph_613430 = ref object of OpenApiRestCall_612658
proc url_GetTraceGraph_613432(protocol: Scheme; host: string; base: string;
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

proc validate_GetTraceGraph_613431(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Retrieves a service graph for one or more specific trace IDs.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613433 = query.getOrDefault("NextToken")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "NextToken", valid_613433
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
  var valid_613434 = header.getOrDefault("X-Amz-Signature")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Signature", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Content-Sha256", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Date")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Date", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Credential")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Credential", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Security-Token")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Security-Token", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-Algorithm")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-Algorithm", valid_613439
  var valid_613440 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613440 = validateParameter(valid_613440, JString, required = false,
                                 default = nil)
  if valid_613440 != nil:
    section.add "X-Amz-SignedHeaders", valid_613440
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613442: Call_GetTraceGraph_613430; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieves a service graph for one or more specific trace IDs.
  ## 
  let valid = call_613442.validator(path, query, header, formData, body)
  let scheme = call_613442.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613442.url(scheme.get, call_613442.host, call_613442.base,
                         call_613442.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613442, url, valid)

proc call*(call_613443: Call_GetTraceGraph_613430; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTraceGraph
  ## Retrieves a service graph for one or more specific trace IDs.
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613444 = newJObject()
  var body_613445 = newJObject()
  add(query_613444, "NextToken", newJString(NextToken))
  if body != nil:
    body_613445 = body
  result = call_613443.call(nil, query_613444, nil, nil, body_613445)

var getTraceGraph* = Call_GetTraceGraph_613430(name: "getTraceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceGraph",
    validator: validate_GetTraceGraph_613431, base: "/", url: url_GetTraceGraph_613432,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceSummaries_613446 = ref object of OpenApiRestCall_612658
proc url_GetTraceSummaries_613448(protocol: Scheme; host: string; base: string;
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

proc validate_GetTraceSummaries_613447(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  section = newJObject()
  var valid_613449 = query.getOrDefault("NextToken")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "NextToken", valid_613449
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
  var valid_613450 = header.getOrDefault("X-Amz-Signature")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Signature", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Content-Sha256", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Date")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Date", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Credential")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Credential", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-Security-Token")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-Security-Token", valid_613454
  var valid_613455 = header.getOrDefault("X-Amz-Algorithm")
  valid_613455 = validateParameter(valid_613455, JString, required = false,
                                 default = nil)
  if valid_613455 != nil:
    section.add "X-Amz-Algorithm", valid_613455
  var valid_613456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613456 = validateParameter(valid_613456, JString, required = false,
                                 default = nil)
  if valid_613456 != nil:
    section.add "X-Amz-SignedHeaders", valid_613456
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613458: Call_GetTraceSummaries_613446; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ## 
  let valid = call_613458.validator(path, query, header, formData, body)
  let scheme = call_613458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613458.url(scheme.get, call_613458.host, call_613458.base,
                         call_613458.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613458, url, valid)

proc call*(call_613459: Call_GetTraceSummaries_613446; body: JsonNode;
          NextToken: string = ""): Recallable =
  ## getTraceSummaries
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ##   NextToken: string
  ##            : Pagination token
  ##   body: JObject (required)
  var query_613460 = newJObject()
  var body_613461 = newJObject()
  add(query_613460, "NextToken", newJString(NextToken))
  if body != nil:
    body_613461 = body
  result = call_613459.call(nil, query_613460, nil, nil, body_613461)

var getTraceSummaries* = Call_GetTraceSummaries_613446(name: "getTraceSummaries",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceSummaries",
    validator: validate_GetTraceSummaries_613447, base: "/",
    url: url_GetTraceSummaries_613448, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEncryptionConfig_613462 = ref object of OpenApiRestCall_612658
proc url_PutEncryptionConfig_613464(protocol: Scheme; host: string; base: string;
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

proc validate_PutEncryptionConfig_613463(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Updates the encryption configuration for X-Ray data.
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
  var valid_613465 = header.getOrDefault("X-Amz-Signature")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Signature", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Content-Sha256", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Date")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Date", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Credential")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Credential", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Security-Token")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Security-Token", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-Algorithm")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-Algorithm", valid_613470
  var valid_613471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613471 = validateParameter(valid_613471, JString, required = false,
                                 default = nil)
  if valid_613471 != nil:
    section.add "X-Amz-SignedHeaders", valid_613471
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613473: Call_PutEncryptionConfig_613462; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates the encryption configuration for X-Ray data.
  ## 
  let valid = call_613473.validator(path, query, header, formData, body)
  let scheme = call_613473.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613473.url(scheme.get, call_613473.host, call_613473.base,
                         call_613473.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613473, url, valid)

proc call*(call_613474: Call_PutEncryptionConfig_613462; body: JsonNode): Recallable =
  ## putEncryptionConfig
  ## Updates the encryption configuration for X-Ray data.
  ##   body: JObject (required)
  var body_613475 = newJObject()
  if body != nil:
    body_613475 = body
  result = call_613474.call(nil, nil, nil, nil, body_613475)

var putEncryptionConfig* = Call_PutEncryptionConfig_613462(
    name: "putEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/PutEncryptionConfig",
    validator: validate_PutEncryptionConfig_613463, base: "/",
    url: url_PutEncryptionConfig_613464, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTelemetryRecords_613476 = ref object of OpenApiRestCall_612658
proc url_PutTelemetryRecords_613478(protocol: Scheme; host: string; base: string;
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

proc validate_PutTelemetryRecords_613477(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Used by the AWS X-Ray daemon to upload telemetry.
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
  var valid_613479 = header.getOrDefault("X-Amz-Signature")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Signature", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Content-Sha256", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Date")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Date", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Credential")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Credential", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Security-Token")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Security-Token", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-Algorithm")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-Algorithm", valid_613484
  var valid_613485 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613485 = validateParameter(valid_613485, JString, required = false,
                                 default = nil)
  if valid_613485 != nil:
    section.add "X-Amz-SignedHeaders", valid_613485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613487: Call_PutTelemetryRecords_613476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ## 
  let valid = call_613487.validator(path, query, header, formData, body)
  let scheme = call_613487.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613487.url(scheme.get, call_613487.host, call_613487.base,
                         call_613487.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613487, url, valid)

proc call*(call_613488: Call_PutTelemetryRecords_613476; body: JsonNode): Recallable =
  ## putTelemetryRecords
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ##   body: JObject (required)
  var body_613489 = newJObject()
  if body != nil:
    body_613489 = body
  result = call_613488.call(nil, nil, nil, nil, body_613489)

var putTelemetryRecords* = Call_PutTelemetryRecords_613476(
    name: "putTelemetryRecords", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TelemetryRecords",
    validator: validate_PutTelemetryRecords_613477, base: "/",
    url: url_PutTelemetryRecords_613478, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTraceSegments_613490 = ref object of OpenApiRestCall_612658
proc url_PutTraceSegments_613492(protocol: Scheme; host: string; base: string;
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

proc validate_PutTraceSegments_613491(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
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
  var valid_613493 = header.getOrDefault("X-Amz-Signature")
  valid_613493 = validateParameter(valid_613493, JString, required = false,
                                 default = nil)
  if valid_613493 != nil:
    section.add "X-Amz-Signature", valid_613493
  var valid_613494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Content-Sha256", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Date")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Date", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Credential")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Credential", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Security-Token")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Security-Token", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Algorithm")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Algorithm", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-SignedHeaders", valid_613499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_PutTraceSegments_613490; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ## 
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_PutTraceSegments_613490; body: JsonNode): Recallable =
  ## putTraceSegments
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ##   body: JObject (required)
  var body_613503 = newJObject()
  if body != nil:
    body_613503 = body
  result = call_613502.call(nil, nil, nil, nil, body_613503)

var putTraceSegments* = Call_PutTraceSegments_613490(name: "putTraceSegments",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceSegments",
    validator: validate_PutTraceSegments_613491, base: "/",
    url: url_PutTraceSegments_613492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_613504 = ref object of OpenApiRestCall_612658
proc url_UpdateGroup_613506(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateGroup_613505(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a group resource.
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
  var valid_613507 = header.getOrDefault("X-Amz-Signature")
  valid_613507 = validateParameter(valid_613507, JString, required = false,
                                 default = nil)
  if valid_613507 != nil:
    section.add "X-Amz-Signature", valid_613507
  var valid_613508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Content-Sha256", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Date")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Date", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Credential")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Credential", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Security-Token")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Security-Token", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Algorithm")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Algorithm", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-SignedHeaders", valid_613513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613515: Call_UpdateGroup_613504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a group resource.
  ## 
  let valid = call_613515.validator(path, query, header, formData, body)
  let scheme = call_613515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613515.url(scheme.get, call_613515.host, call_613515.base,
                         call_613515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613515, url, valid)

proc call*(call_613516: Call_UpdateGroup_613504; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group resource.
  ##   body: JObject (required)
  var body_613517 = newJObject()
  if body != nil:
    body_613517 = body
  result = call_613516.call(nil, nil, nil, nil, body_613517)

var updateGroup* = Call_UpdateGroup_613504(name: "updateGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/UpdateGroup",
                                        validator: validate_UpdateGroup_613505,
                                        base: "/", url: url_UpdateGroup_613506,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSamplingRule_613518 = ref object of OpenApiRestCall_612658
proc url_UpdateSamplingRule_613520(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateSamplingRule_613519(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Modifies a sampling rule's configuration.
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
  var valid_613521 = header.getOrDefault("X-Amz-Signature")
  valid_613521 = validateParameter(valid_613521, JString, required = false,
                                 default = nil)
  if valid_613521 != nil:
    section.add "X-Amz-Signature", valid_613521
  var valid_613522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613522 = validateParameter(valid_613522, JString, required = false,
                                 default = nil)
  if valid_613522 != nil:
    section.add "X-Amz-Content-Sha256", valid_613522
  var valid_613523 = header.getOrDefault("X-Amz-Date")
  valid_613523 = validateParameter(valid_613523, JString, required = false,
                                 default = nil)
  if valid_613523 != nil:
    section.add "X-Amz-Date", valid_613523
  var valid_613524 = header.getOrDefault("X-Amz-Credential")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Credential", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Security-Token")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Security-Token", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Algorithm")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Algorithm", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-SignedHeaders", valid_613527
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613529: Call_UpdateSamplingRule_613518; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Modifies a sampling rule's configuration.
  ## 
  let valid = call_613529.validator(path, query, header, formData, body)
  let scheme = call_613529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613529.url(scheme.get, call_613529.host, call_613529.base,
                         call_613529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613529, url, valid)

proc call*(call_613530: Call_UpdateSamplingRule_613518; body: JsonNode): Recallable =
  ## updateSamplingRule
  ## Modifies a sampling rule's configuration.
  ##   body: JObject (required)
  var body_613531 = newJObject()
  if body != nil:
    body_613531 = body
  result = call_613530.call(nil, nil, nil, nil, body_613531)

var updateSamplingRule* = Call_UpdateSamplingRule_613518(
    name: "updateSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/UpdateSamplingRule",
    validator: validate_UpdateSamplingRule_613519, base: "/",
    url: url_UpdateSamplingRule_613520, schemes: {Scheme.Https, Scheme.Http})
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

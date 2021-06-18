
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CodeGuru Profiler
## version: 2019-07-18
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Example service documentation.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/codeguru-profiler/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
    if required:
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "codeguru-profiler.ap-northeast-1.amazonaws.com", "ap-southeast-1": "codeguru-profiler.ap-southeast-1.amazonaws.com", "us-west-2": "codeguru-profiler.us-west-2.amazonaws.com", "eu-west-2": "codeguru-profiler.eu-west-2.amazonaws.com", "ap-northeast-3": "codeguru-profiler.ap-northeast-3.amazonaws.com", "eu-central-1": "codeguru-profiler.eu-central-1.amazonaws.com", "us-east-2": "codeguru-profiler.us-east-2.amazonaws.com", "us-east-1": "codeguru-profiler.us-east-1.amazonaws.com", "cn-northwest-1": "codeguru-profiler.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "codeguru-profiler.ap-south-1.amazonaws.com", "eu-north-1": "codeguru-profiler.eu-north-1.amazonaws.com", "ap-northeast-2": "codeguru-profiler.ap-northeast-2.amazonaws.com", "us-west-1": "codeguru-profiler.us-west-1.amazonaws.com", "us-gov-east-1": "codeguru-profiler.us-gov-east-1.amazonaws.com", "eu-west-3": "codeguru-profiler.eu-west-3.amazonaws.com", "cn-north-1": "codeguru-profiler.cn-north-1.amazonaws.com.cn", "sa-east-1": "codeguru-profiler.sa-east-1.amazonaws.com", "eu-west-1": "codeguru-profiler.eu-west-1.amazonaws.com", "us-gov-west-1": "codeguru-profiler.us-gov-west-1.amazonaws.com", "ap-southeast-2": "codeguru-profiler.ap-southeast-2.amazonaws.com", "ca-central-1": "codeguru-profiler.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "codeguru-profiler.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "codeguru-profiler.ap-southeast-1.amazonaws.com",
      "us-west-2": "codeguru-profiler.us-west-2.amazonaws.com",
      "eu-west-2": "codeguru-profiler.eu-west-2.amazonaws.com",
      "ap-northeast-3": "codeguru-profiler.ap-northeast-3.amazonaws.com",
      "eu-central-1": "codeguru-profiler.eu-central-1.amazonaws.com",
      "us-east-2": "codeguru-profiler.us-east-2.amazonaws.com",
      "us-east-1": "codeguru-profiler.us-east-1.amazonaws.com",
      "cn-northwest-1": "codeguru-profiler.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "codeguru-profiler.ap-south-1.amazonaws.com",
      "eu-north-1": "codeguru-profiler.eu-north-1.amazonaws.com",
      "ap-northeast-2": "codeguru-profiler.ap-northeast-2.amazonaws.com",
      "us-west-1": "codeguru-profiler.us-west-1.amazonaws.com",
      "us-gov-east-1": "codeguru-profiler.us-gov-east-1.amazonaws.com",
      "eu-west-3": "codeguru-profiler.eu-west-3.amazonaws.com",
      "cn-north-1": "codeguru-profiler.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "codeguru-profiler.sa-east-1.amazonaws.com",
      "eu-west-1": "codeguru-profiler.eu-west-1.amazonaws.com",
      "us-gov-west-1": "codeguru-profiler.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "codeguru-profiler.ap-southeast-2.amazonaws.com",
      "ca-central-1": "codeguru-profiler.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "codeguruprofiler"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_ConfigureAgent_402656288 = ref object of OpenApiRestCall_402656038
proc url_ConfigureAgent_402656290(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName"),
                 (kind: ConstantSegment, value: "/configureAgent")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ConfigureAgent_402656289(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Provides the configuration to use for an agent of the profiling group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656383 = path.getOrDefault("profilingGroupName")
  valid_402656383 = validateParameter(valid_402656383, JString, required = true,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "profilingGroupName", valid_402656383
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Security-Token", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Signature")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Signature", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Algorithm", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Date")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Date", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Credential")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Credential", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656405: Call_ConfigureAgent_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides the configuration to use for an agent of the profiling group.
                                                                                         ## 
  let valid = call_402656405.validator(path, query, header, formData, body, _)
  let scheme = call_402656405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656405.makeUrl(scheme.get, call_402656405.host, call_402656405.base,
                                   call_402656405.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656405, uri, valid, _)

proc call*(call_402656454: Call_ConfigureAgent_402656288;
           profilingGroupName: string; body: JsonNode): Recallable =
  ## configureAgent
  ## Provides the configuration to use for an agent of the profiling group.
  ##   
                                                                           ## profilingGroupName: string (required)
                                                                           ##                     
                                                                           ## : 
                                                                           ## The 
                                                                           ## name 
                                                                           ## of 
                                                                           ## the 
                                                                           ## profiling 
                                                                           ## group.
  ##   
                                                                                    ## body: JObject (required)
  var path_402656455 = newJObject()
  var body_402656457 = newJObject()
  add(path_402656455, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_402656457 = body
  result = call_402656454.call(path_402656455, nil, nil, nil, body_402656457)

var configureAgent* = Call_ConfigureAgent_402656288(name: "configureAgent",
    meth: HttpMethod.HttpPost, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/configureAgent",
    validator: validate_ConfigureAgent_402656289, base: "/",
    makeUrl: url_ConfigureAgent_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateProfilingGroup_402656483 = ref object of OpenApiRestCall_402656038
proc url_CreateProfilingGroup_402656485(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateProfilingGroup_402656484(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a profiling group.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   clientToken: JString (required)
                                  ##              : Client token for the request.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `clientToken` field"
  var valid_402656486 = query.getOrDefault("clientToken")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true,
                                      default = nil)
  if valid_402656486 != nil:
    section.add "clientToken", valid_402656486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-Security-Token", valid_402656487
  var valid_402656488 = header.getOrDefault("X-Amz-Signature")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "X-Amz-Signature", valid_402656488
  var valid_402656489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656489
  var valid_402656490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Algorithm", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Date")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Date", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Credential")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Credential", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656495: Call_CreateProfilingGroup_402656483;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a profiling group.
                                                                                         ## 
  let valid = call_402656495.validator(path, query, header, formData, body, _)
  let scheme = call_402656495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656495.makeUrl(scheme.get, call_402656495.host, call_402656495.base,
                                   call_402656495.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656495, uri, valid, _)

proc call*(call_402656496: Call_CreateProfilingGroup_402656483; body: JsonNode;
           clientToken: string): Recallable =
  ## createProfilingGroup
  ## Create a profiling group.
  ##   body: JObject (required)
  ##   clientToken: string (required)
                               ##              : Client token for the request.
  var query_402656497 = newJObject()
  var body_402656498 = newJObject()
  if body != nil:
    body_402656498 = body
  add(query_402656497, "clientToken", newJString(clientToken))
  result = call_402656496.call(nil, query_402656497, nil, nil, body_402656498)

var createProfilingGroup* = Call_CreateProfilingGroup_402656483(
    name: "createProfilingGroup", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups#clientToken",
    validator: validate_CreateProfilingGroup_402656484, base: "/",
    makeUrl: url_CreateProfilingGroup_402656485,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateProfilingGroup_402656513 = ref object of OpenApiRestCall_402656038
proc url_UpdateProfilingGroup_402656515(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateProfilingGroup_402656514(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a profiling group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656516 = path.getOrDefault("profilingGroupName")
  valid_402656516 = validateParameter(valid_402656516, JString, required = true,
                                      default = nil)
  if valid_402656516 != nil:
    section.add "profilingGroupName", valid_402656516
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656517 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Security-Token", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Signature")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Signature", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Algorithm", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Date")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Date", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Credential")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Credential", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656525: Call_UpdateProfilingGroup_402656513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a profiling group.
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_UpdateProfilingGroup_402656513;
           profilingGroupName: string; body: JsonNode): Recallable =
  ## updateProfilingGroup
  ## Update a profiling group.
  ##   profilingGroupName: string (required)
                              ##                     : The name of the profiling group.
  ##   
                                                                                       ## body: JObject (required)
  var path_402656527 = newJObject()
  var body_402656528 = newJObject()
  add(path_402656527, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_402656528 = body
  result = call_402656526.call(path_402656527, nil, nil, nil, body_402656528)

var updateProfilingGroup* = Call_UpdateProfilingGroup_402656513(
    name: "updateProfilingGroup", meth: HttpMethod.HttpPut,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_UpdateProfilingGroup_402656514, base: "/",
    makeUrl: url_UpdateProfilingGroup_402656515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeProfilingGroup_402656499 = ref object of OpenApiRestCall_402656038
proc url_DescribeProfilingGroup_402656501(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeProfilingGroup_402656500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describe a profiling group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656502 = path.getOrDefault("profilingGroupName")
  valid_402656502 = validateParameter(valid_402656502, JString, required = true,
                                      default = nil)
  if valid_402656502 != nil:
    section.add "profilingGroupName", valid_402656502
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656503 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Security-Token", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Signature")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Signature", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Algorithm", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Date")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Date", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Credential")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Credential", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656509
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656510: Call_DescribeProfilingGroup_402656499;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describe a profiling group.
                                                                                         ## 
  let valid = call_402656510.validator(path, query, header, formData, body, _)
  let scheme = call_402656510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656510.makeUrl(scheme.get, call_402656510.host, call_402656510.base,
                                   call_402656510.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656510, uri, valid, _)

proc call*(call_402656511: Call_DescribeProfilingGroup_402656499;
           profilingGroupName: string): Recallable =
  ## describeProfilingGroup
  ## Describe a profiling group.
  ##   profilingGroupName: string (required)
                                ##                     : The name of the profiling group.
  var path_402656512 = newJObject()
  add(path_402656512, "profilingGroupName", newJString(profilingGroupName))
  result = call_402656511.call(path_402656512, nil, nil, nil, nil)

var describeProfilingGroup* = Call_DescribeProfilingGroup_402656499(
    name: "describeProfilingGroup", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DescribeProfilingGroup_402656500, base: "/",
    makeUrl: url_DescribeProfilingGroup_402656501,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteProfilingGroup_402656529 = ref object of OpenApiRestCall_402656038
proc url_DeleteProfilingGroup_402656531(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteProfilingGroup_402656530(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a profiling group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656532 = path.getOrDefault("profilingGroupName")
  valid_402656532 = validateParameter(valid_402656532, JString, required = true,
                                      default = nil)
  if valid_402656532 != nil:
    section.add "profilingGroupName", valid_402656532
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656533 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Security-Token", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Signature")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Signature", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Algorithm", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Date")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Date", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Credential")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Credential", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656539
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656540: Call_DeleteProfilingGroup_402656529;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a profiling group.
                                                                                         ## 
  let valid = call_402656540.validator(path, query, header, formData, body, _)
  let scheme = call_402656540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656540.makeUrl(scheme.get, call_402656540.host, call_402656540.base,
                                   call_402656540.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656540, uri, valid, _)

proc call*(call_402656541: Call_DeleteProfilingGroup_402656529;
           profilingGroupName: string): Recallable =
  ## deleteProfilingGroup
  ## Delete a profiling group.
  ##   profilingGroupName: string (required)
                              ##                     : The name of the profiling group.
  var path_402656542 = newJObject()
  add(path_402656542, "profilingGroupName", newJString(profilingGroupName))
  result = call_402656541.call(path_402656542, nil, nil, nil, nil)

var deleteProfilingGroup* = Call_DeleteProfilingGroup_402656529(
    name: "deleteProfilingGroup", meth: HttpMethod.HttpDelete,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}",
    validator: validate_DeleteProfilingGroup_402656530, base: "/",
    makeUrl: url_DeleteProfilingGroup_402656531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetProfile_402656543 = ref object of OpenApiRestCall_402656038
proc url_GetProfile_402656545(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName"),
                 (kind: ConstantSegment, value: "/profile")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetProfile_402656544(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656546 = path.getOrDefault("profilingGroupName")
  valid_402656546 = validateParameter(valid_402656546, JString, required = true,
                                      default = nil)
  if valid_402656546 != nil:
    section.add "profilingGroupName", valid_402656546
  result.add "path", section
  ## parameters in `query` object:
  ##   maxDepth: JInt
                                  ##           : Limit the max depth of the profile.
  ##   
                                                                                    ## period: JString
                                                                                    ##         
                                                                                    ## : 
                                                                                    ## Periods 
                                                                                    ## of 
                                                                                    ## time 
                                                                                    ## represented 
                                                                                    ## using 
                                                                                    ## <a 
                                                                                    ## href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 
                                                                                    ## 8601 
                                                                                    ## format</a>.
  ##   
                                                                                                  ## endTime: JString
                                                                                                  ##          
                                                                                                  ## : 
                                                                                                  ## The 
                                                                                                  ## end 
                                                                                                  ## time 
                                                                                                  ## of 
                                                                                                  ## the 
                                                                                                  ## profile 
                                                                                                  ## to 
                                                                                                  ## get. 
                                                                                                  ## Either 
                                                                                                  ## period 
                                                                                                  ## or 
                                                                                                  ## endTime 
                                                                                                  ## must 
                                                                                                  ## be 
                                                                                                  ## specified. 
                                                                                                  ## Must 
                                                                                                  ## be 
                                                                                                  ## greater 
                                                                                                  ## than 
                                                                                                  ## start 
                                                                                                  ## and 
                                                                                                  ## the 
                                                                                                  ## overall 
                                                                                                  ## time 
                                                                                                  ## range 
                                                                                                  ## to 
                                                                                                  ## be 
                                                                                                  ## in 
                                                                                                  ## the 
                                                                                                  ## past 
                                                                                                  ## and 
                                                                                                  ## not 
                                                                                                  ## larger 
                                                                                                  ## than 
                                                                                                  ## a 
                                                                                                  ## week.
  ##   
                                                                                                          ## startTime: JString
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## start 
                                                                                                          ## time 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## profile 
                                                                                                          ## to 
                                                                                                          ## get.
  section = newJObject()
  var valid_402656547 = query.getOrDefault("maxDepth")
  valid_402656547 = validateParameter(valid_402656547, JInt, required = false,
                                      default = nil)
  if valid_402656547 != nil:
    section.add "maxDepth", valid_402656547
  var valid_402656548 = query.getOrDefault("period")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "period", valid_402656548
  var valid_402656549 = query.getOrDefault("endTime")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "endTime", valid_402656549
  var valid_402656550 = query.getOrDefault("startTime")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "startTime", valid_402656550
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   Accept: JString
                               ##         : The format of the profile to return. Supports application/json or application/x-amzn-ion. Defaults to application/x-amzn-ion.
  ##   
                                                                                                                                                                         ## X-Amz-Date: JString
  ##   
                                                                                                                                                                                               ## X-Amz-Credential: JString
  ##   
                                                                                                                                                                                                                           ## X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656551 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Security-Token", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Signature")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Signature", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Algorithm", valid_402656554
  var valid_402656555 = header.getOrDefault("Accept")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "Accept", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Date")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Date", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Credential")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Credential", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656559: Call_GetProfile_402656543; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
                                                                                         ## 
  let valid = call_402656559.validator(path, query, header, formData, body, _)
  let scheme = call_402656559.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656559.makeUrl(scheme.get, call_402656559.host, call_402656559.base,
                                   call_402656559.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656559, uri, valid, _)

proc call*(call_402656560: Call_GetProfile_402656543;
           profilingGroupName: string; maxDepth: int = 0; period: string = "";
           endTime: string = ""; startTime: string = ""): Recallable =
  ## getProfile
  ## Get the aggregated profile of a profiling group for the specified time range. If the requested time range does not align with the available aggregated profiles, it will be expanded to attain alignment. If aggregated profiles are available only for part of the period requested, the profile is returned from the earliest available to the latest within the requested time range. For instance, if the requested time range is from 00:00 to 00:20 and the available profiles are from 00:15 to 00:25, then the returned profile will be from 00:15 to 00:20.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## maxDepth: int
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## Limit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## max 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## depth 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## profile.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## period: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ##         
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## Periods 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## represented 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## using 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## <a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## href="https://en.wikipedia.org/wiki/ISO_8601#Durations">ISO 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## 8601 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## format</a>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## profilingGroupName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##                     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## profiling 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## group.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## endTime: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##          
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## profile 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## get. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Either 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## period 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## or 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## endTime 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## specified. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Must 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## greater 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## start 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## overall 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## range 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## past 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## larger 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## than 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## week.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## startTime: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## start 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## profile 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## get.
  var path_402656561 = newJObject()
  var query_402656562 = newJObject()
  add(query_402656562, "maxDepth", newJInt(maxDepth))
  add(query_402656562, "period", newJString(period))
  add(path_402656561, "profilingGroupName", newJString(profilingGroupName))
  add(query_402656562, "endTime", newJString(endTime))
  add(query_402656562, "startTime", newJString(startTime))
  result = call_402656560.call(path_402656561, query_402656562, nil, nil, nil)

var getProfile* = Call_GetProfile_402656543(name: "getProfile",
    meth: HttpMethod.HttpGet, host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/profile",
    validator: validate_GetProfile_402656544, base: "/",
    makeUrl: url_GetProfile_402656545, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfileTimes_402656563 = ref object of OpenApiRestCall_402656038
proc url_ListProfileTimes_402656565(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName"), (
        kind: ConstantSegment, value: "/profileTimes#endTime&period&startTime")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListProfileTimes_402656564(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656566 = path.getOrDefault("profilingGroupName")
  valid_402656566 = validateParameter(valid_402656566, JString, required = true,
                                      default = nil)
  if valid_402656566 != nil:
    section.add "profilingGroupName", valid_402656566
  result.add "path", section
  ## parameters in `query` object:
  ##   period: JString (required)
                                  ##         : Periods of time used for aggregation of profiles, represented using ISO 8601 format.
  ##   
                                                                                                                                   ## maxResults: JInt
                                                                                                                                   ##             
                                                                                                                                   ## : 
                                                                                                                                   ## Upper 
                                                                                                                                   ## bound 
                                                                                                                                   ## on 
                                                                                                                                   ## the 
                                                                                                                                   ## number 
                                                                                                                                   ## of 
                                                                                                                                   ## results 
                                                                                                                                   ## to 
                                                                                                                                   ## list 
                                                                                                                                   ## in 
                                                                                                                                   ## a 
                                                                                                                                   ## single 
                                                                                                                                   ## call.
  ##   
                                                                                                                                           ## nextToken: JString
                                                                                                                                           ##            
                                                                                                                                           ## : 
                                                                                                                                           ## Token 
                                                                                                                                           ## for 
                                                                                                                                           ## paginating 
                                                                                                                                           ## results.
  ##   
                                                                                                                                                      ## orderBy: JString
                                                                                                                                                      ##          
                                                                                                                                                      ## : 
                                                                                                                                                      ## The 
                                                                                                                                                      ## order 
                                                                                                                                                      ## (ascending 
                                                                                                                                                      ## or 
                                                                                                                                                      ## descending 
                                                                                                                                                      ## by 
                                                                                                                                                      ## start 
                                                                                                                                                      ## time 
                                                                                                                                                      ## of 
                                                                                                                                                      ## the 
                                                                                                                                                      ## profile) 
                                                                                                                                                      ## to 
                                                                                                                                                      ## list 
                                                                                                                                                      ## the 
                                                                                                                                                      ## profiles 
                                                                                                                                                      ## by. 
                                                                                                                                                      ## Defaults 
                                                                                                                                                      ## to 
                                                                                                                                                      ## TIMESTAMP_DESCENDING.
  ##   
                                                                                                                                                                              ## endTime: JString (required)
                                                                                                                                                                              ##          
                                                                                                                                                                              ## : 
                                                                                                                                                                              ## The 
                                                                                                                                                                              ## end 
                                                                                                                                                                              ## time 
                                                                                                                                                                              ## of 
                                                                                                                                                                              ## the 
                                                                                                                                                                              ## time 
                                                                                                                                                                              ## range 
                                                                                                                                                                              ## to 
                                                                                                                                                                              ## list 
                                                                                                                                                                              ## profiles 
                                                                                                                                                                              ## until.
  ##   
                                                                                                                                                                                       ## startTime: JString (required)
                                                                                                                                                                                       ##            
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## The 
                                                                                                                                                                                       ## start 
                                                                                                                                                                                       ## time 
                                                                                                                                                                                       ## of 
                                                                                                                                                                                       ## the 
                                                                                                                                                                                       ## time 
                                                                                                                                                                                       ## range 
                                                                                                                                                                                       ## to 
                                                                                                                                                                                       ## list 
                                                                                                                                                                                       ## the 
                                                                                                                                                                                       ## profiles 
                                                                                                                                                                                       ## from.
  section = newJObject()
  var valid_402656579 = query.getOrDefault("period")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = newJString("P1D"))
  if valid_402656579 != nil:
    section.add "period", valid_402656579
  var valid_402656580 = query.getOrDefault("maxResults")
  valid_402656580 = validateParameter(valid_402656580, JInt, required = false,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "maxResults", valid_402656580
  var valid_402656581 = query.getOrDefault("nextToken")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "nextToken", valid_402656581
  var valid_402656582 = query.getOrDefault("orderBy")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = newJString(
      "TimestampAscending"))
  if valid_402656582 != nil:
    section.add "orderBy", valid_402656582
  var valid_402656583 = query.getOrDefault("endTime")
  valid_402656583 = validateParameter(valid_402656583, JString, required = true,
                                      default = nil)
  if valid_402656583 != nil:
    section.add "endTime", valid_402656583
  var valid_402656584 = query.getOrDefault("startTime")
  valid_402656584 = validateParameter(valid_402656584, JString, required = true,
                                      default = nil)
  if valid_402656584 != nil:
    section.add "startTime", valid_402656584
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656585 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Security-Token", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Signature")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Signature", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Algorithm", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Date")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Date", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Credential")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Credential", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656591
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656592: Call_ListProfileTimes_402656563;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
                                                                                         ## 
  let valid = call_402656592.validator(path, query, header, formData, body, _)
  let scheme = call_402656592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656592.makeUrl(scheme.get, call_402656592.host, call_402656592.base,
                                   call_402656592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656592, uri, valid, _)

proc call*(call_402656593: Call_ListProfileTimes_402656563;
           profilingGroupName: string; endTime: string; startTime: string;
           period: string = "P1D"; maxResults: int = 0; nextToken: string = "";
           orderBy: string = "TimestampAscending"): Recallable =
  ## listProfileTimes
  ## List the start times of the available aggregated profiles of a profiling group for an aggregation period within the specified time range.
  ##   
                                                                                                                                              ## period: string (required)
                                                                                                                                              ##         
                                                                                                                                              ## : 
                                                                                                                                              ## Periods 
                                                                                                                                              ## of 
                                                                                                                                              ## time 
                                                                                                                                              ## used 
                                                                                                                                              ## for 
                                                                                                                                              ## aggregation 
                                                                                                                                              ## of 
                                                                                                                                              ## profiles, 
                                                                                                                                              ## represented 
                                                                                                                                              ## using 
                                                                                                                                              ## ISO 
                                                                                                                                              ## 8601 
                                                                                                                                              ## format.
  ##   
                                                                                                                                                        ## profilingGroupName: string (required)
                                                                                                                                                        ##                     
                                                                                                                                                        ## : 
                                                                                                                                                        ## The 
                                                                                                                                                        ## name 
                                                                                                                                                        ## of 
                                                                                                                                                        ## the 
                                                                                                                                                        ## profiling 
                                                                                                                                                        ## group.
  ##   
                                                                                                                                                                 ## maxResults: int
                                                                                                                                                                 ##             
                                                                                                                                                                 ## : 
                                                                                                                                                                 ## Upper 
                                                                                                                                                                 ## bound 
                                                                                                                                                                 ## on 
                                                                                                                                                                 ## the 
                                                                                                                                                                 ## number 
                                                                                                                                                                 ## of 
                                                                                                                                                                 ## results 
                                                                                                                                                                 ## to 
                                                                                                                                                                 ## list 
                                                                                                                                                                 ## in 
                                                                                                                                                                 ## a 
                                                                                                                                                                 ## single 
                                                                                                                                                                 ## call.
  ##   
                                                                                                                                                                         ## nextToken: string
                                                                                                                                                                         ##            
                                                                                                                                                                         ## : 
                                                                                                                                                                         ## Token 
                                                                                                                                                                         ## for 
                                                                                                                                                                         ## paginating 
                                                                                                                                                                         ## results.
  ##   
                                                                                                                                                                                    ## orderBy: string
                                                                                                                                                                                    ##          
                                                                                                                                                                                    ## : 
                                                                                                                                                                                    ## The 
                                                                                                                                                                                    ## order 
                                                                                                                                                                                    ## (ascending 
                                                                                                                                                                                    ## or 
                                                                                                                                                                                    ## descending 
                                                                                                                                                                                    ## by 
                                                                                                                                                                                    ## start 
                                                                                                                                                                                    ## time 
                                                                                                                                                                                    ## of 
                                                                                                                                                                                    ## the 
                                                                                                                                                                                    ## profile) 
                                                                                                                                                                                    ## to 
                                                                                                                                                                                    ## list 
                                                                                                                                                                                    ## the 
                                                                                                                                                                                    ## profiles 
                                                                                                                                                                                    ## by. 
                                                                                                                                                                                    ## Defaults 
                                                                                                                                                                                    ## to 
                                                                                                                                                                                    ## TIMESTAMP_DESCENDING.
  ##   
                                                                                                                                                                                                            ## endTime: string (required)
                                                                                                                                                                                                            ##          
                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                            ## end 
                                                                                                                                                                                                            ## time 
                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                            ## time 
                                                                                                                                                                                                            ## range 
                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                            ## list 
                                                                                                                                                                                                            ## profiles 
                                                                                                                                                                                                            ## until.
  ##   
                                                                                                                                                                                                                     ## startTime: string (required)
                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                     ## start 
                                                                                                                                                                                                                     ## time 
                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## time 
                                                                                                                                                                                                                     ## range 
                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                     ## list 
                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                     ## profiles 
                                                                                                                                                                                                                     ## from.
  var path_402656594 = newJObject()
  var query_402656595 = newJObject()
  add(query_402656595, "period", newJString(period))
  add(path_402656594, "profilingGroupName", newJString(profilingGroupName))
  add(query_402656595, "maxResults", newJInt(maxResults))
  add(query_402656595, "nextToken", newJString(nextToken))
  add(query_402656595, "orderBy", newJString(orderBy))
  add(query_402656595, "endTime", newJString(endTime))
  add(query_402656595, "startTime", newJString(startTime))
  result = call_402656593.call(path_402656594, query_402656595, nil, nil, nil)

var listProfileTimes* = Call_ListProfileTimes_402656563(
    name: "listProfileTimes", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups/{profilingGroupName}/profileTimes#endTime&period&startTime",
    validator: validate_ListProfileTimes_402656564, base: "/",
    makeUrl: url_ListProfileTimes_402656565,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListProfilingGroups_402656596 = ref object of OpenApiRestCall_402656038
proc url_ListProfilingGroups_402656598(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListProfilingGroups_402656597(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List profiling groups in the account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Upper bound on the number of results to list in a single call.
  ##   
                                                                                                                 ## nextToken: JString
                                                                                                                 ##            
                                                                                                                 ## : 
                                                                                                                 ## Token 
                                                                                                                 ## for 
                                                                                                                 ## paginating 
                                                                                                                 ## results.
  ##   
                                                                                                                            ## includeDescription: JBool
                                                                                                                            ##                     
                                                                                                                            ## : 
                                                                                                                            ## If 
                                                                                                                            ## set 
                                                                                                                            ## to 
                                                                                                                            ## true, 
                                                                                                                            ## returns 
                                                                                                                            ## the 
                                                                                                                            ## full 
                                                                                                                            ## description 
                                                                                                                            ## of 
                                                                                                                            ## the 
                                                                                                                            ## profiling 
                                                                                                                            ## groups 
                                                                                                                            ## instead 
                                                                                                                            ## of 
                                                                                                                            ## the 
                                                                                                                            ## names. 
                                                                                                                            ## Defaults 
                                                                                                                            ## to 
                                                                                                                            ## false.
  section = newJObject()
  var valid_402656599 = query.getOrDefault("maxResults")
  valid_402656599 = validateParameter(valid_402656599, JInt, required = false,
                                      default = nil)
  if valid_402656599 != nil:
    section.add "maxResults", valid_402656599
  var valid_402656600 = query.getOrDefault("nextToken")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "nextToken", valid_402656600
  var valid_402656601 = query.getOrDefault("includeDescription")
  valid_402656601 = validateParameter(valid_402656601, JBool, required = false,
                                      default = nil)
  if valid_402656601 != nil:
    section.add "includeDescription", valid_402656601
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656602 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Security-Token", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Signature")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Signature", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Algorithm", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Date")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Date", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Credential")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Credential", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656609: Call_ListProfilingGroups_402656596;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List profiling groups in the account.
                                                                                         ## 
  let valid = call_402656609.validator(path, query, header, formData, body, _)
  let scheme = call_402656609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656609.makeUrl(scheme.get, call_402656609.host, call_402656609.base,
                                   call_402656609.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656609, uri, valid, _)

proc call*(call_402656610: Call_ListProfilingGroups_402656596;
           maxResults: int = 0; nextToken: string = "";
           includeDescription: bool = false): Recallable =
  ## listProfilingGroups
  ## List profiling groups in the account.
  ##   maxResults: int
                                          ##             : Upper bound on the number of results to list in a single call.
  ##   
                                                                                                                         ## nextToken: string
                                                                                                                         ##            
                                                                                                                         ## : 
                                                                                                                         ## Token 
                                                                                                                         ## for 
                                                                                                                         ## paginating 
                                                                                                                         ## results.
  ##   
                                                                                                                                    ## includeDescription: bool
                                                                                                                                    ##                     
                                                                                                                                    ## : 
                                                                                                                                    ## If 
                                                                                                                                    ## set 
                                                                                                                                    ## to 
                                                                                                                                    ## true, 
                                                                                                                                    ## returns 
                                                                                                                                    ## the 
                                                                                                                                    ## full 
                                                                                                                                    ## description 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## profiling 
                                                                                                                                    ## groups 
                                                                                                                                    ## instead 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## names. 
                                                                                                                                    ## Defaults 
                                                                                                                                    ## to 
                                                                                                                                    ## false.
  var query_402656611 = newJObject()
  add(query_402656611, "maxResults", newJInt(maxResults))
  add(query_402656611, "nextToken", newJString(nextToken))
  add(query_402656611, "includeDescription", newJBool(includeDescription))
  result = call_402656610.call(nil, query_402656611, nil, nil, nil)

var listProfilingGroups* = Call_ListProfilingGroups_402656596(
    name: "listProfilingGroups", meth: HttpMethod.HttpGet,
    host: "codeguru-profiler.amazonaws.com", route: "/profilingGroups",
    validator: validate_ListProfilingGroups_402656597, base: "/",
    makeUrl: url_ListProfilingGroups_402656598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAgentProfile_402656612 = ref object of OpenApiRestCall_402656038
proc url_PostAgentProfile_402656614(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "profilingGroupName" in path,
         "`profilingGroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/profilingGroups/"),
                 (kind: VariableSegment, value: "profilingGroupName"),
                 (kind: ConstantSegment, value: "/agentProfile#Content-Type")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PostAgentProfile_402656613(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   profilingGroupName: JString (required)
                                 ##                     : The name of the profiling group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `profilingGroupName` field"
  var valid_402656615 = path.getOrDefault("profilingGroupName")
  valid_402656615 = validateParameter(valid_402656615, JString, required = true,
                                      default = nil)
  if valid_402656615 != nil:
    section.add "profilingGroupName", valid_402656615
  result.add "path", section
  ## parameters in `query` object:
  ##   profileToken: JString
                                  ##               : Client token for the request.
  section = newJObject()
  var valid_402656616 = query.getOrDefault("profileToken")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "profileToken", valid_402656616
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  ##   Content-Type: JString (required)
                                   ##               : The content type of the agent profile in the payload. Recommended to send the profile gzipped with content-type application/octet-stream. Other accepted values are application/x-amzn-ion and application/json for unzipped Ion and JSON respectively.
  section = newJObject()
  var valid_402656617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Security-Token", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Signature")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Signature", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Algorithm", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Date")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Date", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Credential")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Credential", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656623
  assert header != nil,
         "header argument is necessary due to required `Content-Type` field"
  var valid_402656624 = header.getOrDefault("Content-Type")
  valid_402656624 = validateParameter(valid_402656624, JString, required = true,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "Content-Type", valid_402656624
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656626: Call_PostAgentProfile_402656612;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
                                                                                         ## 
  let valid = call_402656626.validator(path, query, header, formData, body, _)
  let scheme = call_402656626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656626.makeUrl(scheme.get, call_402656626.host, call_402656626.base,
                                   call_402656626.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656626, uri, valid, _)

proc call*(call_402656627: Call_PostAgentProfile_402656612;
           profilingGroupName: string; body: JsonNode; profileToken: string = ""): Recallable =
  ## postAgentProfile
  ## Submit profile collected by an agent belonging to a profiling group for aggregation.
  ##   
                                                                                         ## profilingGroupName: string (required)
                                                                                         ##                     
                                                                                         ## : 
                                                                                         ## The 
                                                                                         ## name 
                                                                                         ## of 
                                                                                         ## the 
                                                                                         ## profiling 
                                                                                         ## group.
  ##   
                                                                                                  ## body: JObject (required)
  ##   
                                                                                                                             ## profileToken: string
                                                                                                                             ##               
                                                                                                                             ## : 
                                                                                                                             ## Client 
                                                                                                                             ## token 
                                                                                                                             ## for 
                                                                                                                             ## the 
                                                                                                                             ## request.
  var path_402656628 = newJObject()
  var query_402656629 = newJObject()
  var body_402656630 = newJObject()
  add(path_402656628, "profilingGroupName", newJString(profilingGroupName))
  if body != nil:
    body_402656630 = body
  add(query_402656629, "profileToken", newJString(profileToken))
  result = call_402656627.call(path_402656628, query_402656629, nil, nil, body_402656630)

var postAgentProfile* = Call_PostAgentProfile_402656612(
    name: "postAgentProfile", meth: HttpMethod.HttpPost,
    host: "codeguru-profiler.amazonaws.com",
    route: "/profilingGroups/{profilingGroupName}/agentProfile#Content-Type",
    validator: validate_PostAgentProfile_402656613, base: "/",
    makeUrl: url_PostAgentProfile_402656614,
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}
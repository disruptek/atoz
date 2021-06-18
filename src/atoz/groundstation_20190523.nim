
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Ground Station
## version: 2019-05-23
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Welcome to the AWS Ground Station API Reference. AWS Ground Station is a fully managed service that enables you to control satellite communications, downlink and process satellite data, and scale your satellite operations efficiently and cost-effectively without having to build or manage your own ground station infrastructure.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/groundstation/
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

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com", "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com", "us-west-2": "groundstation.us-west-2.amazonaws.com", "eu-west-2": "groundstation.eu-west-2.amazonaws.com", "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com", "eu-central-1": "groundstation.eu-central-1.amazonaws.com", "us-east-2": "groundstation.us-east-2.amazonaws.com", "us-east-1": "groundstation.us-east-1.amazonaws.com", "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "groundstation.ap-south-1.amazonaws.com", "eu-north-1": "groundstation.eu-north-1.amazonaws.com", "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com", "us-west-1": "groundstation.us-west-1.amazonaws.com", "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com", "eu-west-3": "groundstation.eu-west-3.amazonaws.com", "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn", "sa-east-1": "groundstation.sa-east-1.amazonaws.com", "eu-west-1": "groundstation.eu-west-1.amazonaws.com", "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com", "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com", "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "groundstation.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "groundstation.ap-southeast-1.amazonaws.com",
      "us-west-2": "groundstation.us-west-2.amazonaws.com",
      "eu-west-2": "groundstation.eu-west-2.amazonaws.com",
      "ap-northeast-3": "groundstation.ap-northeast-3.amazonaws.com",
      "eu-central-1": "groundstation.eu-central-1.amazonaws.com",
      "us-east-2": "groundstation.us-east-2.amazonaws.com",
      "us-east-1": "groundstation.us-east-1.amazonaws.com",
      "cn-northwest-1": "groundstation.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "groundstation.ap-south-1.amazonaws.com",
      "eu-north-1": "groundstation.eu-north-1.amazonaws.com",
      "ap-northeast-2": "groundstation.ap-northeast-2.amazonaws.com",
      "us-west-1": "groundstation.us-west-1.amazonaws.com",
      "us-gov-east-1": "groundstation.us-gov-east-1.amazonaws.com",
      "eu-west-3": "groundstation.eu-west-3.amazonaws.com",
      "cn-north-1": "groundstation.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "groundstation.sa-east-1.amazonaws.com",
      "eu-west-1": "groundstation.eu-west-1.amazonaws.com",
      "us-gov-west-1": "groundstation.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "groundstation.ap-southeast-2.amazonaws.com",
      "ca-central-1": "groundstation.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "groundstation"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_DescribeContact_402656294 = ref object of OpenApiRestCall_402656044
proc url_DescribeContact_402656296(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
                 (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeContact_402656295(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes an existing contact.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
                                 ##            : UUID of a contact.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `contactId` field"
  var valid_402656386 = path.getOrDefault("contactId")
  valid_402656386 = validateParameter(valid_402656386, JString, required = true,
                                      default = nil)
  if valid_402656386 != nil:
    section.add "contactId", valid_402656386
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
  var valid_402656387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Security-Token", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Signature")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Signature", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-Algorithm", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Date")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Date", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Credential")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Credential", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656407: Call_DescribeContact_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes an existing contact.
                                                                                         ## 
  let valid = call_402656407.validator(path, query, header, formData, body, _)
  let scheme = call_402656407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656407.makeUrl(scheme.get, call_402656407.host, call_402656407.base,
                                   call_402656407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656407, uri, valid, _)

proc call*(call_402656456: Call_DescribeContact_402656294; contactId: string): Recallable =
  ## describeContact
  ## Describes an existing contact.
  ##   contactId: string (required)
                                   ##            : UUID of a contact.
  var path_402656457 = newJObject()
  add(path_402656457, "contactId", newJString(contactId))
  result = call_402656456.call(path_402656457, nil, nil, nil, nil)

var describeContact* = Call_DescribeContact_402656294(name: "describeContact",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_DescribeContact_402656295,
    base: "/", makeUrl: url_DescribeContact_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelContact_402656487 = ref object of OpenApiRestCall_402656044
proc url_CancelContact_402656489(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "contactId" in path, "`contactId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/contact/"),
                 (kind: VariableSegment, value: "contactId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CancelContact_402656488(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Cancels a contact with a specified contact ID.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   contactId: JString (required)
                                 ##            : UUID of a contact.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `contactId` field"
  var valid_402656490 = path.getOrDefault("contactId")
  valid_402656490 = validateParameter(valid_402656490, JString, required = true,
                                      default = nil)
  if valid_402656490 != nil:
    section.add "contactId", valid_402656490
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
  var valid_402656491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Security-Token", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Signature")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Signature", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Algorithm", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Date")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Date", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Credential")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Credential", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656498: Call_CancelContact_402656487; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Cancels a contact with a specified contact ID.
                                                                                         ## 
  let valid = call_402656498.validator(path, query, header, formData, body, _)
  let scheme = call_402656498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656498.makeUrl(scheme.get, call_402656498.host, call_402656498.base,
                                   call_402656498.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656498, uri, valid, _)

proc call*(call_402656499: Call_CancelContact_402656487; contactId: string): Recallable =
  ## cancelContact
  ## Cancels a contact with a specified contact ID.
  ##   contactId: string (required)
                                                   ##            : UUID of a contact.
  var path_402656500 = newJObject()
  add(path_402656500, "contactId", newJString(contactId))
  result = call_402656499.call(path_402656500, nil, nil, nil, nil)

var cancelContact* = Call_CancelContact_402656487(name: "cancelContact",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/contact/{contactId}", validator: validate_CancelContact_402656488,
    base: "/", makeUrl: url_CancelContact_402656489,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateConfig_402656516 = ref object of OpenApiRestCall_402656044
proc url_CreateConfig_402656518(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateConfig_402656517(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Security-Token", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Signature")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Signature", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Algorithm", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Date")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Date", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Credential")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Credential", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656525
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

proc call*(call_402656527: Call_CreateConfig_402656516; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
                                                                                         ## 
  let valid = call_402656527.validator(path, query, header, formData, body, _)
  let scheme = call_402656527.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656527.makeUrl(scheme.get, call_402656527.host, call_402656527.base,
                                   call_402656527.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656527, uri, valid, _)

proc call*(call_402656528: Call_CreateConfig_402656516; body: JsonNode): Recallable =
  ## createConfig
  ## <p>Creates a <code>Config</code> with the specified <code>configData</code> parameters.</p> <p>Only one type of <code>configData</code> can be specified.</p>
  ##   
                                                                                                                                                                  ## body: JObject (required)
  var body_402656529 = newJObject()
  if body != nil:
    body_402656529 = body
  result = call_402656528.call(nil, nil, nil, nil, body_402656529)

var createConfig* = Call_CreateConfig_402656516(name: "createConfig",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_CreateConfig_402656517, base: "/",
    makeUrl: url_CreateConfig_402656518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListConfigs_402656501 = ref object of OpenApiRestCall_402656044
proc url_ListConfigs_402656503(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListConfigs_402656502(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of <code>Config</code> objects.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Maximum number of <code>Configs</code> returned.
  ##   
                                                                                                   ## nextToken: JString
                                                                                                   ##            
                                                                                                   ## : 
                                                                                                   ## Next 
                                                                                                   ## token 
                                                                                                   ## returned 
                                                                                                   ## in 
                                                                                                   ## the 
                                                                                                   ## request 
                                                                                                   ## of 
                                                                                                   ## a 
                                                                                                   ## previous 
                                                                                                   ## <code>ListConfigs</code> 
                                                                                                   ## call. 
                                                                                                   ## Used 
                                                                                                   ## to 
                                                                                                   ## get 
                                                                                                   ## the 
                                                                                                   ## next 
                                                                                                   ## page 
                                                                                                   ## of 
                                                                                                   ## results.
  section = newJObject()
  var valid_402656504 = query.getOrDefault("maxResults")
  valid_402656504 = validateParameter(valid_402656504, JInt, required = false,
                                      default = nil)
  if valid_402656504 != nil:
    section.add "maxResults", valid_402656504
  var valid_402656505 = query.getOrDefault("nextToken")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "nextToken", valid_402656505
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
  var valid_402656506 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Security-Token", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Signature")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Signature", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Algorithm", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Date")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Date", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Credential")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Credential", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656513: Call_ListConfigs_402656501; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>Config</code> objects.
                                                                                         ## 
  let valid = call_402656513.validator(path, query, header, formData, body, _)
  let scheme = call_402656513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656513.makeUrl(scheme.get, call_402656513.host, call_402656513.base,
                                   call_402656513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656513, uri, valid, _)

proc call*(call_402656514: Call_ListConfigs_402656501; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listConfigs
  ## Returns a list of <code>Config</code> objects.
  ##   maxResults: int
                                                   ##             : Maximum number of <code>Configs</code> returned.
  ##   
                                                                                                                    ## nextToken: string
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## Next 
                                                                                                                    ## token 
                                                                                                                    ## returned 
                                                                                                                    ## in 
                                                                                                                    ## the 
                                                                                                                    ## request 
                                                                                                                    ## of 
                                                                                                                    ## a 
                                                                                                                    ## previous 
                                                                                                                    ## <code>ListConfigs</code> 
                                                                                                                    ## call. 
                                                                                                                    ## Used 
                                                                                                                    ## to 
                                                                                                                    ## get 
                                                                                                                    ## the 
                                                                                                                    ## next 
                                                                                                                    ## page 
                                                                                                                    ## of 
                                                                                                                    ## results.
  var query_402656515 = newJObject()
  add(query_402656515, "maxResults", newJInt(maxResults))
  add(query_402656515, "nextToken", newJString(nextToken))
  result = call_402656514.call(nil, query_402656515, nil, nil, nil)

var listConfigs* = Call_ListConfigs_402656501(name: "listConfigs",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/config", validator: validate_ListConfigs_402656502, base: "/",
    makeUrl: url_ListConfigs_402656503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDataflowEndpointGroup_402656545 = ref object of OpenApiRestCall_402656044
proc url_CreateDataflowEndpointGroup_402656547(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDataflowEndpointGroup_402656546(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656548 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Security-Token", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Signature")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Signature", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Algorithm", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Date")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Date", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Credential")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Credential", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656554
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

proc call*(call_402656556: Call_CreateDataflowEndpointGroup_402656545;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
                                                                                         ## 
  let valid = call_402656556.validator(path, query, header, formData, body, _)
  let scheme = call_402656556.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656556.makeUrl(scheme.get, call_402656556.host, call_402656556.base,
                                   call_402656556.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656556, uri, valid, _)

proc call*(call_402656557: Call_CreateDataflowEndpointGroup_402656545;
           body: JsonNode): Recallable =
  ## createDataflowEndpointGroup
  ## <p>Creates a <code>DataflowEndpoint</code> group containing the specified list of <code>DataflowEndpoint</code> objects.</p> <p>The <code>name</code> field in each endpoint is used in your mission profile <code>DataflowEndpointConfig</code> to specify which endpoints to use during a contact.</p> <p>When a contact uses multiple <code>DataflowEndpointConfig</code> objects, each <code>Config</code> must match a <code>DataflowEndpoint</code> in the same group.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656558 = newJObject()
  if body != nil:
    body_402656558 = body
  result = call_402656557.call(nil, nil, nil, nil, body_402656558)

var createDataflowEndpointGroup* = Call_CreateDataflowEndpointGroup_402656545(
    name: "createDataflowEndpointGroup", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_CreateDataflowEndpointGroup_402656546, base: "/",
    makeUrl: url_CreateDataflowEndpointGroup_402656547,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDataflowEndpointGroups_402656530 = ref object of OpenApiRestCall_402656044
proc url_ListDataflowEndpointGroups_402656532(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDataflowEndpointGroups_402656531(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Maximum number of dataflow endpoint groups returned.
  ##   
                                                                                                       ## nextToken: JString
                                                                                                       ##            
                                                                                                       ## : 
                                                                                                       ## Next 
                                                                                                       ## token 
                                                                                                       ## returned 
                                                                                                       ## in 
                                                                                                       ## the 
                                                                                                       ## request 
                                                                                                       ## of 
                                                                                                       ## a 
                                                                                                       ## previous 
                                                                                                       ## <code>ListDataflowEndpointGroups</code> 
                                                                                                       ## call. 
                                                                                                       ## Used 
                                                                                                       ## to 
                                                                                                       ## get 
                                                                                                       ## the 
                                                                                                       ## next 
                                                                                                       ## page 
                                                                                                       ## of 
                                                                                                       ## results.
  section = newJObject()
  var valid_402656533 = query.getOrDefault("maxResults")
  valid_402656533 = validateParameter(valid_402656533, JInt, required = false,
                                      default = nil)
  if valid_402656533 != nil:
    section.add "maxResults", valid_402656533
  var valid_402656534 = query.getOrDefault("nextToken")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "nextToken", valid_402656534
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
  var valid_402656535 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Security-Token", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Signature")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Signature", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Algorithm", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Date")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Date", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Credential")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Credential", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656541
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656542: Call_ListDataflowEndpointGroups_402656530;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of <code>DataflowEndpoint</code> groups.
                                                                                         ## 
  let valid = call_402656542.validator(path, query, header, formData, body, _)
  let scheme = call_402656542.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656542.makeUrl(scheme.get, call_402656542.host, call_402656542.base,
                                   call_402656542.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656542, uri, valid, _)

proc call*(call_402656543: Call_ListDataflowEndpointGroups_402656530;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listDataflowEndpointGroups
  ## Returns a list of <code>DataflowEndpoint</code> groups.
  ##   maxResults: int
                                                            ##             : Maximum number of dataflow endpoint groups returned.
  ##   
                                                                                                                                 ## nextToken: string
                                                                                                                                 ##            
                                                                                                                                 ## : 
                                                                                                                                 ## Next 
                                                                                                                                 ## token 
                                                                                                                                 ## returned 
                                                                                                                                 ## in 
                                                                                                                                 ## the 
                                                                                                                                 ## request 
                                                                                                                                 ## of 
                                                                                                                                 ## a 
                                                                                                                                 ## previous 
                                                                                                                                 ## <code>ListDataflowEndpointGroups</code> 
                                                                                                                                 ## call. 
                                                                                                                                 ## Used 
                                                                                                                                 ## to 
                                                                                                                                 ## get 
                                                                                                                                 ## the 
                                                                                                                                 ## next 
                                                                                                                                 ## page 
                                                                                                                                 ## of 
                                                                                                                                 ## results.
  var query_402656544 = newJObject()
  add(query_402656544, "maxResults", newJInt(maxResults))
  add(query_402656544, "nextToken", newJString(nextToken))
  result = call_402656543.call(nil, query_402656544, nil, nil, nil)

var listDataflowEndpointGroups* = Call_ListDataflowEndpointGroups_402656530(
    name: "listDataflowEndpointGroups", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/dataflowEndpointGroup",
    validator: validate_ListDataflowEndpointGroups_402656531, base: "/",
    makeUrl: url_ListDataflowEndpointGroups_402656532,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMissionProfile_402656574 = ref object of OpenApiRestCall_402656044
proc url_CreateMissionProfile_402656576(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMissionProfile_402656575(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656577 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Security-Token", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-Signature")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-Signature", valid_402656578
  var valid_402656579 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Algorithm", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Date")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Date", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Credential")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Credential", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656583
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

proc call*(call_402656585: Call_CreateMissionProfile_402656574;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
                                                                                         ## 
  let valid = call_402656585.validator(path, query, header, formData, body, _)
  let scheme = call_402656585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656585.makeUrl(scheme.get, call_402656585.host, call_402656585.base,
                                   call_402656585.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656585, uri, valid, _)

proc call*(call_402656586: Call_CreateMissionProfile_402656574; body: JsonNode): Recallable =
  ## createMissionProfile
  ## <p>Creates a mission profile.</p> <p> <code>dataflowEdges</code> is a list of lists of strings. Each lower level list of strings has two elements: a <i>from</i> ARN and a <i>to</i> ARN.</p>
  ##   
                                                                                                                                                                                                  ## body: JObject (required)
  var body_402656587 = newJObject()
  if body != nil:
    body_402656587 = body
  result = call_402656586.call(nil, nil, nil, nil, body_402656587)

var createMissionProfile* = Call_CreateMissionProfile_402656574(
    name: "createMissionProfile", meth: HttpMethod.HttpPost,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_CreateMissionProfile_402656575, base: "/",
    makeUrl: url_CreateMissionProfile_402656576,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMissionProfiles_402656559 = ref object of OpenApiRestCall_402656044
proc url_ListMissionProfiles_402656561(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMissionProfiles_402656560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of mission profiles.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Maximum number of mission profiles returned.
  ##   
                                                                                               ## nextToken: JString
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## Next 
                                                                                               ## token 
                                                                                               ## returned 
                                                                                               ## in 
                                                                                               ## the 
                                                                                               ## request 
                                                                                               ## of 
                                                                                               ## a 
                                                                                               ## previous 
                                                                                               ## <code>ListMissionProfiles</code> 
                                                                                               ## call. 
                                                                                               ## Used 
                                                                                               ## to 
                                                                                               ## get 
                                                                                               ## the 
                                                                                               ## next 
                                                                                               ## page 
                                                                                               ## of 
                                                                                               ## results.
  section = newJObject()
  var valid_402656562 = query.getOrDefault("maxResults")
  valid_402656562 = validateParameter(valid_402656562, JInt, required = false,
                                      default = nil)
  if valid_402656562 != nil:
    section.add "maxResults", valid_402656562
  var valid_402656563 = query.getOrDefault("nextToken")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "nextToken", valid_402656563
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
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656571: Call_ListMissionProfiles_402656559;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of mission profiles.
                                                                                         ## 
  let valid = call_402656571.validator(path, query, header, formData, body, _)
  let scheme = call_402656571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656571.makeUrl(scheme.get, call_402656571.host, call_402656571.base,
                                   call_402656571.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656571, uri, valid, _)

proc call*(call_402656572: Call_ListMissionProfiles_402656559;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listMissionProfiles
  ## Returns a list of mission profiles.
  ##   maxResults: int
                                        ##             : Maximum number of mission profiles returned.
  ##   
                                                                                                     ## nextToken: string
                                                                                                     ##            
                                                                                                     ## : 
                                                                                                     ## Next 
                                                                                                     ## token 
                                                                                                     ## returned 
                                                                                                     ## in 
                                                                                                     ## the 
                                                                                                     ## request 
                                                                                                     ## of 
                                                                                                     ## a 
                                                                                                     ## previous 
                                                                                                     ## <code>ListMissionProfiles</code> 
                                                                                                     ## call. 
                                                                                                     ## Used 
                                                                                                     ## to 
                                                                                                     ## get 
                                                                                                     ## the 
                                                                                                     ## next 
                                                                                                     ## page 
                                                                                                     ## of 
                                                                                                     ## results.
  var query_402656573 = newJObject()
  add(query_402656573, "maxResults", newJInt(maxResults))
  add(query_402656573, "nextToken", newJString(nextToken))
  result = call_402656572.call(nil, query_402656573, nil, nil, nil)

var listMissionProfiles* = Call_ListMissionProfiles_402656559(
    name: "listMissionProfiles", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/missionprofile",
    validator: validate_ListMissionProfiles_402656560, base: "/",
    makeUrl: url_ListMissionProfiles_402656561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateConfig_402656615 = ref object of OpenApiRestCall_402656044
proc url_UpdateConfig_402656617(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
                 (kind: VariableSegment, value: "configType"),
                 (kind: ConstantSegment, value: "/"),
                 (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateConfig_402656616(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
                                 ##           : UUID of a <code>Config</code>.
  ##   
                                                                              ## configType: JString (required)
                                                                              ##             
                                                                              ## : 
                                                                              ## Type 
                                                                              ## of 
                                                                              ## a 
                                                                              ## <code>Config</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configId` field"
  var valid_402656618 = path.getOrDefault("configId")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "configId", valid_402656618
  var valid_402656619 = path.getOrDefault("configType")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = newJString("antenna-downlink"))
  if valid_402656619 != nil:
    section.add "configType", valid_402656619
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
  var valid_402656620 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Security-Token", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Signature")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Signature", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656622
  var valid_402656623 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Algorithm", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Date")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Date", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Credential")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Credential", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656626
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

proc call*(call_402656628: Call_UpdateConfig_402656615; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
                                                                                         ## 
  let valid = call_402656628.validator(path, query, header, formData, body, _)
  let scheme = call_402656628.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656628.makeUrl(scheme.get, call_402656628.host, call_402656628.base,
                                   call_402656628.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656628, uri, valid, _)

proc call*(call_402656629: Call_UpdateConfig_402656615; configId: string;
           body: JsonNode; configType: string = "antenna-downlink"): Recallable =
  ## updateConfig
  ## <p>Updates the <code>Config</code> used when scheduling contacts.</p> <p>Updating a <code>Config</code> will not update the execution parameters for existing future contacts scheduled with this <code>Config</code>.</p>
  ##   
                                                                                                                                                                                                                               ## configId: string (required)
                                                                                                                                                                                                                               ##           
                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                               ## UUID 
                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                               ## a 
                                                                                                                                                                                                                               ## <code>Config</code>.
  ##   
                                                                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                 ## configType: string (required)
                                                                                                                                                                                                                                                                                 ##             
                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                 ## Type 
                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                 ## a 
                                                                                                                                                                                                                                                                                 ## <code>Config</code>.
  var path_402656630 = newJObject()
  var body_402656631 = newJObject()
  add(path_402656630, "configId", newJString(configId))
  if body != nil:
    body_402656631 = body
  add(path_402656630, "configType", newJString(configType))
  result = call_402656629.call(path_402656630, nil, nil, nil, body_402656631)

var updateConfig* = Call_UpdateConfig_402656615(name: "updateConfig",
    meth: HttpMethod.HttpPut, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_UpdateConfig_402656616,
    base: "/", makeUrl: url_UpdateConfig_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConfig_402656588 = ref object of OpenApiRestCall_402656044
proc url_GetConfig_402656590(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
                 (kind: VariableSegment, value: "configType"),
                 (kind: ConstantSegment, value: "/"),
                 (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetConfig_402656589(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
                                 ##           : UUID of a <code>Config</code>.
  ##   
                                                                              ## configType: JString (required)
                                                                              ##             
                                                                              ## : 
                                                                              ## Type 
                                                                              ## of 
                                                                              ## a 
                                                                              ## <code>Config</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configId` field"
  var valid_402656591 = path.getOrDefault("configId")
  valid_402656591 = validateParameter(valid_402656591, JString, required = true,
                                      default = nil)
  if valid_402656591 != nil:
    section.add "configId", valid_402656591
  var valid_402656604 = path.getOrDefault("configType")
  valid_402656604 = validateParameter(valid_402656604, JString, required = true,
                                      default = newJString("antenna-downlink"))
  if valid_402656604 != nil:
    section.add "configType", valid_402656604
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
  var valid_402656605 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Security-Token", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Signature")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Signature", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656607
  var valid_402656608 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656608 = validateParameter(valid_402656608, JString,
                                      required = false, default = nil)
  if valid_402656608 != nil:
    section.add "X-Amz-Algorithm", valid_402656608
  var valid_402656609 = header.getOrDefault("X-Amz-Date")
  valid_402656609 = validateParameter(valid_402656609, JString,
                                      required = false, default = nil)
  if valid_402656609 != nil:
    section.add "X-Amz-Date", valid_402656609
  var valid_402656610 = header.getOrDefault("X-Amz-Credential")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Credential", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656611
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656612: Call_GetConfig_402656588; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
                                                                                         ## 
  let valid = call_402656612.validator(path, query, header, formData, body, _)
  let scheme = call_402656612.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656612.makeUrl(scheme.get, call_402656612.host, call_402656612.base,
                                   call_402656612.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656612, uri, valid, _)

proc call*(call_402656613: Call_GetConfig_402656588; configId: string;
           configType: string = "antenna-downlink"): Recallable =
  ## getConfig
  ## <p>Returns <code>Config</code> information.</p> <p>Only one <code>Config</code> response can be returned.</p>
  ##   
                                                                                                                  ## configId: string (required)
                                                                                                                  ##           
                                                                                                                  ## : 
                                                                                                                  ## UUID 
                                                                                                                  ## of 
                                                                                                                  ## a 
                                                                                                                  ## <code>Config</code>.
  ##   
                                                                                                                                         ## configType: string (required)
                                                                                                                                         ##             
                                                                                                                                         ## : 
                                                                                                                                         ## Type 
                                                                                                                                         ## of 
                                                                                                                                         ## a 
                                                                                                                                         ## <code>Config</code>.
  var path_402656614 = newJObject()
  add(path_402656614, "configId", newJString(configId))
  add(path_402656614, "configType", newJString(configType))
  result = call_402656613.call(path_402656614, nil, nil, nil, nil)

var getConfig* = Call_GetConfig_402656588(name: "getConfig",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_GetConfig_402656589,
    base: "/", makeUrl: url_GetConfig_402656590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteConfig_402656632 = ref object of OpenApiRestCall_402656044
proc url_DeleteConfig_402656634(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "configType" in path, "`configType` is a required path parameter"
  assert "configId" in path, "`configId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/config/"),
                 (kind: VariableSegment, value: "configType"),
                 (kind: ConstantSegment, value: "/"),
                 (kind: VariableSegment, value: "configId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteConfig_402656633(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a <code>Config</code>.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   configId: JString (required)
                                 ##           : UUID of a <code>Config</code>.
  ##   
                                                                              ## configType: JString (required)
                                                                              ##             
                                                                              ## : 
                                                                              ## Type 
                                                                              ## of 
                                                                              ## a 
                                                                              ## <code>Config</code>.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `configId` field"
  var valid_402656635 = path.getOrDefault("configId")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "configId", valid_402656635
  var valid_402656636 = path.getOrDefault("configType")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = newJString("antenna-downlink"))
  if valid_402656636 != nil:
    section.add "configType", valid_402656636
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
  var valid_402656637 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-Security-Token", valid_402656637
  var valid_402656638 = header.getOrDefault("X-Amz-Signature")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Signature", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Algorithm", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Date")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Date", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Credential")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Credential", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656643
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656644: Call_DeleteConfig_402656632; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a <code>Config</code>.
                                                                                         ## 
  let valid = call_402656644.validator(path, query, header, formData, body, _)
  let scheme = call_402656644.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656644.makeUrl(scheme.get, call_402656644.host, call_402656644.base,
                                   call_402656644.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656644, uri, valid, _)

proc call*(call_402656645: Call_DeleteConfig_402656632; configId: string;
           configType: string = "antenna-downlink"): Recallable =
  ## deleteConfig
  ## Deletes a <code>Config</code>.
  ##   configId: string (required)
                                   ##           : UUID of a <code>Config</code>.
  ##   
                                                                                ## configType: string (required)
                                                                                ##             
                                                                                ## : 
                                                                                ## Type 
                                                                                ## of 
                                                                                ## a 
                                                                                ## <code>Config</code>.
  var path_402656646 = newJObject()
  add(path_402656646, "configId", newJString(configId))
  add(path_402656646, "configType", newJString(configType))
  result = call_402656645.call(path_402656646, nil, nil, nil, nil)

var deleteConfig* = Call_DeleteConfig_402656632(name: "deleteConfig",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/config/{configType}/{configId}", validator: validate_DeleteConfig_402656633,
    base: "/", makeUrl: url_DeleteConfig_402656634,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDataflowEndpointGroup_402656647 = ref object of OpenApiRestCall_402656044
proc url_GetDataflowEndpointGroup_402656649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
         "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
                 (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetDataflowEndpointGroup_402656648(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns the dataflow endpoint group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
                                 ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_402656650 = path.getOrDefault("dataflowEndpointGroupId")
  valid_402656650 = validateParameter(valid_402656650, JString, required = true,
                                      default = nil)
  if valid_402656650 != nil:
    section.add "dataflowEndpointGroupId", valid_402656650
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
  var valid_402656651 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Security-Token", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-Signature")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-Signature", valid_402656652
  var valid_402656653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656653 = validateParameter(valid_402656653, JString,
                                      required = false, default = nil)
  if valid_402656653 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656653
  var valid_402656654 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656654 = validateParameter(valid_402656654, JString,
                                      required = false, default = nil)
  if valid_402656654 != nil:
    section.add "X-Amz-Algorithm", valid_402656654
  var valid_402656655 = header.getOrDefault("X-Amz-Date")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Date", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Credential")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Credential", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656657
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656658: Call_GetDataflowEndpointGroup_402656647;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the dataflow endpoint group.
                                                                                         ## 
  let valid = call_402656658.validator(path, query, header, formData, body, _)
  let scheme = call_402656658.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656658.makeUrl(scheme.get, call_402656658.host, call_402656658.base,
                                   call_402656658.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656658, uri, valid, _)

proc call*(call_402656659: Call_GetDataflowEndpointGroup_402656647;
           dataflowEndpointGroupId: string): Recallable =
  ## getDataflowEndpointGroup
  ## Returns the dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
                                         ##                          : UUID of a dataflow endpoint group.
  var path_402656660 = newJObject()
  add(path_402656660, "dataflowEndpointGroupId",
      newJString(dataflowEndpointGroupId))
  result = call_402656659.call(path_402656660, nil, nil, nil, nil)

var getDataflowEndpointGroup* = Call_GetDataflowEndpointGroup_402656647(
    name: "getDataflowEndpointGroup", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_GetDataflowEndpointGroup_402656648, base: "/",
    makeUrl: url_GetDataflowEndpointGroup_402656649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDataflowEndpointGroup_402656661 = ref object of OpenApiRestCall_402656044
proc url_DeleteDataflowEndpointGroup_402656663(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "dataflowEndpointGroupId" in path,
         "`dataflowEndpointGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/dataflowEndpointGroup/"),
                 (kind: VariableSegment, value: "dataflowEndpointGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteDataflowEndpointGroup_402656662(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Deletes a dataflow endpoint group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   dataflowEndpointGroupId: JString (required)
                                 ##                          : UUID of a dataflow endpoint group.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `dataflowEndpointGroupId` field"
  var valid_402656664 = path.getOrDefault("dataflowEndpointGroupId")
  valid_402656664 = validateParameter(valid_402656664, JString, required = true,
                                      default = nil)
  if valid_402656664 != nil:
    section.add "dataflowEndpointGroupId", valid_402656664
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
  var valid_402656665 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Security-Token", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Signature")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Signature", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-Algorithm", valid_402656668
  var valid_402656669 = header.getOrDefault("X-Amz-Date")
  valid_402656669 = validateParameter(valid_402656669, JString,
                                      required = false, default = nil)
  if valid_402656669 != nil:
    section.add "X-Amz-Date", valid_402656669
  var valid_402656670 = header.getOrDefault("X-Amz-Credential")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "X-Amz-Credential", valid_402656670
  var valid_402656671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656671 = validateParameter(valid_402656671, JString,
                                      required = false, default = nil)
  if valid_402656671 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656671
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656672: Call_DeleteDataflowEndpointGroup_402656661;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a dataflow endpoint group.
                                                                                         ## 
  let valid = call_402656672.validator(path, query, header, formData, body, _)
  let scheme = call_402656672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656672.makeUrl(scheme.get, call_402656672.host, call_402656672.base,
                                   call_402656672.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656672, uri, valid, _)

proc call*(call_402656673: Call_DeleteDataflowEndpointGroup_402656661;
           dataflowEndpointGroupId: string): Recallable =
  ## deleteDataflowEndpointGroup
  ## Deletes a dataflow endpoint group.
  ##   dataflowEndpointGroupId: string (required)
                                       ##                          : UUID of a dataflow endpoint group.
  var path_402656674 = newJObject()
  add(path_402656674, "dataflowEndpointGroupId",
      newJString(dataflowEndpointGroupId))
  result = call_402656673.call(path_402656674, nil, nil, nil, nil)

var deleteDataflowEndpointGroup* = Call_DeleteDataflowEndpointGroup_402656661(
    name: "deleteDataflowEndpointGroup", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/dataflowEndpointGroup/{dataflowEndpointGroupId}",
    validator: validate_DeleteDataflowEndpointGroup_402656662, base: "/",
    makeUrl: url_DeleteDataflowEndpointGroup_402656663,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMissionProfile_402656689 = ref object of OpenApiRestCall_402656044
proc url_UpdateMissionProfile_402656691(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
         "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
                 (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMissionProfile_402656690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
                                 ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `missionProfileId` field"
  var valid_402656692 = path.getOrDefault("missionProfileId")
  valid_402656692 = validateParameter(valid_402656692, JString, required = true,
                                      default = nil)
  if valid_402656692 != nil:
    section.add "missionProfileId", valid_402656692
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
  var valid_402656693 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Security-Token", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Signature")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Signature", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Algorithm", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-Date")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-Date", valid_402656697
  var valid_402656698 = header.getOrDefault("X-Amz-Credential")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "X-Amz-Credential", valid_402656698
  var valid_402656699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656699 = validateParameter(valid_402656699, JString,
                                      required = false, default = nil)
  if valid_402656699 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656699
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

proc call*(call_402656701: Call_UpdateMissionProfile_402656689;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
                                                                                         ## 
  let valid = call_402656701.validator(path, query, header, formData, body, _)
  let scheme = call_402656701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656701.makeUrl(scheme.get, call_402656701.host, call_402656701.base,
                                   call_402656701.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656701, uri, valid, _)

proc call*(call_402656702: Call_UpdateMissionProfile_402656689;
           missionProfileId: string; body: JsonNode): Recallable =
  ## updateMissionProfile
  ## <p>Updates a mission profile.</p> <p>Updating a mission profile will not update the execution parameters for existing future contacts.</p>
  ##   
                                                                                                                                               ## missionProfileId: string (required)
                                                                                                                                               ##                   
                                                                                                                                               ## : 
                                                                                                                                               ## UUID 
                                                                                                                                               ## of 
                                                                                                                                               ## a 
                                                                                                                                               ## mission 
                                                                                                                                               ## profile.
  ##   
                                                                                                                                                          ## body: JObject (required)
  var path_402656703 = newJObject()
  var body_402656704 = newJObject()
  add(path_402656703, "missionProfileId", newJString(missionProfileId))
  if body != nil:
    body_402656704 = body
  result = call_402656702.call(path_402656703, nil, nil, nil, body_402656704)

var updateMissionProfile* = Call_UpdateMissionProfile_402656689(
    name: "updateMissionProfile", meth: HttpMethod.HttpPut,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_UpdateMissionProfile_402656690, base: "/",
    makeUrl: url_UpdateMissionProfile_402656691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMissionProfile_402656675 = ref object of OpenApiRestCall_402656044
proc url_GetMissionProfile_402656677(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
         "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
                 (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetMissionProfile_402656676(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a mission profile.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
                                 ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `missionProfileId` field"
  var valid_402656678 = path.getOrDefault("missionProfileId")
  valid_402656678 = validateParameter(valid_402656678, JString, required = true,
                                      default = nil)
  if valid_402656678 != nil:
    section.add "missionProfileId", valid_402656678
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
  var valid_402656679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Security-Token", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Signature")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Signature", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Algorithm", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-Date")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-Date", valid_402656683
  var valid_402656684 = header.getOrDefault("X-Amz-Credential")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "X-Amz-Credential", valid_402656684
  var valid_402656685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656685 = validateParameter(valid_402656685, JString,
                                      required = false, default = nil)
  if valid_402656685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656686: Call_GetMissionProfile_402656675;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a mission profile.
                                                                                         ## 
  let valid = call_402656686.validator(path, query, header, formData, body, _)
  let scheme = call_402656686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656686.makeUrl(scheme.get, call_402656686.host, call_402656686.base,
                                   call_402656686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656686, uri, valid, _)

proc call*(call_402656687: Call_GetMissionProfile_402656675;
           missionProfileId: string): Recallable =
  ## getMissionProfile
  ## Returns a mission profile.
  ##   missionProfileId: string (required)
                               ##                   : UUID of a mission profile.
  var path_402656688 = newJObject()
  add(path_402656688, "missionProfileId", newJString(missionProfileId))
  result = call_402656687.call(path_402656688, nil, nil, nil, nil)

var getMissionProfile* = Call_GetMissionProfile_402656675(
    name: "getMissionProfile", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_GetMissionProfile_402656676, base: "/",
    makeUrl: url_GetMissionProfile_402656677,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMissionProfile_402656705 = ref object of OpenApiRestCall_402656044
proc url_DeleteMissionProfile_402656707(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "missionProfileId" in path,
         "`missionProfileId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/missionprofile/"),
                 (kind: VariableSegment, value: "missionProfileId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMissionProfile_402656706(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a mission profile.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   missionProfileId: JString (required)
                                 ##                   : UUID of a mission profile.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `missionProfileId` field"
  var valid_402656708 = path.getOrDefault("missionProfileId")
  valid_402656708 = validateParameter(valid_402656708, JString, required = true,
                                      default = nil)
  if valid_402656708 != nil:
    section.add "missionProfileId", valid_402656708
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
  var valid_402656709 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Security-Token", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-Signature")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Signature", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Algorithm", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Date")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Date", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Credential")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Credential", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656715
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656716: Call_DeleteMissionProfile_402656705;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a mission profile.
                                                                                         ## 
  let valid = call_402656716.validator(path, query, header, formData, body, _)
  let scheme = call_402656716.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656716.makeUrl(scheme.get, call_402656716.host, call_402656716.base,
                                   call_402656716.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656716, uri, valid, _)

proc call*(call_402656717: Call_DeleteMissionProfile_402656705;
           missionProfileId: string): Recallable =
  ## deleteMissionProfile
  ## Deletes a mission profile.
  ##   missionProfileId: string (required)
                               ##                   : UUID of a mission profile.
  var path_402656718 = newJObject()
  add(path_402656718, "missionProfileId", newJString(missionProfileId))
  result = call_402656717.call(path_402656718, nil, nil, nil, nil)

var deleteMissionProfile* = Call_DeleteMissionProfile_402656705(
    name: "deleteMissionProfile", meth: HttpMethod.HttpDelete,
    host: "groundstation.amazonaws.com",
    route: "/missionprofile/{missionProfileId}",
    validator: validate_DeleteMissionProfile_402656706, base: "/",
    makeUrl: url_DeleteMissionProfile_402656707,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMinuteUsage_402656719 = ref object of OpenApiRestCall_402656044
proc url_GetMinuteUsage_402656721(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMinuteUsage_402656720(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns the number of minutes used by account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656722 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Security-Token", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Signature")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Signature", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Algorithm", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Date")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Date", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Credential")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Credential", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656728
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

proc call*(call_402656730: Call_GetMinuteUsage_402656719; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns the number of minutes used by account.
                                                                                         ## 
  let valid = call_402656730.validator(path, query, header, formData, body, _)
  let scheme = call_402656730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656730.makeUrl(scheme.get, call_402656730.host, call_402656730.base,
                                   call_402656730.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656730, uri, valid, _)

proc call*(call_402656731: Call_GetMinuteUsage_402656719; body: JsonNode): Recallable =
  ## getMinuteUsage
  ## Returns the number of minutes used by account.
  ##   body: JObject (required)
  var body_402656732 = newJObject()
  if body != nil:
    body_402656732 = body
  result = call_402656731.call(nil, nil, nil, nil, body_402656732)

var getMinuteUsage* = Call_GetMinuteUsage_402656719(name: "getMinuteUsage",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/minute-usage", validator: validate_GetMinuteUsage_402656720,
    base: "/", makeUrl: url_GetMinuteUsage_402656721,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSatellite_402656733 = ref object of OpenApiRestCall_402656044
proc url_GetSatellite_402656735(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "satelliteId" in path, "`satelliteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/satellite/"),
                 (kind: VariableSegment, value: "satelliteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetSatellite_402656734(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a satellite.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   satelliteId: JString (required)
                                 ##              : UUID of a satellite.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `satelliteId` field"
  var valid_402656736 = path.getOrDefault("satelliteId")
  valid_402656736 = validateParameter(valid_402656736, JString, required = true,
                                      default = nil)
  if valid_402656736 != nil:
    section.add "satelliteId", valid_402656736
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
  var valid_402656737 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Security-Token", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Signature")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Signature", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Algorithm", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Date")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Date", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Credential")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Credential", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656743
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656744: Call_GetSatellite_402656733; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a satellite.
                                                                                         ## 
  let valid = call_402656744.validator(path, query, header, formData, body, _)
  let scheme = call_402656744.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656744.makeUrl(scheme.get, call_402656744.host, call_402656744.base,
                                   call_402656744.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656744, uri, valid, _)

proc call*(call_402656745: Call_GetSatellite_402656733; satelliteId: string): Recallable =
  ## getSatellite
  ## Returns a satellite.
  ##   satelliteId: string (required)
                         ##              : UUID of a satellite.
  var path_402656746 = newJObject()
  add(path_402656746, "satelliteId", newJString(satelliteId))
  result = call_402656745.call(path_402656746, nil, nil, nil, nil)

var getSatellite* = Call_GetSatellite_402656733(name: "getSatellite",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite/{satelliteId}", validator: validate_GetSatellite_402656734,
    base: "/", makeUrl: url_GetSatellite_402656735,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListContacts_402656747 = ref object of OpenApiRestCall_402656044
proc url_ListContacts_402656749(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListContacts_402656748(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
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
  var valid_402656750 = query.getOrDefault("maxResults")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "maxResults", valid_402656750
  var valid_402656751 = query.getOrDefault("nextToken")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "nextToken", valid_402656751
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
  var valid_402656752 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Security-Token", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Signature")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Signature", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656754
  var valid_402656755 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "X-Amz-Algorithm", valid_402656755
  var valid_402656756 = header.getOrDefault("X-Amz-Date")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Date", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Credential")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Credential", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656758
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

proc call*(call_402656760: Call_ListContacts_402656747; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
                                                                                         ## 
  let valid = call_402656760.validator(path, query, header, formData, body, _)
  let scheme = call_402656760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656760.makeUrl(scheme.get, call_402656760.host, call_402656760.base,
                                   call_402656760.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656760, uri, valid, _)

proc call*(call_402656761: Call_ListContacts_402656747; body: JsonNode;
           maxResults: string = ""; nextToken: string = ""): Recallable =
  ## listContacts
  ## <p>Returns a list of contacts.</p> <p>If <code>statusList</code> contains AVAILABLE, the request must include <code>groundStation</code>, <code>missionprofileArn</code>, and <code>satelliteArn</code>. </p>
  ##   
                                                                                                                                                                                                                  ## maxResults: string
                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                          ## nextToken: string
                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                          ## token
  ##   
                                                                                                                                                                                                                                  ## body: JObject (required)
  var query_402656762 = newJObject()
  var body_402656763 = newJObject()
  add(query_402656762, "maxResults", newJString(maxResults))
  add(query_402656762, "nextToken", newJString(nextToken))
  if body != nil:
    body_402656763 = body
  result = call_402656761.call(nil, query_402656762, nil, nil, body_402656763)

var listContacts* = Call_ListContacts_402656747(name: "listContacts",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contacts", validator: validate_ListContacts_402656748, base: "/",
    makeUrl: url_ListContacts_402656749, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListGroundStations_402656764 = ref object of OpenApiRestCall_402656044
proc url_ListGroundStations_402656766(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListGroundStations_402656765(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of ground stations. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Maximum number of ground stations returned.
  ##   
                                                                                              ## nextToken: JString
                                                                                              ##            
                                                                                              ## : 
                                                                                              ## Next 
                                                                                              ## token 
                                                                                              ## that 
                                                                                              ## can 
                                                                                              ## be 
                                                                                              ## supplied 
                                                                                              ## in 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## call 
                                                                                              ## to 
                                                                                              ## get 
                                                                                              ## the 
                                                                                              ## next 
                                                                                              ## page 
                                                                                              ## of 
                                                                                              ## ground 
                                                                                              ## stations.
  ##   
                                                                                                          ## satelliteId: JString
                                                                                                          ##              
                                                                                                          ## : 
                                                                                                          ## Satellite 
                                                                                                          ## ID 
                                                                                                          ## to 
                                                                                                          ## retrieve 
                                                                                                          ## on-boarded 
                                                                                                          ## ground 
                                                                                                          ## stations.
  section = newJObject()
  var valid_402656767 = query.getOrDefault("maxResults")
  valid_402656767 = validateParameter(valid_402656767, JInt, required = false,
                                      default = nil)
  if valid_402656767 != nil:
    section.add "maxResults", valid_402656767
  var valid_402656768 = query.getOrDefault("nextToken")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "nextToken", valid_402656768
  var valid_402656769 = query.getOrDefault("satelliteId")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "satelliteId", valid_402656769
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
  var valid_402656770 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "X-Amz-Security-Token", valid_402656770
  var valid_402656771 = header.getOrDefault("X-Amz-Signature")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Signature", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Algorithm", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Date")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Date", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Credential")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Credential", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656777: Call_ListGroundStations_402656764;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of ground stations. 
                                                                                         ## 
  let valid = call_402656777.validator(path, query, header, formData, body, _)
  let scheme = call_402656777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656777.makeUrl(scheme.get, call_402656777.host, call_402656777.base,
                                   call_402656777.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656777, uri, valid, _)

proc call*(call_402656778: Call_ListGroundStations_402656764;
           maxResults: int = 0; nextToken: string = ""; satelliteId: string = ""): Recallable =
  ## listGroundStations
  ## Returns a list of ground stations. 
  ##   maxResults: int
                                        ##             : Maximum number of ground stations returned.
  ##   
                                                                                                    ## nextToken: string
                                                                                                    ##            
                                                                                                    ## : 
                                                                                                    ## Next 
                                                                                                    ## token 
                                                                                                    ## that 
                                                                                                    ## can 
                                                                                                    ## be 
                                                                                                    ## supplied 
                                                                                                    ## in 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## call 
                                                                                                    ## to 
                                                                                                    ## get 
                                                                                                    ## the 
                                                                                                    ## next 
                                                                                                    ## page 
                                                                                                    ## of 
                                                                                                    ## ground 
                                                                                                    ## stations.
  ##   
                                                                                                                ## satelliteId: string
                                                                                                                ##              
                                                                                                                ## : 
                                                                                                                ## Satellite 
                                                                                                                ## ID 
                                                                                                                ## to 
                                                                                                                ## retrieve 
                                                                                                                ## on-boarded 
                                                                                                                ## ground 
                                                                                                                ## stations.
  var query_402656779 = newJObject()
  add(query_402656779, "maxResults", newJInt(maxResults))
  add(query_402656779, "nextToken", newJString(nextToken))
  add(query_402656779, "satelliteId", newJString(satelliteId))
  result = call_402656778.call(nil, query_402656779, nil, nil, nil)

var listGroundStations* = Call_ListGroundStations_402656764(
    name: "listGroundStations", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/groundstation",
    validator: validate_ListGroundStations_402656765, base: "/",
    makeUrl: url_ListGroundStations_402656766,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSatellites_402656780 = ref object of OpenApiRestCall_402656044
proc url_ListSatellites_402656782(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSatellites_402656781(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of satellites.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : Maximum number of satellites returned.
  ##   
                                                                                         ## nextToken: JString
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Next 
                                                                                         ## token 
                                                                                         ## that 
                                                                                         ## can 
                                                                                         ## be 
                                                                                         ## supplied 
                                                                                         ## in 
                                                                                         ## the 
                                                                                         ## next 
                                                                                         ## call 
                                                                                         ## to 
                                                                                         ## get 
                                                                                         ## the 
                                                                                         ## next 
                                                                                         ## page 
                                                                                         ## of 
                                                                                         ## satellites.
  section = newJObject()
  var valid_402656783 = query.getOrDefault("maxResults")
  valid_402656783 = validateParameter(valid_402656783, JInt, required = false,
                                      default = nil)
  if valid_402656783 != nil:
    section.add "maxResults", valid_402656783
  var valid_402656784 = query.getOrDefault("nextToken")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "nextToken", valid_402656784
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
  var valid_402656785 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Security-Token", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Signature")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Signature", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Algorithm", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-Date")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-Date", valid_402656789
  var valid_402656790 = header.getOrDefault("X-Amz-Credential")
  valid_402656790 = validateParameter(valid_402656790, JString,
                                      required = false, default = nil)
  if valid_402656790 != nil:
    section.add "X-Amz-Credential", valid_402656790
  var valid_402656791 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656791
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656792: Call_ListSatellites_402656780; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of satellites.
                                                                                         ## 
  let valid = call_402656792.validator(path, query, header, formData, body, _)
  let scheme = call_402656792.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656792.makeUrl(scheme.get, call_402656792.host, call_402656792.base,
                                   call_402656792.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656792, uri, valid, _)

proc call*(call_402656793: Call_ListSatellites_402656780; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listSatellites
  ## Returns a list of satellites.
  ##   maxResults: int
                                  ##             : Maximum number of satellites returned.
  ##   
                                                                                         ## nextToken: string
                                                                                         ##            
                                                                                         ## : 
                                                                                         ## Next 
                                                                                         ## token 
                                                                                         ## that 
                                                                                         ## can 
                                                                                         ## be 
                                                                                         ## supplied 
                                                                                         ## in 
                                                                                         ## the 
                                                                                         ## next 
                                                                                         ## call 
                                                                                         ## to 
                                                                                         ## get 
                                                                                         ## the 
                                                                                         ## next 
                                                                                         ## page 
                                                                                         ## of 
                                                                                         ## satellites.
  var query_402656794 = newJObject()
  add(query_402656794, "maxResults", newJInt(maxResults))
  add(query_402656794, "nextToken", newJString(nextToken))
  result = call_402656793.call(nil, query_402656794, nil, nil, nil)

var listSatellites* = Call_ListSatellites_402656780(name: "listSatellites",
    meth: HttpMethod.HttpGet, host: "groundstation.amazonaws.com",
    route: "/satellite", validator: validate_ListSatellites_402656781,
    base: "/", makeUrl: url_ListSatellites_402656782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656809 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656811(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_402656810(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Assigns a tag to a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : ARN of a resource tag.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656812 = path.getOrDefault("resourceArn")
  valid_402656812 = validateParameter(valid_402656812, JString, required = true,
                                      default = nil)
  if valid_402656812 != nil:
    section.add "resourceArn", valid_402656812
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
  var valid_402656813 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Security-Token", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Signature")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Signature", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-Algorithm", valid_402656816
  var valid_402656817 = header.getOrDefault("X-Amz-Date")
  valid_402656817 = validateParameter(valid_402656817, JString,
                                      required = false, default = nil)
  if valid_402656817 != nil:
    section.add "X-Amz-Date", valid_402656817
  var valid_402656818 = header.getOrDefault("X-Amz-Credential")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Credential", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656819
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

proc call*(call_402656821: Call_TagResource_402656809; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns a tag to a resource.
                                                                                         ## 
  let valid = call_402656821.validator(path, query, header, formData, body, _)
  let scheme = call_402656821.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656821.makeUrl(scheme.get, call_402656821.host, call_402656821.base,
                                   call_402656821.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656821, uri, valid, _)

proc call*(call_402656822: Call_TagResource_402656809; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Assigns a tag to a resource.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
                               ##              : ARN of a resource tag.
  var path_402656823 = newJObject()
  var body_402656824 = newJObject()
  if body != nil:
    body_402656824 = body
  add(path_402656823, "resourceArn", newJString(resourceArn))
  result = call_402656822.call(path_402656823, nil, nil, nil, body_402656824)

var tagResource* = Call_TagResource_402656809(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656810,
    base: "/", makeUrl: url_TagResource_402656811,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656795 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656797(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
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

proc validate_ListTagsForResource_402656796(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of tags for a specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656798 = path.getOrDefault("resourceArn")
  valid_402656798 = validateParameter(valid_402656798, JString, required = true,
                                      default = nil)
  if valid_402656798 != nil:
    section.add "resourceArn", valid_402656798
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
  var valid_402656799 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Security-Token", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Signature")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Signature", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Algorithm", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Date")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Date", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-Credential")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-Credential", valid_402656804
  var valid_402656805 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656805 = validateParameter(valid_402656805, JString,
                                      required = false, default = nil)
  if valid_402656805 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656805
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656806: Call_ListTagsForResource_402656795;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of tags for a specified resource.
                                                                                         ## 
  let valid = call_402656806.validator(path, query, header, formData, body, _)
  let scheme = call_402656806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656806.makeUrl(scheme.get, call_402656806.host, call_402656806.base,
                                   call_402656806.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656806, uri, valid, _)

proc call*(call_402656807: Call_ListTagsForResource_402656795;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns a list of tags for a specified resource.
  ##   resourceArn: string (required)
                                                     ##              : ARN of a resource.
  var path_402656808 = newJObject()
  add(path_402656808, "resourceArn", newJString(resourceArn))
  result = call_402656807.call(path_402656808, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656795(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "groundstation.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656796, base: "/",
    makeUrl: url_ListTagsForResource_402656797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ReserveContact_402656825 = ref object of OpenApiRestCall_402656044
proc url_ReserveContact_402656827(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ReserveContact_402656826(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Reserves a contact using specified parameters.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
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
  var valid_402656828 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Security-Token", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-Signature")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-Signature", valid_402656829
  var valid_402656830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656830 = validateParameter(valid_402656830, JString,
                                      required = false, default = nil)
  if valid_402656830 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656830
  var valid_402656831 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Algorithm", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Date")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Date", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Credential")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Credential", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656834
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

proc call*(call_402656836: Call_ReserveContact_402656825; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Reserves a contact using specified parameters.
                                                                                         ## 
  let valid = call_402656836.validator(path, query, header, formData, body, _)
  let scheme = call_402656836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656836.makeUrl(scheme.get, call_402656836.host, call_402656836.base,
                                   call_402656836.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656836, uri, valid, _)

proc call*(call_402656837: Call_ReserveContact_402656825; body: JsonNode): Recallable =
  ## reserveContact
  ## Reserves a contact using specified parameters.
  ##   body: JObject (required)
  var body_402656838 = newJObject()
  if body != nil:
    body_402656838 = body
  result = call_402656837.call(nil, nil, nil, nil, body_402656838)

var reserveContact* = Call_ReserveContact_402656825(name: "reserveContact",
    meth: HttpMethod.HttpPost, host: "groundstation.amazonaws.com",
    route: "/contact", validator: validate_ReserveContact_402656826, base: "/",
    makeUrl: url_ReserveContact_402656827, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656839 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656841(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_402656840(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deassigns a resource tag.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : ARN of a resource.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656842 = path.getOrDefault("resourceArn")
  valid_402656842 = validateParameter(valid_402656842, JString, required = true,
                                      default = nil)
  if valid_402656842 != nil:
    section.add "resourceArn", valid_402656842
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : Keys of a resource tag.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656843 = query.getOrDefault("tagKeys")
  valid_402656843 = validateParameter(valid_402656843, JArray, required = true,
                                      default = nil)
  if valid_402656843 != nil:
    section.add "tagKeys", valid_402656843
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
  var valid_402656844 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Security-Token", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Signature")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Signature", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Algorithm", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Date")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Date", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Credential")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Credential", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656851: Call_UntagResource_402656839; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deassigns a resource tag.
                                                                                         ## 
  let valid = call_402656851.validator(path, query, header, formData, body, _)
  let scheme = call_402656851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656851.makeUrl(scheme.get, call_402656851.host, call_402656851.base,
                                   call_402656851.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656851, uri, valid, _)

proc call*(call_402656852: Call_UntagResource_402656839; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Deassigns a resource tag.
  ##   tagKeys: JArray (required)
                              ##          : Keys of a resource tag.
  ##   resourceArn: string (required)
                                                                   ##              : ARN of a resource.
  var path_402656853 = newJObject()
  var query_402656854 = newJObject()
  if tagKeys != nil:
    query_402656854.add "tagKeys", tagKeys
  add(path_402656853, "resourceArn", newJString(resourceArn))
  result = call_402656852.call(path_402656853, query_402656854, nil, nil, nil)

var untagResource* = Call_UntagResource_402656839(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "groundstation.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656840,
    base: "/", makeUrl: url_UntagResource_402656841,
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
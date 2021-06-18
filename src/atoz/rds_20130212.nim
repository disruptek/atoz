
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-02-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## 
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/rds/
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

  OpenApiRestCall_402656035 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656035](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656035): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "rds.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
                               "us-west-2": "rds.us-west-2.amazonaws.com",
                               "eu-west-2": "rds.eu-west-2.amazonaws.com", "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com", "eu-central-1": "rds.eu-central-1.amazonaws.com",
                               "us-east-2": "rds.us-east-2.amazonaws.com",
                               "us-east-1": "rds.us-east-1.amazonaws.com", "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "rds.ap-south-1.amazonaws.com",
                               "eu-north-1": "rds.eu-north-1.amazonaws.com", "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
                               "us-west-1": "rds.us-west-1.amazonaws.com", "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "rds.eu-west-3.amazonaws.com",
                               "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "rds.sa-east-1.amazonaws.com",
                               "eu-west-1": "rds.eu-west-1.amazonaws.com", "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "rds.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
      "us-west-2": "rds.us-west-2.amazonaws.com",
      "eu-west-2": "rds.eu-west-2.amazonaws.com",
      "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
      "eu-central-1": "rds.eu-central-1.amazonaws.com",
      "us-east-2": "rds.us-east-2.amazonaws.com",
      "us-east-1": "rds.us-east-1.amazonaws.com",
      "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "rds.ap-south-1.amazonaws.com",
      "eu-north-1": "rds.eu-north-1.amazonaws.com",
      "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
      "us-west-1": "rds.us-west-1.amazonaws.com",
      "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
      "eu-west-3": "rds.eu-west-3.amazonaws.com",
      "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "rds.sa-east-1.amazonaws.com",
      "eu-west-1": "rds.eu-west-1.amazonaws.com",
      "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
      "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "rds"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_PostAddSourceIdentifierToSubscription_402656482 = ref object of OpenApiRestCall_402656035
proc url_PostAddSourceIdentifierToSubscription_402656484(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_402656483(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656485 = query.getOrDefault("Version")
  valid_402656485 = validateParameter(valid_402656485, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656485 != nil:
    section.add "Version", valid_402656485
  var valid_402656486 = query.getOrDefault("Action")
  valid_402656486 = validateParameter(valid_402656486, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_402656486 != nil:
    section.add "Action", valid_402656486
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
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_402656494 = formData.getOrDefault("SourceIdentifier")
  valid_402656494 = validateParameter(valid_402656494, JString, required = true,
                                      default = nil)
  if valid_402656494 != nil:
    section.add "SourceIdentifier", valid_402656494
  var valid_402656495 = formData.getOrDefault("SubscriptionName")
  valid_402656495 = validateParameter(valid_402656495, JString, required = true,
                                      default = nil)
  if valid_402656495 != nil:
    section.add "SubscriptionName", valid_402656495
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656496: Call_PostAddSourceIdentifierToSubscription_402656482;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656496.validator(path, query, header, formData, body, _)
  let scheme = call_402656496.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656496.makeUrl(scheme.get, call_402656496.host, call_402656496.base,
                                   call_402656496.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656496, uri, valid, _)

proc call*(call_402656497: Call_PostAddSourceIdentifierToSubscription_402656482;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-02-12";
           Action: string = "AddSourceIdentifierToSubscription"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  var query_402656498 = newJObject()
  var formData_402656499 = newJObject()
  add(query_402656498, "Version", newJString(Version))
  add(query_402656498, "Action", newJString(Action))
  add(formData_402656499, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_402656499, "SubscriptionName", newJString(SubscriptionName))
  result = call_402656497.call(nil, query_402656498, nil, formData_402656499,
                               nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_402656482(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_402656483,
    base: "/", makeUrl: url_PostAddSourceIdentifierToSubscription_402656484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_402656285 = ref object of OpenApiRestCall_402656035
proc url_GetAddSourceIdentifierToSubscription_402656287(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_402656286(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `SourceIdentifier` field"
  var valid_402656366 = query.getOrDefault("SourceIdentifier")
  valid_402656366 = validateParameter(valid_402656366, JString, required = true,
                                      default = nil)
  if valid_402656366 != nil:
    section.add "SourceIdentifier", valid_402656366
  var valid_402656379 = query.getOrDefault("Version")
  valid_402656379 = validateParameter(valid_402656379, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656379 != nil:
    section.add "Version", valid_402656379
  var valid_402656380 = query.getOrDefault("SubscriptionName")
  valid_402656380 = validateParameter(valid_402656380, JString, required = true,
                                      default = nil)
  if valid_402656380 != nil:
    section.add "SubscriptionName", valid_402656380
  var valid_402656381 = query.getOrDefault("Action")
  valid_402656381 = validateParameter(valid_402656381, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_402656381 != nil:
    section.add "Action", valid_402656381
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
  var valid_402656382 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Security-Token", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Signature")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Signature", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Algorithm", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Date")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Date", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Credential")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Credential", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656402: Call_GetAddSourceIdentifierToSubscription_402656285;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656402.validator(path, query, header, formData, body, _)
  let scheme = call_402656402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656402.makeUrl(scheme.get, call_402656402.host, call_402656402.base,
                                   call_402656402.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656402, uri, valid, _)

proc call*(call_402656451: Call_GetAddSourceIdentifierToSubscription_402656285;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-02-12";
           Action: string = "AddSourceIdentifierToSubscription"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402656452 = newJObject()
  add(query_402656452, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402656452, "Version", newJString(Version))
  add(query_402656452, "SubscriptionName", newJString(SubscriptionName))
  add(query_402656452, "Action", newJString(Action))
  result = call_402656451.call(nil, query_402656452, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_402656285(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_402656286,
    base: "/", makeUrl: url_GetAddSourceIdentifierToSubscription_402656287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_402656517 = ref object of OpenApiRestCall_402656035
proc url_PostAddTagsToResource_402656519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_402656518(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656520 = query.getOrDefault("Version")
  valid_402656520 = validateParameter(valid_402656520, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656520 != nil:
    section.add "Version", valid_402656520
  var valid_402656521 = query.getOrDefault("Action")
  valid_402656521 = validateParameter(valid_402656521, JString, required = true,
                                      default = newJString("AddTagsToResource"))
  if valid_402656521 != nil:
    section.add "Action", valid_402656521
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
  var valid_402656522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Security-Token", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Signature")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Signature", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Algorithm", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Date")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Date", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Credential")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Credential", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656528
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
         "formData argument is necessary due to required `Tags` field"
  var valid_402656529 = formData.getOrDefault("Tags")
  valid_402656529 = validateParameter(valid_402656529, JArray, required = true,
                                      default = nil)
  if valid_402656529 != nil:
    section.add "Tags", valid_402656529
  var valid_402656530 = formData.getOrDefault("ResourceName")
  valid_402656530 = validateParameter(valid_402656530, JString, required = true,
                                      default = nil)
  if valid_402656530 != nil:
    section.add "ResourceName", valid_402656530
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_PostAddTagsToResource_402656517;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_PostAddTagsToResource_402656517; Tags: JsonNode;
           ResourceName: string; Version: string = "2013-02-12";
           Action: string = "AddTagsToResource"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  var query_402656533 = newJObject()
  var formData_402656534 = newJObject()
  if Tags != nil:
    formData_402656534.add "Tags", Tags
  add(query_402656533, "Version", newJString(Version))
  add(query_402656533, "Action", newJString(Action))
  add(formData_402656534, "ResourceName", newJString(ResourceName))
  result = call_402656532.call(nil, query_402656533, nil, formData_402656534,
                               nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_402656517(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_402656518, base: "/",
    makeUrl: url_PostAddTagsToResource_402656519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_402656500 = ref object of OpenApiRestCall_402656035
proc url_GetAddTagsToResource_402656502(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_402656501(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656503 = query.getOrDefault("Version")
  valid_402656503 = validateParameter(valid_402656503, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656503 != nil:
    section.add "Version", valid_402656503
  var valid_402656504 = query.getOrDefault("Tags")
  valid_402656504 = validateParameter(valid_402656504, JArray, required = true,
                                      default = nil)
  if valid_402656504 != nil:
    section.add "Tags", valid_402656504
  var valid_402656505 = query.getOrDefault("ResourceName")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "ResourceName", valid_402656505
  var valid_402656506 = query.getOrDefault("Action")
  valid_402656506 = validateParameter(valid_402656506, JString, required = true,
                                      default = newJString("AddTagsToResource"))
  if valid_402656506 != nil:
    section.add "Action", valid_402656506
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
  var valid_402656507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Security-Token", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Signature")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Signature", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Algorithm", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Date")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Date", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Credential")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Credential", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656514: Call_GetAddTagsToResource_402656500;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656514.validator(path, query, header, formData, body, _)
  let scheme = call_402656514.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656514.makeUrl(scheme.get, call_402656514.host, call_402656514.base,
                                   call_402656514.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656514, uri, valid, _)

proc call*(call_402656515: Call_GetAddTagsToResource_402656500; Tags: JsonNode;
           ResourceName: string; Version: string = "2013-02-12";
           Action: string = "AddTagsToResource"): Recallable =
  ## getAddTagsToResource
  ##   Version: string (required)
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402656516 = newJObject()
  add(query_402656516, "Version", newJString(Version))
  if Tags != nil:
    query_402656516.add "Tags", Tags
  add(query_402656516, "ResourceName", newJString(ResourceName))
  add(query_402656516, "Action", newJString(Action))
  result = call_402656515.call(nil, query_402656516, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_402656500(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_402656501, base: "/",
    makeUrl: url_GetAddTagsToResource_402656502,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_402656555 = ref object of OpenApiRestCall_402656035
proc url_PostAuthorizeDBSecurityGroupIngress_402656557(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_402656556(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656558 = query.getOrDefault("Version")
  valid_402656558 = validateParameter(valid_402656558, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656558 != nil:
    section.add "Version", valid_402656558
  var valid_402656559 = query.getOrDefault("Action")
  valid_402656559 = validateParameter(valid_402656559, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_402656559 != nil:
    section.add "Action", valid_402656559
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
  var valid_402656560 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Security-Token", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Signature")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Signature", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Algorithm", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Date")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Date", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Credential")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Credential", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656566
  result.add "header", section
  ## parameters in `formData` object:
  ##   EC2SecurityGroupName: JString
  ##   CIDRIP: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  section = newJObject()
  var valid_402656567 = formData.getOrDefault("EC2SecurityGroupName")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "EC2SecurityGroupName", valid_402656567
  var valid_402656568 = formData.getOrDefault("CIDRIP")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "CIDRIP", valid_402656568
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402656569 = formData.getOrDefault("DBSecurityGroupName")
  valid_402656569 = validateParameter(valid_402656569, JString, required = true,
                                      default = nil)
  if valid_402656569 != nil:
    section.add "DBSecurityGroupName", valid_402656569
  var valid_402656570 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402656570
  var valid_402656571 = formData.getOrDefault("EC2SecurityGroupId")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "EC2SecurityGroupId", valid_402656571
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_PostAuthorizeDBSecurityGroupIngress_402656555;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_PostAuthorizeDBSecurityGroupIngress_402656555;
           DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
           CIDRIP: string = ""; Version: string = "2013-02-12";
           EC2SecurityGroupOwnerId: string = "";
           Action: string = "AuthorizeDBSecurityGroupIngress";
           EC2SecurityGroupId: string = ""): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   EC2SecurityGroupId: string
  var query_402656574 = newJObject()
  var formData_402656575 = newJObject()
  add(formData_402656575, "EC2SecurityGroupName",
      newJString(EC2SecurityGroupName))
  add(formData_402656575, "CIDRIP", newJString(CIDRIP))
  add(query_402656574, "Version", newJString(Version))
  add(formData_402656575, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402656575, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402656574, "Action", newJString(Action))
  add(formData_402656575, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  result = call_402656573.call(nil, query_402656574, nil, formData_402656575,
                               nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_402656555(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_402656556,
    base: "/", makeUrl: url_PostAuthorizeDBSecurityGroupIngress_402656557,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_402656535 = ref object of OpenApiRestCall_402656035
proc url_GetAuthorizeDBSecurityGroupIngress_402656537(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_402656536(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   Version: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_402656538 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402656538
  var valid_402656539 = query.getOrDefault("EC2SecurityGroupId")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "EC2SecurityGroupId", valid_402656539
  var valid_402656540 = query.getOrDefault("Version")
  valid_402656540 = validateParameter(valid_402656540, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656540 != nil:
    section.add "Version", valid_402656540
  var valid_402656541 = query.getOrDefault("EC2SecurityGroupName")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "EC2SecurityGroupName", valid_402656541
  var valid_402656542 = query.getOrDefault("Action")
  valid_402656542 = validateParameter(valid_402656542, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_402656542 != nil:
    section.add "Action", valid_402656542
  var valid_402656543 = query.getOrDefault("DBSecurityGroupName")
  valid_402656543 = validateParameter(valid_402656543, JString, required = true,
                                      default = nil)
  if valid_402656543 != nil:
    section.add "DBSecurityGroupName", valid_402656543
  var valid_402656544 = query.getOrDefault("CIDRIP")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "CIDRIP", valid_402656544
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
  var valid_402656545 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Security-Token", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Signature")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Signature", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Algorithm", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Date")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Date", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Credential")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Credential", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656551
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656552: Call_GetAuthorizeDBSecurityGroupIngress_402656535;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656552.validator(path, query, header, formData, body, _)
  let scheme = call_402656552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656552.makeUrl(scheme.get, call_402656552.host, call_402656552.base,
                                   call_402656552.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656552, uri, valid, _)

proc call*(call_402656553: Call_GetAuthorizeDBSecurityGroupIngress_402656535;
           DBSecurityGroupName: string; EC2SecurityGroupOwnerId: string = "";
           EC2SecurityGroupId: string = ""; Version: string = "2013-02-12";
           EC2SecurityGroupName: string = "";
           Action: string = "AuthorizeDBSecurityGroupIngress";
           CIDRIP: string = ""): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   Version: string (required)
  ##   EC2SecurityGroupName: string
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   CIDRIP: string
  var query_402656554 = newJObject()
  add(query_402656554, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402656554, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_402656554, "Version", newJString(Version))
  add(query_402656554, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_402656554, "Action", newJString(Action))
  add(query_402656554, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402656554, "CIDRIP", newJString(CIDRIP))
  result = call_402656553.call(nil, query_402656554, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_402656535(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_402656536, base: "/",
    makeUrl: url_GetAuthorizeDBSecurityGroupIngress_402656537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_402656593 = ref object of OpenApiRestCall_402656035
proc url_PostCopyDBSnapshot_402656595(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_402656594(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656596 = query.getOrDefault("Version")
  valid_402656596 = validateParameter(valid_402656596, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656596 != nil:
    section.add "Version", valid_402656596
  var valid_402656597 = query.getOrDefault("Action")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656597 != nil:
    section.add "Action", valid_402656597
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
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_402656605 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_402656605 = validateParameter(valid_402656605, JString, required = true,
                                      default = nil)
  if valid_402656605 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_402656605
  var valid_402656606 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_402656606 = validateParameter(valid_402656606, JString, required = true,
                                      default = nil)
  if valid_402656606 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_402656606
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656607: Call_PostCopyDBSnapshot_402656593;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656607.validator(path, query, header, formData, body, _)
  let scheme = call_402656607.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656607.makeUrl(scheme.get, call_402656607.host, call_402656607.base,
                                   call_402656607.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656607, uri, valid, _)

proc call*(call_402656608: Call_PostCopyDBSnapshot_402656593;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Version: string = "2013-02-12";
           Action: string = "CopyDBSnapshot"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656609 = newJObject()
  var formData_402656610 = newJObject()
  add(formData_402656610, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_402656609, "Version", newJString(Version))
  add(formData_402656610, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656609, "Action", newJString(Action))
  result = call_402656608.call(nil, query_402656609, nil, formData_402656610,
                               nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_402656593(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_402656594, base: "/",
    makeUrl: url_PostCopyDBSnapshot_402656595,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_402656576 = ref object of OpenApiRestCall_402656035
proc url_GetCopyDBSnapshot_402656578(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_402656577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_402656579 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_402656579
  var valid_402656580 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_402656580 = validateParameter(valid_402656580, JString, required = true,
                                      default = nil)
  if valid_402656580 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_402656580
  var valid_402656581 = query.getOrDefault("Version")
  valid_402656581 = validateParameter(valid_402656581, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656581 != nil:
    section.add "Version", valid_402656581
  var valid_402656582 = query.getOrDefault("Action")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656582 != nil:
    section.add "Action", valid_402656582
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
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656590: Call_GetCopyDBSnapshot_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656590.validator(path, query, header, formData, body, _)
  let scheme = call_402656590.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656590.makeUrl(scheme.get, call_402656590.host, call_402656590.base,
                                   call_402656590.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656590, uri, valid, _)

proc call*(call_402656591: Call_GetCopyDBSnapshot_402656576;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Version: string = "2013-02-12";
           Action: string = "CopyDBSnapshot"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402656592 = newJObject()
  add(query_402656592, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_402656592, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656592, "Version", newJString(Version))
  add(query_402656592, "Action", newJString(Action))
  result = call_402656591.call(nil, query_402656592, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_402656576(
    name: "getCopyDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_GetCopyDBSnapshot_402656577, base: "/",
    makeUrl: url_GetCopyDBSnapshot_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_402656650 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstance_402656652(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_402656651(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656653 = query.getOrDefault("Version")
  valid_402656653 = validateParameter(valid_402656653, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656653 != nil:
    section.add "Version", valid_402656653
  var valid_402656654 = query.getOrDefault("Action")
  valid_402656654 = validateParameter(valid_402656654, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656654 != nil:
    section.add "Action", valid_402656654
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
  var valid_402656655 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656655 = validateParameter(valid_402656655, JString,
                                      required = false, default = nil)
  if valid_402656655 != nil:
    section.add "X-Amz-Security-Token", valid_402656655
  var valid_402656656 = header.getOrDefault("X-Amz-Signature")
  valid_402656656 = validateParameter(valid_402656656, JString,
                                      required = false, default = nil)
  if valid_402656656 != nil:
    section.add "X-Amz-Signature", valid_402656656
  var valid_402656657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Algorithm", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Date")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Date", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Credential")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Credential", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656661
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   Port: JInt
  ##   Engine: JString (required)
  ##   DBSubnetGroupName: JString
  ##   AllocatedStorage: JInt (required)
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   MasterUserPassword: JString (required)
  ##   CharacterSetName: JString
  ##   DBName: JString
  ##   DBParameterGroupName: JString
  ##   Iops: JInt
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString (required)
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: JString
  ##   EngineVersion: JString
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402656662 = formData.getOrDefault("PreferredBackupWindow")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "PreferredBackupWindow", valid_402656662
  var valid_402656663 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656663 = validateParameter(valid_402656663, JBool, required = false,
                                      default = nil)
  if valid_402656663 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656663
  var valid_402656664 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402656664 = validateParameter(valid_402656664, JArray, required = false,
                                      default = nil)
  if valid_402656664 != nil:
    section.add "VpcSecurityGroupIds", valid_402656664
  var valid_402656665 = formData.getOrDefault("Port")
  valid_402656665 = validateParameter(valid_402656665, JInt, required = false,
                                      default = nil)
  if valid_402656665 != nil:
    section.add "Port", valid_402656665
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402656666 = formData.getOrDefault("Engine")
  valid_402656666 = validateParameter(valid_402656666, JString, required = true,
                                      default = nil)
  if valid_402656666 != nil:
    section.add "Engine", valid_402656666
  var valid_402656667 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "DBSubnetGroupName", valid_402656667
  var valid_402656668 = formData.getOrDefault("AllocatedStorage")
  valid_402656668 = validateParameter(valid_402656668, JInt, required = true,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "AllocatedStorage", valid_402656668
  var valid_402656669 = formData.getOrDefault("PubliclyAccessible")
  valid_402656669 = validateParameter(valid_402656669, JBool, required = false,
                                      default = nil)
  if valid_402656669 != nil:
    section.add "PubliclyAccessible", valid_402656669
  var valid_402656670 = formData.getOrDefault("AvailabilityZone")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "AvailabilityZone", valid_402656670
  var valid_402656671 = formData.getOrDefault("MasterUserPassword")
  valid_402656671 = validateParameter(valid_402656671, JString, required = true,
                                      default = nil)
  if valid_402656671 != nil:
    section.add "MasterUserPassword", valid_402656671
  var valid_402656672 = formData.getOrDefault("CharacterSetName")
  valid_402656672 = validateParameter(valid_402656672, JString,
                                      required = false, default = nil)
  if valid_402656672 != nil:
    section.add "CharacterSetName", valid_402656672
  var valid_402656673 = formData.getOrDefault("DBName")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "DBName", valid_402656673
  var valid_402656674 = formData.getOrDefault("DBParameterGroupName")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "DBParameterGroupName", valid_402656674
  var valid_402656675 = formData.getOrDefault("Iops")
  valid_402656675 = validateParameter(valid_402656675, JInt, required = false,
                                      default = nil)
  if valid_402656675 != nil:
    section.add "Iops", valid_402656675
  var valid_402656676 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656676
  var valid_402656677 = formData.getOrDefault("DBInstanceClass")
  valid_402656677 = validateParameter(valid_402656677, JString, required = true,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "DBInstanceClass", valid_402656677
  var valid_402656678 = formData.getOrDefault("LicenseModel")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "LicenseModel", valid_402656678
  var valid_402656679 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656679 = validateParameter(valid_402656679, JString, required = true,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "DBInstanceIdentifier", valid_402656679
  var valid_402656680 = formData.getOrDefault("MasterUsername")
  valid_402656680 = validateParameter(valid_402656680, JString, required = true,
                                      default = nil)
  if valid_402656680 != nil:
    section.add "MasterUsername", valid_402656680
  var valid_402656681 = formData.getOrDefault("MultiAZ")
  valid_402656681 = validateParameter(valid_402656681, JBool, required = false,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "MultiAZ", valid_402656681
  var valid_402656682 = formData.getOrDefault("DBSecurityGroups")
  valid_402656682 = validateParameter(valid_402656682, JArray, required = false,
                                      default = nil)
  if valid_402656682 != nil:
    section.add "DBSecurityGroups", valid_402656682
  var valid_402656683 = formData.getOrDefault("OptionGroupName")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "OptionGroupName", valid_402656683
  var valid_402656684 = formData.getOrDefault("EngineVersion")
  valid_402656684 = validateParameter(valid_402656684, JString,
                                      required = false, default = nil)
  if valid_402656684 != nil:
    section.add "EngineVersion", valid_402656684
  var valid_402656685 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402656685 = validateParameter(valid_402656685, JInt, required = false,
                                      default = nil)
  if valid_402656685 != nil:
    section.add "BackupRetentionPeriod", valid_402656685
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656686: Call_PostCreateDBInstance_402656650;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656686.validator(path, query, header, formData, body, _)
  let scheme = call_402656686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656686.makeUrl(scheme.get, call_402656686.host, call_402656686.base,
                                   call_402656686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656686, uri, valid, _)

proc call*(call_402656687: Call_PostCreateDBInstance_402656650; Engine: string;
           AllocatedStorage: int; MasterUserPassword: string;
           DBInstanceClass: string; DBInstanceIdentifier: string;
           MasterUsername: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; Port: int = 0;
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; CharacterSetName: string = "";
           DBName: string = ""; Version: string = "2013-02-12";
           DBParameterGroupName: string = ""; Iops: int = 0;
           PreferredMaintenanceWindow: string = ""; LicenseModel: string = "";
           MultiAZ: bool = false; DBSecurityGroups: JsonNode = nil;
           OptionGroupName: string = ""; Action: string = "CreateDBInstance";
           EngineVersion: string = ""; BackupRetentionPeriod: int = 0): Recallable =
  ## postCreateDBInstance
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   VpcSecurityGroupIds: JArray
  ##   Port: int
  ##   Engine: string (required)
  ##   DBSubnetGroupName: string
  ##   AllocatedStorage: int (required)
  ##   PubliclyAccessible: bool
  ##   AvailabilityZone: string
  ##   MasterUserPassword: string (required)
  ##   CharacterSetName: string
  ##   DBName: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string
  ##   Iops: int
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string (required)
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   EngineVersion: string
  ##   BackupRetentionPeriod: int
  var query_402656688 = newJObject()
  var formData_402656689 = newJObject()
  add(formData_402656689, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402656689, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402656689.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402656689, "Port", newJInt(Port))
  add(formData_402656689, "Engine", newJString(Engine))
  add(formData_402656689, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402656689, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402656689, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656689, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402656689, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402656689, "CharacterSetName", newJString(CharacterSetName))
  add(formData_402656689, "DBName", newJString(DBName))
  add(query_402656688, "Version", newJString(Version))
  add(formData_402656689, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402656689, "Iops", newJInt(Iops))
  add(formData_402656689, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402656689, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656689, "LicenseModel", newJString(LicenseModel))
  add(formData_402656689, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656689, "MasterUsername", newJString(MasterUsername))
  add(formData_402656689, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402656689.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402656689, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656688, "Action", newJString(Action))
  add(formData_402656689, "EngineVersion", newJString(EngineVersion))
  add(formData_402656689, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402656687.call(nil, query_402656688, nil, formData_402656689,
                               nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_402656650(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_402656651, base: "/",
    makeUrl: url_PostCreateDBInstance_402656652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_402656611 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstance_402656613(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_402656612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VpcSecurityGroupIds: JArray
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  ##   PreferredBackupWindow: JString
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSubnetGroupName: JString
  ##   DBParameterGroupName: JString
  ##   MasterUserPassword: JString (required)
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   EngineVersion: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBName: JString
  ##   AllocatedStorage: JInt (required)
  ##   MasterUsername: JString (required)
  ##   DBInstanceClass: JString (required)
  ##   Engine: JString (required)
  ##   Port: JInt
  ##   CharacterSetName: JString
  ##   Action: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBSecurityGroups: JArray
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402656614 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402656614 = validateParameter(valid_402656614, JArray, required = false,
                                      default = nil)
  if valid_402656614 != nil:
    section.add "VpcSecurityGroupIds", valid_402656614
  var valid_402656615 = query.getOrDefault("PubliclyAccessible")
  valid_402656615 = validateParameter(valid_402656615, JBool, required = false,
                                      default = nil)
  if valid_402656615 != nil:
    section.add "PubliclyAccessible", valid_402656615
  var valid_402656616 = query.getOrDefault("OptionGroupName")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "OptionGroupName", valid_402656616
  var valid_402656617 = query.getOrDefault("PreferredBackupWindow")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "PreferredBackupWindow", valid_402656617
  var valid_402656618 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656618
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656619 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "DBInstanceIdentifier", valid_402656619
  var valid_402656620 = query.getOrDefault("DBSubnetGroupName")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "DBSubnetGroupName", valid_402656620
  var valid_402656621 = query.getOrDefault("DBParameterGroupName")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "DBParameterGroupName", valid_402656621
  var valid_402656622 = query.getOrDefault("MasterUserPassword")
  valid_402656622 = validateParameter(valid_402656622, JString, required = true,
                                      default = nil)
  if valid_402656622 != nil:
    section.add "MasterUserPassword", valid_402656622
  var valid_402656623 = query.getOrDefault("Iops")
  valid_402656623 = validateParameter(valid_402656623, JInt, required = false,
                                      default = nil)
  if valid_402656623 != nil:
    section.add "Iops", valid_402656623
  var valid_402656624 = query.getOrDefault("AvailabilityZone")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "AvailabilityZone", valid_402656624
  var valid_402656625 = query.getOrDefault("MultiAZ")
  valid_402656625 = validateParameter(valid_402656625, JBool, required = false,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "MultiAZ", valid_402656625
  var valid_402656626 = query.getOrDefault("Version")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656626 != nil:
    section.add "Version", valid_402656626
  var valid_402656627 = query.getOrDefault("EngineVersion")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "EngineVersion", valid_402656627
  var valid_402656628 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656628 = validateParameter(valid_402656628, JBool, required = false,
                                      default = nil)
  if valid_402656628 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656628
  var valid_402656629 = query.getOrDefault("DBName")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "DBName", valid_402656629
  var valid_402656630 = query.getOrDefault("AllocatedStorage")
  valid_402656630 = validateParameter(valid_402656630, JInt, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "AllocatedStorage", valid_402656630
  var valid_402656631 = query.getOrDefault("MasterUsername")
  valid_402656631 = validateParameter(valid_402656631, JString, required = true,
                                      default = nil)
  if valid_402656631 != nil:
    section.add "MasterUsername", valid_402656631
  var valid_402656632 = query.getOrDefault("DBInstanceClass")
  valid_402656632 = validateParameter(valid_402656632, JString, required = true,
                                      default = nil)
  if valid_402656632 != nil:
    section.add "DBInstanceClass", valid_402656632
  var valid_402656633 = query.getOrDefault("Engine")
  valid_402656633 = validateParameter(valid_402656633, JString, required = true,
                                      default = nil)
  if valid_402656633 != nil:
    section.add "Engine", valid_402656633
  var valid_402656634 = query.getOrDefault("Port")
  valid_402656634 = validateParameter(valid_402656634, JInt, required = false,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "Port", valid_402656634
  var valid_402656635 = query.getOrDefault("CharacterSetName")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "CharacterSetName", valid_402656635
  var valid_402656636 = query.getOrDefault("Action")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656636 != nil:
    section.add "Action", valid_402656636
  var valid_402656637 = query.getOrDefault("BackupRetentionPeriod")
  valid_402656637 = validateParameter(valid_402656637, JInt, required = false,
                                      default = nil)
  if valid_402656637 != nil:
    section.add "BackupRetentionPeriod", valid_402656637
  var valid_402656638 = query.getOrDefault("DBSecurityGroups")
  valid_402656638 = validateParameter(valid_402656638, JArray, required = false,
                                      default = nil)
  if valid_402656638 != nil:
    section.add "DBSecurityGroups", valid_402656638
  var valid_402656639 = query.getOrDefault("LicenseModel")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "LicenseModel", valid_402656639
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
  var valid_402656640 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Security-Token", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Signature")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Signature", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Algorithm", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Date")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Date", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Credential")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Credential", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656647: Call_GetCreateDBInstance_402656611;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656647.validator(path, query, header, formData, body, _)
  let scheme = call_402656647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656647.makeUrl(scheme.get, call_402656647.host, call_402656647.base,
                                   call_402656647.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656647, uri, valid, _)

proc call*(call_402656648: Call_GetCreateDBInstance_402656611;
           DBInstanceIdentifier: string; MasterUserPassword: string;
           AllocatedStorage: int; MasterUsername: string;
           DBInstanceClass: string; Engine: string;
           VpcSecurityGroupIds: JsonNode = nil;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBSubnetGroupName: string = ""; DBParameterGroupName: string = "";
           Iops: int = 0; AvailabilityZone: string = ""; MultiAZ: bool = false;
           Version: string = "2013-02-12"; EngineVersion: string = "";
           AutoMinorVersionUpgrade: bool = false; DBName: string = "";
           Port: int = 0; CharacterSetName: string = "";
           Action: string = "CreateDBInstance"; BackupRetentionPeriod: int = 0;
           DBSecurityGroups: JsonNode = nil; LicenseModel: string = ""): Recallable =
  ## getCreateDBInstance
  ##   VpcSecurityGroupIds: JArray
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   DBParameterGroupName: string
  ##   MasterUserPassword: string (required)
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   EngineVersion: string
  ##   AutoMinorVersionUpgrade: bool
  ##   DBName: string
  ##   AllocatedStorage: int (required)
  ##   MasterUsername: string (required)
  ##   DBInstanceClass: string (required)
  ##   Engine: string (required)
  ##   Port: int
  ##   CharacterSetName: string
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBSecurityGroups: JArray
  ##   LicenseModel: string
  var query_402656649 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402656649.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402656649, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656649, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656649, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402656649, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402656649, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656649, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656649, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402656649, "Iops", newJInt(Iops))
  add(query_402656649, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656649, "MultiAZ", newJBool(MultiAZ))
  add(query_402656649, "Version", newJString(Version))
  add(query_402656649, "EngineVersion", newJString(EngineVersion))
  add(query_402656649, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656649, "DBName", newJString(DBName))
  add(query_402656649, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402656649, "MasterUsername", newJString(MasterUsername))
  add(query_402656649, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656649, "Engine", newJString(Engine))
  add(query_402656649, "Port", newJInt(Port))
  add(query_402656649, "CharacterSetName", newJString(CharacterSetName))
  add(query_402656649, "Action", newJString(Action))
  add(query_402656649, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402656649.add "DBSecurityGroups", DBSecurityGroups
  add(query_402656649, "LicenseModel", newJString(LicenseModel))
  result = call_402656648.call(nil, query_402656649, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_402656611(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_402656612, base: "/",
    makeUrl: url_GetCreateDBInstance_402656613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_402656714 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstanceReadReplica_402656716(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_402656715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656717 = query.getOrDefault("Version")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656717 != nil:
    section.add "Version", valid_402656717
  var valid_402656718 = query.getOrDefault("Action")
  valid_402656718 = validateParameter(valid_402656718, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656718 != nil:
    section.add "Action", valid_402656718
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
  var valid_402656719 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Security-Token", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Signature")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Signature", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Algorithm", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Date")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Date", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-Credential")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Credential", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656725
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402656726 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656726 = validateParameter(valid_402656726, JBool, required = false,
                                      default = nil)
  if valid_402656726 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656726
  var valid_402656727 = formData.getOrDefault("Port")
  valid_402656727 = validateParameter(valid_402656727, JInt, required = false,
                                      default = nil)
  if valid_402656727 != nil:
    section.add "Port", valid_402656727
  var valid_402656728 = formData.getOrDefault("PubliclyAccessible")
  valid_402656728 = validateParameter(valid_402656728, JBool, required = false,
                                      default = nil)
  if valid_402656728 != nil:
    section.add "PubliclyAccessible", valid_402656728
  var valid_402656729 = formData.getOrDefault("AvailabilityZone")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "AvailabilityZone", valid_402656729
  var valid_402656730 = formData.getOrDefault("Iops")
  valid_402656730 = validateParameter(valid_402656730, JInt, required = false,
                                      default = nil)
  if valid_402656730 != nil:
    section.add "Iops", valid_402656730
  var valid_402656731 = formData.getOrDefault("DBInstanceClass")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "DBInstanceClass", valid_402656731
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656732 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "DBInstanceIdentifier", valid_402656732
  var valid_402656733 = formData.getOrDefault("OptionGroupName")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "OptionGroupName", valid_402656733
  var valid_402656734 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656734 = validateParameter(valid_402656734, JString, required = true,
                                      default = nil)
  if valid_402656734 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656734
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656735: Call_PostCreateDBInstanceReadReplica_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656735.validator(path, query, header, formData, body, _)
  let scheme = call_402656735.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656735.makeUrl(scheme.get, call_402656735.host, call_402656735.base,
                                   call_402656735.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656735, uri, valid, _)

proc call*(call_402656736: Call_PostCreateDBInstanceReadReplica_402656714;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           Version: string = "2013-02-12"; Iops: int = 0;
           DBInstanceClass: string = ""; OptionGroupName: string = "";
           Action: string = "CreateDBInstanceReadReplica"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   PubliclyAccessible: bool
  ##   AvailabilityZone: string
  ##   Version: string (required)
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  var query_402656737 = newJObject()
  var formData_402656738 = newJObject()
  add(formData_402656738, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402656738, "Port", newJInt(Port))
  add(formData_402656738, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656738, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656737, "Version", newJString(Version))
  add(formData_402656738, "Iops", newJInt(Iops))
  add(formData_402656738, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656738, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656738, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656737, "Action", newJString(Action))
  add(formData_402656738, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402656736.call(nil, query_402656737, nil, formData_402656738,
                               nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_402656714(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_402656715, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_402656690 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstanceReadReplica_402656692(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_402656691(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   Port: JInt
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656693 = query.getOrDefault("PubliclyAccessible")
  valid_402656693 = validateParameter(valid_402656693, JBool, required = false,
                                      default = nil)
  if valid_402656693 != nil:
    section.add "PubliclyAccessible", valid_402656693
  var valid_402656694 = query.getOrDefault("OptionGroupName")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "OptionGroupName", valid_402656694
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656695 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656695 = validateParameter(valid_402656695, JString, required = true,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "DBInstanceIdentifier", valid_402656695
  var valid_402656696 = query.getOrDefault("Iops")
  valid_402656696 = validateParameter(valid_402656696, JInt, required = false,
                                      default = nil)
  if valid_402656696 != nil:
    section.add "Iops", valid_402656696
  var valid_402656697 = query.getOrDefault("AvailabilityZone")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "AvailabilityZone", valid_402656697
  var valid_402656698 = query.getOrDefault("Version")
  valid_402656698 = validateParameter(valid_402656698, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656698 != nil:
    section.add "Version", valid_402656698
  var valid_402656699 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656699 = validateParameter(valid_402656699, JBool, required = false,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656699
  var valid_402656700 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656700
  var valid_402656701 = query.getOrDefault("DBInstanceClass")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "DBInstanceClass", valid_402656701
  var valid_402656702 = query.getOrDefault("Port")
  valid_402656702 = validateParameter(valid_402656702, JInt, required = false,
                                      default = nil)
  if valid_402656702 != nil:
    section.add "Port", valid_402656702
  var valid_402656703 = query.getOrDefault("Action")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656703 != nil:
    section.add "Action", valid_402656703
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
  var valid_402656704 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Security-Token", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Signature")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Signature", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Algorithm", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Date")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Date", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-Credential")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-Credential", valid_402656709
  var valid_402656710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656710
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_GetCreateDBInstanceReadReplica_402656690;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_GetCreateDBInstanceReadReplica_402656690;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           Iops: int = 0; AvailabilityZone: string = "";
           Version: string = "2013-02-12";
           AutoMinorVersionUpgrade: bool = false; DBInstanceClass: string = "";
           Port: int = 0; Action: string = "CreateDBInstanceReadReplica"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   Port: int
  ##   Action: string (required)
  var query_402656713 = newJObject()
  add(query_402656713, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656713, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656713, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656713, "Iops", newJInt(Iops))
  add(query_402656713, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656713, "Version", newJString(Version))
  add(query_402656713, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656713, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402656713, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656713, "Port", newJInt(Port))
  add(query_402656713, "Action", newJString(Action))
  result = call_402656712.call(nil, query_402656713, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_402656690(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_402656691, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_402656692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_402656757 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBParameterGroup_402656759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_402656758(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656760 = query.getOrDefault("Version")
  valid_402656760 = validateParameter(valid_402656760, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656760 != nil:
    section.add "Version", valid_402656760
  var valid_402656761 = query.getOrDefault("Action")
  valid_402656761 = validateParameter(valid_402656761, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656761 != nil:
    section.add "Action", valid_402656761
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
  var valid_402656762 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Security-Token", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Signature")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Signature", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Algorithm", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Date")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Date", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Credential")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Credential", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656768
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402656769 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402656769 = validateParameter(valid_402656769, JString, required = true,
                                      default = nil)
  if valid_402656769 != nil:
    section.add "DBParameterGroupFamily", valid_402656769
  var valid_402656770 = formData.getOrDefault("DBParameterGroupName")
  valid_402656770 = validateParameter(valid_402656770, JString, required = true,
                                      default = nil)
  if valid_402656770 != nil:
    section.add "DBParameterGroupName", valid_402656770
  var valid_402656771 = formData.getOrDefault("Description")
  valid_402656771 = validateParameter(valid_402656771, JString, required = true,
                                      default = nil)
  if valid_402656771 != nil:
    section.add "Description", valid_402656771
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656772: Call_PostCreateDBParameterGroup_402656757;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656772.validator(path, query, header, formData, body, _)
  let scheme = call_402656772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656772.makeUrl(scheme.get, call_402656772.host, call_402656772.base,
                                   call_402656772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656772, uri, valid, _)

proc call*(call_402656773: Call_PostCreateDBParameterGroup_402656757;
           DBParameterGroupFamily: string; DBParameterGroupName: string;
           Description: string; Version: string = "2013-02-12";
           Action: string = "CreateDBParameterGroup"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  var query_402656774 = newJObject()
  var formData_402656775 = newJObject()
  add(formData_402656775, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402656774, "Version", newJString(Version))
  add(formData_402656775, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402656774, "Action", newJString(Action))
  add(formData_402656775, "Description", newJString(Description))
  result = call_402656773.call(nil, query_402656774, nil, formData_402656775,
                               nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_402656757(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_402656758, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_402656759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_402656739 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBParameterGroup_402656741(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_402656740(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString (required)
  ##   DBParameterGroupName: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Description` field"
  var valid_402656742 = query.getOrDefault("Description")
  valid_402656742 = validateParameter(valid_402656742, JString, required = true,
                                      default = nil)
  if valid_402656742 != nil:
    section.add "Description", valid_402656742
  var valid_402656743 = query.getOrDefault("DBParameterGroupName")
  valid_402656743 = validateParameter(valid_402656743, JString, required = true,
                                      default = nil)
  if valid_402656743 != nil:
    section.add "DBParameterGroupName", valid_402656743
  var valid_402656744 = query.getOrDefault("DBParameterGroupFamily")
  valid_402656744 = validateParameter(valid_402656744, JString, required = true,
                                      default = nil)
  if valid_402656744 != nil:
    section.add "DBParameterGroupFamily", valid_402656744
  var valid_402656745 = query.getOrDefault("Version")
  valid_402656745 = validateParameter(valid_402656745, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656745 != nil:
    section.add "Version", valid_402656745
  var valid_402656746 = query.getOrDefault("Action")
  valid_402656746 = validateParameter(valid_402656746, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656746 != nil:
    section.add "Action", valid_402656746
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
  var valid_402656747 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Security-Token", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Signature")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Signature", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Algorithm", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Date")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Date", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Credential")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Credential", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656754: Call_GetCreateDBParameterGroup_402656739;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656754.validator(path, query, header, formData, body, _)
  let scheme = call_402656754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656754.makeUrl(scheme.get, call_402656754.host, call_402656754.base,
                                   call_402656754.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656754, uri, valid, _)

proc call*(call_402656755: Call_GetCreateDBParameterGroup_402656739;
           Description: string; DBParameterGroupName: string;
           DBParameterGroupFamily: string; Version: string = "2013-02-12";
           Action: string = "CreateDBParameterGroup"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402656756 = newJObject()
  add(query_402656756, "Description", newJString(Description))
  add(query_402656756, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656756, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402656756, "Version", newJString(Version))
  add(query_402656756, "Action", newJString(Action))
  result = call_402656755.call(nil, query_402656756, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_402656739(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_402656740, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_402656741,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_402656793 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSecurityGroup_402656795(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_402656794(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656796 = query.getOrDefault("Version")
  valid_402656796 = validateParameter(valid_402656796, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656796 != nil:
    section.add "Version", valid_402656796
  var valid_402656797 = query.getOrDefault("Action")
  valid_402656797 = validateParameter(valid_402656797, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656797 != nil:
    section.add "Action", valid_402656797
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
  var valid_402656798 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Security-Token", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Signature")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Signature", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-Algorithm", valid_402656801
  var valid_402656802 = header.getOrDefault("X-Amz-Date")
  valid_402656802 = validateParameter(valid_402656802, JString,
                                      required = false, default = nil)
  if valid_402656802 != nil:
    section.add "X-Amz-Date", valid_402656802
  var valid_402656803 = header.getOrDefault("X-Amz-Credential")
  valid_402656803 = validateParameter(valid_402656803, JString,
                                      required = false, default = nil)
  if valid_402656803 != nil:
    section.add "X-Amz-Credential", valid_402656803
  var valid_402656804 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656804 = validateParameter(valid_402656804, JString,
                                      required = false, default = nil)
  if valid_402656804 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656804
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_402656805 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_402656805 = validateParameter(valid_402656805, JString, required = true,
                                      default = nil)
  if valid_402656805 != nil:
    section.add "DBSecurityGroupDescription", valid_402656805
  var valid_402656806 = formData.getOrDefault("DBSecurityGroupName")
  valid_402656806 = validateParameter(valid_402656806, JString, required = true,
                                      default = nil)
  if valid_402656806 != nil:
    section.add "DBSecurityGroupName", valid_402656806
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656807: Call_PostCreateDBSecurityGroup_402656793;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656807.validator(path, query, header, formData, body, _)
  let scheme = call_402656807.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656807.makeUrl(scheme.get, call_402656807.host, call_402656807.base,
                                   call_402656807.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656807, uri, valid, _)

proc call*(call_402656808: Call_PostCreateDBSecurityGroup_402656793;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Version: string = "2013-02-12";
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402656809 = newJObject()
  var formData_402656810 = newJObject()
  add(formData_402656810, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_402656809, "Version", newJString(Version))
  add(formData_402656810, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402656809, "Action", newJString(Action))
  result = call_402656808.call(nil, query_402656809, nil, formData_402656810,
                               nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_402656793(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_402656794, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_402656795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_402656776 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSecurityGroup_402656778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_402656777(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_402656779 = query.getOrDefault("DBSecurityGroupDescription")
  valid_402656779 = validateParameter(valid_402656779, JString, required = true,
                                      default = nil)
  if valid_402656779 != nil:
    section.add "DBSecurityGroupDescription", valid_402656779
  var valid_402656780 = query.getOrDefault("Version")
  valid_402656780 = validateParameter(valid_402656780, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656780 != nil:
    section.add "Version", valid_402656780
  var valid_402656781 = query.getOrDefault("Action")
  valid_402656781 = validateParameter(valid_402656781, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656781 != nil:
    section.add "Action", valid_402656781
  var valid_402656782 = query.getOrDefault("DBSecurityGroupName")
  valid_402656782 = validateParameter(valid_402656782, JString, required = true,
                                      default = nil)
  if valid_402656782 != nil:
    section.add "DBSecurityGroupName", valid_402656782
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
  var valid_402656783 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Security-Token", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-Signature")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-Signature", valid_402656784
  var valid_402656785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656785 = validateParameter(valid_402656785, JString,
                                      required = false, default = nil)
  if valid_402656785 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656785
  var valid_402656786 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "X-Amz-Algorithm", valid_402656786
  var valid_402656787 = header.getOrDefault("X-Amz-Date")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "X-Amz-Date", valid_402656787
  var valid_402656788 = header.getOrDefault("X-Amz-Credential")
  valid_402656788 = validateParameter(valid_402656788, JString,
                                      required = false, default = nil)
  if valid_402656788 != nil:
    section.add "X-Amz-Credential", valid_402656788
  var valid_402656789 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656789 = validateParameter(valid_402656789, JString,
                                      required = false, default = nil)
  if valid_402656789 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656790: Call_GetCreateDBSecurityGroup_402656776;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656790.validator(path, query, header, formData, body, _)
  let scheme = call_402656790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656790.makeUrl(scheme.get, call_402656790.host, call_402656790.base,
                                   call_402656790.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656790, uri, valid, _)

proc call*(call_402656791: Call_GetCreateDBSecurityGroup_402656776;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Version: string = "2013-02-12";
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402656792 = newJObject()
  add(query_402656792, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_402656792, "Version", newJString(Version))
  add(query_402656792, "Action", newJString(Action))
  add(query_402656792, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402656791.call(nil, query_402656792, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_402656776(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_402656777, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_402656778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_402656828 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSnapshot_402656830(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_402656829(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656831 = query.getOrDefault("Version")
  valid_402656831 = validateParameter(valid_402656831, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656831 != nil:
    section.add "Version", valid_402656831
  var valid_402656832 = query.getOrDefault("Action")
  valid_402656832 = validateParameter(valid_402656832, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656832 != nil:
    section.add "Action", valid_402656832
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
  var valid_402656833 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Security-Token", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Signature")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Signature", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Algorithm", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-Date")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-Date", valid_402656837
  var valid_402656838 = header.getOrDefault("X-Amz-Credential")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "X-Amz-Credential", valid_402656838
  var valid_402656839 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656839 = validateParameter(valid_402656839, JString,
                                      required = false, default = nil)
  if valid_402656839 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656839
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656840 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656840 = validateParameter(valid_402656840, JString, required = true,
                                      default = nil)
  if valid_402656840 != nil:
    section.add "DBInstanceIdentifier", valid_402656840
  var valid_402656841 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402656841 = validateParameter(valid_402656841, JString, required = true,
                                      default = nil)
  if valid_402656841 != nil:
    section.add "DBSnapshotIdentifier", valid_402656841
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656842: Call_PostCreateDBSnapshot_402656828;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656842.validator(path, query, header, formData, body, _)
  let scheme = call_402656842.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656842.makeUrl(scheme.get, call_402656842.host, call_402656842.base,
                                   call_402656842.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656842, uri, valid, _)

proc call*(call_402656843: Call_PostCreateDBSnapshot_402656828;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Version: string = "2013-02-12"; Action: string = "CreateDBSnapshot"): Recallable =
  ## postCreateDBSnapshot
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656844 = newJObject()
  var formData_402656845 = newJObject()
  add(query_402656844, "Version", newJString(Version))
  add(formData_402656845, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656845, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402656844, "Action", newJString(Action))
  result = call_402656843.call(nil, query_402656844, nil, formData_402656845,
                               nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_402656828(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_402656829, base: "/",
    makeUrl: url_PostCreateDBSnapshot_402656830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_402656811 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSnapshot_402656813(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_402656812(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656814 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656814 = validateParameter(valid_402656814, JString, required = true,
                                      default = nil)
  if valid_402656814 != nil:
    section.add "DBInstanceIdentifier", valid_402656814
  var valid_402656815 = query.getOrDefault("Version")
  valid_402656815 = validateParameter(valid_402656815, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656815 != nil:
    section.add "Version", valid_402656815
  var valid_402656816 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402656816 = validateParameter(valid_402656816, JString, required = true,
                                      default = nil)
  if valid_402656816 != nil:
    section.add "DBSnapshotIdentifier", valid_402656816
  var valid_402656817 = query.getOrDefault("Action")
  valid_402656817 = validateParameter(valid_402656817, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656817 != nil:
    section.add "Action", valid_402656817
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
  var valid_402656818 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656818 = validateParameter(valid_402656818, JString,
                                      required = false, default = nil)
  if valid_402656818 != nil:
    section.add "X-Amz-Security-Token", valid_402656818
  var valid_402656819 = header.getOrDefault("X-Amz-Signature")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "X-Amz-Signature", valid_402656819
  var valid_402656820 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656820 = validateParameter(valid_402656820, JString,
                                      required = false, default = nil)
  if valid_402656820 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656820
  var valid_402656821 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "X-Amz-Algorithm", valid_402656821
  var valid_402656822 = header.getOrDefault("X-Amz-Date")
  valid_402656822 = validateParameter(valid_402656822, JString,
                                      required = false, default = nil)
  if valid_402656822 != nil:
    section.add "X-Amz-Date", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Credential")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Credential", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656825: Call_GetCreateDBSnapshot_402656811;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656825.validator(path, query, header, formData, body, _)
  let scheme = call_402656825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656825.makeUrl(scheme.get, call_402656825.host, call_402656825.base,
                                   call_402656825.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656825, uri, valid, _)

proc call*(call_402656826: Call_GetCreateDBSnapshot_402656811;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Version: string = "2013-02-12"; Action: string = "CreateDBSnapshot"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656827 = newJObject()
  add(query_402656827, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656827, "Version", newJString(Version))
  add(query_402656827, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402656827, "Action", newJString(Action))
  result = call_402656826.call(nil, query_402656827, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_402656811(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_402656812, base: "/",
    makeUrl: url_GetCreateDBSnapshot_402656813,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_402656864 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSubnetGroup_402656866(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_402656865(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656867 = query.getOrDefault("Version")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656867 != nil:
    section.add "Version", valid_402656867
  var valid_402656868 = query.getOrDefault("Action")
  valid_402656868 = validateParameter(valid_402656868, JString, required = true, default = newJString(
      "CreateDBSubnetGroup"))
  if valid_402656868 != nil:
    section.add "Action", valid_402656868
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
  var valid_402656869 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656869 = validateParameter(valid_402656869, JString,
                                      required = false, default = nil)
  if valid_402656869 != nil:
    section.add "X-Amz-Security-Token", valid_402656869
  var valid_402656870 = header.getOrDefault("X-Amz-Signature")
  valid_402656870 = validateParameter(valid_402656870, JString,
                                      required = false, default = nil)
  if valid_402656870 != nil:
    section.add "X-Amz-Signature", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Algorithm", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Date")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Date", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Credential")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Credential", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656875
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402656876 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656876 = validateParameter(valid_402656876, JString, required = true,
                                      default = nil)
  if valid_402656876 != nil:
    section.add "DBSubnetGroupName", valid_402656876
  var valid_402656877 = formData.getOrDefault("SubnetIds")
  valid_402656877 = validateParameter(valid_402656877, JArray, required = true,
                                      default = nil)
  if valid_402656877 != nil:
    section.add "SubnetIds", valid_402656877
  var valid_402656878 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402656878 = validateParameter(valid_402656878, JString, required = true,
                                      default = nil)
  if valid_402656878 != nil:
    section.add "DBSubnetGroupDescription", valid_402656878
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_PostCreateDBSubnetGroup_402656864;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_PostCreateDBSubnetGroup_402656864;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string; Version: string = "2013-02-12";
           Action: string = "CreateDBSubnetGroup"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  var query_402656881 = newJObject()
  var formData_402656882 = newJObject()
  add(formData_402656882, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656881, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402656882.add "SubnetIds", SubnetIds
  add(formData_402656882, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656881, "Action", newJString(Action))
  result = call_402656880.call(nil, query_402656881, nil, formData_402656882,
                               nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_402656864(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_402656865, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_402656866,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_402656846 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSubnetGroup_402656848(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_402656847(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSubnetGroupName: JString (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   Version: JString (required)
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402656849 = query.getOrDefault("DBSubnetGroupName")
  valid_402656849 = validateParameter(valid_402656849, JString, required = true,
                                      default = nil)
  if valid_402656849 != nil:
    section.add "DBSubnetGroupName", valid_402656849
  var valid_402656850 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402656850 = validateParameter(valid_402656850, JString, required = true,
                                      default = nil)
  if valid_402656850 != nil:
    section.add "DBSubnetGroupDescription", valid_402656850
  var valid_402656851 = query.getOrDefault("Version")
  valid_402656851 = validateParameter(valid_402656851, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656851 != nil:
    section.add "Version", valid_402656851
  var valid_402656852 = query.getOrDefault("SubnetIds")
  valid_402656852 = validateParameter(valid_402656852, JArray, required = true,
                                      default = nil)
  if valid_402656852 != nil:
    section.add "SubnetIds", valid_402656852
  var valid_402656853 = query.getOrDefault("Action")
  valid_402656853 = validateParameter(valid_402656853, JString, required = true, default = newJString(
      "CreateDBSubnetGroup"))
  if valid_402656853 != nil:
    section.add "Action", valid_402656853
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
  var valid_402656854 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656854 = validateParameter(valid_402656854, JString,
                                      required = false, default = nil)
  if valid_402656854 != nil:
    section.add "X-Amz-Security-Token", valid_402656854
  var valid_402656855 = header.getOrDefault("X-Amz-Signature")
  valid_402656855 = validateParameter(valid_402656855, JString,
                                      required = false, default = nil)
  if valid_402656855 != nil:
    section.add "X-Amz-Signature", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Algorithm", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Date")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Date", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Credential")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Credential", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656860
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656861: Call_GetCreateDBSubnetGroup_402656846;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656861.validator(path, query, header, formData, body, _)
  let scheme = call_402656861.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656861.makeUrl(scheme.get, call_402656861.host, call_402656861.base,
                                   call_402656861.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656861, uri, valid, _)

proc call*(call_402656862: Call_GetCreateDBSubnetGroup_402656846;
           DBSubnetGroupName: string; DBSubnetGroupDescription: string;
           SubnetIds: JsonNode; Version: string = "2013-02-12";
           Action: string = "CreateDBSubnetGroup"): Recallable =
  ## getCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402656863 = newJObject()
  add(query_402656863, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656863, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656863, "Version", newJString(Version))
  if SubnetIds != nil:
    query_402656863.add "SubnetIds", SubnetIds
  add(query_402656863, "Action", newJString(Action))
  result = call_402656862.call(nil, query_402656863, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_402656846(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_402656847, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_402656848,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_402656904 = ref object of OpenApiRestCall_402656035
proc url_PostCreateEventSubscription_402656906(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_402656905(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656907 = query.getOrDefault("Version")
  valid_402656907 = validateParameter(valid_402656907, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656907 != nil:
    section.add "Version", valid_402656907
  var valid_402656908 = query.getOrDefault("Action")
  valid_402656908 = validateParameter(valid_402656908, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402656908 != nil:
    section.add "Action", valid_402656908
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
  var valid_402656909 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656909 = validateParameter(valid_402656909, JString,
                                      required = false, default = nil)
  if valid_402656909 != nil:
    section.add "X-Amz-Security-Token", valid_402656909
  var valid_402656910 = header.getOrDefault("X-Amz-Signature")
  valid_402656910 = validateParameter(valid_402656910, JString,
                                      required = false, default = nil)
  if valid_402656910 != nil:
    section.add "X-Amz-Signature", valid_402656910
  var valid_402656911 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Algorithm", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Date")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Date", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Credential")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Credential", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656915
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  var valid_402656916 = formData.getOrDefault("SourceIds")
  valid_402656916 = validateParameter(valid_402656916, JArray, required = false,
                                      default = nil)
  if valid_402656916 != nil:
    section.add "SourceIds", valid_402656916
  var valid_402656917 = formData.getOrDefault("SourceType")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "SourceType", valid_402656917
  var valid_402656918 = formData.getOrDefault("Enabled")
  valid_402656918 = validateParameter(valid_402656918, JBool, required = false,
                                      default = nil)
  if valid_402656918 != nil:
    section.add "Enabled", valid_402656918
  var valid_402656919 = formData.getOrDefault("EventCategories")
  valid_402656919 = validateParameter(valid_402656919, JArray, required = false,
                                      default = nil)
  if valid_402656919 != nil:
    section.add "EventCategories", valid_402656919
  assert formData != nil,
         "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_402656920 = formData.getOrDefault("SnsTopicArn")
  valid_402656920 = validateParameter(valid_402656920, JString, required = true,
                                      default = nil)
  if valid_402656920 != nil:
    section.add "SnsTopicArn", valid_402656920
  var valid_402656921 = formData.getOrDefault("SubscriptionName")
  valid_402656921 = validateParameter(valid_402656921, JString, required = true,
                                      default = nil)
  if valid_402656921 != nil:
    section.add "SubscriptionName", valid_402656921
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656922: Call_PostCreateEventSubscription_402656904;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656922.validator(path, query, header, formData, body, _)
  let scheme = call_402656922.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656922.makeUrl(scheme.get, call_402656922.host, call_402656922.base,
                                   call_402656922.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656922, uri, valid, _)

proc call*(call_402656923: Call_PostCreateEventSubscription_402656904;
           SnsTopicArn: string; SubscriptionName: string;
           SourceIds: JsonNode = nil; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2013-02-12";
           Action: string = "CreateEventSubscription"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SourceType: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SnsTopicArn: string (required)
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402656924 = newJObject()
  var formData_402656925 = newJObject()
  if SourceIds != nil:
    formData_402656925.add "SourceIds", SourceIds
  add(formData_402656925, "SourceType", newJString(SourceType))
  add(formData_402656925, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402656925.add "EventCategories", EventCategories
  add(query_402656924, "Version", newJString(Version))
  add(formData_402656925, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402656924, "Action", newJString(Action))
  add(formData_402656925, "SubscriptionName", newJString(SubscriptionName))
  result = call_402656923.call(nil, query_402656924, nil, formData_402656925,
                               nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_402656904(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_402656905, base: "/",
    makeUrl: url_PostCreateEventSubscription_402656906,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_402656883 = ref object of OpenApiRestCall_402656035
proc url_GetCreateEventSubscription_402656885(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_402656884(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SnsTopicArn: JString (required)
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   Version: JString (required)
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   SourceIds: JArray
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `SnsTopicArn` field"
  var valid_402656886 = query.getOrDefault("SnsTopicArn")
  valid_402656886 = validateParameter(valid_402656886, JString, required = true,
                                      default = nil)
  if valid_402656886 != nil:
    section.add "SnsTopicArn", valid_402656886
  var valid_402656887 = query.getOrDefault("Enabled")
  valid_402656887 = validateParameter(valid_402656887, JBool, required = false,
                                      default = nil)
  if valid_402656887 != nil:
    section.add "Enabled", valid_402656887
  var valid_402656888 = query.getOrDefault("EventCategories")
  valid_402656888 = validateParameter(valid_402656888, JArray, required = false,
                                      default = nil)
  if valid_402656888 != nil:
    section.add "EventCategories", valid_402656888
  var valid_402656889 = query.getOrDefault("Version")
  valid_402656889 = validateParameter(valid_402656889, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656889 != nil:
    section.add "Version", valid_402656889
  var valid_402656890 = query.getOrDefault("SubscriptionName")
  valid_402656890 = validateParameter(valid_402656890, JString, required = true,
                                      default = nil)
  if valid_402656890 != nil:
    section.add "SubscriptionName", valid_402656890
  var valid_402656891 = query.getOrDefault("SourceType")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "SourceType", valid_402656891
  var valid_402656892 = query.getOrDefault("SourceIds")
  valid_402656892 = validateParameter(valid_402656892, JArray, required = false,
                                      default = nil)
  if valid_402656892 != nil:
    section.add "SourceIds", valid_402656892
  var valid_402656893 = query.getOrDefault("Action")
  valid_402656893 = validateParameter(valid_402656893, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402656893 != nil:
    section.add "Action", valid_402656893
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
  var valid_402656894 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656894 = validateParameter(valid_402656894, JString,
                                      required = false, default = nil)
  if valid_402656894 != nil:
    section.add "X-Amz-Security-Token", valid_402656894
  var valid_402656895 = header.getOrDefault("X-Amz-Signature")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Signature", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Algorithm", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Date")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Date", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Credential")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Credential", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656900
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656901: Call_GetCreateEventSubscription_402656883;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656901.validator(path, query, header, formData, body, _)
  let scheme = call_402656901.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656901.makeUrl(scheme.get, call_402656901.host, call_402656901.base,
                                   call_402656901.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656901, uri, valid, _)

proc call*(call_402656902: Call_GetCreateEventSubscription_402656883;
           SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
           EventCategories: JsonNode = nil; Version: string = "2013-02-12";
           SourceType: string = ""; SourceIds: JsonNode = nil;
           Action: string = "CreateEventSubscription"): Recallable =
  ## getCreateEventSubscription
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Action: string (required)
  var query_402656903 = newJObject()
  add(query_402656903, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402656903, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402656903.add "EventCategories", EventCategories
  add(query_402656903, "Version", newJString(Version))
  add(query_402656903, "SubscriptionName", newJString(SubscriptionName))
  add(query_402656903, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_402656903.add "SourceIds", SourceIds
  add(query_402656903, "Action", newJString(Action))
  result = call_402656902.call(nil, query_402656903, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_402656883(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_402656884, base: "/",
    makeUrl: url_GetCreateEventSubscription_402656885,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_402656945 = ref object of OpenApiRestCall_402656035
proc url_PostCreateOptionGroup_402656947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_402656946(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656948 = query.getOrDefault("Version")
  valid_402656948 = validateParameter(valid_402656948, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656948 != nil:
    section.add "Version", valid_402656948
  var valid_402656949 = query.getOrDefault("Action")
  valid_402656949 = validateParameter(valid_402656949, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402656949 != nil:
    section.add "Action", valid_402656949
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
  var valid_402656950 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Security-Token", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Signature")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Signature", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656952
  var valid_402656953 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656953 = validateParameter(valid_402656953, JString,
                                      required = false, default = nil)
  if valid_402656953 != nil:
    section.add "X-Amz-Algorithm", valid_402656953
  var valid_402656954 = header.getOrDefault("X-Amz-Date")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Date", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Credential")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Credential", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656956
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   OptionGroupName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_402656957 = formData.getOrDefault("OptionGroupDescription")
  valid_402656957 = validateParameter(valid_402656957, JString, required = true,
                                      default = nil)
  if valid_402656957 != nil:
    section.add "OptionGroupDescription", valid_402656957
  var valid_402656958 = formData.getOrDefault("EngineName")
  valid_402656958 = validateParameter(valid_402656958, JString, required = true,
                                      default = nil)
  if valid_402656958 != nil:
    section.add "EngineName", valid_402656958
  var valid_402656959 = formData.getOrDefault("OptionGroupName")
  valid_402656959 = validateParameter(valid_402656959, JString, required = true,
                                      default = nil)
  if valid_402656959 != nil:
    section.add "OptionGroupName", valid_402656959
  var valid_402656960 = formData.getOrDefault("MajorEngineVersion")
  valid_402656960 = validateParameter(valid_402656960, JString, required = true,
                                      default = nil)
  if valid_402656960 != nil:
    section.add "MajorEngineVersion", valid_402656960
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656961: Call_PostCreateOptionGroup_402656945;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656961.validator(path, query, header, formData, body, _)
  let scheme = call_402656961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656961.makeUrl(scheme.get, call_402656961.host, call_402656961.base,
                                   call_402656961.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656961, uri, valid, _)

proc call*(call_402656962: Call_PostCreateOptionGroup_402656945;
           OptionGroupDescription: string; EngineName: string;
           OptionGroupName: string; MajorEngineVersion: string;
           Version: string = "2013-02-12"; Action: string = "CreateOptionGroup"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   MajorEngineVersion: string (required)
  var query_402656963 = newJObject()
  var formData_402656964 = newJObject()
  add(formData_402656964, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_402656964, "EngineName", newJString(EngineName))
  add(query_402656963, "Version", newJString(Version))
  add(formData_402656964, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656963, "Action", newJString(Action))
  add(formData_402656964, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402656962.call(nil, query_402656963, nil, formData_402656964,
                               nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_402656945(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_402656946, base: "/",
    makeUrl: url_PostCreateOptionGroup_402656947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_402656926 = ref object of OpenApiRestCall_402656035
proc url_GetCreateOptionGroup_402656928(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_402656927(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402656929 = query.getOrDefault("OptionGroupName")
  valid_402656929 = validateParameter(valid_402656929, JString, required = true,
                                      default = nil)
  if valid_402656929 != nil:
    section.add "OptionGroupName", valid_402656929
  var valid_402656930 = query.getOrDefault("Version")
  valid_402656930 = validateParameter(valid_402656930, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656930 != nil:
    section.add "Version", valid_402656930
  var valid_402656931 = query.getOrDefault("Action")
  valid_402656931 = validateParameter(valid_402656931, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402656931 != nil:
    section.add "Action", valid_402656931
  var valid_402656932 = query.getOrDefault("EngineName")
  valid_402656932 = validateParameter(valid_402656932, JString, required = true,
                                      default = nil)
  if valid_402656932 != nil:
    section.add "EngineName", valid_402656932
  var valid_402656933 = query.getOrDefault("MajorEngineVersion")
  valid_402656933 = validateParameter(valid_402656933, JString, required = true,
                                      default = nil)
  if valid_402656933 != nil:
    section.add "MajorEngineVersion", valid_402656933
  var valid_402656934 = query.getOrDefault("OptionGroupDescription")
  valid_402656934 = validateParameter(valid_402656934, JString, required = true,
                                      default = nil)
  if valid_402656934 != nil:
    section.add "OptionGroupDescription", valid_402656934
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
  var valid_402656935 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Security-Token", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Signature")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Signature", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-Algorithm", valid_402656938
  var valid_402656939 = header.getOrDefault("X-Amz-Date")
  valid_402656939 = validateParameter(valid_402656939, JString,
                                      required = false, default = nil)
  if valid_402656939 != nil:
    section.add "X-Amz-Date", valid_402656939
  var valid_402656940 = header.getOrDefault("X-Amz-Credential")
  valid_402656940 = validateParameter(valid_402656940, JString,
                                      required = false, default = nil)
  if valid_402656940 != nil:
    section.add "X-Amz-Credential", valid_402656940
  var valid_402656941 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656941 = validateParameter(valid_402656941, JString,
                                      required = false, default = nil)
  if valid_402656941 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656941
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656942: Call_GetCreateOptionGroup_402656926;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656942.validator(path, query, header, formData, body, _)
  let scheme = call_402656942.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656942.makeUrl(scheme.get, call_402656942.host, call_402656942.base,
                                   call_402656942.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656942, uri, valid, _)

proc call*(call_402656943: Call_GetCreateOptionGroup_402656926;
           OptionGroupName: string; EngineName: string;
           MajorEngineVersion: string; OptionGroupDescription: string;
           Version: string = "2013-02-12"; Action: string = "CreateOptionGroup"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupDescription: string (required)
  var query_402656944 = newJObject()
  add(query_402656944, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656944, "Version", newJString(Version))
  add(query_402656944, "Action", newJString(Action))
  add(query_402656944, "EngineName", newJString(EngineName))
  add(query_402656944, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_402656944, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  result = call_402656943.call(nil, query_402656944, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_402656926(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_402656927, base: "/",
    makeUrl: url_GetCreateOptionGroup_402656928,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_402656983 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBInstance_402656985(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_402656984(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656986 = query.getOrDefault("Version")
  valid_402656986 = validateParameter(valid_402656986, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656986 != nil:
    section.add "Version", valid_402656986
  var valid_402656987 = query.getOrDefault("Action")
  valid_402656987 = validateParameter(valid_402656987, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
  if valid_402656987 != nil:
    section.add "Action", valid_402656987
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
  var valid_402656988 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656988 = validateParameter(valid_402656988, JString,
                                      required = false, default = nil)
  if valid_402656988 != nil:
    section.add "X-Amz-Security-Token", valid_402656988
  var valid_402656989 = header.getOrDefault("X-Amz-Signature")
  valid_402656989 = validateParameter(valid_402656989, JString,
                                      required = false, default = nil)
  if valid_402656989 != nil:
    section.add "X-Amz-Signature", valid_402656989
  var valid_402656990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Algorithm", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Date")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Date", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Credential")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Credential", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656994
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656995 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656995 = validateParameter(valid_402656995, JString, required = true,
                                      default = nil)
  if valid_402656995 != nil:
    section.add "DBInstanceIdentifier", valid_402656995
  var valid_402656996 = formData.getOrDefault("SkipFinalSnapshot")
  valid_402656996 = validateParameter(valid_402656996, JBool, required = false,
                                      default = nil)
  if valid_402656996 != nil:
    section.add "SkipFinalSnapshot", valid_402656996
  var valid_402656997 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402656997
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656998: Call_PostDeleteDBInstance_402656983;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656998.validator(path, query, header, formData, body, _)
  let scheme = call_402656998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656998.makeUrl(scheme.get, call_402656998.host, call_402656998.base,
                                   call_402656998.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656998, uri, valid, _)

proc call*(call_402656999: Call_PostDeleteDBInstance_402656983;
           DBInstanceIdentifier: string; Version: string = "2013-02-12";
           SkipFinalSnapshot: bool = false; Action: string = "DeleteDBInstance";
           FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## postDeleteDBInstance
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_402657000 = newJObject()
  var formData_402657001 = newJObject()
  add(query_402657000, "Version", newJString(Version))
  add(formData_402657001, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657001, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_402657000, "Action", newJString(Action))
  add(formData_402657001, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_402656999.call(nil, query_402657000, nil, formData_402657001,
                               nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_402656983(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_402656984, base: "/",
    makeUrl: url_PostDeleteDBInstance_402656985,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_402656965 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBInstance_402656967(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_402656966(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656968 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656968 = validateParameter(valid_402656968, JString, required = true,
                                      default = nil)
  if valid_402656968 != nil:
    section.add "DBInstanceIdentifier", valid_402656968
  var valid_402656969 = query.getOrDefault("Version")
  valid_402656969 = validateParameter(valid_402656969, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402656969 != nil:
    section.add "Version", valid_402656969
  var valid_402656970 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402656970
  var valid_402656971 = query.getOrDefault("Action")
  valid_402656971 = validateParameter(valid_402656971, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
  if valid_402656971 != nil:
    section.add "Action", valid_402656971
  var valid_402656972 = query.getOrDefault("SkipFinalSnapshot")
  valid_402656972 = validateParameter(valid_402656972, JBool, required = false,
                                      default = nil)
  if valid_402656972 != nil:
    section.add "SkipFinalSnapshot", valid_402656972
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
  var valid_402656973 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Security-Token", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Signature")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Signature", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Algorithm", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Date")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Date", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Credential")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Credential", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656979
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656980: Call_GetDeleteDBInstance_402656965;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656980.validator(path, query, header, formData, body, _)
  let scheme = call_402656980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656980.makeUrl(scheme.get, call_402656980.host, call_402656980.base,
                                   call_402656980.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656980, uri, valid, _)

proc call*(call_402656981: Call_GetDeleteDBInstance_402656965;
           DBInstanceIdentifier: string; Version: string = "2013-02-12";
           FinalDBSnapshotIdentifier: string = "";
           Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  var query_402656982 = newJObject()
  add(query_402656982, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656982, "Version", newJString(Version))
  add(query_402656982, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_402656982, "Action", newJString(Action))
  add(query_402656982, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_402656981.call(nil, query_402656982, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_402656965(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_402656966, base: "/",
    makeUrl: url_GetDeleteDBInstance_402656967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_402657018 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBParameterGroup_402657020(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_402657019(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657021 = query.getOrDefault("Version")
  valid_402657021 = validateParameter(valid_402657021, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657021 != nil:
    section.add "Version", valid_402657021
  var valid_402657022 = query.getOrDefault("Action")
  valid_402657022 = validateParameter(valid_402657022, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657022 != nil:
    section.add "Action", valid_402657022
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
  var valid_402657023 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Security-Token", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Signature")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Signature", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Algorithm", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Date")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Date", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Credential")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Credential", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657029
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657030 = formData.getOrDefault("DBParameterGroupName")
  valid_402657030 = validateParameter(valid_402657030, JString, required = true,
                                      default = nil)
  if valid_402657030 != nil:
    section.add "DBParameterGroupName", valid_402657030
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657031: Call_PostDeleteDBParameterGroup_402657018;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657031.validator(path, query, header, formData, body, _)
  let scheme = call_402657031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657031.makeUrl(scheme.get, call_402657031.host, call_402657031.base,
                                   call_402657031.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657031, uri, valid, _)

proc call*(call_402657032: Call_PostDeleteDBParameterGroup_402657018;
           DBParameterGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## postDeleteDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  var query_402657033 = newJObject()
  var formData_402657034 = newJObject()
  add(query_402657033, "Version", newJString(Version))
  add(formData_402657034, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402657033, "Action", newJString(Action))
  result = call_402657032.call(nil, query_402657033, nil, formData_402657034,
                               nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_402657018(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_402657019, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_402657020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_402657002 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBParameterGroup_402657004(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_402657003(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657005 = query.getOrDefault("DBParameterGroupName")
  valid_402657005 = validateParameter(valid_402657005, JString, required = true,
                                      default = nil)
  if valid_402657005 != nil:
    section.add "DBParameterGroupName", valid_402657005
  var valid_402657006 = query.getOrDefault("Version")
  valid_402657006 = validateParameter(valid_402657006, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657006 != nil:
    section.add "Version", valid_402657006
  var valid_402657007 = query.getOrDefault("Action")
  valid_402657007 = validateParameter(valid_402657007, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657007 != nil:
    section.add "Action", valid_402657007
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
  var valid_402657008 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Security-Token", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Signature")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Signature", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Algorithm", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-Date")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Date", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Credential")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Credential", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657014
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657015: Call_GetDeleteDBParameterGroup_402657002;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657015.validator(path, query, header, formData, body, _)
  let scheme = call_402657015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657015.makeUrl(scheme.get, call_402657015.host, call_402657015.base,
                                   call_402657015.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657015, uri, valid, _)

proc call*(call_402657016: Call_GetDeleteDBParameterGroup_402657002;
           DBParameterGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657017 = newJObject()
  add(query_402657017, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657017, "Version", newJString(Version))
  add(query_402657017, "Action", newJString(Action))
  result = call_402657016.call(nil, query_402657017, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_402657002(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_402657003, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_402657004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_402657051 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSecurityGroup_402657053(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_402657052(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657054 = query.getOrDefault("Version")
  valid_402657054 = validateParameter(valid_402657054, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657054 != nil:
    section.add "Version", valid_402657054
  var valid_402657055 = query.getOrDefault("Action")
  valid_402657055 = validateParameter(valid_402657055, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657055 != nil:
    section.add "Action", valid_402657055
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
  var valid_402657056 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Security-Token", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Signature")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Signature", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Algorithm", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Date")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Date", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-Credential")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Credential", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657062
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402657063 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657063 = validateParameter(valid_402657063, JString, required = true,
                                      default = nil)
  if valid_402657063 != nil:
    section.add "DBSecurityGroupName", valid_402657063
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657064: Call_PostDeleteDBSecurityGroup_402657051;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657064.validator(path, query, header, formData, body, _)
  let scheme = call_402657064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657064.makeUrl(scheme.get, call_402657064.host, call_402657064.base,
                                   call_402657064.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657064, uri, valid, _)

proc call*(call_402657065: Call_PostDeleteDBSecurityGroup_402657051;
           DBSecurityGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402657066 = newJObject()
  var formData_402657067 = newJObject()
  add(query_402657066, "Version", newJString(Version))
  add(formData_402657067, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402657066, "Action", newJString(Action))
  result = call_402657065.call(nil, query_402657066, nil, formData_402657067,
                               nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_402657051(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_402657052, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_402657053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_402657035 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSecurityGroup_402657037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_402657036(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  var valid_402657038 = query.getOrDefault("Version")
  valid_402657038 = validateParameter(valid_402657038, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657038 != nil:
    section.add "Version", valid_402657038
  var valid_402657039 = query.getOrDefault("Action")
  valid_402657039 = validateParameter(valid_402657039, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657039 != nil:
    section.add "Action", valid_402657039
  var valid_402657040 = query.getOrDefault("DBSecurityGroupName")
  valid_402657040 = validateParameter(valid_402657040, JString, required = true,
                                      default = nil)
  if valid_402657040 != nil:
    section.add "DBSecurityGroupName", valid_402657040
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
  var valid_402657041 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Security-Token", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Signature")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Signature", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Algorithm", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Date")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Date", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Credential")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Credential", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657048: Call_GetDeleteDBSecurityGroup_402657035;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657048.validator(path, query, header, formData, body, _)
  let scheme = call_402657048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657048.makeUrl(scheme.get, call_402657048.host, call_402657048.base,
                                   call_402657048.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657048, uri, valid, _)

proc call*(call_402657049: Call_GetDeleteDBSecurityGroup_402657035;
           DBSecurityGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402657050 = newJObject()
  add(query_402657050, "Version", newJString(Version))
  add(query_402657050, "Action", newJString(Action))
  add(query_402657050, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657049.call(nil, query_402657050, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_402657035(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_402657036, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_402657037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_402657084 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSnapshot_402657086(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_402657085(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657087 = query.getOrDefault("Version")
  valid_402657087 = validateParameter(valid_402657087, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657087 != nil:
    section.add "Version", valid_402657087
  var valid_402657088 = query.getOrDefault("Action")
  valid_402657088 = validateParameter(valid_402657088, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657088 != nil:
    section.add "Action", valid_402657088
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
  var valid_402657089 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Security-Token", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-Signature")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-Signature", valid_402657090
  var valid_402657091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657091 = validateParameter(valid_402657091, JString,
                                      required = false, default = nil)
  if valid_402657091 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657091
  var valid_402657092 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657092 = validateParameter(valid_402657092, JString,
                                      required = false, default = nil)
  if valid_402657092 != nil:
    section.add "X-Amz-Algorithm", valid_402657092
  var valid_402657093 = header.getOrDefault("X-Amz-Date")
  valid_402657093 = validateParameter(valid_402657093, JString,
                                      required = false, default = nil)
  if valid_402657093 != nil:
    section.add "X-Amz-Date", valid_402657093
  var valid_402657094 = header.getOrDefault("X-Amz-Credential")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Credential", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657095
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_402657096 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657096 = validateParameter(valid_402657096, JString, required = true,
                                      default = nil)
  if valid_402657096 != nil:
    section.add "DBSnapshotIdentifier", valid_402657096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657097: Call_PostDeleteDBSnapshot_402657084;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657097.validator(path, query, header, formData, body, _)
  let scheme = call_402657097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657097.makeUrl(scheme.get, call_402657097.host, call_402657097.base,
                                   call_402657097.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657097, uri, valid, _)

proc call*(call_402657098: Call_PostDeleteDBSnapshot_402657084;
           DBSnapshotIdentifier: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## postDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657099 = newJObject()
  var formData_402657100 = newJObject()
  add(query_402657099, "Version", newJString(Version))
  add(formData_402657100, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402657099, "Action", newJString(Action))
  result = call_402657098.call(nil, query_402657099, nil, formData_402657100,
                               nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_402657084(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_402657085, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_402657086,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_402657068 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSnapshot_402657070(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_402657069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657071 = query.getOrDefault("Version")
  valid_402657071 = validateParameter(valid_402657071, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657071 != nil:
    section.add "Version", valid_402657071
  var valid_402657072 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657072 = validateParameter(valid_402657072, JString, required = true,
                                      default = nil)
  if valid_402657072 != nil:
    section.add "DBSnapshotIdentifier", valid_402657072
  var valid_402657073 = query.getOrDefault("Action")
  valid_402657073 = validateParameter(valid_402657073, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657073 != nil:
    section.add "Action", valid_402657073
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
  var valid_402657074 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Security-Token", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-Signature")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-Signature", valid_402657075
  var valid_402657076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Algorithm", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Date")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Date", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Credential")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Credential", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657080
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657081: Call_GetDeleteDBSnapshot_402657068;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657081.validator(path, query, header, formData, body, _)
  let scheme = call_402657081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657081.makeUrl(scheme.get, call_402657081.host, call_402657081.base,
                                   call_402657081.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657081, uri, valid, _)

proc call*(call_402657082: Call_GetDeleteDBSnapshot_402657068;
           DBSnapshotIdentifier: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## getDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657083 = newJObject()
  add(query_402657083, "Version", newJString(Version))
  add(query_402657083, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657083, "Action", newJString(Action))
  result = call_402657082.call(nil, query_402657083, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_402657068(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_402657069, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_402657070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_402657117 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSubnetGroup_402657119(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_402657118(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657120 = query.getOrDefault("Version")
  valid_402657120 = validateParameter(valid_402657120, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657120 != nil:
    section.add "Version", valid_402657120
  var valid_402657121 = query.getOrDefault("Action")
  valid_402657121 = validateParameter(valid_402657121, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657121 != nil:
    section.add "Action", valid_402657121
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
  var valid_402657122 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657122 = validateParameter(valid_402657122, JString,
                                      required = false, default = nil)
  if valid_402657122 != nil:
    section.add "X-Amz-Security-Token", valid_402657122
  var valid_402657123 = header.getOrDefault("X-Amz-Signature")
  valid_402657123 = validateParameter(valid_402657123, JString,
                                      required = false, default = nil)
  if valid_402657123 != nil:
    section.add "X-Amz-Signature", valid_402657123
  var valid_402657124 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657124 = validateParameter(valid_402657124, JString,
                                      required = false, default = nil)
  if valid_402657124 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657124
  var valid_402657125 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657125 = validateParameter(valid_402657125, JString,
                                      required = false, default = nil)
  if valid_402657125 != nil:
    section.add "X-Amz-Algorithm", valid_402657125
  var valid_402657126 = header.getOrDefault("X-Amz-Date")
  valid_402657126 = validateParameter(valid_402657126, JString,
                                      required = false, default = nil)
  if valid_402657126 != nil:
    section.add "X-Amz-Date", valid_402657126
  var valid_402657127 = header.getOrDefault("X-Amz-Credential")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Credential", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657128
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402657129 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657129 = validateParameter(valid_402657129, JString, required = true,
                                      default = nil)
  if valid_402657129 != nil:
    section.add "DBSubnetGroupName", valid_402657129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657130: Call_PostDeleteDBSubnetGroup_402657117;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657130.validator(path, query, header, formData, body, _)
  let scheme = call_402657130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657130.makeUrl(scheme.get, call_402657130.host, call_402657130.base,
                                   call_402657130.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657130, uri, valid, _)

proc call*(call_402657131: Call_PostDeleteDBSubnetGroup_402657117;
           DBSubnetGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657132 = newJObject()
  var formData_402657133 = newJObject()
  add(formData_402657133, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657132, "Version", newJString(Version))
  add(query_402657132, "Action", newJString(Action))
  result = call_402657131.call(nil, query_402657132, nil, formData_402657133,
                               nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_402657117(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_402657118, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_402657119,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_402657101 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSubnetGroup_402657103(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_402657102(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402657104 = query.getOrDefault("DBSubnetGroupName")
  valid_402657104 = validateParameter(valid_402657104, JString, required = true,
                                      default = nil)
  if valid_402657104 != nil:
    section.add "DBSubnetGroupName", valid_402657104
  var valid_402657105 = query.getOrDefault("Version")
  valid_402657105 = validateParameter(valid_402657105, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657105 != nil:
    section.add "Version", valid_402657105
  var valid_402657106 = query.getOrDefault("Action")
  valid_402657106 = validateParameter(valid_402657106, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657106 != nil:
    section.add "Action", valid_402657106
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
  var valid_402657107 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657107 = validateParameter(valid_402657107, JString,
                                      required = false, default = nil)
  if valid_402657107 != nil:
    section.add "X-Amz-Security-Token", valid_402657107
  var valid_402657108 = header.getOrDefault("X-Amz-Signature")
  valid_402657108 = validateParameter(valid_402657108, JString,
                                      required = false, default = nil)
  if valid_402657108 != nil:
    section.add "X-Amz-Signature", valid_402657108
  var valid_402657109 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Algorithm", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Date")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Date", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Credential")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Credential", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657113
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657114: Call_GetDeleteDBSubnetGroup_402657101;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657114.validator(path, query, header, formData, body, _)
  let scheme = call_402657114.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657114.makeUrl(scheme.get, call_402657114.host, call_402657114.base,
                                   call_402657114.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657114, uri, valid, _)

proc call*(call_402657115: Call_GetDeleteDBSubnetGroup_402657101;
           DBSubnetGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657116 = newJObject()
  add(query_402657116, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657116, "Version", newJString(Version))
  add(query_402657116, "Action", newJString(Action))
  result = call_402657115.call(nil, query_402657116, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_402657101(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_402657102, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_402657103,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_402657150 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteEventSubscription_402657152(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_402657151(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657153 = query.getOrDefault("Version")
  valid_402657153 = validateParameter(valid_402657153, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657153 != nil:
    section.add "Version", valid_402657153
  var valid_402657154 = query.getOrDefault("Action")
  valid_402657154 = validateParameter(valid_402657154, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657154 != nil:
    section.add "Action", valid_402657154
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
  var valid_402657155 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657155 = validateParameter(valid_402657155, JString,
                                      required = false, default = nil)
  if valid_402657155 != nil:
    section.add "X-Amz-Security-Token", valid_402657155
  var valid_402657156 = header.getOrDefault("X-Amz-Signature")
  valid_402657156 = validateParameter(valid_402657156, JString,
                                      required = false, default = nil)
  if valid_402657156 != nil:
    section.add "X-Amz-Signature", valid_402657156
  var valid_402657157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657157 = validateParameter(valid_402657157, JString,
                                      required = false, default = nil)
  if valid_402657157 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657157
  var valid_402657158 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657158 = validateParameter(valid_402657158, JString,
                                      required = false, default = nil)
  if valid_402657158 != nil:
    section.add "X-Amz-Algorithm", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Date")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Date", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Credential")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Credential", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657161
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402657162 = formData.getOrDefault("SubscriptionName")
  valid_402657162 = validateParameter(valid_402657162, JString, required = true,
                                      default = nil)
  if valid_402657162 != nil:
    section.add "SubscriptionName", valid_402657162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657163: Call_PostDeleteEventSubscription_402657150;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657163.validator(path, query, header, formData, body, _)
  let scheme = call_402657163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657163.makeUrl(scheme.get, call_402657163.host, call_402657163.base,
                                   call_402657163.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657163, uri, valid, _)

proc call*(call_402657164: Call_PostDeleteEventSubscription_402657150;
           SubscriptionName: string; Version: string = "2013-02-12";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## postDeleteEventSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402657165 = newJObject()
  var formData_402657166 = newJObject()
  add(query_402657165, "Version", newJString(Version))
  add(query_402657165, "Action", newJString(Action))
  add(formData_402657166, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657164.call(nil, query_402657165, nil, formData_402657166,
                               nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_402657150(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_402657151, base: "/",
    makeUrl: url_PostDeleteEventSubscription_402657152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_402657134 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteEventSubscription_402657136(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_402657135(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657137 = query.getOrDefault("Version")
  valid_402657137 = validateParameter(valid_402657137, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657137 != nil:
    section.add "Version", valid_402657137
  var valid_402657138 = query.getOrDefault("SubscriptionName")
  valid_402657138 = validateParameter(valid_402657138, JString, required = true,
                                      default = nil)
  if valid_402657138 != nil:
    section.add "SubscriptionName", valid_402657138
  var valid_402657139 = query.getOrDefault("Action")
  valid_402657139 = validateParameter(valid_402657139, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657139 != nil:
    section.add "Action", valid_402657139
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
  var valid_402657140 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657140 = validateParameter(valid_402657140, JString,
                                      required = false, default = nil)
  if valid_402657140 != nil:
    section.add "X-Amz-Security-Token", valid_402657140
  var valid_402657141 = header.getOrDefault("X-Amz-Signature")
  valid_402657141 = validateParameter(valid_402657141, JString,
                                      required = false, default = nil)
  if valid_402657141 != nil:
    section.add "X-Amz-Signature", valid_402657141
  var valid_402657142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Algorithm", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Date")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Date", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Credential")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Credential", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657147: Call_GetDeleteEventSubscription_402657134;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657147.validator(path, query, header, formData, body, _)
  let scheme = call_402657147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657147.makeUrl(scheme.get, call_402657147.host, call_402657147.base,
                                   call_402657147.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657147, uri, valid, _)

proc call*(call_402657148: Call_GetDeleteEventSubscription_402657134;
           SubscriptionName: string; Version: string = "2013-02-12";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## getDeleteEventSubscription
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402657149 = newJObject()
  add(query_402657149, "Version", newJString(Version))
  add(query_402657149, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657149, "Action", newJString(Action))
  result = call_402657148.call(nil, query_402657149, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_402657134(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_402657135, base: "/",
    makeUrl: url_GetDeleteEventSubscription_402657136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_402657183 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteOptionGroup_402657185(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_402657184(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657186 = query.getOrDefault("Version")
  valid_402657186 = validateParameter(valid_402657186, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657186 != nil:
    section.add "Version", valid_402657186
  var valid_402657187 = query.getOrDefault("Action")
  valid_402657187 = validateParameter(valid_402657187, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657187 != nil:
    section.add "Action", valid_402657187
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
  var valid_402657188 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657188 = validateParameter(valid_402657188, JString,
                                      required = false, default = nil)
  if valid_402657188 != nil:
    section.add "X-Amz-Security-Token", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Signature")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Signature", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Algorithm", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Date")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Date", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Credential")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Credential", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657194
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402657195 = formData.getOrDefault("OptionGroupName")
  valid_402657195 = validateParameter(valid_402657195, JString, required = true,
                                      default = nil)
  if valid_402657195 != nil:
    section.add "OptionGroupName", valid_402657195
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657196: Call_PostDeleteOptionGroup_402657183;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657196.validator(path, query, header, formData, body, _)
  let scheme = call_402657196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657196.makeUrl(scheme.get, call_402657196.host, call_402657196.base,
                                   call_402657196.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657196, uri, valid, _)

proc call*(call_402657197: Call_PostDeleteOptionGroup_402657183;
           OptionGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## postDeleteOptionGroup
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402657198 = newJObject()
  var formData_402657199 = newJObject()
  add(query_402657198, "Version", newJString(Version))
  add(formData_402657199, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657198, "Action", newJString(Action))
  result = call_402657197.call(nil, query_402657198, nil, formData_402657199,
                               nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_402657183(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_402657184, base: "/",
    makeUrl: url_PostDeleteOptionGroup_402657185,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_402657167 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteOptionGroup_402657169(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_402657168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402657170 = query.getOrDefault("OptionGroupName")
  valid_402657170 = validateParameter(valid_402657170, JString, required = true,
                                      default = nil)
  if valid_402657170 != nil:
    section.add "OptionGroupName", valid_402657170
  var valid_402657171 = query.getOrDefault("Version")
  valid_402657171 = validateParameter(valid_402657171, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657171 != nil:
    section.add "Version", valid_402657171
  var valid_402657172 = query.getOrDefault("Action")
  valid_402657172 = validateParameter(valid_402657172, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657172 != nil:
    section.add "Action", valid_402657172
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
  var valid_402657173 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657173 = validateParameter(valid_402657173, JString,
                                      required = false, default = nil)
  if valid_402657173 != nil:
    section.add "X-Amz-Security-Token", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Signature")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Signature", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Algorithm", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Date")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Date", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-Credential")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Credential", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657180: Call_GetDeleteOptionGroup_402657167;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657180.validator(path, query, header, formData, body, _)
  let scheme = call_402657180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657180.makeUrl(scheme.get, call_402657180.host, call_402657180.base,
                                   call_402657180.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657180, uri, valid, _)

proc call*(call_402657181: Call_GetDeleteOptionGroup_402657167;
           OptionGroupName: string; Version: string = "2013-02-12";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657182 = newJObject()
  add(query_402657182, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657182, "Version", newJString(Version))
  add(query_402657182, "Action", newJString(Action))
  result = call_402657181.call(nil, query_402657182, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_402657167(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_402657168, base: "/",
    makeUrl: url_GetDeleteOptionGroup_402657169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_402657222 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBEngineVersions_402657224(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_402657223(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657225 = query.getOrDefault("Version")
  valid_402657225 = validateParameter(valid_402657225, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657225 != nil:
    section.add "Version", valid_402657225
  var valid_402657226 = query.getOrDefault("Action")
  valid_402657226 = validateParameter(valid_402657226, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657226 != nil:
    section.add "Action", valid_402657226
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
  var valid_402657227 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false, default = nil)
  if valid_402657227 != nil:
    section.add "X-Amz-Security-Token", valid_402657227
  var valid_402657228 = header.getOrDefault("X-Amz-Signature")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Signature", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Algorithm", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Date")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Date", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Credential")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Credential", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657233
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DefaultOnly: JBool
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   DBParameterGroupFamily: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  var valid_402657234 = formData.getOrDefault("Marker")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "Marker", valid_402657234
  var valid_402657235 = formData.getOrDefault("DefaultOnly")
  valid_402657235 = validateParameter(valid_402657235, JBool, required = false,
                                      default = nil)
  if valid_402657235 != nil:
    section.add "DefaultOnly", valid_402657235
  var valid_402657236 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_402657236 = validateParameter(valid_402657236, JBool, required = false,
                                      default = nil)
  if valid_402657236 != nil:
    section.add "ListSupportedCharacterSets", valid_402657236
  var valid_402657237 = formData.getOrDefault("Engine")
  valid_402657237 = validateParameter(valid_402657237, JString,
                                      required = false, default = nil)
  if valid_402657237 != nil:
    section.add "Engine", valid_402657237
  var valid_402657238 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657238 = validateParameter(valid_402657238, JString,
                                      required = false, default = nil)
  if valid_402657238 != nil:
    section.add "DBParameterGroupFamily", valid_402657238
  var valid_402657239 = formData.getOrDefault("MaxRecords")
  valid_402657239 = validateParameter(valid_402657239, JInt, required = false,
                                      default = nil)
  if valid_402657239 != nil:
    section.add "MaxRecords", valid_402657239
  var valid_402657240 = formData.getOrDefault("EngineVersion")
  valid_402657240 = validateParameter(valid_402657240, JString,
                                      required = false, default = nil)
  if valid_402657240 != nil:
    section.add "EngineVersion", valid_402657240
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657241: Call_PostDescribeDBEngineVersions_402657222;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657241.validator(path, query, header, formData, body, _)
  let scheme = call_402657241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657241.makeUrl(scheme.get, call_402657241.host, call_402657241.base,
                                   call_402657241.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657241, uri, valid, _)

proc call*(call_402657242: Call_PostDescribeDBEngineVersions_402657222;
           Marker: string = ""; DefaultOnly: bool = false;
           ListSupportedCharacterSets: bool = false; Engine: string = "";
           DBParameterGroupFamily: string = ""; Version: string = "2013-02-12";
           MaxRecords: int = 0; Action: string = "DescribeDBEngineVersions";
           EngineVersion: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   Marker: string
  ##   DefaultOnly: bool
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   DBParameterGroupFamily: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   EngineVersion: string
  var query_402657243 = newJObject()
  var formData_402657244 = newJObject()
  add(formData_402657244, "Marker", newJString(Marker))
  add(formData_402657244, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_402657244, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_402657244, "Engine", newJString(Engine))
  add(formData_402657244, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657243, "Version", newJString(Version))
  add(formData_402657244, "MaxRecords", newJInt(MaxRecords))
  add(query_402657243, "Action", newJString(Action))
  add(formData_402657244, "EngineVersion", newJString(EngineVersion))
  result = call_402657242.call(nil, query_402657243, nil, formData_402657244,
                               nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_402657222(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_402657223, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_402657224,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_402657200 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBEngineVersions_402657202(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_402657201(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DefaultOnly: JBool
  ##   DBParameterGroupFamily: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineVersion: JString
  ##   Engine: JString
  ##   Action: JString (required)
  ##   ListSupportedCharacterSets: JBool
  section = newJObject()
  var valid_402657203 = query.getOrDefault("DefaultOnly")
  valid_402657203 = validateParameter(valid_402657203, JBool, required = false,
                                      default = nil)
  if valid_402657203 != nil:
    section.add "DefaultOnly", valid_402657203
  var valid_402657204 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "DBParameterGroupFamily", valid_402657204
  var valid_402657205 = query.getOrDefault("MaxRecords")
  valid_402657205 = validateParameter(valid_402657205, JInt, required = false,
                                      default = nil)
  if valid_402657205 != nil:
    section.add "MaxRecords", valid_402657205
  var valid_402657206 = query.getOrDefault("Marker")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "Marker", valid_402657206
  var valid_402657207 = query.getOrDefault("Version")
  valid_402657207 = validateParameter(valid_402657207, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657207 != nil:
    section.add "Version", valid_402657207
  var valid_402657208 = query.getOrDefault("EngineVersion")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "EngineVersion", valid_402657208
  var valid_402657209 = query.getOrDefault("Engine")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "Engine", valid_402657209
  var valid_402657210 = query.getOrDefault("Action")
  valid_402657210 = validateParameter(valid_402657210, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657210 != nil:
    section.add "Action", valid_402657210
  var valid_402657211 = query.getOrDefault("ListSupportedCharacterSets")
  valid_402657211 = validateParameter(valid_402657211, JBool, required = false,
                                      default = nil)
  if valid_402657211 != nil:
    section.add "ListSupportedCharacterSets", valid_402657211
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
  var valid_402657212 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-Security-Token", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Signature")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Signature", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Algorithm", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Date")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Date", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Credential")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Credential", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657218
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657219: Call_GetDescribeDBEngineVersions_402657200;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657219.validator(path, query, header, formData, body, _)
  let scheme = call_402657219.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657219.makeUrl(scheme.get, call_402657219.host, call_402657219.base,
                                   call_402657219.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657219, uri, valid, _)

proc call*(call_402657220: Call_GetDescribeDBEngineVersions_402657200;
           DefaultOnly: bool = false; DBParameterGroupFamily: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-02-12"; EngineVersion: string = "";
           Engine: string = ""; Action: string = "DescribeDBEngineVersions";
           ListSupportedCharacterSets: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   DefaultOnly: bool
  ##   DBParameterGroupFamily: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineVersion: string
  ##   Engine: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  var query_402657221 = newJObject()
  add(query_402657221, "DefaultOnly", newJBool(DefaultOnly))
  add(query_402657221, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657221, "MaxRecords", newJInt(MaxRecords))
  add(query_402657221, "Marker", newJString(Marker))
  add(query_402657221, "Version", newJString(Version))
  add(query_402657221, "EngineVersion", newJString(EngineVersion))
  add(query_402657221, "Engine", newJString(Engine))
  add(query_402657221, "Action", newJString(Action))
  add(query_402657221, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  result = call_402657220.call(nil, query_402657221, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_402657200(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_402657201, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_402657202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_402657263 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBInstances_402657265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_402657264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657266 = query.getOrDefault("Version")
  valid_402657266 = validateParameter(valid_402657266, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657266 != nil:
    section.add "Version", valid_402657266
  var valid_402657267 = query.getOrDefault("Action")
  valid_402657267 = validateParameter(valid_402657267, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657267 != nil:
    section.add "Action", valid_402657267
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
  var valid_402657268 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657268 = validateParameter(valid_402657268, JString,
                                      required = false, default = nil)
  if valid_402657268 != nil:
    section.add "X-Amz-Security-Token", valid_402657268
  var valid_402657269 = header.getOrDefault("X-Amz-Signature")
  valid_402657269 = validateParameter(valid_402657269, JString,
                                      required = false, default = nil)
  if valid_402657269 != nil:
    section.add "X-Amz-Signature", valid_402657269
  var valid_402657270 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657270 = validateParameter(valid_402657270, JString,
                                      required = false, default = nil)
  if valid_402657270 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657270
  var valid_402657271 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657271 = validateParameter(valid_402657271, JString,
                                      required = false, default = nil)
  if valid_402657271 != nil:
    section.add "X-Amz-Algorithm", valid_402657271
  var valid_402657272 = header.getOrDefault("X-Amz-Date")
  valid_402657272 = validateParameter(valid_402657272, JString,
                                      required = false, default = nil)
  if valid_402657272 != nil:
    section.add "X-Amz-Date", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-Credential")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-Credential", valid_402657273
  var valid_402657274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657274 = validateParameter(valid_402657274, JString,
                                      required = false, default = nil)
  if valid_402657274 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657274
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_402657275 = formData.getOrDefault("Marker")
  valid_402657275 = validateParameter(valid_402657275, JString,
                                      required = false, default = nil)
  if valid_402657275 != nil:
    section.add "Marker", valid_402657275
  var valid_402657276 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "DBInstanceIdentifier", valid_402657276
  var valid_402657277 = formData.getOrDefault("MaxRecords")
  valid_402657277 = validateParameter(valid_402657277, JInt, required = false,
                                      default = nil)
  if valid_402657277 != nil:
    section.add "MaxRecords", valid_402657277
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657278: Call_PostDescribeDBInstances_402657263;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657278.validator(path, query, header, formData, body, _)
  let scheme = call_402657278.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657278.makeUrl(scheme.get, call_402657278.host, call_402657278.base,
                                   call_402657278.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657278, uri, valid, _)

proc call*(call_402657279: Call_PostDescribeDBInstances_402657263;
           Marker: string = ""; Version: string = "2013-02-12";
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBInstances"): Recallable =
  ## postDescribeDBInstances
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Action: string (required)
  var query_402657280 = newJObject()
  var formData_402657281 = newJObject()
  add(formData_402657281, "Marker", newJString(Marker))
  add(query_402657280, "Version", newJString(Version))
  add(formData_402657281, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657281, "MaxRecords", newJInt(MaxRecords))
  add(query_402657280, "Action", newJString(Action))
  result = call_402657279.call(nil, query_402657280, nil, formData_402657281,
                               nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_402657263(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_402657264, base: "/",
    makeUrl: url_PostDescribeDBInstances_402657265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_402657245 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBInstances_402657247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_402657246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657248 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "DBInstanceIdentifier", valid_402657248
  var valid_402657249 = query.getOrDefault("MaxRecords")
  valid_402657249 = validateParameter(valid_402657249, JInt, required = false,
                                      default = nil)
  if valid_402657249 != nil:
    section.add "MaxRecords", valid_402657249
  var valid_402657250 = query.getOrDefault("Marker")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "Marker", valid_402657250
  var valid_402657251 = query.getOrDefault("Version")
  valid_402657251 = validateParameter(valid_402657251, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657251 != nil:
    section.add "Version", valid_402657251
  var valid_402657252 = query.getOrDefault("Action")
  valid_402657252 = validateParameter(valid_402657252, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657252 != nil:
    section.add "Action", valid_402657252
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
  var valid_402657253 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-Security-Token", valid_402657253
  var valid_402657254 = header.getOrDefault("X-Amz-Signature")
  valid_402657254 = validateParameter(valid_402657254, JString,
                                      required = false, default = nil)
  if valid_402657254 != nil:
    section.add "X-Amz-Signature", valid_402657254
  var valid_402657255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657255
  var valid_402657256 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657256 = validateParameter(valid_402657256, JString,
                                      required = false, default = nil)
  if valid_402657256 != nil:
    section.add "X-Amz-Algorithm", valid_402657256
  var valid_402657257 = header.getOrDefault("X-Amz-Date")
  valid_402657257 = validateParameter(valid_402657257, JString,
                                      required = false, default = nil)
  if valid_402657257 != nil:
    section.add "X-Amz-Date", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-Credential")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-Credential", valid_402657258
  var valid_402657259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657260: Call_GetDescribeDBInstances_402657245;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657260.validator(path, query, header, formData, body, _)
  let scheme = call_402657260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657260.makeUrl(scheme.get, call_402657260.host, call_402657260.base,
                                   call_402657260.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657260, uri, valid, _)

proc call*(call_402657261: Call_GetDescribeDBInstances_402657245;
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeDBInstances"): Recallable =
  ## getDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657262 = newJObject()
  add(query_402657262, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657262, "MaxRecords", newJInt(MaxRecords))
  add(query_402657262, "Marker", newJString(Marker))
  add(query_402657262, "Version", newJString(Version))
  add(query_402657262, "Action", newJString(Action))
  result = call_402657261.call(nil, query_402657262, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_402657245(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_402657246, base: "/",
    makeUrl: url_GetDescribeDBInstances_402657247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_402657303 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBLogFiles_402657305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_402657304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657306 = query.getOrDefault("Version")
  valid_402657306 = validateParameter(valid_402657306, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657306 != nil:
    section.add "Version", valid_402657306
  var valid_402657307 = query.getOrDefault("Action")
  valid_402657307 = validateParameter(valid_402657307, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
  if valid_402657307 != nil:
    section.add "Action", valid_402657307
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
  var valid_402657308 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657308 = validateParameter(valid_402657308, JString,
                                      required = false, default = nil)
  if valid_402657308 != nil:
    section.add "X-Amz-Security-Token", valid_402657308
  var valid_402657309 = header.getOrDefault("X-Amz-Signature")
  valid_402657309 = validateParameter(valid_402657309, JString,
                                      required = false, default = nil)
  if valid_402657309 != nil:
    section.add "X-Amz-Signature", valid_402657309
  var valid_402657310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657310 = validateParameter(valid_402657310, JString,
                                      required = false, default = nil)
  if valid_402657310 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657310
  var valid_402657311 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "X-Amz-Algorithm", valid_402657311
  var valid_402657312 = header.getOrDefault("X-Amz-Date")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Date", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-Credential")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-Credential", valid_402657313
  var valid_402657314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657314
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  section = newJObject()
  var valid_402657315 = formData.getOrDefault("Marker")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "Marker", valid_402657315
  var valid_402657316 = formData.getOrDefault("FilenameContains")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "FilenameContains", valid_402657316
  var valid_402657317 = formData.getOrDefault("FileLastWritten")
  valid_402657317 = validateParameter(valid_402657317, JInt, required = false,
                                      default = nil)
  if valid_402657317 != nil:
    section.add "FileLastWritten", valid_402657317
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657318 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657318 = validateParameter(valid_402657318, JString, required = true,
                                      default = nil)
  if valid_402657318 != nil:
    section.add "DBInstanceIdentifier", valid_402657318
  var valid_402657319 = formData.getOrDefault("MaxRecords")
  valid_402657319 = validateParameter(valid_402657319, JInt, required = false,
                                      default = nil)
  if valid_402657319 != nil:
    section.add "MaxRecords", valid_402657319
  var valid_402657320 = formData.getOrDefault("FileSize")
  valid_402657320 = validateParameter(valid_402657320, JInt, required = false,
                                      default = nil)
  if valid_402657320 != nil:
    section.add "FileSize", valid_402657320
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657321: Call_PostDescribeDBLogFiles_402657303;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657321.validator(path, query, header, formData, body, _)
  let scheme = call_402657321.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657321.makeUrl(scheme.get, call_402657321.host, call_402657321.base,
                                   call_402657321.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657321, uri, valid, _)

proc call*(call_402657322: Call_PostDescribeDBLogFiles_402657303;
           DBInstanceIdentifier: string; Marker: string = "";
           FilenameContains: string = ""; FileLastWritten: int = 0;
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           FileSize: int = 0; Action: string = "DescribeDBLogFiles"): Recallable =
  ## postDescribeDBLogFiles
  ##   Marker: string
  ##   FilenameContains: string
  ##   FileLastWritten: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MaxRecords: int
  ##   FileSize: int
  ##   Action: string (required)
  var query_402657323 = newJObject()
  var formData_402657324 = newJObject()
  add(formData_402657324, "Marker", newJString(Marker))
  add(formData_402657324, "FilenameContains", newJString(FilenameContains))
  add(formData_402657324, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657323, "Version", newJString(Version))
  add(formData_402657324, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657324, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657324, "FileSize", newJInt(FileSize))
  add(query_402657323, "Action", newJString(Action))
  result = call_402657322.call(nil, query_402657323, nil, formData_402657324,
                               nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_402657303(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_402657304, base: "/",
    makeUrl: url_PostDescribeDBLogFiles_402657305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_402657282 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBLogFiles_402657284(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_402657283(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  ##   FilenameContains: JString
  ##   Marker: JString
  ##   FileSize: JInt
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657285 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657285 = validateParameter(valid_402657285, JString, required = true,
                                      default = nil)
  if valid_402657285 != nil:
    section.add "DBInstanceIdentifier", valid_402657285
  var valid_402657286 = query.getOrDefault("MaxRecords")
  valid_402657286 = validateParameter(valid_402657286, JInt, required = false,
                                      default = nil)
  if valid_402657286 != nil:
    section.add "MaxRecords", valid_402657286
  var valid_402657287 = query.getOrDefault("FileLastWritten")
  valid_402657287 = validateParameter(valid_402657287, JInt, required = false,
                                      default = nil)
  if valid_402657287 != nil:
    section.add "FileLastWritten", valid_402657287
  var valid_402657288 = query.getOrDefault("FilenameContains")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "FilenameContains", valid_402657288
  var valid_402657289 = query.getOrDefault("Marker")
  valid_402657289 = validateParameter(valid_402657289, JString,
                                      required = false, default = nil)
  if valid_402657289 != nil:
    section.add "Marker", valid_402657289
  var valid_402657290 = query.getOrDefault("FileSize")
  valid_402657290 = validateParameter(valid_402657290, JInt, required = false,
                                      default = nil)
  if valid_402657290 != nil:
    section.add "FileSize", valid_402657290
  var valid_402657291 = query.getOrDefault("Version")
  valid_402657291 = validateParameter(valid_402657291, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657291 != nil:
    section.add "Version", valid_402657291
  var valid_402657292 = query.getOrDefault("Action")
  valid_402657292 = validateParameter(valid_402657292, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
  if valid_402657292 != nil:
    section.add "Action", valid_402657292
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
  var valid_402657293 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Security-Token", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-Signature")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Signature", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Algorithm", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Date")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Date", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Credential")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Credential", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657300: Call_GetDescribeDBLogFiles_402657282;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657300.validator(path, query, header, formData, body, _)
  let scheme = call_402657300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657300.makeUrl(scheme.get, call_402657300.host, call_402657300.base,
                                   call_402657300.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657300, uri, valid, _)

proc call*(call_402657301: Call_GetDescribeDBLogFiles_402657282;
           DBInstanceIdentifier: string; MaxRecords: int = 0;
           FileLastWritten: int = 0; FilenameContains: string = "";
           Marker: string = ""; FileSize: int = 0;
           Version: string = "2013-02-12"; Action: string = "DescribeDBLogFiles"): Recallable =
  ## getDescribeDBLogFiles
  ##   DBInstanceIdentifier: string (required)
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   FilenameContains: string
  ##   Marker: string
  ##   FileSize: int
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657302 = newJObject()
  add(query_402657302, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657302, "MaxRecords", newJInt(MaxRecords))
  add(query_402657302, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657302, "FilenameContains", newJString(FilenameContains))
  add(query_402657302, "Marker", newJString(Marker))
  add(query_402657302, "FileSize", newJInt(FileSize))
  add(query_402657302, "Version", newJString(Version))
  add(query_402657302, "Action", newJString(Action))
  result = call_402657301.call(nil, query_402657302, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_402657282(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_402657283, base: "/",
    makeUrl: url_GetDescribeDBLogFiles_402657284,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_402657343 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameterGroups_402657345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_402657344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657346 = query.getOrDefault("Version")
  valid_402657346 = validateParameter(valid_402657346, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657346 != nil:
    section.add "Version", valid_402657346
  var valid_402657347 = query.getOrDefault("Action")
  valid_402657347 = validateParameter(valid_402657347, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657347 != nil:
    section.add "Action", valid_402657347
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
  var valid_402657348 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-Security-Token", valid_402657348
  var valid_402657349 = header.getOrDefault("X-Amz-Signature")
  valid_402657349 = validateParameter(valid_402657349, JString,
                                      required = false, default = nil)
  if valid_402657349 != nil:
    section.add "X-Amz-Signature", valid_402657349
  var valid_402657350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657350 = validateParameter(valid_402657350, JString,
                                      required = false, default = nil)
  if valid_402657350 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657350
  var valid_402657351 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657351 = validateParameter(valid_402657351, JString,
                                      required = false, default = nil)
  if valid_402657351 != nil:
    section.add "X-Amz-Algorithm", valid_402657351
  var valid_402657352 = header.getOrDefault("X-Amz-Date")
  valid_402657352 = validateParameter(valid_402657352, JString,
                                      required = false, default = nil)
  if valid_402657352 != nil:
    section.add "X-Amz-Date", valid_402657352
  var valid_402657353 = header.getOrDefault("X-Amz-Credential")
  valid_402657353 = validateParameter(valid_402657353, JString,
                                      required = false, default = nil)
  if valid_402657353 != nil:
    section.add "X-Amz-Credential", valid_402657353
  var valid_402657354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657354 = validateParameter(valid_402657354, JString,
                                      required = false, default = nil)
  if valid_402657354 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657354
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_402657355 = formData.getOrDefault("Marker")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "Marker", valid_402657355
  var valid_402657356 = formData.getOrDefault("DBParameterGroupName")
  valid_402657356 = validateParameter(valid_402657356, JString,
                                      required = false, default = nil)
  if valid_402657356 != nil:
    section.add "DBParameterGroupName", valid_402657356
  var valid_402657357 = formData.getOrDefault("MaxRecords")
  valid_402657357 = validateParameter(valid_402657357, JInt, required = false,
                                      default = nil)
  if valid_402657357 != nil:
    section.add "MaxRecords", valid_402657357
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657358: Call_PostDescribeDBParameterGroups_402657343;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657358.validator(path, query, header, formData, body, _)
  let scheme = call_402657358.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657358.makeUrl(scheme.get, call_402657358.host, call_402657358.base,
                                   call_402657358.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657358, uri, valid, _)

proc call*(call_402657359: Call_PostDescribeDBParameterGroups_402657343;
           Marker: string = ""; Version: string = "2013-02-12";
           DBParameterGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBParameterGroups"): Recallable =
  ## postDescribeDBParameterGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  var query_402657360 = newJObject()
  var formData_402657361 = newJObject()
  add(formData_402657361, "Marker", newJString(Marker))
  add(query_402657360, "Version", newJString(Version))
  add(formData_402657361, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657361, "MaxRecords", newJInt(MaxRecords))
  add(query_402657360, "Action", newJString(Action))
  result = call_402657359.call(nil, query_402657360, nil, formData_402657361,
                               nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_402657343(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_402657344, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_402657345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_402657325 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameterGroups_402657327(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_402657326(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657328 = query.getOrDefault("DBParameterGroupName")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "DBParameterGroupName", valid_402657328
  var valid_402657329 = query.getOrDefault("MaxRecords")
  valid_402657329 = validateParameter(valid_402657329, JInt, required = false,
                                      default = nil)
  if valid_402657329 != nil:
    section.add "MaxRecords", valid_402657329
  var valid_402657330 = query.getOrDefault("Marker")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "Marker", valid_402657330
  var valid_402657331 = query.getOrDefault("Version")
  valid_402657331 = validateParameter(valid_402657331, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657331 != nil:
    section.add "Version", valid_402657331
  var valid_402657332 = query.getOrDefault("Action")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657332 != nil:
    section.add "Action", valid_402657332
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
  var valid_402657333 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-Security-Token", valid_402657333
  var valid_402657334 = header.getOrDefault("X-Amz-Signature")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Signature", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Algorithm", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Date")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Date", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Credential")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Credential", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657340: Call_GetDescribeDBParameterGroups_402657325;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657340.validator(path, query, header, formData, body, _)
  let scheme = call_402657340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657340.makeUrl(scheme.get, call_402657340.host, call_402657340.base,
                                   call_402657340.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657340, uri, valid, _)

proc call*(call_402657341: Call_GetDescribeDBParameterGroups_402657325;
           DBParameterGroupName: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeDBParameterGroups"): Recallable =
  ## getDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657342 = newJObject()
  add(query_402657342, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657342, "MaxRecords", newJInt(MaxRecords))
  add(query_402657342, "Marker", newJString(Marker))
  add(query_402657342, "Version", newJString(Version))
  add(query_402657342, "Action", newJString(Action))
  result = call_402657341.call(nil, query_402657342, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_402657325(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_402657326, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_402657327,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_402657381 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameters_402657383(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_402657382(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657384 = query.getOrDefault("Version")
  valid_402657384 = validateParameter(valid_402657384, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657384 != nil:
    section.add "Version", valid_402657384
  var valid_402657385 = query.getOrDefault("Action")
  valid_402657385 = validateParameter(valid_402657385, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657385 != nil:
    section.add "Action", valid_402657385
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
  var valid_402657386 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657386 = validateParameter(valid_402657386, JString,
                                      required = false, default = nil)
  if valid_402657386 != nil:
    section.add "X-Amz-Security-Token", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Signature")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Signature", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-Algorithm", valid_402657389
  var valid_402657390 = header.getOrDefault("X-Amz-Date")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-Date", valid_402657390
  var valid_402657391 = header.getOrDefault("X-Amz-Credential")
  valid_402657391 = validateParameter(valid_402657391, JString,
                                      required = false, default = nil)
  if valid_402657391 != nil:
    section.add "X-Amz-Credential", valid_402657391
  var valid_402657392 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657392 = validateParameter(valid_402657392, JString,
                                      required = false, default = nil)
  if valid_402657392 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657392
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  var valid_402657393 = formData.getOrDefault("Marker")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "Marker", valid_402657393
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657394 = formData.getOrDefault("DBParameterGroupName")
  valid_402657394 = validateParameter(valid_402657394, JString, required = true,
                                      default = nil)
  if valid_402657394 != nil:
    section.add "DBParameterGroupName", valid_402657394
  var valid_402657395 = formData.getOrDefault("MaxRecords")
  valid_402657395 = validateParameter(valid_402657395, JInt, required = false,
                                      default = nil)
  if valid_402657395 != nil:
    section.add "MaxRecords", valid_402657395
  var valid_402657396 = formData.getOrDefault("Source")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "Source", valid_402657396
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657397: Call_PostDescribeDBParameters_402657381;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657397.validator(path, query, header, formData, body, _)
  let scheme = call_402657397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657397.makeUrl(scheme.get, call_402657397.host, call_402657397.base,
                                   call_402657397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657397, uri, valid, _)

proc call*(call_402657398: Call_PostDescribeDBParameters_402657381;
           DBParameterGroupName: string; Marker: string = "";
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           Action: string = "DescribeDBParameters"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   Marker: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Source: string
  var query_402657399 = newJObject()
  var formData_402657400 = newJObject()
  add(formData_402657400, "Marker", newJString(Marker))
  add(query_402657399, "Version", newJString(Version))
  add(formData_402657400, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657400, "MaxRecords", newJInt(MaxRecords))
  add(query_402657399, "Action", newJString(Action))
  add(formData_402657400, "Source", newJString(Source))
  result = call_402657398.call(nil, query_402657399, nil, formData_402657400,
                               nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_402657381(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_402657382, base: "/",
    makeUrl: url_PostDescribeDBParameters_402657383,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_402657362 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameters_402657364(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_402657363(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   Source: JString
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657365 = query.getOrDefault("DBParameterGroupName")
  valid_402657365 = validateParameter(valid_402657365, JString, required = true,
                                      default = nil)
  if valid_402657365 != nil:
    section.add "DBParameterGroupName", valid_402657365
  var valid_402657366 = query.getOrDefault("MaxRecords")
  valid_402657366 = validateParameter(valid_402657366, JInt, required = false,
                                      default = nil)
  if valid_402657366 != nil:
    section.add "MaxRecords", valid_402657366
  var valid_402657367 = query.getOrDefault("Marker")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "Marker", valid_402657367
  var valid_402657368 = query.getOrDefault("Version")
  valid_402657368 = validateParameter(valid_402657368, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657368 != nil:
    section.add "Version", valid_402657368
  var valid_402657369 = query.getOrDefault("Action")
  valid_402657369 = validateParameter(valid_402657369, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657369 != nil:
    section.add "Action", valid_402657369
  var valid_402657370 = query.getOrDefault("Source")
  valid_402657370 = validateParameter(valid_402657370, JString,
                                      required = false, default = nil)
  if valid_402657370 != nil:
    section.add "Source", valid_402657370
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
  var valid_402657371 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657371 = validateParameter(valid_402657371, JString,
                                      required = false, default = nil)
  if valid_402657371 != nil:
    section.add "X-Amz-Security-Token", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-Signature")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-Signature", valid_402657372
  var valid_402657373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657373
  var valid_402657374 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-Algorithm", valid_402657374
  var valid_402657375 = header.getOrDefault("X-Amz-Date")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-Date", valid_402657375
  var valid_402657376 = header.getOrDefault("X-Amz-Credential")
  valid_402657376 = validateParameter(valid_402657376, JString,
                                      required = false, default = nil)
  if valid_402657376 != nil:
    section.add "X-Amz-Credential", valid_402657376
  var valid_402657377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657378: Call_GetDescribeDBParameters_402657362;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657378.validator(path, query, header, formData, body, _)
  let scheme = call_402657378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657378.makeUrl(scheme.get, call_402657378.host, call_402657378.base,
                                   call_402657378.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657378, uri, valid, _)

proc call*(call_402657379: Call_GetDescribeDBParameters_402657362;
           DBParameterGroupName: string; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeDBParameters"; Source: string = ""): Recallable =
  ## getDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Source: string
  var query_402657380 = newJObject()
  add(query_402657380, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657380, "MaxRecords", newJInt(MaxRecords))
  add(query_402657380, "Marker", newJString(Marker))
  add(query_402657380, "Version", newJString(Version))
  add(query_402657380, "Action", newJString(Action))
  add(query_402657380, "Source", newJString(Source))
  result = call_402657379.call(nil, query_402657380, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_402657362(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_402657363, base: "/",
    makeUrl: url_GetDescribeDBParameters_402657364,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_402657419 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSecurityGroups_402657421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_402657420(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657422 = query.getOrDefault("Version")
  valid_402657422 = validateParameter(valid_402657422, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657422 != nil:
    section.add "Version", valid_402657422
  var valid_402657423 = query.getOrDefault("Action")
  valid_402657423 = validateParameter(valid_402657423, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657423 != nil:
    section.add "Action", valid_402657423
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
  var valid_402657424 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Security-Token", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-Signature")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-Signature", valid_402657425
  var valid_402657426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657426
  var valid_402657427 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "X-Amz-Algorithm", valid_402657427
  var valid_402657428 = header.getOrDefault("X-Amz-Date")
  valid_402657428 = validateParameter(valid_402657428, JString,
                                      required = false, default = nil)
  if valid_402657428 != nil:
    section.add "X-Amz-Date", valid_402657428
  var valid_402657429 = header.getOrDefault("X-Amz-Credential")
  valid_402657429 = validateParameter(valid_402657429, JString,
                                      required = false, default = nil)
  if valid_402657429 != nil:
    section.add "X-Amz-Credential", valid_402657429
  var valid_402657430 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657430 = validateParameter(valid_402657430, JString,
                                      required = false, default = nil)
  if valid_402657430 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657430
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_402657431 = formData.getOrDefault("Marker")
  valid_402657431 = validateParameter(valid_402657431, JString,
                                      required = false, default = nil)
  if valid_402657431 != nil:
    section.add "Marker", valid_402657431
  var valid_402657432 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657432 = validateParameter(valid_402657432, JString,
                                      required = false, default = nil)
  if valid_402657432 != nil:
    section.add "DBSecurityGroupName", valid_402657432
  var valid_402657433 = formData.getOrDefault("MaxRecords")
  valid_402657433 = validateParameter(valid_402657433, JInt, required = false,
                                      default = nil)
  if valid_402657433 != nil:
    section.add "MaxRecords", valid_402657433
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657434: Call_PostDescribeDBSecurityGroups_402657419;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657434.validator(path, query, header, formData, body, _)
  let scheme = call_402657434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657434.makeUrl(scheme.get, call_402657434.host, call_402657434.base,
                                   call_402657434.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657434, uri, valid, _)

proc call*(call_402657435: Call_PostDescribeDBSecurityGroups_402657419;
           Marker: string = ""; Version: string = "2013-02-12";
           DBSecurityGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBSecurityGroups"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  var query_402657436 = newJObject()
  var formData_402657437 = newJObject()
  add(formData_402657437, "Marker", newJString(Marker))
  add(query_402657436, "Version", newJString(Version))
  add(formData_402657437, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402657437, "MaxRecords", newJInt(MaxRecords))
  add(query_402657436, "Action", newJString(Action))
  result = call_402657435.call(nil, query_402657436, nil, formData_402657437,
                               nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_402657419(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_402657420, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_402657421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_402657401 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSecurityGroups_402657403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_402657402(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString
  section = newJObject()
  var valid_402657404 = query.getOrDefault("MaxRecords")
  valid_402657404 = validateParameter(valid_402657404, JInt, required = false,
                                      default = nil)
  if valid_402657404 != nil:
    section.add "MaxRecords", valid_402657404
  var valid_402657405 = query.getOrDefault("Marker")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "Marker", valid_402657405
  var valid_402657406 = query.getOrDefault("Version")
  valid_402657406 = validateParameter(valid_402657406, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657406 != nil:
    section.add "Version", valid_402657406
  var valid_402657407 = query.getOrDefault("Action")
  valid_402657407 = validateParameter(valid_402657407, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657407 != nil:
    section.add "Action", valid_402657407
  var valid_402657408 = query.getOrDefault("DBSecurityGroupName")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "DBSecurityGroupName", valid_402657408
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
  var valid_402657409 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Security-Token", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-Signature")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-Signature", valid_402657410
  var valid_402657411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657411 = validateParameter(valid_402657411, JString,
                                      required = false, default = nil)
  if valid_402657411 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657411
  var valid_402657412 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657412 = validateParameter(valid_402657412, JString,
                                      required = false, default = nil)
  if valid_402657412 != nil:
    section.add "X-Amz-Algorithm", valid_402657412
  var valid_402657413 = header.getOrDefault("X-Amz-Date")
  valid_402657413 = validateParameter(valid_402657413, JString,
                                      required = false, default = nil)
  if valid_402657413 != nil:
    section.add "X-Amz-Date", valid_402657413
  var valid_402657414 = header.getOrDefault("X-Amz-Credential")
  valid_402657414 = validateParameter(valid_402657414, JString,
                                      required = false, default = nil)
  if valid_402657414 != nil:
    section.add "X-Amz-Credential", valid_402657414
  var valid_402657415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657415 = validateParameter(valid_402657415, JString,
                                      required = false, default = nil)
  if valid_402657415 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657416: Call_GetDescribeDBSecurityGroups_402657401;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657416.validator(path, query, header, formData, body, _)
  let scheme = call_402657416.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657416.makeUrl(scheme.get, call_402657416.host, call_402657416.base,
                                   call_402657416.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657416, uri, valid, _)

proc call*(call_402657417: Call_GetDescribeDBSecurityGroups_402657401;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-02-12";
           Action: string = "DescribeDBSecurityGroups";
           DBSecurityGroupName: string = ""): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string
  var query_402657418 = newJObject()
  add(query_402657418, "MaxRecords", newJInt(MaxRecords))
  add(query_402657418, "Marker", newJString(Marker))
  add(query_402657418, "Version", newJString(Version))
  add(query_402657418, "Action", newJString(Action))
  add(query_402657418, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657417.call(nil, query_402657418, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_402657401(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_402657402, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_402657403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_402657458 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSnapshots_402657460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_402657459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657461 = query.getOrDefault("Version")
  valid_402657461 = validateParameter(valid_402657461, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657461 != nil:
    section.add "Version", valid_402657461
  var valid_402657462 = query.getOrDefault("Action")
  valid_402657462 = validateParameter(valid_402657462, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657462 != nil:
    section.add "Action", valid_402657462
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
  var valid_402657463 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Security-Token", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Signature")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Signature", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Algorithm", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Date")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Date", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-Credential")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-Credential", valid_402657468
  var valid_402657469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657469
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  section = newJObject()
  var valid_402657470 = formData.getOrDefault("Marker")
  valid_402657470 = validateParameter(valid_402657470, JString,
                                      required = false, default = nil)
  if valid_402657470 != nil:
    section.add "Marker", valid_402657470
  var valid_402657471 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657471 = validateParameter(valid_402657471, JString,
                                      required = false, default = nil)
  if valid_402657471 != nil:
    section.add "DBInstanceIdentifier", valid_402657471
  var valid_402657472 = formData.getOrDefault("MaxRecords")
  valid_402657472 = validateParameter(valid_402657472, JInt, required = false,
                                      default = nil)
  if valid_402657472 != nil:
    section.add "MaxRecords", valid_402657472
  var valid_402657473 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657473 = validateParameter(valid_402657473, JString,
                                      required = false, default = nil)
  if valid_402657473 != nil:
    section.add "DBSnapshotIdentifier", valid_402657473
  var valid_402657474 = formData.getOrDefault("SnapshotType")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "SnapshotType", valid_402657474
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657475: Call_PostDescribeDBSnapshots_402657458;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657475.validator(path, query, header, formData, body, _)
  let scheme = call_402657475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657475.makeUrl(scheme.get, call_402657475.host, call_402657475.base,
                                   call_402657475.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657475, uri, valid, _)

proc call*(call_402657476: Call_PostDescribeDBSnapshots_402657458;
           Marker: string = ""; Version: string = "2013-02-12";
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           DBSnapshotIdentifier: string = ""; SnapshotType: string = "";
           Action: string = "DescribeDBSnapshots"): Recallable =
  ## postDescribeDBSnapshots
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  var query_402657477 = newJObject()
  var formData_402657478 = newJObject()
  add(formData_402657478, "Marker", newJString(Marker))
  add(query_402657477, "Version", newJString(Version))
  add(formData_402657478, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657478, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657478, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402657478, "SnapshotType", newJString(SnapshotType))
  add(query_402657477, "Action", newJString(Action))
  result = call_402657476.call(nil, query_402657477, nil, formData_402657478,
                               nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_402657458(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_402657459, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_402657460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_402657438 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSnapshots_402657440(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_402657439(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   SnapshotType: JString
  ##   DBSnapshotIdentifier: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657441 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "DBInstanceIdentifier", valid_402657441
  var valid_402657442 = query.getOrDefault("MaxRecords")
  valid_402657442 = validateParameter(valid_402657442, JInt, required = false,
                                      default = nil)
  if valid_402657442 != nil:
    section.add "MaxRecords", valid_402657442
  var valid_402657443 = query.getOrDefault("Marker")
  valid_402657443 = validateParameter(valid_402657443, JString,
                                      required = false, default = nil)
  if valid_402657443 != nil:
    section.add "Marker", valid_402657443
  var valid_402657444 = query.getOrDefault("Version")
  valid_402657444 = validateParameter(valid_402657444, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657444 != nil:
    section.add "Version", valid_402657444
  var valid_402657445 = query.getOrDefault("SnapshotType")
  valid_402657445 = validateParameter(valid_402657445, JString,
                                      required = false, default = nil)
  if valid_402657445 != nil:
    section.add "SnapshotType", valid_402657445
  var valid_402657446 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657446 = validateParameter(valid_402657446, JString,
                                      required = false, default = nil)
  if valid_402657446 != nil:
    section.add "DBSnapshotIdentifier", valid_402657446
  var valid_402657447 = query.getOrDefault("Action")
  valid_402657447 = validateParameter(valid_402657447, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657447 != nil:
    section.add "Action", valid_402657447
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
  var valid_402657448 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Security-Token", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Signature")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Signature", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Algorithm", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Date")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Date", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-Credential")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-Credential", valid_402657453
  var valid_402657454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657454 = validateParameter(valid_402657454, JString,
                                      required = false, default = nil)
  if valid_402657454 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657455: Call_GetDescribeDBSnapshots_402657438;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657455.validator(path, query, header, formData, body, _)
  let scheme = call_402657455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657455.makeUrl(scheme.get, call_402657455.host, call_402657455.base,
                                   call_402657455.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657455, uri, valid, _)

proc call*(call_402657456: Call_GetDescribeDBSnapshots_402657438;
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           SnapshotType: string = ""; DBSnapshotIdentifier: string = "";
           Action: string = "DescribeDBSnapshots"): Recallable =
  ## getDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   SnapshotType: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  var query_402657457 = newJObject()
  add(query_402657457, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657457, "MaxRecords", newJInt(MaxRecords))
  add(query_402657457, "Marker", newJString(Marker))
  add(query_402657457, "Version", newJString(Version))
  add(query_402657457, "SnapshotType", newJString(SnapshotType))
  add(query_402657457, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657457, "Action", newJString(Action))
  result = call_402657456.call(nil, query_402657457, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_402657438(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_402657439, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_402657440,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_402657497 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSubnetGroups_402657499(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_402657498(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657500 = query.getOrDefault("Version")
  valid_402657500 = validateParameter(valid_402657500, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657500 != nil:
    section.add "Version", valid_402657500
  var valid_402657501 = query.getOrDefault("Action")
  valid_402657501 = validateParameter(valid_402657501, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657501 != nil:
    section.add "Action", valid_402657501
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
  var valid_402657502 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Security-Token", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Signature")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Signature", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657504
  var valid_402657505 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657505 = validateParameter(valid_402657505, JString,
                                      required = false, default = nil)
  if valid_402657505 != nil:
    section.add "X-Amz-Algorithm", valid_402657505
  var valid_402657506 = header.getOrDefault("X-Amz-Date")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "X-Amz-Date", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-Credential")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-Credential", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657508
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_402657509 = formData.getOrDefault("Marker")
  valid_402657509 = validateParameter(valid_402657509, JString,
                                      required = false, default = nil)
  if valid_402657509 != nil:
    section.add "Marker", valid_402657509
  var valid_402657510 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657510 = validateParameter(valid_402657510, JString,
                                      required = false, default = nil)
  if valid_402657510 != nil:
    section.add "DBSubnetGroupName", valid_402657510
  var valid_402657511 = formData.getOrDefault("MaxRecords")
  valid_402657511 = validateParameter(valid_402657511, JInt, required = false,
                                      default = nil)
  if valid_402657511 != nil:
    section.add "MaxRecords", valid_402657511
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657512: Call_PostDescribeDBSubnetGroups_402657497;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657512.validator(path, query, header, formData, body, _)
  let scheme = call_402657512.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657512.makeUrl(scheme.get, call_402657512.host, call_402657512.base,
                                   call_402657512.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657512, uri, valid, _)

proc call*(call_402657513: Call_PostDescribeDBSubnetGroups_402657497;
           Marker: string = ""; DBSubnetGroupName: string = "";
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           Action: string = "DescribeDBSubnetGroups"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  var query_402657514 = newJObject()
  var formData_402657515 = newJObject()
  add(formData_402657515, "Marker", newJString(Marker))
  add(formData_402657515, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657514, "Version", newJString(Version))
  add(formData_402657515, "MaxRecords", newJInt(MaxRecords))
  add(query_402657514, "Action", newJString(Action))
  result = call_402657513.call(nil, query_402657514, nil, formData_402657515,
                               nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_402657497(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_402657498, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_402657499,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_402657479 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSubnetGroups_402657481(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_402657480(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSubnetGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657482 = query.getOrDefault("DBSubnetGroupName")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "DBSubnetGroupName", valid_402657482
  var valid_402657483 = query.getOrDefault("MaxRecords")
  valid_402657483 = validateParameter(valid_402657483, JInt, required = false,
                                      default = nil)
  if valid_402657483 != nil:
    section.add "MaxRecords", valid_402657483
  var valid_402657484 = query.getOrDefault("Marker")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "Marker", valid_402657484
  var valid_402657485 = query.getOrDefault("Version")
  valid_402657485 = validateParameter(valid_402657485, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657485 != nil:
    section.add "Version", valid_402657485
  var valid_402657486 = query.getOrDefault("Action")
  valid_402657486 = validateParameter(valid_402657486, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657486 != nil:
    section.add "Action", valid_402657486
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
  var valid_402657487 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Security-Token", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Signature")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Signature", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657489
  var valid_402657490 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657490 = validateParameter(valid_402657490, JString,
                                      required = false, default = nil)
  if valid_402657490 != nil:
    section.add "X-Amz-Algorithm", valid_402657490
  var valid_402657491 = header.getOrDefault("X-Amz-Date")
  valid_402657491 = validateParameter(valid_402657491, JString,
                                      required = false, default = nil)
  if valid_402657491 != nil:
    section.add "X-Amz-Date", valid_402657491
  var valid_402657492 = header.getOrDefault("X-Amz-Credential")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-Credential", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657494: Call_GetDescribeDBSubnetGroups_402657479;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657494.validator(path, query, header, formData, body, _)
  let scheme = call_402657494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657494.makeUrl(scheme.get, call_402657494.host, call_402657494.base,
                                   call_402657494.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657494, uri, valid, _)

proc call*(call_402657495: Call_GetDescribeDBSubnetGroups_402657479;
           DBSubnetGroupName: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeDBSubnetGroups"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657496 = newJObject()
  add(query_402657496, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657496, "MaxRecords", newJInt(MaxRecords))
  add(query_402657496, "Marker", newJString(Marker))
  add(query_402657496, "Version", newJString(Version))
  add(query_402657496, "Action", newJString(Action))
  result = call_402657495.call(nil, query_402657496, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_402657479(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_402657480, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_402657481,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_402657534 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEngineDefaultParameters_402657536(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_402657535(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657537 = query.getOrDefault("Version")
  valid_402657537 = validateParameter(valid_402657537, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657537 != nil:
    section.add "Version", valid_402657537
  var valid_402657538 = query.getOrDefault("Action")
  valid_402657538 = validateParameter(valid_402657538, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657538 != nil:
    section.add "Action", valid_402657538
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
  var valid_402657539 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "X-Amz-Security-Token", valid_402657539
  var valid_402657540 = header.getOrDefault("X-Amz-Signature")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "X-Amz-Signature", valid_402657540
  var valid_402657541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Algorithm", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Date")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Date", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-Credential")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-Credential", valid_402657544
  var valid_402657545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657545
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_402657546 = formData.getOrDefault("Marker")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "Marker", valid_402657546
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657547 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657547 = validateParameter(valid_402657547, JString, required = true,
                                      default = nil)
  if valid_402657547 != nil:
    section.add "DBParameterGroupFamily", valid_402657547
  var valid_402657548 = formData.getOrDefault("MaxRecords")
  valid_402657548 = validateParameter(valid_402657548, JInt, required = false,
                                      default = nil)
  if valid_402657548 != nil:
    section.add "MaxRecords", valid_402657548
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657549: Call_PostDescribeEngineDefaultParameters_402657534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657549.validator(path, query, header, formData, body, _)
  let scheme = call_402657549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657549.makeUrl(scheme.get, call_402657549.host, call_402657549.base,
                                   call_402657549.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657549, uri, valid, _)

proc call*(call_402657550: Call_PostDescribeEngineDefaultParameters_402657534;
           DBParameterGroupFamily: string; Marker: string = "";
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           Action: string = "DescribeEngineDefaultParameters"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  var query_402657551 = newJObject()
  var formData_402657552 = newJObject()
  add(formData_402657552, "Marker", newJString(Marker))
  add(formData_402657552, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657551, "Version", newJString(Version))
  add(formData_402657552, "MaxRecords", newJInt(MaxRecords))
  add(query_402657551, "Action", newJString(Action))
  result = call_402657550.call(nil, query_402657551, nil, formData_402657552,
                               nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_402657534(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_402657535,
    base: "/", makeUrl: url_PostDescribeEngineDefaultParameters_402657536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_402657516 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEngineDefaultParameters_402657518(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_402657517(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657519 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657519 = validateParameter(valid_402657519, JString, required = true,
                                      default = nil)
  if valid_402657519 != nil:
    section.add "DBParameterGroupFamily", valid_402657519
  var valid_402657520 = query.getOrDefault("MaxRecords")
  valid_402657520 = validateParameter(valid_402657520, JInt, required = false,
                                      default = nil)
  if valid_402657520 != nil:
    section.add "MaxRecords", valid_402657520
  var valid_402657521 = query.getOrDefault("Marker")
  valid_402657521 = validateParameter(valid_402657521, JString,
                                      required = false, default = nil)
  if valid_402657521 != nil:
    section.add "Marker", valid_402657521
  var valid_402657522 = query.getOrDefault("Version")
  valid_402657522 = validateParameter(valid_402657522, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657522 != nil:
    section.add "Version", valid_402657522
  var valid_402657523 = query.getOrDefault("Action")
  valid_402657523 = validateParameter(valid_402657523, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657523 != nil:
    section.add "Action", valid_402657523
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
  var valid_402657524 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Security-Token", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Signature")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Signature", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Algorithm", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Date")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Date", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-Credential")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-Credential", valid_402657529
  var valid_402657530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657530 = validateParameter(valid_402657530, JString,
                                      required = false, default = nil)
  if valid_402657530 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657531: Call_GetDescribeEngineDefaultParameters_402657516;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657531.validator(path, query, header, formData, body, _)
  let scheme = call_402657531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657531.makeUrl(scheme.get, call_402657531.host, call_402657531.base,
                                   call_402657531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657531, uri, valid, _)

proc call*(call_402657532: Call_GetDescribeEngineDefaultParameters_402657516;
           DBParameterGroupFamily: string; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeEngineDefaultParameters"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657533 = newJObject()
  add(query_402657533, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657533, "MaxRecords", newJInt(MaxRecords))
  add(query_402657533, "Marker", newJString(Marker))
  add(query_402657533, "Version", newJString(Version))
  add(query_402657533, "Action", newJString(Action))
  result = call_402657532.call(nil, query_402657533, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_402657516(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_402657517, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_402657518,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_402657569 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventCategories_402657571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_402657570(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657572 = query.getOrDefault("Version")
  valid_402657572 = validateParameter(valid_402657572, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657572 != nil:
    section.add "Version", valid_402657572
  var valid_402657573 = query.getOrDefault("Action")
  valid_402657573 = validateParameter(valid_402657573, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657573 != nil:
    section.add "Action", valid_402657573
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
  var valid_402657574 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657574 = validateParameter(valid_402657574, JString,
                                      required = false, default = nil)
  if valid_402657574 != nil:
    section.add "X-Amz-Security-Token", valid_402657574
  var valid_402657575 = header.getOrDefault("X-Amz-Signature")
  valid_402657575 = validateParameter(valid_402657575, JString,
                                      required = false, default = nil)
  if valid_402657575 != nil:
    section.add "X-Amz-Signature", valid_402657575
  var valid_402657576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Algorithm", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Date")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Date", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-Credential")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-Credential", valid_402657579
  var valid_402657580 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657580 = validateParameter(valid_402657580, JString,
                                      required = false, default = nil)
  if valid_402657580 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657580
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  section = newJObject()
  var valid_402657581 = formData.getOrDefault("SourceType")
  valid_402657581 = validateParameter(valid_402657581, JString,
                                      required = false, default = nil)
  if valid_402657581 != nil:
    section.add "SourceType", valid_402657581
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657582: Call_PostDescribeEventCategories_402657569;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657582.validator(path, query, header, formData, body, _)
  let scheme = call_402657582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657582.makeUrl(scheme.get, call_402657582.host, call_402657582.base,
                                   call_402657582.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657582, uri, valid, _)

proc call*(call_402657583: Call_PostDescribeEventCategories_402657569;
           SourceType: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeEventCategories"): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657584 = newJObject()
  var formData_402657585 = newJObject()
  add(formData_402657585, "SourceType", newJString(SourceType))
  add(query_402657584, "Version", newJString(Version))
  add(query_402657584, "Action", newJString(Action))
  result = call_402657583.call(nil, query_402657584, nil, formData_402657585,
                               nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_402657569(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_402657570, base: "/",
    makeUrl: url_PostDescribeEventCategories_402657571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_402657553 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventCategories_402657555(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_402657554(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   SourceType: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657556 = query.getOrDefault("Version")
  valid_402657556 = validateParameter(valid_402657556, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657556 != nil:
    section.add "Version", valid_402657556
  var valid_402657557 = query.getOrDefault("SourceType")
  valid_402657557 = validateParameter(valid_402657557, JString,
                                      required = false, default = nil)
  if valid_402657557 != nil:
    section.add "SourceType", valid_402657557
  var valid_402657558 = query.getOrDefault("Action")
  valid_402657558 = validateParameter(valid_402657558, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657558 != nil:
    section.add "Action", valid_402657558
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
  var valid_402657559 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657559 = validateParameter(valid_402657559, JString,
                                      required = false, default = nil)
  if valid_402657559 != nil:
    section.add "X-Amz-Security-Token", valid_402657559
  var valid_402657560 = header.getOrDefault("X-Amz-Signature")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "X-Amz-Signature", valid_402657560
  var valid_402657561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Algorithm", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Date")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Date", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-Credential")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-Credential", valid_402657564
  var valid_402657565 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657565 = validateParameter(valid_402657565, JString,
                                      required = false, default = nil)
  if valid_402657565 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657565
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657566: Call_GetDescribeEventCategories_402657553;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657566.validator(path, query, header, formData, body, _)
  let scheme = call_402657566.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657566.makeUrl(scheme.get, call_402657566.host, call_402657566.base,
                                   call_402657566.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657566, uri, valid, _)

proc call*(call_402657567: Call_GetDescribeEventCategories_402657553;
           Version: string = "2013-02-12"; SourceType: string = "";
           Action: string = "DescribeEventCategories"): Recallable =
  ## getDescribeEventCategories
  ##   Version: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402657568 = newJObject()
  add(query_402657568, "Version", newJString(Version))
  add(query_402657568, "SourceType", newJString(SourceType))
  add(query_402657568, "Action", newJString(Action))
  result = call_402657567.call(nil, query_402657568, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_402657553(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_402657554, base: "/",
    makeUrl: url_GetDescribeEventCategories_402657555,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_402657604 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventSubscriptions_402657606(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_402657605(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657607 = query.getOrDefault("Version")
  valid_402657607 = validateParameter(valid_402657607, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657607 != nil:
    section.add "Version", valid_402657607
  var valid_402657608 = query.getOrDefault("Action")
  valid_402657608 = validateParameter(valid_402657608, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657608 != nil:
    section.add "Action", valid_402657608
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
  var valid_402657609 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-Security-Token", valid_402657609
  var valid_402657610 = header.getOrDefault("X-Amz-Signature")
  valid_402657610 = validateParameter(valid_402657610, JString,
                                      required = false, default = nil)
  if valid_402657610 != nil:
    section.add "X-Amz-Signature", valid_402657610
  var valid_402657611 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657611 = validateParameter(valid_402657611, JString,
                                      required = false, default = nil)
  if valid_402657611 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657611
  var valid_402657612 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657612 = validateParameter(valid_402657612, JString,
                                      required = false, default = nil)
  if valid_402657612 != nil:
    section.add "X-Amz-Algorithm", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-Date")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Date", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-Credential")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-Credential", valid_402657614
  var valid_402657615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657615 = validateParameter(valid_402657615, JString,
                                      required = false, default = nil)
  if valid_402657615 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657615
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_402657616 = formData.getOrDefault("Marker")
  valid_402657616 = validateParameter(valid_402657616, JString,
                                      required = false, default = nil)
  if valid_402657616 != nil:
    section.add "Marker", valid_402657616
  var valid_402657617 = formData.getOrDefault("MaxRecords")
  valid_402657617 = validateParameter(valid_402657617, JInt, required = false,
                                      default = nil)
  if valid_402657617 != nil:
    section.add "MaxRecords", valid_402657617
  var valid_402657618 = formData.getOrDefault("SubscriptionName")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "SubscriptionName", valid_402657618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657619: Call_PostDescribeEventSubscriptions_402657604;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657619.validator(path, query, header, formData, body, _)
  let scheme = call_402657619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657619.makeUrl(scheme.get, call_402657619.host, call_402657619.base,
                                   call_402657619.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657619, uri, valid, _)

proc call*(call_402657620: Call_PostDescribeEventSubscriptions_402657604;
           Marker: string = ""; Version: string = "2013-02-12";
           MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
           SubscriptionName: string = ""): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   SubscriptionName: string
  var query_402657621 = newJObject()
  var formData_402657622 = newJObject()
  add(formData_402657622, "Marker", newJString(Marker))
  add(query_402657621, "Version", newJString(Version))
  add(formData_402657622, "MaxRecords", newJInt(MaxRecords))
  add(query_402657621, "Action", newJString(Action))
  add(formData_402657622, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657620.call(nil, query_402657621, nil, formData_402657622,
                               nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_402657604(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_402657605, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_402657606,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_402657586 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventSubscriptions_402657588(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_402657587(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   SubscriptionName: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657589 = query.getOrDefault("MaxRecords")
  valid_402657589 = validateParameter(valid_402657589, JInt, required = false,
                                      default = nil)
  if valid_402657589 != nil:
    section.add "MaxRecords", valid_402657589
  var valid_402657590 = query.getOrDefault("Marker")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "Marker", valid_402657590
  var valid_402657591 = query.getOrDefault("Version")
  valid_402657591 = validateParameter(valid_402657591, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657591 != nil:
    section.add "Version", valid_402657591
  var valid_402657592 = query.getOrDefault("SubscriptionName")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "SubscriptionName", valid_402657592
  var valid_402657593 = query.getOrDefault("Action")
  valid_402657593 = validateParameter(valid_402657593, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657593 != nil:
    section.add "Action", valid_402657593
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
  var valid_402657594 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657594 = validateParameter(valid_402657594, JString,
                                      required = false, default = nil)
  if valid_402657594 != nil:
    section.add "X-Amz-Security-Token", valid_402657594
  var valid_402657595 = header.getOrDefault("X-Amz-Signature")
  valid_402657595 = validateParameter(valid_402657595, JString,
                                      required = false, default = nil)
  if valid_402657595 != nil:
    section.add "X-Amz-Signature", valid_402657595
  var valid_402657596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657596 = validateParameter(valid_402657596, JString,
                                      required = false, default = nil)
  if valid_402657596 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657596
  var valid_402657597 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657597 = validateParameter(valid_402657597, JString,
                                      required = false, default = nil)
  if valid_402657597 != nil:
    section.add "X-Amz-Algorithm", valid_402657597
  var valid_402657598 = header.getOrDefault("X-Amz-Date")
  valid_402657598 = validateParameter(valid_402657598, JString,
                                      required = false, default = nil)
  if valid_402657598 != nil:
    section.add "X-Amz-Date", valid_402657598
  var valid_402657599 = header.getOrDefault("X-Amz-Credential")
  valid_402657599 = validateParameter(valid_402657599, JString,
                                      required = false, default = nil)
  if valid_402657599 != nil:
    section.add "X-Amz-Credential", valid_402657599
  var valid_402657600 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657600 = validateParameter(valid_402657600, JString,
                                      required = false, default = nil)
  if valid_402657600 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657601: Call_GetDescribeEventSubscriptions_402657586;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657601.validator(path, query, header, formData, body, _)
  let scheme = call_402657601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657601.makeUrl(scheme.get, call_402657601.host, call_402657601.base,
                                   call_402657601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657601, uri, valid, _)

proc call*(call_402657602: Call_GetDescribeEventSubscriptions_402657586;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-02-12"; SubscriptionName: string = "";
           Action: string = "DescribeEventSubscriptions"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   SubscriptionName: string
  ##   Action: string (required)
  var query_402657603 = newJObject()
  add(query_402657603, "MaxRecords", newJInt(MaxRecords))
  add(query_402657603, "Marker", newJString(Marker))
  add(query_402657603, "Version", newJString(Version))
  add(query_402657603, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657603, "Action", newJString(Action))
  result = call_402657602.call(nil, query_402657603, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_402657586(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_402657587, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_402657588,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_402657646 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEvents_402657648(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_402657647(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657649 = query.getOrDefault("Version")
  valid_402657649 = validateParameter(valid_402657649, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657649 != nil:
    section.add "Version", valid_402657649
  var valid_402657650 = query.getOrDefault("Action")
  valid_402657650 = validateParameter(valid_402657650, JString, required = true,
                                      default = newJString("DescribeEvents"))
  if valid_402657650 != nil:
    section.add "Action", valid_402657650
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
  var valid_402657651 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Security-Token", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-Signature")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-Signature", valid_402657652
  var valid_402657653 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657653
  var valid_402657654 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657654 = validateParameter(valid_402657654, JString,
                                      required = false, default = nil)
  if valid_402657654 != nil:
    section.add "X-Amz-Algorithm", valid_402657654
  var valid_402657655 = header.getOrDefault("X-Amz-Date")
  valid_402657655 = validateParameter(valid_402657655, JString,
                                      required = false, default = nil)
  if valid_402657655 != nil:
    section.add "X-Amz-Date", valid_402657655
  var valid_402657656 = header.getOrDefault("X-Amz-Credential")
  valid_402657656 = validateParameter(valid_402657656, JString,
                                      required = false, default = nil)
  if valid_402657656 != nil:
    section.add "X-Amz-Credential", valid_402657656
  var valid_402657657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657657 = validateParameter(valid_402657657, JString,
                                      required = false, default = nil)
  if valid_402657657 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657657
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SourceType: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   MaxRecords: JInt
  ##   SourceIdentifier: JString
  section = newJObject()
  var valid_402657658 = formData.getOrDefault("Marker")
  valid_402657658 = validateParameter(valid_402657658, JString,
                                      required = false, default = nil)
  if valid_402657658 != nil:
    section.add "Marker", valid_402657658
  var valid_402657659 = formData.getOrDefault("SourceType")
  valid_402657659 = validateParameter(valid_402657659, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657659 != nil:
    section.add "SourceType", valid_402657659
  var valid_402657660 = formData.getOrDefault("EventCategories")
  valid_402657660 = validateParameter(valid_402657660, JArray, required = false,
                                      default = nil)
  if valid_402657660 != nil:
    section.add "EventCategories", valid_402657660
  var valid_402657661 = formData.getOrDefault("Duration")
  valid_402657661 = validateParameter(valid_402657661, JInt, required = false,
                                      default = nil)
  if valid_402657661 != nil:
    section.add "Duration", valid_402657661
  var valid_402657662 = formData.getOrDefault("EndTime")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "EndTime", valid_402657662
  var valid_402657663 = formData.getOrDefault("StartTime")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "StartTime", valid_402657663
  var valid_402657664 = formData.getOrDefault("MaxRecords")
  valid_402657664 = validateParameter(valid_402657664, JInt, required = false,
                                      default = nil)
  if valid_402657664 != nil:
    section.add "MaxRecords", valid_402657664
  var valid_402657665 = formData.getOrDefault("SourceIdentifier")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "SourceIdentifier", valid_402657665
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657666: Call_PostDescribeEvents_402657646;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657666.validator(path, query, header, formData, body, _)
  let scheme = call_402657666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657666.makeUrl(scheme.get, call_402657666.host, call_402657666.base,
                                   call_402657666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657666, uri, valid, _)

proc call*(call_402657667: Call_PostDescribeEvents_402657646;
           Marker: string = ""; SourceType: string = "db-instance";
           EventCategories: JsonNode = nil; Version: string = "2013-02-12";
           Duration: int = 0; EndTime: string = ""; StartTime: string = "";
           MaxRecords: int = 0; Action: string = "DescribeEvents";
           SourceIdentifier: string = ""): Recallable =
  ## postDescribeEvents
  ##   Marker: string
  ##   SourceType: string
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   Duration: int
  ##   EndTime: string
  ##   StartTime: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   SourceIdentifier: string
  var query_402657668 = newJObject()
  var formData_402657669 = newJObject()
  add(formData_402657669, "Marker", newJString(Marker))
  add(formData_402657669, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_402657669.add "EventCategories", EventCategories
  add(query_402657668, "Version", newJString(Version))
  add(formData_402657669, "Duration", newJInt(Duration))
  add(formData_402657669, "EndTime", newJString(EndTime))
  add(formData_402657669, "StartTime", newJString(StartTime))
  add(formData_402657669, "MaxRecords", newJInt(MaxRecords))
  add(query_402657668, "Action", newJString(Action))
  add(formData_402657669, "SourceIdentifier", newJString(SourceIdentifier))
  result = call_402657667.call(nil, query_402657668, nil, formData_402657669,
                               nil)

var postDescribeEvents* = Call_PostDescribeEvents_402657646(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_402657647, base: "/",
    makeUrl: url_PostDescribeEvents_402657648,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_402657623 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEvents_402657625(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_402657624(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndTime: JString
  ##   SourceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Version: JString (required)
  ##   Duration: JInt
  ##   StartTime: JString
  ##   SourceType: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657626 = query.getOrDefault("EndTime")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "EndTime", valid_402657626
  var valid_402657627 = query.getOrDefault("SourceIdentifier")
  valid_402657627 = validateParameter(valid_402657627, JString,
                                      required = false, default = nil)
  if valid_402657627 != nil:
    section.add "SourceIdentifier", valid_402657627
  var valid_402657628 = query.getOrDefault("MaxRecords")
  valid_402657628 = validateParameter(valid_402657628, JInt, required = false,
                                      default = nil)
  if valid_402657628 != nil:
    section.add "MaxRecords", valid_402657628
  var valid_402657629 = query.getOrDefault("Marker")
  valid_402657629 = validateParameter(valid_402657629, JString,
                                      required = false, default = nil)
  if valid_402657629 != nil:
    section.add "Marker", valid_402657629
  var valid_402657630 = query.getOrDefault("EventCategories")
  valid_402657630 = validateParameter(valid_402657630, JArray, required = false,
                                      default = nil)
  if valid_402657630 != nil:
    section.add "EventCategories", valid_402657630
  var valid_402657631 = query.getOrDefault("Version")
  valid_402657631 = validateParameter(valid_402657631, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657631 != nil:
    section.add "Version", valid_402657631
  var valid_402657632 = query.getOrDefault("Duration")
  valid_402657632 = validateParameter(valid_402657632, JInt, required = false,
                                      default = nil)
  if valid_402657632 != nil:
    section.add "Duration", valid_402657632
  var valid_402657633 = query.getOrDefault("StartTime")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "StartTime", valid_402657633
  var valid_402657634 = query.getOrDefault("SourceType")
  valid_402657634 = validateParameter(valid_402657634, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657634 != nil:
    section.add "SourceType", valid_402657634
  var valid_402657635 = query.getOrDefault("Action")
  valid_402657635 = validateParameter(valid_402657635, JString, required = true,
                                      default = newJString("DescribeEvents"))
  if valid_402657635 != nil:
    section.add "Action", valid_402657635
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
  var valid_402657636 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "X-Amz-Security-Token", valid_402657636
  var valid_402657637 = header.getOrDefault("X-Amz-Signature")
  valid_402657637 = validateParameter(valid_402657637, JString,
                                      required = false, default = nil)
  if valid_402657637 != nil:
    section.add "X-Amz-Signature", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657638
  var valid_402657639 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657639 = validateParameter(valid_402657639, JString,
                                      required = false, default = nil)
  if valid_402657639 != nil:
    section.add "X-Amz-Algorithm", valid_402657639
  var valid_402657640 = header.getOrDefault("X-Amz-Date")
  valid_402657640 = validateParameter(valid_402657640, JString,
                                      required = false, default = nil)
  if valid_402657640 != nil:
    section.add "X-Amz-Date", valid_402657640
  var valid_402657641 = header.getOrDefault("X-Amz-Credential")
  valid_402657641 = validateParameter(valid_402657641, JString,
                                      required = false, default = nil)
  if valid_402657641 != nil:
    section.add "X-Amz-Credential", valid_402657641
  var valid_402657642 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657642 = validateParameter(valid_402657642, JString,
                                      required = false, default = nil)
  if valid_402657642 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657642
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657643: Call_GetDescribeEvents_402657623;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657643.validator(path, query, header, formData, body, _)
  let scheme = call_402657643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657643.makeUrl(scheme.get, call_402657643.host, call_402657643.base,
                                   call_402657643.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657643, uri, valid, _)

proc call*(call_402657644: Call_GetDescribeEvents_402657623;
           EndTime: string = ""; SourceIdentifier: string = "";
           MaxRecords: int = 0; Marker: string = "";
           EventCategories: JsonNode = nil; Version: string = "2013-02-12";
           Duration: int = 0; StartTime: string = "";
           SourceType: string = "db-instance"; Action: string = "DescribeEvents"): Recallable =
  ## getDescribeEvents
  ##   EndTime: string
  ##   SourceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   Duration: int
  ##   StartTime: string
  ##   SourceType: string
  ##   Action: string (required)
  var query_402657645 = newJObject()
  add(query_402657645, "EndTime", newJString(EndTime))
  add(query_402657645, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402657645, "MaxRecords", newJInt(MaxRecords))
  add(query_402657645, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_402657645.add "EventCategories", EventCategories
  add(query_402657645, "Version", newJString(Version))
  add(query_402657645, "Duration", newJInt(Duration))
  add(query_402657645, "StartTime", newJString(StartTime))
  add(query_402657645, "SourceType", newJString(SourceType))
  add(query_402657645, "Action", newJString(Action))
  result = call_402657644.call(nil, query_402657645, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_402657623(
    name: "getDescribeEvents", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_GetDescribeEvents_402657624, base: "/",
    makeUrl: url_GetDescribeEvents_402657625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_402657689 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroupOptions_402657691(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_402657690(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657692 = query.getOrDefault("Version")
  valid_402657692 = validateParameter(valid_402657692, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657692 != nil:
    section.add "Version", valid_402657692
  var valid_402657693 = query.getOrDefault("Action")
  valid_402657693 = validateParameter(valid_402657693, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657693 != nil:
    section.add "Action", valid_402657693
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
  var valid_402657694 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Security-Token", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Signature")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Signature", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Algorithm", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-Date")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-Date", valid_402657698
  var valid_402657699 = header.getOrDefault("X-Amz-Credential")
  valid_402657699 = validateParameter(valid_402657699, JString,
                                      required = false, default = nil)
  if valid_402657699 != nil:
    section.add "X-Amz-Credential", valid_402657699
  var valid_402657700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657700 = validateParameter(valid_402657700, JString,
                                      required = false, default = nil)
  if valid_402657700 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657700
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657701 = formData.getOrDefault("Marker")
  valid_402657701 = validateParameter(valid_402657701, JString,
                                      required = false, default = nil)
  if valid_402657701 != nil:
    section.add "Marker", valid_402657701
  assert formData != nil,
         "formData argument is necessary due to required `EngineName` field"
  var valid_402657702 = formData.getOrDefault("EngineName")
  valid_402657702 = validateParameter(valid_402657702, JString, required = true,
                                      default = nil)
  if valid_402657702 != nil:
    section.add "EngineName", valid_402657702
  var valid_402657703 = formData.getOrDefault("MaxRecords")
  valid_402657703 = validateParameter(valid_402657703, JInt, required = false,
                                      default = nil)
  if valid_402657703 != nil:
    section.add "MaxRecords", valid_402657703
  var valid_402657704 = formData.getOrDefault("MajorEngineVersion")
  valid_402657704 = validateParameter(valid_402657704, JString,
                                      required = false, default = nil)
  if valid_402657704 != nil:
    section.add "MajorEngineVersion", valid_402657704
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657705: Call_PostDescribeOptionGroupOptions_402657689;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657705.validator(path, query, header, formData, body, _)
  let scheme = call_402657705.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657705.makeUrl(scheme.get, call_402657705.host, call_402657705.base,
                                   call_402657705.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657705, uri, valid, _)

proc call*(call_402657706: Call_PostDescribeOptionGroupOptions_402657689;
           EngineName: string; Marker: string = "";
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           Action: string = "DescribeOptionGroupOptions";
           MajorEngineVersion: string = ""): Recallable =
  ## postDescribeOptionGroupOptions
  ##   Marker: string
  ##   EngineName: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   MajorEngineVersion: string
  var query_402657707 = newJObject()
  var formData_402657708 = newJObject()
  add(formData_402657708, "Marker", newJString(Marker))
  add(formData_402657708, "EngineName", newJString(EngineName))
  add(query_402657707, "Version", newJString(Version))
  add(formData_402657708, "MaxRecords", newJInt(MaxRecords))
  add(query_402657707, "Action", newJString(Action))
  add(formData_402657708, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657706.call(nil, query_402657707, nil, formData_402657708,
                               nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_402657689(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_402657690, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_402657691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_402657670 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroupOptions_402657672(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_402657671(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657673 = query.getOrDefault("MaxRecords")
  valid_402657673 = validateParameter(valid_402657673, JInt, required = false,
                                      default = nil)
  if valid_402657673 != nil:
    section.add "MaxRecords", valid_402657673
  var valid_402657674 = query.getOrDefault("Marker")
  valid_402657674 = validateParameter(valid_402657674, JString,
                                      required = false, default = nil)
  if valid_402657674 != nil:
    section.add "Marker", valid_402657674
  var valid_402657675 = query.getOrDefault("Version")
  valid_402657675 = validateParameter(valid_402657675, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657675 != nil:
    section.add "Version", valid_402657675
  var valid_402657676 = query.getOrDefault("Action")
  valid_402657676 = validateParameter(valid_402657676, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657676 != nil:
    section.add "Action", valid_402657676
  var valid_402657677 = query.getOrDefault("EngineName")
  valid_402657677 = validateParameter(valid_402657677, JString, required = true,
                                      default = nil)
  if valid_402657677 != nil:
    section.add "EngineName", valid_402657677
  var valid_402657678 = query.getOrDefault("MajorEngineVersion")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "MajorEngineVersion", valid_402657678
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
  var valid_402657679 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Security-Token", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Signature")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Signature", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657681
  var valid_402657682 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657682 = validateParameter(valid_402657682, JString,
                                      required = false, default = nil)
  if valid_402657682 != nil:
    section.add "X-Amz-Algorithm", valid_402657682
  var valid_402657683 = header.getOrDefault("X-Amz-Date")
  valid_402657683 = validateParameter(valid_402657683, JString,
                                      required = false, default = nil)
  if valid_402657683 != nil:
    section.add "X-Amz-Date", valid_402657683
  var valid_402657684 = header.getOrDefault("X-Amz-Credential")
  valid_402657684 = validateParameter(valid_402657684, JString,
                                      required = false, default = nil)
  if valid_402657684 != nil:
    section.add "X-Amz-Credential", valid_402657684
  var valid_402657685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657685 = validateParameter(valid_402657685, JString,
                                      required = false, default = nil)
  if valid_402657685 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657685
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657686: Call_GetDescribeOptionGroupOptions_402657670;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657686.validator(path, query, header, formData, body, _)
  let scheme = call_402657686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657686.makeUrl(scheme.get, call_402657686.host, call_402657686.base,
                                   call_402657686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657686, uri, valid, _)

proc call*(call_402657687: Call_GetDescribeOptionGroupOptions_402657670;
           EngineName: string; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-02-12";
           Action: string = "DescribeOptionGroupOptions";
           MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_402657688 = newJObject()
  add(query_402657688, "MaxRecords", newJInt(MaxRecords))
  add(query_402657688, "Marker", newJString(Marker))
  add(query_402657688, "Version", newJString(Version))
  add(query_402657688, "Action", newJString(Action))
  add(query_402657688, "EngineName", newJString(EngineName))
  add(query_402657688, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657687.call(nil, query_402657688, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_402657670(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_402657671, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_402657672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_402657729 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroups_402657731(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_402657730(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657732 = query.getOrDefault("Version")
  valid_402657732 = validateParameter(valid_402657732, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657732 != nil:
    section.add "Version", valid_402657732
  var valid_402657733 = query.getOrDefault("Action")
  valid_402657733 = validateParameter(valid_402657733, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657733 != nil:
    section.add "Action", valid_402657733
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
  var valid_402657734 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657734 = validateParameter(valid_402657734, JString,
                                      required = false, default = nil)
  if valid_402657734 != nil:
    section.add "X-Amz-Security-Token", valid_402657734
  var valid_402657735 = header.getOrDefault("X-Amz-Signature")
  valid_402657735 = validateParameter(valid_402657735, JString,
                                      required = false, default = nil)
  if valid_402657735 != nil:
    section.add "X-Amz-Signature", valid_402657735
  var valid_402657736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657736 = validateParameter(valid_402657736, JString,
                                      required = false, default = nil)
  if valid_402657736 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657736
  var valid_402657737 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657737 = validateParameter(valid_402657737, JString,
                                      required = false, default = nil)
  if valid_402657737 != nil:
    section.add "X-Amz-Algorithm", valid_402657737
  var valid_402657738 = header.getOrDefault("X-Amz-Date")
  valid_402657738 = validateParameter(valid_402657738, JString,
                                      required = false, default = nil)
  if valid_402657738 != nil:
    section.add "X-Amz-Date", valid_402657738
  var valid_402657739 = header.getOrDefault("X-Amz-Credential")
  valid_402657739 = validateParameter(valid_402657739, JString,
                                      required = false, default = nil)
  if valid_402657739 != nil:
    section.add "X-Amz-Credential", valid_402657739
  var valid_402657740 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657740 = validateParameter(valid_402657740, JString,
                                      required = false, default = nil)
  if valid_402657740 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657740
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657741 = formData.getOrDefault("Marker")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "Marker", valid_402657741
  var valid_402657742 = formData.getOrDefault("EngineName")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "EngineName", valid_402657742
  var valid_402657743 = formData.getOrDefault("MaxRecords")
  valid_402657743 = validateParameter(valid_402657743, JInt, required = false,
                                      default = nil)
  if valid_402657743 != nil:
    section.add "MaxRecords", valid_402657743
  var valid_402657744 = formData.getOrDefault("OptionGroupName")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "OptionGroupName", valid_402657744
  var valid_402657745 = formData.getOrDefault("MajorEngineVersion")
  valid_402657745 = validateParameter(valid_402657745, JString,
                                      required = false, default = nil)
  if valid_402657745 != nil:
    section.add "MajorEngineVersion", valid_402657745
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657746: Call_PostDescribeOptionGroups_402657729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657746.validator(path, query, header, formData, body, _)
  let scheme = call_402657746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657746.makeUrl(scheme.get, call_402657746.host, call_402657746.base,
                                   call_402657746.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657746, uri, valid, _)

proc call*(call_402657747: Call_PostDescribeOptionGroups_402657729;
           Marker: string = ""; EngineName: string = "";
           Version: string = "2013-02-12"; MaxRecords: int = 0;
           OptionGroupName: string = "";
           Action: string = "DescribeOptionGroups";
           MajorEngineVersion: string = ""): Recallable =
  ## postDescribeOptionGroups
  ##   Marker: string
  ##   EngineName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   MajorEngineVersion: string
  var query_402657748 = newJObject()
  var formData_402657749 = newJObject()
  add(formData_402657749, "Marker", newJString(Marker))
  add(formData_402657749, "EngineName", newJString(EngineName))
  add(query_402657748, "Version", newJString(Version))
  add(formData_402657749, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657749, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657748, "Action", newJString(Action))
  add(formData_402657749, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657747.call(nil, query_402657748, nil, formData_402657749,
                               nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_402657729(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_402657730, base: "/",
    makeUrl: url_PostDescribeOptionGroups_402657731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_402657709 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroups_402657711(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_402657710(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657712 = query.getOrDefault("OptionGroupName")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "OptionGroupName", valid_402657712
  var valid_402657713 = query.getOrDefault("MaxRecords")
  valid_402657713 = validateParameter(valid_402657713, JInt, required = false,
                                      default = nil)
  if valid_402657713 != nil:
    section.add "MaxRecords", valid_402657713
  var valid_402657714 = query.getOrDefault("Marker")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "Marker", valid_402657714
  var valid_402657715 = query.getOrDefault("Version")
  valid_402657715 = validateParameter(valid_402657715, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657715 != nil:
    section.add "Version", valid_402657715
  var valid_402657716 = query.getOrDefault("Action")
  valid_402657716 = validateParameter(valid_402657716, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657716 != nil:
    section.add "Action", valid_402657716
  var valid_402657717 = query.getOrDefault("EngineName")
  valid_402657717 = validateParameter(valid_402657717, JString,
                                      required = false, default = nil)
  if valid_402657717 != nil:
    section.add "EngineName", valid_402657717
  var valid_402657718 = query.getOrDefault("MajorEngineVersion")
  valid_402657718 = validateParameter(valid_402657718, JString,
                                      required = false, default = nil)
  if valid_402657718 != nil:
    section.add "MajorEngineVersion", valid_402657718
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
  var valid_402657719 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657719 = validateParameter(valid_402657719, JString,
                                      required = false, default = nil)
  if valid_402657719 != nil:
    section.add "X-Amz-Security-Token", valid_402657719
  var valid_402657720 = header.getOrDefault("X-Amz-Signature")
  valid_402657720 = validateParameter(valid_402657720, JString,
                                      required = false, default = nil)
  if valid_402657720 != nil:
    section.add "X-Amz-Signature", valid_402657720
  var valid_402657721 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657721 = validateParameter(valid_402657721, JString,
                                      required = false, default = nil)
  if valid_402657721 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657721
  var valid_402657722 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657722 = validateParameter(valid_402657722, JString,
                                      required = false, default = nil)
  if valid_402657722 != nil:
    section.add "X-Amz-Algorithm", valid_402657722
  var valid_402657723 = header.getOrDefault("X-Amz-Date")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "X-Amz-Date", valid_402657723
  var valid_402657724 = header.getOrDefault("X-Amz-Credential")
  valid_402657724 = validateParameter(valid_402657724, JString,
                                      required = false, default = nil)
  if valid_402657724 != nil:
    section.add "X-Amz-Credential", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657725
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657726: Call_GetDescribeOptionGroups_402657709;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657726.validator(path, query, header, formData, body, _)
  let scheme = call_402657726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657726.makeUrl(scheme.get, call_402657726.host, call_402657726.base,
                                   call_402657726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657726, uri, valid, _)

proc call*(call_402657727: Call_GetDescribeOptionGroups_402657709;
           OptionGroupName: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-02-12";
           Action: string = "DescribeOptionGroups"; EngineName: string = "";
           MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   OptionGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_402657728 = newJObject()
  add(query_402657728, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657728, "MaxRecords", newJInt(MaxRecords))
  add(query_402657728, "Marker", newJString(Marker))
  add(query_402657728, "Version", newJString(Version))
  add(query_402657728, "Action", newJString(Action))
  add(query_402657728, "EngineName", newJString(EngineName))
  add(query_402657728, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657727.call(nil, query_402657728, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_402657709(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_402657710, base: "/",
    makeUrl: url_GetDescribeOptionGroups_402657711,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_402657772 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOrderableDBInstanceOptions_402657774(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_402657773(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657775 = query.getOrDefault("Version")
  valid_402657775 = validateParameter(valid_402657775, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657775 != nil:
    section.add "Version", valid_402657775
  var valid_402657776 = query.getOrDefault("Action")
  valid_402657776 = validateParameter(valid_402657776, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657776 != nil:
    section.add "Action", valid_402657776
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
  var valid_402657777 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657777 = validateParameter(valid_402657777, JString,
                                      required = false, default = nil)
  if valid_402657777 != nil:
    section.add "X-Amz-Security-Token", valid_402657777
  var valid_402657778 = header.getOrDefault("X-Amz-Signature")
  valid_402657778 = validateParameter(valid_402657778, JString,
                                      required = false, default = nil)
  if valid_402657778 != nil:
    section.add "X-Amz-Signature", valid_402657778
  var valid_402657779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657779 = validateParameter(valid_402657779, JString,
                                      required = false, default = nil)
  if valid_402657779 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657779
  var valid_402657780 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657780 = validateParameter(valid_402657780, JString,
                                      required = false, default = nil)
  if valid_402657780 != nil:
    section.add "X-Amz-Algorithm", valid_402657780
  var valid_402657781 = header.getOrDefault("X-Amz-Date")
  valid_402657781 = validateParameter(valid_402657781, JString,
                                      required = false, default = nil)
  if valid_402657781 != nil:
    section.add "X-Amz-Date", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Credential")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Credential", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657783
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   Vpc: JBool
  ##   Engine: JString (required)
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  var valid_402657784 = formData.getOrDefault("Marker")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "Marker", valid_402657784
  var valid_402657785 = formData.getOrDefault("Vpc")
  valid_402657785 = validateParameter(valid_402657785, JBool, required = false,
                                      default = nil)
  if valid_402657785 != nil:
    section.add "Vpc", valid_402657785
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402657786 = formData.getOrDefault("Engine")
  valid_402657786 = validateParameter(valid_402657786, JString, required = true,
                                      default = nil)
  if valid_402657786 != nil:
    section.add "Engine", valid_402657786
  var valid_402657787 = formData.getOrDefault("DBInstanceClass")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "DBInstanceClass", valid_402657787
  var valid_402657788 = formData.getOrDefault("LicenseModel")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "LicenseModel", valid_402657788
  var valid_402657789 = formData.getOrDefault("MaxRecords")
  valid_402657789 = validateParameter(valid_402657789, JInt, required = false,
                                      default = nil)
  if valid_402657789 != nil:
    section.add "MaxRecords", valid_402657789
  var valid_402657790 = formData.getOrDefault("EngineVersion")
  valid_402657790 = validateParameter(valid_402657790, JString,
                                      required = false, default = nil)
  if valid_402657790 != nil:
    section.add "EngineVersion", valid_402657790
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657791: Call_PostDescribeOrderableDBInstanceOptions_402657772;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657791.validator(path, query, header, formData, body, _)
  let scheme = call_402657791.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657791.makeUrl(scheme.get, call_402657791.host, call_402657791.base,
                                   call_402657791.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657791, uri, valid, _)

proc call*(call_402657792: Call_PostDescribeOrderableDBInstanceOptions_402657772;
           Engine: string; Marker: string = ""; Vpc: bool = false;
           Version: string = "2013-02-12"; DBInstanceClass: string = "";
           LicenseModel: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeOrderableDBInstanceOptions";
           EngineVersion: string = ""): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Vpc: bool
  ##   Engine: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   EngineVersion: string
  var query_402657793 = newJObject()
  var formData_402657794 = newJObject()
  add(formData_402657794, "Marker", newJString(Marker))
  add(formData_402657794, "Vpc", newJBool(Vpc))
  add(formData_402657794, "Engine", newJString(Engine))
  add(query_402657793, "Version", newJString(Version))
  add(formData_402657794, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657794, "LicenseModel", newJString(LicenseModel))
  add(formData_402657794, "MaxRecords", newJInt(MaxRecords))
  add(query_402657793, "Action", newJString(Action))
  add(formData_402657794, "EngineVersion", newJString(EngineVersion))
  result = call_402657792.call(nil, query_402657793, nil, formData_402657794,
                               nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_402657772(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_402657773,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_402657774,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_402657750 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOrderableDBInstanceOptions_402657752(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_402657751(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineVersion: JString
  ##   Vpc: JBool
  ##   Engine: JString (required)
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402657753 = query.getOrDefault("MaxRecords")
  valid_402657753 = validateParameter(valid_402657753, JInt, required = false,
                                      default = nil)
  if valid_402657753 != nil:
    section.add "MaxRecords", valid_402657753
  var valid_402657754 = query.getOrDefault("Marker")
  valid_402657754 = validateParameter(valid_402657754, JString,
                                      required = false, default = nil)
  if valid_402657754 != nil:
    section.add "Marker", valid_402657754
  var valid_402657755 = query.getOrDefault("Version")
  valid_402657755 = validateParameter(valid_402657755, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657755 != nil:
    section.add "Version", valid_402657755
  var valid_402657756 = query.getOrDefault("EngineVersion")
  valid_402657756 = validateParameter(valid_402657756, JString,
                                      required = false, default = nil)
  if valid_402657756 != nil:
    section.add "EngineVersion", valid_402657756
  var valid_402657757 = query.getOrDefault("Vpc")
  valid_402657757 = validateParameter(valid_402657757, JBool, required = false,
                                      default = nil)
  if valid_402657757 != nil:
    section.add "Vpc", valid_402657757
  var valid_402657758 = query.getOrDefault("Engine")
  valid_402657758 = validateParameter(valid_402657758, JString, required = true,
                                      default = nil)
  if valid_402657758 != nil:
    section.add "Engine", valid_402657758
  var valid_402657759 = query.getOrDefault("DBInstanceClass")
  valid_402657759 = validateParameter(valid_402657759, JString,
                                      required = false, default = nil)
  if valid_402657759 != nil:
    section.add "DBInstanceClass", valid_402657759
  var valid_402657760 = query.getOrDefault("Action")
  valid_402657760 = validateParameter(valid_402657760, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657760 != nil:
    section.add "Action", valid_402657760
  var valid_402657761 = query.getOrDefault("LicenseModel")
  valid_402657761 = validateParameter(valid_402657761, JString,
                                      required = false, default = nil)
  if valid_402657761 != nil:
    section.add "LicenseModel", valid_402657761
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
  var valid_402657762 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "X-Amz-Security-Token", valid_402657762
  var valid_402657763 = header.getOrDefault("X-Amz-Signature")
  valid_402657763 = validateParameter(valid_402657763, JString,
                                      required = false, default = nil)
  if valid_402657763 != nil:
    section.add "X-Amz-Signature", valid_402657763
  var valid_402657764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657764 = validateParameter(valid_402657764, JString,
                                      required = false, default = nil)
  if valid_402657764 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657764
  var valid_402657765 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "X-Amz-Algorithm", valid_402657765
  var valid_402657766 = header.getOrDefault("X-Amz-Date")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Date", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Credential")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Credential", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657769: Call_GetDescribeOrderableDBInstanceOptions_402657750;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657769.validator(path, query, header, formData, body, _)
  let scheme = call_402657769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657769.makeUrl(scheme.get, call_402657769.host, call_402657769.base,
                                   call_402657769.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657769, uri, valid, _)

proc call*(call_402657770: Call_GetDescribeOrderableDBInstanceOptions_402657750;
           Engine: string; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-02-12"; EngineVersion: string = "";
           Vpc: bool = false; DBInstanceClass: string = "";
           Action: string = "DescribeOrderableDBInstanceOptions";
           LicenseModel: string = ""): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineVersion: string
  ##   Vpc: bool
  ##   Engine: string (required)
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402657771 = newJObject()
  add(query_402657771, "MaxRecords", newJInt(MaxRecords))
  add(query_402657771, "Marker", newJString(Marker))
  add(query_402657771, "Version", newJString(Version))
  add(query_402657771, "EngineVersion", newJString(EngineVersion))
  add(query_402657771, "Vpc", newJBool(Vpc))
  add(query_402657771, "Engine", newJString(Engine))
  add(query_402657771, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657771, "Action", newJString(Action))
  add(query_402657771, "LicenseModel", newJString(LicenseModel))
  result = call_402657770.call(nil, query_402657771, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_402657750(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_402657751,
    base: "/", makeUrl: url_GetDescribeOrderableDBInstanceOptions_402657752,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_402657819 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstances_402657821(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_402657820(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657822 = query.getOrDefault("Version")
  valid_402657822 = validateParameter(valid_402657822, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657822 != nil:
    section.add "Version", valid_402657822
  var valid_402657823 = query.getOrDefault("Action")
  valid_402657823 = validateParameter(valid_402657823, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657823 != nil:
    section.add "Action", valid_402657823
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
  var valid_402657824 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657824 = validateParameter(valid_402657824, JString,
                                      required = false, default = nil)
  if valid_402657824 != nil:
    section.add "X-Amz-Security-Token", valid_402657824
  var valid_402657825 = header.getOrDefault("X-Amz-Signature")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Signature", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-Algorithm", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Date")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Date", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Credential")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Credential", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657830
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   DBInstanceClass: JString
  ##   Duration: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  ##   ReservedDBInstanceId: JString
  ##   MultiAZ: JBool
  section = newJObject()
  var valid_402657831 = formData.getOrDefault("Marker")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "Marker", valid_402657831
  var valid_402657832 = formData.getOrDefault("OfferingType")
  valid_402657832 = validateParameter(valid_402657832, JString,
                                      required = false, default = nil)
  if valid_402657832 != nil:
    section.add "OfferingType", valid_402657832
  var valid_402657833 = formData.getOrDefault("ProductDescription")
  valid_402657833 = validateParameter(valid_402657833, JString,
                                      required = false, default = nil)
  if valid_402657833 != nil:
    section.add "ProductDescription", valid_402657833
  var valid_402657834 = formData.getOrDefault("DBInstanceClass")
  valid_402657834 = validateParameter(valid_402657834, JString,
                                      required = false, default = nil)
  if valid_402657834 != nil:
    section.add "DBInstanceClass", valid_402657834
  var valid_402657835 = formData.getOrDefault("Duration")
  valid_402657835 = validateParameter(valid_402657835, JString,
                                      required = false, default = nil)
  if valid_402657835 != nil:
    section.add "Duration", valid_402657835
  var valid_402657836 = formData.getOrDefault("MaxRecords")
  valid_402657836 = validateParameter(valid_402657836, JInt, required = false,
                                      default = nil)
  if valid_402657836 != nil:
    section.add "MaxRecords", valid_402657836
  var valid_402657837 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657837 = validateParameter(valid_402657837, JString,
                                      required = false, default = nil)
  if valid_402657837 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657837
  var valid_402657838 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402657838 = validateParameter(valid_402657838, JString,
                                      required = false, default = nil)
  if valid_402657838 != nil:
    section.add "ReservedDBInstanceId", valid_402657838
  var valid_402657839 = formData.getOrDefault("MultiAZ")
  valid_402657839 = validateParameter(valid_402657839, JBool, required = false,
                                      default = nil)
  if valid_402657839 != nil:
    section.add "MultiAZ", valid_402657839
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657840: Call_PostDescribeReservedDBInstances_402657819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657840.validator(path, query, header, formData, body, _)
  let scheme = call_402657840.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657840.makeUrl(scheme.get, call_402657840.host, call_402657840.base,
                                   call_402657840.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657840, uri, valid, _)

proc call*(call_402657841: Call_PostDescribeReservedDBInstances_402657819;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2013-02-12";
           DBInstanceClass: string = ""; Duration: string = "";
           MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
           ReservedDBInstanceId: string = ""; MultiAZ: bool = false;
           Action: string = "DescribeReservedDBInstances"): Recallable =
  ## postDescribeReservedDBInstances
  ##   Marker: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Duration: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   ReservedDBInstanceId: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  var query_402657842 = newJObject()
  var formData_402657843 = newJObject()
  add(formData_402657843, "Marker", newJString(Marker))
  add(formData_402657843, "OfferingType", newJString(OfferingType))
  add(formData_402657843, "ProductDescription", newJString(ProductDescription))
  add(query_402657842, "Version", newJString(Version))
  add(formData_402657843, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657843, "Duration", newJString(Duration))
  add(formData_402657843, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657843, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402657843, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(formData_402657843, "MultiAZ", newJBool(MultiAZ))
  add(query_402657842, "Action", newJString(Action))
  result = call_402657841.call(nil, query_402657842, nil, formData_402657843,
                               nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_402657819(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_402657820, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_402657821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_402657795 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstances_402657797(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_402657796(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   OfferingType: JString
  ##   Action: JString (required)
  ##   ProductDescription: JString
  section = newJObject()
  var valid_402657798 = query.getOrDefault("ReservedDBInstanceId")
  valid_402657798 = validateParameter(valid_402657798, JString,
                                      required = false, default = nil)
  if valid_402657798 != nil:
    section.add "ReservedDBInstanceId", valid_402657798
  var valid_402657799 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657799 = validateParameter(valid_402657799, JString,
                                      required = false, default = nil)
  if valid_402657799 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657799
  var valid_402657800 = query.getOrDefault("MaxRecords")
  valid_402657800 = validateParameter(valid_402657800, JInt, required = false,
                                      default = nil)
  if valid_402657800 != nil:
    section.add "MaxRecords", valid_402657800
  var valid_402657801 = query.getOrDefault("Marker")
  valid_402657801 = validateParameter(valid_402657801, JString,
                                      required = false, default = nil)
  if valid_402657801 != nil:
    section.add "Marker", valid_402657801
  var valid_402657802 = query.getOrDefault("MultiAZ")
  valid_402657802 = validateParameter(valid_402657802, JBool, required = false,
                                      default = nil)
  if valid_402657802 != nil:
    section.add "MultiAZ", valid_402657802
  var valid_402657803 = query.getOrDefault("Version")
  valid_402657803 = validateParameter(valid_402657803, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657803 != nil:
    section.add "Version", valid_402657803
  var valid_402657804 = query.getOrDefault("Duration")
  valid_402657804 = validateParameter(valid_402657804, JString,
                                      required = false, default = nil)
  if valid_402657804 != nil:
    section.add "Duration", valid_402657804
  var valid_402657805 = query.getOrDefault("DBInstanceClass")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "DBInstanceClass", valid_402657805
  var valid_402657806 = query.getOrDefault("OfferingType")
  valid_402657806 = validateParameter(valid_402657806, JString,
                                      required = false, default = nil)
  if valid_402657806 != nil:
    section.add "OfferingType", valid_402657806
  var valid_402657807 = query.getOrDefault("Action")
  valid_402657807 = validateParameter(valid_402657807, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657807 != nil:
    section.add "Action", valid_402657807
  var valid_402657808 = query.getOrDefault("ProductDescription")
  valid_402657808 = validateParameter(valid_402657808, JString,
                                      required = false, default = nil)
  if valid_402657808 != nil:
    section.add "ProductDescription", valid_402657808
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
  var valid_402657809 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657809 = validateParameter(valid_402657809, JString,
                                      required = false, default = nil)
  if valid_402657809 != nil:
    section.add "X-Amz-Security-Token", valid_402657809
  var valid_402657810 = header.getOrDefault("X-Amz-Signature")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-Signature", valid_402657810
  var valid_402657811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657811 = validateParameter(valid_402657811, JString,
                                      required = false, default = nil)
  if valid_402657811 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657811
  var valid_402657812 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657812 = validateParameter(valid_402657812, JString,
                                      required = false, default = nil)
  if valid_402657812 != nil:
    section.add "X-Amz-Algorithm", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Date")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Date", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Credential")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Credential", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657816: Call_GetDescribeReservedDBInstances_402657795;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657816.validator(path, query, header, formData, body, _)
  let scheme = call_402657816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657816.makeUrl(scheme.get, call_402657816.host, call_402657816.base,
                                   call_402657816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657816, uri, valid, _)

proc call*(call_402657817: Call_GetDescribeReservedDBInstances_402657795;
           ReservedDBInstanceId: string = "";
           ReservedDBInstancesOfferingId: string = ""; MaxRecords: int = 0;
           Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2013-02-12"; Duration: string = "";
           DBInstanceClass: string = ""; OfferingType: string = "";
           Action: string = "DescribeReservedDBInstances";
           ProductDescription: string = ""): Recallable =
  ## getDescribeReservedDBInstances
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   OfferingType: string
  ##   Action: string (required)
  ##   ProductDescription: string
  var query_402657818 = newJObject()
  add(query_402657818, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_402657818, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402657818, "MaxRecords", newJInt(MaxRecords))
  add(query_402657818, "Marker", newJString(Marker))
  add(query_402657818, "MultiAZ", newJBool(MultiAZ))
  add(query_402657818, "Version", newJString(Version))
  add(query_402657818, "Duration", newJString(Duration))
  add(query_402657818, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657818, "OfferingType", newJString(OfferingType))
  add(query_402657818, "Action", newJString(Action))
  add(query_402657818, "ProductDescription", newJString(ProductDescription))
  result = call_402657817.call(nil, query_402657818, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_402657795(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_402657796, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_402657797,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_402657867 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstancesOfferings_402657869(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_402657868(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657870 = query.getOrDefault("Version")
  valid_402657870 = validateParameter(valid_402657870, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657870 != nil:
    section.add "Version", valid_402657870
  var valid_402657871 = query.getOrDefault("Action")
  valid_402657871 = validateParameter(valid_402657871, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402657871 != nil:
    section.add "Action", valid_402657871
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
  var valid_402657872 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "X-Amz-Security-Token", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-Signature")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-Signature", valid_402657873
  var valid_402657874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Algorithm", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-Date")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-Date", valid_402657876
  var valid_402657877 = header.getOrDefault("X-Amz-Credential")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "X-Amz-Credential", valid_402657877
  var valid_402657878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657878 = validateParameter(valid_402657878, JString,
                                      required = false, default = nil)
  if valid_402657878 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657878
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   OfferingType: JString
  ##   ProductDescription: JString
  ##   DBInstanceClass: JString
  ##   Duration: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  ##   MultiAZ: JBool
  section = newJObject()
  var valid_402657879 = formData.getOrDefault("Marker")
  valid_402657879 = validateParameter(valid_402657879, JString,
                                      required = false, default = nil)
  if valid_402657879 != nil:
    section.add "Marker", valid_402657879
  var valid_402657880 = formData.getOrDefault("OfferingType")
  valid_402657880 = validateParameter(valid_402657880, JString,
                                      required = false, default = nil)
  if valid_402657880 != nil:
    section.add "OfferingType", valid_402657880
  var valid_402657881 = formData.getOrDefault("ProductDescription")
  valid_402657881 = validateParameter(valid_402657881, JString,
                                      required = false, default = nil)
  if valid_402657881 != nil:
    section.add "ProductDescription", valid_402657881
  var valid_402657882 = formData.getOrDefault("DBInstanceClass")
  valid_402657882 = validateParameter(valid_402657882, JString,
                                      required = false, default = nil)
  if valid_402657882 != nil:
    section.add "DBInstanceClass", valid_402657882
  var valid_402657883 = formData.getOrDefault("Duration")
  valid_402657883 = validateParameter(valid_402657883, JString,
                                      required = false, default = nil)
  if valid_402657883 != nil:
    section.add "Duration", valid_402657883
  var valid_402657884 = formData.getOrDefault("MaxRecords")
  valid_402657884 = validateParameter(valid_402657884, JInt, required = false,
                                      default = nil)
  if valid_402657884 != nil:
    section.add "MaxRecords", valid_402657884
  var valid_402657885 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657885 = validateParameter(valid_402657885, JString,
                                      required = false, default = nil)
  if valid_402657885 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657885
  var valid_402657886 = formData.getOrDefault("MultiAZ")
  valid_402657886 = validateParameter(valid_402657886, JBool, required = false,
                                      default = nil)
  if valid_402657886 != nil:
    section.add "MultiAZ", valid_402657886
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657887: Call_PostDescribeReservedDBInstancesOfferings_402657867;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657887.validator(path, query, header, formData, body, _)
  let scheme = call_402657887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657887.makeUrl(scheme.get, call_402657887.host, call_402657887.base,
                                   call_402657887.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657887, uri, valid, _)

proc call*(call_402657888: Call_PostDescribeReservedDBInstancesOfferings_402657867;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2013-02-12";
           DBInstanceClass: string = ""; Duration: string = "";
           MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
           MultiAZ: bool = false;
           Action: string = "DescribeReservedDBInstancesOfferings"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   Marker: string
  ##   OfferingType: string
  ##   ProductDescription: string
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   Duration: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  var query_402657889 = newJObject()
  var formData_402657890 = newJObject()
  add(formData_402657890, "Marker", newJString(Marker))
  add(formData_402657890, "OfferingType", newJString(OfferingType))
  add(formData_402657890, "ProductDescription", newJString(ProductDescription))
  add(query_402657889, "Version", newJString(Version))
  add(formData_402657890, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657890, "Duration", newJString(Duration))
  add(formData_402657890, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657890, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402657890, "MultiAZ", newJBool(MultiAZ))
  add(query_402657889, "Action", newJString(Action))
  result = call_402657888.call(nil, query_402657889, nil, formData_402657890,
                               nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_402657867(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_402657868,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_402657869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_402657844 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstancesOfferings_402657846(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_402657845(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ReservedDBInstancesOfferingId: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   OfferingType: JString
  ##   Action: JString (required)
  ##   ProductDescription: JString
  section = newJObject()
  var valid_402657847 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657847 = validateParameter(valid_402657847, JString,
                                      required = false, default = nil)
  if valid_402657847 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657847
  var valid_402657848 = query.getOrDefault("MaxRecords")
  valid_402657848 = validateParameter(valid_402657848, JInt, required = false,
                                      default = nil)
  if valid_402657848 != nil:
    section.add "MaxRecords", valid_402657848
  var valid_402657849 = query.getOrDefault("Marker")
  valid_402657849 = validateParameter(valid_402657849, JString,
                                      required = false, default = nil)
  if valid_402657849 != nil:
    section.add "Marker", valid_402657849
  var valid_402657850 = query.getOrDefault("MultiAZ")
  valid_402657850 = validateParameter(valid_402657850, JBool, required = false,
                                      default = nil)
  if valid_402657850 != nil:
    section.add "MultiAZ", valid_402657850
  var valid_402657851 = query.getOrDefault("Version")
  valid_402657851 = validateParameter(valid_402657851, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657851 != nil:
    section.add "Version", valid_402657851
  var valid_402657852 = query.getOrDefault("Duration")
  valid_402657852 = validateParameter(valid_402657852, JString,
                                      required = false, default = nil)
  if valid_402657852 != nil:
    section.add "Duration", valid_402657852
  var valid_402657853 = query.getOrDefault("DBInstanceClass")
  valid_402657853 = validateParameter(valid_402657853, JString,
                                      required = false, default = nil)
  if valid_402657853 != nil:
    section.add "DBInstanceClass", valid_402657853
  var valid_402657854 = query.getOrDefault("OfferingType")
  valid_402657854 = validateParameter(valid_402657854, JString,
                                      required = false, default = nil)
  if valid_402657854 != nil:
    section.add "OfferingType", valid_402657854
  var valid_402657855 = query.getOrDefault("Action")
  valid_402657855 = validateParameter(valid_402657855, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402657855 != nil:
    section.add "Action", valid_402657855
  var valid_402657856 = query.getOrDefault("ProductDescription")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "ProductDescription", valid_402657856
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
  var valid_402657857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Security-Token", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Signature")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Signature", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Algorithm", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-Date")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-Date", valid_402657861
  var valid_402657862 = header.getOrDefault("X-Amz-Credential")
  valid_402657862 = validateParameter(valid_402657862, JString,
                                      required = false, default = nil)
  if valid_402657862 != nil:
    section.add "X-Amz-Credential", valid_402657862
  var valid_402657863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657863 = validateParameter(valid_402657863, JString,
                                      required = false, default = nil)
  if valid_402657863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657863
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657864: Call_GetDescribeReservedDBInstancesOfferings_402657844;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657864.validator(path, query, header, formData, body, _)
  let scheme = call_402657864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657864.makeUrl(scheme.get, call_402657864.host, call_402657864.base,
                                   call_402657864.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657864, uri, valid, _)

proc call*(call_402657865: Call_GetDescribeReservedDBInstancesOfferings_402657844;
           ReservedDBInstancesOfferingId: string = ""; MaxRecords: int = 0;
           Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2013-02-12"; Duration: string = "";
           DBInstanceClass: string = ""; OfferingType: string = "";
           Action: string = "DescribeReservedDBInstancesOfferings";
           ProductDescription: string = ""): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   ReservedDBInstancesOfferingId: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   OfferingType: string
  ##   Action: string (required)
  ##   ProductDescription: string
  var query_402657866 = newJObject()
  add(query_402657866, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402657866, "MaxRecords", newJInt(MaxRecords))
  add(query_402657866, "Marker", newJString(Marker))
  add(query_402657866, "MultiAZ", newJBool(MultiAZ))
  add(query_402657866, "Version", newJString(Version))
  add(query_402657866, "Duration", newJString(Duration))
  add(query_402657866, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657866, "OfferingType", newJString(OfferingType))
  add(query_402657866, "Action", newJString(Action))
  add(query_402657866, "ProductDescription", newJString(ProductDescription))
  result = call_402657865.call(nil, query_402657866, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_402657844(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_402657845,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_402657846,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_402657910 = ref object of OpenApiRestCall_402656035
proc url_PostDownloadDBLogFilePortion_402657912(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_402657911(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657913 = query.getOrDefault("Version")
  valid_402657913 = validateParameter(valid_402657913, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657913 != nil:
    section.add "Version", valid_402657913
  var valid_402657914 = query.getOrDefault("Action")
  valid_402657914 = validateParameter(valid_402657914, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402657914 != nil:
    section.add "Action", valid_402657914
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
  var valid_402657915 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-Security-Token", valid_402657915
  var valid_402657916 = header.getOrDefault("X-Amz-Signature")
  valid_402657916 = validateParameter(valid_402657916, JString,
                                      required = false, default = nil)
  if valid_402657916 != nil:
    section.add "X-Amz-Signature", valid_402657916
  var valid_402657917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657917 = validateParameter(valid_402657917, JString,
                                      required = false, default = nil)
  if valid_402657917 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657917
  var valid_402657918 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657918 = validateParameter(valid_402657918, JString,
                                      required = false, default = nil)
  if valid_402657918 != nil:
    section.add "X-Amz-Algorithm", valid_402657918
  var valid_402657919 = header.getOrDefault("X-Amz-Date")
  valid_402657919 = validateParameter(valid_402657919, JString,
                                      required = false, default = nil)
  if valid_402657919 != nil:
    section.add "X-Amz-Date", valid_402657919
  var valid_402657920 = header.getOrDefault("X-Amz-Credential")
  valid_402657920 = validateParameter(valid_402657920, JString,
                                      required = false, default = nil)
  if valid_402657920 != nil:
    section.add "X-Amz-Credential", valid_402657920
  var valid_402657921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657921 = validateParameter(valid_402657921, JString,
                                      required = false, default = nil)
  if valid_402657921 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657921
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   NumberOfLines: JInt
  section = newJObject()
  var valid_402657922 = formData.getOrDefault("Marker")
  valid_402657922 = validateParameter(valid_402657922, JString,
                                      required = false, default = nil)
  if valid_402657922 != nil:
    section.add "Marker", valid_402657922
  assert formData != nil,
         "formData argument is necessary due to required `LogFileName` field"
  var valid_402657923 = formData.getOrDefault("LogFileName")
  valid_402657923 = validateParameter(valid_402657923, JString, required = true,
                                      default = nil)
  if valid_402657923 != nil:
    section.add "LogFileName", valid_402657923
  var valid_402657924 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657924 = validateParameter(valid_402657924, JString, required = true,
                                      default = nil)
  if valid_402657924 != nil:
    section.add "DBInstanceIdentifier", valid_402657924
  var valid_402657925 = formData.getOrDefault("NumberOfLines")
  valid_402657925 = validateParameter(valid_402657925, JInt, required = false,
                                      default = nil)
  if valid_402657925 != nil:
    section.add "NumberOfLines", valid_402657925
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657926: Call_PostDownloadDBLogFilePortion_402657910;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657926.validator(path, query, header, formData, body, _)
  let scheme = call_402657926.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657926.makeUrl(scheme.get, call_402657926.host, call_402657926.base,
                                   call_402657926.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657926, uri, valid, _)

proc call*(call_402657927: Call_PostDownloadDBLogFilePortion_402657910;
           LogFileName: string; DBInstanceIdentifier: string;
           Marker: string = ""; Version: string = "2013-02-12";
           NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Action: string (required)
  var query_402657928 = newJObject()
  var formData_402657929 = newJObject()
  add(formData_402657929, "Marker", newJString(Marker))
  add(query_402657928, "Version", newJString(Version))
  add(formData_402657929, "LogFileName", newJString(LogFileName))
  add(formData_402657929, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657929, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402657928, "Action", newJString(Action))
  result = call_402657927.call(nil, query_402657928, nil, formData_402657929,
                               nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_402657910(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_402657911, base: "/",
    makeUrl: url_PostDownloadDBLogFilePortion_402657912,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_402657891 = ref object of OpenApiRestCall_402656035
proc url_GetDownloadDBLogFilePortion_402657893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_402657892(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   NumberOfLines: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   LogFileName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657894 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657894 = validateParameter(valid_402657894, JString, required = true,
                                      default = nil)
  if valid_402657894 != nil:
    section.add "DBInstanceIdentifier", valid_402657894
  var valid_402657895 = query.getOrDefault("NumberOfLines")
  valid_402657895 = validateParameter(valid_402657895, JInt, required = false,
                                      default = nil)
  if valid_402657895 != nil:
    section.add "NumberOfLines", valid_402657895
  var valid_402657896 = query.getOrDefault("Marker")
  valid_402657896 = validateParameter(valid_402657896, JString,
                                      required = false, default = nil)
  if valid_402657896 != nil:
    section.add "Marker", valid_402657896
  var valid_402657897 = query.getOrDefault("Version")
  valid_402657897 = validateParameter(valid_402657897, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657897 != nil:
    section.add "Version", valid_402657897
  var valid_402657898 = query.getOrDefault("LogFileName")
  valid_402657898 = validateParameter(valid_402657898, JString, required = true,
                                      default = nil)
  if valid_402657898 != nil:
    section.add "LogFileName", valid_402657898
  var valid_402657899 = query.getOrDefault("Action")
  valid_402657899 = validateParameter(valid_402657899, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402657899 != nil:
    section.add "Action", valid_402657899
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
  var valid_402657900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657900 = validateParameter(valid_402657900, JString,
                                      required = false, default = nil)
  if valid_402657900 != nil:
    section.add "X-Amz-Security-Token", valid_402657900
  var valid_402657901 = header.getOrDefault("X-Amz-Signature")
  valid_402657901 = validateParameter(valid_402657901, JString,
                                      required = false, default = nil)
  if valid_402657901 != nil:
    section.add "X-Amz-Signature", valid_402657901
  var valid_402657902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657902 = validateParameter(valid_402657902, JString,
                                      required = false, default = nil)
  if valid_402657902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657902
  var valid_402657903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657903 = validateParameter(valid_402657903, JString,
                                      required = false, default = nil)
  if valid_402657903 != nil:
    section.add "X-Amz-Algorithm", valid_402657903
  var valid_402657904 = header.getOrDefault("X-Amz-Date")
  valid_402657904 = validateParameter(valid_402657904, JString,
                                      required = false, default = nil)
  if valid_402657904 != nil:
    section.add "X-Amz-Date", valid_402657904
  var valid_402657905 = header.getOrDefault("X-Amz-Credential")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "X-Amz-Credential", valid_402657905
  var valid_402657906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657907: Call_GetDownloadDBLogFilePortion_402657891;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657907.validator(path, query, header, formData, body, _)
  let scheme = call_402657907.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657907.makeUrl(scheme.get, call_402657907.host, call_402657907.base,
                                   call_402657907.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657907, uri, valid, _)

proc call*(call_402657908: Call_GetDownloadDBLogFilePortion_402657891;
           DBInstanceIdentifier: string; LogFileName: string;
           NumberOfLines: int = 0; Marker: string = "";
           Version: string = "2013-02-12";
           Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   Action: string (required)
  var query_402657909 = newJObject()
  add(query_402657909, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657909, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402657909, "Marker", newJString(Marker))
  add(query_402657909, "Version", newJString(Version))
  add(query_402657909, "LogFileName", newJString(LogFileName))
  add(query_402657909, "Action", newJString(Action))
  result = call_402657908.call(nil, query_402657909, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_402657891(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_402657892, base: "/",
    makeUrl: url_GetDownloadDBLogFilePortion_402657893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_402657946 = ref object of OpenApiRestCall_402656035
proc url_PostListTagsForResource_402657948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_402657947(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657949 = query.getOrDefault("Version")
  valid_402657949 = validateParameter(valid_402657949, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657949 != nil:
    section.add "Version", valid_402657949
  var valid_402657950 = query.getOrDefault("Action")
  valid_402657950 = validateParameter(valid_402657950, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402657950 != nil:
    section.add "Action", valid_402657950
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
  var valid_402657951 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657951 = validateParameter(valid_402657951, JString,
                                      required = false, default = nil)
  if valid_402657951 != nil:
    section.add "X-Amz-Security-Token", valid_402657951
  var valid_402657952 = header.getOrDefault("X-Amz-Signature")
  valid_402657952 = validateParameter(valid_402657952, JString,
                                      required = false, default = nil)
  if valid_402657952 != nil:
    section.add "X-Amz-Signature", valid_402657952
  var valid_402657953 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657953 = validateParameter(valid_402657953, JString,
                                      required = false, default = nil)
  if valid_402657953 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657953
  var valid_402657954 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657954 = validateParameter(valid_402657954, JString,
                                      required = false, default = nil)
  if valid_402657954 != nil:
    section.add "X-Amz-Algorithm", valid_402657954
  var valid_402657955 = header.getOrDefault("X-Amz-Date")
  valid_402657955 = validateParameter(valid_402657955, JString,
                                      required = false, default = nil)
  if valid_402657955 != nil:
    section.add "X-Amz-Date", valid_402657955
  var valid_402657956 = header.getOrDefault("X-Amz-Credential")
  valid_402657956 = validateParameter(valid_402657956, JString,
                                      required = false, default = nil)
  if valid_402657956 != nil:
    section.add "X-Amz-Credential", valid_402657956
  var valid_402657957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657957 = validateParameter(valid_402657957, JString,
                                      required = false, default = nil)
  if valid_402657957 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657957
  result.add "header", section
  ## parameters in `formData` object:
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
         "formData argument is necessary due to required `ResourceName` field"
  var valid_402657958 = formData.getOrDefault("ResourceName")
  valid_402657958 = validateParameter(valid_402657958, JString, required = true,
                                      default = nil)
  if valid_402657958 != nil:
    section.add "ResourceName", valid_402657958
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657959: Call_PostListTagsForResource_402657946;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657959.validator(path, query, header, formData, body, _)
  let scheme = call_402657959.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657959.makeUrl(scheme.get, call_402657959.host, call_402657959.base,
                                   call_402657959.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657959, uri, valid, _)

proc call*(call_402657960: Call_PostListTagsForResource_402657946;
           ResourceName: string; Version: string = "2013-02-12";
           Action: string = "ListTagsForResource"): Recallable =
  ## postListTagsForResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  var query_402657961 = newJObject()
  var formData_402657962 = newJObject()
  add(query_402657961, "Version", newJString(Version))
  add(query_402657961, "Action", newJString(Action))
  add(formData_402657962, "ResourceName", newJString(ResourceName))
  result = call_402657960.call(nil, query_402657961, nil, formData_402657962,
                               nil)

var postListTagsForResource* = Call_PostListTagsForResource_402657946(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_402657947, base: "/",
    makeUrl: url_PostListTagsForResource_402657948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_402657930 = ref object of OpenApiRestCall_402656035
proc url_GetListTagsForResource_402657932(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_402657931(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657933 = query.getOrDefault("Version")
  valid_402657933 = validateParameter(valid_402657933, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657933 != nil:
    section.add "Version", valid_402657933
  var valid_402657934 = query.getOrDefault("ResourceName")
  valid_402657934 = validateParameter(valid_402657934, JString, required = true,
                                      default = nil)
  if valid_402657934 != nil:
    section.add "ResourceName", valid_402657934
  var valid_402657935 = query.getOrDefault("Action")
  valid_402657935 = validateParameter(valid_402657935, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402657935 != nil:
    section.add "Action", valid_402657935
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
  var valid_402657936 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "X-Amz-Security-Token", valid_402657936
  var valid_402657937 = header.getOrDefault("X-Amz-Signature")
  valid_402657937 = validateParameter(valid_402657937, JString,
                                      required = false, default = nil)
  if valid_402657937 != nil:
    section.add "X-Amz-Signature", valid_402657937
  var valid_402657938 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657938 = validateParameter(valid_402657938, JString,
                                      required = false, default = nil)
  if valid_402657938 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657938
  var valid_402657939 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657939 = validateParameter(valid_402657939, JString,
                                      required = false, default = nil)
  if valid_402657939 != nil:
    section.add "X-Amz-Algorithm", valid_402657939
  var valid_402657940 = header.getOrDefault("X-Amz-Date")
  valid_402657940 = validateParameter(valid_402657940, JString,
                                      required = false, default = nil)
  if valid_402657940 != nil:
    section.add "X-Amz-Date", valid_402657940
  var valid_402657941 = header.getOrDefault("X-Amz-Credential")
  valid_402657941 = validateParameter(valid_402657941, JString,
                                      required = false, default = nil)
  if valid_402657941 != nil:
    section.add "X-Amz-Credential", valid_402657941
  var valid_402657942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657942 = validateParameter(valid_402657942, JString,
                                      required = false, default = nil)
  if valid_402657942 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657942
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657943: Call_GetListTagsForResource_402657930;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657943.validator(path, query, header, formData, body, _)
  let scheme = call_402657943.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657943.makeUrl(scheme.get, call_402657943.host, call_402657943.base,
                                   call_402657943.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657943, uri, valid, _)

proc call*(call_402657944: Call_GetListTagsForResource_402657930;
           ResourceName: string; Version: string = "2013-02-12";
           Action: string = "ListTagsForResource"): Recallable =
  ## getListTagsForResource
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402657945 = newJObject()
  add(query_402657945, "Version", newJString(Version))
  add(query_402657945, "ResourceName", newJString(ResourceName))
  add(query_402657945, "Action", newJString(Action))
  result = call_402657944.call(nil, query_402657945, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_402657930(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_402657931, base: "/",
    makeUrl: url_GetListTagsForResource_402657932,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_402657996 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBInstance_402657998(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_402657997(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657999 = query.getOrDefault("Version")
  valid_402657999 = validateParameter(valid_402657999, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657999 != nil:
    section.add "Version", valid_402657999
  var valid_402658000 = query.getOrDefault("Action")
  valid_402658000 = validateParameter(valid_402658000, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402658000 != nil:
    section.add "Action", valid_402658000
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
  var valid_402658001 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658001 = validateParameter(valid_402658001, JString,
                                      required = false, default = nil)
  if valid_402658001 != nil:
    section.add "X-Amz-Security-Token", valid_402658001
  var valid_402658002 = header.getOrDefault("X-Amz-Signature")
  valid_402658002 = validateParameter(valid_402658002, JString,
                                      required = false, default = nil)
  if valid_402658002 != nil:
    section.add "X-Amz-Signature", valid_402658002
  var valid_402658003 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658003 = validateParameter(valid_402658003, JString,
                                      required = false, default = nil)
  if valid_402658003 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658003
  var valid_402658004 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658004 = validateParameter(valid_402658004, JString,
                                      required = false, default = nil)
  if valid_402658004 != nil:
    section.add "X-Amz-Algorithm", valid_402658004
  var valid_402658005 = header.getOrDefault("X-Amz-Date")
  valid_402658005 = validateParameter(valid_402658005, JString,
                                      required = false, default = nil)
  if valid_402658005 != nil:
    section.add "X-Amz-Date", valid_402658005
  var valid_402658006 = header.getOrDefault("X-Amz-Credential")
  valid_402658006 = validateParameter(valid_402658006, JString,
                                      required = false, default = nil)
  if valid_402658006 != nil:
    section.add "X-Amz-Credential", valid_402658006
  var valid_402658007 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658007 = validateParameter(valid_402658007, JString,
                                      required = false, default = nil)
  if valid_402658007 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658007
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   AllocatedStorage: JInt
  ##   MasterUserPassword: JString
  ##   ApplyImmediately: JBool
  ##   DBParameterGroupName: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   EngineVersion: JString
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658008 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658008 = validateParameter(valid_402658008, JString,
                                      required = false, default = nil)
  if valid_402658008 != nil:
    section.add "PreferredBackupWindow", valid_402658008
  var valid_402658009 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658009 = validateParameter(valid_402658009, JBool, required = false,
                                      default = nil)
  if valid_402658009 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658009
  var valid_402658010 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402658010 = validateParameter(valid_402658010, JArray, required = false,
                                      default = nil)
  if valid_402658010 != nil:
    section.add "VpcSecurityGroupIds", valid_402658010
  var valid_402658011 = formData.getOrDefault("AllocatedStorage")
  valid_402658011 = validateParameter(valid_402658011, JInt, required = false,
                                      default = nil)
  if valid_402658011 != nil:
    section.add "AllocatedStorage", valid_402658011
  var valid_402658012 = formData.getOrDefault("MasterUserPassword")
  valid_402658012 = validateParameter(valid_402658012, JString,
                                      required = false, default = nil)
  if valid_402658012 != nil:
    section.add "MasterUserPassword", valid_402658012
  var valid_402658013 = formData.getOrDefault("ApplyImmediately")
  valid_402658013 = validateParameter(valid_402658013, JBool, required = false,
                                      default = nil)
  if valid_402658013 != nil:
    section.add "ApplyImmediately", valid_402658013
  var valid_402658014 = formData.getOrDefault("DBParameterGroupName")
  valid_402658014 = validateParameter(valid_402658014, JString,
                                      required = false, default = nil)
  if valid_402658014 != nil:
    section.add "DBParameterGroupName", valid_402658014
  var valid_402658015 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_402658015 = validateParameter(valid_402658015, JBool, required = false,
                                      default = nil)
  if valid_402658015 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402658015
  var valid_402658016 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402658016 = validateParameter(valid_402658016, JString,
                                      required = false, default = nil)
  if valid_402658016 != nil:
    section.add "PreferredMaintenanceWindow", valid_402658016
  var valid_402658017 = formData.getOrDefault("DBInstanceClass")
  valid_402658017 = validateParameter(valid_402658017, JString,
                                      required = false, default = nil)
  if valid_402658017 != nil:
    section.add "DBInstanceClass", valid_402658017
  var valid_402658018 = formData.getOrDefault("Iops")
  valid_402658018 = validateParameter(valid_402658018, JInt, required = false,
                                      default = nil)
  if valid_402658018 != nil:
    section.add "Iops", valid_402658018
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658019 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658019 = validateParameter(valid_402658019, JString, required = true,
                                      default = nil)
  if valid_402658019 != nil:
    section.add "DBInstanceIdentifier", valid_402658019
  var valid_402658020 = formData.getOrDefault("MultiAZ")
  valid_402658020 = validateParameter(valid_402658020, JBool, required = false,
                                      default = nil)
  if valid_402658020 != nil:
    section.add "MultiAZ", valid_402658020
  var valid_402658021 = formData.getOrDefault("DBSecurityGroups")
  valid_402658021 = validateParameter(valid_402658021, JArray, required = false,
                                      default = nil)
  if valid_402658021 != nil:
    section.add "DBSecurityGroups", valid_402658021
  var valid_402658022 = formData.getOrDefault("OptionGroupName")
  valid_402658022 = validateParameter(valid_402658022, JString,
                                      required = false, default = nil)
  if valid_402658022 != nil:
    section.add "OptionGroupName", valid_402658022
  var valid_402658023 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_402658023 = validateParameter(valid_402658023, JString,
                                      required = false, default = nil)
  if valid_402658023 != nil:
    section.add "NewDBInstanceIdentifier", valid_402658023
  var valid_402658024 = formData.getOrDefault("EngineVersion")
  valid_402658024 = validateParameter(valid_402658024, JString,
                                      required = false, default = nil)
  if valid_402658024 != nil:
    section.add "EngineVersion", valid_402658024
  var valid_402658025 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658025 = validateParameter(valid_402658025, JInt, required = false,
                                      default = nil)
  if valid_402658025 != nil:
    section.add "BackupRetentionPeriod", valid_402658025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658026: Call_PostModifyDBInstance_402657996;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658026.validator(path, query, header, formData, body, _)
  let scheme = call_402658026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658026.makeUrl(scheme.get, call_402658026.host, call_402658026.base,
                                   call_402658026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658026, uri, valid, _)

proc call*(call_402658027: Call_PostModifyDBInstance_402657996;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; AllocatedStorage: int = 0;
           MasterUserPassword: string = ""; ApplyImmediately: bool = false;
           Version: string = "2013-02-12"; DBParameterGroupName: string = "";
           AllowMajorVersionUpgrade: bool = false;
           PreferredMaintenanceWindow: string = "";
           DBInstanceClass: string = ""; Iops: int = 0; MultiAZ: bool = false;
           DBSecurityGroups: JsonNode = nil; OptionGroupName: string = "";
           Action: string = "ModifyDBInstance";
           NewDBInstanceIdentifier: string = ""; EngineVersion: string = "";
           BackupRetentionPeriod: int = 0): Recallable =
  ## postModifyDBInstance
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   VpcSecurityGroupIds: JArray
  ##   AllocatedStorage: int
  ##   MasterUserPassword: string
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   DBParameterGroupName: string
  ##   AllowMajorVersionUpgrade: bool
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceClass: string
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##   EngineVersion: string
  ##   BackupRetentionPeriod: int
  var query_402658028 = newJObject()
  var formData_402658029 = newJObject()
  add(formData_402658029, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402658029, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402658029.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402658029, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402658029, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402658029, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658028, "Version", newJString(Version))
  add(formData_402658029, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402658029, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_402658029, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402658029, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658029, "Iops", newJInt(Iops))
  add(formData_402658029, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658029, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402658029.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402658029, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658028, "Action", newJString(Action))
  add(formData_402658029, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_402658029, "EngineVersion", newJString(EngineVersion))
  add(formData_402658029, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658027.call(nil, query_402658028, nil, formData_402658029,
                               nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_402657996(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_402657997, base: "/",
    makeUrl: url_PostModifyDBInstance_402657998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_402657963 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBInstance_402657965(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_402657964(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   VpcSecurityGroupIds: JArray
  ##   OptionGroupName: JString
  ##   PreferredBackupWindow: JString
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBParameterGroupName: JString
  ##   MasterUserPassword: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   Iops: JInt
  ##   ApplyImmediately: JBool
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   NewDBInstanceIdentifier: JString
  ##   EngineVersion: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBSecurityGroups: JArray
  section = newJObject()
  var valid_402657966 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402657966 = validateParameter(valid_402657966, JArray, required = false,
                                      default = nil)
  if valid_402657966 != nil:
    section.add "VpcSecurityGroupIds", valid_402657966
  var valid_402657967 = query.getOrDefault("OptionGroupName")
  valid_402657967 = validateParameter(valid_402657967, JString,
                                      required = false, default = nil)
  if valid_402657967 != nil:
    section.add "OptionGroupName", valid_402657967
  var valid_402657968 = query.getOrDefault("PreferredBackupWindow")
  valid_402657968 = validateParameter(valid_402657968, JString,
                                      required = false, default = nil)
  if valid_402657968 != nil:
    section.add "PreferredBackupWindow", valid_402657968
  var valid_402657969 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402657969 = validateParameter(valid_402657969, JString,
                                      required = false, default = nil)
  if valid_402657969 != nil:
    section.add "PreferredMaintenanceWindow", valid_402657969
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657970 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657970 = validateParameter(valid_402657970, JString, required = true,
                                      default = nil)
  if valid_402657970 != nil:
    section.add "DBInstanceIdentifier", valid_402657970
  var valid_402657971 = query.getOrDefault("DBParameterGroupName")
  valid_402657971 = validateParameter(valid_402657971, JString,
                                      required = false, default = nil)
  if valid_402657971 != nil:
    section.add "DBParameterGroupName", valid_402657971
  var valid_402657972 = query.getOrDefault("MasterUserPassword")
  valid_402657972 = validateParameter(valid_402657972, JString,
                                      required = false, default = nil)
  if valid_402657972 != nil:
    section.add "MasterUserPassword", valid_402657972
  var valid_402657973 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_402657973 = validateParameter(valid_402657973, JBool, required = false,
                                      default = nil)
  if valid_402657973 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402657973
  var valid_402657974 = query.getOrDefault("Iops")
  valid_402657974 = validateParameter(valid_402657974, JInt, required = false,
                                      default = nil)
  if valid_402657974 != nil:
    section.add "Iops", valid_402657974
  var valid_402657975 = query.getOrDefault("ApplyImmediately")
  valid_402657975 = validateParameter(valid_402657975, JBool, required = false,
                                      default = nil)
  if valid_402657975 != nil:
    section.add "ApplyImmediately", valid_402657975
  var valid_402657976 = query.getOrDefault("MultiAZ")
  valid_402657976 = validateParameter(valid_402657976, JBool, required = false,
                                      default = nil)
  if valid_402657976 != nil:
    section.add "MultiAZ", valid_402657976
  var valid_402657977 = query.getOrDefault("Version")
  valid_402657977 = validateParameter(valid_402657977, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402657977 != nil:
    section.add "Version", valid_402657977
  var valid_402657978 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_402657978 = validateParameter(valid_402657978, JString,
                                      required = false, default = nil)
  if valid_402657978 != nil:
    section.add "NewDBInstanceIdentifier", valid_402657978
  var valid_402657979 = query.getOrDefault("EngineVersion")
  valid_402657979 = validateParameter(valid_402657979, JString,
                                      required = false, default = nil)
  if valid_402657979 != nil:
    section.add "EngineVersion", valid_402657979
  var valid_402657980 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402657980 = validateParameter(valid_402657980, JBool, required = false,
                                      default = nil)
  if valid_402657980 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402657980
  var valid_402657981 = query.getOrDefault("AllocatedStorage")
  valid_402657981 = validateParameter(valid_402657981, JInt, required = false,
                                      default = nil)
  if valid_402657981 != nil:
    section.add "AllocatedStorage", valid_402657981
  var valid_402657982 = query.getOrDefault("DBInstanceClass")
  valid_402657982 = validateParameter(valid_402657982, JString,
                                      required = false, default = nil)
  if valid_402657982 != nil:
    section.add "DBInstanceClass", valid_402657982
  var valid_402657983 = query.getOrDefault("Action")
  valid_402657983 = validateParameter(valid_402657983, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402657983 != nil:
    section.add "Action", valid_402657983
  var valid_402657984 = query.getOrDefault("BackupRetentionPeriod")
  valid_402657984 = validateParameter(valid_402657984, JInt, required = false,
                                      default = nil)
  if valid_402657984 != nil:
    section.add "BackupRetentionPeriod", valid_402657984
  var valid_402657985 = query.getOrDefault("DBSecurityGroups")
  valid_402657985 = validateParameter(valid_402657985, JArray, required = false,
                                      default = nil)
  if valid_402657985 != nil:
    section.add "DBSecurityGroups", valid_402657985
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
  var valid_402657986 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657986 = validateParameter(valid_402657986, JString,
                                      required = false, default = nil)
  if valid_402657986 != nil:
    section.add "X-Amz-Security-Token", valid_402657986
  var valid_402657987 = header.getOrDefault("X-Amz-Signature")
  valid_402657987 = validateParameter(valid_402657987, JString,
                                      required = false, default = nil)
  if valid_402657987 != nil:
    section.add "X-Amz-Signature", valid_402657987
  var valid_402657988 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657988 = validateParameter(valid_402657988, JString,
                                      required = false, default = nil)
  if valid_402657988 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657988
  var valid_402657989 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657989 = validateParameter(valid_402657989, JString,
                                      required = false, default = nil)
  if valid_402657989 != nil:
    section.add "X-Amz-Algorithm", valid_402657989
  var valid_402657990 = header.getOrDefault("X-Amz-Date")
  valid_402657990 = validateParameter(valid_402657990, JString,
                                      required = false, default = nil)
  if valid_402657990 != nil:
    section.add "X-Amz-Date", valid_402657990
  var valid_402657991 = header.getOrDefault("X-Amz-Credential")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "X-Amz-Credential", valid_402657991
  var valid_402657992 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657992
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657993: Call_GetModifyDBInstance_402657963;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657993.validator(path, query, header, formData, body, _)
  let scheme = call_402657993.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657993.makeUrl(scheme.get, call_402657993.host, call_402657993.base,
                                   call_402657993.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657993, uri, valid, _)

proc call*(call_402657994: Call_GetModifyDBInstance_402657963;
           DBInstanceIdentifier: string; VpcSecurityGroupIds: JsonNode = nil;
           OptionGroupName: string = ""; PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBParameterGroupName: string = ""; MasterUserPassword: string = "";
           AllowMajorVersionUpgrade: bool = false; Iops: int = 0;
           ApplyImmediately: bool = false; MultiAZ: bool = false;
           Version: string = "2013-02-12"; NewDBInstanceIdentifier: string = "";
           EngineVersion: string = ""; AutoMinorVersionUpgrade: bool = false;
           AllocatedStorage: int = 0; DBInstanceClass: string = "";
           Action: string = "ModifyDBInstance"; BackupRetentionPeriod: int = 0;
           DBSecurityGroups: JsonNode = nil): Recallable =
  ## getModifyDBInstance
  ##   VpcSecurityGroupIds: JArray
  ##   OptionGroupName: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBParameterGroupName: string
  ##   MasterUserPassword: string
  ##   AllowMajorVersionUpgrade: bool
  ##   Iops: int
  ##   ApplyImmediately: bool
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   NewDBInstanceIdentifier: string
  ##   EngineVersion: string
  ##   AutoMinorVersionUpgrade: bool
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBSecurityGroups: JArray
  var query_402657995 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402657995.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402657995, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657995, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402657995, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402657995, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657995, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657995, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402657995, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_402657995, "Iops", newJInt(Iops))
  add(query_402657995, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402657995, "MultiAZ", newJBool(MultiAZ))
  add(query_402657995, "Version", newJString(Version))
  add(query_402657995, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_402657995, "EngineVersion", newJString(EngineVersion))
  add(query_402657995, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402657995, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402657995, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657995, "Action", newJString(Action))
  add(query_402657995, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402657995.add "DBSecurityGroups", DBSecurityGroups
  result = call_402657994.call(nil, query_402657995, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_402657963(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_402657964, base: "/",
    makeUrl: url_GetModifyDBInstance_402657965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_402658047 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBParameterGroup_402658049(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_402658048(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658050 = query.getOrDefault("Version")
  valid_402658050 = validateParameter(valid_402658050, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658050 != nil:
    section.add "Version", valid_402658050
  var valid_402658051 = query.getOrDefault("Action")
  valid_402658051 = validateParameter(valid_402658051, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658051 != nil:
    section.add "Action", valid_402658051
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
  var valid_402658052 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658052 = validateParameter(valid_402658052, JString,
                                      required = false, default = nil)
  if valid_402658052 != nil:
    section.add "X-Amz-Security-Token", valid_402658052
  var valid_402658053 = header.getOrDefault("X-Amz-Signature")
  valid_402658053 = validateParameter(valid_402658053, JString,
                                      required = false, default = nil)
  if valid_402658053 != nil:
    section.add "X-Amz-Signature", valid_402658053
  var valid_402658054 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658054 = validateParameter(valid_402658054, JString,
                                      required = false, default = nil)
  if valid_402658054 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658054
  var valid_402658055 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658055 = validateParameter(valid_402658055, JString,
                                      required = false, default = nil)
  if valid_402658055 != nil:
    section.add "X-Amz-Algorithm", valid_402658055
  var valid_402658056 = header.getOrDefault("X-Amz-Date")
  valid_402658056 = validateParameter(valid_402658056, JString,
                                      required = false, default = nil)
  if valid_402658056 != nil:
    section.add "X-Amz-Date", valid_402658056
  var valid_402658057 = header.getOrDefault("X-Amz-Credential")
  valid_402658057 = validateParameter(valid_402658057, JString,
                                      required = false, default = nil)
  if valid_402658057 != nil:
    section.add "X-Amz-Credential", valid_402658057
  var valid_402658058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658058 = validateParameter(valid_402658058, JString,
                                      required = false, default = nil)
  if valid_402658058 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658058
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658059 = formData.getOrDefault("DBParameterGroupName")
  valid_402658059 = validateParameter(valid_402658059, JString, required = true,
                                      default = nil)
  if valid_402658059 != nil:
    section.add "DBParameterGroupName", valid_402658059
  var valid_402658060 = formData.getOrDefault("Parameters")
  valid_402658060 = validateParameter(valid_402658060, JArray, required = true,
                                      default = nil)
  if valid_402658060 != nil:
    section.add "Parameters", valid_402658060
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658061: Call_PostModifyDBParameterGroup_402658047;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658061.validator(path, query, header, formData, body, _)
  let scheme = call_402658061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658061.makeUrl(scheme.get, call_402658061.host, call_402658061.base,
                                   call_402658061.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658061, uri, valid, _)

proc call*(call_402658062: Call_PostModifyDBParameterGroup_402658047;
           DBParameterGroupName: string; Parameters: JsonNode;
           Version: string = "2013-02-12";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## postModifyDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  var query_402658063 = newJObject()
  var formData_402658064 = newJObject()
  add(query_402658063, "Version", newJString(Version))
  add(formData_402658064, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658063, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658064.add "Parameters", Parameters
  result = call_402658062.call(nil, query_402658063, nil, formData_402658064,
                               nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_402658047(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_402658048, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_402658049,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_402658030 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBParameterGroup_402658032(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_402658031(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray (required)
  ##   DBParameterGroupName: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Parameters` field"
  var valid_402658033 = query.getOrDefault("Parameters")
  valid_402658033 = validateParameter(valid_402658033, JArray, required = true,
                                      default = nil)
  if valid_402658033 != nil:
    section.add "Parameters", valid_402658033
  var valid_402658034 = query.getOrDefault("DBParameterGroupName")
  valid_402658034 = validateParameter(valid_402658034, JString, required = true,
                                      default = nil)
  if valid_402658034 != nil:
    section.add "DBParameterGroupName", valid_402658034
  var valid_402658035 = query.getOrDefault("Version")
  valid_402658035 = validateParameter(valid_402658035, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658035 != nil:
    section.add "Version", valid_402658035
  var valid_402658036 = query.getOrDefault("Action")
  valid_402658036 = validateParameter(valid_402658036, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658036 != nil:
    section.add "Action", valid_402658036
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
  var valid_402658037 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658037 = validateParameter(valid_402658037, JString,
                                      required = false, default = nil)
  if valid_402658037 != nil:
    section.add "X-Amz-Security-Token", valid_402658037
  var valid_402658038 = header.getOrDefault("X-Amz-Signature")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "X-Amz-Signature", valid_402658038
  var valid_402658039 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658039 = validateParameter(valid_402658039, JString,
                                      required = false, default = nil)
  if valid_402658039 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658039
  var valid_402658040 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658040 = validateParameter(valid_402658040, JString,
                                      required = false, default = nil)
  if valid_402658040 != nil:
    section.add "X-Amz-Algorithm", valid_402658040
  var valid_402658041 = header.getOrDefault("X-Amz-Date")
  valid_402658041 = validateParameter(valid_402658041, JString,
                                      required = false, default = nil)
  if valid_402658041 != nil:
    section.add "X-Amz-Date", valid_402658041
  var valid_402658042 = header.getOrDefault("X-Amz-Credential")
  valid_402658042 = validateParameter(valid_402658042, JString,
                                      required = false, default = nil)
  if valid_402658042 != nil:
    section.add "X-Amz-Credential", valid_402658042
  var valid_402658043 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658043 = validateParameter(valid_402658043, JString,
                                      required = false, default = nil)
  if valid_402658043 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658043
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658044: Call_GetModifyDBParameterGroup_402658030;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658044.validator(path, query, header, formData, body, _)
  let scheme = call_402658044.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658044.makeUrl(scheme.get, call_402658044.host, call_402658044.base,
                                   call_402658044.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658044, uri, valid, _)

proc call*(call_402658045: Call_GetModifyDBParameterGroup_402658030;
           Parameters: JsonNode; DBParameterGroupName: string;
           Version: string = "2013-02-12";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## getModifyDBParameterGroup
  ##   Parameters: JArray (required)
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658046 = newJObject()
  if Parameters != nil:
    query_402658046.add "Parameters", Parameters
  add(query_402658046, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658046, "Version", newJString(Version))
  add(query_402658046, "Action", newJString(Action))
  result = call_402658045.call(nil, query_402658046, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_402658030(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_402658031, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_402658032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_402658083 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBSubnetGroup_402658085(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_402658084(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658086 = query.getOrDefault("Version")
  valid_402658086 = validateParameter(valid_402658086, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658086 != nil:
    section.add "Version", valid_402658086
  var valid_402658087 = query.getOrDefault("Action")
  valid_402658087 = validateParameter(valid_402658087, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658087 != nil:
    section.add "Action", valid_402658087
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
  var valid_402658088 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658088 = validateParameter(valid_402658088, JString,
                                      required = false, default = nil)
  if valid_402658088 != nil:
    section.add "X-Amz-Security-Token", valid_402658088
  var valid_402658089 = header.getOrDefault("X-Amz-Signature")
  valid_402658089 = validateParameter(valid_402658089, JString,
                                      required = false, default = nil)
  if valid_402658089 != nil:
    section.add "X-Amz-Signature", valid_402658089
  var valid_402658090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658090 = validateParameter(valid_402658090, JString,
                                      required = false, default = nil)
  if valid_402658090 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658090
  var valid_402658091 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658091 = validateParameter(valid_402658091, JString,
                                      required = false, default = nil)
  if valid_402658091 != nil:
    section.add "X-Amz-Algorithm", valid_402658091
  var valid_402658092 = header.getOrDefault("X-Amz-Date")
  valid_402658092 = validateParameter(valid_402658092, JString,
                                      required = false, default = nil)
  if valid_402658092 != nil:
    section.add "X-Amz-Date", valid_402658092
  var valid_402658093 = header.getOrDefault("X-Amz-Credential")
  valid_402658093 = validateParameter(valid_402658093, JString,
                                      required = false, default = nil)
  if valid_402658093 != nil:
    section.add "X-Amz-Credential", valid_402658093
  var valid_402658094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658094 = validateParameter(valid_402658094, JString,
                                      required = false, default = nil)
  if valid_402658094 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658094
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402658095 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658095 = validateParameter(valid_402658095, JString, required = true,
                                      default = nil)
  if valid_402658095 != nil:
    section.add "DBSubnetGroupName", valid_402658095
  var valid_402658096 = formData.getOrDefault("SubnetIds")
  valid_402658096 = validateParameter(valid_402658096, JArray, required = true,
                                      default = nil)
  if valid_402658096 != nil:
    section.add "SubnetIds", valid_402658096
  var valid_402658097 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402658097 = validateParameter(valid_402658097, JString,
                                      required = false, default = nil)
  if valid_402658097 != nil:
    section.add "DBSubnetGroupDescription", valid_402658097
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658098: Call_PostModifyDBSubnetGroup_402658083;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658098.validator(path, query, header, formData, body, _)
  let scheme = call_402658098.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658098.makeUrl(scheme.get, call_402658098.host, call_402658098.base,
                                   call_402658098.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658098, uri, valid, _)

proc call*(call_402658099: Call_PostModifyDBSubnetGroup_402658083;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           Version: string = "2013-02-12";
           DBSubnetGroupDescription: string = "";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  var query_402658100 = newJObject()
  var formData_402658101 = newJObject()
  add(formData_402658101, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658100, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402658101.add "SubnetIds", SubnetIds
  add(formData_402658101, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658100, "Action", newJString(Action))
  result = call_402658099.call(nil, query_402658100, nil, formData_402658101,
                               nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_402658083(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_402658084, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_402658085,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_402658065 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBSubnetGroup_402658067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_402658066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSubnetGroupName: JString (required)
  ##   DBSubnetGroupDescription: JString
  ##   Version: JString (required)
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402658068 = query.getOrDefault("DBSubnetGroupName")
  valid_402658068 = validateParameter(valid_402658068, JString, required = true,
                                      default = nil)
  if valid_402658068 != nil:
    section.add "DBSubnetGroupName", valid_402658068
  var valid_402658069 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402658069 = validateParameter(valid_402658069, JString,
                                      required = false, default = nil)
  if valid_402658069 != nil:
    section.add "DBSubnetGroupDescription", valid_402658069
  var valid_402658070 = query.getOrDefault("Version")
  valid_402658070 = validateParameter(valid_402658070, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658070 != nil:
    section.add "Version", valid_402658070
  var valid_402658071 = query.getOrDefault("SubnetIds")
  valid_402658071 = validateParameter(valid_402658071, JArray, required = true,
                                      default = nil)
  if valid_402658071 != nil:
    section.add "SubnetIds", valid_402658071
  var valid_402658072 = query.getOrDefault("Action")
  valid_402658072 = validateParameter(valid_402658072, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658072 != nil:
    section.add "Action", valid_402658072
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
  var valid_402658073 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658073 = validateParameter(valid_402658073, JString,
                                      required = false, default = nil)
  if valid_402658073 != nil:
    section.add "X-Amz-Security-Token", valid_402658073
  var valid_402658074 = header.getOrDefault("X-Amz-Signature")
  valid_402658074 = validateParameter(valid_402658074, JString,
                                      required = false, default = nil)
  if valid_402658074 != nil:
    section.add "X-Amz-Signature", valid_402658074
  var valid_402658075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658075 = validateParameter(valid_402658075, JString,
                                      required = false, default = nil)
  if valid_402658075 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658075
  var valid_402658076 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658076 = validateParameter(valid_402658076, JString,
                                      required = false, default = nil)
  if valid_402658076 != nil:
    section.add "X-Amz-Algorithm", valid_402658076
  var valid_402658077 = header.getOrDefault("X-Amz-Date")
  valid_402658077 = validateParameter(valid_402658077, JString,
                                      required = false, default = nil)
  if valid_402658077 != nil:
    section.add "X-Amz-Date", valid_402658077
  var valid_402658078 = header.getOrDefault("X-Amz-Credential")
  valid_402658078 = validateParameter(valid_402658078, JString,
                                      required = false, default = nil)
  if valid_402658078 != nil:
    section.add "X-Amz-Credential", valid_402658078
  var valid_402658079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658079 = validateParameter(valid_402658079, JString,
                                      required = false, default = nil)
  if valid_402658079 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658080: Call_GetModifyDBSubnetGroup_402658065;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658080.validator(path, query, header, formData, body, _)
  let scheme = call_402658080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658080.makeUrl(scheme.get, call_402658080.host, call_402658080.base,
                                   call_402658080.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658080, uri, valid, _)

proc call*(call_402658081: Call_GetModifyDBSubnetGroup_402658065;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string = "";
           Version: string = "2013-02-12";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## getModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402658082 = newJObject()
  add(query_402658082, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658082, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658082, "Version", newJString(Version))
  if SubnetIds != nil:
    query_402658082.add "SubnetIds", SubnetIds
  add(query_402658082, "Action", newJString(Action))
  result = call_402658081.call(nil, query_402658082, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_402658065(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_402658066, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_402658067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_402658122 = ref object of OpenApiRestCall_402656035
proc url_PostModifyEventSubscription_402658124(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_402658123(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658125 = query.getOrDefault("Version")
  valid_402658125 = validateParameter(valid_402658125, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658125 != nil:
    section.add "Version", valid_402658125
  var valid_402658126 = query.getOrDefault("Action")
  valid_402658126 = validateParameter(valid_402658126, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658126 != nil:
    section.add "Action", valid_402658126
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
  var valid_402658127 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658127 = validateParameter(valid_402658127, JString,
                                      required = false, default = nil)
  if valid_402658127 != nil:
    section.add "X-Amz-Security-Token", valid_402658127
  var valid_402658128 = header.getOrDefault("X-Amz-Signature")
  valid_402658128 = validateParameter(valid_402658128, JString,
                                      required = false, default = nil)
  if valid_402658128 != nil:
    section.add "X-Amz-Signature", valid_402658128
  var valid_402658129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658129 = validateParameter(valid_402658129, JString,
                                      required = false, default = nil)
  if valid_402658129 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658129
  var valid_402658130 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658130 = validateParameter(valid_402658130, JString,
                                      required = false, default = nil)
  if valid_402658130 != nil:
    section.add "X-Amz-Algorithm", valid_402658130
  var valid_402658131 = header.getOrDefault("X-Amz-Date")
  valid_402658131 = validateParameter(valid_402658131, JString,
                                      required = false, default = nil)
  if valid_402658131 != nil:
    section.add "X-Amz-Date", valid_402658131
  var valid_402658132 = header.getOrDefault("X-Amz-Credential")
  valid_402658132 = validateParameter(valid_402658132, JString,
                                      required = false, default = nil)
  if valid_402658132 != nil:
    section.add "X-Amz-Credential", valid_402658132
  var valid_402658133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658133 = validateParameter(valid_402658133, JString,
                                      required = false, default = nil)
  if valid_402658133 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658133
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  section = newJObject()
  var valid_402658134 = formData.getOrDefault("SourceType")
  valid_402658134 = validateParameter(valid_402658134, JString,
                                      required = false, default = nil)
  if valid_402658134 != nil:
    section.add "SourceType", valid_402658134
  var valid_402658135 = formData.getOrDefault("Enabled")
  valid_402658135 = validateParameter(valid_402658135, JBool, required = false,
                                      default = nil)
  if valid_402658135 != nil:
    section.add "Enabled", valid_402658135
  var valid_402658136 = formData.getOrDefault("EventCategories")
  valid_402658136 = validateParameter(valid_402658136, JArray, required = false,
                                      default = nil)
  if valid_402658136 != nil:
    section.add "EventCategories", valid_402658136
  var valid_402658137 = formData.getOrDefault("SnsTopicArn")
  valid_402658137 = validateParameter(valid_402658137, JString,
                                      required = false, default = nil)
  if valid_402658137 != nil:
    section.add "SnsTopicArn", valid_402658137
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402658138 = formData.getOrDefault("SubscriptionName")
  valid_402658138 = validateParameter(valid_402658138, JString, required = true,
                                      default = nil)
  if valid_402658138 != nil:
    section.add "SubscriptionName", valid_402658138
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658139: Call_PostModifyEventSubscription_402658122;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658139.validator(path, query, header, formData, body, _)
  let scheme = call_402658139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658139.makeUrl(scheme.get, call_402658139.host, call_402658139.base,
                                   call_402658139.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658139, uri, valid, _)

proc call*(call_402658140: Call_PostModifyEventSubscription_402658122;
           SubscriptionName: string; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2013-02-12"; SnsTopicArn: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## postModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SnsTopicArn: string
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402658141 = newJObject()
  var formData_402658142 = newJObject()
  add(formData_402658142, "SourceType", newJString(SourceType))
  add(formData_402658142, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402658142.add "EventCategories", EventCategories
  add(query_402658141, "Version", newJString(Version))
  add(formData_402658142, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658141, "Action", newJString(Action))
  add(formData_402658142, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658140.call(nil, query_402658141, nil, formData_402658142,
                               nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_402658122(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_402658123, base: "/",
    makeUrl: url_PostModifyEventSubscription_402658124,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_402658102 = ref object of OpenApiRestCall_402656035
proc url_GetModifyEventSubscription_402658104(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_402658103(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SnsTopicArn: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   Version: JString (required)
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658105 = query.getOrDefault("SnsTopicArn")
  valid_402658105 = validateParameter(valid_402658105, JString,
                                      required = false, default = nil)
  if valid_402658105 != nil:
    section.add "SnsTopicArn", valid_402658105
  var valid_402658106 = query.getOrDefault("Enabled")
  valid_402658106 = validateParameter(valid_402658106, JBool, required = false,
                                      default = nil)
  if valid_402658106 != nil:
    section.add "Enabled", valid_402658106
  var valid_402658107 = query.getOrDefault("EventCategories")
  valid_402658107 = validateParameter(valid_402658107, JArray, required = false,
                                      default = nil)
  if valid_402658107 != nil:
    section.add "EventCategories", valid_402658107
  var valid_402658108 = query.getOrDefault("Version")
  valid_402658108 = validateParameter(valid_402658108, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658108 != nil:
    section.add "Version", valid_402658108
  var valid_402658109 = query.getOrDefault("SubscriptionName")
  valid_402658109 = validateParameter(valid_402658109, JString, required = true,
                                      default = nil)
  if valid_402658109 != nil:
    section.add "SubscriptionName", valid_402658109
  var valid_402658110 = query.getOrDefault("SourceType")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "SourceType", valid_402658110
  var valid_402658111 = query.getOrDefault("Action")
  valid_402658111 = validateParameter(valid_402658111, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658111 != nil:
    section.add "Action", valid_402658111
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
  var valid_402658112 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658112 = validateParameter(valid_402658112, JString,
                                      required = false, default = nil)
  if valid_402658112 != nil:
    section.add "X-Amz-Security-Token", valid_402658112
  var valid_402658113 = header.getOrDefault("X-Amz-Signature")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "X-Amz-Signature", valid_402658113
  var valid_402658114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658114 = validateParameter(valid_402658114, JString,
                                      required = false, default = nil)
  if valid_402658114 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658114
  var valid_402658115 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658115 = validateParameter(valid_402658115, JString,
                                      required = false, default = nil)
  if valid_402658115 != nil:
    section.add "X-Amz-Algorithm", valid_402658115
  var valid_402658116 = header.getOrDefault("X-Amz-Date")
  valid_402658116 = validateParameter(valid_402658116, JString,
                                      required = false, default = nil)
  if valid_402658116 != nil:
    section.add "X-Amz-Date", valid_402658116
  var valid_402658117 = header.getOrDefault("X-Amz-Credential")
  valid_402658117 = validateParameter(valid_402658117, JString,
                                      required = false, default = nil)
  if valid_402658117 != nil:
    section.add "X-Amz-Credential", valid_402658117
  var valid_402658118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658118 = validateParameter(valid_402658118, JString,
                                      required = false, default = nil)
  if valid_402658118 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658119: Call_GetModifyEventSubscription_402658102;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658119.validator(path, query, header, formData, body, _)
  let scheme = call_402658119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658119.makeUrl(scheme.get, call_402658119.host, call_402658119.base,
                                   call_402658119.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658119, uri, valid, _)

proc call*(call_402658120: Call_GetModifyEventSubscription_402658102;
           SubscriptionName: string; SnsTopicArn: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2013-02-12"; SourceType: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## getModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402658121 = newJObject()
  add(query_402658121, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658121, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402658121.add "EventCategories", EventCategories
  add(query_402658121, "Version", newJString(Version))
  add(query_402658121, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658121, "SourceType", newJString(SourceType))
  add(query_402658121, "Action", newJString(Action))
  result = call_402658120.call(nil, query_402658121, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_402658102(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_402658103, base: "/",
    makeUrl: url_GetModifyEventSubscription_402658104,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_402658162 = ref object of OpenApiRestCall_402656035
proc url_PostModifyOptionGroup_402658164(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_402658163(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658165 = query.getOrDefault("Version")
  valid_402658165 = validateParameter(valid_402658165, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658165 != nil:
    section.add "Version", valid_402658165
  var valid_402658166 = query.getOrDefault("Action")
  valid_402658166 = validateParameter(valid_402658166, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658166 != nil:
    section.add "Action", valid_402658166
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
  var valid_402658167 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658167 = validateParameter(valid_402658167, JString,
                                      required = false, default = nil)
  if valid_402658167 != nil:
    section.add "X-Amz-Security-Token", valid_402658167
  var valid_402658168 = header.getOrDefault("X-Amz-Signature")
  valid_402658168 = validateParameter(valid_402658168, JString,
                                      required = false, default = nil)
  if valid_402658168 != nil:
    section.add "X-Amz-Signature", valid_402658168
  var valid_402658169 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658169 = validateParameter(valid_402658169, JString,
                                      required = false, default = nil)
  if valid_402658169 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658169
  var valid_402658170 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658170 = validateParameter(valid_402658170, JString,
                                      required = false, default = nil)
  if valid_402658170 != nil:
    section.add "X-Amz-Algorithm", valid_402658170
  var valid_402658171 = header.getOrDefault("X-Amz-Date")
  valid_402658171 = validateParameter(valid_402658171, JString,
                                      required = false, default = nil)
  if valid_402658171 != nil:
    section.add "X-Amz-Date", valid_402658171
  var valid_402658172 = header.getOrDefault("X-Amz-Credential")
  valid_402658172 = validateParameter(valid_402658172, JString,
                                      required = false, default = nil)
  if valid_402658172 != nil:
    section.add "X-Amz-Credential", valid_402658172
  var valid_402658173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658173 = validateParameter(valid_402658173, JString,
                                      required = false, default = nil)
  if valid_402658173 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658173
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_402658174 = formData.getOrDefault("OptionsToRemove")
  valid_402658174 = validateParameter(valid_402658174, JArray, required = false,
                                      default = nil)
  if valid_402658174 != nil:
    section.add "OptionsToRemove", valid_402658174
  var valid_402658175 = formData.getOrDefault("OptionsToInclude")
  valid_402658175 = validateParameter(valid_402658175, JArray, required = false,
                                      default = nil)
  if valid_402658175 != nil:
    section.add "OptionsToInclude", valid_402658175
  var valid_402658176 = formData.getOrDefault("ApplyImmediately")
  valid_402658176 = validateParameter(valid_402658176, JBool, required = false,
                                      default = nil)
  if valid_402658176 != nil:
    section.add "ApplyImmediately", valid_402658176
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402658177 = formData.getOrDefault("OptionGroupName")
  valid_402658177 = validateParameter(valid_402658177, JString, required = true,
                                      default = nil)
  if valid_402658177 != nil:
    section.add "OptionGroupName", valid_402658177
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658178: Call_PostModifyOptionGroup_402658162;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658178.validator(path, query, header, formData, body, _)
  let scheme = call_402658178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658178.makeUrl(scheme.get, call_402658178.host, call_402658178.base,
                                   call_402658178.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658178, uri, valid, _)

proc call*(call_402658179: Call_PostModifyOptionGroup_402658162;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2013-02-12"; Action: string = "ModifyOptionGroup"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402658180 = newJObject()
  var formData_402658181 = newJObject()
  if OptionsToRemove != nil:
    formData_402658181.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    formData_402658181.add "OptionsToInclude", OptionsToInclude
  add(formData_402658181, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658180, "Version", newJString(Version))
  add(formData_402658181, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658180, "Action", newJString(Action))
  result = call_402658179.call(nil, query_402658180, nil, formData_402658181,
                               nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_402658162(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_402658163, base: "/",
    makeUrl: url_PostModifyOptionGroup_402658164,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_402658143 = ref object of OpenApiRestCall_402656035
proc url_GetModifyOptionGroup_402658145(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_402658144(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionsToRemove: JArray
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: JBool
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658146 = query.getOrDefault("OptionsToRemove")
  valid_402658146 = validateParameter(valid_402658146, JArray, required = false,
                                      default = nil)
  if valid_402658146 != nil:
    section.add "OptionsToRemove", valid_402658146
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402658147 = query.getOrDefault("OptionGroupName")
  valid_402658147 = validateParameter(valid_402658147, JString, required = true,
                                      default = nil)
  if valid_402658147 != nil:
    section.add "OptionGroupName", valid_402658147
  var valid_402658148 = query.getOrDefault("OptionsToInclude")
  valid_402658148 = validateParameter(valid_402658148, JArray, required = false,
                                      default = nil)
  if valid_402658148 != nil:
    section.add "OptionsToInclude", valid_402658148
  var valid_402658149 = query.getOrDefault("ApplyImmediately")
  valid_402658149 = validateParameter(valid_402658149, JBool, required = false,
                                      default = nil)
  if valid_402658149 != nil:
    section.add "ApplyImmediately", valid_402658149
  var valid_402658150 = query.getOrDefault("Version")
  valid_402658150 = validateParameter(valid_402658150, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658150 != nil:
    section.add "Version", valid_402658150
  var valid_402658151 = query.getOrDefault("Action")
  valid_402658151 = validateParameter(valid_402658151, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658151 != nil:
    section.add "Action", valid_402658151
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
  var valid_402658152 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658152 = validateParameter(valid_402658152, JString,
                                      required = false, default = nil)
  if valid_402658152 != nil:
    section.add "X-Amz-Security-Token", valid_402658152
  var valid_402658153 = header.getOrDefault("X-Amz-Signature")
  valid_402658153 = validateParameter(valid_402658153, JString,
                                      required = false, default = nil)
  if valid_402658153 != nil:
    section.add "X-Amz-Signature", valid_402658153
  var valid_402658154 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658154 = validateParameter(valid_402658154, JString,
                                      required = false, default = nil)
  if valid_402658154 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658154
  var valid_402658155 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658155 = validateParameter(valid_402658155, JString,
                                      required = false, default = nil)
  if valid_402658155 != nil:
    section.add "X-Amz-Algorithm", valid_402658155
  var valid_402658156 = header.getOrDefault("X-Amz-Date")
  valid_402658156 = validateParameter(valid_402658156, JString,
                                      required = false, default = nil)
  if valid_402658156 != nil:
    section.add "X-Amz-Date", valid_402658156
  var valid_402658157 = header.getOrDefault("X-Amz-Credential")
  valid_402658157 = validateParameter(valid_402658157, JString,
                                      required = false, default = nil)
  if valid_402658157 != nil:
    section.add "X-Amz-Credential", valid_402658157
  var valid_402658158 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658158
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658159: Call_GetModifyOptionGroup_402658143;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658159.validator(path, query, header, formData, body, _)
  let scheme = call_402658159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658159.makeUrl(scheme.get, call_402658159.host, call_402658159.base,
                                   call_402658159.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658159, uri, valid, _)

proc call*(call_402658160: Call_GetModifyOptionGroup_402658143;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2013-02-12"; Action: string = "ModifyOptionGroup"): Recallable =
  ## getModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658161 = newJObject()
  if OptionsToRemove != nil:
    query_402658161.add "OptionsToRemove", OptionsToRemove
  add(query_402658161, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    query_402658161.add "OptionsToInclude", OptionsToInclude
  add(query_402658161, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658161, "Version", newJString(Version))
  add(query_402658161, "Action", newJString(Action))
  result = call_402658160.call(nil, query_402658161, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_402658143(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_402658144, base: "/",
    makeUrl: url_GetModifyOptionGroup_402658145,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_402658200 = ref object of OpenApiRestCall_402656035
proc url_PostPromoteReadReplica_402658202(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_402658201(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658203 = query.getOrDefault("Version")
  valid_402658203 = validateParameter(valid_402658203, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658203 != nil:
    section.add "Version", valid_402658203
  var valid_402658204 = query.getOrDefault("Action")
  valid_402658204 = validateParameter(valid_402658204, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658204 != nil:
    section.add "Action", valid_402658204
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
  var valid_402658205 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658205 = validateParameter(valid_402658205, JString,
                                      required = false, default = nil)
  if valid_402658205 != nil:
    section.add "X-Amz-Security-Token", valid_402658205
  var valid_402658206 = header.getOrDefault("X-Amz-Signature")
  valid_402658206 = validateParameter(valid_402658206, JString,
                                      required = false, default = nil)
  if valid_402658206 != nil:
    section.add "X-Amz-Signature", valid_402658206
  var valid_402658207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658207 = validateParameter(valid_402658207, JString,
                                      required = false, default = nil)
  if valid_402658207 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658207
  var valid_402658208 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658208 = validateParameter(valid_402658208, JString,
                                      required = false, default = nil)
  if valid_402658208 != nil:
    section.add "X-Amz-Algorithm", valid_402658208
  var valid_402658209 = header.getOrDefault("X-Amz-Date")
  valid_402658209 = validateParameter(valid_402658209, JString,
                                      required = false, default = nil)
  if valid_402658209 != nil:
    section.add "X-Amz-Date", valid_402658209
  var valid_402658210 = header.getOrDefault("X-Amz-Credential")
  valid_402658210 = validateParameter(valid_402658210, JString,
                                      required = false, default = nil)
  if valid_402658210 != nil:
    section.add "X-Amz-Credential", valid_402658210
  var valid_402658211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658211 = validateParameter(valid_402658211, JString,
                                      required = false, default = nil)
  if valid_402658211 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658211
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658212 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658212 = validateParameter(valid_402658212, JString,
                                      required = false, default = nil)
  if valid_402658212 != nil:
    section.add "PreferredBackupWindow", valid_402658212
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658213 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658213 = validateParameter(valid_402658213, JString, required = true,
                                      default = nil)
  if valid_402658213 != nil:
    section.add "DBInstanceIdentifier", valid_402658213
  var valid_402658214 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658214 = validateParameter(valid_402658214, JInt, required = false,
                                      default = nil)
  if valid_402658214 != nil:
    section.add "BackupRetentionPeriod", valid_402658214
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658215: Call_PostPromoteReadReplica_402658200;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658215.validator(path, query, header, formData, body, _)
  let scheme = call_402658215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658215.makeUrl(scheme.get, call_402658215.host, call_402658215.base,
                                   call_402658215.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658215, uri, valid, _)

proc call*(call_402658216: Call_PostPromoteReadReplica_402658200;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2013-02-12";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658217 = newJObject()
  var formData_402658218 = newJObject()
  add(formData_402658218, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658217, "Version", newJString(Version))
  add(formData_402658218, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658217, "Action", newJString(Action))
  add(formData_402658218, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658216.call(nil, query_402658217, nil, formData_402658218,
                               nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_402658200(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_402658201, base: "/",
    makeUrl: url_PostPromoteReadReplica_402658202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_402658182 = ref object of OpenApiRestCall_402656035
proc url_GetPromoteReadReplica_402658184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_402658183(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredBackupWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658185 = query.getOrDefault("PreferredBackupWindow")
  valid_402658185 = validateParameter(valid_402658185, JString,
                                      required = false, default = nil)
  if valid_402658185 != nil:
    section.add "PreferredBackupWindow", valid_402658185
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658186 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658186 = validateParameter(valid_402658186, JString, required = true,
                                      default = nil)
  if valid_402658186 != nil:
    section.add "DBInstanceIdentifier", valid_402658186
  var valid_402658187 = query.getOrDefault("Version")
  valid_402658187 = validateParameter(valid_402658187, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658187 != nil:
    section.add "Version", valid_402658187
  var valid_402658188 = query.getOrDefault("Action")
  valid_402658188 = validateParameter(valid_402658188, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658188 != nil:
    section.add "Action", valid_402658188
  var valid_402658189 = query.getOrDefault("BackupRetentionPeriod")
  valid_402658189 = validateParameter(valid_402658189, JInt, required = false,
                                      default = nil)
  if valid_402658189 != nil:
    section.add "BackupRetentionPeriod", valid_402658189
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
  var valid_402658190 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658190 = validateParameter(valid_402658190, JString,
                                      required = false, default = nil)
  if valid_402658190 != nil:
    section.add "X-Amz-Security-Token", valid_402658190
  var valid_402658191 = header.getOrDefault("X-Amz-Signature")
  valid_402658191 = validateParameter(valid_402658191, JString,
                                      required = false, default = nil)
  if valid_402658191 != nil:
    section.add "X-Amz-Signature", valid_402658191
  var valid_402658192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658192 = validateParameter(valid_402658192, JString,
                                      required = false, default = nil)
  if valid_402658192 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658192
  var valid_402658193 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658193 = validateParameter(valid_402658193, JString,
                                      required = false, default = nil)
  if valid_402658193 != nil:
    section.add "X-Amz-Algorithm", valid_402658193
  var valid_402658194 = header.getOrDefault("X-Amz-Date")
  valid_402658194 = validateParameter(valid_402658194, JString,
                                      required = false, default = nil)
  if valid_402658194 != nil:
    section.add "X-Amz-Date", valid_402658194
  var valid_402658195 = header.getOrDefault("X-Amz-Credential")
  valid_402658195 = validateParameter(valid_402658195, JString,
                                      required = false, default = nil)
  if valid_402658195 != nil:
    section.add "X-Amz-Credential", valid_402658195
  var valid_402658196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658196 = validateParameter(valid_402658196, JString,
                                      required = false, default = nil)
  if valid_402658196 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658197: Call_GetPromoteReadReplica_402658182;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658197.validator(path, query, header, formData, body, _)
  let scheme = call_402658197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658197.makeUrl(scheme.get, call_402658197.host, call_402658197.base,
                                   call_402658197.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658197, uri, valid, _)

proc call*(call_402658198: Call_GetPromoteReadReplica_402658182;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2013-02-12";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## getPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658199 = newJObject()
  add(query_402658199, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658199, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658199, "Version", newJString(Version))
  add(query_402658199, "Action", newJString(Action))
  add(query_402658199, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  result = call_402658198.call(nil, query_402658199, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_402658182(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_402658183, base: "/",
    makeUrl: url_GetPromoteReadReplica_402658184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_402658237 = ref object of OpenApiRestCall_402656035
proc url_PostPurchaseReservedDBInstancesOffering_402658239(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_402658238(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658240 = query.getOrDefault("Version")
  valid_402658240 = validateParameter(valid_402658240, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658240 != nil:
    section.add "Version", valid_402658240
  var valid_402658241 = query.getOrDefault("Action")
  valid_402658241 = validateParameter(valid_402658241, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_402658241 != nil:
    section.add "Action", valid_402658241
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
  var valid_402658242 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658242 = validateParameter(valid_402658242, JString,
                                      required = false, default = nil)
  if valid_402658242 != nil:
    section.add "X-Amz-Security-Token", valid_402658242
  var valid_402658243 = header.getOrDefault("X-Amz-Signature")
  valid_402658243 = validateParameter(valid_402658243, JString,
                                      required = false, default = nil)
  if valid_402658243 != nil:
    section.add "X-Amz-Signature", valid_402658243
  var valid_402658244 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658244 = validateParameter(valid_402658244, JString,
                                      required = false, default = nil)
  if valid_402658244 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658244
  var valid_402658245 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658245 = validateParameter(valid_402658245, JString,
                                      required = false, default = nil)
  if valid_402658245 != nil:
    section.add "X-Amz-Algorithm", valid_402658245
  var valid_402658246 = header.getOrDefault("X-Amz-Date")
  valid_402658246 = validateParameter(valid_402658246, JString,
                                      required = false, default = nil)
  if valid_402658246 != nil:
    section.add "X-Amz-Date", valid_402658246
  var valid_402658247 = header.getOrDefault("X-Amz-Credential")
  valid_402658247 = validateParameter(valid_402658247, JString,
                                      required = false, default = nil)
  if valid_402658247 != nil:
    section.add "X-Amz-Credential", valid_402658247
  var valid_402658248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658248 = validateParameter(valid_402658248, JString,
                                      required = false, default = nil)
  if valid_402658248 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658248
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   ReservedDBInstanceId: JString
  section = newJObject()
  var valid_402658249 = formData.getOrDefault("DBInstanceCount")
  valid_402658249 = validateParameter(valid_402658249, JInt, required = false,
                                      default = nil)
  if valid_402658249 != nil:
    section.add "DBInstanceCount", valid_402658249
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658250 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658250 = validateParameter(valid_402658250, JString, required = true,
                                      default = nil)
  if valid_402658250 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658250
  var valid_402658251 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402658251 = validateParameter(valid_402658251, JString,
                                      required = false, default = nil)
  if valid_402658251 != nil:
    section.add "ReservedDBInstanceId", valid_402658251
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658252: Call_PostPurchaseReservedDBInstancesOffering_402658237;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658252.validator(path, query, header, formData, body, _)
  let scheme = call_402658252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658252.makeUrl(scheme.get, call_402658252.host, call_402658252.base,
                                   call_402658252.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658252, uri, valid, _)

proc call*(call_402658253: Call_PostPurchaseReservedDBInstancesOffering_402658237;
           ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
           Version: string = "2013-02-12"; ReservedDBInstanceId: string = "";
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Version: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  var query_402658254 = newJObject()
  var formData_402658255 = newJObject()
  add(formData_402658255, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_402658254, "Version", newJString(Version))
  add(formData_402658255, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402658255, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(query_402658254, "Action", newJString(Action))
  result = call_402658253.call(nil, query_402658254, nil, formData_402658255,
                               nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_402658237(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_402658238,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_402658239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_402658219 = ref object of OpenApiRestCall_402656035
proc url_GetPurchaseReservedDBInstancesOffering_402658221(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_402658220(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceCount: JInt
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658222 = query.getOrDefault("ReservedDBInstanceId")
  valid_402658222 = validateParameter(valid_402658222, JString,
                                      required = false, default = nil)
  if valid_402658222 != nil:
    section.add "ReservedDBInstanceId", valid_402658222
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658223 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658223 = validateParameter(valid_402658223, JString, required = true,
                                      default = nil)
  if valid_402658223 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658223
  var valid_402658224 = query.getOrDefault("Version")
  valid_402658224 = validateParameter(valid_402658224, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658224 != nil:
    section.add "Version", valid_402658224
  var valid_402658225 = query.getOrDefault("DBInstanceCount")
  valid_402658225 = validateParameter(valid_402658225, JInt, required = false,
                                      default = nil)
  if valid_402658225 != nil:
    section.add "DBInstanceCount", valid_402658225
  var valid_402658226 = query.getOrDefault("Action")
  valid_402658226 = validateParameter(valid_402658226, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_402658226 != nil:
    section.add "Action", valid_402658226
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
  var valid_402658227 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658227 = validateParameter(valid_402658227, JString,
                                      required = false, default = nil)
  if valid_402658227 != nil:
    section.add "X-Amz-Security-Token", valid_402658227
  var valid_402658228 = header.getOrDefault("X-Amz-Signature")
  valid_402658228 = validateParameter(valid_402658228, JString,
                                      required = false, default = nil)
  if valid_402658228 != nil:
    section.add "X-Amz-Signature", valid_402658228
  var valid_402658229 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658229 = validateParameter(valid_402658229, JString,
                                      required = false, default = nil)
  if valid_402658229 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658229
  var valid_402658230 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658230 = validateParameter(valid_402658230, JString,
                                      required = false, default = nil)
  if valid_402658230 != nil:
    section.add "X-Amz-Algorithm", valid_402658230
  var valid_402658231 = header.getOrDefault("X-Amz-Date")
  valid_402658231 = validateParameter(valid_402658231, JString,
                                      required = false, default = nil)
  if valid_402658231 != nil:
    section.add "X-Amz-Date", valid_402658231
  var valid_402658232 = header.getOrDefault("X-Amz-Credential")
  valid_402658232 = validateParameter(valid_402658232, JString,
                                      required = false, default = nil)
  if valid_402658232 != nil:
    section.add "X-Amz-Credential", valid_402658232
  var valid_402658233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658233 = validateParameter(valid_402658233, JString,
                                      required = false, default = nil)
  if valid_402658233 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658234: Call_GetPurchaseReservedDBInstancesOffering_402658219;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658234.validator(path, query, header, formData, body, _)
  let scheme = call_402658234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658234.makeUrl(scheme.get, call_402658234.host, call_402658234.base,
                                   call_402658234.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658234, uri, valid, _)

proc call*(call_402658235: Call_GetPurchaseReservedDBInstancesOffering_402658219;
           ReservedDBInstancesOfferingId: string;
           ReservedDBInstanceId: string = ""; Version: string = "2013-02-12";
           DBInstanceCount: int = 0;
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   DBInstanceCount: int
  ##   Action: string (required)
  var query_402658236 = newJObject()
  add(query_402658236, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_402658236, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402658236, "Version", newJString(Version))
  add(query_402658236, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_402658236, "Action", newJString(Action))
  result = call_402658235.call(nil, query_402658236, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_402658219(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_402658220,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_402658221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_402658273 = ref object of OpenApiRestCall_402656035
proc url_PostRebootDBInstance_402658275(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_402658274(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658276 = query.getOrDefault("Version")
  valid_402658276 = validateParameter(valid_402658276, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658276 != nil:
    section.add "Version", valid_402658276
  var valid_402658277 = query.getOrDefault("Action")
  valid_402658277 = validateParameter(valid_402658277, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658277 != nil:
    section.add "Action", valid_402658277
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
  var valid_402658278 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658278 = validateParameter(valid_402658278, JString,
                                      required = false, default = nil)
  if valid_402658278 != nil:
    section.add "X-Amz-Security-Token", valid_402658278
  var valid_402658279 = header.getOrDefault("X-Amz-Signature")
  valid_402658279 = validateParameter(valid_402658279, JString,
                                      required = false, default = nil)
  if valid_402658279 != nil:
    section.add "X-Amz-Signature", valid_402658279
  var valid_402658280 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658280 = validateParameter(valid_402658280, JString,
                                      required = false, default = nil)
  if valid_402658280 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658280
  var valid_402658281 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658281 = validateParameter(valid_402658281, JString,
                                      required = false, default = nil)
  if valid_402658281 != nil:
    section.add "X-Amz-Algorithm", valid_402658281
  var valid_402658282 = header.getOrDefault("X-Amz-Date")
  valid_402658282 = validateParameter(valid_402658282, JString,
                                      required = false, default = nil)
  if valid_402658282 != nil:
    section.add "X-Amz-Date", valid_402658282
  var valid_402658283 = header.getOrDefault("X-Amz-Credential")
  valid_402658283 = validateParameter(valid_402658283, JString,
                                      required = false, default = nil)
  if valid_402658283 != nil:
    section.add "X-Amz-Credential", valid_402658283
  var valid_402658284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658284 = validateParameter(valid_402658284, JString,
                                      required = false, default = nil)
  if valid_402658284 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658284
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658285 = formData.getOrDefault("ForceFailover")
  valid_402658285 = validateParameter(valid_402658285, JBool, required = false,
                                      default = nil)
  if valid_402658285 != nil:
    section.add "ForceFailover", valid_402658285
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658286 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658286 = validateParameter(valid_402658286, JString, required = true,
                                      default = nil)
  if valid_402658286 != nil:
    section.add "DBInstanceIdentifier", valid_402658286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658287: Call_PostRebootDBInstance_402658273;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658287.validator(path, query, header, formData, body, _)
  let scheme = call_402658287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658287.makeUrl(scheme.get, call_402658287.host, call_402658287.base,
                                   call_402658287.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658287, uri, valid, _)

proc call*(call_402658288: Call_PostRebootDBInstance_402658273;
           DBInstanceIdentifier: string; Version: string = "2013-02-12";
           ForceFailover: bool = false; Action: string = "RebootDBInstance"): Recallable =
  ## postRebootDBInstance
  ##   Version: string (required)
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  var query_402658289 = newJObject()
  var formData_402658290 = newJObject()
  add(query_402658289, "Version", newJString(Version))
  add(formData_402658290, "ForceFailover", newJBool(ForceFailover))
  add(formData_402658290, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658289, "Action", newJString(Action))
  result = call_402658288.call(nil, query_402658289, nil, formData_402658290,
                               nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_402658273(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_402658274, base: "/",
    makeUrl: url_PostRebootDBInstance_402658275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_402658256 = ref object of OpenApiRestCall_402656035
proc url_GetRebootDBInstance_402658258(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_402658257(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658259 = query.getOrDefault("ForceFailover")
  valid_402658259 = validateParameter(valid_402658259, JBool, required = false,
                                      default = nil)
  if valid_402658259 != nil:
    section.add "ForceFailover", valid_402658259
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658260 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658260 = validateParameter(valid_402658260, JString, required = true,
                                      default = nil)
  if valid_402658260 != nil:
    section.add "DBInstanceIdentifier", valid_402658260
  var valid_402658261 = query.getOrDefault("Version")
  valid_402658261 = validateParameter(valid_402658261, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658261 != nil:
    section.add "Version", valid_402658261
  var valid_402658262 = query.getOrDefault("Action")
  valid_402658262 = validateParameter(valid_402658262, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658262 != nil:
    section.add "Action", valid_402658262
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
  var valid_402658263 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658263 = validateParameter(valid_402658263, JString,
                                      required = false, default = nil)
  if valid_402658263 != nil:
    section.add "X-Amz-Security-Token", valid_402658263
  var valid_402658264 = header.getOrDefault("X-Amz-Signature")
  valid_402658264 = validateParameter(valid_402658264, JString,
                                      required = false, default = nil)
  if valid_402658264 != nil:
    section.add "X-Amz-Signature", valid_402658264
  var valid_402658265 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658265 = validateParameter(valid_402658265, JString,
                                      required = false, default = nil)
  if valid_402658265 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658265
  var valid_402658266 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658266 = validateParameter(valid_402658266, JString,
                                      required = false, default = nil)
  if valid_402658266 != nil:
    section.add "X-Amz-Algorithm", valid_402658266
  var valid_402658267 = header.getOrDefault("X-Amz-Date")
  valid_402658267 = validateParameter(valid_402658267, JString,
                                      required = false, default = nil)
  if valid_402658267 != nil:
    section.add "X-Amz-Date", valid_402658267
  var valid_402658268 = header.getOrDefault("X-Amz-Credential")
  valid_402658268 = validateParameter(valid_402658268, JString,
                                      required = false, default = nil)
  if valid_402658268 != nil:
    section.add "X-Amz-Credential", valid_402658268
  var valid_402658269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658269 = validateParameter(valid_402658269, JString,
                                      required = false, default = nil)
  if valid_402658269 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658269
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658270: Call_GetRebootDBInstance_402658256;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658270.validator(path, query, header, formData, body, _)
  let scheme = call_402658270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658270.makeUrl(scheme.get, call_402658270.host, call_402658270.base,
                                   call_402658270.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658270, uri, valid, _)

proc call*(call_402658271: Call_GetRebootDBInstance_402658256;
           DBInstanceIdentifier: string; ForceFailover: bool = false;
           Version: string = "2013-02-12"; Action: string = "RebootDBInstance"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658272 = newJObject()
  add(query_402658272, "ForceFailover", newJBool(ForceFailover))
  add(query_402658272, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658272, "Version", newJString(Version))
  add(query_402658272, "Action", newJString(Action))
  result = call_402658271.call(nil, query_402658272, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_402658256(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_402658257, base: "/",
    makeUrl: url_GetRebootDBInstance_402658258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_402658308 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveSourceIdentifierFromSubscription_402658310(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_402658309(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658311 = query.getOrDefault("Version")
  valid_402658311 = validateParameter(valid_402658311, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658311 != nil:
    section.add "Version", valid_402658311
  var valid_402658312 = query.getOrDefault("Action")
  valid_402658312 = validateParameter(valid_402658312, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658312 != nil:
    section.add "Action", valid_402658312
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
  var valid_402658313 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658313 = validateParameter(valid_402658313, JString,
                                      required = false, default = nil)
  if valid_402658313 != nil:
    section.add "X-Amz-Security-Token", valid_402658313
  var valid_402658314 = header.getOrDefault("X-Amz-Signature")
  valid_402658314 = validateParameter(valid_402658314, JString,
                                      required = false, default = nil)
  if valid_402658314 != nil:
    section.add "X-Amz-Signature", valid_402658314
  var valid_402658315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658315 = validateParameter(valid_402658315, JString,
                                      required = false, default = nil)
  if valid_402658315 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658315
  var valid_402658316 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658316 = validateParameter(valid_402658316, JString,
                                      required = false, default = nil)
  if valid_402658316 != nil:
    section.add "X-Amz-Algorithm", valid_402658316
  var valid_402658317 = header.getOrDefault("X-Amz-Date")
  valid_402658317 = validateParameter(valid_402658317, JString,
                                      required = false, default = nil)
  if valid_402658317 != nil:
    section.add "X-Amz-Date", valid_402658317
  var valid_402658318 = header.getOrDefault("X-Amz-Credential")
  valid_402658318 = validateParameter(valid_402658318, JString,
                                      required = false, default = nil)
  if valid_402658318 != nil:
    section.add "X-Amz-Credential", valid_402658318
  var valid_402658319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658319 = validateParameter(valid_402658319, JString,
                                      required = false, default = nil)
  if valid_402658319 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658319
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_402658320 = formData.getOrDefault("SourceIdentifier")
  valid_402658320 = validateParameter(valid_402658320, JString, required = true,
                                      default = nil)
  if valid_402658320 != nil:
    section.add "SourceIdentifier", valid_402658320
  var valid_402658321 = formData.getOrDefault("SubscriptionName")
  valid_402658321 = validateParameter(valid_402658321, JString, required = true,
                                      default = nil)
  if valid_402658321 != nil:
    section.add "SubscriptionName", valid_402658321
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658322: Call_PostRemoveSourceIdentifierFromSubscription_402658308;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658322.validator(path, query, header, formData, body, _)
  let scheme = call_402658322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658322.makeUrl(scheme.get, call_402658322.host, call_402658322.base,
                                   call_402658322.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658322, uri, valid, _)

proc call*(call_402658323: Call_PostRemoveSourceIdentifierFromSubscription_402658308;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-02-12";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  var query_402658324 = newJObject()
  var formData_402658325 = newJObject()
  add(query_402658324, "Version", newJString(Version))
  add(query_402658324, "Action", newJString(Action))
  add(formData_402658325, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_402658325, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658323.call(nil, query_402658324, nil, formData_402658325,
                               nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_402658308(
    name: "postRemoveSourceIdentifierFromSubscription",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_402658309,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_402658310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_402658291 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveSourceIdentifierFromSubscription_402658293(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_402658292(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `SourceIdentifier` field"
  var valid_402658294 = query.getOrDefault("SourceIdentifier")
  valid_402658294 = validateParameter(valid_402658294, JString, required = true,
                                      default = nil)
  if valid_402658294 != nil:
    section.add "SourceIdentifier", valid_402658294
  var valid_402658295 = query.getOrDefault("Version")
  valid_402658295 = validateParameter(valid_402658295, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658295 != nil:
    section.add "Version", valid_402658295
  var valid_402658296 = query.getOrDefault("SubscriptionName")
  valid_402658296 = validateParameter(valid_402658296, JString, required = true,
                                      default = nil)
  if valid_402658296 != nil:
    section.add "SubscriptionName", valid_402658296
  var valid_402658297 = query.getOrDefault("Action")
  valid_402658297 = validateParameter(valid_402658297, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658297 != nil:
    section.add "Action", valid_402658297
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
  var valid_402658298 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658298 = validateParameter(valid_402658298, JString,
                                      required = false, default = nil)
  if valid_402658298 != nil:
    section.add "X-Amz-Security-Token", valid_402658298
  var valid_402658299 = header.getOrDefault("X-Amz-Signature")
  valid_402658299 = validateParameter(valid_402658299, JString,
                                      required = false, default = nil)
  if valid_402658299 != nil:
    section.add "X-Amz-Signature", valid_402658299
  var valid_402658300 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658300 = validateParameter(valid_402658300, JString,
                                      required = false, default = nil)
  if valid_402658300 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658300
  var valid_402658301 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658301 = validateParameter(valid_402658301, JString,
                                      required = false, default = nil)
  if valid_402658301 != nil:
    section.add "X-Amz-Algorithm", valid_402658301
  var valid_402658302 = header.getOrDefault("X-Amz-Date")
  valid_402658302 = validateParameter(valid_402658302, JString,
                                      required = false, default = nil)
  if valid_402658302 != nil:
    section.add "X-Amz-Date", valid_402658302
  var valid_402658303 = header.getOrDefault("X-Amz-Credential")
  valid_402658303 = validateParameter(valid_402658303, JString,
                                      required = false, default = nil)
  if valid_402658303 != nil:
    section.add "X-Amz-Credential", valid_402658303
  var valid_402658304 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658304 = validateParameter(valid_402658304, JString,
                                      required = false, default = nil)
  if valid_402658304 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658304
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658305: Call_GetRemoveSourceIdentifierFromSubscription_402658291;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658305.validator(path, query, header, formData, body, _)
  let scheme = call_402658305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658305.makeUrl(scheme.get, call_402658305.host, call_402658305.base,
                                   call_402658305.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658305, uri, valid, _)

proc call*(call_402658306: Call_GetRemoveSourceIdentifierFromSubscription_402658291;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-02-12";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402658307 = newJObject()
  add(query_402658307, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402658307, "Version", newJString(Version))
  add(query_402658307, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658307, "Action", newJString(Action))
  result = call_402658306.call(nil, query_402658307, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_402658291(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_402658292,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_402658293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_402658343 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveTagsFromResource_402658345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_402658344(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658346 = query.getOrDefault("Version")
  valid_402658346 = validateParameter(valid_402658346, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658346 != nil:
    section.add "Version", valid_402658346
  var valid_402658347 = query.getOrDefault("Action")
  valid_402658347 = validateParameter(valid_402658347, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658347 != nil:
    section.add "Action", valid_402658347
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
  var valid_402658348 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658348 = validateParameter(valid_402658348, JString,
                                      required = false, default = nil)
  if valid_402658348 != nil:
    section.add "X-Amz-Security-Token", valid_402658348
  var valid_402658349 = header.getOrDefault("X-Amz-Signature")
  valid_402658349 = validateParameter(valid_402658349, JString,
                                      required = false, default = nil)
  if valid_402658349 != nil:
    section.add "X-Amz-Signature", valid_402658349
  var valid_402658350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658350 = validateParameter(valid_402658350, JString,
                                      required = false, default = nil)
  if valid_402658350 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658350
  var valid_402658351 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658351 = validateParameter(valid_402658351, JString,
                                      required = false, default = nil)
  if valid_402658351 != nil:
    section.add "X-Amz-Algorithm", valid_402658351
  var valid_402658352 = header.getOrDefault("X-Amz-Date")
  valid_402658352 = validateParameter(valid_402658352, JString,
                                      required = false, default = nil)
  if valid_402658352 != nil:
    section.add "X-Amz-Date", valid_402658352
  var valid_402658353 = header.getOrDefault("X-Amz-Credential")
  valid_402658353 = validateParameter(valid_402658353, JString,
                                      required = false, default = nil)
  if valid_402658353 != nil:
    section.add "X-Amz-Credential", valid_402658353
  var valid_402658354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658354 = validateParameter(valid_402658354, JString,
                                      required = false, default = nil)
  if valid_402658354 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658354
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
         "formData argument is necessary due to required `TagKeys` field"
  var valid_402658355 = formData.getOrDefault("TagKeys")
  valid_402658355 = validateParameter(valid_402658355, JArray, required = true,
                                      default = nil)
  if valid_402658355 != nil:
    section.add "TagKeys", valid_402658355
  var valid_402658356 = formData.getOrDefault("ResourceName")
  valid_402658356 = validateParameter(valid_402658356, JString, required = true,
                                      default = nil)
  if valid_402658356 != nil:
    section.add "ResourceName", valid_402658356
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658357: Call_PostRemoveTagsFromResource_402658343;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658357.validator(path, query, header, formData, body, _)
  let scheme = call_402658357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658357.makeUrl(scheme.get, call_402658357.host, call_402658357.base,
                                   call_402658357.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658357, uri, valid, _)

proc call*(call_402658358: Call_PostRemoveTagsFromResource_402658343;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2013-02-12";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## postRemoveTagsFromResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  var query_402658359 = newJObject()
  var formData_402658360 = newJObject()
  add(query_402658359, "Version", newJString(Version))
  add(query_402658359, "Action", newJString(Action))
  if TagKeys != nil:
    formData_402658360.add "TagKeys", TagKeys
  add(formData_402658360, "ResourceName", newJString(ResourceName))
  result = call_402658358.call(nil, query_402658359, nil, formData_402658360,
                               nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_402658343(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_402658344, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_402658345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_402658326 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveTagsFromResource_402658328(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_402658327(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TagKeys: JArray (required)
  ##   Version: JString (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `TagKeys` field"
  var valid_402658329 = query.getOrDefault("TagKeys")
  valid_402658329 = validateParameter(valid_402658329, JArray, required = true,
                                      default = nil)
  if valid_402658329 != nil:
    section.add "TagKeys", valid_402658329
  var valid_402658330 = query.getOrDefault("Version")
  valid_402658330 = validateParameter(valid_402658330, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658330 != nil:
    section.add "Version", valid_402658330
  var valid_402658331 = query.getOrDefault("ResourceName")
  valid_402658331 = validateParameter(valid_402658331, JString, required = true,
                                      default = nil)
  if valid_402658331 != nil:
    section.add "ResourceName", valid_402658331
  var valid_402658332 = query.getOrDefault("Action")
  valid_402658332 = validateParameter(valid_402658332, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658332 != nil:
    section.add "Action", valid_402658332
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
  var valid_402658333 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658333 = validateParameter(valid_402658333, JString,
                                      required = false, default = nil)
  if valid_402658333 != nil:
    section.add "X-Amz-Security-Token", valid_402658333
  var valid_402658334 = header.getOrDefault("X-Amz-Signature")
  valid_402658334 = validateParameter(valid_402658334, JString,
                                      required = false, default = nil)
  if valid_402658334 != nil:
    section.add "X-Amz-Signature", valid_402658334
  var valid_402658335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658335 = validateParameter(valid_402658335, JString,
                                      required = false, default = nil)
  if valid_402658335 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658335
  var valid_402658336 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658336 = validateParameter(valid_402658336, JString,
                                      required = false, default = nil)
  if valid_402658336 != nil:
    section.add "X-Amz-Algorithm", valid_402658336
  var valid_402658337 = header.getOrDefault("X-Amz-Date")
  valid_402658337 = validateParameter(valid_402658337, JString,
                                      required = false, default = nil)
  if valid_402658337 != nil:
    section.add "X-Amz-Date", valid_402658337
  var valid_402658338 = header.getOrDefault("X-Amz-Credential")
  valid_402658338 = validateParameter(valid_402658338, JString,
                                      required = false, default = nil)
  if valid_402658338 != nil:
    section.add "X-Amz-Credential", valid_402658338
  var valid_402658339 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658339 = validateParameter(valid_402658339, JString,
                                      required = false, default = nil)
  if valid_402658339 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658340: Call_GetRemoveTagsFromResource_402658326;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658340.validator(path, query, header, formData, body, _)
  let scheme = call_402658340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658340.makeUrl(scheme.get, call_402658340.host, call_402658340.base,
                                   call_402658340.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658340, uri, valid, _)

proc call*(call_402658341: Call_GetRemoveTagsFromResource_402658326;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2013-02-12";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## getRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402658342 = newJObject()
  if TagKeys != nil:
    query_402658342.add "TagKeys", TagKeys
  add(query_402658342, "Version", newJString(Version))
  add(query_402658342, "ResourceName", newJString(ResourceName))
  add(query_402658342, "Action", newJString(Action))
  result = call_402658341.call(nil, query_402658342, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_402658326(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_402658327, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_402658328,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_402658379 = ref object of OpenApiRestCall_402656035
proc url_PostResetDBParameterGroup_402658381(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_402658380(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658382 = query.getOrDefault("Version")
  valid_402658382 = validateParameter(valid_402658382, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658382 != nil:
    section.add "Version", valid_402658382
  var valid_402658383 = query.getOrDefault("Action")
  valid_402658383 = validateParameter(valid_402658383, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658383 != nil:
    section.add "Action", valid_402658383
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
  var valid_402658384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658384 = validateParameter(valid_402658384, JString,
                                      required = false, default = nil)
  if valid_402658384 != nil:
    section.add "X-Amz-Security-Token", valid_402658384
  var valid_402658385 = header.getOrDefault("X-Amz-Signature")
  valid_402658385 = validateParameter(valid_402658385, JString,
                                      required = false, default = nil)
  if valid_402658385 != nil:
    section.add "X-Amz-Signature", valid_402658385
  var valid_402658386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658386 = validateParameter(valid_402658386, JString,
                                      required = false, default = nil)
  if valid_402658386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658386
  var valid_402658387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658387 = validateParameter(valid_402658387, JString,
                                      required = false, default = nil)
  if valid_402658387 != nil:
    section.add "X-Amz-Algorithm", valid_402658387
  var valid_402658388 = header.getOrDefault("X-Amz-Date")
  valid_402658388 = validateParameter(valid_402658388, JString,
                                      required = false, default = nil)
  if valid_402658388 != nil:
    section.add "X-Amz-Date", valid_402658388
  var valid_402658389 = header.getOrDefault("X-Amz-Credential")
  valid_402658389 = validateParameter(valid_402658389, JString,
                                      required = false, default = nil)
  if valid_402658389 != nil:
    section.add "X-Amz-Credential", valid_402658389
  var valid_402658390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658390 = validateParameter(valid_402658390, JString,
                                      required = false, default = nil)
  if valid_402658390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658390
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658391 = formData.getOrDefault("DBParameterGroupName")
  valid_402658391 = validateParameter(valid_402658391, JString, required = true,
                                      default = nil)
  if valid_402658391 != nil:
    section.add "DBParameterGroupName", valid_402658391
  var valid_402658392 = formData.getOrDefault("Parameters")
  valid_402658392 = validateParameter(valid_402658392, JArray, required = false,
                                      default = nil)
  if valid_402658392 != nil:
    section.add "Parameters", valid_402658392
  var valid_402658393 = formData.getOrDefault("ResetAllParameters")
  valid_402658393 = validateParameter(valid_402658393, JBool, required = false,
                                      default = nil)
  if valid_402658393 != nil:
    section.add "ResetAllParameters", valid_402658393
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658394: Call_PostResetDBParameterGroup_402658379;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658394.validator(path, query, header, formData, body, _)
  let scheme = call_402658394.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658394.makeUrl(scheme.get, call_402658394.host, call_402658394.base,
                                   call_402658394.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658394, uri, valid, _)

proc call*(call_402658395: Call_PostResetDBParameterGroup_402658379;
           DBParameterGroupName: string; Version: string = "2013-02-12";
           Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
           ResetAllParameters: bool = false): Recallable =
  ## postResetDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  var query_402658396 = newJObject()
  var formData_402658397 = newJObject()
  add(query_402658396, "Version", newJString(Version))
  add(formData_402658397, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658396, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658397.add "Parameters", Parameters
  add(formData_402658397, "ResetAllParameters", newJBool(ResetAllParameters))
  result = call_402658395.call(nil, query_402658396, nil, formData_402658397,
                               nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_402658379(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_402658380, base: "/",
    makeUrl: url_PostResetDBParameterGroup_402658381,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_402658361 = ref object of OpenApiRestCall_402656035
proc url_GetResetDBParameterGroup_402658363(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_402658362(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Parameters: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Version: JString (required)
  ##   ResetAllParameters: JBool
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658364 = query.getOrDefault("Parameters")
  valid_402658364 = validateParameter(valid_402658364, JArray, required = false,
                                      default = nil)
  if valid_402658364 != nil:
    section.add "Parameters", valid_402658364
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658365 = query.getOrDefault("DBParameterGroupName")
  valid_402658365 = validateParameter(valid_402658365, JString, required = true,
                                      default = nil)
  if valid_402658365 != nil:
    section.add "DBParameterGroupName", valid_402658365
  var valid_402658366 = query.getOrDefault("Version")
  valid_402658366 = validateParameter(valid_402658366, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658366 != nil:
    section.add "Version", valid_402658366
  var valid_402658367 = query.getOrDefault("ResetAllParameters")
  valid_402658367 = validateParameter(valid_402658367, JBool, required = false,
                                      default = nil)
  if valid_402658367 != nil:
    section.add "ResetAllParameters", valid_402658367
  var valid_402658368 = query.getOrDefault("Action")
  valid_402658368 = validateParameter(valid_402658368, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658368 != nil:
    section.add "Action", valid_402658368
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
  var valid_402658369 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658369 = validateParameter(valid_402658369, JString,
                                      required = false, default = nil)
  if valid_402658369 != nil:
    section.add "X-Amz-Security-Token", valid_402658369
  var valid_402658370 = header.getOrDefault("X-Amz-Signature")
  valid_402658370 = validateParameter(valid_402658370, JString,
                                      required = false, default = nil)
  if valid_402658370 != nil:
    section.add "X-Amz-Signature", valid_402658370
  var valid_402658371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658371 = validateParameter(valid_402658371, JString,
                                      required = false, default = nil)
  if valid_402658371 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658371
  var valid_402658372 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658372 = validateParameter(valid_402658372, JString,
                                      required = false, default = nil)
  if valid_402658372 != nil:
    section.add "X-Amz-Algorithm", valid_402658372
  var valid_402658373 = header.getOrDefault("X-Amz-Date")
  valid_402658373 = validateParameter(valid_402658373, JString,
                                      required = false, default = nil)
  if valid_402658373 != nil:
    section.add "X-Amz-Date", valid_402658373
  var valid_402658374 = header.getOrDefault("X-Amz-Credential")
  valid_402658374 = validateParameter(valid_402658374, JString,
                                      required = false, default = nil)
  if valid_402658374 != nil:
    section.add "X-Amz-Credential", valid_402658374
  var valid_402658375 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658375 = validateParameter(valid_402658375, JString,
                                      required = false, default = nil)
  if valid_402658375 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658375
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658376: Call_GetResetDBParameterGroup_402658361;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658376.validator(path, query, header, formData, body, _)
  let scheme = call_402658376.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658376.makeUrl(scheme.get, call_402658376.host, call_402658376.base,
                                   call_402658376.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658376, uri, valid, _)

proc call*(call_402658377: Call_GetResetDBParameterGroup_402658361;
           DBParameterGroupName: string; Parameters: JsonNode = nil;
           Version: string = "2013-02-12"; ResetAllParameters: bool = false;
           Action: string = "ResetDBParameterGroup"): Recallable =
  ## getResetDBParameterGroup
  ##   Parameters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  var query_402658378 = newJObject()
  if Parameters != nil:
    query_402658378.add "Parameters", Parameters
  add(query_402658378, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658378, "Version", newJString(Version))
  add(query_402658378, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_402658378, "Action", newJString(Action))
  result = call_402658377.call(nil, query_402658378, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_402658361(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_402658362, base: "/",
    makeUrl: url_GetResetDBParameterGroup_402658363,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_402658427 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceFromDBSnapshot_402658429(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_402658428(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658430 = query.getOrDefault("Version")
  valid_402658430 = validateParameter(valid_402658430, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658430 != nil:
    section.add "Version", valid_402658430
  var valid_402658431 = query.getOrDefault("Action")
  valid_402658431 = validateParameter(valid_402658431, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658431 != nil:
    section.add "Action", valid_402658431
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
  var valid_402658432 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658432 = validateParameter(valid_402658432, JString,
                                      required = false, default = nil)
  if valid_402658432 != nil:
    section.add "X-Amz-Security-Token", valid_402658432
  var valid_402658433 = header.getOrDefault("X-Amz-Signature")
  valid_402658433 = validateParameter(valid_402658433, JString,
                                      required = false, default = nil)
  if valid_402658433 != nil:
    section.add "X-Amz-Signature", valid_402658433
  var valid_402658434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658434 = validateParameter(valid_402658434, JString,
                                      required = false, default = nil)
  if valid_402658434 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658434
  var valid_402658435 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658435 = validateParameter(valid_402658435, JString,
                                      required = false, default = nil)
  if valid_402658435 != nil:
    section.add "X-Amz-Algorithm", valid_402658435
  var valid_402658436 = header.getOrDefault("X-Amz-Date")
  valid_402658436 = validateParameter(valid_402658436, JString,
                                      required = false, default = nil)
  if valid_402658436 != nil:
    section.add "X-Amz-Date", valid_402658436
  var valid_402658437 = header.getOrDefault("X-Amz-Credential")
  valid_402658437 = validateParameter(valid_402658437, JString,
                                      required = false, default = nil)
  if valid_402658437 != nil:
    section.add "X-Amz-Credential", valid_402658437
  var valid_402658438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658438 = validateParameter(valid_402658438, JString,
                                      required = false, default = nil)
  if valid_402658438 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658438
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   DBName: JString
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_402658439 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658439 = validateParameter(valid_402658439, JBool, required = false,
                                      default = nil)
  if valid_402658439 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658439
  var valid_402658440 = formData.getOrDefault("Port")
  valid_402658440 = validateParameter(valid_402658440, JInt, required = false,
                                      default = nil)
  if valid_402658440 != nil:
    section.add "Port", valid_402658440
  var valid_402658441 = formData.getOrDefault("Engine")
  valid_402658441 = validateParameter(valid_402658441, JString,
                                      required = false, default = nil)
  if valid_402658441 != nil:
    section.add "Engine", valid_402658441
  var valid_402658442 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658442 = validateParameter(valid_402658442, JString,
                                      required = false, default = nil)
  if valid_402658442 != nil:
    section.add "DBSubnetGroupName", valid_402658442
  var valid_402658443 = formData.getOrDefault("PubliclyAccessible")
  valid_402658443 = validateParameter(valid_402658443, JBool, required = false,
                                      default = nil)
  if valid_402658443 != nil:
    section.add "PubliclyAccessible", valid_402658443
  var valid_402658444 = formData.getOrDefault("AvailabilityZone")
  valid_402658444 = validateParameter(valid_402658444, JString,
                                      required = false, default = nil)
  if valid_402658444 != nil:
    section.add "AvailabilityZone", valid_402658444
  var valid_402658445 = formData.getOrDefault("DBName")
  valid_402658445 = validateParameter(valid_402658445, JString,
                                      required = false, default = nil)
  if valid_402658445 != nil:
    section.add "DBName", valid_402658445
  var valid_402658446 = formData.getOrDefault("Iops")
  valid_402658446 = validateParameter(valid_402658446, JInt, required = false,
                                      default = nil)
  if valid_402658446 != nil:
    section.add "Iops", valid_402658446
  var valid_402658447 = formData.getOrDefault("DBInstanceClass")
  valid_402658447 = validateParameter(valid_402658447, JString,
                                      required = false, default = nil)
  if valid_402658447 != nil:
    section.add "DBInstanceClass", valid_402658447
  var valid_402658448 = formData.getOrDefault("LicenseModel")
  valid_402658448 = validateParameter(valid_402658448, JString,
                                      required = false, default = nil)
  if valid_402658448 != nil:
    section.add "LicenseModel", valid_402658448
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658449 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658449 = validateParameter(valid_402658449, JString, required = true,
                                      default = nil)
  if valid_402658449 != nil:
    section.add "DBInstanceIdentifier", valid_402658449
  var valid_402658450 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402658450 = validateParameter(valid_402658450, JString, required = true,
                                      default = nil)
  if valid_402658450 != nil:
    section.add "DBSnapshotIdentifier", valid_402658450
  var valid_402658451 = formData.getOrDefault("MultiAZ")
  valid_402658451 = validateParameter(valid_402658451, JBool, required = false,
                                      default = nil)
  if valid_402658451 != nil:
    section.add "MultiAZ", valid_402658451
  var valid_402658452 = formData.getOrDefault("OptionGroupName")
  valid_402658452 = validateParameter(valid_402658452, JString,
                                      required = false, default = nil)
  if valid_402658452 != nil:
    section.add "OptionGroupName", valid_402658452
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658453: Call_PostRestoreDBInstanceFromDBSnapshot_402658427;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658453.validator(path, query, header, formData, body, _)
  let scheme = call_402658453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658453.makeUrl(scheme.get, call_402658453.host, call_402658453.base,
                                   call_402658453.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658453, uri, valid, _)

proc call*(call_402658454: Call_PostRestoreDBInstanceFromDBSnapshot_402658427;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           Engine: string = ""; DBSubnetGroupName: string = "";
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           DBName: string = ""; Version: string = "2013-02-12"; Iops: int = 0;
           DBInstanceClass: string = ""; LicenseModel: string = "";
           MultiAZ: bool = false; OptionGroupName: string = "";
           Action: string = "RestoreDBInstanceFromDBSnapshot"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Engine: string
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AvailabilityZone: string
  ##   DBName: string
  ##   Version: string (required)
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   MultiAZ: bool
  ##   OptionGroupName: string
  ##   Action: string (required)
  var query_402658455 = newJObject()
  var formData_402658456 = newJObject()
  add(formData_402658456, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658456, "Port", newJInt(Port))
  add(formData_402658456, "Engine", newJString(Engine))
  add(formData_402658456, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658456, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658456, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658456, "DBName", newJString(DBName))
  add(query_402658455, "Version", newJString(Version))
  add(formData_402658456, "Iops", newJInt(Iops))
  add(formData_402658456, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658456, "LicenseModel", newJString(LicenseModel))
  add(formData_402658456, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658456, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402658456, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658456, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658455, "Action", newJString(Action))
  result = call_402658454.call(nil, query_402658455, nil, formData_402658456,
                               nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_402658427(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_402658428,
    base: "/", makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_402658429,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_402658398 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceFromDBSnapshot_402658400(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_402658399(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSubnetGroupName: JString
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Engine: JString
  ##   Port: JInt
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402658401 = query.getOrDefault("PubliclyAccessible")
  valid_402658401 = validateParameter(valid_402658401, JBool, required = false,
                                      default = nil)
  if valid_402658401 != nil:
    section.add "PubliclyAccessible", valid_402658401
  var valid_402658402 = query.getOrDefault("OptionGroupName")
  valid_402658402 = validateParameter(valid_402658402, JString,
                                      required = false, default = nil)
  if valid_402658402 != nil:
    section.add "OptionGroupName", valid_402658402
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658403 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658403 = validateParameter(valid_402658403, JString, required = true,
                                      default = nil)
  if valid_402658403 != nil:
    section.add "DBInstanceIdentifier", valid_402658403
  var valid_402658404 = query.getOrDefault("DBSubnetGroupName")
  valid_402658404 = validateParameter(valid_402658404, JString,
                                      required = false, default = nil)
  if valid_402658404 != nil:
    section.add "DBSubnetGroupName", valid_402658404
  var valid_402658405 = query.getOrDefault("Iops")
  valid_402658405 = validateParameter(valid_402658405, JInt, required = false,
                                      default = nil)
  if valid_402658405 != nil:
    section.add "Iops", valid_402658405
  var valid_402658406 = query.getOrDefault("AvailabilityZone")
  valid_402658406 = validateParameter(valid_402658406, JString,
                                      required = false, default = nil)
  if valid_402658406 != nil:
    section.add "AvailabilityZone", valid_402658406
  var valid_402658407 = query.getOrDefault("MultiAZ")
  valid_402658407 = validateParameter(valid_402658407, JBool, required = false,
                                      default = nil)
  if valid_402658407 != nil:
    section.add "MultiAZ", valid_402658407
  var valid_402658408 = query.getOrDefault("Version")
  valid_402658408 = validateParameter(valid_402658408, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658408 != nil:
    section.add "Version", valid_402658408
  var valid_402658409 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658409 = validateParameter(valid_402658409, JBool, required = false,
                                      default = nil)
  if valid_402658409 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658409
  var valid_402658410 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402658410 = validateParameter(valid_402658410, JString, required = true,
                                      default = nil)
  if valid_402658410 != nil:
    section.add "DBSnapshotIdentifier", valid_402658410
  var valid_402658411 = query.getOrDefault("DBName")
  valid_402658411 = validateParameter(valid_402658411, JString,
                                      required = false, default = nil)
  if valid_402658411 != nil:
    section.add "DBName", valid_402658411
  var valid_402658412 = query.getOrDefault("DBInstanceClass")
  valid_402658412 = validateParameter(valid_402658412, JString,
                                      required = false, default = nil)
  if valid_402658412 != nil:
    section.add "DBInstanceClass", valid_402658412
  var valid_402658413 = query.getOrDefault("Engine")
  valid_402658413 = validateParameter(valid_402658413, JString,
                                      required = false, default = nil)
  if valid_402658413 != nil:
    section.add "Engine", valid_402658413
  var valid_402658414 = query.getOrDefault("Port")
  valid_402658414 = validateParameter(valid_402658414, JInt, required = false,
                                      default = nil)
  if valid_402658414 != nil:
    section.add "Port", valid_402658414
  var valid_402658415 = query.getOrDefault("Action")
  valid_402658415 = validateParameter(valid_402658415, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658415 != nil:
    section.add "Action", valid_402658415
  var valid_402658416 = query.getOrDefault("LicenseModel")
  valid_402658416 = validateParameter(valid_402658416, JString,
                                      required = false, default = nil)
  if valid_402658416 != nil:
    section.add "LicenseModel", valid_402658416
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
  var valid_402658417 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658417 = validateParameter(valid_402658417, JString,
                                      required = false, default = nil)
  if valid_402658417 != nil:
    section.add "X-Amz-Security-Token", valid_402658417
  var valid_402658418 = header.getOrDefault("X-Amz-Signature")
  valid_402658418 = validateParameter(valid_402658418, JString,
                                      required = false, default = nil)
  if valid_402658418 != nil:
    section.add "X-Amz-Signature", valid_402658418
  var valid_402658419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658419 = validateParameter(valid_402658419, JString,
                                      required = false, default = nil)
  if valid_402658419 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658419
  var valid_402658420 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658420 = validateParameter(valid_402658420, JString,
                                      required = false, default = nil)
  if valid_402658420 != nil:
    section.add "X-Amz-Algorithm", valid_402658420
  var valid_402658421 = header.getOrDefault("X-Amz-Date")
  valid_402658421 = validateParameter(valid_402658421, JString,
                                      required = false, default = nil)
  if valid_402658421 != nil:
    section.add "X-Amz-Date", valid_402658421
  var valid_402658422 = header.getOrDefault("X-Amz-Credential")
  valid_402658422 = validateParameter(valid_402658422, JString,
                                      required = false, default = nil)
  if valid_402658422 != nil:
    section.add "X-Amz-Credential", valid_402658422
  var valid_402658423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658423 = validateParameter(valid_402658423, JString,
                                      required = false, default = nil)
  if valid_402658423 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658424: Call_GetRestoreDBInstanceFromDBSnapshot_402658398;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658424.validator(path, query, header, formData, body, _)
  let scheme = call_402658424.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658424.makeUrl(scheme.get, call_402658424.host, call_402658424.base,
                                   call_402658424.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658424, uri, valid, _)

proc call*(call_402658425: Call_GetRestoreDBInstanceFromDBSnapshot_402658398;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           DBSubnetGroupName: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; MultiAZ: bool = false;
           Version: string = "2013-02-12";
           AutoMinorVersionUpgrade: bool = false; DBName: string = "";
           DBInstanceClass: string = ""; Engine: string = ""; Port: int = 0;
           Action: string = "RestoreDBInstanceFromDBSnapshot";
           LicenseModel: string = ""): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Engine: string
  ##   Port: int
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402658426 = newJObject()
  add(query_402658426, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658426, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658426, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658426, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658426, "Iops", newJInt(Iops))
  add(query_402658426, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658426, "MultiAZ", newJBool(MultiAZ))
  add(query_402658426, "Version", newJString(Version))
  add(query_402658426, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658426, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402658426, "DBName", newJString(DBName))
  add(query_402658426, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658426, "Engine", newJString(Engine))
  add(query_402658426, "Port", newJInt(Port))
  add(query_402658426, "Action", newJString(Action))
  add(query_402658426, "LicenseModel", newJString(LicenseModel))
  result = call_402658425.call(nil, query_402658426, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_402658398(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_402658399, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_402658400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_402658488 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceToPointInTime_402658490(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_402658489(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658491 = query.getOrDefault("Version")
  valid_402658491 = validateParameter(valid_402658491, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658491 != nil:
    section.add "Version", valid_402658491
  var valid_402658492 = query.getOrDefault("Action")
  valid_402658492 = validateParameter(valid_402658492, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658492 != nil:
    section.add "Action", valid_402658492
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
  var valid_402658493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658493 = validateParameter(valid_402658493, JString,
                                      required = false, default = nil)
  if valid_402658493 != nil:
    section.add "X-Amz-Security-Token", valid_402658493
  var valid_402658494 = header.getOrDefault("X-Amz-Signature")
  valid_402658494 = validateParameter(valid_402658494, JString,
                                      required = false, default = nil)
  if valid_402658494 != nil:
    section.add "X-Amz-Signature", valid_402658494
  var valid_402658495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658495 = validateParameter(valid_402658495, JString,
                                      required = false, default = nil)
  if valid_402658495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658495
  var valid_402658496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658496 = validateParameter(valid_402658496, JString,
                                      required = false, default = nil)
  if valid_402658496 != nil:
    section.add "X-Amz-Algorithm", valid_402658496
  var valid_402658497 = header.getOrDefault("X-Amz-Date")
  valid_402658497 = validateParameter(valid_402658497, JString,
                                      required = false, default = nil)
  if valid_402658497 != nil:
    section.add "X-Amz-Date", valid_402658497
  var valid_402658498 = header.getOrDefault("X-Amz-Credential")
  valid_402658498 = validateParameter(valid_402658498, JString,
                                      required = false, default = nil)
  if valid_402658498 != nil:
    section.add "X-Amz-Credential", valid_402658498
  var valid_402658499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658499 = validateParameter(valid_402658499, JString,
                                      required = false, default = nil)
  if valid_402658499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658499
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   UseLatestRestorableTime: JBool
  ##   Engine: JString
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   DBName: JString
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   RestoreTime: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658500 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658500 = validateParameter(valid_402658500, JBool, required = false,
                                      default = nil)
  if valid_402658500 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658500
  var valid_402658501 = formData.getOrDefault("Port")
  valid_402658501 = validateParameter(valid_402658501, JInt, required = false,
                                      default = nil)
  if valid_402658501 != nil:
    section.add "Port", valid_402658501
  var valid_402658502 = formData.getOrDefault("UseLatestRestorableTime")
  valid_402658502 = validateParameter(valid_402658502, JBool, required = false,
                                      default = nil)
  if valid_402658502 != nil:
    section.add "UseLatestRestorableTime", valid_402658502
  var valid_402658503 = formData.getOrDefault("Engine")
  valid_402658503 = validateParameter(valid_402658503, JString,
                                      required = false, default = nil)
  if valid_402658503 != nil:
    section.add "Engine", valid_402658503
  var valid_402658504 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658504 = validateParameter(valid_402658504, JString,
                                      required = false, default = nil)
  if valid_402658504 != nil:
    section.add "DBSubnetGroupName", valid_402658504
  var valid_402658505 = formData.getOrDefault("PubliclyAccessible")
  valid_402658505 = validateParameter(valid_402658505, JBool, required = false,
                                      default = nil)
  if valid_402658505 != nil:
    section.add "PubliclyAccessible", valid_402658505
  var valid_402658506 = formData.getOrDefault("AvailabilityZone")
  valid_402658506 = validateParameter(valid_402658506, JString,
                                      required = false, default = nil)
  if valid_402658506 != nil:
    section.add "AvailabilityZone", valid_402658506
  var valid_402658507 = formData.getOrDefault("DBName")
  valid_402658507 = validateParameter(valid_402658507, JString,
                                      required = false, default = nil)
  if valid_402658507 != nil:
    section.add "DBName", valid_402658507
  var valid_402658508 = formData.getOrDefault("Iops")
  valid_402658508 = validateParameter(valid_402658508, JInt, required = false,
                                      default = nil)
  if valid_402658508 != nil:
    section.add "Iops", valid_402658508
  var valid_402658509 = formData.getOrDefault("DBInstanceClass")
  valid_402658509 = validateParameter(valid_402658509, JString,
                                      required = false, default = nil)
  if valid_402658509 != nil:
    section.add "DBInstanceClass", valid_402658509
  var valid_402658510 = formData.getOrDefault("LicenseModel")
  valid_402658510 = validateParameter(valid_402658510, JString,
                                      required = false, default = nil)
  if valid_402658510 != nil:
    section.add "LicenseModel", valid_402658510
  var valid_402658511 = formData.getOrDefault("MultiAZ")
  valid_402658511 = validateParameter(valid_402658511, JBool, required = false,
                                      default = nil)
  if valid_402658511 != nil:
    section.add "MultiAZ", valid_402658511
  var valid_402658512 = formData.getOrDefault("OptionGroupName")
  valid_402658512 = validateParameter(valid_402658512, JString,
                                      required = false, default = nil)
  if valid_402658512 != nil:
    section.add "OptionGroupName", valid_402658512
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_402658513 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658513 = validateParameter(valid_402658513, JString, required = true,
                                      default = nil)
  if valid_402658513 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658513
  var valid_402658514 = formData.getOrDefault("RestoreTime")
  valid_402658514 = validateParameter(valid_402658514, JString,
                                      required = false, default = nil)
  if valid_402658514 != nil:
    section.add "RestoreTime", valid_402658514
  var valid_402658515 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658515 = validateParameter(valid_402658515, JString, required = true,
                                      default = nil)
  if valid_402658515 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658515
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658516: Call_PostRestoreDBInstanceToPointInTime_402658488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658516.validator(path, query, header, formData, body, _)
  let scheme = call_402658516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658516.makeUrl(scheme.get, call_402658516.host, call_402658516.base,
                                   call_402658516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658516, uri, valid, _)

proc call*(call_402658517: Call_PostRestoreDBInstanceToPointInTime_402658488;
           TargetDBInstanceIdentifier: string;
           SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           UseLatestRestorableTime: bool = false; Engine: string = "";
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; DBName: string = "";
           Version: string = "2013-02-12"; Iops: int = 0;
           DBInstanceClass: string = ""; LicenseModel: string = "";
           MultiAZ: bool = false; OptionGroupName: string = "";
           Action: string = "RestoreDBInstanceToPointInTime";
           RestoreTime: string = ""): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   UseLatestRestorableTime: bool
  ##   Engine: string
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AvailabilityZone: string
  ##   DBName: string
  ##   Version: string (required)
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   MultiAZ: bool
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   TargetDBInstanceIdentifier: string (required)
  ##   RestoreTime: string
  ##   SourceDBInstanceIdentifier: string (required)
  var query_402658518 = newJObject()
  var formData_402658519 = newJObject()
  add(formData_402658519, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658519, "Port", newJInt(Port))
  add(formData_402658519, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_402658519, "Engine", newJString(Engine))
  add(formData_402658519, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658519, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658519, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658519, "DBName", newJString(DBName))
  add(query_402658518, "Version", newJString(Version))
  add(formData_402658519, "Iops", newJInt(Iops))
  add(formData_402658519, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658519, "LicenseModel", newJString(LicenseModel))
  add(formData_402658519, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658519, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658518, "Action", newJString(Action))
  add(formData_402658519, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_402658519, "RestoreTime", newJString(RestoreTime))
  add(formData_402658519, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402658517.call(nil, query_402658518, nil, formData_402658519,
                               nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_402658488(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_402658489, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_402658490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_402658457 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceToPointInTime_402658459(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_402658458(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  ##   DBSubnetGroupName: JString
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   RestoreTime: JString
  ##   Version: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  ##   UseLatestRestorableTime: JBool
  ##   DBName: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   Engine: JString
  ##   Port: JInt
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402658460 = query.getOrDefault("PubliclyAccessible")
  valid_402658460 = validateParameter(valid_402658460, JBool, required = false,
                                      default = nil)
  if valid_402658460 != nil:
    section.add "PubliclyAccessible", valid_402658460
  var valid_402658461 = query.getOrDefault("OptionGroupName")
  valid_402658461 = validateParameter(valid_402658461, JString,
                                      required = false, default = nil)
  if valid_402658461 != nil:
    section.add "OptionGroupName", valid_402658461
  var valid_402658462 = query.getOrDefault("DBSubnetGroupName")
  valid_402658462 = validateParameter(valid_402658462, JString,
                                      required = false, default = nil)
  if valid_402658462 != nil:
    section.add "DBSubnetGroupName", valid_402658462
  var valid_402658463 = query.getOrDefault("Iops")
  valid_402658463 = validateParameter(valid_402658463, JInt, required = false,
                                      default = nil)
  if valid_402658463 != nil:
    section.add "Iops", valid_402658463
  var valid_402658464 = query.getOrDefault("AvailabilityZone")
  valid_402658464 = validateParameter(valid_402658464, JString,
                                      required = false, default = nil)
  if valid_402658464 != nil:
    section.add "AvailabilityZone", valid_402658464
  var valid_402658465 = query.getOrDefault("MultiAZ")
  valid_402658465 = validateParameter(valid_402658465, JBool, required = false,
                                      default = nil)
  if valid_402658465 != nil:
    section.add "MultiAZ", valid_402658465
  var valid_402658466 = query.getOrDefault("RestoreTime")
  valid_402658466 = validateParameter(valid_402658466, JString,
                                      required = false, default = nil)
  if valid_402658466 != nil:
    section.add "RestoreTime", valid_402658466
  var valid_402658467 = query.getOrDefault("Version")
  valid_402658467 = validateParameter(valid_402658467, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658467 != nil:
    section.add "Version", valid_402658467
  var valid_402658468 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658468 = validateParameter(valid_402658468, JBool, required = false,
                                      default = nil)
  if valid_402658468 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658468
  var valid_402658469 = query.getOrDefault("UseLatestRestorableTime")
  valid_402658469 = validateParameter(valid_402658469, JBool, required = false,
                                      default = nil)
  if valid_402658469 != nil:
    section.add "UseLatestRestorableTime", valid_402658469
  var valid_402658470 = query.getOrDefault("DBName")
  valid_402658470 = validateParameter(valid_402658470, JString,
                                      required = false, default = nil)
  if valid_402658470 != nil:
    section.add "DBName", valid_402658470
  var valid_402658471 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658471 = validateParameter(valid_402658471, JString, required = true,
                                      default = nil)
  if valid_402658471 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658471
  var valid_402658472 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658472 = validateParameter(valid_402658472, JString, required = true,
                                      default = nil)
  if valid_402658472 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658472
  var valid_402658473 = query.getOrDefault("DBInstanceClass")
  valid_402658473 = validateParameter(valid_402658473, JString,
                                      required = false, default = nil)
  if valid_402658473 != nil:
    section.add "DBInstanceClass", valid_402658473
  var valid_402658474 = query.getOrDefault("Engine")
  valid_402658474 = validateParameter(valid_402658474, JString,
                                      required = false, default = nil)
  if valid_402658474 != nil:
    section.add "Engine", valid_402658474
  var valid_402658475 = query.getOrDefault("Port")
  valid_402658475 = validateParameter(valid_402658475, JInt, required = false,
                                      default = nil)
  if valid_402658475 != nil:
    section.add "Port", valid_402658475
  var valid_402658476 = query.getOrDefault("Action")
  valid_402658476 = validateParameter(valid_402658476, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658476 != nil:
    section.add "Action", valid_402658476
  var valid_402658477 = query.getOrDefault("LicenseModel")
  valid_402658477 = validateParameter(valid_402658477, JString,
                                      required = false, default = nil)
  if valid_402658477 != nil:
    section.add "LicenseModel", valid_402658477
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
  var valid_402658478 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658478 = validateParameter(valid_402658478, JString,
                                      required = false, default = nil)
  if valid_402658478 != nil:
    section.add "X-Amz-Security-Token", valid_402658478
  var valid_402658479 = header.getOrDefault("X-Amz-Signature")
  valid_402658479 = validateParameter(valid_402658479, JString,
                                      required = false, default = nil)
  if valid_402658479 != nil:
    section.add "X-Amz-Signature", valid_402658479
  var valid_402658480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658480 = validateParameter(valid_402658480, JString,
                                      required = false, default = nil)
  if valid_402658480 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658480
  var valid_402658481 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658481 = validateParameter(valid_402658481, JString,
                                      required = false, default = nil)
  if valid_402658481 != nil:
    section.add "X-Amz-Algorithm", valid_402658481
  var valid_402658482 = header.getOrDefault("X-Amz-Date")
  valid_402658482 = validateParameter(valid_402658482, JString,
                                      required = false, default = nil)
  if valid_402658482 != nil:
    section.add "X-Amz-Date", valid_402658482
  var valid_402658483 = header.getOrDefault("X-Amz-Credential")
  valid_402658483 = validateParameter(valid_402658483, JString,
                                      required = false, default = nil)
  if valid_402658483 != nil:
    section.add "X-Amz-Credential", valid_402658483
  var valid_402658484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658484 = validateParameter(valid_402658484, JString,
                                      required = false, default = nil)
  if valid_402658484 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658485: Call_GetRestoreDBInstanceToPointInTime_402658457;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658485.validator(path, query, header, formData, body, _)
  let scheme = call_402658485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658485.makeUrl(scheme.get, call_402658485.host, call_402658485.base,
                                   call_402658485.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658485, uri, valid, _)

proc call*(call_402658486: Call_GetRestoreDBInstanceToPointInTime_402658457;
           SourceDBInstanceIdentifier: string;
           TargetDBInstanceIdentifier: string; PubliclyAccessible: bool = false;
           OptionGroupName: string = ""; DBSubnetGroupName: string = "";
           Iops: int = 0; AvailabilityZone: string = ""; MultiAZ: bool = false;
           RestoreTime: string = ""; Version: string = "2013-02-12";
           AutoMinorVersionUpgrade: bool = false;
           UseLatestRestorableTime: bool = false; DBName: string = "";
           DBInstanceClass: string = ""; Engine: string = ""; Port: int = 0;
           Action: string = "RestoreDBInstanceToPointInTime";
           LicenseModel: string = ""): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBSubnetGroupName: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   RestoreTime: string
  ##   Version: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   UseLatestRestorableTime: bool
  ##   DBName: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   TargetDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   Engine: string
  ##   Port: int
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402658487 = newJObject()
  add(query_402658487, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658487, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658487, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658487, "Iops", newJInt(Iops))
  add(query_402658487, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658487, "MultiAZ", newJBool(MultiAZ))
  add(query_402658487, "RestoreTime", newJString(RestoreTime))
  add(query_402658487, "Version", newJString(Version))
  add(query_402658487, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658487, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(query_402658487, "DBName", newJString(DBName))
  add(query_402658487, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402658487, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_402658487, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658487, "Engine", newJString(Engine))
  add(query_402658487, "Port", newJInt(Port))
  add(query_402658487, "Action", newJString(Action))
  add(query_402658487, "LicenseModel", newJString(LicenseModel))
  result = call_402658486.call(nil, query_402658487, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_402658457(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_402658458, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_402658459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_402658540 = ref object of OpenApiRestCall_402656035
proc url_PostRevokeDBSecurityGroupIngress_402658542(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_402658541(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658543 = query.getOrDefault("Version")
  valid_402658543 = validateParameter(valid_402658543, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658543 != nil:
    section.add "Version", valid_402658543
  var valid_402658544 = query.getOrDefault("Action")
  valid_402658544 = validateParameter(valid_402658544, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658544 != nil:
    section.add "Action", valid_402658544
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
  var valid_402658545 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658545 = validateParameter(valid_402658545, JString,
                                      required = false, default = nil)
  if valid_402658545 != nil:
    section.add "X-Amz-Security-Token", valid_402658545
  var valid_402658546 = header.getOrDefault("X-Amz-Signature")
  valid_402658546 = validateParameter(valid_402658546, JString,
                                      required = false, default = nil)
  if valid_402658546 != nil:
    section.add "X-Amz-Signature", valid_402658546
  var valid_402658547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658547 = validateParameter(valid_402658547, JString,
                                      required = false, default = nil)
  if valid_402658547 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658547
  var valid_402658548 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658548 = validateParameter(valid_402658548, JString,
                                      required = false, default = nil)
  if valid_402658548 != nil:
    section.add "X-Amz-Algorithm", valid_402658548
  var valid_402658549 = header.getOrDefault("X-Amz-Date")
  valid_402658549 = validateParameter(valid_402658549, JString,
                                      required = false, default = nil)
  if valid_402658549 != nil:
    section.add "X-Amz-Date", valid_402658549
  var valid_402658550 = header.getOrDefault("X-Amz-Credential")
  valid_402658550 = validateParameter(valid_402658550, JString,
                                      required = false, default = nil)
  if valid_402658550 != nil:
    section.add "X-Amz-Credential", valid_402658550
  var valid_402658551 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658551 = validateParameter(valid_402658551, JString,
                                      required = false, default = nil)
  if valid_402658551 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658551
  result.add "header", section
  ## parameters in `formData` object:
  ##   EC2SecurityGroupName: JString
  ##   CIDRIP: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  section = newJObject()
  var valid_402658552 = formData.getOrDefault("EC2SecurityGroupName")
  valid_402658552 = validateParameter(valid_402658552, JString,
                                      required = false, default = nil)
  if valid_402658552 != nil:
    section.add "EC2SecurityGroupName", valid_402658552
  var valid_402658553 = formData.getOrDefault("CIDRIP")
  valid_402658553 = validateParameter(valid_402658553, JString,
                                      required = false, default = nil)
  if valid_402658553 != nil:
    section.add "CIDRIP", valid_402658553
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402658554 = formData.getOrDefault("DBSecurityGroupName")
  valid_402658554 = validateParameter(valid_402658554, JString, required = true,
                                      default = nil)
  if valid_402658554 != nil:
    section.add "DBSecurityGroupName", valid_402658554
  var valid_402658555 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658555 = validateParameter(valid_402658555, JString,
                                      required = false, default = nil)
  if valid_402658555 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658555
  var valid_402658556 = formData.getOrDefault("EC2SecurityGroupId")
  valid_402658556 = validateParameter(valid_402658556, JString,
                                      required = false, default = nil)
  if valid_402658556 != nil:
    section.add "EC2SecurityGroupId", valid_402658556
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658557: Call_PostRevokeDBSecurityGroupIngress_402658540;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658557.validator(path, query, header, formData, body, _)
  let scheme = call_402658557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658557.makeUrl(scheme.get, call_402658557.host, call_402658557.base,
                                   call_402658557.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658557, uri, valid, _)

proc call*(call_402658558: Call_PostRevokeDBSecurityGroupIngress_402658540;
           DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
           CIDRIP: string = ""; Version: string = "2013-02-12";
           EC2SecurityGroupOwnerId: string = "";
           Action: string = "RevokeDBSecurityGroupIngress";
           EC2SecurityGroupId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupName: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   EC2SecurityGroupOwnerId: string
  ##   Action: string (required)
  ##   EC2SecurityGroupId: string
  var query_402658559 = newJObject()
  var formData_402658560 = newJObject()
  add(formData_402658560, "EC2SecurityGroupName",
      newJString(EC2SecurityGroupName))
  add(formData_402658560, "CIDRIP", newJString(CIDRIP))
  add(query_402658559, "Version", newJString(Version))
  add(formData_402658560, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402658560, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658559, "Action", newJString(Action))
  add(formData_402658560, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  result = call_402658558.call(nil, query_402658559, nil, formData_402658560,
                               nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_402658540(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_402658541, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_402658542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_402658520 = ref object of OpenApiRestCall_402656035
proc url_GetRevokeDBSecurityGroupIngress_402658522(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_402658521(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  ##   Version: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString (required)
  ##   CIDRIP: JString
  section = newJObject()
  var valid_402658523 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658523 = validateParameter(valid_402658523, JString,
                                      required = false, default = nil)
  if valid_402658523 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658523
  var valid_402658524 = query.getOrDefault("EC2SecurityGroupId")
  valid_402658524 = validateParameter(valid_402658524, JString,
                                      required = false, default = nil)
  if valid_402658524 != nil:
    section.add "EC2SecurityGroupId", valid_402658524
  var valid_402658525 = query.getOrDefault("Version")
  valid_402658525 = validateParameter(valid_402658525, JString, required = true,
                                      default = newJString("2013-02-12"))
  if valid_402658525 != nil:
    section.add "Version", valid_402658525
  var valid_402658526 = query.getOrDefault("EC2SecurityGroupName")
  valid_402658526 = validateParameter(valid_402658526, JString,
                                      required = false, default = nil)
  if valid_402658526 != nil:
    section.add "EC2SecurityGroupName", valid_402658526
  var valid_402658527 = query.getOrDefault("Action")
  valid_402658527 = validateParameter(valid_402658527, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658527 != nil:
    section.add "Action", valid_402658527
  var valid_402658528 = query.getOrDefault("DBSecurityGroupName")
  valid_402658528 = validateParameter(valid_402658528, JString, required = true,
                                      default = nil)
  if valid_402658528 != nil:
    section.add "DBSecurityGroupName", valid_402658528
  var valid_402658529 = query.getOrDefault("CIDRIP")
  valid_402658529 = validateParameter(valid_402658529, JString,
                                      required = false, default = nil)
  if valid_402658529 != nil:
    section.add "CIDRIP", valid_402658529
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
  var valid_402658530 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658530 = validateParameter(valid_402658530, JString,
                                      required = false, default = nil)
  if valid_402658530 != nil:
    section.add "X-Amz-Security-Token", valid_402658530
  var valid_402658531 = header.getOrDefault("X-Amz-Signature")
  valid_402658531 = validateParameter(valid_402658531, JString,
                                      required = false, default = nil)
  if valid_402658531 != nil:
    section.add "X-Amz-Signature", valid_402658531
  var valid_402658532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658532 = validateParameter(valid_402658532, JString,
                                      required = false, default = nil)
  if valid_402658532 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658532
  var valid_402658533 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658533 = validateParameter(valid_402658533, JString,
                                      required = false, default = nil)
  if valid_402658533 != nil:
    section.add "X-Amz-Algorithm", valid_402658533
  var valid_402658534 = header.getOrDefault("X-Amz-Date")
  valid_402658534 = validateParameter(valid_402658534, JString,
                                      required = false, default = nil)
  if valid_402658534 != nil:
    section.add "X-Amz-Date", valid_402658534
  var valid_402658535 = header.getOrDefault("X-Amz-Credential")
  valid_402658535 = validateParameter(valid_402658535, JString,
                                      required = false, default = nil)
  if valid_402658535 != nil:
    section.add "X-Amz-Credential", valid_402658535
  var valid_402658536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658536 = validateParameter(valid_402658536, JString,
                                      required = false, default = nil)
  if valid_402658536 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658537: Call_GetRevokeDBSecurityGroupIngress_402658520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658537.validator(path, query, header, formData, body, _)
  let scheme = call_402658537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658537.makeUrl(scheme.get, call_402658537.host, call_402658537.base,
                                   call_402658537.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658537, uri, valid, _)

proc call*(call_402658538: Call_GetRevokeDBSecurityGroupIngress_402658520;
           DBSecurityGroupName: string; EC2SecurityGroupOwnerId: string = "";
           EC2SecurityGroupId: string = ""; Version: string = "2013-02-12";
           EC2SecurityGroupName: string = "";
           Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = ""): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupOwnerId: string
  ##   EC2SecurityGroupId: string
  ##   Version: string (required)
  ##   EC2SecurityGroupName: string
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   CIDRIP: string
  var query_402658539 = newJObject()
  add(query_402658539, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658539, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_402658539, "Version", newJString(Version))
  add(query_402658539, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_402658539, "Action", newJString(Action))
  add(query_402658539, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402658539, "CIDRIP", newJString(CIDRIP))
  result = call_402658538.call(nil, query_402658539, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_402658520(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_402658521, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_402658522,
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
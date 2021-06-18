
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2013-09-09
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
                                      default = newJString("2013-09-09"))
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
           Version: string = "2013-09-09";
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
                                      default = newJString("2013-09-09"))
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
           Version: string = "2013-09-09";
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
                                      default = newJString("2013-09-09"))
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
           ResourceName: string; Version: string = "2013-09-09";
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
                                      default = newJString("2013-09-09"))
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
           ResourceName: string; Version: string = "2013-09-09";
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
                                      default = newJString("2013-09-09"))
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
           CIDRIP: string = ""; Version: string = "2013-09-09";
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
                                      default = newJString("2013-09-09"))
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
           EC2SecurityGroupId: string = ""; Version: string = "2013-09-09";
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
  Call_PostCopyDBSnapshot_402656594 = ref object of OpenApiRestCall_402656035
proc url_PostCopyDBSnapshot_402656596(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_402656595(path: JsonNode; query: JsonNode;
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
  var valid_402656597 = query.getOrDefault("Version")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656597 != nil:
    section.add "Version", valid_402656597
  var valid_402656598 = query.getOrDefault("Action")
  valid_402656598 = validateParameter(valid_402656598, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656598 != nil:
    section.add "Action", valid_402656598
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
  var valid_402656599 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Security-Token", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Signature")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Signature", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Algorithm", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Date")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Date", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Credential")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Credential", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656605
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_402656606 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_402656606 = validateParameter(valid_402656606, JString, required = true,
                                      default = nil)
  if valid_402656606 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_402656606
  var valid_402656607 = formData.getOrDefault("Tags")
  valid_402656607 = validateParameter(valid_402656607, JArray, required = false,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "Tags", valid_402656607
  var valid_402656608 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_402656608
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656609: Call_PostCopyDBSnapshot_402656594;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656609.validator(path, query, header, formData, body, _)
  let scheme = call_402656609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656609.makeUrl(scheme.get, call_402656609.host, call_402656609.base,
                                   call_402656609.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656609, uri, valid, _)

proc call*(call_402656610: Call_PostCopyDBSnapshot_402656594;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Tags: JsonNode = nil;
           Version: string = "2013-09-09"; Action: string = "CopyDBSnapshot"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656611 = newJObject()
  var formData_402656612 = newJObject()
  add(formData_402656612, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    formData_402656612.add "Tags", Tags
  add(query_402656611, "Version", newJString(Version))
  add(formData_402656612, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656611, "Action", newJString(Action))
  result = call_402656610.call(nil, query_402656611, nil, formData_402656612,
                               nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_402656594(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_402656595, base: "/",
    makeUrl: url_PostCopyDBSnapshot_402656596,
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
  ##   Tags: JArray
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
                                      default = newJString("2013-09-09"))
  if valid_402656581 != nil:
    section.add "Version", valid_402656581
  var valid_402656582 = query.getOrDefault("Tags")
  valid_402656582 = validateParameter(valid_402656582, JArray, required = false,
                                      default = nil)
  if valid_402656582 != nil:
    section.add "Tags", valid_402656582
  var valid_402656583 = query.getOrDefault("Action")
  valid_402656583 = validateParameter(valid_402656583, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656583 != nil:
    section.add "Action", valid_402656583
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
  var valid_402656584 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Security-Token", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Signature")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Signature", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Algorithm", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Date")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Date", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Credential")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Credential", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_GetCopyDBSnapshot_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_GetCopyDBSnapshot_402656576;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Version: string = "2013-09-09";
           Tags: JsonNode = nil; Action: string = "CopyDBSnapshot"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  var query_402656593 = newJObject()
  add(query_402656593, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_402656593, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656593, "Version", newJString(Version))
  if Tags != nil:
    query_402656593.add "Tags", Tags
  add(query_402656593, "Action", newJString(Action))
  result = call_402656592.call(nil, query_402656593, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_402656576(
    name: "getCopyDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_GetCopyDBSnapshot_402656577, base: "/",
    makeUrl: url_GetCopyDBSnapshot_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_402656653 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstance_402656655(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_402656654(path: JsonNode; query: JsonNode;
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
  var valid_402656656 = query.getOrDefault("Version")
  valid_402656656 = validateParameter(valid_402656656, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656656 != nil:
    section.add "Version", valid_402656656
  var valid_402656657 = query.getOrDefault("Action")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656657 != nil:
    section.add "Action", valid_402656657
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
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
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
  ##   Tags: JArray
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
  var valid_402656665 = formData.getOrDefault("PreferredBackupWindow")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "PreferredBackupWindow", valid_402656665
  var valid_402656666 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656666 = validateParameter(valid_402656666, JBool, required = false,
                                      default = nil)
  if valid_402656666 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656666
  var valid_402656667 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402656667 = validateParameter(valid_402656667, JArray, required = false,
                                      default = nil)
  if valid_402656667 != nil:
    section.add "VpcSecurityGroupIds", valid_402656667
  var valid_402656668 = formData.getOrDefault("Port")
  valid_402656668 = validateParameter(valid_402656668, JInt, required = false,
                                      default = nil)
  if valid_402656668 != nil:
    section.add "Port", valid_402656668
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402656669 = formData.getOrDefault("Engine")
  valid_402656669 = validateParameter(valid_402656669, JString, required = true,
                                      default = nil)
  if valid_402656669 != nil:
    section.add "Engine", valid_402656669
  var valid_402656670 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656670 = validateParameter(valid_402656670, JString,
                                      required = false, default = nil)
  if valid_402656670 != nil:
    section.add "DBSubnetGroupName", valid_402656670
  var valid_402656671 = formData.getOrDefault("AllocatedStorage")
  valid_402656671 = validateParameter(valid_402656671, JInt, required = true,
                                      default = nil)
  if valid_402656671 != nil:
    section.add "AllocatedStorage", valid_402656671
  var valid_402656672 = formData.getOrDefault("PubliclyAccessible")
  valid_402656672 = validateParameter(valid_402656672, JBool, required = false,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "PubliclyAccessible", valid_402656672
  var valid_402656673 = formData.getOrDefault("AvailabilityZone")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "AvailabilityZone", valid_402656673
  var valid_402656674 = formData.getOrDefault("MasterUserPassword")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true,
                                      default = nil)
  if valid_402656674 != nil:
    section.add "MasterUserPassword", valid_402656674
  var valid_402656675 = formData.getOrDefault("CharacterSetName")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "CharacterSetName", valid_402656675
  var valid_402656676 = formData.getOrDefault("DBName")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "DBName", valid_402656676
  var valid_402656677 = formData.getOrDefault("Tags")
  valid_402656677 = validateParameter(valid_402656677, JArray, required = false,
                                      default = nil)
  if valid_402656677 != nil:
    section.add "Tags", valid_402656677
  var valid_402656678 = formData.getOrDefault("DBParameterGroupName")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "DBParameterGroupName", valid_402656678
  var valid_402656679 = formData.getOrDefault("Iops")
  valid_402656679 = validateParameter(valid_402656679, JInt, required = false,
                                      default = nil)
  if valid_402656679 != nil:
    section.add "Iops", valid_402656679
  var valid_402656680 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656680
  var valid_402656681 = formData.getOrDefault("DBInstanceClass")
  valid_402656681 = validateParameter(valid_402656681, JString, required = true,
                                      default = nil)
  if valid_402656681 != nil:
    section.add "DBInstanceClass", valid_402656681
  var valid_402656682 = formData.getOrDefault("LicenseModel")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "LicenseModel", valid_402656682
  var valid_402656683 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "DBInstanceIdentifier", valid_402656683
  var valid_402656684 = formData.getOrDefault("MasterUsername")
  valid_402656684 = validateParameter(valid_402656684, JString, required = true,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "MasterUsername", valid_402656684
  var valid_402656685 = formData.getOrDefault("MultiAZ")
  valid_402656685 = validateParameter(valid_402656685, JBool, required = false,
                                      default = nil)
  if valid_402656685 != nil:
    section.add "MultiAZ", valid_402656685
  var valid_402656686 = formData.getOrDefault("DBSecurityGroups")
  valid_402656686 = validateParameter(valid_402656686, JArray, required = false,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "DBSecurityGroups", valid_402656686
  var valid_402656687 = formData.getOrDefault("OptionGroupName")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "OptionGroupName", valid_402656687
  var valid_402656688 = formData.getOrDefault("EngineVersion")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "EngineVersion", valid_402656688
  var valid_402656689 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402656689 = validateParameter(valid_402656689, JInt, required = false,
                                      default = nil)
  if valid_402656689 != nil:
    section.add "BackupRetentionPeriod", valid_402656689
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656690: Call_PostCreateDBInstance_402656653;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656690.validator(path, query, header, formData, body, _)
  let scheme = call_402656690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656690.makeUrl(scheme.get, call_402656690.host, call_402656690.base,
                                   call_402656690.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656690, uri, valid, _)

proc call*(call_402656691: Call_PostCreateDBInstance_402656653; Engine: string;
           AllocatedStorage: int; MasterUserPassword: string;
           DBInstanceClass: string; DBInstanceIdentifier: string;
           MasterUsername: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; Port: int = 0;
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; CharacterSetName: string = "";
           DBName: string = ""; Tags: JsonNode = nil;
           Version: string = "2013-09-09"; DBParameterGroupName: string = "";
           Iops: int = 0; PreferredMaintenanceWindow: string = "";
           LicenseModel: string = ""; MultiAZ: bool = false;
           DBSecurityGroups: JsonNode = nil; OptionGroupName: string = "";
           Action: string = "CreateDBInstance"; EngineVersion: string = "";
           BackupRetentionPeriod: int = 0): Recallable =
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
  ##   Tags: JArray
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
  var query_402656692 = newJObject()
  var formData_402656693 = newJObject()
  add(formData_402656693, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402656693, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402656693.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402656693, "Port", newJInt(Port))
  add(formData_402656693, "Engine", newJString(Engine))
  add(formData_402656693, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402656693, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402656693, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656693, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402656693, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402656693, "CharacterSetName", newJString(CharacterSetName))
  add(formData_402656693, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402656693.add "Tags", Tags
  add(query_402656692, "Version", newJString(Version))
  add(formData_402656693, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402656693, "Iops", newJInt(Iops))
  add(formData_402656693, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402656693, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656693, "LicenseModel", newJString(LicenseModel))
  add(formData_402656693, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656693, "MasterUsername", newJString(MasterUsername))
  add(formData_402656693, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402656693.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402656693, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656692, "Action", newJString(Action))
  add(formData_402656693, "EngineVersion", newJString(EngineVersion))
  add(formData_402656693, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402656691.call(nil, query_402656692, nil, formData_402656693,
                               nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_402656653(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_402656654, base: "/",
    makeUrl: url_PostCreateDBInstance_402656655,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_402656613 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstance_402656615(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_402656614(path: JsonNode; query: JsonNode;
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
  ##   Tags: JArray
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
  var valid_402656616 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402656616 = validateParameter(valid_402656616, JArray, required = false,
                                      default = nil)
  if valid_402656616 != nil:
    section.add "VpcSecurityGroupIds", valid_402656616
  var valid_402656617 = query.getOrDefault("PubliclyAccessible")
  valid_402656617 = validateParameter(valid_402656617, JBool, required = false,
                                      default = nil)
  if valid_402656617 != nil:
    section.add "PubliclyAccessible", valid_402656617
  var valid_402656618 = query.getOrDefault("OptionGroupName")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "OptionGroupName", valid_402656618
  var valid_402656619 = query.getOrDefault("PreferredBackupWindow")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "PreferredBackupWindow", valid_402656619
  var valid_402656620 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656620
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656621 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656621 = validateParameter(valid_402656621, JString, required = true,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "DBInstanceIdentifier", valid_402656621
  var valid_402656622 = query.getOrDefault("DBSubnetGroupName")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "DBSubnetGroupName", valid_402656622
  var valid_402656623 = query.getOrDefault("DBParameterGroupName")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "DBParameterGroupName", valid_402656623
  var valid_402656624 = query.getOrDefault("MasterUserPassword")
  valid_402656624 = validateParameter(valid_402656624, JString, required = true,
                                      default = nil)
  if valid_402656624 != nil:
    section.add "MasterUserPassword", valid_402656624
  var valid_402656625 = query.getOrDefault("Iops")
  valid_402656625 = validateParameter(valid_402656625, JInt, required = false,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "Iops", valid_402656625
  var valid_402656626 = query.getOrDefault("AvailabilityZone")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "AvailabilityZone", valid_402656626
  var valid_402656627 = query.getOrDefault("MultiAZ")
  valid_402656627 = validateParameter(valid_402656627, JBool, required = false,
                                      default = nil)
  if valid_402656627 != nil:
    section.add "MultiAZ", valid_402656627
  var valid_402656628 = query.getOrDefault("Version")
  valid_402656628 = validateParameter(valid_402656628, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656628 != nil:
    section.add "Version", valid_402656628
  var valid_402656629 = query.getOrDefault("EngineVersion")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "EngineVersion", valid_402656629
  var valid_402656630 = query.getOrDefault("Tags")
  valid_402656630 = validateParameter(valid_402656630, JArray, required = false,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "Tags", valid_402656630
  var valid_402656631 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656631 = validateParameter(valid_402656631, JBool, required = false,
                                      default = nil)
  if valid_402656631 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656631
  var valid_402656632 = query.getOrDefault("DBName")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "DBName", valid_402656632
  var valid_402656633 = query.getOrDefault("AllocatedStorage")
  valid_402656633 = validateParameter(valid_402656633, JInt, required = true,
                                      default = nil)
  if valid_402656633 != nil:
    section.add "AllocatedStorage", valid_402656633
  var valid_402656634 = query.getOrDefault("MasterUsername")
  valid_402656634 = validateParameter(valid_402656634, JString, required = true,
                                      default = nil)
  if valid_402656634 != nil:
    section.add "MasterUsername", valid_402656634
  var valid_402656635 = query.getOrDefault("DBInstanceClass")
  valid_402656635 = validateParameter(valid_402656635, JString, required = true,
                                      default = nil)
  if valid_402656635 != nil:
    section.add "DBInstanceClass", valid_402656635
  var valid_402656636 = query.getOrDefault("Engine")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = nil)
  if valid_402656636 != nil:
    section.add "Engine", valid_402656636
  var valid_402656637 = query.getOrDefault("Port")
  valid_402656637 = validateParameter(valid_402656637, JInt, required = false,
                                      default = nil)
  if valid_402656637 != nil:
    section.add "Port", valid_402656637
  var valid_402656638 = query.getOrDefault("CharacterSetName")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "CharacterSetName", valid_402656638
  var valid_402656639 = query.getOrDefault("Action")
  valid_402656639 = validateParameter(valid_402656639, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656639 != nil:
    section.add "Action", valid_402656639
  var valid_402656640 = query.getOrDefault("BackupRetentionPeriod")
  valid_402656640 = validateParameter(valid_402656640, JInt, required = false,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "BackupRetentionPeriod", valid_402656640
  var valid_402656641 = query.getOrDefault("DBSecurityGroups")
  valid_402656641 = validateParameter(valid_402656641, JArray, required = false,
                                      default = nil)
  if valid_402656641 != nil:
    section.add "DBSecurityGroups", valid_402656641
  var valid_402656642 = query.getOrDefault("LicenseModel")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "LicenseModel", valid_402656642
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
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656650: Call_GetCreateDBInstance_402656613;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_GetCreateDBInstance_402656613;
           DBInstanceIdentifier: string; MasterUserPassword: string;
           AllocatedStorage: int; MasterUsername: string;
           DBInstanceClass: string; Engine: string;
           VpcSecurityGroupIds: JsonNode = nil;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBSubnetGroupName: string = ""; DBParameterGroupName: string = "";
           Iops: int = 0; AvailabilityZone: string = ""; MultiAZ: bool = false;
           Version: string = "2013-09-09"; EngineVersion: string = "";
           Tags: JsonNode = nil; AutoMinorVersionUpgrade: bool = false;
           DBName: string = ""; Port: int = 0; CharacterSetName: string = "";
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
  ##   Tags: JArray
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
  var query_402656652 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402656652.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402656652, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656652, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656652, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402656652, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402656652, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656652, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656652, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656652, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402656652, "Iops", newJInt(Iops))
  add(query_402656652, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656652, "MultiAZ", newJBool(MultiAZ))
  add(query_402656652, "Version", newJString(Version))
  add(query_402656652, "EngineVersion", newJString(EngineVersion))
  if Tags != nil:
    query_402656652.add "Tags", Tags
  add(query_402656652, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656652, "DBName", newJString(DBName))
  add(query_402656652, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402656652, "MasterUsername", newJString(MasterUsername))
  add(query_402656652, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656652, "Engine", newJString(Engine))
  add(query_402656652, "Port", newJInt(Port))
  add(query_402656652, "CharacterSetName", newJString(CharacterSetName))
  add(query_402656652, "Action", newJString(Action))
  add(query_402656652, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402656652.add "DBSecurityGroups", DBSecurityGroups
  add(query_402656652, "LicenseModel", newJString(LicenseModel))
  result = call_402656651.call(nil, query_402656652, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_402656613(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_402656614, base: "/",
    makeUrl: url_GetCreateDBInstance_402656615,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_402656720 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstanceReadReplica_402656722(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_402656721(path: JsonNode;
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
  var valid_402656723 = query.getOrDefault("Version")
  valid_402656723 = validateParameter(valid_402656723, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656723 != nil:
    section.add "Version", valid_402656723
  var valid_402656724 = query.getOrDefault("Action")
  valid_402656724 = validateParameter(valid_402656724, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656724 != nil:
    section.add "Action", valid_402656724
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
  var valid_402656725 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Security-Token", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Signature")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Signature", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Algorithm", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Date")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Date", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Credential")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Credential", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656731
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   Tags: JArray
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402656732 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656732 = validateParameter(valid_402656732, JBool, required = false,
                                      default = nil)
  if valid_402656732 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656732
  var valid_402656733 = formData.getOrDefault("Port")
  valid_402656733 = validateParameter(valid_402656733, JInt, required = false,
                                      default = nil)
  if valid_402656733 != nil:
    section.add "Port", valid_402656733
  var valid_402656734 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "DBSubnetGroupName", valid_402656734
  var valid_402656735 = formData.getOrDefault("PubliclyAccessible")
  valid_402656735 = validateParameter(valid_402656735, JBool, required = false,
                                      default = nil)
  if valid_402656735 != nil:
    section.add "PubliclyAccessible", valid_402656735
  var valid_402656736 = formData.getOrDefault("AvailabilityZone")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "AvailabilityZone", valid_402656736
  var valid_402656737 = formData.getOrDefault("Tags")
  valid_402656737 = validateParameter(valid_402656737, JArray, required = false,
                                      default = nil)
  if valid_402656737 != nil:
    section.add "Tags", valid_402656737
  var valid_402656738 = formData.getOrDefault("Iops")
  valid_402656738 = validateParameter(valid_402656738, JInt, required = false,
                                      default = nil)
  if valid_402656738 != nil:
    section.add "Iops", valid_402656738
  var valid_402656739 = formData.getOrDefault("DBInstanceClass")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "DBInstanceClass", valid_402656739
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656740 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656740 = validateParameter(valid_402656740, JString, required = true,
                                      default = nil)
  if valid_402656740 != nil:
    section.add "DBInstanceIdentifier", valid_402656740
  var valid_402656741 = formData.getOrDefault("OptionGroupName")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "OptionGroupName", valid_402656741
  var valid_402656742 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656742 = validateParameter(valid_402656742, JString, required = true,
                                      default = nil)
  if valid_402656742 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656742
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656743: Call_PostCreateDBInstanceReadReplica_402656720;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656743.validator(path, query, header, formData, body, _)
  let scheme = call_402656743.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656743.makeUrl(scheme.get, call_402656743.host, call_402656743.base,
                                   call_402656743.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656743, uri, valid, _)

proc call*(call_402656744: Call_PostCreateDBInstanceReadReplica_402656720;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; Tags: JsonNode = nil;
           Version: string = "2013-09-09"; Iops: int = 0;
           DBInstanceClass: string = ""; OptionGroupName: string = "";
           Action: string = "CreateDBInstanceReadReplica"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AvailabilityZone: string
  ##   Tags: JArray
  ##   Version: string (required)
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   SourceDBInstanceIdentifier: string (required)
  var query_402656745 = newJObject()
  var formData_402656746 = newJObject()
  add(formData_402656746, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402656746, "Port", newJInt(Port))
  add(formData_402656746, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402656746, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656746, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    formData_402656746.add "Tags", Tags
  add(query_402656745, "Version", newJString(Version))
  add(formData_402656746, "Iops", newJInt(Iops))
  add(formData_402656746, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656746, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656746, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656745, "Action", newJString(Action))
  add(formData_402656746, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402656744.call(nil, query_402656745, nil, formData_402656746,
                               nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_402656720(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_402656721, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_402656722,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_402656694 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstanceReadReplica_402656696(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_402656695(path: JsonNode;
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
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   Port: JInt
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656697 = query.getOrDefault("PubliclyAccessible")
  valid_402656697 = validateParameter(valid_402656697, JBool, required = false,
                                      default = nil)
  if valid_402656697 != nil:
    section.add "PubliclyAccessible", valid_402656697
  var valid_402656698 = query.getOrDefault("OptionGroupName")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "OptionGroupName", valid_402656698
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656699 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656699 = validateParameter(valid_402656699, JString, required = true,
                                      default = nil)
  if valid_402656699 != nil:
    section.add "DBInstanceIdentifier", valid_402656699
  var valid_402656700 = query.getOrDefault("DBSubnetGroupName")
  valid_402656700 = validateParameter(valid_402656700, JString,
                                      required = false, default = nil)
  if valid_402656700 != nil:
    section.add "DBSubnetGroupName", valid_402656700
  var valid_402656701 = query.getOrDefault("Iops")
  valid_402656701 = validateParameter(valid_402656701, JInt, required = false,
                                      default = nil)
  if valid_402656701 != nil:
    section.add "Iops", valid_402656701
  var valid_402656702 = query.getOrDefault("AvailabilityZone")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "AvailabilityZone", valid_402656702
  var valid_402656703 = query.getOrDefault("Version")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656703 != nil:
    section.add "Version", valid_402656703
  var valid_402656704 = query.getOrDefault("Tags")
  valid_402656704 = validateParameter(valid_402656704, JArray, required = false,
                                      default = nil)
  if valid_402656704 != nil:
    section.add "Tags", valid_402656704
  var valid_402656705 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656705 = validateParameter(valid_402656705, JBool, required = false,
                                      default = nil)
  if valid_402656705 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656705
  var valid_402656706 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656706 = validateParameter(valid_402656706, JString, required = true,
                                      default = nil)
  if valid_402656706 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656706
  var valid_402656707 = query.getOrDefault("DBInstanceClass")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "DBInstanceClass", valid_402656707
  var valid_402656708 = query.getOrDefault("Port")
  valid_402656708 = validateParameter(valid_402656708, JInt, required = false,
                                      default = nil)
  if valid_402656708 != nil:
    section.add "Port", valid_402656708
  var valid_402656709 = query.getOrDefault("Action")
  valid_402656709 = validateParameter(valid_402656709, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656709 != nil:
    section.add "Action", valid_402656709
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
  var valid_402656710 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Security-Token", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Signature")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Signature", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Algorithm", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Date")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Date", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Credential")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Credential", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656717: Call_GetCreateDBInstanceReadReplica_402656694;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656717.validator(path, query, header, formData, body, _)
  let scheme = call_402656717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656717.makeUrl(scheme.get, call_402656717.host, call_402656717.base,
                                   call_402656717.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656717, uri, valid, _)

proc call*(call_402656718: Call_GetCreateDBInstanceReadReplica_402656694;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           DBSubnetGroupName: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; Version: string = "2013-09-09";
           Tags: JsonNode = nil; AutoMinorVersionUpgrade: bool = false;
           DBInstanceClass: string = ""; Port: int = 0;
           Action: string = "CreateDBInstanceReadReplica"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   Version: string (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   Port: int
  ##   Action: string (required)
  var query_402656719 = newJObject()
  add(query_402656719, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656719, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656719, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656719, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656719, "Iops", newJInt(Iops))
  add(query_402656719, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656719, "Version", newJString(Version))
  if Tags != nil:
    query_402656719.add "Tags", Tags
  add(query_402656719, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656719, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402656719, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656719, "Port", newJInt(Port))
  add(query_402656719, "Action", newJString(Action))
  result = call_402656718.call(nil, query_402656719, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_402656694(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_402656695, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_402656696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_402656766 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBParameterGroup_402656768(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_402656767(path: JsonNode;
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
  var valid_402656769 = query.getOrDefault("Version")
  valid_402656769 = validateParameter(valid_402656769, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656769 != nil:
    section.add "Version", valid_402656769
  var valid_402656770 = query.getOrDefault("Action")
  valid_402656770 = validateParameter(valid_402656770, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656770 != nil:
    section.add "Action", valid_402656770
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
  var valid_402656771 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "X-Amz-Security-Token", valid_402656771
  var valid_402656772 = header.getOrDefault("X-Amz-Signature")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "X-Amz-Signature", valid_402656772
  var valid_402656773 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656773 = validateParameter(valid_402656773, JString,
                                      required = false, default = nil)
  if valid_402656773 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656773
  var valid_402656774 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Algorithm", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Date")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Date", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Credential")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Credential", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656777
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402656778 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402656778 = validateParameter(valid_402656778, JString, required = true,
                                      default = nil)
  if valid_402656778 != nil:
    section.add "DBParameterGroupFamily", valid_402656778
  var valid_402656779 = formData.getOrDefault("Tags")
  valid_402656779 = validateParameter(valid_402656779, JArray, required = false,
                                      default = nil)
  if valid_402656779 != nil:
    section.add "Tags", valid_402656779
  var valid_402656780 = formData.getOrDefault("DBParameterGroupName")
  valid_402656780 = validateParameter(valid_402656780, JString, required = true,
                                      default = nil)
  if valid_402656780 != nil:
    section.add "DBParameterGroupName", valid_402656780
  var valid_402656781 = formData.getOrDefault("Description")
  valid_402656781 = validateParameter(valid_402656781, JString, required = true,
                                      default = nil)
  if valid_402656781 != nil:
    section.add "Description", valid_402656781
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656782: Call_PostCreateDBParameterGroup_402656766;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656782.validator(path, query, header, formData, body, _)
  let scheme = call_402656782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656782.makeUrl(scheme.get, call_402656782.host, call_402656782.base,
                                   call_402656782.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656782, uri, valid, _)

proc call*(call_402656783: Call_PostCreateDBParameterGroup_402656766;
           DBParameterGroupFamily: string; DBParameterGroupName: string;
           Description: string; Tags: JsonNode = nil;
           Version: string = "2013-09-09";
           Action: string = "CreateDBParameterGroup"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  var query_402656784 = newJObject()
  var formData_402656785 = newJObject()
  add(formData_402656785, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Tags != nil:
    formData_402656785.add "Tags", Tags
  add(query_402656784, "Version", newJString(Version))
  add(formData_402656785, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402656784, "Action", newJString(Action))
  add(formData_402656785, "Description", newJString(Description))
  result = call_402656783.call(nil, query_402656784, nil, formData_402656785,
                               nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_402656766(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_402656767, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_402656768,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_402656747 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBParameterGroup_402656749(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_402656748(path: JsonNode;
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
  ##   Tags: JArray
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `Description` field"
  var valid_402656750 = query.getOrDefault("Description")
  valid_402656750 = validateParameter(valid_402656750, JString, required = true,
                                      default = nil)
  if valid_402656750 != nil:
    section.add "Description", valid_402656750
  var valid_402656751 = query.getOrDefault("DBParameterGroupName")
  valid_402656751 = validateParameter(valid_402656751, JString, required = true,
                                      default = nil)
  if valid_402656751 != nil:
    section.add "DBParameterGroupName", valid_402656751
  var valid_402656752 = query.getOrDefault("DBParameterGroupFamily")
  valid_402656752 = validateParameter(valid_402656752, JString, required = true,
                                      default = nil)
  if valid_402656752 != nil:
    section.add "DBParameterGroupFamily", valid_402656752
  var valid_402656753 = query.getOrDefault("Version")
  valid_402656753 = validateParameter(valid_402656753, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656753 != nil:
    section.add "Version", valid_402656753
  var valid_402656754 = query.getOrDefault("Tags")
  valid_402656754 = validateParameter(valid_402656754, JArray, required = false,
                                      default = nil)
  if valid_402656754 != nil:
    section.add "Tags", valid_402656754
  var valid_402656755 = query.getOrDefault("Action")
  valid_402656755 = validateParameter(valid_402656755, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656755 != nil:
    section.add "Action", valid_402656755
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
  var valid_402656756 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656756 = validateParameter(valid_402656756, JString,
                                      required = false, default = nil)
  if valid_402656756 != nil:
    section.add "X-Amz-Security-Token", valid_402656756
  var valid_402656757 = header.getOrDefault("X-Amz-Signature")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Signature", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Algorithm", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Date")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Date", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Credential")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Credential", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656762
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656763: Call_GetCreateDBParameterGroup_402656747;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656763.validator(path, query, header, formData, body, _)
  let scheme = call_402656763.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656763.makeUrl(scheme.get, call_402656763.host, call_402656763.base,
                                   call_402656763.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656763, uri, valid, _)

proc call*(call_402656764: Call_GetCreateDBParameterGroup_402656747;
           Description: string; DBParameterGroupName: string;
           DBParameterGroupFamily: string; Version: string = "2013-09-09";
           Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  var query_402656765 = newJObject()
  add(query_402656765, "Description", newJString(Description))
  add(query_402656765, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656765, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402656765, "Version", newJString(Version))
  if Tags != nil:
    query_402656765.add "Tags", Tags
  add(query_402656765, "Action", newJString(Action))
  result = call_402656764.call(nil, query_402656765, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_402656747(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_402656748, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_402656749,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_402656804 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSecurityGroup_402656806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_402656805(path: JsonNode;
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
  var valid_402656807 = query.getOrDefault("Version")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656807 != nil:
    section.add "Version", valid_402656807
  var valid_402656808 = query.getOrDefault("Action")
  valid_402656808 = validateParameter(valid_402656808, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656808 != nil:
    section.add "Action", valid_402656808
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
  var valid_402656809 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Security-Token", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Signature")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Signature", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Algorithm", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Date")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Date", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Credential")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Credential", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656815
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_402656816 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_402656816 = validateParameter(valid_402656816, JString, required = true,
                                      default = nil)
  if valid_402656816 != nil:
    section.add "DBSecurityGroupDescription", valid_402656816
  var valid_402656817 = formData.getOrDefault("Tags")
  valid_402656817 = validateParameter(valid_402656817, JArray, required = false,
                                      default = nil)
  if valid_402656817 != nil:
    section.add "Tags", valid_402656817
  var valid_402656818 = formData.getOrDefault("DBSecurityGroupName")
  valid_402656818 = validateParameter(valid_402656818, JString, required = true,
                                      default = nil)
  if valid_402656818 != nil:
    section.add "DBSecurityGroupName", valid_402656818
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656819: Call_PostCreateDBSecurityGroup_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656819.validator(path, query, header, formData, body, _)
  let scheme = call_402656819.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656819.makeUrl(scheme.get, call_402656819.host, call_402656819.base,
                                   call_402656819.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656819, uri, valid, _)

proc call*(call_402656820: Call_PostCreateDBSecurityGroup_402656804;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Tags: JsonNode = nil; Version: string = "2013-09-09";
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402656821 = newJObject()
  var formData_402656822 = newJObject()
  add(formData_402656822, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    formData_402656822.add "Tags", Tags
  add(query_402656821, "Version", newJString(Version))
  add(formData_402656822, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402656821, "Action", newJString(Action))
  result = call_402656820.call(nil, query_402656821, nil, formData_402656822,
                               nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_402656804(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_402656805, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_402656786 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSecurityGroup_402656788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_402656787(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_402656789 = query.getOrDefault("DBSecurityGroupDescription")
  valid_402656789 = validateParameter(valid_402656789, JString, required = true,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "DBSecurityGroupDescription", valid_402656789
  var valid_402656790 = query.getOrDefault("Version")
  valid_402656790 = validateParameter(valid_402656790, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656790 != nil:
    section.add "Version", valid_402656790
  var valid_402656791 = query.getOrDefault("Tags")
  valid_402656791 = validateParameter(valid_402656791, JArray, required = false,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "Tags", valid_402656791
  var valid_402656792 = query.getOrDefault("Action")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656792 != nil:
    section.add "Action", valid_402656792
  var valid_402656793 = query.getOrDefault("DBSecurityGroupName")
  valid_402656793 = validateParameter(valid_402656793, JString, required = true,
                                      default = nil)
  if valid_402656793 != nil:
    section.add "DBSecurityGroupName", valid_402656793
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
  var valid_402656794 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Security-Token", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Signature")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Signature", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Algorithm", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Date")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Date", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Credential")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Credential", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656800
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_GetCreateDBSecurityGroup_402656786;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_GetCreateDBSecurityGroup_402656786;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Version: string = "2013-09-09"; Tags: JsonNode = nil;
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402656803 = newJObject()
  add(query_402656803, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_402656803, "Version", newJString(Version))
  if Tags != nil:
    query_402656803.add "Tags", Tags
  add(query_402656803, "Action", newJString(Action))
  add(query_402656803, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402656802.call(nil, query_402656803, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_402656786(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_402656787, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_402656788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_402656841 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSnapshot_402656843(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_402656842(path: JsonNode; query: JsonNode;
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
  var valid_402656844 = query.getOrDefault("Version")
  valid_402656844 = validateParameter(valid_402656844, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656844 != nil:
    section.add "Version", valid_402656844
  var valid_402656845 = query.getOrDefault("Action")
  valid_402656845 = validateParameter(valid_402656845, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656845 != nil:
    section.add "Action", valid_402656845
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
  var valid_402656846 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Security-Token", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Signature")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Signature", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656848
  var valid_402656849 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656849 = validateParameter(valid_402656849, JString,
                                      required = false, default = nil)
  if valid_402656849 != nil:
    section.add "X-Amz-Algorithm", valid_402656849
  var valid_402656850 = header.getOrDefault("X-Amz-Date")
  valid_402656850 = validateParameter(valid_402656850, JString,
                                      required = false, default = nil)
  if valid_402656850 != nil:
    section.add "X-Amz-Date", valid_402656850
  var valid_402656851 = header.getOrDefault("X-Amz-Credential")
  valid_402656851 = validateParameter(valid_402656851, JString,
                                      required = false, default = nil)
  if valid_402656851 != nil:
    section.add "X-Amz-Credential", valid_402656851
  var valid_402656852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656852 = validateParameter(valid_402656852, JString,
                                      required = false, default = nil)
  if valid_402656852 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656852
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_402656853 = formData.getOrDefault("Tags")
  valid_402656853 = validateParameter(valid_402656853, JArray, required = false,
                                      default = nil)
  if valid_402656853 != nil:
    section.add "Tags", valid_402656853
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656854 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656854 = validateParameter(valid_402656854, JString, required = true,
                                      default = nil)
  if valid_402656854 != nil:
    section.add "DBInstanceIdentifier", valid_402656854
  var valid_402656855 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true,
                                      default = nil)
  if valid_402656855 != nil:
    section.add "DBSnapshotIdentifier", valid_402656855
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656856: Call_PostCreateDBSnapshot_402656841;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656856.validator(path, query, header, formData, body, _)
  let scheme = call_402656856.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656856.makeUrl(scheme.get, call_402656856.host, call_402656856.base,
                                   call_402656856.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656856, uri, valid, _)

proc call*(call_402656857: Call_PostCreateDBSnapshot_402656841;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Tags: JsonNode = nil; Version: string = "2013-09-09";
           Action: string = "CreateDBSnapshot"): Recallable =
  ## postCreateDBSnapshot
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656858 = newJObject()
  var formData_402656859 = newJObject()
  if Tags != nil:
    formData_402656859.add "Tags", Tags
  add(query_402656858, "Version", newJString(Version))
  add(formData_402656859, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656859, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402656858, "Action", newJString(Action))
  result = call_402656857.call(nil, query_402656858, nil, formData_402656859,
                               nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_402656841(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_402656842, base: "/",
    makeUrl: url_PostCreateDBSnapshot_402656843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_402656823 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSnapshot_402656825(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_402656824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656826 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656826 = validateParameter(valid_402656826, JString, required = true,
                                      default = nil)
  if valid_402656826 != nil:
    section.add "DBInstanceIdentifier", valid_402656826
  var valid_402656827 = query.getOrDefault("Version")
  valid_402656827 = validateParameter(valid_402656827, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656827 != nil:
    section.add "Version", valid_402656827
  var valid_402656828 = query.getOrDefault("Tags")
  valid_402656828 = validateParameter(valid_402656828, JArray, required = false,
                                      default = nil)
  if valid_402656828 != nil:
    section.add "Tags", valid_402656828
  var valid_402656829 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402656829 = validateParameter(valid_402656829, JString, required = true,
                                      default = nil)
  if valid_402656829 != nil:
    section.add "DBSnapshotIdentifier", valid_402656829
  var valid_402656830 = query.getOrDefault("Action")
  valid_402656830 = validateParameter(valid_402656830, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656830 != nil:
    section.add "Action", valid_402656830
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
  var valid_402656831 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656831 = validateParameter(valid_402656831, JString,
                                      required = false, default = nil)
  if valid_402656831 != nil:
    section.add "X-Amz-Security-Token", valid_402656831
  var valid_402656832 = header.getOrDefault("X-Amz-Signature")
  valid_402656832 = validateParameter(valid_402656832, JString,
                                      required = false, default = nil)
  if valid_402656832 != nil:
    section.add "X-Amz-Signature", valid_402656832
  var valid_402656833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656833 = validateParameter(valid_402656833, JString,
                                      required = false, default = nil)
  if valid_402656833 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656833
  var valid_402656834 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656834 = validateParameter(valid_402656834, JString,
                                      required = false, default = nil)
  if valid_402656834 != nil:
    section.add "X-Amz-Algorithm", valid_402656834
  var valid_402656835 = header.getOrDefault("X-Amz-Date")
  valid_402656835 = validateParameter(valid_402656835, JString,
                                      required = false, default = nil)
  if valid_402656835 != nil:
    section.add "X-Amz-Date", valid_402656835
  var valid_402656836 = header.getOrDefault("X-Amz-Credential")
  valid_402656836 = validateParameter(valid_402656836, JString,
                                      required = false, default = nil)
  if valid_402656836 != nil:
    section.add "X-Amz-Credential", valid_402656836
  var valid_402656837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656837
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656838: Call_GetCreateDBSnapshot_402656823;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656838.validator(path, query, header, formData, body, _)
  let scheme = call_402656838.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656838.makeUrl(scheme.get, call_402656838.host, call_402656838.base,
                                   call_402656838.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656838, uri, valid, _)

proc call*(call_402656839: Call_GetCreateDBSnapshot_402656823;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Version: string = "2013-09-09"; Tags: JsonNode = nil;
           Action: string = "CreateDBSnapshot"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656840 = newJObject()
  add(query_402656840, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656840, "Version", newJString(Version))
  if Tags != nil:
    query_402656840.add "Tags", Tags
  add(query_402656840, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402656840, "Action", newJString(Action))
  result = call_402656839.call(nil, query_402656840, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_402656823(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_402656824, base: "/",
    makeUrl: url_GetCreateDBSnapshot_402656825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_402656879 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSubnetGroup_402656881(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_402656880(path: JsonNode; query: JsonNode;
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
  var valid_402656882 = query.getOrDefault("Version")
  valid_402656882 = validateParameter(valid_402656882, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656882 != nil:
    section.add "Version", valid_402656882
  var valid_402656883 = query.getOrDefault("Action")
  valid_402656883 = validateParameter(valid_402656883, JString, required = true, default = newJString(
      "CreateDBSubnetGroup"))
  if valid_402656883 != nil:
    section.add "Action", valid_402656883
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
  var valid_402656884 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Security-Token", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Signature")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Signature", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Algorithm", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Date")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Date", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Credential")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Credential", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656890
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402656891 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656891 = validateParameter(valid_402656891, JString, required = true,
                                      default = nil)
  if valid_402656891 != nil:
    section.add "DBSubnetGroupName", valid_402656891
  var valid_402656892 = formData.getOrDefault("Tags")
  valid_402656892 = validateParameter(valid_402656892, JArray, required = false,
                                      default = nil)
  if valid_402656892 != nil:
    section.add "Tags", valid_402656892
  var valid_402656893 = formData.getOrDefault("SubnetIds")
  valid_402656893 = validateParameter(valid_402656893, JArray, required = true,
                                      default = nil)
  if valid_402656893 != nil:
    section.add "SubnetIds", valid_402656893
  var valid_402656894 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402656894 = validateParameter(valid_402656894, JString, required = true,
                                      default = nil)
  if valid_402656894 != nil:
    section.add "DBSubnetGroupDescription", valid_402656894
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656895: Call_PostCreateDBSubnetGroup_402656879;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656895.validator(path, query, header, formData, body, _)
  let scheme = call_402656895.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656895.makeUrl(scheme.get, call_402656895.host, call_402656895.base,
                                   call_402656895.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656895, uri, valid, _)

proc call*(call_402656896: Call_PostCreateDBSubnetGroup_402656879;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string; Tags: JsonNode = nil;
           Version: string = "2013-09-09";
           Action: string = "CreateDBSubnetGroup"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  var query_402656897 = newJObject()
  var formData_402656898 = newJObject()
  add(formData_402656898, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Tags != nil:
    formData_402656898.add "Tags", Tags
  add(query_402656897, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402656898.add "SubnetIds", SubnetIds
  add(formData_402656898, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656897, "Action", newJString(Action))
  result = call_402656896.call(nil, query_402656897, nil, formData_402656898,
                               nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_402656879(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_402656880, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_402656881,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_402656860 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSubnetGroup_402656862(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_402656861(path: JsonNode; query: JsonNode;
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
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402656863 = query.getOrDefault("DBSubnetGroupName")
  valid_402656863 = validateParameter(valid_402656863, JString, required = true,
                                      default = nil)
  if valid_402656863 != nil:
    section.add "DBSubnetGroupName", valid_402656863
  var valid_402656864 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402656864 = validateParameter(valid_402656864, JString, required = true,
                                      default = nil)
  if valid_402656864 != nil:
    section.add "DBSubnetGroupDescription", valid_402656864
  var valid_402656865 = query.getOrDefault("Version")
  valid_402656865 = validateParameter(valid_402656865, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656865 != nil:
    section.add "Version", valid_402656865
  var valid_402656866 = query.getOrDefault("Tags")
  valid_402656866 = validateParameter(valid_402656866, JArray, required = false,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "Tags", valid_402656866
  var valid_402656867 = query.getOrDefault("SubnetIds")
  valid_402656867 = validateParameter(valid_402656867, JArray, required = true,
                                      default = nil)
  if valid_402656867 != nil:
    section.add "SubnetIds", valid_402656867
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
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656876: Call_GetCreateDBSubnetGroup_402656860;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656876.validator(path, query, header, formData, body, _)
  let scheme = call_402656876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656876.makeUrl(scheme.get, call_402656876.host, call_402656876.base,
                                   call_402656876.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656876, uri, valid, _)

proc call*(call_402656877: Call_GetCreateDBSubnetGroup_402656860;
           DBSubnetGroupName: string; DBSubnetGroupDescription: string;
           SubnetIds: JsonNode; Version: string = "2013-09-09";
           Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup"): Recallable =
  ## getCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402656878 = newJObject()
  add(query_402656878, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656878, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656878, "Version", newJString(Version))
  if Tags != nil:
    query_402656878.add "Tags", Tags
  if SubnetIds != nil:
    query_402656878.add "SubnetIds", SubnetIds
  add(query_402656878, "Action", newJString(Action))
  result = call_402656877.call(nil, query_402656878, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_402656860(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_402656861, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_402656862,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_402656921 = ref object of OpenApiRestCall_402656035
proc url_PostCreateEventSubscription_402656923(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_402656922(path: JsonNode;
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
  var valid_402656924 = query.getOrDefault("Version")
  valid_402656924 = validateParameter(valid_402656924, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656924 != nil:
    section.add "Version", valid_402656924
  var valid_402656925 = query.getOrDefault("Action")
  valid_402656925 = validateParameter(valid_402656925, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402656925 != nil:
    section.add "Action", valid_402656925
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
  var valid_402656926 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656926 = validateParameter(valid_402656926, JString,
                                      required = false, default = nil)
  if valid_402656926 != nil:
    section.add "X-Amz-Security-Token", valid_402656926
  var valid_402656927 = header.getOrDefault("X-Amz-Signature")
  valid_402656927 = validateParameter(valid_402656927, JString,
                                      required = false, default = nil)
  if valid_402656927 != nil:
    section.add "X-Amz-Signature", valid_402656927
  var valid_402656928 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656928 = validateParameter(valid_402656928, JString,
                                      required = false, default = nil)
  if valid_402656928 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656928
  var valid_402656929 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656929 = validateParameter(valid_402656929, JString,
                                      required = false, default = nil)
  if valid_402656929 != nil:
    section.add "X-Amz-Algorithm", valid_402656929
  var valid_402656930 = header.getOrDefault("X-Amz-Date")
  valid_402656930 = validateParameter(valid_402656930, JString,
                                      required = false, default = nil)
  if valid_402656930 != nil:
    section.add "X-Amz-Date", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Credential")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Credential", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656932
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIds: JArray
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   Tags: JArray
  ##   SnsTopicArn: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  var valid_402656933 = formData.getOrDefault("SourceIds")
  valid_402656933 = validateParameter(valid_402656933, JArray, required = false,
                                      default = nil)
  if valid_402656933 != nil:
    section.add "SourceIds", valid_402656933
  var valid_402656934 = formData.getOrDefault("SourceType")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "SourceType", valid_402656934
  var valid_402656935 = formData.getOrDefault("Enabled")
  valid_402656935 = validateParameter(valid_402656935, JBool, required = false,
                                      default = nil)
  if valid_402656935 != nil:
    section.add "Enabled", valid_402656935
  var valid_402656936 = formData.getOrDefault("EventCategories")
  valid_402656936 = validateParameter(valid_402656936, JArray, required = false,
                                      default = nil)
  if valid_402656936 != nil:
    section.add "EventCategories", valid_402656936
  var valid_402656937 = formData.getOrDefault("Tags")
  valid_402656937 = validateParameter(valid_402656937, JArray, required = false,
                                      default = nil)
  if valid_402656937 != nil:
    section.add "Tags", valid_402656937
  assert formData != nil,
         "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_402656938 = formData.getOrDefault("SnsTopicArn")
  valid_402656938 = validateParameter(valid_402656938, JString, required = true,
                                      default = nil)
  if valid_402656938 != nil:
    section.add "SnsTopicArn", valid_402656938
  var valid_402656939 = formData.getOrDefault("SubscriptionName")
  valid_402656939 = validateParameter(valid_402656939, JString, required = true,
                                      default = nil)
  if valid_402656939 != nil:
    section.add "SubscriptionName", valid_402656939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656940: Call_PostCreateEventSubscription_402656921;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656940.validator(path, query, header, formData, body, _)
  let scheme = call_402656940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656940.makeUrl(scheme.get, call_402656940.host, call_402656940.base,
                                   call_402656940.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656940, uri, valid, _)

proc call*(call_402656941: Call_PostCreateEventSubscription_402656921;
           SnsTopicArn: string; SubscriptionName: string;
           SourceIds: JsonNode = nil; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Tags: JsonNode = nil; Version: string = "2013-09-09";
           Action: string = "CreateEventSubscription"): Recallable =
  ## postCreateEventSubscription
  ##   SourceIds: JArray
  ##   SourceType: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Tags: JArray
  ##   Version: string (required)
  ##   SnsTopicArn: string (required)
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402656942 = newJObject()
  var formData_402656943 = newJObject()
  if SourceIds != nil:
    formData_402656943.add "SourceIds", SourceIds
  add(formData_402656943, "SourceType", newJString(SourceType))
  add(formData_402656943, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402656943.add "EventCategories", EventCategories
  if Tags != nil:
    formData_402656943.add "Tags", Tags
  add(query_402656942, "Version", newJString(Version))
  add(formData_402656943, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402656942, "Action", newJString(Action))
  add(formData_402656943, "SubscriptionName", newJString(SubscriptionName))
  result = call_402656941.call(nil, query_402656942, nil, formData_402656943,
                               nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_402656921(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_402656922, base: "/",
    makeUrl: url_PostCreateEventSubscription_402656923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_402656899 = ref object of OpenApiRestCall_402656035
proc url_GetCreateEventSubscription_402656901(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_402656900(path: JsonNode;
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
  ##   Tags: JArray
  ##   SourceType: JString
  ##   SourceIds: JArray
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `SnsTopicArn` field"
  var valid_402656902 = query.getOrDefault("SnsTopicArn")
  valid_402656902 = validateParameter(valid_402656902, JString, required = true,
                                      default = nil)
  if valid_402656902 != nil:
    section.add "SnsTopicArn", valid_402656902
  var valid_402656903 = query.getOrDefault("Enabled")
  valid_402656903 = validateParameter(valid_402656903, JBool, required = false,
                                      default = nil)
  if valid_402656903 != nil:
    section.add "Enabled", valid_402656903
  var valid_402656904 = query.getOrDefault("EventCategories")
  valid_402656904 = validateParameter(valid_402656904, JArray, required = false,
                                      default = nil)
  if valid_402656904 != nil:
    section.add "EventCategories", valid_402656904
  var valid_402656905 = query.getOrDefault("Version")
  valid_402656905 = validateParameter(valid_402656905, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656905 != nil:
    section.add "Version", valid_402656905
  var valid_402656906 = query.getOrDefault("SubscriptionName")
  valid_402656906 = validateParameter(valid_402656906, JString, required = true,
                                      default = nil)
  if valid_402656906 != nil:
    section.add "SubscriptionName", valid_402656906
  var valid_402656907 = query.getOrDefault("Tags")
  valid_402656907 = validateParameter(valid_402656907, JArray, required = false,
                                      default = nil)
  if valid_402656907 != nil:
    section.add "Tags", valid_402656907
  var valid_402656908 = query.getOrDefault("SourceType")
  valid_402656908 = validateParameter(valid_402656908, JString,
                                      required = false, default = nil)
  if valid_402656908 != nil:
    section.add "SourceType", valid_402656908
  var valid_402656909 = query.getOrDefault("SourceIds")
  valid_402656909 = validateParameter(valid_402656909, JArray, required = false,
                                      default = nil)
  if valid_402656909 != nil:
    section.add "SourceIds", valid_402656909
  var valid_402656910 = query.getOrDefault("Action")
  valid_402656910 = validateParameter(valid_402656910, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402656910 != nil:
    section.add "Action", valid_402656910
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
  var valid_402656911 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656911 = validateParameter(valid_402656911, JString,
                                      required = false, default = nil)
  if valid_402656911 != nil:
    section.add "X-Amz-Security-Token", valid_402656911
  var valid_402656912 = header.getOrDefault("X-Amz-Signature")
  valid_402656912 = validateParameter(valid_402656912, JString,
                                      required = false, default = nil)
  if valid_402656912 != nil:
    section.add "X-Amz-Signature", valid_402656912
  var valid_402656913 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656913 = validateParameter(valid_402656913, JString,
                                      required = false, default = nil)
  if valid_402656913 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656913
  var valid_402656914 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656914 = validateParameter(valid_402656914, JString,
                                      required = false, default = nil)
  if valid_402656914 != nil:
    section.add "X-Amz-Algorithm", valid_402656914
  var valid_402656915 = header.getOrDefault("X-Amz-Date")
  valid_402656915 = validateParameter(valid_402656915, JString,
                                      required = false, default = nil)
  if valid_402656915 != nil:
    section.add "X-Amz-Date", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Credential")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Credential", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656917
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656918: Call_GetCreateEventSubscription_402656899;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656918.validator(path, query, header, formData, body, _)
  let scheme = call_402656918.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656918.makeUrl(scheme.get, call_402656918.host, call_402656918.base,
                                   call_402656918.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656918, uri, valid, _)

proc call*(call_402656919: Call_GetCreateEventSubscription_402656899;
           SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
           EventCategories: JsonNode = nil; Version: string = "2013-09-09";
           Tags: JsonNode = nil; SourceType: string = "";
           SourceIds: JsonNode = nil; Action: string = "CreateEventSubscription"): Recallable =
  ## getCreateEventSubscription
  ##   SnsTopicArn: string (required)
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Tags: JArray
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Action: string (required)
  var query_402656920 = newJObject()
  add(query_402656920, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402656920, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402656920.add "EventCategories", EventCategories
  add(query_402656920, "Version", newJString(Version))
  add(query_402656920, "SubscriptionName", newJString(SubscriptionName))
  if Tags != nil:
    query_402656920.add "Tags", Tags
  add(query_402656920, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_402656920.add "SourceIds", SourceIds
  add(query_402656920, "Action", newJString(Action))
  result = call_402656919.call(nil, query_402656920, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_402656899(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_402656900, base: "/",
    makeUrl: url_GetCreateEventSubscription_402656901,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_402656964 = ref object of OpenApiRestCall_402656035
proc url_PostCreateOptionGroup_402656966(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_402656965(path: JsonNode; query: JsonNode;
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
  var valid_402656967 = query.getOrDefault("Version")
  valid_402656967 = validateParameter(valid_402656967, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656967 != nil:
    section.add "Version", valid_402656967
  var valid_402656968 = query.getOrDefault("Action")
  valid_402656968 = validateParameter(valid_402656968, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402656968 != nil:
    section.add "Action", valid_402656968
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
  var valid_402656969 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656969 = validateParameter(valid_402656969, JString,
                                      required = false, default = nil)
  if valid_402656969 != nil:
    section.add "X-Amz-Security-Token", valid_402656969
  var valid_402656970 = header.getOrDefault("X-Amz-Signature")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Signature", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Algorithm", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Date")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Date", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Credential")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Credential", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656975
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_402656976 = formData.getOrDefault("OptionGroupDescription")
  valid_402656976 = validateParameter(valid_402656976, JString, required = true,
                                      default = nil)
  if valid_402656976 != nil:
    section.add "OptionGroupDescription", valid_402656976
  var valid_402656977 = formData.getOrDefault("EngineName")
  valid_402656977 = validateParameter(valid_402656977, JString, required = true,
                                      default = nil)
  if valid_402656977 != nil:
    section.add "EngineName", valid_402656977
  var valid_402656978 = formData.getOrDefault("Tags")
  valid_402656978 = validateParameter(valid_402656978, JArray, required = false,
                                      default = nil)
  if valid_402656978 != nil:
    section.add "Tags", valid_402656978
  var valid_402656979 = formData.getOrDefault("OptionGroupName")
  valid_402656979 = validateParameter(valid_402656979, JString, required = true,
                                      default = nil)
  if valid_402656979 != nil:
    section.add "OptionGroupName", valid_402656979
  var valid_402656980 = formData.getOrDefault("MajorEngineVersion")
  valid_402656980 = validateParameter(valid_402656980, JString, required = true,
                                      default = nil)
  if valid_402656980 != nil:
    section.add "MajorEngineVersion", valid_402656980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656981: Call_PostCreateOptionGroup_402656964;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656981.validator(path, query, header, formData, body, _)
  let scheme = call_402656981.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656981.makeUrl(scheme.get, call_402656981.host, call_402656981.base,
                                   call_402656981.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656981, uri, valid, _)

proc call*(call_402656982: Call_PostCreateOptionGroup_402656964;
           OptionGroupDescription: string; EngineName: string;
           OptionGroupName: string; MajorEngineVersion: string;
           Tags: JsonNode = nil; Version: string = "2013-09-09";
           Action: string = "CreateOptionGroup"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   MajorEngineVersion: string (required)
  var query_402656983 = newJObject()
  var formData_402656984 = newJObject()
  add(formData_402656984, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_402656984, "EngineName", newJString(EngineName))
  if Tags != nil:
    formData_402656984.add "Tags", Tags
  add(query_402656983, "Version", newJString(Version))
  add(formData_402656984, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656983, "Action", newJString(Action))
  add(formData_402656984, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402656982.call(nil, query_402656983, nil, formData_402656984,
                               nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_402656964(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_402656965, base: "/",
    makeUrl: url_PostCreateOptionGroup_402656966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_402656944 = ref object of OpenApiRestCall_402656035
proc url_GetCreateOptionGroup_402656946(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_402656945(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402656947 = query.getOrDefault("OptionGroupName")
  valid_402656947 = validateParameter(valid_402656947, JString, required = true,
                                      default = nil)
  if valid_402656947 != nil:
    section.add "OptionGroupName", valid_402656947
  var valid_402656948 = query.getOrDefault("Version")
  valid_402656948 = validateParameter(valid_402656948, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656948 != nil:
    section.add "Version", valid_402656948
  var valid_402656949 = query.getOrDefault("Tags")
  valid_402656949 = validateParameter(valid_402656949, JArray, required = false,
                                      default = nil)
  if valid_402656949 != nil:
    section.add "Tags", valid_402656949
  var valid_402656950 = query.getOrDefault("Action")
  valid_402656950 = validateParameter(valid_402656950, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402656950 != nil:
    section.add "Action", valid_402656950
  var valid_402656951 = query.getOrDefault("EngineName")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = nil)
  if valid_402656951 != nil:
    section.add "EngineName", valid_402656951
  var valid_402656952 = query.getOrDefault("MajorEngineVersion")
  valid_402656952 = validateParameter(valid_402656952, JString, required = true,
                                      default = nil)
  if valid_402656952 != nil:
    section.add "MajorEngineVersion", valid_402656952
  var valid_402656953 = query.getOrDefault("OptionGroupDescription")
  valid_402656953 = validateParameter(valid_402656953, JString, required = true,
                                      default = nil)
  if valid_402656953 != nil:
    section.add "OptionGroupDescription", valid_402656953
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
  var valid_402656954 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656954 = validateParameter(valid_402656954, JString,
                                      required = false, default = nil)
  if valid_402656954 != nil:
    section.add "X-Amz-Security-Token", valid_402656954
  var valid_402656955 = header.getOrDefault("X-Amz-Signature")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Signature", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Algorithm", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Date")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Date", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Credential")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Credential", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656961: Call_GetCreateOptionGroup_402656944;
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

proc call*(call_402656962: Call_GetCreateOptionGroup_402656944;
           OptionGroupName: string; EngineName: string;
           MajorEngineVersion: string; OptionGroupDescription: string;
           Version: string = "2013-09-09"; Tags: JsonNode = nil;
           Action: string = "CreateOptionGroup"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupDescription: string (required)
  var query_402656963 = newJObject()
  add(query_402656963, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656963, "Version", newJString(Version))
  if Tags != nil:
    query_402656963.add "Tags", Tags
  add(query_402656963, "Action", newJString(Action))
  add(query_402656963, "EngineName", newJString(EngineName))
  add(query_402656963, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_402656963, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  result = call_402656962.call(nil, query_402656963, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_402656944(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_402656945, base: "/",
    makeUrl: url_GetCreateOptionGroup_402656946,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_402657003 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBInstance_402657005(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_402657004(path: JsonNode; query: JsonNode;
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
  var valid_402657006 = query.getOrDefault("Version")
  valid_402657006 = validateParameter(valid_402657006, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657006 != nil:
    section.add "Version", valid_402657006
  var valid_402657007 = query.getOrDefault("Action")
  valid_402657007 = validateParameter(valid_402657007, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657015 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657015 = validateParameter(valid_402657015, JString, required = true,
                                      default = nil)
  if valid_402657015 != nil:
    section.add "DBInstanceIdentifier", valid_402657015
  var valid_402657016 = formData.getOrDefault("SkipFinalSnapshot")
  valid_402657016 = validateParameter(valid_402657016, JBool, required = false,
                                      default = nil)
  if valid_402657016 != nil:
    section.add "SkipFinalSnapshot", valid_402657016
  var valid_402657017 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402657017
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657018: Call_PostDeleteDBInstance_402657003;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657018.validator(path, query, header, formData, body, _)
  let scheme = call_402657018.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657018.makeUrl(scheme.get, call_402657018.host, call_402657018.base,
                                   call_402657018.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657018, uri, valid, _)

proc call*(call_402657019: Call_PostDeleteDBInstance_402657003;
           DBInstanceIdentifier: string; Version: string = "2013-09-09";
           SkipFinalSnapshot: bool = false; Action: string = "DeleteDBInstance";
           FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## postDeleteDBInstance
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_402657020 = newJObject()
  var formData_402657021 = newJObject()
  add(query_402657020, "Version", newJString(Version))
  add(formData_402657021, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657021, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_402657020, "Action", newJString(Action))
  add(formData_402657021, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_402657019.call(nil, query_402657020, nil, formData_402657021,
                               nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_402657003(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_402657004, base: "/",
    makeUrl: url_PostDeleteDBInstance_402657005,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_402656985 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBInstance_402656987(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_402656986(path: JsonNode; query: JsonNode;
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
  var valid_402656988 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656988 = validateParameter(valid_402656988, JString, required = true,
                                      default = nil)
  if valid_402656988 != nil:
    section.add "DBInstanceIdentifier", valid_402656988
  var valid_402656989 = query.getOrDefault("Version")
  valid_402656989 = validateParameter(valid_402656989, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402656989 != nil:
    section.add "Version", valid_402656989
  var valid_402656990 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402656990 = validateParameter(valid_402656990, JString,
                                      required = false, default = nil)
  if valid_402656990 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402656990
  var valid_402656991 = query.getOrDefault("Action")
  valid_402656991 = validateParameter(valid_402656991, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
  if valid_402656991 != nil:
    section.add "Action", valid_402656991
  var valid_402656992 = query.getOrDefault("SkipFinalSnapshot")
  valid_402656992 = validateParameter(valid_402656992, JBool, required = false,
                                      default = nil)
  if valid_402656992 != nil:
    section.add "SkipFinalSnapshot", valid_402656992
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
  var valid_402656993 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Security-Token", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Signature")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Signature", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Algorithm", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-Date")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Date", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Credential")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Credential", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656999
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657000: Call_GetDeleteDBInstance_402656985;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657000.validator(path, query, header, formData, body, _)
  let scheme = call_402657000.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657000.makeUrl(scheme.get, call_402657000.host, call_402657000.base,
                                   call_402657000.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657000, uri, valid, _)

proc call*(call_402657001: Call_GetDeleteDBInstance_402656985;
           DBInstanceIdentifier: string; Version: string = "2013-09-09";
           FinalDBSnapshotIdentifier: string = "";
           Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  var query_402657002 = newJObject()
  add(query_402657002, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657002, "Version", newJString(Version))
  add(query_402657002, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_402657002, "Action", newJString(Action))
  add(query_402657002, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_402657001.call(nil, query_402657002, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_402656985(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_402656986, base: "/",
    makeUrl: url_GetDeleteDBInstance_402656987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_402657038 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBParameterGroup_402657040(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_402657039(path: JsonNode;
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
  var valid_402657041 = query.getOrDefault("Version")
  valid_402657041 = validateParameter(valid_402657041, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657041 != nil:
    section.add "Version", valid_402657041
  var valid_402657042 = query.getOrDefault("Action")
  valid_402657042 = validateParameter(valid_402657042, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657042 != nil:
    section.add "Action", valid_402657042
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
  var valid_402657043 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Security-Token", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Signature")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Signature", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-Algorithm", valid_402657046
  var valid_402657047 = header.getOrDefault("X-Amz-Date")
  valid_402657047 = validateParameter(valid_402657047, JString,
                                      required = false, default = nil)
  if valid_402657047 != nil:
    section.add "X-Amz-Date", valid_402657047
  var valid_402657048 = header.getOrDefault("X-Amz-Credential")
  valid_402657048 = validateParameter(valid_402657048, JString,
                                      required = false, default = nil)
  if valid_402657048 != nil:
    section.add "X-Amz-Credential", valid_402657048
  var valid_402657049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657049 = validateParameter(valid_402657049, JString,
                                      required = false, default = nil)
  if valid_402657049 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657049
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657050 = formData.getOrDefault("DBParameterGroupName")
  valid_402657050 = validateParameter(valid_402657050, JString, required = true,
                                      default = nil)
  if valid_402657050 != nil:
    section.add "DBParameterGroupName", valid_402657050
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657051: Call_PostDeleteDBParameterGroup_402657038;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657051.validator(path, query, header, formData, body, _)
  let scheme = call_402657051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657051.makeUrl(scheme.get, call_402657051.host, call_402657051.base,
                                   call_402657051.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657051, uri, valid, _)

proc call*(call_402657052: Call_PostDeleteDBParameterGroup_402657038;
           DBParameterGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## postDeleteDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  var query_402657053 = newJObject()
  var formData_402657054 = newJObject()
  add(query_402657053, "Version", newJString(Version))
  add(formData_402657054, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402657053, "Action", newJString(Action))
  result = call_402657052.call(nil, query_402657053, nil, formData_402657054,
                               nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_402657038(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_402657039, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_402657040,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_402657022 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBParameterGroup_402657024(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_402657023(path: JsonNode;
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
  var valid_402657025 = query.getOrDefault("DBParameterGroupName")
  valid_402657025 = validateParameter(valid_402657025, JString, required = true,
                                      default = nil)
  if valid_402657025 != nil:
    section.add "DBParameterGroupName", valid_402657025
  var valid_402657026 = query.getOrDefault("Version")
  valid_402657026 = validateParameter(valid_402657026, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657026 != nil:
    section.add "Version", valid_402657026
  var valid_402657027 = query.getOrDefault("Action")
  valid_402657027 = validateParameter(valid_402657027, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657027 != nil:
    section.add "Action", valid_402657027
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
  var valid_402657028 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Security-Token", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-Signature")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-Signature", valid_402657029
  var valid_402657030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657030 = validateParameter(valid_402657030, JString,
                                      required = false, default = nil)
  if valid_402657030 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657030
  var valid_402657031 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657031 = validateParameter(valid_402657031, JString,
                                      required = false, default = nil)
  if valid_402657031 != nil:
    section.add "X-Amz-Algorithm", valid_402657031
  var valid_402657032 = header.getOrDefault("X-Amz-Date")
  valid_402657032 = validateParameter(valid_402657032, JString,
                                      required = false, default = nil)
  if valid_402657032 != nil:
    section.add "X-Amz-Date", valid_402657032
  var valid_402657033 = header.getOrDefault("X-Amz-Credential")
  valid_402657033 = validateParameter(valid_402657033, JString,
                                      required = false, default = nil)
  if valid_402657033 != nil:
    section.add "X-Amz-Credential", valid_402657033
  var valid_402657034 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657034 = validateParameter(valid_402657034, JString,
                                      required = false, default = nil)
  if valid_402657034 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657035: Call_GetDeleteDBParameterGroup_402657022;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657035.validator(path, query, header, formData, body, _)
  let scheme = call_402657035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657035.makeUrl(scheme.get, call_402657035.host, call_402657035.base,
                                   call_402657035.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657035, uri, valid, _)

proc call*(call_402657036: Call_GetDeleteDBParameterGroup_402657022;
           DBParameterGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657037 = newJObject()
  add(query_402657037, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657037, "Version", newJString(Version))
  add(query_402657037, "Action", newJString(Action))
  result = call_402657036.call(nil, query_402657037, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_402657022(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_402657023, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_402657024,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_402657071 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSecurityGroup_402657073(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_402657072(path: JsonNode;
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
  var valid_402657074 = query.getOrDefault("Version")
  valid_402657074 = validateParameter(valid_402657074, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657074 != nil:
    section.add "Version", valid_402657074
  var valid_402657075 = query.getOrDefault("Action")
  valid_402657075 = validateParameter(valid_402657075, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657075 != nil:
    section.add "Action", valid_402657075
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
  var valid_402657076 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "X-Amz-Security-Token", valid_402657076
  var valid_402657077 = header.getOrDefault("X-Amz-Signature")
  valid_402657077 = validateParameter(valid_402657077, JString,
                                      required = false, default = nil)
  if valid_402657077 != nil:
    section.add "X-Amz-Signature", valid_402657077
  var valid_402657078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657078 = validateParameter(valid_402657078, JString,
                                      required = false, default = nil)
  if valid_402657078 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657078
  var valid_402657079 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Algorithm", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Date")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Date", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Credential")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Credential", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657082
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402657083 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657083 = validateParameter(valid_402657083, JString, required = true,
                                      default = nil)
  if valid_402657083 != nil:
    section.add "DBSecurityGroupName", valid_402657083
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657084: Call_PostDeleteDBSecurityGroup_402657071;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657084.validator(path, query, header, formData, body, _)
  let scheme = call_402657084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657084.makeUrl(scheme.get, call_402657084.host, call_402657084.base,
                                   call_402657084.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657084, uri, valid, _)

proc call*(call_402657085: Call_PostDeleteDBSecurityGroup_402657071;
           DBSecurityGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402657086 = newJObject()
  var formData_402657087 = newJObject()
  add(query_402657086, "Version", newJString(Version))
  add(formData_402657087, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402657086, "Action", newJString(Action))
  result = call_402657085.call(nil, query_402657086, nil, formData_402657087,
                               nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_402657071(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_402657072, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_402657073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_402657055 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSecurityGroup_402657057(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_402657056(path: JsonNode;
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
  var valid_402657058 = query.getOrDefault("Version")
  valid_402657058 = validateParameter(valid_402657058, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657058 != nil:
    section.add "Version", valid_402657058
  var valid_402657059 = query.getOrDefault("Action")
  valid_402657059 = validateParameter(valid_402657059, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657059 != nil:
    section.add "Action", valid_402657059
  var valid_402657060 = query.getOrDefault("DBSecurityGroupName")
  valid_402657060 = validateParameter(valid_402657060, JString, required = true,
                                      default = nil)
  if valid_402657060 != nil:
    section.add "DBSecurityGroupName", valid_402657060
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
  var valid_402657061 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-Security-Token", valid_402657061
  var valid_402657062 = header.getOrDefault("X-Amz-Signature")
  valid_402657062 = validateParameter(valid_402657062, JString,
                                      required = false, default = nil)
  if valid_402657062 != nil:
    section.add "X-Amz-Signature", valid_402657062
  var valid_402657063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657063 = validateParameter(valid_402657063, JString,
                                      required = false, default = nil)
  if valid_402657063 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657063
  var valid_402657064 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657064 = validateParameter(valid_402657064, JString,
                                      required = false, default = nil)
  if valid_402657064 != nil:
    section.add "X-Amz-Algorithm", valid_402657064
  var valid_402657065 = header.getOrDefault("X-Amz-Date")
  valid_402657065 = validateParameter(valid_402657065, JString,
                                      required = false, default = nil)
  if valid_402657065 != nil:
    section.add "X-Amz-Date", valid_402657065
  var valid_402657066 = header.getOrDefault("X-Amz-Credential")
  valid_402657066 = validateParameter(valid_402657066, JString,
                                      required = false, default = nil)
  if valid_402657066 != nil:
    section.add "X-Amz-Credential", valid_402657066
  var valid_402657067 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657067 = validateParameter(valid_402657067, JString,
                                      required = false, default = nil)
  if valid_402657067 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657068: Call_GetDeleteDBSecurityGroup_402657055;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657068.validator(path, query, header, formData, body, _)
  let scheme = call_402657068.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657068.makeUrl(scheme.get, call_402657068.host, call_402657068.base,
                                   call_402657068.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657068, uri, valid, _)

proc call*(call_402657069: Call_GetDeleteDBSecurityGroup_402657055;
           DBSecurityGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402657070 = newJObject()
  add(query_402657070, "Version", newJString(Version))
  add(query_402657070, "Action", newJString(Action))
  add(query_402657070, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657069.call(nil, query_402657070, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_402657055(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_402657056, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_402657057,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_402657104 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSnapshot_402657106(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_402657105(path: JsonNode; query: JsonNode;
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
  var valid_402657107 = query.getOrDefault("Version")
  valid_402657107 = validateParameter(valid_402657107, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657107 != nil:
    section.add "Version", valid_402657107
  var valid_402657108 = query.getOrDefault("Action")
  valid_402657108 = validateParameter(valid_402657108, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657108 != nil:
    section.add "Action", valid_402657108
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
  var valid_402657109 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657109 = validateParameter(valid_402657109, JString,
                                      required = false, default = nil)
  if valid_402657109 != nil:
    section.add "X-Amz-Security-Token", valid_402657109
  var valid_402657110 = header.getOrDefault("X-Amz-Signature")
  valid_402657110 = validateParameter(valid_402657110, JString,
                                      required = false, default = nil)
  if valid_402657110 != nil:
    section.add "X-Amz-Signature", valid_402657110
  var valid_402657111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657111 = validateParameter(valid_402657111, JString,
                                      required = false, default = nil)
  if valid_402657111 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657111
  var valid_402657112 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657112 = validateParameter(valid_402657112, JString,
                                      required = false, default = nil)
  if valid_402657112 != nil:
    section.add "X-Amz-Algorithm", valid_402657112
  var valid_402657113 = header.getOrDefault("X-Amz-Date")
  valid_402657113 = validateParameter(valid_402657113, JString,
                                      required = false, default = nil)
  if valid_402657113 != nil:
    section.add "X-Amz-Date", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Credential")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Credential", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657115
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_402657116 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657116 = validateParameter(valid_402657116, JString, required = true,
                                      default = nil)
  if valid_402657116 != nil:
    section.add "DBSnapshotIdentifier", valid_402657116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657117: Call_PostDeleteDBSnapshot_402657104;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657117.validator(path, query, header, formData, body, _)
  let scheme = call_402657117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657117.makeUrl(scheme.get, call_402657117.host, call_402657117.base,
                                   call_402657117.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657117, uri, valid, _)

proc call*(call_402657118: Call_PostDeleteDBSnapshot_402657104;
           DBSnapshotIdentifier: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## postDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657119 = newJObject()
  var formData_402657120 = newJObject()
  add(query_402657119, "Version", newJString(Version))
  add(formData_402657120, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402657119, "Action", newJString(Action))
  result = call_402657118.call(nil, query_402657119, nil, formData_402657120,
                               nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_402657104(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_402657105, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_402657106,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_402657088 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSnapshot_402657090(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_402657089(path: JsonNode; query: JsonNode;
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
  var valid_402657091 = query.getOrDefault("Version")
  valid_402657091 = validateParameter(valid_402657091, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657091 != nil:
    section.add "Version", valid_402657091
  var valid_402657092 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true,
                                      default = nil)
  if valid_402657092 != nil:
    section.add "DBSnapshotIdentifier", valid_402657092
  var valid_402657093 = query.getOrDefault("Action")
  valid_402657093 = validateParameter(valid_402657093, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657093 != nil:
    section.add "Action", valid_402657093
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
  var valid_402657094 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657094 = validateParameter(valid_402657094, JString,
                                      required = false, default = nil)
  if valid_402657094 != nil:
    section.add "X-Amz-Security-Token", valid_402657094
  var valid_402657095 = header.getOrDefault("X-Amz-Signature")
  valid_402657095 = validateParameter(valid_402657095, JString,
                                      required = false, default = nil)
  if valid_402657095 != nil:
    section.add "X-Amz-Signature", valid_402657095
  var valid_402657096 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657096 = validateParameter(valid_402657096, JString,
                                      required = false, default = nil)
  if valid_402657096 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657096
  var valid_402657097 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657097 = validateParameter(valid_402657097, JString,
                                      required = false, default = nil)
  if valid_402657097 != nil:
    section.add "X-Amz-Algorithm", valid_402657097
  var valid_402657098 = header.getOrDefault("X-Amz-Date")
  valid_402657098 = validateParameter(valid_402657098, JString,
                                      required = false, default = nil)
  if valid_402657098 != nil:
    section.add "X-Amz-Date", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Credential")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Credential", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657100
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657101: Call_GetDeleteDBSnapshot_402657088;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657101.validator(path, query, header, formData, body, _)
  let scheme = call_402657101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657101.makeUrl(scheme.get, call_402657101.host, call_402657101.base,
                                   call_402657101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657101, uri, valid, _)

proc call*(call_402657102: Call_GetDeleteDBSnapshot_402657088;
           DBSnapshotIdentifier: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## getDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657103 = newJObject()
  add(query_402657103, "Version", newJString(Version))
  add(query_402657103, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657103, "Action", newJString(Action))
  result = call_402657102.call(nil, query_402657103, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_402657088(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_402657089, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_402657090,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_402657137 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSubnetGroup_402657139(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_402657138(path: JsonNode; query: JsonNode;
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
  var valid_402657140 = query.getOrDefault("Version")
  valid_402657140 = validateParameter(valid_402657140, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657140 != nil:
    section.add "Version", valid_402657140
  var valid_402657141 = query.getOrDefault("Action")
  valid_402657141 = validateParameter(valid_402657141, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657141 != nil:
    section.add "Action", valid_402657141
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
  var valid_402657142 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657142 = validateParameter(valid_402657142, JString,
                                      required = false, default = nil)
  if valid_402657142 != nil:
    section.add "X-Amz-Security-Token", valid_402657142
  var valid_402657143 = header.getOrDefault("X-Amz-Signature")
  valid_402657143 = validateParameter(valid_402657143, JString,
                                      required = false, default = nil)
  if valid_402657143 != nil:
    section.add "X-Amz-Signature", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Algorithm", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-Date")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-Date", valid_402657146
  var valid_402657147 = header.getOrDefault("X-Amz-Credential")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Credential", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657148
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402657149 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657149 = validateParameter(valid_402657149, JString, required = true,
                                      default = nil)
  if valid_402657149 != nil:
    section.add "DBSubnetGroupName", valid_402657149
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657150: Call_PostDeleteDBSubnetGroup_402657137;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657150.validator(path, query, header, formData, body, _)
  let scheme = call_402657150.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657150.makeUrl(scheme.get, call_402657150.host, call_402657150.base,
                                   call_402657150.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657150, uri, valid, _)

proc call*(call_402657151: Call_PostDeleteDBSubnetGroup_402657137;
           DBSubnetGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657152 = newJObject()
  var formData_402657153 = newJObject()
  add(formData_402657153, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657152, "Version", newJString(Version))
  add(query_402657152, "Action", newJString(Action))
  result = call_402657151.call(nil, query_402657152, nil, formData_402657153,
                               nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_402657137(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_402657138, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_402657139,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_402657121 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSubnetGroup_402657123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_402657122(path: JsonNode; query: JsonNode;
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
  var valid_402657124 = query.getOrDefault("DBSubnetGroupName")
  valid_402657124 = validateParameter(valid_402657124, JString, required = true,
                                      default = nil)
  if valid_402657124 != nil:
    section.add "DBSubnetGroupName", valid_402657124
  var valid_402657125 = query.getOrDefault("Version")
  valid_402657125 = validateParameter(valid_402657125, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657125 != nil:
    section.add "Version", valid_402657125
  var valid_402657126 = query.getOrDefault("Action")
  valid_402657126 = validateParameter(valid_402657126, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657126 != nil:
    section.add "Action", valid_402657126
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
  var valid_402657127 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657127 = validateParameter(valid_402657127, JString,
                                      required = false, default = nil)
  if valid_402657127 != nil:
    section.add "X-Amz-Security-Token", valid_402657127
  var valid_402657128 = header.getOrDefault("X-Amz-Signature")
  valid_402657128 = validateParameter(valid_402657128, JString,
                                      required = false, default = nil)
  if valid_402657128 != nil:
    section.add "X-Amz-Signature", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Algorithm", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Date")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Date", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Credential")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Credential", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657134: Call_GetDeleteDBSubnetGroup_402657121;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657134.validator(path, query, header, formData, body, _)
  let scheme = call_402657134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657134.makeUrl(scheme.get, call_402657134.host, call_402657134.base,
                                   call_402657134.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657134, uri, valid, _)

proc call*(call_402657135: Call_GetDeleteDBSubnetGroup_402657121;
           DBSubnetGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657136 = newJObject()
  add(query_402657136, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657136, "Version", newJString(Version))
  add(query_402657136, "Action", newJString(Action))
  result = call_402657135.call(nil, query_402657136, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_402657121(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_402657122, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_402657123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_402657170 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteEventSubscription_402657172(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_402657171(path: JsonNode;
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
  var valid_402657173 = query.getOrDefault("Version")
  valid_402657173 = validateParameter(valid_402657173, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657173 != nil:
    section.add "Version", valid_402657173
  var valid_402657174 = query.getOrDefault("Action")
  valid_402657174 = validateParameter(valid_402657174, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657174 != nil:
    section.add "Action", valid_402657174
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
  var valid_402657175 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Security-Token", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Signature")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Signature", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Algorithm", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-Date")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-Date", valid_402657179
  var valid_402657180 = header.getOrDefault("X-Amz-Credential")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-Credential", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657181
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402657182 = formData.getOrDefault("SubscriptionName")
  valid_402657182 = validateParameter(valid_402657182, JString, required = true,
                                      default = nil)
  if valid_402657182 != nil:
    section.add "SubscriptionName", valid_402657182
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657183: Call_PostDeleteEventSubscription_402657170;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657183.validator(path, query, header, formData, body, _)
  let scheme = call_402657183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657183.makeUrl(scheme.get, call_402657183.host, call_402657183.base,
                                   call_402657183.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657183, uri, valid, _)

proc call*(call_402657184: Call_PostDeleteEventSubscription_402657170;
           SubscriptionName: string; Version: string = "2013-09-09";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## postDeleteEventSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402657185 = newJObject()
  var formData_402657186 = newJObject()
  add(query_402657185, "Version", newJString(Version))
  add(query_402657185, "Action", newJString(Action))
  add(formData_402657186, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657184.call(nil, query_402657185, nil, formData_402657186,
                               nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_402657170(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_402657171, base: "/",
    makeUrl: url_PostDeleteEventSubscription_402657172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_402657154 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteEventSubscription_402657156(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_402657155(path: JsonNode;
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
  var valid_402657157 = query.getOrDefault("Version")
  valid_402657157 = validateParameter(valid_402657157, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657157 != nil:
    section.add "Version", valid_402657157
  var valid_402657158 = query.getOrDefault("SubscriptionName")
  valid_402657158 = validateParameter(valid_402657158, JString, required = true,
                                      default = nil)
  if valid_402657158 != nil:
    section.add "SubscriptionName", valid_402657158
  var valid_402657159 = query.getOrDefault("Action")
  valid_402657159 = validateParameter(valid_402657159, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657159 != nil:
    section.add "Action", valid_402657159
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
  var valid_402657160 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Security-Token", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Signature")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Signature", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657162
  var valid_402657163 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "X-Amz-Algorithm", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Date")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Date", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Credential")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Credential", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657166
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657167: Call_GetDeleteEventSubscription_402657154;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657167.validator(path, query, header, formData, body, _)
  let scheme = call_402657167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657167.makeUrl(scheme.get, call_402657167.host, call_402657167.base,
                                   call_402657167.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657167, uri, valid, _)

proc call*(call_402657168: Call_GetDeleteEventSubscription_402657154;
           SubscriptionName: string; Version: string = "2013-09-09";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## getDeleteEventSubscription
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402657169 = newJObject()
  add(query_402657169, "Version", newJString(Version))
  add(query_402657169, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657169, "Action", newJString(Action))
  result = call_402657168.call(nil, query_402657169, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_402657154(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_402657155, base: "/",
    makeUrl: url_GetDeleteEventSubscription_402657156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_402657203 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteOptionGroup_402657205(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_402657204(path: JsonNode; query: JsonNode;
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
  var valid_402657206 = query.getOrDefault("Version")
  valid_402657206 = validateParameter(valid_402657206, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657206 != nil:
    section.add "Version", valid_402657206
  var valid_402657207 = query.getOrDefault("Action")
  valid_402657207 = validateParameter(valid_402657207, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657207 != nil:
    section.add "Action", valid_402657207
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
  var valid_402657208 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "X-Amz-Security-Token", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Signature")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Signature", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657210
  var valid_402657211 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657211 = validateParameter(valid_402657211, JString,
                                      required = false, default = nil)
  if valid_402657211 != nil:
    section.add "X-Amz-Algorithm", valid_402657211
  var valid_402657212 = header.getOrDefault("X-Amz-Date")
  valid_402657212 = validateParameter(valid_402657212, JString,
                                      required = false, default = nil)
  if valid_402657212 != nil:
    section.add "X-Amz-Date", valid_402657212
  var valid_402657213 = header.getOrDefault("X-Amz-Credential")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Credential", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657214
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402657215 = formData.getOrDefault("OptionGroupName")
  valid_402657215 = validateParameter(valid_402657215, JString, required = true,
                                      default = nil)
  if valid_402657215 != nil:
    section.add "OptionGroupName", valid_402657215
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657216: Call_PostDeleteOptionGroup_402657203;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657216.validator(path, query, header, formData, body, _)
  let scheme = call_402657216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657216.makeUrl(scheme.get, call_402657216.host, call_402657216.base,
                                   call_402657216.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657216, uri, valid, _)

proc call*(call_402657217: Call_PostDeleteOptionGroup_402657203;
           OptionGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## postDeleteOptionGroup
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402657218 = newJObject()
  var formData_402657219 = newJObject()
  add(query_402657218, "Version", newJString(Version))
  add(formData_402657219, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657218, "Action", newJString(Action))
  result = call_402657217.call(nil, query_402657218, nil, formData_402657219,
                               nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_402657203(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_402657204, base: "/",
    makeUrl: url_PostDeleteOptionGroup_402657205,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_402657187 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteOptionGroup_402657189(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_402657188(path: JsonNode; query: JsonNode;
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
  var valid_402657190 = query.getOrDefault("OptionGroupName")
  valid_402657190 = validateParameter(valid_402657190, JString, required = true,
                                      default = nil)
  if valid_402657190 != nil:
    section.add "OptionGroupName", valid_402657190
  var valid_402657191 = query.getOrDefault("Version")
  valid_402657191 = validateParameter(valid_402657191, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657191 != nil:
    section.add "Version", valid_402657191
  var valid_402657192 = query.getOrDefault("Action")
  valid_402657192 = validateParameter(valid_402657192, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657192 != nil:
    section.add "Action", valid_402657192
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
  var valid_402657193 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Security-Token", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-Signature")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Signature", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657195
  var valid_402657196 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "X-Amz-Algorithm", valid_402657196
  var valid_402657197 = header.getOrDefault("X-Amz-Date")
  valid_402657197 = validateParameter(valid_402657197, JString,
                                      required = false, default = nil)
  if valid_402657197 != nil:
    section.add "X-Amz-Date", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Credential")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Credential", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657199
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657200: Call_GetDeleteOptionGroup_402657187;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657200.validator(path, query, header, formData, body, _)
  let scheme = call_402657200.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657200.makeUrl(scheme.get, call_402657200.host, call_402657200.base,
                                   call_402657200.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657200, uri, valid, _)

proc call*(call_402657201: Call_GetDeleteOptionGroup_402657187;
           OptionGroupName: string; Version: string = "2013-09-09";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657202 = newJObject()
  add(query_402657202, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657202, "Version", newJString(Version))
  add(query_402657202, "Action", newJString(Action))
  result = call_402657201.call(nil, query_402657202, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_402657187(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_402657188, base: "/",
    makeUrl: url_GetDeleteOptionGroup_402657189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_402657243 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBEngineVersions_402657245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_402657244(path: JsonNode;
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
  var valid_402657246 = query.getOrDefault("Version")
  valid_402657246 = validateParameter(valid_402657246, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657246 != nil:
    section.add "Version", valid_402657246
  var valid_402657247 = query.getOrDefault("Action")
  valid_402657247 = validateParameter(valid_402657247, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657247 != nil:
    section.add "Action", valid_402657247
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
  var valid_402657248 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Security-Token", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-Signature")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-Signature", valid_402657249
  var valid_402657250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657250
  var valid_402657251 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657251 = validateParameter(valid_402657251, JString,
                                      required = false, default = nil)
  if valid_402657251 != nil:
    section.add "X-Amz-Algorithm", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-Date")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-Date", valid_402657252
  var valid_402657253 = header.getOrDefault("X-Amz-Credential")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-Credential", valid_402657253
  var valid_402657254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657254 = validateParameter(valid_402657254, JString,
                                      required = false, default = nil)
  if valid_402657254 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657254
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DefaultOnly: JBool
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   DBParameterGroupFamily: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   EngineVersion: JString
  section = newJObject()
  var valid_402657255 = formData.getOrDefault("Marker")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "Marker", valid_402657255
  var valid_402657256 = formData.getOrDefault("DefaultOnly")
  valid_402657256 = validateParameter(valid_402657256, JBool, required = false,
                                      default = nil)
  if valid_402657256 != nil:
    section.add "DefaultOnly", valid_402657256
  var valid_402657257 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_402657257 = validateParameter(valid_402657257, JBool, required = false,
                                      default = nil)
  if valid_402657257 != nil:
    section.add "ListSupportedCharacterSets", valid_402657257
  var valid_402657258 = formData.getOrDefault("Engine")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "Engine", valid_402657258
  var valid_402657259 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657259 = validateParameter(valid_402657259, JString,
                                      required = false, default = nil)
  if valid_402657259 != nil:
    section.add "DBParameterGroupFamily", valid_402657259
  var valid_402657260 = formData.getOrDefault("MaxRecords")
  valid_402657260 = validateParameter(valid_402657260, JInt, required = false,
                                      default = nil)
  if valid_402657260 != nil:
    section.add "MaxRecords", valid_402657260
  var valid_402657261 = formData.getOrDefault("Filters")
  valid_402657261 = validateParameter(valid_402657261, JArray, required = false,
                                      default = nil)
  if valid_402657261 != nil:
    section.add "Filters", valid_402657261
  var valid_402657262 = formData.getOrDefault("EngineVersion")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "EngineVersion", valid_402657262
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657263: Call_PostDescribeDBEngineVersions_402657243;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657263.validator(path, query, header, formData, body, _)
  let scheme = call_402657263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657263.makeUrl(scheme.get, call_402657263.host, call_402657263.base,
                                   call_402657263.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657263, uri, valid, _)

proc call*(call_402657264: Call_PostDescribeDBEngineVersions_402657243;
           Marker: string = ""; DefaultOnly: bool = false;
           ListSupportedCharacterSets: bool = false; Engine: string = "";
           DBParameterGroupFamily: string = ""; Version: string = "2013-09-09";
           MaxRecords: int = 0; Action: string = "DescribeDBEngineVersions";
           Filters: JsonNode = nil; EngineVersion: string = ""): Recallable =
  ## postDescribeDBEngineVersions
  ##   Marker: string
  ##   DefaultOnly: bool
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   DBParameterGroupFamily: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   EngineVersion: string
  var query_402657265 = newJObject()
  var formData_402657266 = newJObject()
  add(formData_402657266, "Marker", newJString(Marker))
  add(formData_402657266, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_402657266, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_402657266, "Engine", newJString(Engine))
  add(formData_402657266, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657265, "Version", newJString(Version))
  add(formData_402657266, "MaxRecords", newJInt(MaxRecords))
  add(query_402657265, "Action", newJString(Action))
  if Filters != nil:
    formData_402657266.add "Filters", Filters
  add(formData_402657266, "EngineVersion", newJString(EngineVersion))
  result = call_402657264.call(nil, query_402657265, nil, formData_402657266,
                               nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_402657243(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_402657244, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_402657245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_402657220 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBEngineVersions_402657222(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_402657221(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
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
  var valid_402657223 = query.getOrDefault("Filters")
  valid_402657223 = validateParameter(valid_402657223, JArray, required = false,
                                      default = nil)
  if valid_402657223 != nil:
    section.add "Filters", valid_402657223
  var valid_402657224 = query.getOrDefault("DefaultOnly")
  valid_402657224 = validateParameter(valid_402657224, JBool, required = false,
                                      default = nil)
  if valid_402657224 != nil:
    section.add "DefaultOnly", valid_402657224
  var valid_402657225 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "DBParameterGroupFamily", valid_402657225
  var valid_402657226 = query.getOrDefault("MaxRecords")
  valid_402657226 = validateParameter(valid_402657226, JInt, required = false,
                                      default = nil)
  if valid_402657226 != nil:
    section.add "MaxRecords", valid_402657226
  var valid_402657227 = query.getOrDefault("Marker")
  valid_402657227 = validateParameter(valid_402657227, JString,
                                      required = false, default = nil)
  if valid_402657227 != nil:
    section.add "Marker", valid_402657227
  var valid_402657228 = query.getOrDefault("Version")
  valid_402657228 = validateParameter(valid_402657228, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657228 != nil:
    section.add "Version", valid_402657228
  var valid_402657229 = query.getOrDefault("EngineVersion")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "EngineVersion", valid_402657229
  var valid_402657230 = query.getOrDefault("Engine")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "Engine", valid_402657230
  var valid_402657231 = query.getOrDefault("Action")
  valid_402657231 = validateParameter(valid_402657231, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657231 != nil:
    section.add "Action", valid_402657231
  var valid_402657232 = query.getOrDefault("ListSupportedCharacterSets")
  valid_402657232 = validateParameter(valid_402657232, JBool, required = false,
                                      default = nil)
  if valid_402657232 != nil:
    section.add "ListSupportedCharacterSets", valid_402657232
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
  var valid_402657233 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Security-Token", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-Signature")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-Signature", valid_402657234
  var valid_402657235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657235 = validateParameter(valid_402657235, JString,
                                      required = false, default = nil)
  if valid_402657235 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657235
  var valid_402657236 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657236 = validateParameter(valid_402657236, JString,
                                      required = false, default = nil)
  if valid_402657236 != nil:
    section.add "X-Amz-Algorithm", valid_402657236
  var valid_402657237 = header.getOrDefault("X-Amz-Date")
  valid_402657237 = validateParameter(valid_402657237, JString,
                                      required = false, default = nil)
  if valid_402657237 != nil:
    section.add "X-Amz-Date", valid_402657237
  var valid_402657238 = header.getOrDefault("X-Amz-Credential")
  valid_402657238 = validateParameter(valid_402657238, JString,
                                      required = false, default = nil)
  if valid_402657238 != nil:
    section.add "X-Amz-Credential", valid_402657238
  var valid_402657239 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657239 = validateParameter(valid_402657239, JString,
                                      required = false, default = nil)
  if valid_402657239 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657240: Call_GetDescribeDBEngineVersions_402657220;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657240.validator(path, query, header, formData, body, _)
  let scheme = call_402657240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657240.makeUrl(scheme.get, call_402657240.host, call_402657240.base,
                                   call_402657240.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657240, uri, valid, _)

proc call*(call_402657241: Call_GetDescribeDBEngineVersions_402657220;
           Filters: JsonNode = nil; DefaultOnly: bool = false;
           DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-09-09";
           EngineVersion: string = ""; Engine: string = "";
           Action: string = "DescribeDBEngineVersions";
           ListSupportedCharacterSets: bool = false): Recallable =
  ## getDescribeDBEngineVersions
  ##   Filters: JArray
  ##   DefaultOnly: bool
  ##   DBParameterGroupFamily: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineVersion: string
  ##   Engine: string
  ##   Action: string (required)
  ##   ListSupportedCharacterSets: bool
  var query_402657242 = newJObject()
  if Filters != nil:
    query_402657242.add "Filters", Filters
  add(query_402657242, "DefaultOnly", newJBool(DefaultOnly))
  add(query_402657242, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657242, "MaxRecords", newJInt(MaxRecords))
  add(query_402657242, "Marker", newJString(Marker))
  add(query_402657242, "Version", newJString(Version))
  add(query_402657242, "EngineVersion", newJString(EngineVersion))
  add(query_402657242, "Engine", newJString(Engine))
  add(query_402657242, "Action", newJString(Action))
  add(query_402657242, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  result = call_402657241.call(nil, query_402657242, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_402657220(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_402657221, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_402657222,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_402657286 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBInstances_402657288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_402657287(path: JsonNode; query: JsonNode;
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
  var valid_402657289 = query.getOrDefault("Version")
  valid_402657289 = validateParameter(valid_402657289, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657289 != nil:
    section.add "Version", valid_402657289
  var valid_402657290 = query.getOrDefault("Action")
  valid_402657290 = validateParameter(valid_402657290, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657290 != nil:
    section.add "Action", valid_402657290
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
  var valid_402657291 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657291 = validateParameter(valid_402657291, JString,
                                      required = false, default = nil)
  if valid_402657291 != nil:
    section.add "X-Amz-Security-Token", valid_402657291
  var valid_402657292 = header.getOrDefault("X-Amz-Signature")
  valid_402657292 = validateParameter(valid_402657292, JString,
                                      required = false, default = nil)
  if valid_402657292 != nil:
    section.add "X-Amz-Signature", valid_402657292
  var valid_402657293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657293 = validateParameter(valid_402657293, JString,
                                      required = false, default = nil)
  if valid_402657293 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657293
  var valid_402657294 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Algorithm", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Date")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Date", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Credential")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Credential", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657297
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657298 = formData.getOrDefault("Marker")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "Marker", valid_402657298
  var valid_402657299 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "DBInstanceIdentifier", valid_402657299
  var valid_402657300 = formData.getOrDefault("MaxRecords")
  valid_402657300 = validateParameter(valid_402657300, JInt, required = false,
                                      default = nil)
  if valid_402657300 != nil:
    section.add "MaxRecords", valid_402657300
  var valid_402657301 = formData.getOrDefault("Filters")
  valid_402657301 = validateParameter(valid_402657301, JArray, required = false,
                                      default = nil)
  if valid_402657301 != nil:
    section.add "Filters", valid_402657301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657302: Call_PostDescribeDBInstances_402657286;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657302.validator(path, query, header, formData, body, _)
  let scheme = call_402657302.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657302.makeUrl(scheme.get, call_402657302.host, call_402657302.base,
                                   call_402657302.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657302, uri, valid, _)

proc call*(call_402657303: Call_PostDescribeDBInstances_402657286;
           Marker: string = ""; Version: string = "2013-09-09";
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBInstances"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBInstances
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657304 = newJObject()
  var formData_402657305 = newJObject()
  add(formData_402657305, "Marker", newJString(Marker))
  add(query_402657304, "Version", newJString(Version))
  add(formData_402657305, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657305, "MaxRecords", newJInt(MaxRecords))
  add(query_402657304, "Action", newJString(Action))
  if Filters != nil:
    formData_402657305.add "Filters", Filters
  result = call_402657303.call(nil, query_402657304, nil, formData_402657305,
                               nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_402657286(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_402657287, base: "/",
    makeUrl: url_PostDescribeDBInstances_402657288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_402657267 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBInstances_402657269(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_402657268(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657270 = query.getOrDefault("Filters")
  valid_402657270 = validateParameter(valid_402657270, JArray, required = false,
                                      default = nil)
  if valid_402657270 != nil:
    section.add "Filters", valid_402657270
  var valid_402657271 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657271 = validateParameter(valid_402657271, JString,
                                      required = false, default = nil)
  if valid_402657271 != nil:
    section.add "DBInstanceIdentifier", valid_402657271
  var valid_402657272 = query.getOrDefault("MaxRecords")
  valid_402657272 = validateParameter(valid_402657272, JInt, required = false,
                                      default = nil)
  if valid_402657272 != nil:
    section.add "MaxRecords", valid_402657272
  var valid_402657273 = query.getOrDefault("Marker")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "Marker", valid_402657273
  var valid_402657274 = query.getOrDefault("Version")
  valid_402657274 = validateParameter(valid_402657274, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657274 != nil:
    section.add "Version", valid_402657274
  var valid_402657275 = query.getOrDefault("Action")
  valid_402657275 = validateParameter(valid_402657275, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657275 != nil:
    section.add "Action", valid_402657275
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
  var valid_402657276 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657276 = validateParameter(valid_402657276, JString,
                                      required = false, default = nil)
  if valid_402657276 != nil:
    section.add "X-Amz-Security-Token", valid_402657276
  var valid_402657277 = header.getOrDefault("X-Amz-Signature")
  valid_402657277 = validateParameter(valid_402657277, JString,
                                      required = false, default = nil)
  if valid_402657277 != nil:
    section.add "X-Amz-Signature", valid_402657277
  var valid_402657278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657278 = validateParameter(valid_402657278, JString,
                                      required = false, default = nil)
  if valid_402657278 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657278
  var valid_402657279 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Algorithm", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Date")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Date", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Credential")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Credential", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657283: Call_GetDescribeDBInstances_402657267;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657283.validator(path, query, header, formData, body, _)
  let scheme = call_402657283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657283.makeUrl(scheme.get, call_402657283.host, call_402657283.base,
                                   call_402657283.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657283, uri, valid, _)

proc call*(call_402657284: Call_GetDescribeDBInstances_402657267;
           Filters: JsonNode = nil; DBInstanceIdentifier: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeDBInstances"): Recallable =
  ## getDescribeDBInstances
  ##   Filters: JArray
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657285 = newJObject()
  if Filters != nil:
    query_402657285.add "Filters", Filters
  add(query_402657285, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657285, "MaxRecords", newJInt(MaxRecords))
  add(query_402657285, "Marker", newJString(Marker))
  add(query_402657285, "Version", newJString(Version))
  add(query_402657285, "Action", newJString(Action))
  result = call_402657284.call(nil, query_402657285, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_402657267(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_402657268, base: "/",
    makeUrl: url_GetDescribeDBInstances_402657269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_402657328 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBLogFiles_402657330(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_402657329(path: JsonNode; query: JsonNode;
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
  var valid_402657331 = query.getOrDefault("Version")
  valid_402657331 = validateParameter(valid_402657331, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657331 != nil:
    section.add "Version", valid_402657331
  var valid_402657332 = query.getOrDefault("Action")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
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
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   FilenameContains: JString
  ##   FileLastWritten: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   MaxRecords: JInt
  ##   FileSize: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657340 = formData.getOrDefault("Marker")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "Marker", valid_402657340
  var valid_402657341 = formData.getOrDefault("FilenameContains")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "FilenameContains", valid_402657341
  var valid_402657342 = formData.getOrDefault("FileLastWritten")
  valid_402657342 = validateParameter(valid_402657342, JInt, required = false,
                                      default = nil)
  if valid_402657342 != nil:
    section.add "FileLastWritten", valid_402657342
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657343 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657343 = validateParameter(valid_402657343, JString, required = true,
                                      default = nil)
  if valid_402657343 != nil:
    section.add "DBInstanceIdentifier", valid_402657343
  var valid_402657344 = formData.getOrDefault("MaxRecords")
  valid_402657344 = validateParameter(valid_402657344, JInt, required = false,
                                      default = nil)
  if valid_402657344 != nil:
    section.add "MaxRecords", valid_402657344
  var valid_402657345 = formData.getOrDefault("FileSize")
  valid_402657345 = validateParameter(valid_402657345, JInt, required = false,
                                      default = nil)
  if valid_402657345 != nil:
    section.add "FileSize", valid_402657345
  var valid_402657346 = formData.getOrDefault("Filters")
  valid_402657346 = validateParameter(valid_402657346, JArray, required = false,
                                      default = nil)
  if valid_402657346 != nil:
    section.add "Filters", valid_402657346
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657347: Call_PostDescribeDBLogFiles_402657328;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657347.validator(path, query, header, formData, body, _)
  let scheme = call_402657347.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657347.makeUrl(scheme.get, call_402657347.host, call_402657347.base,
                                   call_402657347.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657347, uri, valid, _)

proc call*(call_402657348: Call_PostDescribeDBLogFiles_402657328;
           DBInstanceIdentifier: string; Marker: string = "";
           FilenameContains: string = ""; FileLastWritten: int = 0;
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           FileSize: int = 0; Action: string = "DescribeDBLogFiles";
           Filters: JsonNode = nil): Recallable =
  ## postDescribeDBLogFiles
  ##   Marker: string
  ##   FilenameContains: string
  ##   FileLastWritten: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MaxRecords: int
  ##   FileSize: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657349 = newJObject()
  var formData_402657350 = newJObject()
  add(formData_402657350, "Marker", newJString(Marker))
  add(formData_402657350, "FilenameContains", newJString(FilenameContains))
  add(formData_402657350, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657349, "Version", newJString(Version))
  add(formData_402657350, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657350, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657350, "FileSize", newJInt(FileSize))
  add(query_402657349, "Action", newJString(Action))
  if Filters != nil:
    formData_402657350.add "Filters", Filters
  result = call_402657348.call(nil, query_402657349, nil, formData_402657350,
                               nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_402657328(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_402657329, base: "/",
    makeUrl: url_PostDescribeDBLogFiles_402657330,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_402657306 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBLogFiles_402657308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_402657307(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  ##   FilenameContains: JString
  ##   Marker: JString
  ##   FileSize: JInt
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657309 = query.getOrDefault("Filters")
  valid_402657309 = validateParameter(valid_402657309, JArray, required = false,
                                      default = nil)
  if valid_402657309 != nil:
    section.add "Filters", valid_402657309
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657310 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657310 = validateParameter(valid_402657310, JString, required = true,
                                      default = nil)
  if valid_402657310 != nil:
    section.add "DBInstanceIdentifier", valid_402657310
  var valid_402657311 = query.getOrDefault("MaxRecords")
  valid_402657311 = validateParameter(valid_402657311, JInt, required = false,
                                      default = nil)
  if valid_402657311 != nil:
    section.add "MaxRecords", valid_402657311
  var valid_402657312 = query.getOrDefault("FileLastWritten")
  valid_402657312 = validateParameter(valid_402657312, JInt, required = false,
                                      default = nil)
  if valid_402657312 != nil:
    section.add "FileLastWritten", valid_402657312
  var valid_402657313 = query.getOrDefault("FilenameContains")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "FilenameContains", valid_402657313
  var valid_402657314 = query.getOrDefault("Marker")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "Marker", valid_402657314
  var valid_402657315 = query.getOrDefault("FileSize")
  valid_402657315 = validateParameter(valid_402657315, JInt, required = false,
                                      default = nil)
  if valid_402657315 != nil:
    section.add "FileSize", valid_402657315
  var valid_402657316 = query.getOrDefault("Version")
  valid_402657316 = validateParameter(valid_402657316, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657316 != nil:
    section.add "Version", valid_402657316
  var valid_402657317 = query.getOrDefault("Action")
  valid_402657317 = validateParameter(valid_402657317, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
  if valid_402657317 != nil:
    section.add "Action", valid_402657317
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
  var valid_402657318 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-Security-Token", valid_402657318
  var valid_402657319 = header.getOrDefault("X-Amz-Signature")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Signature", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Algorithm", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Date")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Date", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Credential")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Credential", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657324
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657325: Call_GetDescribeDBLogFiles_402657306;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657325.validator(path, query, header, formData, body, _)
  let scheme = call_402657325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657325.makeUrl(scheme.get, call_402657325.host, call_402657325.base,
                                   call_402657325.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657325, uri, valid, _)

proc call*(call_402657326: Call_GetDescribeDBLogFiles_402657306;
           DBInstanceIdentifier: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; FileLastWritten: int = 0;
           FilenameContains: string = ""; Marker: string = "";
           FileSize: int = 0; Version: string = "2013-09-09";
           Action: string = "DescribeDBLogFiles"): Recallable =
  ## getDescribeDBLogFiles
  ##   Filters: JArray
  ##   DBInstanceIdentifier: string (required)
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   FilenameContains: string
  ##   Marker: string
  ##   FileSize: int
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657327 = newJObject()
  if Filters != nil:
    query_402657327.add "Filters", Filters
  add(query_402657327, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657327, "MaxRecords", newJInt(MaxRecords))
  add(query_402657327, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657327, "FilenameContains", newJString(FilenameContains))
  add(query_402657327, "Marker", newJString(Marker))
  add(query_402657327, "FileSize", newJInt(FileSize))
  add(query_402657327, "Version", newJString(Version))
  add(query_402657327, "Action", newJString(Action))
  result = call_402657326.call(nil, query_402657327, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_402657306(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_402657307, base: "/",
    makeUrl: url_GetDescribeDBLogFiles_402657308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_402657370 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameterGroups_402657372(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_402657371(path: JsonNode;
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
  var valid_402657373 = query.getOrDefault("Version")
  valid_402657373 = validateParameter(valid_402657373, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657373 != nil:
    section.add "Version", valid_402657373
  var valid_402657374 = query.getOrDefault("Action")
  valid_402657374 = validateParameter(valid_402657374, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657374 != nil:
    section.add "Action", valid_402657374
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
  var valid_402657375 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-Security-Token", valid_402657375
  var valid_402657376 = header.getOrDefault("X-Amz-Signature")
  valid_402657376 = validateParameter(valid_402657376, JString,
                                      required = false, default = nil)
  if valid_402657376 != nil:
    section.add "X-Amz-Signature", valid_402657376
  var valid_402657377 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Algorithm", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-Date")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Date", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-Credential")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-Credential", valid_402657380
  var valid_402657381 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657381
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657382 = formData.getOrDefault("Marker")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "Marker", valid_402657382
  var valid_402657383 = formData.getOrDefault("DBParameterGroupName")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "DBParameterGroupName", valid_402657383
  var valid_402657384 = formData.getOrDefault("MaxRecords")
  valid_402657384 = validateParameter(valid_402657384, JInt, required = false,
                                      default = nil)
  if valid_402657384 != nil:
    section.add "MaxRecords", valid_402657384
  var valid_402657385 = formData.getOrDefault("Filters")
  valid_402657385 = validateParameter(valid_402657385, JArray, required = false,
                                      default = nil)
  if valid_402657385 != nil:
    section.add "Filters", valid_402657385
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657386: Call_PostDescribeDBParameterGroups_402657370;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657386.validator(path, query, header, formData, body, _)
  let scheme = call_402657386.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657386.makeUrl(scheme.get, call_402657386.host, call_402657386.base,
                                   call_402657386.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657386, uri, valid, _)

proc call*(call_402657387: Call_PostDescribeDBParameterGroups_402657370;
           Marker: string = ""; Version: string = "2013-09-09";
           DBParameterGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBParameterGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657388 = newJObject()
  var formData_402657389 = newJObject()
  add(formData_402657389, "Marker", newJString(Marker))
  add(query_402657388, "Version", newJString(Version))
  add(formData_402657389, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657389, "MaxRecords", newJInt(MaxRecords))
  add(query_402657388, "Action", newJString(Action))
  if Filters != nil:
    formData_402657389.add "Filters", Filters
  result = call_402657387.call(nil, query_402657388, nil, formData_402657389,
                               nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_402657370(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_402657371, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_402657372,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_402657351 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameterGroups_402657353(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_402657352(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBParameterGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657354 = query.getOrDefault("Filters")
  valid_402657354 = validateParameter(valid_402657354, JArray, required = false,
                                      default = nil)
  if valid_402657354 != nil:
    section.add "Filters", valid_402657354
  var valid_402657355 = query.getOrDefault("DBParameterGroupName")
  valid_402657355 = validateParameter(valid_402657355, JString,
                                      required = false, default = nil)
  if valid_402657355 != nil:
    section.add "DBParameterGroupName", valid_402657355
  var valid_402657356 = query.getOrDefault("MaxRecords")
  valid_402657356 = validateParameter(valid_402657356, JInt, required = false,
                                      default = nil)
  if valid_402657356 != nil:
    section.add "MaxRecords", valid_402657356
  var valid_402657357 = query.getOrDefault("Marker")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "Marker", valid_402657357
  var valid_402657358 = query.getOrDefault("Version")
  valid_402657358 = validateParameter(valid_402657358, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657358 != nil:
    section.add "Version", valid_402657358
  var valid_402657359 = query.getOrDefault("Action")
  valid_402657359 = validateParameter(valid_402657359, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657359 != nil:
    section.add "Action", valid_402657359
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
  var valid_402657360 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657360 = validateParameter(valid_402657360, JString,
                                      required = false, default = nil)
  if valid_402657360 != nil:
    section.add "X-Amz-Security-Token", valid_402657360
  var valid_402657361 = header.getOrDefault("X-Amz-Signature")
  valid_402657361 = validateParameter(valid_402657361, JString,
                                      required = false, default = nil)
  if valid_402657361 != nil:
    section.add "X-Amz-Signature", valid_402657361
  var valid_402657362 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657362 = validateParameter(valid_402657362, JString,
                                      required = false, default = nil)
  if valid_402657362 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Algorithm", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-Date")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Date", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Credential")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Credential", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657366
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657367: Call_GetDescribeDBParameterGroups_402657351;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657367.validator(path, query, header, formData, body, _)
  let scheme = call_402657367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657367.makeUrl(scheme.get, call_402657367.host, call_402657367.base,
                                   call_402657367.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657367, uri, valid, _)

proc call*(call_402657368: Call_GetDescribeDBParameterGroups_402657351;
           Filters: JsonNode = nil; DBParameterGroupName: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeDBParameterGroups"): Recallable =
  ## getDescribeDBParameterGroups
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657369 = newJObject()
  if Filters != nil:
    query_402657369.add "Filters", Filters
  add(query_402657369, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657369, "MaxRecords", newJInt(MaxRecords))
  add(query_402657369, "Marker", newJString(Marker))
  add(query_402657369, "Version", newJString(Version))
  add(query_402657369, "Action", newJString(Action))
  result = call_402657368.call(nil, query_402657369, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_402657351(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_402657352, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_402657353,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_402657410 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameters_402657412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_402657411(path: JsonNode;
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
  var valid_402657413 = query.getOrDefault("Version")
  valid_402657413 = validateParameter(valid_402657413, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657413 != nil:
    section.add "Version", valid_402657413
  var valid_402657414 = query.getOrDefault("Action")
  valid_402657414 = validateParameter(valid_402657414, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657414 != nil:
    section.add "Action", valid_402657414
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
  var valid_402657415 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657415 = validateParameter(valid_402657415, JString,
                                      required = false, default = nil)
  if valid_402657415 != nil:
    section.add "X-Amz-Security-Token", valid_402657415
  var valid_402657416 = header.getOrDefault("X-Amz-Signature")
  valid_402657416 = validateParameter(valid_402657416, JString,
                                      required = false, default = nil)
  if valid_402657416 != nil:
    section.add "X-Amz-Signature", valid_402657416
  var valid_402657417 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657417 = validateParameter(valid_402657417, JString,
                                      required = false, default = nil)
  if valid_402657417 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Algorithm", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Date")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Date", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Credential")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Credential", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657421
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Source: JString
  section = newJObject()
  var valid_402657422 = formData.getOrDefault("Marker")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "Marker", valid_402657422
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657423 = formData.getOrDefault("DBParameterGroupName")
  valid_402657423 = validateParameter(valid_402657423, JString, required = true,
                                      default = nil)
  if valid_402657423 != nil:
    section.add "DBParameterGroupName", valid_402657423
  var valid_402657424 = formData.getOrDefault("MaxRecords")
  valid_402657424 = validateParameter(valid_402657424, JInt, required = false,
                                      default = nil)
  if valid_402657424 != nil:
    section.add "MaxRecords", valid_402657424
  var valid_402657425 = formData.getOrDefault("Filters")
  valid_402657425 = validateParameter(valid_402657425, JArray, required = false,
                                      default = nil)
  if valid_402657425 != nil:
    section.add "Filters", valid_402657425
  var valid_402657426 = formData.getOrDefault("Source")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "Source", valid_402657426
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657427: Call_PostDescribeDBParameters_402657410;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657427.validator(path, query, header, formData, body, _)
  let scheme = call_402657427.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657427.makeUrl(scheme.get, call_402657427.host, call_402657427.base,
                                   call_402657427.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657427, uri, valid, _)

proc call*(call_402657428: Call_PostDescribeDBParameters_402657410;
           DBParameterGroupName: string; Marker: string = "";
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           Action: string = "DescribeDBParameters"; Filters: JsonNode = nil;
           Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   Marker: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Source: string
  var query_402657429 = newJObject()
  var formData_402657430 = newJObject()
  add(formData_402657430, "Marker", newJString(Marker))
  add(query_402657429, "Version", newJString(Version))
  add(formData_402657430, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657430, "MaxRecords", newJInt(MaxRecords))
  add(query_402657429, "Action", newJString(Action))
  if Filters != nil:
    formData_402657430.add "Filters", Filters
  add(formData_402657430, "Source", newJString(Source))
  result = call_402657428.call(nil, query_402657429, nil, formData_402657430,
                               nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_402657410(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_402657411, base: "/",
    makeUrl: url_PostDescribeDBParameters_402657412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_402657390 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameters_402657392(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_402657391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBParameterGroupName: JString (required)
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   Source: JString
  section = newJObject()
  var valid_402657393 = query.getOrDefault("Filters")
  valid_402657393 = validateParameter(valid_402657393, JArray, required = false,
                                      default = nil)
  if valid_402657393 != nil:
    section.add "Filters", valid_402657393
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657394 = query.getOrDefault("DBParameterGroupName")
  valid_402657394 = validateParameter(valid_402657394, JString, required = true,
                                      default = nil)
  if valid_402657394 != nil:
    section.add "DBParameterGroupName", valid_402657394
  var valid_402657395 = query.getOrDefault("MaxRecords")
  valid_402657395 = validateParameter(valid_402657395, JInt, required = false,
                                      default = nil)
  if valid_402657395 != nil:
    section.add "MaxRecords", valid_402657395
  var valid_402657396 = query.getOrDefault("Marker")
  valid_402657396 = validateParameter(valid_402657396, JString,
                                      required = false, default = nil)
  if valid_402657396 != nil:
    section.add "Marker", valid_402657396
  var valid_402657397 = query.getOrDefault("Version")
  valid_402657397 = validateParameter(valid_402657397, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657397 != nil:
    section.add "Version", valid_402657397
  var valid_402657398 = query.getOrDefault("Action")
  valid_402657398 = validateParameter(valid_402657398, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657398 != nil:
    section.add "Action", valid_402657398
  var valid_402657399 = query.getOrDefault("Source")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "Source", valid_402657399
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
  var valid_402657400 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "X-Amz-Security-Token", valid_402657400
  var valid_402657401 = header.getOrDefault("X-Amz-Signature")
  valid_402657401 = validateParameter(valid_402657401, JString,
                                      required = false, default = nil)
  if valid_402657401 != nil:
    section.add "X-Amz-Signature", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Algorithm", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Date")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Date", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Credential")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Credential", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657406
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657407: Call_GetDescribeDBParameters_402657390;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657407.validator(path, query, header, formData, body, _)
  let scheme = call_402657407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657407.makeUrl(scheme.get, call_402657407.host, call_402657407.base,
                                   call_402657407.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657407, uri, valid, _)

proc call*(call_402657408: Call_GetDescribeDBParameters_402657390;
           DBParameterGroupName: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeDBParameters"; Source: string = ""): Recallable =
  ## getDescribeDBParameters
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Source: string
  var query_402657409 = newJObject()
  if Filters != nil:
    query_402657409.add "Filters", Filters
  add(query_402657409, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657409, "MaxRecords", newJInt(MaxRecords))
  add(query_402657409, "Marker", newJString(Marker))
  add(query_402657409, "Version", newJString(Version))
  add(query_402657409, "Action", newJString(Action))
  add(query_402657409, "Source", newJString(Source))
  result = call_402657408.call(nil, query_402657409, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_402657390(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_402657391, base: "/",
    makeUrl: url_GetDescribeDBParameters_402657392,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_402657450 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSecurityGroups_402657452(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_402657451(path: JsonNode;
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
  var valid_402657453 = query.getOrDefault("Version")
  valid_402657453 = validateParameter(valid_402657453, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657453 != nil:
    section.add "Version", valid_402657453
  var valid_402657454 = query.getOrDefault("Action")
  valid_402657454 = validateParameter(valid_402657454, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657454 != nil:
    section.add "Action", valid_402657454
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
  var valid_402657455 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657455 = validateParameter(valid_402657455, JString,
                                      required = false, default = nil)
  if valid_402657455 != nil:
    section.add "X-Amz-Security-Token", valid_402657455
  var valid_402657456 = header.getOrDefault("X-Amz-Signature")
  valid_402657456 = validateParameter(valid_402657456, JString,
                                      required = false, default = nil)
  if valid_402657456 != nil:
    section.add "X-Amz-Signature", valid_402657456
  var valid_402657457 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657457 = validateParameter(valid_402657457, JString,
                                      required = false, default = nil)
  if valid_402657457 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657457
  var valid_402657458 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657458 = validateParameter(valid_402657458, JString,
                                      required = false, default = nil)
  if valid_402657458 != nil:
    section.add "X-Amz-Algorithm", valid_402657458
  var valid_402657459 = header.getOrDefault("X-Amz-Date")
  valid_402657459 = validateParameter(valid_402657459, JString,
                                      required = false, default = nil)
  if valid_402657459 != nil:
    section.add "X-Amz-Date", valid_402657459
  var valid_402657460 = header.getOrDefault("X-Amz-Credential")
  valid_402657460 = validateParameter(valid_402657460, JString,
                                      required = false, default = nil)
  if valid_402657460 != nil:
    section.add "X-Amz-Credential", valid_402657460
  var valid_402657461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657461 = validateParameter(valid_402657461, JString,
                                      required = false, default = nil)
  if valid_402657461 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657461
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657462 = formData.getOrDefault("Marker")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "Marker", valid_402657462
  var valid_402657463 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "DBSecurityGroupName", valid_402657463
  var valid_402657464 = formData.getOrDefault("MaxRecords")
  valid_402657464 = validateParameter(valid_402657464, JInt, required = false,
                                      default = nil)
  if valid_402657464 != nil:
    section.add "MaxRecords", valid_402657464
  var valid_402657465 = formData.getOrDefault("Filters")
  valid_402657465 = validateParameter(valid_402657465, JArray, required = false,
                                      default = nil)
  if valid_402657465 != nil:
    section.add "Filters", valid_402657465
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657466: Call_PostDescribeDBSecurityGroups_402657450;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657466.validator(path, query, header, formData, body, _)
  let scheme = call_402657466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657466.makeUrl(scheme.get, call_402657466.host, call_402657466.base,
                                   call_402657466.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657466, uri, valid, _)

proc call*(call_402657467: Call_PostDescribeDBSecurityGroups_402657450;
           Marker: string = ""; Version: string = "2013-09-09";
           DBSecurityGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBSecurityGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657468 = newJObject()
  var formData_402657469 = newJObject()
  add(formData_402657469, "Marker", newJString(Marker))
  add(query_402657468, "Version", newJString(Version))
  add(formData_402657469, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402657469, "MaxRecords", newJInt(MaxRecords))
  add(query_402657468, "Action", newJString(Action))
  if Filters != nil:
    formData_402657469.add "Filters", Filters
  result = call_402657467.call(nil, query_402657468, nil, formData_402657469,
                               nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_402657450(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_402657451, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_402657452,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_402657431 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSecurityGroups_402657433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_402657432(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   DBSecurityGroupName: JString
  section = newJObject()
  var valid_402657434 = query.getOrDefault("Filters")
  valid_402657434 = validateParameter(valid_402657434, JArray, required = false,
                                      default = nil)
  if valid_402657434 != nil:
    section.add "Filters", valid_402657434
  var valid_402657435 = query.getOrDefault("MaxRecords")
  valid_402657435 = validateParameter(valid_402657435, JInt, required = false,
                                      default = nil)
  if valid_402657435 != nil:
    section.add "MaxRecords", valid_402657435
  var valid_402657436 = query.getOrDefault("Marker")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "Marker", valid_402657436
  var valid_402657437 = query.getOrDefault("Version")
  valid_402657437 = validateParameter(valid_402657437, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657437 != nil:
    section.add "Version", valid_402657437
  var valid_402657438 = query.getOrDefault("Action")
  valid_402657438 = validateParameter(valid_402657438, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657438 != nil:
    section.add "Action", valid_402657438
  var valid_402657439 = query.getOrDefault("DBSecurityGroupName")
  valid_402657439 = validateParameter(valid_402657439, JString,
                                      required = false, default = nil)
  if valid_402657439 != nil:
    section.add "DBSecurityGroupName", valid_402657439
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
  var valid_402657440 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657440 = validateParameter(valid_402657440, JString,
                                      required = false, default = nil)
  if valid_402657440 != nil:
    section.add "X-Amz-Security-Token", valid_402657440
  var valid_402657441 = header.getOrDefault("X-Amz-Signature")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "X-Amz-Signature", valid_402657441
  var valid_402657442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657442 = validateParameter(valid_402657442, JString,
                                      required = false, default = nil)
  if valid_402657442 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657442
  var valid_402657443 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657443 = validateParameter(valid_402657443, JString,
                                      required = false, default = nil)
  if valid_402657443 != nil:
    section.add "X-Amz-Algorithm", valid_402657443
  var valid_402657444 = header.getOrDefault("X-Amz-Date")
  valid_402657444 = validateParameter(valid_402657444, JString,
                                      required = false, default = nil)
  if valid_402657444 != nil:
    section.add "X-Amz-Date", valid_402657444
  var valid_402657445 = header.getOrDefault("X-Amz-Credential")
  valid_402657445 = validateParameter(valid_402657445, JString,
                                      required = false, default = nil)
  if valid_402657445 != nil:
    section.add "X-Amz-Credential", valid_402657445
  var valid_402657446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657446 = validateParameter(valid_402657446, JString,
                                      required = false, default = nil)
  if valid_402657446 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657447: Call_GetDescribeDBSecurityGroups_402657431;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657447.validator(path, query, header, formData, body, _)
  let scheme = call_402657447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657447.makeUrl(scheme.get, call_402657447.host, call_402657447.base,
                                   call_402657447.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657447, uri, valid, _)

proc call*(call_402657448: Call_GetDescribeDBSecurityGroups_402657431;
           Filters: JsonNode = nil; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeDBSecurityGroups";
           DBSecurityGroupName: string = ""): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string
  var query_402657449 = newJObject()
  if Filters != nil:
    query_402657449.add "Filters", Filters
  add(query_402657449, "MaxRecords", newJInt(MaxRecords))
  add(query_402657449, "Marker", newJString(Marker))
  add(query_402657449, "Version", newJString(Version))
  add(query_402657449, "Action", newJString(Action))
  add(query_402657449, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657448.call(nil, query_402657449, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_402657431(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_402657432, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_402657433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_402657491 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSnapshots_402657493(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_402657492(path: JsonNode; query: JsonNode;
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
  var valid_402657494 = query.getOrDefault("Version")
  valid_402657494 = validateParameter(valid_402657494, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657494 != nil:
    section.add "Version", valid_402657494
  var valid_402657495 = query.getOrDefault("Action")
  valid_402657495 = validateParameter(valid_402657495, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657495 != nil:
    section.add "Action", valid_402657495
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
  var valid_402657496 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657496 = validateParameter(valid_402657496, JString,
                                      required = false, default = nil)
  if valid_402657496 != nil:
    section.add "X-Amz-Security-Token", valid_402657496
  var valid_402657497 = header.getOrDefault("X-Amz-Signature")
  valid_402657497 = validateParameter(valid_402657497, JString,
                                      required = false, default = nil)
  if valid_402657497 != nil:
    section.add "X-Amz-Signature", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657498
  var valid_402657499 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657499 = validateParameter(valid_402657499, JString,
                                      required = false, default = nil)
  if valid_402657499 != nil:
    section.add "X-Amz-Algorithm", valid_402657499
  var valid_402657500 = header.getOrDefault("X-Amz-Date")
  valid_402657500 = validateParameter(valid_402657500, JString,
                                      required = false, default = nil)
  if valid_402657500 != nil:
    section.add "X-Amz-Date", valid_402657500
  var valid_402657501 = header.getOrDefault("X-Amz-Credential")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Credential", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657502
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_402657503 = formData.getOrDefault("Marker")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "Marker", valid_402657503
  var valid_402657504 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "DBInstanceIdentifier", valid_402657504
  var valid_402657505 = formData.getOrDefault("MaxRecords")
  valid_402657505 = validateParameter(valid_402657505, JInt, required = false,
                                      default = nil)
  if valid_402657505 != nil:
    section.add "MaxRecords", valid_402657505
  var valid_402657506 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "DBSnapshotIdentifier", valid_402657506
  var valid_402657507 = formData.getOrDefault("SnapshotType")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "SnapshotType", valid_402657507
  var valid_402657508 = formData.getOrDefault("Filters")
  valid_402657508 = validateParameter(valid_402657508, JArray, required = false,
                                      default = nil)
  if valid_402657508 != nil:
    section.add "Filters", valid_402657508
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657509: Call_PostDescribeDBSnapshots_402657491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657509.validator(path, query, header, formData, body, _)
  let scheme = call_402657509.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657509.makeUrl(scheme.get, call_402657509.host, call_402657509.base,
                                   call_402657509.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657509, uri, valid, _)

proc call*(call_402657510: Call_PostDescribeDBSnapshots_402657491;
           Marker: string = ""; Version: string = "2013-09-09";
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           DBSnapshotIdentifier: string = ""; SnapshotType: string = "";
           Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBSnapshots
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   DBSnapshotIdentifier: string
  ##   SnapshotType: string
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657511 = newJObject()
  var formData_402657512 = newJObject()
  add(formData_402657512, "Marker", newJString(Marker))
  add(query_402657511, "Version", newJString(Version))
  add(formData_402657512, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657512, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657512, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402657512, "SnapshotType", newJString(SnapshotType))
  add(query_402657511, "Action", newJString(Action))
  if Filters != nil:
    formData_402657512.add "Filters", Filters
  result = call_402657510.call(nil, query_402657511, nil, formData_402657512,
                               nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_402657491(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_402657492, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_402657493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_402657470 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSnapshots_402657472(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_402657471(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   SnapshotType: JString
  ##   DBSnapshotIdentifier: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657473 = query.getOrDefault("Filters")
  valid_402657473 = validateParameter(valid_402657473, JArray, required = false,
                                      default = nil)
  if valid_402657473 != nil:
    section.add "Filters", valid_402657473
  var valid_402657474 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657474 = validateParameter(valid_402657474, JString,
                                      required = false, default = nil)
  if valid_402657474 != nil:
    section.add "DBInstanceIdentifier", valid_402657474
  var valid_402657475 = query.getOrDefault("MaxRecords")
  valid_402657475 = validateParameter(valid_402657475, JInt, required = false,
                                      default = nil)
  if valid_402657475 != nil:
    section.add "MaxRecords", valid_402657475
  var valid_402657476 = query.getOrDefault("Marker")
  valid_402657476 = validateParameter(valid_402657476, JString,
                                      required = false, default = nil)
  if valid_402657476 != nil:
    section.add "Marker", valid_402657476
  var valid_402657477 = query.getOrDefault("Version")
  valid_402657477 = validateParameter(valid_402657477, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657477 != nil:
    section.add "Version", valid_402657477
  var valid_402657478 = query.getOrDefault("SnapshotType")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "SnapshotType", valid_402657478
  var valid_402657479 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657479 = validateParameter(valid_402657479, JString,
                                      required = false, default = nil)
  if valid_402657479 != nil:
    section.add "DBSnapshotIdentifier", valid_402657479
  var valid_402657480 = query.getOrDefault("Action")
  valid_402657480 = validateParameter(valid_402657480, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657480 != nil:
    section.add "Action", valid_402657480
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
  var valid_402657481 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657481 = validateParameter(valid_402657481, JString,
                                      required = false, default = nil)
  if valid_402657481 != nil:
    section.add "X-Amz-Security-Token", valid_402657481
  var valid_402657482 = header.getOrDefault("X-Amz-Signature")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "X-Amz-Signature", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657483
  var valid_402657484 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657484 = validateParameter(valid_402657484, JString,
                                      required = false, default = nil)
  if valid_402657484 != nil:
    section.add "X-Amz-Algorithm", valid_402657484
  var valid_402657485 = header.getOrDefault("X-Amz-Date")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "X-Amz-Date", valid_402657485
  var valid_402657486 = header.getOrDefault("X-Amz-Credential")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Credential", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657487
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657488: Call_GetDescribeDBSnapshots_402657470;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657488.validator(path, query, header, formData, body, _)
  let scheme = call_402657488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657488.makeUrl(scheme.get, call_402657488.host, call_402657488.base,
                                   call_402657488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657488, uri, valid, _)

proc call*(call_402657489: Call_GetDescribeDBSnapshots_402657470;
           Filters: JsonNode = nil; DBInstanceIdentifier: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09"; SnapshotType: string = "";
           DBSnapshotIdentifier: string = "";
           Action: string = "DescribeDBSnapshots"): Recallable =
  ## getDescribeDBSnapshots
  ##   Filters: JArray
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   SnapshotType: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  var query_402657490 = newJObject()
  if Filters != nil:
    query_402657490.add "Filters", Filters
  add(query_402657490, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657490, "MaxRecords", newJInt(MaxRecords))
  add(query_402657490, "Marker", newJString(Marker))
  add(query_402657490, "Version", newJString(Version))
  add(query_402657490, "SnapshotType", newJString(SnapshotType))
  add(query_402657490, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657490, "Action", newJString(Action))
  result = call_402657489.call(nil, query_402657490, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_402657470(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_402657471, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_402657472,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_402657532 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSubnetGroups_402657534(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_402657533(path: JsonNode;
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
  var valid_402657535 = query.getOrDefault("Version")
  valid_402657535 = validateParameter(valid_402657535, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657535 != nil:
    section.add "Version", valid_402657535
  var valid_402657536 = query.getOrDefault("Action")
  valid_402657536 = validateParameter(valid_402657536, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657536 != nil:
    section.add "Action", valid_402657536
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
  var valid_402657537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657537 = validateParameter(valid_402657537, JString,
                                      required = false, default = nil)
  if valid_402657537 != nil:
    section.add "X-Amz-Security-Token", valid_402657537
  var valid_402657538 = header.getOrDefault("X-Amz-Signature")
  valid_402657538 = validateParameter(valid_402657538, JString,
                                      required = false, default = nil)
  if valid_402657538 != nil:
    section.add "X-Amz-Signature", valid_402657538
  var valid_402657539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657539
  var valid_402657540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "X-Amz-Algorithm", valid_402657540
  var valid_402657541 = header.getOrDefault("X-Amz-Date")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Date", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Credential")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Credential", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657543
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657544 = formData.getOrDefault("Marker")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "Marker", valid_402657544
  var valid_402657545 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "DBSubnetGroupName", valid_402657545
  var valid_402657546 = formData.getOrDefault("MaxRecords")
  valid_402657546 = validateParameter(valid_402657546, JInt, required = false,
                                      default = nil)
  if valid_402657546 != nil:
    section.add "MaxRecords", valid_402657546
  var valid_402657547 = formData.getOrDefault("Filters")
  valid_402657547 = validateParameter(valid_402657547, JArray, required = false,
                                      default = nil)
  if valid_402657547 != nil:
    section.add "Filters", valid_402657547
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657548: Call_PostDescribeDBSubnetGroups_402657532;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657548.validator(path, query, header, formData, body, _)
  let scheme = call_402657548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657548.makeUrl(scheme.get, call_402657548.host, call_402657548.base,
                                   call_402657548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657548, uri, valid, _)

proc call*(call_402657549: Call_PostDescribeDBSubnetGroups_402657532;
           Marker: string = ""; DBSubnetGroupName: string = "";
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBSubnetGroups
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657550 = newJObject()
  var formData_402657551 = newJObject()
  add(formData_402657551, "Marker", newJString(Marker))
  add(formData_402657551, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657550, "Version", newJString(Version))
  add(formData_402657551, "MaxRecords", newJInt(MaxRecords))
  add(query_402657550, "Action", newJString(Action))
  if Filters != nil:
    formData_402657551.add "Filters", Filters
  result = call_402657549.call(nil, query_402657550, nil, formData_402657551,
                               nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_402657532(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_402657533, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_402657534,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_402657513 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSubnetGroups_402657515(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_402657514(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBSubnetGroupName: JString
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657516 = query.getOrDefault("Filters")
  valid_402657516 = validateParameter(valid_402657516, JArray, required = false,
                                      default = nil)
  if valid_402657516 != nil:
    section.add "Filters", valid_402657516
  var valid_402657517 = query.getOrDefault("DBSubnetGroupName")
  valid_402657517 = validateParameter(valid_402657517, JString,
                                      required = false, default = nil)
  if valid_402657517 != nil:
    section.add "DBSubnetGroupName", valid_402657517
  var valid_402657518 = query.getOrDefault("MaxRecords")
  valid_402657518 = validateParameter(valid_402657518, JInt, required = false,
                                      default = nil)
  if valid_402657518 != nil:
    section.add "MaxRecords", valid_402657518
  var valid_402657519 = query.getOrDefault("Marker")
  valid_402657519 = validateParameter(valid_402657519, JString,
                                      required = false, default = nil)
  if valid_402657519 != nil:
    section.add "Marker", valid_402657519
  var valid_402657520 = query.getOrDefault("Version")
  valid_402657520 = validateParameter(valid_402657520, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657520 != nil:
    section.add "Version", valid_402657520
  var valid_402657521 = query.getOrDefault("Action")
  valid_402657521 = validateParameter(valid_402657521, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657521 != nil:
    section.add "Action", valid_402657521
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
  var valid_402657522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "X-Amz-Security-Token", valid_402657522
  var valid_402657523 = header.getOrDefault("X-Amz-Signature")
  valid_402657523 = validateParameter(valid_402657523, JString,
                                      required = false, default = nil)
  if valid_402657523 != nil:
    section.add "X-Amz-Signature", valid_402657523
  var valid_402657524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Algorithm", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-Date")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Date", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Credential")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Credential", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657529: Call_GetDescribeDBSubnetGroups_402657513;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657529.validator(path, query, header, formData, body, _)
  let scheme = call_402657529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657529.makeUrl(scheme.get, call_402657529.host, call_402657529.base,
                                   call_402657529.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657529, uri, valid, _)

proc call*(call_402657530: Call_GetDescribeDBSubnetGroups_402657513;
           Filters: JsonNode = nil; DBSubnetGroupName: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeDBSubnetGroups"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Filters: JArray
  ##   DBSubnetGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657531 = newJObject()
  if Filters != nil:
    query_402657531.add "Filters", Filters
  add(query_402657531, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657531, "MaxRecords", newJInt(MaxRecords))
  add(query_402657531, "Marker", newJString(Marker))
  add(query_402657531, "Version", newJString(Version))
  add(query_402657531, "Action", newJString(Action))
  result = call_402657530.call(nil, query_402657531, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_402657513(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_402657514, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_402657515,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_402657571 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEngineDefaultParameters_402657573(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_402657572(path: JsonNode;
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
  var valid_402657574 = query.getOrDefault("Version")
  valid_402657574 = validateParameter(valid_402657574, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657574 != nil:
    section.add "Version", valid_402657574
  var valid_402657575 = query.getOrDefault("Action")
  valid_402657575 = validateParameter(valid_402657575, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657575 != nil:
    section.add "Action", valid_402657575
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
  var valid_402657576 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657576 = validateParameter(valid_402657576, JString,
                                      required = false, default = nil)
  if valid_402657576 != nil:
    section.add "X-Amz-Security-Token", valid_402657576
  var valid_402657577 = header.getOrDefault("X-Amz-Signature")
  valid_402657577 = validateParameter(valid_402657577, JString,
                                      required = false, default = nil)
  if valid_402657577 != nil:
    section.add "X-Amz-Signature", valid_402657577
  var valid_402657578 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657578 = validateParameter(valid_402657578, JString,
                                      required = false, default = nil)
  if valid_402657578 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657578
  var valid_402657579 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657579 = validateParameter(valid_402657579, JString,
                                      required = false, default = nil)
  if valid_402657579 != nil:
    section.add "X-Amz-Algorithm", valid_402657579
  var valid_402657580 = header.getOrDefault("X-Amz-Date")
  valid_402657580 = validateParameter(valid_402657580, JString,
                                      required = false, default = nil)
  if valid_402657580 != nil:
    section.add "X-Amz-Date", valid_402657580
  var valid_402657581 = header.getOrDefault("X-Amz-Credential")
  valid_402657581 = validateParameter(valid_402657581, JString,
                                      required = false, default = nil)
  if valid_402657581 != nil:
    section.add "X-Amz-Credential", valid_402657581
  var valid_402657582 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657582 = validateParameter(valid_402657582, JString,
                                      required = false, default = nil)
  if valid_402657582 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657582
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657583 = formData.getOrDefault("Marker")
  valid_402657583 = validateParameter(valid_402657583, JString,
                                      required = false, default = nil)
  if valid_402657583 != nil:
    section.add "Marker", valid_402657583
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657584 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657584 = validateParameter(valid_402657584, JString, required = true,
                                      default = nil)
  if valid_402657584 != nil:
    section.add "DBParameterGroupFamily", valid_402657584
  var valid_402657585 = formData.getOrDefault("MaxRecords")
  valid_402657585 = validateParameter(valid_402657585, JInt, required = false,
                                      default = nil)
  if valid_402657585 != nil:
    section.add "MaxRecords", valid_402657585
  var valid_402657586 = formData.getOrDefault("Filters")
  valid_402657586 = validateParameter(valid_402657586, JArray, required = false,
                                      default = nil)
  if valid_402657586 != nil:
    section.add "Filters", valid_402657586
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657587: Call_PostDescribeEngineDefaultParameters_402657571;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657587.validator(path, query, header, formData, body, _)
  let scheme = call_402657587.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657587.makeUrl(scheme.get, call_402657587.host, call_402657587.base,
                                   call_402657587.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657587, uri, valid, _)

proc call*(call_402657588: Call_PostDescribeEngineDefaultParameters_402657571;
           DBParameterGroupFamily: string; Marker: string = "";
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           Action: string = "DescribeEngineDefaultParameters";
           Filters: JsonNode = nil): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657589 = newJObject()
  var formData_402657590 = newJObject()
  add(formData_402657590, "Marker", newJString(Marker))
  add(formData_402657590, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657589, "Version", newJString(Version))
  add(formData_402657590, "MaxRecords", newJInt(MaxRecords))
  add(query_402657589, "Action", newJString(Action))
  if Filters != nil:
    formData_402657590.add "Filters", Filters
  result = call_402657588.call(nil, query_402657589, nil, formData_402657590,
                               nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_402657571(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_402657572,
    base: "/", makeUrl: url_PostDescribeEngineDefaultParameters_402657573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_402657552 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEngineDefaultParameters_402657554(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_402657553(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657555 = query.getOrDefault("Filters")
  valid_402657555 = validateParameter(valid_402657555, JArray, required = false,
                                      default = nil)
  if valid_402657555 != nil:
    section.add "Filters", valid_402657555
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657556 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657556 = validateParameter(valid_402657556, JString, required = true,
                                      default = nil)
  if valid_402657556 != nil:
    section.add "DBParameterGroupFamily", valid_402657556
  var valid_402657557 = query.getOrDefault("MaxRecords")
  valid_402657557 = validateParameter(valid_402657557, JInt, required = false,
                                      default = nil)
  if valid_402657557 != nil:
    section.add "MaxRecords", valid_402657557
  var valid_402657558 = query.getOrDefault("Marker")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "Marker", valid_402657558
  var valid_402657559 = query.getOrDefault("Version")
  valid_402657559 = validateParameter(valid_402657559, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657559 != nil:
    section.add "Version", valid_402657559
  var valid_402657560 = query.getOrDefault("Action")
  valid_402657560 = validateParameter(valid_402657560, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657560 != nil:
    section.add "Action", valid_402657560
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
  var valid_402657561 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657561 = validateParameter(valid_402657561, JString,
                                      required = false, default = nil)
  if valid_402657561 != nil:
    section.add "X-Amz-Security-Token", valid_402657561
  var valid_402657562 = header.getOrDefault("X-Amz-Signature")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "X-Amz-Signature", valid_402657562
  var valid_402657563 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657563 = validateParameter(valid_402657563, JString,
                                      required = false, default = nil)
  if valid_402657563 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657563
  var valid_402657564 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "X-Amz-Algorithm", valid_402657564
  var valid_402657565 = header.getOrDefault("X-Amz-Date")
  valid_402657565 = validateParameter(valid_402657565, JString,
                                      required = false, default = nil)
  if valid_402657565 != nil:
    section.add "X-Amz-Date", valid_402657565
  var valid_402657566 = header.getOrDefault("X-Amz-Credential")
  valid_402657566 = validateParameter(valid_402657566, JString,
                                      required = false, default = nil)
  if valid_402657566 != nil:
    section.add "X-Amz-Credential", valid_402657566
  var valid_402657567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657567 = validateParameter(valid_402657567, JString,
                                      required = false, default = nil)
  if valid_402657567 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657567
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657568: Call_GetDescribeEngineDefaultParameters_402657552;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657568.validator(path, query, header, formData, body, _)
  let scheme = call_402657568.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657568.makeUrl(scheme.get, call_402657568.host, call_402657568.base,
                                   call_402657568.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657568, uri, valid, _)

proc call*(call_402657569: Call_GetDescribeEngineDefaultParameters_402657552;
           DBParameterGroupFamily: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeEngineDefaultParameters"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Filters: JArray
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657570 = newJObject()
  if Filters != nil:
    query_402657570.add "Filters", Filters
  add(query_402657570, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657570, "MaxRecords", newJInt(MaxRecords))
  add(query_402657570, "Marker", newJString(Marker))
  add(query_402657570, "Version", newJString(Version))
  add(query_402657570, "Action", newJString(Action))
  result = call_402657569.call(nil, query_402657570, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_402657552(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_402657553, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_402657554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_402657608 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventCategories_402657610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_402657609(path: JsonNode;
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
  var valid_402657611 = query.getOrDefault("Version")
  valid_402657611 = validateParameter(valid_402657611, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657611 != nil:
    section.add "Version", valid_402657611
  var valid_402657612 = query.getOrDefault("Action")
  valid_402657612 = validateParameter(valid_402657612, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657612 != nil:
    section.add "Action", valid_402657612
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
  var valid_402657613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Security-Token", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-Signature")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-Signature", valid_402657614
  var valid_402657615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657615 = validateParameter(valid_402657615, JString,
                                      required = false, default = nil)
  if valid_402657615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657615
  var valid_402657616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657616 = validateParameter(valid_402657616, JString,
                                      required = false, default = nil)
  if valid_402657616 != nil:
    section.add "X-Amz-Algorithm", valid_402657616
  var valid_402657617 = header.getOrDefault("X-Amz-Date")
  valid_402657617 = validateParameter(valid_402657617, JString,
                                      required = false, default = nil)
  if valid_402657617 != nil:
    section.add "X-Amz-Date", valid_402657617
  var valid_402657618 = header.getOrDefault("X-Amz-Credential")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "X-Amz-Credential", valid_402657618
  var valid_402657619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657619 = validateParameter(valid_402657619, JString,
                                      required = false, default = nil)
  if valid_402657619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657619
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_402657620 = formData.getOrDefault("SourceType")
  valid_402657620 = validateParameter(valid_402657620, JString,
                                      required = false, default = nil)
  if valid_402657620 != nil:
    section.add "SourceType", valid_402657620
  var valid_402657621 = formData.getOrDefault("Filters")
  valid_402657621 = validateParameter(valid_402657621, JArray, required = false,
                                      default = nil)
  if valid_402657621 != nil:
    section.add "Filters", valid_402657621
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657622: Call_PostDescribeEventCategories_402657608;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657622.validator(path, query, header, formData, body, _)
  let scheme = call_402657622.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657622.makeUrl(scheme.get, call_402657622.host, call_402657622.base,
                                   call_402657622.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657622, uri, valid, _)

proc call*(call_402657623: Call_PostDescribeEventCategories_402657608;
           SourceType: string = ""; Version: string = "2013-09-09";
           Action: string = "DescribeEventCategories"; Filters: JsonNode = nil): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657624 = newJObject()
  var formData_402657625 = newJObject()
  add(formData_402657625, "SourceType", newJString(SourceType))
  add(query_402657624, "Version", newJString(Version))
  add(query_402657624, "Action", newJString(Action))
  if Filters != nil:
    formData_402657625.add "Filters", Filters
  result = call_402657623.call(nil, query_402657624, nil, formData_402657625,
                               nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_402657608(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_402657609, base: "/",
    makeUrl: url_PostDescribeEventCategories_402657610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_402657591 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventCategories_402657593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_402657592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   Version: JString (required)
  ##   SourceType: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657594 = query.getOrDefault("Filters")
  valid_402657594 = validateParameter(valid_402657594, JArray, required = false,
                                      default = nil)
  if valid_402657594 != nil:
    section.add "Filters", valid_402657594
  var valid_402657595 = query.getOrDefault("Version")
  valid_402657595 = validateParameter(valid_402657595, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657595 != nil:
    section.add "Version", valid_402657595
  var valid_402657596 = query.getOrDefault("SourceType")
  valid_402657596 = validateParameter(valid_402657596, JString,
                                      required = false, default = nil)
  if valid_402657596 != nil:
    section.add "SourceType", valid_402657596
  var valid_402657597 = query.getOrDefault("Action")
  valid_402657597 = validateParameter(valid_402657597, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657597 != nil:
    section.add "Action", valid_402657597
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
  var valid_402657598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657598 = validateParameter(valid_402657598, JString,
                                      required = false, default = nil)
  if valid_402657598 != nil:
    section.add "X-Amz-Security-Token", valid_402657598
  var valid_402657599 = header.getOrDefault("X-Amz-Signature")
  valid_402657599 = validateParameter(valid_402657599, JString,
                                      required = false, default = nil)
  if valid_402657599 != nil:
    section.add "X-Amz-Signature", valid_402657599
  var valid_402657600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657600 = validateParameter(valid_402657600, JString,
                                      required = false, default = nil)
  if valid_402657600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657600
  var valid_402657601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657601 = validateParameter(valid_402657601, JString,
                                      required = false, default = nil)
  if valid_402657601 != nil:
    section.add "X-Amz-Algorithm", valid_402657601
  var valid_402657602 = header.getOrDefault("X-Amz-Date")
  valid_402657602 = validateParameter(valid_402657602, JString,
                                      required = false, default = nil)
  if valid_402657602 != nil:
    section.add "X-Amz-Date", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Credential")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Credential", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657605: Call_GetDescribeEventCategories_402657591;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657605.validator(path, query, header, formData, body, _)
  let scheme = call_402657605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657605.makeUrl(scheme.get, call_402657605.host, call_402657605.base,
                                   call_402657605.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657605, uri, valid, _)

proc call*(call_402657606: Call_GetDescribeEventCategories_402657591;
           Filters: JsonNode = nil; Version: string = "2013-09-09";
           SourceType: string = ""; Action: string = "DescribeEventCategories"): Recallable =
  ## getDescribeEventCategories
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402657607 = newJObject()
  if Filters != nil:
    query_402657607.add "Filters", Filters
  add(query_402657607, "Version", newJString(Version))
  add(query_402657607, "SourceType", newJString(SourceType))
  add(query_402657607, "Action", newJString(Action))
  result = call_402657606.call(nil, query_402657607, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_402657591(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_402657592, base: "/",
    makeUrl: url_GetDescribeEventCategories_402657593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_402657645 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventSubscriptions_402657647(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_402657646(path: JsonNode;
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
  var valid_402657648 = query.getOrDefault("Version")
  valid_402657648 = validateParameter(valid_402657648, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657648 != nil:
    section.add "Version", valid_402657648
  var valid_402657649 = query.getOrDefault("Action")
  valid_402657649 = validateParameter(valid_402657649, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657649 != nil:
    section.add "Action", valid_402657649
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
  var valid_402657650 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-Security-Token", valid_402657650
  var valid_402657651 = header.getOrDefault("X-Amz-Signature")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Signature", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657652
  var valid_402657653 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "X-Amz-Algorithm", valid_402657653
  var valid_402657654 = header.getOrDefault("X-Amz-Date")
  valid_402657654 = validateParameter(valid_402657654, JString,
                                      required = false, default = nil)
  if valid_402657654 != nil:
    section.add "X-Amz-Date", valid_402657654
  var valid_402657655 = header.getOrDefault("X-Amz-Credential")
  valid_402657655 = validateParameter(valid_402657655, JString,
                                      required = false, default = nil)
  if valid_402657655 != nil:
    section.add "X-Amz-Credential", valid_402657655
  var valid_402657656 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657656 = validateParameter(valid_402657656, JString,
                                      required = false, default = nil)
  if valid_402657656 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657656
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_402657657 = formData.getOrDefault("Marker")
  valid_402657657 = validateParameter(valid_402657657, JString,
                                      required = false, default = nil)
  if valid_402657657 != nil:
    section.add "Marker", valid_402657657
  var valid_402657658 = formData.getOrDefault("MaxRecords")
  valid_402657658 = validateParameter(valid_402657658, JInt, required = false,
                                      default = nil)
  if valid_402657658 != nil:
    section.add "MaxRecords", valid_402657658
  var valid_402657659 = formData.getOrDefault("Filters")
  valid_402657659 = validateParameter(valid_402657659, JArray, required = false,
                                      default = nil)
  if valid_402657659 != nil:
    section.add "Filters", valid_402657659
  var valid_402657660 = formData.getOrDefault("SubscriptionName")
  valid_402657660 = validateParameter(valid_402657660, JString,
                                      required = false, default = nil)
  if valid_402657660 != nil:
    section.add "SubscriptionName", valid_402657660
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657661: Call_PostDescribeEventSubscriptions_402657645;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657661.validator(path, query, header, formData, body, _)
  let scheme = call_402657661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657661.makeUrl(scheme.get, call_402657661.host, call_402657661.base,
                                   call_402657661.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657661, uri, valid, _)

proc call*(call_402657662: Call_PostDescribeEventSubscriptions_402657645;
           Marker: string = ""; Version: string = "2013-09-09";
           MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
           Filters: JsonNode = nil; SubscriptionName: string = ""): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   SubscriptionName: string
  var query_402657663 = newJObject()
  var formData_402657664 = newJObject()
  add(formData_402657664, "Marker", newJString(Marker))
  add(query_402657663, "Version", newJString(Version))
  add(formData_402657664, "MaxRecords", newJInt(MaxRecords))
  add(query_402657663, "Action", newJString(Action))
  if Filters != nil:
    formData_402657664.add "Filters", Filters
  add(formData_402657664, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657662.call(nil, query_402657663, nil, formData_402657664,
                               nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_402657645(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_402657646, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_402657647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_402657626 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventSubscriptions_402657628(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_402657627(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   SubscriptionName: JString
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657629 = query.getOrDefault("Filters")
  valid_402657629 = validateParameter(valid_402657629, JArray, required = false,
                                      default = nil)
  if valid_402657629 != nil:
    section.add "Filters", valid_402657629
  var valid_402657630 = query.getOrDefault("MaxRecords")
  valid_402657630 = validateParameter(valid_402657630, JInt, required = false,
                                      default = nil)
  if valid_402657630 != nil:
    section.add "MaxRecords", valid_402657630
  var valid_402657631 = query.getOrDefault("Marker")
  valid_402657631 = validateParameter(valid_402657631, JString,
                                      required = false, default = nil)
  if valid_402657631 != nil:
    section.add "Marker", valid_402657631
  var valid_402657632 = query.getOrDefault("Version")
  valid_402657632 = validateParameter(valid_402657632, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657632 != nil:
    section.add "Version", valid_402657632
  var valid_402657633 = query.getOrDefault("SubscriptionName")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "SubscriptionName", valid_402657633
  var valid_402657634 = query.getOrDefault("Action")
  valid_402657634 = validateParameter(valid_402657634, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657634 != nil:
    section.add "Action", valid_402657634
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
  var valid_402657635 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657635 = validateParameter(valid_402657635, JString,
                                      required = false, default = nil)
  if valid_402657635 != nil:
    section.add "X-Amz-Security-Token", valid_402657635
  var valid_402657636 = header.getOrDefault("X-Amz-Signature")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "X-Amz-Signature", valid_402657636
  var valid_402657637 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657637 = validateParameter(valid_402657637, JString,
                                      required = false, default = nil)
  if valid_402657637 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-Algorithm", valid_402657638
  var valid_402657639 = header.getOrDefault("X-Amz-Date")
  valid_402657639 = validateParameter(valid_402657639, JString,
                                      required = false, default = nil)
  if valid_402657639 != nil:
    section.add "X-Amz-Date", valid_402657639
  var valid_402657640 = header.getOrDefault("X-Amz-Credential")
  valid_402657640 = validateParameter(valid_402657640, JString,
                                      required = false, default = nil)
  if valid_402657640 != nil:
    section.add "X-Amz-Credential", valid_402657640
  var valid_402657641 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657641 = validateParameter(valid_402657641, JString,
                                      required = false, default = nil)
  if valid_402657641 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657641
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657642: Call_GetDescribeEventSubscriptions_402657626;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657642.validator(path, query, header, formData, body, _)
  let scheme = call_402657642.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657642.makeUrl(scheme.get, call_402657642.host, call_402657642.base,
                                   call_402657642.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657642, uri, valid, _)

proc call*(call_402657643: Call_GetDescribeEventSubscriptions_402657626;
           Filters: JsonNode = nil; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09"; SubscriptionName: string = "";
           Action: string = "DescribeEventSubscriptions"): Recallable =
  ## getDescribeEventSubscriptions
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   SubscriptionName: string
  ##   Action: string (required)
  var query_402657644 = newJObject()
  if Filters != nil:
    query_402657644.add "Filters", Filters
  add(query_402657644, "MaxRecords", newJInt(MaxRecords))
  add(query_402657644, "Marker", newJString(Marker))
  add(query_402657644, "Version", newJString(Version))
  add(query_402657644, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657644, "Action", newJString(Action))
  result = call_402657643.call(nil, query_402657644, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_402657626(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_402657627, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_402657628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_402657689 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEvents_402657691(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_402657690(path: JsonNode; query: JsonNode;
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
  var valid_402657692 = query.getOrDefault("Version")
  valid_402657692 = validateParameter(valid_402657692, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657692 != nil:
    section.add "Version", valid_402657692
  var valid_402657693 = query.getOrDefault("Action")
  valid_402657693 = validateParameter(valid_402657693, JString, required = true,
                                      default = newJString("DescribeEvents"))
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
  ##   SourceType: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   StartTime: JString
  ##   MaxRecords: JInt
  ##   SourceIdentifier: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_402657701 = formData.getOrDefault("Marker")
  valid_402657701 = validateParameter(valid_402657701, JString,
                                      required = false, default = nil)
  if valid_402657701 != nil:
    section.add "Marker", valid_402657701
  var valid_402657702 = formData.getOrDefault("SourceType")
  valid_402657702 = validateParameter(valid_402657702, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657702 != nil:
    section.add "SourceType", valid_402657702
  var valid_402657703 = formData.getOrDefault("EventCategories")
  valid_402657703 = validateParameter(valid_402657703, JArray, required = false,
                                      default = nil)
  if valid_402657703 != nil:
    section.add "EventCategories", valid_402657703
  var valid_402657704 = formData.getOrDefault("Duration")
  valid_402657704 = validateParameter(valid_402657704, JInt, required = false,
                                      default = nil)
  if valid_402657704 != nil:
    section.add "Duration", valid_402657704
  var valid_402657705 = formData.getOrDefault("EndTime")
  valid_402657705 = validateParameter(valid_402657705, JString,
                                      required = false, default = nil)
  if valid_402657705 != nil:
    section.add "EndTime", valid_402657705
  var valid_402657706 = formData.getOrDefault("StartTime")
  valid_402657706 = validateParameter(valid_402657706, JString,
                                      required = false, default = nil)
  if valid_402657706 != nil:
    section.add "StartTime", valid_402657706
  var valid_402657707 = formData.getOrDefault("MaxRecords")
  valid_402657707 = validateParameter(valid_402657707, JInt, required = false,
                                      default = nil)
  if valid_402657707 != nil:
    section.add "MaxRecords", valid_402657707
  var valid_402657708 = formData.getOrDefault("SourceIdentifier")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "SourceIdentifier", valid_402657708
  var valid_402657709 = formData.getOrDefault("Filters")
  valid_402657709 = validateParameter(valid_402657709, JArray, required = false,
                                      default = nil)
  if valid_402657709 != nil:
    section.add "Filters", valid_402657709
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657710: Call_PostDescribeEvents_402657689;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657710.validator(path, query, header, formData, body, _)
  let scheme = call_402657710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657710.makeUrl(scheme.get, call_402657710.host, call_402657710.base,
                                   call_402657710.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657710, uri, valid, _)

proc call*(call_402657711: Call_PostDescribeEvents_402657689;
           Marker: string = ""; SourceType: string = "db-instance";
           EventCategories: JsonNode = nil; Version: string = "2013-09-09";
           Duration: int = 0; EndTime: string = ""; StartTime: string = "";
           MaxRecords: int = 0; Action: string = "DescribeEvents";
           SourceIdentifier: string = ""; Filters: JsonNode = nil): Recallable =
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
  ##   Filters: JArray
  var query_402657712 = newJObject()
  var formData_402657713 = newJObject()
  add(formData_402657713, "Marker", newJString(Marker))
  add(formData_402657713, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_402657713.add "EventCategories", EventCategories
  add(query_402657712, "Version", newJString(Version))
  add(formData_402657713, "Duration", newJInt(Duration))
  add(formData_402657713, "EndTime", newJString(EndTime))
  add(formData_402657713, "StartTime", newJString(StartTime))
  add(formData_402657713, "MaxRecords", newJInt(MaxRecords))
  add(query_402657712, "Action", newJString(Action))
  add(formData_402657713, "SourceIdentifier", newJString(SourceIdentifier))
  if Filters != nil:
    formData_402657713.add "Filters", Filters
  result = call_402657711.call(nil, query_402657712, nil, formData_402657713,
                               nil)

var postDescribeEvents* = Call_PostDescribeEvents_402657689(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_402657690, base: "/",
    makeUrl: url_PostDescribeEvents_402657691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_402657665 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEvents_402657667(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_402657666(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EndTime: JString
  ##   Filters: JArray
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
  var valid_402657668 = query.getOrDefault("EndTime")
  valid_402657668 = validateParameter(valid_402657668, JString,
                                      required = false, default = nil)
  if valid_402657668 != nil:
    section.add "EndTime", valid_402657668
  var valid_402657669 = query.getOrDefault("Filters")
  valid_402657669 = validateParameter(valid_402657669, JArray, required = false,
                                      default = nil)
  if valid_402657669 != nil:
    section.add "Filters", valid_402657669
  var valid_402657670 = query.getOrDefault("SourceIdentifier")
  valid_402657670 = validateParameter(valid_402657670, JString,
                                      required = false, default = nil)
  if valid_402657670 != nil:
    section.add "SourceIdentifier", valid_402657670
  var valid_402657671 = query.getOrDefault("MaxRecords")
  valid_402657671 = validateParameter(valid_402657671, JInt, required = false,
                                      default = nil)
  if valid_402657671 != nil:
    section.add "MaxRecords", valid_402657671
  var valid_402657672 = query.getOrDefault("Marker")
  valid_402657672 = validateParameter(valid_402657672, JString,
                                      required = false, default = nil)
  if valid_402657672 != nil:
    section.add "Marker", valid_402657672
  var valid_402657673 = query.getOrDefault("EventCategories")
  valid_402657673 = validateParameter(valid_402657673, JArray, required = false,
                                      default = nil)
  if valid_402657673 != nil:
    section.add "EventCategories", valid_402657673
  var valid_402657674 = query.getOrDefault("Version")
  valid_402657674 = validateParameter(valid_402657674, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657674 != nil:
    section.add "Version", valid_402657674
  var valid_402657675 = query.getOrDefault("Duration")
  valid_402657675 = validateParameter(valid_402657675, JInt, required = false,
                                      default = nil)
  if valid_402657675 != nil:
    section.add "Duration", valid_402657675
  var valid_402657676 = query.getOrDefault("StartTime")
  valid_402657676 = validateParameter(valid_402657676, JString,
                                      required = false, default = nil)
  if valid_402657676 != nil:
    section.add "StartTime", valid_402657676
  var valid_402657677 = query.getOrDefault("SourceType")
  valid_402657677 = validateParameter(valid_402657677, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657677 != nil:
    section.add "SourceType", valid_402657677
  var valid_402657678 = query.getOrDefault("Action")
  valid_402657678 = validateParameter(valid_402657678, JString, required = true,
                                      default = newJString("DescribeEvents"))
  if valid_402657678 != nil:
    section.add "Action", valid_402657678
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

proc call*(call_402657686: Call_GetDescribeEvents_402657665;
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

proc call*(call_402657687: Call_GetDescribeEvents_402657665;
           EndTime: string = ""; Filters: JsonNode = nil;
           SourceIdentifier: string = ""; MaxRecords: int = 0;
           Marker: string = ""; EventCategories: JsonNode = nil;
           Version: string = "2013-09-09"; Duration: int = 0;
           StartTime: string = ""; SourceType: string = "db-instance";
           Action: string = "DescribeEvents"): Recallable =
  ## getDescribeEvents
  ##   EndTime: string
  ##   Filters: JArray
  ##   SourceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   Duration: int
  ##   StartTime: string
  ##   SourceType: string
  ##   Action: string (required)
  var query_402657688 = newJObject()
  add(query_402657688, "EndTime", newJString(EndTime))
  if Filters != nil:
    query_402657688.add "Filters", Filters
  add(query_402657688, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402657688, "MaxRecords", newJInt(MaxRecords))
  add(query_402657688, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_402657688.add "EventCategories", EventCategories
  add(query_402657688, "Version", newJString(Version))
  add(query_402657688, "Duration", newJInt(Duration))
  add(query_402657688, "StartTime", newJString(StartTime))
  add(query_402657688, "SourceType", newJString(SourceType))
  add(query_402657688, "Action", newJString(Action))
  result = call_402657687.call(nil, query_402657688, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_402657665(
    name: "getDescribeEvents", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_GetDescribeEvents_402657666, base: "/",
    makeUrl: url_GetDescribeEvents_402657667,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_402657734 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroupOptions_402657736(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_402657735(path: JsonNode;
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
  var valid_402657737 = query.getOrDefault("Version")
  valid_402657737 = validateParameter(valid_402657737, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657737 != nil:
    section.add "Version", valid_402657737
  var valid_402657738 = query.getOrDefault("Action")
  valid_402657738 = validateParameter(valid_402657738, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657738 != nil:
    section.add "Action", valid_402657738
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
  var valid_402657739 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657739 = validateParameter(valid_402657739, JString,
                                      required = false, default = nil)
  if valid_402657739 != nil:
    section.add "X-Amz-Security-Token", valid_402657739
  var valid_402657740 = header.getOrDefault("X-Amz-Signature")
  valid_402657740 = validateParameter(valid_402657740, JString,
                                      required = false, default = nil)
  if valid_402657740 != nil:
    section.add "X-Amz-Signature", valid_402657740
  var valid_402657741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657741
  var valid_402657742 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "X-Amz-Algorithm", valid_402657742
  var valid_402657743 = header.getOrDefault("X-Amz-Date")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "X-Amz-Date", valid_402657743
  var valid_402657744 = header.getOrDefault("X-Amz-Credential")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "X-Amz-Credential", valid_402657744
  var valid_402657745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657745 = validateParameter(valid_402657745, JString,
                                      required = false, default = nil)
  if valid_402657745 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657745
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657746 = formData.getOrDefault("Marker")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "Marker", valid_402657746
  assert formData != nil,
         "formData argument is necessary due to required `EngineName` field"
  var valid_402657747 = formData.getOrDefault("EngineName")
  valid_402657747 = validateParameter(valid_402657747, JString, required = true,
                                      default = nil)
  if valid_402657747 != nil:
    section.add "EngineName", valid_402657747
  var valid_402657748 = formData.getOrDefault("MaxRecords")
  valid_402657748 = validateParameter(valid_402657748, JInt, required = false,
                                      default = nil)
  if valid_402657748 != nil:
    section.add "MaxRecords", valid_402657748
  var valid_402657749 = formData.getOrDefault("Filters")
  valid_402657749 = validateParameter(valid_402657749, JArray, required = false,
                                      default = nil)
  if valid_402657749 != nil:
    section.add "Filters", valid_402657749
  var valid_402657750 = formData.getOrDefault("MajorEngineVersion")
  valid_402657750 = validateParameter(valid_402657750, JString,
                                      required = false, default = nil)
  if valid_402657750 != nil:
    section.add "MajorEngineVersion", valid_402657750
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657751: Call_PostDescribeOptionGroupOptions_402657734;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657751.validator(path, query, header, formData, body, _)
  let scheme = call_402657751.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657751.makeUrl(scheme.get, call_402657751.host, call_402657751.base,
                                   call_402657751.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657751, uri, valid, _)

proc call*(call_402657752: Call_PostDescribeOptionGroupOptions_402657734;
           EngineName: string; Marker: string = "";
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           Action: string = "DescribeOptionGroupOptions";
           Filters: JsonNode = nil; MajorEngineVersion: string = ""): Recallable =
  ## postDescribeOptionGroupOptions
  ##   Marker: string
  ##   EngineName: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MajorEngineVersion: string
  var query_402657753 = newJObject()
  var formData_402657754 = newJObject()
  add(formData_402657754, "Marker", newJString(Marker))
  add(formData_402657754, "EngineName", newJString(EngineName))
  add(query_402657753, "Version", newJString(Version))
  add(formData_402657754, "MaxRecords", newJInt(MaxRecords))
  add(query_402657753, "Action", newJString(Action))
  if Filters != nil:
    formData_402657754.add "Filters", Filters
  add(formData_402657754, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657752.call(nil, query_402657753, nil, formData_402657754,
                               nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_402657734(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_402657735, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_402657736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_402657714 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroupOptions_402657716(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_402657715(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657717 = query.getOrDefault("Filters")
  valid_402657717 = validateParameter(valid_402657717, JArray, required = false,
                                      default = nil)
  if valid_402657717 != nil:
    section.add "Filters", valid_402657717
  var valid_402657718 = query.getOrDefault("MaxRecords")
  valid_402657718 = validateParameter(valid_402657718, JInt, required = false,
                                      default = nil)
  if valid_402657718 != nil:
    section.add "MaxRecords", valid_402657718
  var valid_402657719 = query.getOrDefault("Marker")
  valid_402657719 = validateParameter(valid_402657719, JString,
                                      required = false, default = nil)
  if valid_402657719 != nil:
    section.add "Marker", valid_402657719
  var valid_402657720 = query.getOrDefault("Version")
  valid_402657720 = validateParameter(valid_402657720, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657720 != nil:
    section.add "Version", valid_402657720
  var valid_402657721 = query.getOrDefault("Action")
  valid_402657721 = validateParameter(valid_402657721, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657721 != nil:
    section.add "Action", valid_402657721
  var valid_402657722 = query.getOrDefault("EngineName")
  valid_402657722 = validateParameter(valid_402657722, JString, required = true,
                                      default = nil)
  if valid_402657722 != nil:
    section.add "EngineName", valid_402657722
  var valid_402657723 = query.getOrDefault("MajorEngineVersion")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "MajorEngineVersion", valid_402657723
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
  var valid_402657724 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657724 = validateParameter(valid_402657724, JString,
                                      required = false, default = nil)
  if valid_402657724 != nil:
    section.add "X-Amz-Security-Token", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-Signature")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-Signature", valid_402657725
  var valid_402657726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657726
  var valid_402657727 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657727 = validateParameter(valid_402657727, JString,
                                      required = false, default = nil)
  if valid_402657727 != nil:
    section.add "X-Amz-Algorithm", valid_402657727
  var valid_402657728 = header.getOrDefault("X-Amz-Date")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Date", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-Credential")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-Credential", valid_402657729
  var valid_402657730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657730 = validateParameter(valid_402657730, JString,
                                      required = false, default = nil)
  if valid_402657730 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657731: Call_GetDescribeOptionGroupOptions_402657714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657731.validator(path, query, header, formData, body, _)
  let scheme = call_402657731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657731.makeUrl(scheme.get, call_402657731.host, call_402657731.base,
                                   call_402657731.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657731, uri, valid, _)

proc call*(call_402657732: Call_GetDescribeOptionGroupOptions_402657714;
           EngineName: string; Filters: JsonNode = nil; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-09-09";
           Action: string = "DescribeOptionGroupOptions";
           MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_402657733 = newJObject()
  if Filters != nil:
    query_402657733.add "Filters", Filters
  add(query_402657733, "MaxRecords", newJInt(MaxRecords))
  add(query_402657733, "Marker", newJString(Marker))
  add(query_402657733, "Version", newJString(Version))
  add(query_402657733, "Action", newJString(Action))
  add(query_402657733, "EngineName", newJString(EngineName))
  add(query_402657733, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657732.call(nil, query_402657733, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_402657714(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_402657715, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_402657716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_402657776 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroups_402657778(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_402657777(path: JsonNode;
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
  var valid_402657779 = query.getOrDefault("Version")
  valid_402657779 = validateParameter(valid_402657779, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657779 != nil:
    section.add "Version", valid_402657779
  var valid_402657780 = query.getOrDefault("Action")
  valid_402657780 = validateParameter(valid_402657780, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657780 != nil:
    section.add "Action", valid_402657780
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
  var valid_402657781 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657781 = validateParameter(valid_402657781, JString,
                                      required = false, default = nil)
  if valid_402657781 != nil:
    section.add "X-Amz-Security-Token", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Signature")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Signature", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657783
  var valid_402657784 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "X-Amz-Algorithm", valid_402657784
  var valid_402657785 = header.getOrDefault("X-Amz-Date")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "X-Amz-Date", valid_402657785
  var valid_402657786 = header.getOrDefault("X-Amz-Credential")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "X-Amz-Credential", valid_402657786
  var valid_402657787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657787
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Filters: JArray
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657788 = formData.getOrDefault("Marker")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false, default = nil)
  if valid_402657788 != nil:
    section.add "Marker", valid_402657788
  var valid_402657789 = formData.getOrDefault("EngineName")
  valid_402657789 = validateParameter(valid_402657789, JString,
                                      required = false, default = nil)
  if valid_402657789 != nil:
    section.add "EngineName", valid_402657789
  var valid_402657790 = formData.getOrDefault("MaxRecords")
  valid_402657790 = validateParameter(valid_402657790, JInt, required = false,
                                      default = nil)
  if valid_402657790 != nil:
    section.add "MaxRecords", valid_402657790
  var valid_402657791 = formData.getOrDefault("OptionGroupName")
  valid_402657791 = validateParameter(valid_402657791, JString,
                                      required = false, default = nil)
  if valid_402657791 != nil:
    section.add "OptionGroupName", valid_402657791
  var valid_402657792 = formData.getOrDefault("Filters")
  valid_402657792 = validateParameter(valid_402657792, JArray, required = false,
                                      default = nil)
  if valid_402657792 != nil:
    section.add "Filters", valid_402657792
  var valid_402657793 = formData.getOrDefault("MajorEngineVersion")
  valid_402657793 = validateParameter(valid_402657793, JString,
                                      required = false, default = nil)
  if valid_402657793 != nil:
    section.add "MajorEngineVersion", valid_402657793
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657794: Call_PostDescribeOptionGroups_402657776;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657794.validator(path, query, header, formData, body, _)
  let scheme = call_402657794.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657794.makeUrl(scheme.get, call_402657794.host, call_402657794.base,
                                   call_402657794.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657794, uri, valid, _)

proc call*(call_402657795: Call_PostDescribeOptionGroups_402657776;
           Marker: string = ""; EngineName: string = "";
           Version: string = "2013-09-09"; MaxRecords: int = 0;
           OptionGroupName: string = "";
           Action: string = "DescribeOptionGroups"; Filters: JsonNode = nil;
           MajorEngineVersion: string = ""): Recallable =
  ## postDescribeOptionGroups
  ##   Marker: string
  ##   EngineName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MajorEngineVersion: string
  var query_402657796 = newJObject()
  var formData_402657797 = newJObject()
  add(formData_402657797, "Marker", newJString(Marker))
  add(formData_402657797, "EngineName", newJString(EngineName))
  add(query_402657796, "Version", newJString(Version))
  add(formData_402657797, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657797, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657796, "Action", newJString(Action))
  if Filters != nil:
    formData_402657797.add "Filters", Filters
  add(formData_402657797, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657795.call(nil, query_402657796, nil, formData_402657797,
                               nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_402657776(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_402657777, base: "/",
    makeUrl: url_PostDescribeOptionGroups_402657778,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_402657755 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroups_402657757(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_402657756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Marker: JString
  ##   Version: JString (required)
  ##   Action: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657758 = query.getOrDefault("OptionGroupName")
  valid_402657758 = validateParameter(valid_402657758, JString,
                                      required = false, default = nil)
  if valid_402657758 != nil:
    section.add "OptionGroupName", valid_402657758
  var valid_402657759 = query.getOrDefault("Filters")
  valid_402657759 = validateParameter(valid_402657759, JArray, required = false,
                                      default = nil)
  if valid_402657759 != nil:
    section.add "Filters", valid_402657759
  var valid_402657760 = query.getOrDefault("MaxRecords")
  valid_402657760 = validateParameter(valid_402657760, JInt, required = false,
                                      default = nil)
  if valid_402657760 != nil:
    section.add "MaxRecords", valid_402657760
  var valid_402657761 = query.getOrDefault("Marker")
  valid_402657761 = validateParameter(valid_402657761, JString,
                                      required = false, default = nil)
  if valid_402657761 != nil:
    section.add "Marker", valid_402657761
  var valid_402657762 = query.getOrDefault("Version")
  valid_402657762 = validateParameter(valid_402657762, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657762 != nil:
    section.add "Version", valid_402657762
  var valid_402657763 = query.getOrDefault("Action")
  valid_402657763 = validateParameter(valid_402657763, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657763 != nil:
    section.add "Action", valid_402657763
  var valid_402657764 = query.getOrDefault("EngineName")
  valid_402657764 = validateParameter(valid_402657764, JString,
                                      required = false, default = nil)
  if valid_402657764 != nil:
    section.add "EngineName", valid_402657764
  var valid_402657765 = query.getOrDefault("MajorEngineVersion")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "MajorEngineVersion", valid_402657765
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
  var valid_402657766 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Security-Token", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Signature")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Signature", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657768
  var valid_402657769 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657769 = validateParameter(valid_402657769, JString,
                                      required = false, default = nil)
  if valid_402657769 != nil:
    section.add "X-Amz-Algorithm", valid_402657769
  var valid_402657770 = header.getOrDefault("X-Amz-Date")
  valid_402657770 = validateParameter(valid_402657770, JString,
                                      required = false, default = nil)
  if valid_402657770 != nil:
    section.add "X-Amz-Date", valid_402657770
  var valid_402657771 = header.getOrDefault("X-Amz-Credential")
  valid_402657771 = validateParameter(valid_402657771, JString,
                                      required = false, default = nil)
  if valid_402657771 != nil:
    section.add "X-Amz-Credential", valid_402657771
  var valid_402657772 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657772 = validateParameter(valid_402657772, JString,
                                      required = false, default = nil)
  if valid_402657772 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657772
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657773: Call_GetDescribeOptionGroups_402657755;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657773.validator(path, query, header, formData, body, _)
  let scheme = call_402657773.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657773.makeUrl(scheme.get, call_402657773.host, call_402657773.base,
                                   call_402657773.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657773, uri, valid, _)

proc call*(call_402657774: Call_GetDescribeOptionGroups_402657755;
           OptionGroupName: string = ""; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DescribeOptionGroups"; EngineName: string = "";
           MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_402657775 = newJObject()
  add(query_402657775, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_402657775.add "Filters", Filters
  add(query_402657775, "MaxRecords", newJInt(MaxRecords))
  add(query_402657775, "Marker", newJString(Marker))
  add(query_402657775, "Version", newJString(Version))
  add(query_402657775, "Action", newJString(Action))
  add(query_402657775, "EngineName", newJString(EngineName))
  add(query_402657775, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657774.call(nil, query_402657775, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_402657755(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_402657756, base: "/",
    makeUrl: url_GetDescribeOptionGroups_402657757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_402657821 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOrderableDBInstanceOptions_402657823(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_402657822(path: JsonNode;
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
  var valid_402657824 = query.getOrDefault("Version")
  valid_402657824 = validateParameter(valid_402657824, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657824 != nil:
    section.add "Version", valid_402657824
  var valid_402657825 = query.getOrDefault("Action")
  valid_402657825 = validateParameter(valid_402657825, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657825 != nil:
    section.add "Action", valid_402657825
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
  var valid_402657826 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Security-Token", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-Signature")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-Signature", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Algorithm", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-Date")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-Date", valid_402657830
  var valid_402657831 = header.getOrDefault("X-Amz-Credential")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "X-Amz-Credential", valid_402657831
  var valid_402657832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657832 = validateParameter(valid_402657832, JString,
                                      required = false, default = nil)
  if valid_402657832 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657832
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   Vpc: JBool
  ##   Engine: JString (required)
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   EngineVersion: JString
  section = newJObject()
  var valid_402657833 = formData.getOrDefault("Marker")
  valid_402657833 = validateParameter(valid_402657833, JString,
                                      required = false, default = nil)
  if valid_402657833 != nil:
    section.add "Marker", valid_402657833
  var valid_402657834 = formData.getOrDefault("Vpc")
  valid_402657834 = validateParameter(valid_402657834, JBool, required = false,
                                      default = nil)
  if valid_402657834 != nil:
    section.add "Vpc", valid_402657834
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402657835 = formData.getOrDefault("Engine")
  valid_402657835 = validateParameter(valid_402657835, JString, required = true,
                                      default = nil)
  if valid_402657835 != nil:
    section.add "Engine", valid_402657835
  var valid_402657836 = formData.getOrDefault("DBInstanceClass")
  valid_402657836 = validateParameter(valid_402657836, JString,
                                      required = false, default = nil)
  if valid_402657836 != nil:
    section.add "DBInstanceClass", valid_402657836
  var valid_402657837 = formData.getOrDefault("LicenseModel")
  valid_402657837 = validateParameter(valid_402657837, JString,
                                      required = false, default = nil)
  if valid_402657837 != nil:
    section.add "LicenseModel", valid_402657837
  var valid_402657838 = formData.getOrDefault("MaxRecords")
  valid_402657838 = validateParameter(valid_402657838, JInt, required = false,
                                      default = nil)
  if valid_402657838 != nil:
    section.add "MaxRecords", valid_402657838
  var valid_402657839 = formData.getOrDefault("Filters")
  valid_402657839 = validateParameter(valid_402657839, JArray, required = false,
                                      default = nil)
  if valid_402657839 != nil:
    section.add "Filters", valid_402657839
  var valid_402657840 = formData.getOrDefault("EngineVersion")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "EngineVersion", valid_402657840
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657841: Call_PostDescribeOrderableDBInstanceOptions_402657821;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657841.validator(path, query, header, formData, body, _)
  let scheme = call_402657841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657841.makeUrl(scheme.get, call_402657841.host, call_402657841.base,
                                   call_402657841.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657841, uri, valid, _)

proc call*(call_402657842: Call_PostDescribeOrderableDBInstanceOptions_402657821;
           Engine: string; Marker: string = ""; Vpc: bool = false;
           Version: string = "2013-09-09"; DBInstanceClass: string = "";
           LicenseModel: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeOrderableDBInstanceOptions";
           Filters: JsonNode = nil; EngineVersion: string = ""): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Marker: string
  ##   Vpc: bool
  ##   Engine: string (required)
  ##   Version: string (required)
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   EngineVersion: string
  var query_402657843 = newJObject()
  var formData_402657844 = newJObject()
  add(formData_402657844, "Marker", newJString(Marker))
  add(formData_402657844, "Vpc", newJBool(Vpc))
  add(formData_402657844, "Engine", newJString(Engine))
  add(query_402657843, "Version", newJString(Version))
  add(formData_402657844, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657844, "LicenseModel", newJString(LicenseModel))
  add(formData_402657844, "MaxRecords", newJInt(MaxRecords))
  add(query_402657843, "Action", newJString(Action))
  if Filters != nil:
    formData_402657844.add "Filters", Filters
  add(formData_402657844, "EngineVersion", newJString(EngineVersion))
  result = call_402657842.call(nil, query_402657843, nil, formData_402657844,
                               nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_402657821(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_402657822,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_402657823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_402657798 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOrderableDBInstanceOptions_402657800(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_402657799(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
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
  var valid_402657801 = query.getOrDefault("Filters")
  valid_402657801 = validateParameter(valid_402657801, JArray, required = false,
                                      default = nil)
  if valid_402657801 != nil:
    section.add "Filters", valid_402657801
  var valid_402657802 = query.getOrDefault("MaxRecords")
  valid_402657802 = validateParameter(valid_402657802, JInt, required = false,
                                      default = nil)
  if valid_402657802 != nil:
    section.add "MaxRecords", valid_402657802
  var valid_402657803 = query.getOrDefault("Marker")
  valid_402657803 = validateParameter(valid_402657803, JString,
                                      required = false, default = nil)
  if valid_402657803 != nil:
    section.add "Marker", valid_402657803
  var valid_402657804 = query.getOrDefault("Version")
  valid_402657804 = validateParameter(valid_402657804, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657804 != nil:
    section.add "Version", valid_402657804
  var valid_402657805 = query.getOrDefault("EngineVersion")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "EngineVersion", valid_402657805
  var valid_402657806 = query.getOrDefault("Vpc")
  valid_402657806 = validateParameter(valid_402657806, JBool, required = false,
                                      default = nil)
  if valid_402657806 != nil:
    section.add "Vpc", valid_402657806
  var valid_402657807 = query.getOrDefault("Engine")
  valid_402657807 = validateParameter(valid_402657807, JString, required = true,
                                      default = nil)
  if valid_402657807 != nil:
    section.add "Engine", valid_402657807
  var valid_402657808 = query.getOrDefault("DBInstanceClass")
  valid_402657808 = validateParameter(valid_402657808, JString,
                                      required = false, default = nil)
  if valid_402657808 != nil:
    section.add "DBInstanceClass", valid_402657808
  var valid_402657809 = query.getOrDefault("Action")
  valid_402657809 = validateParameter(valid_402657809, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657809 != nil:
    section.add "Action", valid_402657809
  var valid_402657810 = query.getOrDefault("LicenseModel")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "LicenseModel", valid_402657810
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
  var valid_402657811 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657811 = validateParameter(valid_402657811, JString,
                                      required = false, default = nil)
  if valid_402657811 != nil:
    section.add "X-Amz-Security-Token", valid_402657811
  var valid_402657812 = header.getOrDefault("X-Amz-Signature")
  valid_402657812 = validateParameter(valid_402657812, JString,
                                      required = false, default = nil)
  if valid_402657812 != nil:
    section.add "X-Amz-Signature", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Algorithm", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-Date")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-Date", valid_402657815
  var valid_402657816 = header.getOrDefault("X-Amz-Credential")
  valid_402657816 = validateParameter(valid_402657816, JString,
                                      required = false, default = nil)
  if valid_402657816 != nil:
    section.add "X-Amz-Credential", valid_402657816
  var valid_402657817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657817 = validateParameter(valid_402657817, JString,
                                      required = false, default = nil)
  if valid_402657817 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657818: Call_GetDescribeOrderableDBInstanceOptions_402657798;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657818.validator(path, query, header, formData, body, _)
  let scheme = call_402657818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657818.makeUrl(scheme.get, call_402657818.host, call_402657818.base,
                                   call_402657818.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657818, uri, valid, _)

proc call*(call_402657819: Call_GetDescribeOrderableDBInstanceOptions_402657798;
           Engine: string; Filters: JsonNode = nil; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2013-09-09";
           EngineVersion: string = ""; Vpc: bool = false;
           DBInstanceClass: string = "";
           Action: string = "DescribeOrderableDBInstanceOptions";
           LicenseModel: string = ""): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineVersion: string
  ##   Vpc: bool
  ##   Engine: string (required)
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402657820 = newJObject()
  if Filters != nil:
    query_402657820.add "Filters", Filters
  add(query_402657820, "MaxRecords", newJInt(MaxRecords))
  add(query_402657820, "Marker", newJString(Marker))
  add(query_402657820, "Version", newJString(Version))
  add(query_402657820, "EngineVersion", newJString(EngineVersion))
  add(query_402657820, "Vpc", newJBool(Vpc))
  add(query_402657820, "Engine", newJString(Engine))
  add(query_402657820, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657820, "Action", newJString(Action))
  add(query_402657820, "LicenseModel", newJString(LicenseModel))
  result = call_402657819.call(nil, query_402657820, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_402657798(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_402657799,
    base: "/", makeUrl: url_GetDescribeOrderableDBInstanceOptions_402657800,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_402657870 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstances_402657872(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_402657871(path: JsonNode;
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
  var valid_402657873 = query.getOrDefault("Version")
  valid_402657873 = validateParameter(valid_402657873, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657873 != nil:
    section.add "Version", valid_402657873
  var valid_402657874 = query.getOrDefault("Action")
  valid_402657874 = validateParameter(valid_402657874, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657874 != nil:
    section.add "Action", valid_402657874
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
  var valid_402657875 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Security-Token", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-Signature")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-Signature", valid_402657876
  var valid_402657877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657877
  var valid_402657878 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657878 = validateParameter(valid_402657878, JString,
                                      required = false, default = nil)
  if valid_402657878 != nil:
    section.add "X-Amz-Algorithm", valid_402657878
  var valid_402657879 = header.getOrDefault("X-Amz-Date")
  valid_402657879 = validateParameter(valid_402657879, JString,
                                      required = false, default = nil)
  if valid_402657879 != nil:
    section.add "X-Amz-Date", valid_402657879
  var valid_402657880 = header.getOrDefault("X-Amz-Credential")
  valid_402657880 = validateParameter(valid_402657880, JString,
                                      required = false, default = nil)
  if valid_402657880 != nil:
    section.add "X-Amz-Credential", valid_402657880
  var valid_402657881 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657881 = validateParameter(valid_402657881, JString,
                                      required = false, default = nil)
  if valid_402657881 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657881
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
  ##   Filters: JArray
  section = newJObject()
  var valid_402657882 = formData.getOrDefault("Marker")
  valid_402657882 = validateParameter(valid_402657882, JString,
                                      required = false, default = nil)
  if valid_402657882 != nil:
    section.add "Marker", valid_402657882
  var valid_402657883 = formData.getOrDefault("OfferingType")
  valid_402657883 = validateParameter(valid_402657883, JString,
                                      required = false, default = nil)
  if valid_402657883 != nil:
    section.add "OfferingType", valid_402657883
  var valid_402657884 = formData.getOrDefault("ProductDescription")
  valid_402657884 = validateParameter(valid_402657884, JString,
                                      required = false, default = nil)
  if valid_402657884 != nil:
    section.add "ProductDescription", valid_402657884
  var valid_402657885 = formData.getOrDefault("DBInstanceClass")
  valid_402657885 = validateParameter(valid_402657885, JString,
                                      required = false, default = nil)
  if valid_402657885 != nil:
    section.add "DBInstanceClass", valid_402657885
  var valid_402657886 = formData.getOrDefault("Duration")
  valid_402657886 = validateParameter(valid_402657886, JString,
                                      required = false, default = nil)
  if valid_402657886 != nil:
    section.add "Duration", valid_402657886
  var valid_402657887 = formData.getOrDefault("MaxRecords")
  valid_402657887 = validateParameter(valid_402657887, JInt, required = false,
                                      default = nil)
  if valid_402657887 != nil:
    section.add "MaxRecords", valid_402657887
  var valid_402657888 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657888 = validateParameter(valid_402657888, JString,
                                      required = false, default = nil)
  if valid_402657888 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657888
  var valid_402657889 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402657889 = validateParameter(valid_402657889, JString,
                                      required = false, default = nil)
  if valid_402657889 != nil:
    section.add "ReservedDBInstanceId", valid_402657889
  var valid_402657890 = formData.getOrDefault("MultiAZ")
  valid_402657890 = validateParameter(valid_402657890, JBool, required = false,
                                      default = nil)
  if valid_402657890 != nil:
    section.add "MultiAZ", valid_402657890
  var valid_402657891 = formData.getOrDefault("Filters")
  valid_402657891 = validateParameter(valid_402657891, JArray, required = false,
                                      default = nil)
  if valid_402657891 != nil:
    section.add "Filters", valid_402657891
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657892: Call_PostDescribeReservedDBInstances_402657870;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657892.validator(path, query, header, formData, body, _)
  let scheme = call_402657892.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657892.makeUrl(scheme.get, call_402657892.host, call_402657892.base,
                                   call_402657892.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657892, uri, valid, _)

proc call*(call_402657893: Call_PostDescribeReservedDBInstances_402657870;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2013-09-09";
           DBInstanceClass: string = ""; Duration: string = "";
           MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
           ReservedDBInstanceId: string = ""; MultiAZ: bool = false;
           Action: string = "DescribeReservedDBInstances";
           Filters: JsonNode = nil): Recallable =
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
  ##   Filters: JArray
  var query_402657894 = newJObject()
  var formData_402657895 = newJObject()
  add(formData_402657895, "Marker", newJString(Marker))
  add(formData_402657895, "OfferingType", newJString(OfferingType))
  add(formData_402657895, "ProductDescription", newJString(ProductDescription))
  add(query_402657894, "Version", newJString(Version))
  add(formData_402657895, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657895, "Duration", newJString(Duration))
  add(formData_402657895, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657895, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402657895, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(formData_402657895, "MultiAZ", newJBool(MultiAZ))
  add(query_402657894, "Action", newJString(Action))
  if Filters != nil:
    formData_402657895.add "Filters", Filters
  result = call_402657893.call(nil, query_402657894, nil, formData_402657895,
                               nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_402657870(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_402657871, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_402657872,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_402657845 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstances_402657847(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_402657846(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ReservedDBInstanceId: JString
  ##   Filters: JArray
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
  var valid_402657848 = query.getOrDefault("ReservedDBInstanceId")
  valid_402657848 = validateParameter(valid_402657848, JString,
                                      required = false, default = nil)
  if valid_402657848 != nil:
    section.add "ReservedDBInstanceId", valid_402657848
  var valid_402657849 = query.getOrDefault("Filters")
  valid_402657849 = validateParameter(valid_402657849, JArray, required = false,
                                      default = nil)
  if valid_402657849 != nil:
    section.add "Filters", valid_402657849
  var valid_402657850 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657850 = validateParameter(valid_402657850, JString,
                                      required = false, default = nil)
  if valid_402657850 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657850
  var valid_402657851 = query.getOrDefault("MaxRecords")
  valid_402657851 = validateParameter(valid_402657851, JInt, required = false,
                                      default = nil)
  if valid_402657851 != nil:
    section.add "MaxRecords", valid_402657851
  var valid_402657852 = query.getOrDefault("Marker")
  valid_402657852 = validateParameter(valid_402657852, JString,
                                      required = false, default = nil)
  if valid_402657852 != nil:
    section.add "Marker", valid_402657852
  var valid_402657853 = query.getOrDefault("MultiAZ")
  valid_402657853 = validateParameter(valid_402657853, JBool, required = false,
                                      default = nil)
  if valid_402657853 != nil:
    section.add "MultiAZ", valid_402657853
  var valid_402657854 = query.getOrDefault("Version")
  valid_402657854 = validateParameter(valid_402657854, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657854 != nil:
    section.add "Version", valid_402657854
  var valid_402657855 = query.getOrDefault("Duration")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "Duration", valid_402657855
  var valid_402657856 = query.getOrDefault("DBInstanceClass")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "DBInstanceClass", valid_402657856
  var valid_402657857 = query.getOrDefault("OfferingType")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "OfferingType", valid_402657857
  var valid_402657858 = query.getOrDefault("Action")
  valid_402657858 = validateParameter(valid_402657858, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657858 != nil:
    section.add "Action", valid_402657858
  var valid_402657859 = query.getOrDefault("ProductDescription")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "ProductDescription", valid_402657859
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
  var valid_402657860 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Security-Token", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-Signature")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-Signature", valid_402657861
  var valid_402657862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657862 = validateParameter(valid_402657862, JString,
                                      required = false, default = nil)
  if valid_402657862 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657862
  var valid_402657863 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657863 = validateParameter(valid_402657863, JString,
                                      required = false, default = nil)
  if valid_402657863 != nil:
    section.add "X-Amz-Algorithm", valid_402657863
  var valid_402657864 = header.getOrDefault("X-Amz-Date")
  valid_402657864 = validateParameter(valid_402657864, JString,
                                      required = false, default = nil)
  if valid_402657864 != nil:
    section.add "X-Amz-Date", valid_402657864
  var valid_402657865 = header.getOrDefault("X-Amz-Credential")
  valid_402657865 = validateParameter(valid_402657865, JString,
                                      required = false, default = nil)
  if valid_402657865 != nil:
    section.add "X-Amz-Credential", valid_402657865
  var valid_402657866 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657866 = validateParameter(valid_402657866, JString,
                                      required = false, default = nil)
  if valid_402657866 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657866
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657867: Call_GetDescribeReservedDBInstances_402657845;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657867.validator(path, query, header, formData, body, _)
  let scheme = call_402657867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657867.makeUrl(scheme.get, call_402657867.host, call_402657867.base,
                                   call_402657867.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657867, uri, valid, _)

proc call*(call_402657868: Call_GetDescribeReservedDBInstances_402657845;
           ReservedDBInstanceId: string = ""; Filters: JsonNode = nil;
           ReservedDBInstancesOfferingId: string = ""; MaxRecords: int = 0;
           Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2013-09-09"; Duration: string = "";
           DBInstanceClass: string = ""; OfferingType: string = "";
           Action: string = "DescribeReservedDBInstances";
           ProductDescription: string = ""): Recallable =
  ## getDescribeReservedDBInstances
  ##   ReservedDBInstanceId: string
  ##   Filters: JArray
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
  var query_402657869 = newJObject()
  add(query_402657869, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Filters != nil:
    query_402657869.add "Filters", Filters
  add(query_402657869, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402657869, "MaxRecords", newJInt(MaxRecords))
  add(query_402657869, "Marker", newJString(Marker))
  add(query_402657869, "MultiAZ", newJBool(MultiAZ))
  add(query_402657869, "Version", newJString(Version))
  add(query_402657869, "Duration", newJString(Duration))
  add(query_402657869, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657869, "OfferingType", newJString(OfferingType))
  add(query_402657869, "Action", newJString(Action))
  add(query_402657869, "ProductDescription", newJString(ProductDescription))
  result = call_402657868.call(nil, query_402657869, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_402657845(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_402657846, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_402657847,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_402657920 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstancesOfferings_402657922(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_402657921(path: JsonNode;
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
  var valid_402657923 = query.getOrDefault("Version")
  valid_402657923 = validateParameter(valid_402657923, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657923 != nil:
    section.add "Version", valid_402657923
  var valid_402657924 = query.getOrDefault("Action")
  valid_402657924 = validateParameter(valid_402657924, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402657924 != nil:
    section.add "Action", valid_402657924
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
  var valid_402657925 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657925 = validateParameter(valid_402657925, JString,
                                      required = false, default = nil)
  if valid_402657925 != nil:
    section.add "X-Amz-Security-Token", valid_402657925
  var valid_402657926 = header.getOrDefault("X-Amz-Signature")
  valid_402657926 = validateParameter(valid_402657926, JString,
                                      required = false, default = nil)
  if valid_402657926 != nil:
    section.add "X-Amz-Signature", valid_402657926
  var valid_402657927 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657927 = validateParameter(valid_402657927, JString,
                                      required = false, default = nil)
  if valid_402657927 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657927
  var valid_402657928 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657928 = validateParameter(valid_402657928, JString,
                                      required = false, default = nil)
  if valid_402657928 != nil:
    section.add "X-Amz-Algorithm", valid_402657928
  var valid_402657929 = header.getOrDefault("X-Amz-Date")
  valid_402657929 = validateParameter(valid_402657929, JString,
                                      required = false, default = nil)
  if valid_402657929 != nil:
    section.add "X-Amz-Date", valid_402657929
  var valid_402657930 = header.getOrDefault("X-Amz-Credential")
  valid_402657930 = validateParameter(valid_402657930, JString,
                                      required = false, default = nil)
  if valid_402657930 != nil:
    section.add "X-Amz-Credential", valid_402657930
  var valid_402657931 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657931 = validateParameter(valid_402657931, JString,
                                      required = false, default = nil)
  if valid_402657931 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657931
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
  ##   Filters: JArray
  section = newJObject()
  var valid_402657932 = formData.getOrDefault("Marker")
  valid_402657932 = validateParameter(valid_402657932, JString,
                                      required = false, default = nil)
  if valid_402657932 != nil:
    section.add "Marker", valid_402657932
  var valid_402657933 = formData.getOrDefault("OfferingType")
  valid_402657933 = validateParameter(valid_402657933, JString,
                                      required = false, default = nil)
  if valid_402657933 != nil:
    section.add "OfferingType", valid_402657933
  var valid_402657934 = formData.getOrDefault("ProductDescription")
  valid_402657934 = validateParameter(valid_402657934, JString,
                                      required = false, default = nil)
  if valid_402657934 != nil:
    section.add "ProductDescription", valid_402657934
  var valid_402657935 = formData.getOrDefault("DBInstanceClass")
  valid_402657935 = validateParameter(valid_402657935, JString,
                                      required = false, default = nil)
  if valid_402657935 != nil:
    section.add "DBInstanceClass", valid_402657935
  var valid_402657936 = formData.getOrDefault("Duration")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "Duration", valid_402657936
  var valid_402657937 = formData.getOrDefault("MaxRecords")
  valid_402657937 = validateParameter(valid_402657937, JInt, required = false,
                                      default = nil)
  if valid_402657937 != nil:
    section.add "MaxRecords", valid_402657937
  var valid_402657938 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657938 = validateParameter(valid_402657938, JString,
                                      required = false, default = nil)
  if valid_402657938 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657938
  var valid_402657939 = formData.getOrDefault("MultiAZ")
  valid_402657939 = validateParameter(valid_402657939, JBool, required = false,
                                      default = nil)
  if valid_402657939 != nil:
    section.add "MultiAZ", valid_402657939
  var valid_402657940 = formData.getOrDefault("Filters")
  valid_402657940 = validateParameter(valid_402657940, JArray, required = false,
                                      default = nil)
  if valid_402657940 != nil:
    section.add "Filters", valid_402657940
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657941: Call_PostDescribeReservedDBInstancesOfferings_402657920;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657941.validator(path, query, header, formData, body, _)
  let scheme = call_402657941.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657941.makeUrl(scheme.get, call_402657941.host, call_402657941.base,
                                   call_402657941.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657941, uri, valid, _)

proc call*(call_402657942: Call_PostDescribeReservedDBInstancesOfferings_402657920;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2013-09-09";
           DBInstanceClass: string = ""; Duration: string = "";
           MaxRecords: int = 0; ReservedDBInstancesOfferingId: string = "";
           MultiAZ: bool = false;
           Action: string = "DescribeReservedDBInstancesOfferings";
           Filters: JsonNode = nil): Recallable =
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
  ##   Filters: JArray
  var query_402657943 = newJObject()
  var formData_402657944 = newJObject()
  add(formData_402657944, "Marker", newJString(Marker))
  add(formData_402657944, "OfferingType", newJString(OfferingType))
  add(formData_402657944, "ProductDescription", newJString(ProductDescription))
  add(query_402657943, "Version", newJString(Version))
  add(formData_402657944, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657944, "Duration", newJString(Duration))
  add(formData_402657944, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657944, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402657944, "MultiAZ", newJBool(MultiAZ))
  add(query_402657943, "Action", newJString(Action))
  if Filters != nil:
    formData_402657944.add "Filters", Filters
  result = call_402657942.call(nil, query_402657943, nil, formData_402657944,
                               nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_402657920(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_402657921,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_402657922,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_402657896 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstancesOfferings_402657898(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_402657897(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
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
  var valid_402657899 = query.getOrDefault("Filters")
  valid_402657899 = validateParameter(valid_402657899, JArray, required = false,
                                      default = nil)
  if valid_402657899 != nil:
    section.add "Filters", valid_402657899
  var valid_402657900 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657900 = validateParameter(valid_402657900, JString,
                                      required = false, default = nil)
  if valid_402657900 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657900
  var valid_402657901 = query.getOrDefault("MaxRecords")
  valid_402657901 = validateParameter(valid_402657901, JInt, required = false,
                                      default = nil)
  if valid_402657901 != nil:
    section.add "MaxRecords", valid_402657901
  var valid_402657902 = query.getOrDefault("Marker")
  valid_402657902 = validateParameter(valid_402657902, JString,
                                      required = false, default = nil)
  if valid_402657902 != nil:
    section.add "Marker", valid_402657902
  var valid_402657903 = query.getOrDefault("MultiAZ")
  valid_402657903 = validateParameter(valid_402657903, JBool, required = false,
                                      default = nil)
  if valid_402657903 != nil:
    section.add "MultiAZ", valid_402657903
  var valid_402657904 = query.getOrDefault("Version")
  valid_402657904 = validateParameter(valid_402657904, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657904 != nil:
    section.add "Version", valid_402657904
  var valid_402657905 = query.getOrDefault("Duration")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "Duration", valid_402657905
  var valid_402657906 = query.getOrDefault("DBInstanceClass")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "DBInstanceClass", valid_402657906
  var valid_402657907 = query.getOrDefault("OfferingType")
  valid_402657907 = validateParameter(valid_402657907, JString,
                                      required = false, default = nil)
  if valid_402657907 != nil:
    section.add "OfferingType", valid_402657907
  var valid_402657908 = query.getOrDefault("Action")
  valid_402657908 = validateParameter(valid_402657908, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402657908 != nil:
    section.add "Action", valid_402657908
  var valid_402657909 = query.getOrDefault("ProductDescription")
  valid_402657909 = validateParameter(valid_402657909, JString,
                                      required = false, default = nil)
  if valid_402657909 != nil:
    section.add "ProductDescription", valid_402657909
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
  var valid_402657910 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657910 = validateParameter(valid_402657910, JString,
                                      required = false, default = nil)
  if valid_402657910 != nil:
    section.add "X-Amz-Security-Token", valid_402657910
  var valid_402657911 = header.getOrDefault("X-Amz-Signature")
  valid_402657911 = validateParameter(valid_402657911, JString,
                                      required = false, default = nil)
  if valid_402657911 != nil:
    section.add "X-Amz-Signature", valid_402657911
  var valid_402657912 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657912 = validateParameter(valid_402657912, JString,
                                      required = false, default = nil)
  if valid_402657912 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657912
  var valid_402657913 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657913 = validateParameter(valid_402657913, JString,
                                      required = false, default = nil)
  if valid_402657913 != nil:
    section.add "X-Amz-Algorithm", valid_402657913
  var valid_402657914 = header.getOrDefault("X-Amz-Date")
  valid_402657914 = validateParameter(valid_402657914, JString,
                                      required = false, default = nil)
  if valid_402657914 != nil:
    section.add "X-Amz-Date", valid_402657914
  var valid_402657915 = header.getOrDefault("X-Amz-Credential")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-Credential", valid_402657915
  var valid_402657916 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657916 = validateParameter(valid_402657916, JString,
                                      required = false, default = nil)
  if valid_402657916 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657916
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657917: Call_GetDescribeReservedDBInstancesOfferings_402657896;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657917.validator(path, query, header, formData, body, _)
  let scheme = call_402657917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657917.makeUrl(scheme.get, call_402657917.host, call_402657917.base,
                                   call_402657917.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657917, uri, valid, _)

proc call*(call_402657918: Call_GetDescribeReservedDBInstancesOfferings_402657896;
           Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
           MaxRecords: int = 0; Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2013-09-09"; Duration: string = "";
           DBInstanceClass: string = ""; OfferingType: string = "";
           Action: string = "DescribeReservedDBInstancesOfferings";
           ProductDescription: string = ""): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   Filters: JArray
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
  var query_402657919 = newJObject()
  if Filters != nil:
    query_402657919.add "Filters", Filters
  add(query_402657919, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402657919, "MaxRecords", newJInt(MaxRecords))
  add(query_402657919, "Marker", newJString(Marker))
  add(query_402657919, "MultiAZ", newJBool(MultiAZ))
  add(query_402657919, "Version", newJString(Version))
  add(query_402657919, "Duration", newJString(Duration))
  add(query_402657919, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657919, "OfferingType", newJString(OfferingType))
  add(query_402657919, "Action", newJString(Action))
  add(query_402657919, "ProductDescription", newJString(ProductDescription))
  result = call_402657918.call(nil, query_402657919, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_402657896(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_402657897,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_402657898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_402657964 = ref object of OpenApiRestCall_402656035
proc url_PostDownloadDBLogFilePortion_402657966(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_402657965(path: JsonNode;
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
  var valid_402657967 = query.getOrDefault("Version")
  valid_402657967 = validateParameter(valid_402657967, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657967 != nil:
    section.add "Version", valid_402657967
  var valid_402657968 = query.getOrDefault("Action")
  valid_402657968 = validateParameter(valid_402657968, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402657968 != nil:
    section.add "Action", valid_402657968
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
  var valid_402657969 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657969 = validateParameter(valid_402657969, JString,
                                      required = false, default = nil)
  if valid_402657969 != nil:
    section.add "X-Amz-Security-Token", valid_402657969
  var valid_402657970 = header.getOrDefault("X-Amz-Signature")
  valid_402657970 = validateParameter(valid_402657970, JString,
                                      required = false, default = nil)
  if valid_402657970 != nil:
    section.add "X-Amz-Signature", valid_402657970
  var valid_402657971 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657971 = validateParameter(valid_402657971, JString,
                                      required = false, default = nil)
  if valid_402657971 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657971
  var valid_402657972 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657972 = validateParameter(valid_402657972, JString,
                                      required = false, default = nil)
  if valid_402657972 != nil:
    section.add "X-Amz-Algorithm", valid_402657972
  var valid_402657973 = header.getOrDefault("X-Amz-Date")
  valid_402657973 = validateParameter(valid_402657973, JString,
                                      required = false, default = nil)
  if valid_402657973 != nil:
    section.add "X-Amz-Date", valid_402657973
  var valid_402657974 = header.getOrDefault("X-Amz-Credential")
  valid_402657974 = validateParameter(valid_402657974, JString,
                                      required = false, default = nil)
  if valid_402657974 != nil:
    section.add "X-Amz-Credential", valid_402657974
  var valid_402657975 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657975 = validateParameter(valid_402657975, JString,
                                      required = false, default = nil)
  if valid_402657975 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657975
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   NumberOfLines: JInt
  section = newJObject()
  var valid_402657976 = formData.getOrDefault("Marker")
  valid_402657976 = validateParameter(valid_402657976, JString,
                                      required = false, default = nil)
  if valid_402657976 != nil:
    section.add "Marker", valid_402657976
  assert formData != nil,
         "formData argument is necessary due to required `LogFileName` field"
  var valid_402657977 = formData.getOrDefault("LogFileName")
  valid_402657977 = validateParameter(valid_402657977, JString, required = true,
                                      default = nil)
  if valid_402657977 != nil:
    section.add "LogFileName", valid_402657977
  var valid_402657978 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657978 = validateParameter(valid_402657978, JString, required = true,
                                      default = nil)
  if valid_402657978 != nil:
    section.add "DBInstanceIdentifier", valid_402657978
  var valid_402657979 = formData.getOrDefault("NumberOfLines")
  valid_402657979 = validateParameter(valid_402657979, JInt, required = false,
                                      default = nil)
  if valid_402657979 != nil:
    section.add "NumberOfLines", valid_402657979
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657980: Call_PostDownloadDBLogFilePortion_402657964;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657980.validator(path, query, header, formData, body, _)
  let scheme = call_402657980.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657980.makeUrl(scheme.get, call_402657980.host, call_402657980.base,
                                   call_402657980.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657980, uri, valid, _)

proc call*(call_402657981: Call_PostDownloadDBLogFilePortion_402657964;
           LogFileName: string; DBInstanceIdentifier: string;
           Marker: string = ""; Version: string = "2013-09-09";
           NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Action: string (required)
  var query_402657982 = newJObject()
  var formData_402657983 = newJObject()
  add(formData_402657983, "Marker", newJString(Marker))
  add(query_402657982, "Version", newJString(Version))
  add(formData_402657983, "LogFileName", newJString(LogFileName))
  add(formData_402657983, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657983, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402657982, "Action", newJString(Action))
  result = call_402657981.call(nil, query_402657982, nil, formData_402657983,
                               nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_402657964(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_402657965, base: "/",
    makeUrl: url_PostDownloadDBLogFilePortion_402657966,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_402657945 = ref object of OpenApiRestCall_402656035
proc url_GetDownloadDBLogFilePortion_402657947(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_402657946(path: JsonNode;
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
  var valid_402657948 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657948 = validateParameter(valid_402657948, JString, required = true,
                                      default = nil)
  if valid_402657948 != nil:
    section.add "DBInstanceIdentifier", valid_402657948
  var valid_402657949 = query.getOrDefault("NumberOfLines")
  valid_402657949 = validateParameter(valid_402657949, JInt, required = false,
                                      default = nil)
  if valid_402657949 != nil:
    section.add "NumberOfLines", valid_402657949
  var valid_402657950 = query.getOrDefault("Marker")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "Marker", valid_402657950
  var valid_402657951 = query.getOrDefault("Version")
  valid_402657951 = validateParameter(valid_402657951, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657951 != nil:
    section.add "Version", valid_402657951
  var valid_402657952 = query.getOrDefault("LogFileName")
  valid_402657952 = validateParameter(valid_402657952, JString, required = true,
                                      default = nil)
  if valid_402657952 != nil:
    section.add "LogFileName", valid_402657952
  var valid_402657953 = query.getOrDefault("Action")
  valid_402657953 = validateParameter(valid_402657953, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402657953 != nil:
    section.add "Action", valid_402657953
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
  var valid_402657954 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657954 = validateParameter(valid_402657954, JString,
                                      required = false, default = nil)
  if valid_402657954 != nil:
    section.add "X-Amz-Security-Token", valid_402657954
  var valid_402657955 = header.getOrDefault("X-Amz-Signature")
  valid_402657955 = validateParameter(valid_402657955, JString,
                                      required = false, default = nil)
  if valid_402657955 != nil:
    section.add "X-Amz-Signature", valid_402657955
  var valid_402657956 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657956 = validateParameter(valid_402657956, JString,
                                      required = false, default = nil)
  if valid_402657956 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657956
  var valid_402657957 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657957 = validateParameter(valid_402657957, JString,
                                      required = false, default = nil)
  if valid_402657957 != nil:
    section.add "X-Amz-Algorithm", valid_402657957
  var valid_402657958 = header.getOrDefault("X-Amz-Date")
  valid_402657958 = validateParameter(valid_402657958, JString,
                                      required = false, default = nil)
  if valid_402657958 != nil:
    section.add "X-Amz-Date", valid_402657958
  var valid_402657959 = header.getOrDefault("X-Amz-Credential")
  valid_402657959 = validateParameter(valid_402657959, JString,
                                      required = false, default = nil)
  if valid_402657959 != nil:
    section.add "X-Amz-Credential", valid_402657959
  var valid_402657960 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657960 = validateParameter(valid_402657960, JString,
                                      required = false, default = nil)
  if valid_402657960 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657960
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657961: Call_GetDownloadDBLogFilePortion_402657945;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657961.validator(path, query, header, formData, body, _)
  let scheme = call_402657961.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657961.makeUrl(scheme.get, call_402657961.host, call_402657961.base,
                                   call_402657961.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657961, uri, valid, _)

proc call*(call_402657962: Call_GetDownloadDBLogFilePortion_402657945;
           DBInstanceIdentifier: string; LogFileName: string;
           NumberOfLines: int = 0; Marker: string = "";
           Version: string = "2013-09-09";
           Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   Action: string (required)
  var query_402657963 = newJObject()
  add(query_402657963, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657963, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402657963, "Marker", newJString(Marker))
  add(query_402657963, "Version", newJString(Version))
  add(query_402657963, "LogFileName", newJString(LogFileName))
  add(query_402657963, "Action", newJString(Action))
  result = call_402657962.call(nil, query_402657963, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_402657945(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_402657946, base: "/",
    makeUrl: url_GetDownloadDBLogFilePortion_402657947,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_402658001 = ref object of OpenApiRestCall_402656035
proc url_PostListTagsForResource_402658003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_402658002(path: JsonNode; query: JsonNode;
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
  var valid_402658004 = query.getOrDefault("Version")
  valid_402658004 = validateParameter(valid_402658004, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658004 != nil:
    section.add "Version", valid_402658004
  var valid_402658005 = query.getOrDefault("Action")
  valid_402658005 = validateParameter(valid_402658005, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402658005 != nil:
    section.add "Action", valid_402658005
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
  var valid_402658006 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658006 = validateParameter(valid_402658006, JString,
                                      required = false, default = nil)
  if valid_402658006 != nil:
    section.add "X-Amz-Security-Token", valid_402658006
  var valid_402658007 = header.getOrDefault("X-Amz-Signature")
  valid_402658007 = validateParameter(valid_402658007, JString,
                                      required = false, default = nil)
  if valid_402658007 != nil:
    section.add "X-Amz-Signature", valid_402658007
  var valid_402658008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658008 = validateParameter(valid_402658008, JString,
                                      required = false, default = nil)
  if valid_402658008 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658008
  var valid_402658009 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658009 = validateParameter(valid_402658009, JString,
                                      required = false, default = nil)
  if valid_402658009 != nil:
    section.add "X-Amz-Algorithm", valid_402658009
  var valid_402658010 = header.getOrDefault("X-Amz-Date")
  valid_402658010 = validateParameter(valid_402658010, JString,
                                      required = false, default = nil)
  if valid_402658010 != nil:
    section.add "X-Amz-Date", valid_402658010
  var valid_402658011 = header.getOrDefault("X-Amz-Credential")
  valid_402658011 = validateParameter(valid_402658011, JString,
                                      required = false, default = nil)
  if valid_402658011 != nil:
    section.add "X-Amz-Credential", valid_402658011
  var valid_402658012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658012 = validateParameter(valid_402658012, JString,
                                      required = false, default = nil)
  if valid_402658012 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658012
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_402658013 = formData.getOrDefault("Filters")
  valid_402658013 = validateParameter(valid_402658013, JArray, required = false,
                                      default = nil)
  if valid_402658013 != nil:
    section.add "Filters", valid_402658013
  assert formData != nil,
         "formData argument is necessary due to required `ResourceName` field"
  var valid_402658014 = formData.getOrDefault("ResourceName")
  valid_402658014 = validateParameter(valid_402658014, JString, required = true,
                                      default = nil)
  if valid_402658014 != nil:
    section.add "ResourceName", valid_402658014
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658015: Call_PostListTagsForResource_402658001;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658015.validator(path, query, header, formData, body, _)
  let scheme = call_402658015.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658015.makeUrl(scheme.get, call_402658015.host, call_402658015.base,
                                   call_402658015.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658015, uri, valid, _)

proc call*(call_402658016: Call_PostListTagsForResource_402658001;
           ResourceName: string; Version: string = "2013-09-09";
           Action: string = "ListTagsForResource"; Filters: JsonNode = nil): Recallable =
  ## postListTagsForResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  var query_402658017 = newJObject()
  var formData_402658018 = newJObject()
  add(query_402658017, "Version", newJString(Version))
  add(query_402658017, "Action", newJString(Action))
  if Filters != nil:
    formData_402658018.add "Filters", Filters
  add(formData_402658018, "ResourceName", newJString(ResourceName))
  result = call_402658016.call(nil, query_402658017, nil, formData_402658018,
                               nil)

var postListTagsForResource* = Call_PostListTagsForResource_402658001(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_402658002, base: "/",
    makeUrl: url_PostListTagsForResource_402658003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_402657984 = ref object of OpenApiRestCall_402656035
proc url_GetListTagsForResource_402657986(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_402657985(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   Version: JString (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  var valid_402657987 = query.getOrDefault("Filters")
  valid_402657987 = validateParameter(valid_402657987, JArray, required = false,
                                      default = nil)
  if valid_402657987 != nil:
    section.add "Filters", valid_402657987
  var valid_402657988 = query.getOrDefault("Version")
  valid_402657988 = validateParameter(valid_402657988, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402657988 != nil:
    section.add "Version", valid_402657988
  var valid_402657989 = query.getOrDefault("ResourceName")
  valid_402657989 = validateParameter(valid_402657989, JString, required = true,
                                      default = nil)
  if valid_402657989 != nil:
    section.add "ResourceName", valid_402657989
  var valid_402657990 = query.getOrDefault("Action")
  valid_402657990 = validateParameter(valid_402657990, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402657990 != nil:
    section.add "Action", valid_402657990
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
  var valid_402657991 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "X-Amz-Security-Token", valid_402657991
  var valid_402657992 = header.getOrDefault("X-Amz-Signature")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "X-Amz-Signature", valid_402657992
  var valid_402657993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657993
  var valid_402657994 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657994 = validateParameter(valid_402657994, JString,
                                      required = false, default = nil)
  if valid_402657994 != nil:
    section.add "X-Amz-Algorithm", valid_402657994
  var valid_402657995 = header.getOrDefault("X-Amz-Date")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "X-Amz-Date", valid_402657995
  var valid_402657996 = header.getOrDefault("X-Amz-Credential")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "X-Amz-Credential", valid_402657996
  var valid_402657997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657997 = validateParameter(valid_402657997, JString,
                                      required = false, default = nil)
  if valid_402657997 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657998: Call_GetListTagsForResource_402657984;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657998.validator(path, query, header, formData, body, _)
  let scheme = call_402657998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657998.makeUrl(scheme.get, call_402657998.host, call_402657998.base,
                                   call_402657998.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657998, uri, valid, _)

proc call*(call_402657999: Call_GetListTagsForResource_402657984;
           ResourceName: string; Filters: JsonNode = nil;
           Version: string = "2013-09-09";
           Action: string = "ListTagsForResource"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402658000 = newJObject()
  if Filters != nil:
    query_402658000.add "Filters", Filters
  add(query_402658000, "Version", newJString(Version))
  add(query_402658000, "ResourceName", newJString(ResourceName))
  add(query_402658000, "Action", newJString(Action))
  result = call_402657999.call(nil, query_402658000, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_402657984(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_402657985, base: "/",
    makeUrl: url_GetListTagsForResource_402657986,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_402658052 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBInstance_402658054(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_402658053(path: JsonNode; query: JsonNode;
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
  var valid_402658055 = query.getOrDefault("Version")
  valid_402658055 = validateParameter(valid_402658055, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658055 != nil:
    section.add "Version", valid_402658055
  var valid_402658056 = query.getOrDefault("Action")
  valid_402658056 = validateParameter(valid_402658056, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402658056 != nil:
    section.add "Action", valid_402658056
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
  var valid_402658057 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658057 = validateParameter(valid_402658057, JString,
                                      required = false, default = nil)
  if valid_402658057 != nil:
    section.add "X-Amz-Security-Token", valid_402658057
  var valid_402658058 = header.getOrDefault("X-Amz-Signature")
  valid_402658058 = validateParameter(valid_402658058, JString,
                                      required = false, default = nil)
  if valid_402658058 != nil:
    section.add "X-Amz-Signature", valid_402658058
  var valid_402658059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658059 = validateParameter(valid_402658059, JString,
                                      required = false, default = nil)
  if valid_402658059 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658059
  var valid_402658060 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658060 = validateParameter(valid_402658060, JString,
                                      required = false, default = nil)
  if valid_402658060 != nil:
    section.add "X-Amz-Algorithm", valid_402658060
  var valid_402658061 = header.getOrDefault("X-Amz-Date")
  valid_402658061 = validateParameter(valid_402658061, JString,
                                      required = false, default = nil)
  if valid_402658061 != nil:
    section.add "X-Amz-Date", valid_402658061
  var valid_402658062 = header.getOrDefault("X-Amz-Credential")
  valid_402658062 = validateParameter(valid_402658062, JString,
                                      required = false, default = nil)
  if valid_402658062 != nil:
    section.add "X-Amz-Credential", valid_402658062
  var valid_402658063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658063 = validateParameter(valid_402658063, JString,
                                      required = false, default = nil)
  if valid_402658063 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658063
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
  var valid_402658064 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658064 = validateParameter(valid_402658064, JString,
                                      required = false, default = nil)
  if valid_402658064 != nil:
    section.add "PreferredBackupWindow", valid_402658064
  var valid_402658065 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658065 = validateParameter(valid_402658065, JBool, required = false,
                                      default = nil)
  if valid_402658065 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658065
  var valid_402658066 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402658066 = validateParameter(valid_402658066, JArray, required = false,
                                      default = nil)
  if valid_402658066 != nil:
    section.add "VpcSecurityGroupIds", valid_402658066
  var valid_402658067 = formData.getOrDefault("AllocatedStorage")
  valid_402658067 = validateParameter(valid_402658067, JInt, required = false,
                                      default = nil)
  if valid_402658067 != nil:
    section.add "AllocatedStorage", valid_402658067
  var valid_402658068 = formData.getOrDefault("MasterUserPassword")
  valid_402658068 = validateParameter(valid_402658068, JString,
                                      required = false, default = nil)
  if valid_402658068 != nil:
    section.add "MasterUserPassword", valid_402658068
  var valid_402658069 = formData.getOrDefault("ApplyImmediately")
  valid_402658069 = validateParameter(valid_402658069, JBool, required = false,
                                      default = nil)
  if valid_402658069 != nil:
    section.add "ApplyImmediately", valid_402658069
  var valid_402658070 = formData.getOrDefault("DBParameterGroupName")
  valid_402658070 = validateParameter(valid_402658070, JString,
                                      required = false, default = nil)
  if valid_402658070 != nil:
    section.add "DBParameterGroupName", valid_402658070
  var valid_402658071 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_402658071 = validateParameter(valid_402658071, JBool, required = false,
                                      default = nil)
  if valid_402658071 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402658071
  var valid_402658072 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402658072 = validateParameter(valid_402658072, JString,
                                      required = false, default = nil)
  if valid_402658072 != nil:
    section.add "PreferredMaintenanceWindow", valid_402658072
  var valid_402658073 = formData.getOrDefault("DBInstanceClass")
  valid_402658073 = validateParameter(valid_402658073, JString,
                                      required = false, default = nil)
  if valid_402658073 != nil:
    section.add "DBInstanceClass", valid_402658073
  var valid_402658074 = formData.getOrDefault("Iops")
  valid_402658074 = validateParameter(valid_402658074, JInt, required = false,
                                      default = nil)
  if valid_402658074 != nil:
    section.add "Iops", valid_402658074
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658075 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658075 = validateParameter(valid_402658075, JString, required = true,
                                      default = nil)
  if valid_402658075 != nil:
    section.add "DBInstanceIdentifier", valid_402658075
  var valid_402658076 = formData.getOrDefault("MultiAZ")
  valid_402658076 = validateParameter(valid_402658076, JBool, required = false,
                                      default = nil)
  if valid_402658076 != nil:
    section.add "MultiAZ", valid_402658076
  var valid_402658077 = formData.getOrDefault("DBSecurityGroups")
  valid_402658077 = validateParameter(valid_402658077, JArray, required = false,
                                      default = nil)
  if valid_402658077 != nil:
    section.add "DBSecurityGroups", valid_402658077
  var valid_402658078 = formData.getOrDefault("OptionGroupName")
  valid_402658078 = validateParameter(valid_402658078, JString,
                                      required = false, default = nil)
  if valid_402658078 != nil:
    section.add "OptionGroupName", valid_402658078
  var valid_402658079 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_402658079 = validateParameter(valid_402658079, JString,
                                      required = false, default = nil)
  if valid_402658079 != nil:
    section.add "NewDBInstanceIdentifier", valid_402658079
  var valid_402658080 = formData.getOrDefault("EngineVersion")
  valid_402658080 = validateParameter(valid_402658080, JString,
                                      required = false, default = nil)
  if valid_402658080 != nil:
    section.add "EngineVersion", valid_402658080
  var valid_402658081 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658081 = validateParameter(valid_402658081, JInt, required = false,
                                      default = nil)
  if valid_402658081 != nil:
    section.add "BackupRetentionPeriod", valid_402658081
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658082: Call_PostModifyDBInstance_402658052;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658082.validator(path, query, header, formData, body, _)
  let scheme = call_402658082.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658082.makeUrl(scheme.get, call_402658082.host, call_402658082.base,
                                   call_402658082.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658082, uri, valid, _)

proc call*(call_402658083: Call_PostModifyDBInstance_402658052;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; AllocatedStorage: int = 0;
           MasterUserPassword: string = ""; ApplyImmediately: bool = false;
           Version: string = "2013-09-09"; DBParameterGroupName: string = "";
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
  var query_402658084 = newJObject()
  var formData_402658085 = newJObject()
  add(formData_402658085, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402658085, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402658085.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402658085, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402658085, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402658085, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658084, "Version", newJString(Version))
  add(formData_402658085, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402658085, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_402658085, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402658085, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658085, "Iops", newJInt(Iops))
  add(formData_402658085, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658085, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402658085.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402658085, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658084, "Action", newJString(Action))
  add(formData_402658085, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_402658085, "EngineVersion", newJString(EngineVersion))
  add(formData_402658085, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658083.call(nil, query_402658084, nil, formData_402658085,
                               nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_402658052(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_402658053, base: "/",
    makeUrl: url_PostModifyDBInstance_402658054,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_402658019 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBInstance_402658021(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_402658020(path: JsonNode; query: JsonNode;
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
  var valid_402658022 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402658022 = validateParameter(valid_402658022, JArray, required = false,
                                      default = nil)
  if valid_402658022 != nil:
    section.add "VpcSecurityGroupIds", valid_402658022
  var valid_402658023 = query.getOrDefault("OptionGroupName")
  valid_402658023 = validateParameter(valid_402658023, JString,
                                      required = false, default = nil)
  if valid_402658023 != nil:
    section.add "OptionGroupName", valid_402658023
  var valid_402658024 = query.getOrDefault("PreferredBackupWindow")
  valid_402658024 = validateParameter(valid_402658024, JString,
                                      required = false, default = nil)
  if valid_402658024 != nil:
    section.add "PreferredBackupWindow", valid_402658024
  var valid_402658025 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402658025 = validateParameter(valid_402658025, JString,
                                      required = false, default = nil)
  if valid_402658025 != nil:
    section.add "PreferredMaintenanceWindow", valid_402658025
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658026 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658026 = validateParameter(valid_402658026, JString, required = true,
                                      default = nil)
  if valid_402658026 != nil:
    section.add "DBInstanceIdentifier", valid_402658026
  var valid_402658027 = query.getOrDefault("DBParameterGroupName")
  valid_402658027 = validateParameter(valid_402658027, JString,
                                      required = false, default = nil)
  if valid_402658027 != nil:
    section.add "DBParameterGroupName", valid_402658027
  var valid_402658028 = query.getOrDefault("MasterUserPassword")
  valid_402658028 = validateParameter(valid_402658028, JString,
                                      required = false, default = nil)
  if valid_402658028 != nil:
    section.add "MasterUserPassword", valid_402658028
  var valid_402658029 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_402658029 = validateParameter(valid_402658029, JBool, required = false,
                                      default = nil)
  if valid_402658029 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402658029
  var valid_402658030 = query.getOrDefault("Iops")
  valid_402658030 = validateParameter(valid_402658030, JInt, required = false,
                                      default = nil)
  if valid_402658030 != nil:
    section.add "Iops", valid_402658030
  var valid_402658031 = query.getOrDefault("ApplyImmediately")
  valid_402658031 = validateParameter(valid_402658031, JBool, required = false,
                                      default = nil)
  if valid_402658031 != nil:
    section.add "ApplyImmediately", valid_402658031
  var valid_402658032 = query.getOrDefault("MultiAZ")
  valid_402658032 = validateParameter(valid_402658032, JBool, required = false,
                                      default = nil)
  if valid_402658032 != nil:
    section.add "MultiAZ", valid_402658032
  var valid_402658033 = query.getOrDefault("Version")
  valid_402658033 = validateParameter(valid_402658033, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658033 != nil:
    section.add "Version", valid_402658033
  var valid_402658034 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_402658034 = validateParameter(valid_402658034, JString,
                                      required = false, default = nil)
  if valid_402658034 != nil:
    section.add "NewDBInstanceIdentifier", valid_402658034
  var valid_402658035 = query.getOrDefault("EngineVersion")
  valid_402658035 = validateParameter(valid_402658035, JString,
                                      required = false, default = nil)
  if valid_402658035 != nil:
    section.add "EngineVersion", valid_402658035
  var valid_402658036 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658036 = validateParameter(valid_402658036, JBool, required = false,
                                      default = nil)
  if valid_402658036 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658036
  var valid_402658037 = query.getOrDefault("AllocatedStorage")
  valid_402658037 = validateParameter(valid_402658037, JInt, required = false,
                                      default = nil)
  if valid_402658037 != nil:
    section.add "AllocatedStorage", valid_402658037
  var valid_402658038 = query.getOrDefault("DBInstanceClass")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "DBInstanceClass", valid_402658038
  var valid_402658039 = query.getOrDefault("Action")
  valid_402658039 = validateParameter(valid_402658039, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402658039 != nil:
    section.add "Action", valid_402658039
  var valid_402658040 = query.getOrDefault("BackupRetentionPeriod")
  valid_402658040 = validateParameter(valid_402658040, JInt, required = false,
                                      default = nil)
  if valid_402658040 != nil:
    section.add "BackupRetentionPeriod", valid_402658040
  var valid_402658041 = query.getOrDefault("DBSecurityGroups")
  valid_402658041 = validateParameter(valid_402658041, JArray, required = false,
                                      default = nil)
  if valid_402658041 != nil:
    section.add "DBSecurityGroups", valid_402658041
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
  var valid_402658042 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658042 = validateParameter(valid_402658042, JString,
                                      required = false, default = nil)
  if valid_402658042 != nil:
    section.add "X-Amz-Security-Token", valid_402658042
  var valid_402658043 = header.getOrDefault("X-Amz-Signature")
  valid_402658043 = validateParameter(valid_402658043, JString,
                                      required = false, default = nil)
  if valid_402658043 != nil:
    section.add "X-Amz-Signature", valid_402658043
  var valid_402658044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658044 = validateParameter(valid_402658044, JString,
                                      required = false, default = nil)
  if valid_402658044 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658044
  var valid_402658045 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658045 = validateParameter(valid_402658045, JString,
                                      required = false, default = nil)
  if valid_402658045 != nil:
    section.add "X-Amz-Algorithm", valid_402658045
  var valid_402658046 = header.getOrDefault("X-Amz-Date")
  valid_402658046 = validateParameter(valid_402658046, JString,
                                      required = false, default = nil)
  if valid_402658046 != nil:
    section.add "X-Amz-Date", valid_402658046
  var valid_402658047 = header.getOrDefault("X-Amz-Credential")
  valid_402658047 = validateParameter(valid_402658047, JString,
                                      required = false, default = nil)
  if valid_402658047 != nil:
    section.add "X-Amz-Credential", valid_402658047
  var valid_402658048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658048 = validateParameter(valid_402658048, JString,
                                      required = false, default = nil)
  if valid_402658048 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658049: Call_GetModifyDBInstance_402658019;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658049.validator(path, query, header, formData, body, _)
  let scheme = call_402658049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658049.makeUrl(scheme.get, call_402658049.host, call_402658049.base,
                                   call_402658049.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658049, uri, valid, _)

proc call*(call_402658050: Call_GetModifyDBInstance_402658019;
           DBInstanceIdentifier: string; VpcSecurityGroupIds: JsonNode = nil;
           OptionGroupName: string = ""; PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBParameterGroupName: string = ""; MasterUserPassword: string = "";
           AllowMajorVersionUpgrade: bool = false; Iops: int = 0;
           ApplyImmediately: bool = false; MultiAZ: bool = false;
           Version: string = "2013-09-09"; NewDBInstanceIdentifier: string = "";
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
  var query_402658051 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402658051.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402658051, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658051, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658051, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402658051, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658051, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658051, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402658051, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_402658051, "Iops", newJInt(Iops))
  add(query_402658051, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658051, "MultiAZ", newJBool(MultiAZ))
  add(query_402658051, "Version", newJString(Version))
  add(query_402658051, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_402658051, "EngineVersion", newJString(EngineVersion))
  add(query_402658051, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658051, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402658051, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658051, "Action", newJString(Action))
  add(query_402658051, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402658051.add "DBSecurityGroups", DBSecurityGroups
  result = call_402658050.call(nil, query_402658051, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_402658019(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_402658020, base: "/",
    makeUrl: url_GetModifyDBInstance_402658021,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_402658103 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBParameterGroup_402658105(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_402658104(path: JsonNode;
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
  var valid_402658106 = query.getOrDefault("Version")
  valid_402658106 = validateParameter(valid_402658106, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658106 != nil:
    section.add "Version", valid_402658106
  var valid_402658107 = query.getOrDefault("Action")
  valid_402658107 = validateParameter(valid_402658107, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658107 != nil:
    section.add "Action", valid_402658107
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
  var valid_402658108 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658108 = validateParameter(valid_402658108, JString,
                                      required = false, default = nil)
  if valid_402658108 != nil:
    section.add "X-Amz-Security-Token", valid_402658108
  var valid_402658109 = header.getOrDefault("X-Amz-Signature")
  valid_402658109 = validateParameter(valid_402658109, JString,
                                      required = false, default = nil)
  if valid_402658109 != nil:
    section.add "X-Amz-Signature", valid_402658109
  var valid_402658110 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658110
  var valid_402658111 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658111 = validateParameter(valid_402658111, JString,
                                      required = false, default = nil)
  if valid_402658111 != nil:
    section.add "X-Amz-Algorithm", valid_402658111
  var valid_402658112 = header.getOrDefault("X-Amz-Date")
  valid_402658112 = validateParameter(valid_402658112, JString,
                                      required = false, default = nil)
  if valid_402658112 != nil:
    section.add "X-Amz-Date", valid_402658112
  var valid_402658113 = header.getOrDefault("X-Amz-Credential")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "X-Amz-Credential", valid_402658113
  var valid_402658114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658114 = validateParameter(valid_402658114, JString,
                                      required = false, default = nil)
  if valid_402658114 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658114
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658115 = formData.getOrDefault("DBParameterGroupName")
  valid_402658115 = validateParameter(valid_402658115, JString, required = true,
                                      default = nil)
  if valid_402658115 != nil:
    section.add "DBParameterGroupName", valid_402658115
  var valid_402658116 = formData.getOrDefault("Parameters")
  valid_402658116 = validateParameter(valid_402658116, JArray, required = true,
                                      default = nil)
  if valid_402658116 != nil:
    section.add "Parameters", valid_402658116
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658117: Call_PostModifyDBParameterGroup_402658103;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658117.validator(path, query, header, formData, body, _)
  let scheme = call_402658117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658117.makeUrl(scheme.get, call_402658117.host, call_402658117.base,
                                   call_402658117.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658117, uri, valid, _)

proc call*(call_402658118: Call_PostModifyDBParameterGroup_402658103;
           DBParameterGroupName: string; Parameters: JsonNode;
           Version: string = "2013-09-09";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## postModifyDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  var query_402658119 = newJObject()
  var formData_402658120 = newJObject()
  add(query_402658119, "Version", newJString(Version))
  add(formData_402658120, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658119, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658120.add "Parameters", Parameters
  result = call_402658118.call(nil, query_402658119, nil, formData_402658120,
                               nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_402658103(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_402658104, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_402658105,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_402658086 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBParameterGroup_402658088(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_402658087(path: JsonNode;
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
  var valid_402658089 = query.getOrDefault("Parameters")
  valid_402658089 = validateParameter(valid_402658089, JArray, required = true,
                                      default = nil)
  if valid_402658089 != nil:
    section.add "Parameters", valid_402658089
  var valid_402658090 = query.getOrDefault("DBParameterGroupName")
  valid_402658090 = validateParameter(valid_402658090, JString, required = true,
                                      default = nil)
  if valid_402658090 != nil:
    section.add "DBParameterGroupName", valid_402658090
  var valid_402658091 = query.getOrDefault("Version")
  valid_402658091 = validateParameter(valid_402658091, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658091 != nil:
    section.add "Version", valid_402658091
  var valid_402658092 = query.getOrDefault("Action")
  valid_402658092 = validateParameter(valid_402658092, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658092 != nil:
    section.add "Action", valid_402658092
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
  var valid_402658093 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658093 = validateParameter(valid_402658093, JString,
                                      required = false, default = nil)
  if valid_402658093 != nil:
    section.add "X-Amz-Security-Token", valid_402658093
  var valid_402658094 = header.getOrDefault("X-Amz-Signature")
  valid_402658094 = validateParameter(valid_402658094, JString,
                                      required = false, default = nil)
  if valid_402658094 != nil:
    section.add "X-Amz-Signature", valid_402658094
  var valid_402658095 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658095 = validateParameter(valid_402658095, JString,
                                      required = false, default = nil)
  if valid_402658095 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658095
  var valid_402658096 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658096 = validateParameter(valid_402658096, JString,
                                      required = false, default = nil)
  if valid_402658096 != nil:
    section.add "X-Amz-Algorithm", valid_402658096
  var valid_402658097 = header.getOrDefault("X-Amz-Date")
  valid_402658097 = validateParameter(valid_402658097, JString,
                                      required = false, default = nil)
  if valid_402658097 != nil:
    section.add "X-Amz-Date", valid_402658097
  var valid_402658098 = header.getOrDefault("X-Amz-Credential")
  valid_402658098 = validateParameter(valid_402658098, JString,
                                      required = false, default = nil)
  if valid_402658098 != nil:
    section.add "X-Amz-Credential", valid_402658098
  var valid_402658099 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658099 = validateParameter(valid_402658099, JString,
                                      required = false, default = nil)
  if valid_402658099 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658099
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658100: Call_GetModifyDBParameterGroup_402658086;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658100.validator(path, query, header, formData, body, _)
  let scheme = call_402658100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658100.makeUrl(scheme.get, call_402658100.host, call_402658100.base,
                                   call_402658100.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658100, uri, valid, _)

proc call*(call_402658101: Call_GetModifyDBParameterGroup_402658086;
           Parameters: JsonNode; DBParameterGroupName: string;
           Version: string = "2013-09-09";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## getModifyDBParameterGroup
  ##   Parameters: JArray (required)
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658102 = newJObject()
  if Parameters != nil:
    query_402658102.add "Parameters", Parameters
  add(query_402658102, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658102, "Version", newJString(Version))
  add(query_402658102, "Action", newJString(Action))
  result = call_402658101.call(nil, query_402658102, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_402658086(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_402658087, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_402658088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_402658139 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBSubnetGroup_402658141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_402658140(path: JsonNode; query: JsonNode;
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
  var valid_402658142 = query.getOrDefault("Version")
  valid_402658142 = validateParameter(valid_402658142, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658142 != nil:
    section.add "Version", valid_402658142
  var valid_402658143 = query.getOrDefault("Action")
  valid_402658143 = validateParameter(valid_402658143, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658143 != nil:
    section.add "Action", valid_402658143
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
  var valid_402658144 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658144 = validateParameter(valid_402658144, JString,
                                      required = false, default = nil)
  if valid_402658144 != nil:
    section.add "X-Amz-Security-Token", valid_402658144
  var valid_402658145 = header.getOrDefault("X-Amz-Signature")
  valid_402658145 = validateParameter(valid_402658145, JString,
                                      required = false, default = nil)
  if valid_402658145 != nil:
    section.add "X-Amz-Signature", valid_402658145
  var valid_402658146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658146 = validateParameter(valid_402658146, JString,
                                      required = false, default = nil)
  if valid_402658146 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658146
  var valid_402658147 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658147 = validateParameter(valid_402658147, JString,
                                      required = false, default = nil)
  if valid_402658147 != nil:
    section.add "X-Amz-Algorithm", valid_402658147
  var valid_402658148 = header.getOrDefault("X-Amz-Date")
  valid_402658148 = validateParameter(valid_402658148, JString,
                                      required = false, default = nil)
  if valid_402658148 != nil:
    section.add "X-Amz-Date", valid_402658148
  var valid_402658149 = header.getOrDefault("X-Amz-Credential")
  valid_402658149 = validateParameter(valid_402658149, JString,
                                      required = false, default = nil)
  if valid_402658149 != nil:
    section.add "X-Amz-Credential", valid_402658149
  var valid_402658150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658150 = validateParameter(valid_402658150, JString,
                                      required = false, default = nil)
  if valid_402658150 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658150
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402658151 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658151 = validateParameter(valid_402658151, JString, required = true,
                                      default = nil)
  if valid_402658151 != nil:
    section.add "DBSubnetGroupName", valid_402658151
  var valid_402658152 = formData.getOrDefault("SubnetIds")
  valid_402658152 = validateParameter(valid_402658152, JArray, required = true,
                                      default = nil)
  if valid_402658152 != nil:
    section.add "SubnetIds", valid_402658152
  var valid_402658153 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402658153 = validateParameter(valid_402658153, JString,
                                      required = false, default = nil)
  if valid_402658153 != nil:
    section.add "DBSubnetGroupDescription", valid_402658153
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658154: Call_PostModifyDBSubnetGroup_402658139;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658154.validator(path, query, header, formData, body, _)
  let scheme = call_402658154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658154.makeUrl(scheme.get, call_402658154.host, call_402658154.base,
                                   call_402658154.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658154, uri, valid, _)

proc call*(call_402658155: Call_PostModifyDBSubnetGroup_402658139;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           Version: string = "2013-09-09";
           DBSubnetGroupDescription: string = "";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  var query_402658156 = newJObject()
  var formData_402658157 = newJObject()
  add(formData_402658157, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658156, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402658157.add "SubnetIds", SubnetIds
  add(formData_402658157, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658156, "Action", newJString(Action))
  result = call_402658155.call(nil, query_402658156, nil, formData_402658157,
                               nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_402658139(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_402658140, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_402658141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_402658121 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBSubnetGroup_402658123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_402658122(path: JsonNode; query: JsonNode;
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
  var valid_402658124 = query.getOrDefault("DBSubnetGroupName")
  valid_402658124 = validateParameter(valid_402658124, JString, required = true,
                                      default = nil)
  if valid_402658124 != nil:
    section.add "DBSubnetGroupName", valid_402658124
  var valid_402658125 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402658125 = validateParameter(valid_402658125, JString,
                                      required = false, default = nil)
  if valid_402658125 != nil:
    section.add "DBSubnetGroupDescription", valid_402658125
  var valid_402658126 = query.getOrDefault("Version")
  valid_402658126 = validateParameter(valid_402658126, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658126 != nil:
    section.add "Version", valid_402658126
  var valid_402658127 = query.getOrDefault("SubnetIds")
  valid_402658127 = validateParameter(valid_402658127, JArray, required = true,
                                      default = nil)
  if valid_402658127 != nil:
    section.add "SubnetIds", valid_402658127
  var valid_402658128 = query.getOrDefault("Action")
  valid_402658128 = validateParameter(valid_402658128, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658128 != nil:
    section.add "Action", valid_402658128
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
  var valid_402658129 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658129 = validateParameter(valid_402658129, JString,
                                      required = false, default = nil)
  if valid_402658129 != nil:
    section.add "X-Amz-Security-Token", valid_402658129
  var valid_402658130 = header.getOrDefault("X-Amz-Signature")
  valid_402658130 = validateParameter(valid_402658130, JString,
                                      required = false, default = nil)
  if valid_402658130 != nil:
    section.add "X-Amz-Signature", valid_402658130
  var valid_402658131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658131 = validateParameter(valid_402658131, JString,
                                      required = false, default = nil)
  if valid_402658131 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658131
  var valid_402658132 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658132 = validateParameter(valid_402658132, JString,
                                      required = false, default = nil)
  if valid_402658132 != nil:
    section.add "X-Amz-Algorithm", valid_402658132
  var valid_402658133 = header.getOrDefault("X-Amz-Date")
  valid_402658133 = validateParameter(valid_402658133, JString,
                                      required = false, default = nil)
  if valid_402658133 != nil:
    section.add "X-Amz-Date", valid_402658133
  var valid_402658134 = header.getOrDefault("X-Amz-Credential")
  valid_402658134 = validateParameter(valid_402658134, JString,
                                      required = false, default = nil)
  if valid_402658134 != nil:
    section.add "X-Amz-Credential", valid_402658134
  var valid_402658135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658135 = validateParameter(valid_402658135, JString,
                                      required = false, default = nil)
  if valid_402658135 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658136: Call_GetModifyDBSubnetGroup_402658121;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658136.validator(path, query, header, formData, body, _)
  let scheme = call_402658136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658136.makeUrl(scheme.get, call_402658136.host, call_402658136.base,
                                   call_402658136.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658136, uri, valid, _)

proc call*(call_402658137: Call_GetModifyDBSubnetGroup_402658121;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string = "";
           Version: string = "2013-09-09";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## getModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402658138 = newJObject()
  add(query_402658138, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658138, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658138, "Version", newJString(Version))
  if SubnetIds != nil:
    query_402658138.add "SubnetIds", SubnetIds
  add(query_402658138, "Action", newJString(Action))
  result = call_402658137.call(nil, query_402658138, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_402658121(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_402658122, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_402658123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_402658178 = ref object of OpenApiRestCall_402656035
proc url_PostModifyEventSubscription_402658180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_402658179(path: JsonNode;
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
  var valid_402658181 = query.getOrDefault("Version")
  valid_402658181 = validateParameter(valid_402658181, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658181 != nil:
    section.add "Version", valid_402658181
  var valid_402658182 = query.getOrDefault("Action")
  valid_402658182 = validateParameter(valid_402658182, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658182 != nil:
    section.add "Action", valid_402658182
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
  var valid_402658183 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658183 = validateParameter(valid_402658183, JString,
                                      required = false, default = nil)
  if valid_402658183 != nil:
    section.add "X-Amz-Security-Token", valid_402658183
  var valid_402658184 = header.getOrDefault("X-Amz-Signature")
  valid_402658184 = validateParameter(valid_402658184, JString,
                                      required = false, default = nil)
  if valid_402658184 != nil:
    section.add "X-Amz-Signature", valid_402658184
  var valid_402658185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658185 = validateParameter(valid_402658185, JString,
                                      required = false, default = nil)
  if valid_402658185 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658185
  var valid_402658186 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658186 = validateParameter(valid_402658186, JString,
                                      required = false, default = nil)
  if valid_402658186 != nil:
    section.add "X-Amz-Algorithm", valid_402658186
  var valid_402658187 = header.getOrDefault("X-Amz-Date")
  valid_402658187 = validateParameter(valid_402658187, JString,
                                      required = false, default = nil)
  if valid_402658187 != nil:
    section.add "X-Amz-Date", valid_402658187
  var valid_402658188 = header.getOrDefault("X-Amz-Credential")
  valid_402658188 = validateParameter(valid_402658188, JString,
                                      required = false, default = nil)
  if valid_402658188 != nil:
    section.add "X-Amz-Credential", valid_402658188
  var valid_402658189 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658189 = validateParameter(valid_402658189, JString,
                                      required = false, default = nil)
  if valid_402658189 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658189
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  section = newJObject()
  var valid_402658190 = formData.getOrDefault("SourceType")
  valid_402658190 = validateParameter(valid_402658190, JString,
                                      required = false, default = nil)
  if valid_402658190 != nil:
    section.add "SourceType", valid_402658190
  var valid_402658191 = formData.getOrDefault("Enabled")
  valid_402658191 = validateParameter(valid_402658191, JBool, required = false,
                                      default = nil)
  if valid_402658191 != nil:
    section.add "Enabled", valid_402658191
  var valid_402658192 = formData.getOrDefault("EventCategories")
  valid_402658192 = validateParameter(valid_402658192, JArray, required = false,
                                      default = nil)
  if valid_402658192 != nil:
    section.add "EventCategories", valid_402658192
  var valid_402658193 = formData.getOrDefault("SnsTopicArn")
  valid_402658193 = validateParameter(valid_402658193, JString,
                                      required = false, default = nil)
  if valid_402658193 != nil:
    section.add "SnsTopicArn", valid_402658193
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402658194 = formData.getOrDefault("SubscriptionName")
  valid_402658194 = validateParameter(valid_402658194, JString, required = true,
                                      default = nil)
  if valid_402658194 != nil:
    section.add "SubscriptionName", valid_402658194
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658195: Call_PostModifyEventSubscription_402658178;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658195.validator(path, query, header, formData, body, _)
  let scheme = call_402658195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658195.makeUrl(scheme.get, call_402658195.host, call_402658195.base,
                                   call_402658195.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658195, uri, valid, _)

proc call*(call_402658196: Call_PostModifyEventSubscription_402658178;
           SubscriptionName: string; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2013-09-09"; SnsTopicArn: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## postModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SnsTopicArn: string
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402658197 = newJObject()
  var formData_402658198 = newJObject()
  add(formData_402658198, "SourceType", newJString(SourceType))
  add(formData_402658198, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402658198.add "EventCategories", EventCategories
  add(query_402658197, "Version", newJString(Version))
  add(formData_402658198, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658197, "Action", newJString(Action))
  add(formData_402658198, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658196.call(nil, query_402658197, nil, formData_402658198,
                               nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_402658178(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_402658179, base: "/",
    makeUrl: url_PostModifyEventSubscription_402658180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_402658158 = ref object of OpenApiRestCall_402656035
proc url_GetModifyEventSubscription_402658160(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_402658159(path: JsonNode;
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
  var valid_402658161 = query.getOrDefault("SnsTopicArn")
  valid_402658161 = validateParameter(valid_402658161, JString,
                                      required = false, default = nil)
  if valid_402658161 != nil:
    section.add "SnsTopicArn", valid_402658161
  var valid_402658162 = query.getOrDefault("Enabled")
  valid_402658162 = validateParameter(valid_402658162, JBool, required = false,
                                      default = nil)
  if valid_402658162 != nil:
    section.add "Enabled", valid_402658162
  var valid_402658163 = query.getOrDefault("EventCategories")
  valid_402658163 = validateParameter(valid_402658163, JArray, required = false,
                                      default = nil)
  if valid_402658163 != nil:
    section.add "EventCategories", valid_402658163
  var valid_402658164 = query.getOrDefault("Version")
  valid_402658164 = validateParameter(valid_402658164, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658164 != nil:
    section.add "Version", valid_402658164
  var valid_402658165 = query.getOrDefault("SubscriptionName")
  valid_402658165 = validateParameter(valid_402658165, JString, required = true,
                                      default = nil)
  if valid_402658165 != nil:
    section.add "SubscriptionName", valid_402658165
  var valid_402658166 = query.getOrDefault("SourceType")
  valid_402658166 = validateParameter(valid_402658166, JString,
                                      required = false, default = nil)
  if valid_402658166 != nil:
    section.add "SourceType", valid_402658166
  var valid_402658167 = query.getOrDefault("Action")
  valid_402658167 = validateParameter(valid_402658167, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658167 != nil:
    section.add "Action", valid_402658167
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
  var valid_402658168 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658168 = validateParameter(valid_402658168, JString,
                                      required = false, default = nil)
  if valid_402658168 != nil:
    section.add "X-Amz-Security-Token", valid_402658168
  var valid_402658169 = header.getOrDefault("X-Amz-Signature")
  valid_402658169 = validateParameter(valid_402658169, JString,
                                      required = false, default = nil)
  if valid_402658169 != nil:
    section.add "X-Amz-Signature", valid_402658169
  var valid_402658170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658170 = validateParameter(valid_402658170, JString,
                                      required = false, default = nil)
  if valid_402658170 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658170
  var valid_402658171 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658171 = validateParameter(valid_402658171, JString,
                                      required = false, default = nil)
  if valid_402658171 != nil:
    section.add "X-Amz-Algorithm", valid_402658171
  var valid_402658172 = header.getOrDefault("X-Amz-Date")
  valid_402658172 = validateParameter(valid_402658172, JString,
                                      required = false, default = nil)
  if valid_402658172 != nil:
    section.add "X-Amz-Date", valid_402658172
  var valid_402658173 = header.getOrDefault("X-Amz-Credential")
  valid_402658173 = validateParameter(valid_402658173, JString,
                                      required = false, default = nil)
  if valid_402658173 != nil:
    section.add "X-Amz-Credential", valid_402658173
  var valid_402658174 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658174 = validateParameter(valid_402658174, JString,
                                      required = false, default = nil)
  if valid_402658174 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658175: Call_GetModifyEventSubscription_402658158;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658175.validator(path, query, header, formData, body, _)
  let scheme = call_402658175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658175.makeUrl(scheme.get, call_402658175.host, call_402658175.base,
                                   call_402658175.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658175, uri, valid, _)

proc call*(call_402658176: Call_GetModifyEventSubscription_402658158;
           SubscriptionName: string; SnsTopicArn: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2013-09-09"; SourceType: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## getModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402658177 = newJObject()
  add(query_402658177, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658177, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402658177.add "EventCategories", EventCategories
  add(query_402658177, "Version", newJString(Version))
  add(query_402658177, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658177, "SourceType", newJString(SourceType))
  add(query_402658177, "Action", newJString(Action))
  result = call_402658176.call(nil, query_402658177, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_402658158(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_402658159, base: "/",
    makeUrl: url_GetModifyEventSubscription_402658160,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_402658218 = ref object of OpenApiRestCall_402656035
proc url_PostModifyOptionGroup_402658220(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_402658219(path: JsonNode; query: JsonNode;
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
  var valid_402658221 = query.getOrDefault("Version")
  valid_402658221 = validateParameter(valid_402658221, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658221 != nil:
    section.add "Version", valid_402658221
  var valid_402658222 = query.getOrDefault("Action")
  valid_402658222 = validateParameter(valid_402658222, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658222 != nil:
    section.add "Action", valid_402658222
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
  var valid_402658223 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658223 = validateParameter(valid_402658223, JString,
                                      required = false, default = nil)
  if valid_402658223 != nil:
    section.add "X-Amz-Security-Token", valid_402658223
  var valid_402658224 = header.getOrDefault("X-Amz-Signature")
  valid_402658224 = validateParameter(valid_402658224, JString,
                                      required = false, default = nil)
  if valid_402658224 != nil:
    section.add "X-Amz-Signature", valid_402658224
  var valid_402658225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658225 = validateParameter(valid_402658225, JString,
                                      required = false, default = nil)
  if valid_402658225 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658225
  var valid_402658226 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658226 = validateParameter(valid_402658226, JString,
                                      required = false, default = nil)
  if valid_402658226 != nil:
    section.add "X-Amz-Algorithm", valid_402658226
  var valid_402658227 = header.getOrDefault("X-Amz-Date")
  valid_402658227 = validateParameter(valid_402658227, JString,
                                      required = false, default = nil)
  if valid_402658227 != nil:
    section.add "X-Amz-Date", valid_402658227
  var valid_402658228 = header.getOrDefault("X-Amz-Credential")
  valid_402658228 = validateParameter(valid_402658228, JString,
                                      required = false, default = nil)
  if valid_402658228 != nil:
    section.add "X-Amz-Credential", valid_402658228
  var valid_402658229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658229 = validateParameter(valid_402658229, JString,
                                      required = false, default = nil)
  if valid_402658229 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658229
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_402658230 = formData.getOrDefault("OptionsToRemove")
  valid_402658230 = validateParameter(valid_402658230, JArray, required = false,
                                      default = nil)
  if valid_402658230 != nil:
    section.add "OptionsToRemove", valid_402658230
  var valid_402658231 = formData.getOrDefault("OptionsToInclude")
  valid_402658231 = validateParameter(valid_402658231, JArray, required = false,
                                      default = nil)
  if valid_402658231 != nil:
    section.add "OptionsToInclude", valid_402658231
  var valid_402658232 = formData.getOrDefault("ApplyImmediately")
  valid_402658232 = validateParameter(valid_402658232, JBool, required = false,
                                      default = nil)
  if valid_402658232 != nil:
    section.add "ApplyImmediately", valid_402658232
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402658233 = formData.getOrDefault("OptionGroupName")
  valid_402658233 = validateParameter(valid_402658233, JString, required = true,
                                      default = nil)
  if valid_402658233 != nil:
    section.add "OptionGroupName", valid_402658233
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658234: Call_PostModifyOptionGroup_402658218;
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

proc call*(call_402658235: Call_PostModifyOptionGroup_402658218;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2013-09-09"; Action: string = "ModifyOptionGroup"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402658236 = newJObject()
  var formData_402658237 = newJObject()
  if OptionsToRemove != nil:
    formData_402658237.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    formData_402658237.add "OptionsToInclude", OptionsToInclude
  add(formData_402658237, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658236, "Version", newJString(Version))
  add(formData_402658237, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658236, "Action", newJString(Action))
  result = call_402658235.call(nil, query_402658236, nil, formData_402658237,
                               nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_402658218(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_402658219, base: "/",
    makeUrl: url_PostModifyOptionGroup_402658220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_402658199 = ref object of OpenApiRestCall_402656035
proc url_GetModifyOptionGroup_402658201(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_402658200(path: JsonNode; query: JsonNode;
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
  var valid_402658202 = query.getOrDefault("OptionsToRemove")
  valid_402658202 = validateParameter(valid_402658202, JArray, required = false,
                                      default = nil)
  if valid_402658202 != nil:
    section.add "OptionsToRemove", valid_402658202
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402658203 = query.getOrDefault("OptionGroupName")
  valid_402658203 = validateParameter(valid_402658203, JString, required = true,
                                      default = nil)
  if valid_402658203 != nil:
    section.add "OptionGroupName", valid_402658203
  var valid_402658204 = query.getOrDefault("OptionsToInclude")
  valid_402658204 = validateParameter(valid_402658204, JArray, required = false,
                                      default = nil)
  if valid_402658204 != nil:
    section.add "OptionsToInclude", valid_402658204
  var valid_402658205 = query.getOrDefault("ApplyImmediately")
  valid_402658205 = validateParameter(valid_402658205, JBool, required = false,
                                      default = nil)
  if valid_402658205 != nil:
    section.add "ApplyImmediately", valid_402658205
  var valid_402658206 = query.getOrDefault("Version")
  valid_402658206 = validateParameter(valid_402658206, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658206 != nil:
    section.add "Version", valid_402658206
  var valid_402658207 = query.getOrDefault("Action")
  valid_402658207 = validateParameter(valid_402658207, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658207 != nil:
    section.add "Action", valid_402658207
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
  var valid_402658208 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658208 = validateParameter(valid_402658208, JString,
                                      required = false, default = nil)
  if valid_402658208 != nil:
    section.add "X-Amz-Security-Token", valid_402658208
  var valid_402658209 = header.getOrDefault("X-Amz-Signature")
  valid_402658209 = validateParameter(valid_402658209, JString,
                                      required = false, default = nil)
  if valid_402658209 != nil:
    section.add "X-Amz-Signature", valid_402658209
  var valid_402658210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658210 = validateParameter(valid_402658210, JString,
                                      required = false, default = nil)
  if valid_402658210 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658210
  var valid_402658211 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658211 = validateParameter(valid_402658211, JString,
                                      required = false, default = nil)
  if valid_402658211 != nil:
    section.add "X-Amz-Algorithm", valid_402658211
  var valid_402658212 = header.getOrDefault("X-Amz-Date")
  valid_402658212 = validateParameter(valid_402658212, JString,
                                      required = false, default = nil)
  if valid_402658212 != nil:
    section.add "X-Amz-Date", valid_402658212
  var valid_402658213 = header.getOrDefault("X-Amz-Credential")
  valid_402658213 = validateParameter(valid_402658213, JString,
                                      required = false, default = nil)
  if valid_402658213 != nil:
    section.add "X-Amz-Credential", valid_402658213
  var valid_402658214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658214 = validateParameter(valid_402658214, JString,
                                      required = false, default = nil)
  if valid_402658214 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658215: Call_GetModifyOptionGroup_402658199;
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

proc call*(call_402658216: Call_GetModifyOptionGroup_402658199;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2013-09-09"; Action: string = "ModifyOptionGroup"): Recallable =
  ## getModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658217 = newJObject()
  if OptionsToRemove != nil:
    query_402658217.add "OptionsToRemove", OptionsToRemove
  add(query_402658217, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    query_402658217.add "OptionsToInclude", OptionsToInclude
  add(query_402658217, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658217, "Version", newJString(Version))
  add(query_402658217, "Action", newJString(Action))
  result = call_402658216.call(nil, query_402658217, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_402658199(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_402658200, base: "/",
    makeUrl: url_GetModifyOptionGroup_402658201,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_402658256 = ref object of OpenApiRestCall_402656035
proc url_PostPromoteReadReplica_402658258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_402658257(path: JsonNode; query: JsonNode;
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
  var valid_402658259 = query.getOrDefault("Version")
  valid_402658259 = validateParameter(valid_402658259, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658259 != nil:
    section.add "Version", valid_402658259
  var valid_402658260 = query.getOrDefault("Action")
  valid_402658260 = validateParameter(valid_402658260, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658260 != nil:
    section.add "Action", valid_402658260
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
  var valid_402658261 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658261 = validateParameter(valid_402658261, JString,
                                      required = false, default = nil)
  if valid_402658261 != nil:
    section.add "X-Amz-Security-Token", valid_402658261
  var valid_402658262 = header.getOrDefault("X-Amz-Signature")
  valid_402658262 = validateParameter(valid_402658262, JString,
                                      required = false, default = nil)
  if valid_402658262 != nil:
    section.add "X-Amz-Signature", valid_402658262
  var valid_402658263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658263 = validateParameter(valid_402658263, JString,
                                      required = false, default = nil)
  if valid_402658263 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658263
  var valid_402658264 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658264 = validateParameter(valid_402658264, JString,
                                      required = false, default = nil)
  if valid_402658264 != nil:
    section.add "X-Amz-Algorithm", valid_402658264
  var valid_402658265 = header.getOrDefault("X-Amz-Date")
  valid_402658265 = validateParameter(valid_402658265, JString,
                                      required = false, default = nil)
  if valid_402658265 != nil:
    section.add "X-Amz-Date", valid_402658265
  var valid_402658266 = header.getOrDefault("X-Amz-Credential")
  valid_402658266 = validateParameter(valid_402658266, JString,
                                      required = false, default = nil)
  if valid_402658266 != nil:
    section.add "X-Amz-Credential", valid_402658266
  var valid_402658267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658267 = validateParameter(valid_402658267, JString,
                                      required = false, default = nil)
  if valid_402658267 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658267
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658268 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658268 = validateParameter(valid_402658268, JString,
                                      required = false, default = nil)
  if valid_402658268 != nil:
    section.add "PreferredBackupWindow", valid_402658268
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658269 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658269 = validateParameter(valid_402658269, JString, required = true,
                                      default = nil)
  if valid_402658269 != nil:
    section.add "DBInstanceIdentifier", valid_402658269
  var valid_402658270 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658270 = validateParameter(valid_402658270, JInt, required = false,
                                      default = nil)
  if valid_402658270 != nil:
    section.add "BackupRetentionPeriod", valid_402658270
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658271: Call_PostPromoteReadReplica_402658256;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658271.validator(path, query, header, formData, body, _)
  let scheme = call_402658271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658271.makeUrl(scheme.get, call_402658271.host, call_402658271.base,
                                   call_402658271.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658271, uri, valid, _)

proc call*(call_402658272: Call_PostPromoteReadReplica_402658256;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2013-09-09";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658273 = newJObject()
  var formData_402658274 = newJObject()
  add(formData_402658274, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658273, "Version", newJString(Version))
  add(formData_402658274, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658273, "Action", newJString(Action))
  add(formData_402658274, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658272.call(nil, query_402658273, nil, formData_402658274,
                               nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_402658256(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_402658257, base: "/",
    makeUrl: url_PostPromoteReadReplica_402658258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_402658238 = ref object of OpenApiRestCall_402656035
proc url_GetPromoteReadReplica_402658240(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_402658239(path: JsonNode; query: JsonNode;
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
  var valid_402658241 = query.getOrDefault("PreferredBackupWindow")
  valid_402658241 = validateParameter(valid_402658241, JString,
                                      required = false, default = nil)
  if valid_402658241 != nil:
    section.add "PreferredBackupWindow", valid_402658241
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658242 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658242 = validateParameter(valid_402658242, JString, required = true,
                                      default = nil)
  if valid_402658242 != nil:
    section.add "DBInstanceIdentifier", valid_402658242
  var valid_402658243 = query.getOrDefault("Version")
  valid_402658243 = validateParameter(valid_402658243, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658243 != nil:
    section.add "Version", valid_402658243
  var valid_402658244 = query.getOrDefault("Action")
  valid_402658244 = validateParameter(valid_402658244, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658244 != nil:
    section.add "Action", valid_402658244
  var valid_402658245 = query.getOrDefault("BackupRetentionPeriod")
  valid_402658245 = validateParameter(valid_402658245, JInt, required = false,
                                      default = nil)
  if valid_402658245 != nil:
    section.add "BackupRetentionPeriod", valid_402658245
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
  var valid_402658246 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658246 = validateParameter(valid_402658246, JString,
                                      required = false, default = nil)
  if valid_402658246 != nil:
    section.add "X-Amz-Security-Token", valid_402658246
  var valid_402658247 = header.getOrDefault("X-Amz-Signature")
  valid_402658247 = validateParameter(valid_402658247, JString,
                                      required = false, default = nil)
  if valid_402658247 != nil:
    section.add "X-Amz-Signature", valid_402658247
  var valid_402658248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658248 = validateParameter(valid_402658248, JString,
                                      required = false, default = nil)
  if valid_402658248 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658248
  var valid_402658249 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658249 = validateParameter(valid_402658249, JString,
                                      required = false, default = nil)
  if valid_402658249 != nil:
    section.add "X-Amz-Algorithm", valid_402658249
  var valid_402658250 = header.getOrDefault("X-Amz-Date")
  valid_402658250 = validateParameter(valid_402658250, JString,
                                      required = false, default = nil)
  if valid_402658250 != nil:
    section.add "X-Amz-Date", valid_402658250
  var valid_402658251 = header.getOrDefault("X-Amz-Credential")
  valid_402658251 = validateParameter(valid_402658251, JString,
                                      required = false, default = nil)
  if valid_402658251 != nil:
    section.add "X-Amz-Credential", valid_402658251
  var valid_402658252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658252 = validateParameter(valid_402658252, JString,
                                      required = false, default = nil)
  if valid_402658252 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658253: Call_GetPromoteReadReplica_402658238;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658253.validator(path, query, header, formData, body, _)
  let scheme = call_402658253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658253.makeUrl(scheme.get, call_402658253.host, call_402658253.base,
                                   call_402658253.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658253, uri, valid, _)

proc call*(call_402658254: Call_GetPromoteReadReplica_402658238;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2013-09-09";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## getPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658255 = newJObject()
  add(query_402658255, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658255, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658255, "Version", newJString(Version))
  add(query_402658255, "Action", newJString(Action))
  add(query_402658255, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  result = call_402658254.call(nil, query_402658255, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_402658238(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_402658239, base: "/",
    makeUrl: url_GetPromoteReadReplica_402658240,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_402658294 = ref object of OpenApiRestCall_402656035
proc url_PostPurchaseReservedDBInstancesOffering_402658296(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_402658295(path: JsonNode;
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
  var valid_402658297 = query.getOrDefault("Version")
  valid_402658297 = validateParameter(valid_402658297, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658297 != nil:
    section.add "Version", valid_402658297
  var valid_402658298 = query.getOrDefault("Action")
  valid_402658298 = validateParameter(valid_402658298, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_402658298 != nil:
    section.add "Action", valid_402658298
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
  var valid_402658299 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658299 = validateParameter(valid_402658299, JString,
                                      required = false, default = nil)
  if valid_402658299 != nil:
    section.add "X-Amz-Security-Token", valid_402658299
  var valid_402658300 = header.getOrDefault("X-Amz-Signature")
  valid_402658300 = validateParameter(valid_402658300, JString,
                                      required = false, default = nil)
  if valid_402658300 != nil:
    section.add "X-Amz-Signature", valid_402658300
  var valid_402658301 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658301 = validateParameter(valid_402658301, JString,
                                      required = false, default = nil)
  if valid_402658301 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658301
  var valid_402658302 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658302 = validateParameter(valid_402658302, JString,
                                      required = false, default = nil)
  if valid_402658302 != nil:
    section.add "X-Amz-Algorithm", valid_402658302
  var valid_402658303 = header.getOrDefault("X-Amz-Date")
  valid_402658303 = validateParameter(valid_402658303, JString,
                                      required = false, default = nil)
  if valid_402658303 != nil:
    section.add "X-Amz-Date", valid_402658303
  var valid_402658304 = header.getOrDefault("X-Amz-Credential")
  valid_402658304 = validateParameter(valid_402658304, JString,
                                      required = false, default = nil)
  if valid_402658304 != nil:
    section.add "X-Amz-Credential", valid_402658304
  var valid_402658305 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658305 = validateParameter(valid_402658305, JString,
                                      required = false, default = nil)
  if valid_402658305 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658305
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceCount: JInt
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   ReservedDBInstanceId: JString
  section = newJObject()
  var valid_402658306 = formData.getOrDefault("DBInstanceCount")
  valid_402658306 = validateParameter(valid_402658306, JInt, required = false,
                                      default = nil)
  if valid_402658306 != nil:
    section.add "DBInstanceCount", valid_402658306
  var valid_402658307 = formData.getOrDefault("Tags")
  valid_402658307 = validateParameter(valid_402658307, JArray, required = false,
                                      default = nil)
  if valid_402658307 != nil:
    section.add "Tags", valid_402658307
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658308 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658308 = validateParameter(valid_402658308, JString, required = true,
                                      default = nil)
  if valid_402658308 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658308
  var valid_402658309 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402658309 = validateParameter(valid_402658309, JString,
                                      required = false, default = nil)
  if valid_402658309 != nil:
    section.add "ReservedDBInstanceId", valid_402658309
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658310: Call_PostPurchaseReservedDBInstancesOffering_402658294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658310.validator(path, query, header, formData, body, _)
  let scheme = call_402658310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658310.makeUrl(scheme.get, call_402658310.host, call_402658310.base,
                                   call_402658310.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658310, uri, valid, _)

proc call*(call_402658311: Call_PostPurchaseReservedDBInstancesOffering_402658294;
           ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
           Tags: JsonNode = nil; Version: string = "2013-09-09";
           ReservedDBInstanceId: string = "";
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   Version: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  var query_402658312 = newJObject()
  var formData_402658313 = newJObject()
  add(formData_402658313, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    formData_402658313.add "Tags", Tags
  add(query_402658312, "Version", newJString(Version))
  add(formData_402658313, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402658313, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(query_402658312, "Action", newJString(Action))
  result = call_402658311.call(nil, query_402658312, nil, formData_402658313,
                               nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_402658294(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_402658295,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_402658296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_402658275 = ref object of OpenApiRestCall_402656035
proc url_GetPurchaseReservedDBInstancesOffering_402658277(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_402658276(path: JsonNode;
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
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   Action: JString (required)
  section = newJObject()
  var valid_402658278 = query.getOrDefault("ReservedDBInstanceId")
  valid_402658278 = validateParameter(valid_402658278, JString,
                                      required = false, default = nil)
  if valid_402658278 != nil:
    section.add "ReservedDBInstanceId", valid_402658278
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658279 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658279 = validateParameter(valid_402658279, JString, required = true,
                                      default = nil)
  if valid_402658279 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658279
  var valid_402658280 = query.getOrDefault("Version")
  valid_402658280 = validateParameter(valid_402658280, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658280 != nil:
    section.add "Version", valid_402658280
  var valid_402658281 = query.getOrDefault("Tags")
  valid_402658281 = validateParameter(valid_402658281, JArray, required = false,
                                      default = nil)
  if valid_402658281 != nil:
    section.add "Tags", valid_402658281
  var valid_402658282 = query.getOrDefault("DBInstanceCount")
  valid_402658282 = validateParameter(valid_402658282, JInt, required = false,
                                      default = nil)
  if valid_402658282 != nil:
    section.add "DBInstanceCount", valid_402658282
  var valid_402658283 = query.getOrDefault("Action")
  valid_402658283 = validateParameter(valid_402658283, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_402658283 != nil:
    section.add "Action", valid_402658283
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
  var valid_402658284 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658284 = validateParameter(valid_402658284, JString,
                                      required = false, default = nil)
  if valid_402658284 != nil:
    section.add "X-Amz-Security-Token", valid_402658284
  var valid_402658285 = header.getOrDefault("X-Amz-Signature")
  valid_402658285 = validateParameter(valid_402658285, JString,
                                      required = false, default = nil)
  if valid_402658285 != nil:
    section.add "X-Amz-Signature", valid_402658285
  var valid_402658286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658286 = validateParameter(valid_402658286, JString,
                                      required = false, default = nil)
  if valid_402658286 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658286
  var valid_402658287 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658287 = validateParameter(valid_402658287, JString,
                                      required = false, default = nil)
  if valid_402658287 != nil:
    section.add "X-Amz-Algorithm", valid_402658287
  var valid_402658288 = header.getOrDefault("X-Amz-Date")
  valid_402658288 = validateParameter(valid_402658288, JString,
                                      required = false, default = nil)
  if valid_402658288 != nil:
    section.add "X-Amz-Date", valid_402658288
  var valid_402658289 = header.getOrDefault("X-Amz-Credential")
  valid_402658289 = validateParameter(valid_402658289, JString,
                                      required = false, default = nil)
  if valid_402658289 != nil:
    section.add "X-Amz-Credential", valid_402658289
  var valid_402658290 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658290 = validateParameter(valid_402658290, JString,
                                      required = false, default = nil)
  if valid_402658290 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658290
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658291: Call_GetPurchaseReservedDBInstancesOffering_402658275;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658291.validator(path, query, header, formData, body, _)
  let scheme = call_402658291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658291.makeUrl(scheme.get, call_402658291.host, call_402658291.base,
                                   call_402658291.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658291, uri, valid, _)

proc call*(call_402658292: Call_GetPurchaseReservedDBInstancesOffering_402658275;
           ReservedDBInstancesOfferingId: string;
           ReservedDBInstanceId: string = ""; Version: string = "2013-09-09";
           Tags: JsonNode = nil; DBInstanceCount: int = 0;
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  var query_402658293 = newJObject()
  add(query_402658293, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_402658293, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402658293, "Version", newJString(Version))
  if Tags != nil:
    query_402658293.add "Tags", Tags
  add(query_402658293, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_402658293, "Action", newJString(Action))
  result = call_402658292.call(nil, query_402658293, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_402658275(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_402658276,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_402658277,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_402658331 = ref object of OpenApiRestCall_402656035
proc url_PostRebootDBInstance_402658333(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_402658332(path: JsonNode; query: JsonNode;
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
  var valid_402658334 = query.getOrDefault("Version")
  valid_402658334 = validateParameter(valid_402658334, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658334 != nil:
    section.add "Version", valid_402658334
  var valid_402658335 = query.getOrDefault("Action")
  valid_402658335 = validateParameter(valid_402658335, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658335 != nil:
    section.add "Action", valid_402658335
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
  var valid_402658336 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658336 = validateParameter(valid_402658336, JString,
                                      required = false, default = nil)
  if valid_402658336 != nil:
    section.add "X-Amz-Security-Token", valid_402658336
  var valid_402658337 = header.getOrDefault("X-Amz-Signature")
  valid_402658337 = validateParameter(valid_402658337, JString,
                                      required = false, default = nil)
  if valid_402658337 != nil:
    section.add "X-Amz-Signature", valid_402658337
  var valid_402658338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658338 = validateParameter(valid_402658338, JString,
                                      required = false, default = nil)
  if valid_402658338 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658338
  var valid_402658339 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658339 = validateParameter(valid_402658339, JString,
                                      required = false, default = nil)
  if valid_402658339 != nil:
    section.add "X-Amz-Algorithm", valid_402658339
  var valid_402658340 = header.getOrDefault("X-Amz-Date")
  valid_402658340 = validateParameter(valid_402658340, JString,
                                      required = false, default = nil)
  if valid_402658340 != nil:
    section.add "X-Amz-Date", valid_402658340
  var valid_402658341 = header.getOrDefault("X-Amz-Credential")
  valid_402658341 = validateParameter(valid_402658341, JString,
                                      required = false, default = nil)
  if valid_402658341 != nil:
    section.add "X-Amz-Credential", valid_402658341
  var valid_402658342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658342 = validateParameter(valid_402658342, JString,
                                      required = false, default = nil)
  if valid_402658342 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658342
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658343 = formData.getOrDefault("ForceFailover")
  valid_402658343 = validateParameter(valid_402658343, JBool, required = false,
                                      default = nil)
  if valid_402658343 != nil:
    section.add "ForceFailover", valid_402658343
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658344 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658344 = validateParameter(valid_402658344, JString, required = true,
                                      default = nil)
  if valid_402658344 != nil:
    section.add "DBInstanceIdentifier", valid_402658344
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658345: Call_PostRebootDBInstance_402658331;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658345.validator(path, query, header, formData, body, _)
  let scheme = call_402658345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658345.makeUrl(scheme.get, call_402658345.host, call_402658345.base,
                                   call_402658345.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658345, uri, valid, _)

proc call*(call_402658346: Call_PostRebootDBInstance_402658331;
           DBInstanceIdentifier: string; Version: string = "2013-09-09";
           ForceFailover: bool = false; Action: string = "RebootDBInstance"): Recallable =
  ## postRebootDBInstance
  ##   Version: string (required)
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  var query_402658347 = newJObject()
  var formData_402658348 = newJObject()
  add(query_402658347, "Version", newJString(Version))
  add(formData_402658348, "ForceFailover", newJBool(ForceFailover))
  add(formData_402658348, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658347, "Action", newJString(Action))
  result = call_402658346.call(nil, query_402658347, nil, formData_402658348,
                               nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_402658331(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_402658332, base: "/",
    makeUrl: url_PostRebootDBInstance_402658333,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_402658314 = ref object of OpenApiRestCall_402656035
proc url_GetRebootDBInstance_402658316(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_402658315(path: JsonNode; query: JsonNode;
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
  var valid_402658317 = query.getOrDefault("ForceFailover")
  valid_402658317 = validateParameter(valid_402658317, JBool, required = false,
                                      default = nil)
  if valid_402658317 != nil:
    section.add "ForceFailover", valid_402658317
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658318 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658318 = validateParameter(valid_402658318, JString, required = true,
                                      default = nil)
  if valid_402658318 != nil:
    section.add "DBInstanceIdentifier", valid_402658318
  var valid_402658319 = query.getOrDefault("Version")
  valid_402658319 = validateParameter(valid_402658319, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658319 != nil:
    section.add "Version", valid_402658319
  var valid_402658320 = query.getOrDefault("Action")
  valid_402658320 = validateParameter(valid_402658320, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658320 != nil:
    section.add "Action", valid_402658320
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
  var valid_402658321 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658321 = validateParameter(valid_402658321, JString,
                                      required = false, default = nil)
  if valid_402658321 != nil:
    section.add "X-Amz-Security-Token", valid_402658321
  var valid_402658322 = header.getOrDefault("X-Amz-Signature")
  valid_402658322 = validateParameter(valid_402658322, JString,
                                      required = false, default = nil)
  if valid_402658322 != nil:
    section.add "X-Amz-Signature", valid_402658322
  var valid_402658323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658323 = validateParameter(valid_402658323, JString,
                                      required = false, default = nil)
  if valid_402658323 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658323
  var valid_402658324 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658324 = validateParameter(valid_402658324, JString,
                                      required = false, default = nil)
  if valid_402658324 != nil:
    section.add "X-Amz-Algorithm", valid_402658324
  var valid_402658325 = header.getOrDefault("X-Amz-Date")
  valid_402658325 = validateParameter(valid_402658325, JString,
                                      required = false, default = nil)
  if valid_402658325 != nil:
    section.add "X-Amz-Date", valid_402658325
  var valid_402658326 = header.getOrDefault("X-Amz-Credential")
  valid_402658326 = validateParameter(valid_402658326, JString,
                                      required = false, default = nil)
  if valid_402658326 != nil:
    section.add "X-Amz-Credential", valid_402658326
  var valid_402658327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658327 = validateParameter(valid_402658327, JString,
                                      required = false, default = nil)
  if valid_402658327 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658328: Call_GetRebootDBInstance_402658314;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658328.validator(path, query, header, formData, body, _)
  let scheme = call_402658328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658328.makeUrl(scheme.get, call_402658328.host, call_402658328.base,
                                   call_402658328.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658328, uri, valid, _)

proc call*(call_402658329: Call_GetRebootDBInstance_402658314;
           DBInstanceIdentifier: string; ForceFailover: bool = false;
           Version: string = "2013-09-09"; Action: string = "RebootDBInstance"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658330 = newJObject()
  add(query_402658330, "ForceFailover", newJBool(ForceFailover))
  add(query_402658330, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658330, "Version", newJString(Version))
  add(query_402658330, "Action", newJString(Action))
  result = call_402658329.call(nil, query_402658330, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_402658314(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_402658315, base: "/",
    makeUrl: url_GetRebootDBInstance_402658316,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_402658366 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveSourceIdentifierFromSubscription_402658368(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_402658367(
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
  var valid_402658369 = query.getOrDefault("Version")
  valid_402658369 = validateParameter(valid_402658369, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658369 != nil:
    section.add "Version", valid_402658369
  var valid_402658370 = query.getOrDefault("Action")
  valid_402658370 = validateParameter(valid_402658370, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658370 != nil:
    section.add "Action", valid_402658370
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
  var valid_402658371 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658371 = validateParameter(valid_402658371, JString,
                                      required = false, default = nil)
  if valid_402658371 != nil:
    section.add "X-Amz-Security-Token", valid_402658371
  var valid_402658372 = header.getOrDefault("X-Amz-Signature")
  valid_402658372 = validateParameter(valid_402658372, JString,
                                      required = false, default = nil)
  if valid_402658372 != nil:
    section.add "X-Amz-Signature", valid_402658372
  var valid_402658373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658373 = validateParameter(valid_402658373, JString,
                                      required = false, default = nil)
  if valid_402658373 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658373
  var valid_402658374 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658374 = validateParameter(valid_402658374, JString,
                                      required = false, default = nil)
  if valid_402658374 != nil:
    section.add "X-Amz-Algorithm", valid_402658374
  var valid_402658375 = header.getOrDefault("X-Amz-Date")
  valid_402658375 = validateParameter(valid_402658375, JString,
                                      required = false, default = nil)
  if valid_402658375 != nil:
    section.add "X-Amz-Date", valid_402658375
  var valid_402658376 = header.getOrDefault("X-Amz-Credential")
  valid_402658376 = validateParameter(valid_402658376, JString,
                                      required = false, default = nil)
  if valid_402658376 != nil:
    section.add "X-Amz-Credential", valid_402658376
  var valid_402658377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658377 = validateParameter(valid_402658377, JString,
                                      required = false, default = nil)
  if valid_402658377 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658377
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_402658378 = formData.getOrDefault("SourceIdentifier")
  valid_402658378 = validateParameter(valid_402658378, JString, required = true,
                                      default = nil)
  if valid_402658378 != nil:
    section.add "SourceIdentifier", valid_402658378
  var valid_402658379 = formData.getOrDefault("SubscriptionName")
  valid_402658379 = validateParameter(valid_402658379, JString, required = true,
                                      default = nil)
  if valid_402658379 != nil:
    section.add "SubscriptionName", valid_402658379
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658380: Call_PostRemoveSourceIdentifierFromSubscription_402658366;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658380.validator(path, query, header, formData, body, _)
  let scheme = call_402658380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658380.makeUrl(scheme.get, call_402658380.host, call_402658380.base,
                                   call_402658380.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658380, uri, valid, _)

proc call*(call_402658381: Call_PostRemoveSourceIdentifierFromSubscription_402658366;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-09-09";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  var query_402658382 = newJObject()
  var formData_402658383 = newJObject()
  add(query_402658382, "Version", newJString(Version))
  add(query_402658382, "Action", newJString(Action))
  add(formData_402658383, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_402658383, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658381.call(nil, query_402658382, nil, formData_402658383,
                               nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_402658366(
    name: "postRemoveSourceIdentifierFromSubscription",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_402658367,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_402658368,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_402658349 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveSourceIdentifierFromSubscription_402658351(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_402658350(
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
  var valid_402658352 = query.getOrDefault("SourceIdentifier")
  valid_402658352 = validateParameter(valid_402658352, JString, required = true,
                                      default = nil)
  if valid_402658352 != nil:
    section.add "SourceIdentifier", valid_402658352
  var valid_402658353 = query.getOrDefault("Version")
  valid_402658353 = validateParameter(valid_402658353, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658353 != nil:
    section.add "Version", valid_402658353
  var valid_402658354 = query.getOrDefault("SubscriptionName")
  valid_402658354 = validateParameter(valid_402658354, JString, required = true,
                                      default = nil)
  if valid_402658354 != nil:
    section.add "SubscriptionName", valid_402658354
  var valid_402658355 = query.getOrDefault("Action")
  valid_402658355 = validateParameter(valid_402658355, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658355 != nil:
    section.add "Action", valid_402658355
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
  var valid_402658356 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658356 = validateParameter(valid_402658356, JString,
                                      required = false, default = nil)
  if valid_402658356 != nil:
    section.add "X-Amz-Security-Token", valid_402658356
  var valid_402658357 = header.getOrDefault("X-Amz-Signature")
  valid_402658357 = validateParameter(valid_402658357, JString,
                                      required = false, default = nil)
  if valid_402658357 != nil:
    section.add "X-Amz-Signature", valid_402658357
  var valid_402658358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658358 = validateParameter(valid_402658358, JString,
                                      required = false, default = nil)
  if valid_402658358 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658358
  var valid_402658359 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658359 = validateParameter(valid_402658359, JString,
                                      required = false, default = nil)
  if valid_402658359 != nil:
    section.add "X-Amz-Algorithm", valid_402658359
  var valid_402658360 = header.getOrDefault("X-Amz-Date")
  valid_402658360 = validateParameter(valid_402658360, JString,
                                      required = false, default = nil)
  if valid_402658360 != nil:
    section.add "X-Amz-Date", valid_402658360
  var valid_402658361 = header.getOrDefault("X-Amz-Credential")
  valid_402658361 = validateParameter(valid_402658361, JString,
                                      required = false, default = nil)
  if valid_402658361 != nil:
    section.add "X-Amz-Credential", valid_402658361
  var valid_402658362 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658362 = validateParameter(valid_402658362, JString,
                                      required = false, default = nil)
  if valid_402658362 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658362
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658363: Call_GetRemoveSourceIdentifierFromSubscription_402658349;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658363.validator(path, query, header, formData, body, _)
  let scheme = call_402658363.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658363.makeUrl(scheme.get, call_402658363.host, call_402658363.base,
                                   call_402658363.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658363, uri, valid, _)

proc call*(call_402658364: Call_GetRemoveSourceIdentifierFromSubscription_402658349;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2013-09-09";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402658365 = newJObject()
  add(query_402658365, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402658365, "Version", newJString(Version))
  add(query_402658365, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658365, "Action", newJString(Action))
  result = call_402658364.call(nil, query_402658365, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_402658349(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_402658350,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_402658351,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_402658401 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveTagsFromResource_402658403(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_402658402(path: JsonNode;
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
  var valid_402658404 = query.getOrDefault("Version")
  valid_402658404 = validateParameter(valid_402658404, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658404 != nil:
    section.add "Version", valid_402658404
  var valid_402658405 = query.getOrDefault("Action")
  valid_402658405 = validateParameter(valid_402658405, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658405 != nil:
    section.add "Action", valid_402658405
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
  var valid_402658406 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658406 = validateParameter(valid_402658406, JString,
                                      required = false, default = nil)
  if valid_402658406 != nil:
    section.add "X-Amz-Security-Token", valid_402658406
  var valid_402658407 = header.getOrDefault("X-Amz-Signature")
  valid_402658407 = validateParameter(valid_402658407, JString,
                                      required = false, default = nil)
  if valid_402658407 != nil:
    section.add "X-Amz-Signature", valid_402658407
  var valid_402658408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658408 = validateParameter(valid_402658408, JString,
                                      required = false, default = nil)
  if valid_402658408 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658408
  var valid_402658409 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658409 = validateParameter(valid_402658409, JString,
                                      required = false, default = nil)
  if valid_402658409 != nil:
    section.add "X-Amz-Algorithm", valid_402658409
  var valid_402658410 = header.getOrDefault("X-Amz-Date")
  valid_402658410 = validateParameter(valid_402658410, JString,
                                      required = false, default = nil)
  if valid_402658410 != nil:
    section.add "X-Amz-Date", valid_402658410
  var valid_402658411 = header.getOrDefault("X-Amz-Credential")
  valid_402658411 = validateParameter(valid_402658411, JString,
                                      required = false, default = nil)
  if valid_402658411 != nil:
    section.add "X-Amz-Credential", valid_402658411
  var valid_402658412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658412 = validateParameter(valid_402658412, JString,
                                      required = false, default = nil)
  if valid_402658412 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658412
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
         "formData argument is necessary due to required `TagKeys` field"
  var valid_402658413 = formData.getOrDefault("TagKeys")
  valid_402658413 = validateParameter(valid_402658413, JArray, required = true,
                                      default = nil)
  if valid_402658413 != nil:
    section.add "TagKeys", valid_402658413
  var valid_402658414 = formData.getOrDefault("ResourceName")
  valid_402658414 = validateParameter(valid_402658414, JString, required = true,
                                      default = nil)
  if valid_402658414 != nil:
    section.add "ResourceName", valid_402658414
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658415: Call_PostRemoveTagsFromResource_402658401;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658415.validator(path, query, header, formData, body, _)
  let scheme = call_402658415.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658415.makeUrl(scheme.get, call_402658415.host, call_402658415.base,
                                   call_402658415.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658415, uri, valid, _)

proc call*(call_402658416: Call_PostRemoveTagsFromResource_402658401;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2013-09-09";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## postRemoveTagsFromResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  var query_402658417 = newJObject()
  var formData_402658418 = newJObject()
  add(query_402658417, "Version", newJString(Version))
  add(query_402658417, "Action", newJString(Action))
  if TagKeys != nil:
    formData_402658418.add "TagKeys", TagKeys
  add(formData_402658418, "ResourceName", newJString(ResourceName))
  result = call_402658416.call(nil, query_402658417, nil, formData_402658418,
                               nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_402658401(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_402658402, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_402658403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_402658384 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveTagsFromResource_402658386(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_402658385(path: JsonNode;
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
  var valid_402658387 = query.getOrDefault("TagKeys")
  valid_402658387 = validateParameter(valid_402658387, JArray, required = true,
                                      default = nil)
  if valid_402658387 != nil:
    section.add "TagKeys", valid_402658387
  var valid_402658388 = query.getOrDefault("Version")
  valid_402658388 = validateParameter(valid_402658388, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658388 != nil:
    section.add "Version", valid_402658388
  var valid_402658389 = query.getOrDefault("ResourceName")
  valid_402658389 = validateParameter(valid_402658389, JString, required = true,
                                      default = nil)
  if valid_402658389 != nil:
    section.add "ResourceName", valid_402658389
  var valid_402658390 = query.getOrDefault("Action")
  valid_402658390 = validateParameter(valid_402658390, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658390 != nil:
    section.add "Action", valid_402658390
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
  var valid_402658391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658391 = validateParameter(valid_402658391, JString,
                                      required = false, default = nil)
  if valid_402658391 != nil:
    section.add "X-Amz-Security-Token", valid_402658391
  var valid_402658392 = header.getOrDefault("X-Amz-Signature")
  valid_402658392 = validateParameter(valid_402658392, JString,
                                      required = false, default = nil)
  if valid_402658392 != nil:
    section.add "X-Amz-Signature", valid_402658392
  var valid_402658393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658393 = validateParameter(valid_402658393, JString,
                                      required = false, default = nil)
  if valid_402658393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658393
  var valid_402658394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658394 = validateParameter(valid_402658394, JString,
                                      required = false, default = nil)
  if valid_402658394 != nil:
    section.add "X-Amz-Algorithm", valid_402658394
  var valid_402658395 = header.getOrDefault("X-Amz-Date")
  valid_402658395 = validateParameter(valid_402658395, JString,
                                      required = false, default = nil)
  if valid_402658395 != nil:
    section.add "X-Amz-Date", valid_402658395
  var valid_402658396 = header.getOrDefault("X-Amz-Credential")
  valid_402658396 = validateParameter(valid_402658396, JString,
                                      required = false, default = nil)
  if valid_402658396 != nil:
    section.add "X-Amz-Credential", valid_402658396
  var valid_402658397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658397 = validateParameter(valid_402658397, JString,
                                      required = false, default = nil)
  if valid_402658397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658398: Call_GetRemoveTagsFromResource_402658384;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658398.validator(path, query, header, formData, body, _)
  let scheme = call_402658398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658398.makeUrl(scheme.get, call_402658398.host, call_402658398.base,
                                   call_402658398.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658398, uri, valid, _)

proc call*(call_402658399: Call_GetRemoveTagsFromResource_402658384;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2013-09-09";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## getRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402658400 = newJObject()
  if TagKeys != nil:
    query_402658400.add "TagKeys", TagKeys
  add(query_402658400, "Version", newJString(Version))
  add(query_402658400, "ResourceName", newJString(ResourceName))
  add(query_402658400, "Action", newJString(Action))
  result = call_402658399.call(nil, query_402658400, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_402658384(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_402658385, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_402658386,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_402658437 = ref object of OpenApiRestCall_402656035
proc url_PostResetDBParameterGroup_402658439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_402658438(path: JsonNode;
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
  var valid_402658440 = query.getOrDefault("Version")
  valid_402658440 = validateParameter(valid_402658440, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658440 != nil:
    section.add "Version", valid_402658440
  var valid_402658441 = query.getOrDefault("Action")
  valid_402658441 = validateParameter(valid_402658441, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658441 != nil:
    section.add "Action", valid_402658441
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
  var valid_402658442 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658442 = validateParameter(valid_402658442, JString,
                                      required = false, default = nil)
  if valid_402658442 != nil:
    section.add "X-Amz-Security-Token", valid_402658442
  var valid_402658443 = header.getOrDefault("X-Amz-Signature")
  valid_402658443 = validateParameter(valid_402658443, JString,
                                      required = false, default = nil)
  if valid_402658443 != nil:
    section.add "X-Amz-Signature", valid_402658443
  var valid_402658444 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658444 = validateParameter(valid_402658444, JString,
                                      required = false, default = nil)
  if valid_402658444 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658444
  var valid_402658445 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658445 = validateParameter(valid_402658445, JString,
                                      required = false, default = nil)
  if valid_402658445 != nil:
    section.add "X-Amz-Algorithm", valid_402658445
  var valid_402658446 = header.getOrDefault("X-Amz-Date")
  valid_402658446 = validateParameter(valid_402658446, JString,
                                      required = false, default = nil)
  if valid_402658446 != nil:
    section.add "X-Amz-Date", valid_402658446
  var valid_402658447 = header.getOrDefault("X-Amz-Credential")
  valid_402658447 = validateParameter(valid_402658447, JString,
                                      required = false, default = nil)
  if valid_402658447 != nil:
    section.add "X-Amz-Credential", valid_402658447
  var valid_402658448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658448 = validateParameter(valid_402658448, JString,
                                      required = false, default = nil)
  if valid_402658448 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658448
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658449 = formData.getOrDefault("DBParameterGroupName")
  valid_402658449 = validateParameter(valid_402658449, JString, required = true,
                                      default = nil)
  if valid_402658449 != nil:
    section.add "DBParameterGroupName", valid_402658449
  var valid_402658450 = formData.getOrDefault("Parameters")
  valid_402658450 = validateParameter(valid_402658450, JArray, required = false,
                                      default = nil)
  if valid_402658450 != nil:
    section.add "Parameters", valid_402658450
  var valid_402658451 = formData.getOrDefault("ResetAllParameters")
  valid_402658451 = validateParameter(valid_402658451, JBool, required = false,
                                      default = nil)
  if valid_402658451 != nil:
    section.add "ResetAllParameters", valid_402658451
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658452: Call_PostResetDBParameterGroup_402658437;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658452.validator(path, query, header, formData, body, _)
  let scheme = call_402658452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658452.makeUrl(scheme.get, call_402658452.host, call_402658452.base,
                                   call_402658452.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658452, uri, valid, _)

proc call*(call_402658453: Call_PostResetDBParameterGroup_402658437;
           DBParameterGroupName: string; Version: string = "2013-09-09";
           Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
           ResetAllParameters: bool = false): Recallable =
  ## postResetDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  var query_402658454 = newJObject()
  var formData_402658455 = newJObject()
  add(query_402658454, "Version", newJString(Version))
  add(formData_402658455, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658454, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658455.add "Parameters", Parameters
  add(formData_402658455, "ResetAllParameters", newJBool(ResetAllParameters))
  result = call_402658453.call(nil, query_402658454, nil, formData_402658455,
                               nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_402658437(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_402658438, base: "/",
    makeUrl: url_PostResetDBParameterGroup_402658439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_402658419 = ref object of OpenApiRestCall_402656035
proc url_GetResetDBParameterGroup_402658421(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_402658420(path: JsonNode;
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
  var valid_402658422 = query.getOrDefault("Parameters")
  valid_402658422 = validateParameter(valid_402658422, JArray, required = false,
                                      default = nil)
  if valid_402658422 != nil:
    section.add "Parameters", valid_402658422
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658423 = query.getOrDefault("DBParameterGroupName")
  valid_402658423 = validateParameter(valid_402658423, JString, required = true,
                                      default = nil)
  if valid_402658423 != nil:
    section.add "DBParameterGroupName", valid_402658423
  var valid_402658424 = query.getOrDefault("Version")
  valid_402658424 = validateParameter(valid_402658424, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658424 != nil:
    section.add "Version", valid_402658424
  var valid_402658425 = query.getOrDefault("ResetAllParameters")
  valid_402658425 = validateParameter(valid_402658425, JBool, required = false,
                                      default = nil)
  if valid_402658425 != nil:
    section.add "ResetAllParameters", valid_402658425
  var valid_402658426 = query.getOrDefault("Action")
  valid_402658426 = validateParameter(valid_402658426, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658426 != nil:
    section.add "Action", valid_402658426
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
  var valid_402658427 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658427 = validateParameter(valid_402658427, JString,
                                      required = false, default = nil)
  if valid_402658427 != nil:
    section.add "X-Amz-Security-Token", valid_402658427
  var valid_402658428 = header.getOrDefault("X-Amz-Signature")
  valid_402658428 = validateParameter(valid_402658428, JString,
                                      required = false, default = nil)
  if valid_402658428 != nil:
    section.add "X-Amz-Signature", valid_402658428
  var valid_402658429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658429 = validateParameter(valid_402658429, JString,
                                      required = false, default = nil)
  if valid_402658429 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658429
  var valid_402658430 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658430 = validateParameter(valid_402658430, JString,
                                      required = false, default = nil)
  if valid_402658430 != nil:
    section.add "X-Amz-Algorithm", valid_402658430
  var valid_402658431 = header.getOrDefault("X-Amz-Date")
  valid_402658431 = validateParameter(valid_402658431, JString,
                                      required = false, default = nil)
  if valid_402658431 != nil:
    section.add "X-Amz-Date", valid_402658431
  var valid_402658432 = header.getOrDefault("X-Amz-Credential")
  valid_402658432 = validateParameter(valid_402658432, JString,
                                      required = false, default = nil)
  if valid_402658432 != nil:
    section.add "X-Amz-Credential", valid_402658432
  var valid_402658433 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658433 = validateParameter(valid_402658433, JString,
                                      required = false, default = nil)
  if valid_402658433 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658433
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658434: Call_GetResetDBParameterGroup_402658419;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658434.validator(path, query, header, formData, body, _)
  let scheme = call_402658434.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658434.makeUrl(scheme.get, call_402658434.host, call_402658434.base,
                                   call_402658434.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658434, uri, valid, _)

proc call*(call_402658435: Call_GetResetDBParameterGroup_402658419;
           DBParameterGroupName: string; Parameters: JsonNode = nil;
           Version: string = "2013-09-09"; ResetAllParameters: bool = false;
           Action: string = "ResetDBParameterGroup"): Recallable =
  ## getResetDBParameterGroup
  ##   Parameters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  var query_402658436 = newJObject()
  if Parameters != nil:
    query_402658436.add "Parameters", Parameters
  add(query_402658436, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658436, "Version", newJString(Version))
  add(query_402658436, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_402658436, "Action", newJString(Action))
  result = call_402658435.call(nil, query_402658436, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_402658419(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_402658420, base: "/",
    makeUrl: url_GetResetDBParameterGroup_402658421,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_402658486 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceFromDBSnapshot_402658488(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_402658487(path: JsonNode;
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
  var valid_402658489 = query.getOrDefault("Version")
  valid_402658489 = validateParameter(valid_402658489, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658489 != nil:
    section.add "Version", valid_402658489
  var valid_402658490 = query.getOrDefault("Action")
  valid_402658490 = validateParameter(valid_402658490, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658490 != nil:
    section.add "Action", valid_402658490
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
  var valid_402658491 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658491 = validateParameter(valid_402658491, JString,
                                      required = false, default = nil)
  if valid_402658491 != nil:
    section.add "X-Amz-Security-Token", valid_402658491
  var valid_402658492 = header.getOrDefault("X-Amz-Signature")
  valid_402658492 = validateParameter(valid_402658492, JString,
                                      required = false, default = nil)
  if valid_402658492 != nil:
    section.add "X-Amz-Signature", valid_402658492
  var valid_402658493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658493 = validateParameter(valid_402658493, JString,
                                      required = false, default = nil)
  if valid_402658493 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658493
  var valid_402658494 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658494 = validateParameter(valid_402658494, JString,
                                      required = false, default = nil)
  if valid_402658494 != nil:
    section.add "X-Amz-Algorithm", valid_402658494
  var valid_402658495 = header.getOrDefault("X-Amz-Date")
  valid_402658495 = validateParameter(valid_402658495, JString,
                                      required = false, default = nil)
  if valid_402658495 != nil:
    section.add "X-Amz-Date", valid_402658495
  var valid_402658496 = header.getOrDefault("X-Amz-Credential")
  valid_402658496 = validateParameter(valid_402658496, JString,
                                      required = false, default = nil)
  if valid_402658496 != nil:
    section.add "X-Amz-Credential", valid_402658496
  var valid_402658497 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658497 = validateParameter(valid_402658497, JString,
                                      required = false, default = nil)
  if valid_402658497 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658497
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AvailabilityZone: JString
  ##   DBName: JString
  ##   Tags: JArray
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  section = newJObject()
  var valid_402658498 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658498 = validateParameter(valid_402658498, JBool, required = false,
                                      default = nil)
  if valid_402658498 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658498
  var valid_402658499 = formData.getOrDefault("Port")
  valid_402658499 = validateParameter(valid_402658499, JInt, required = false,
                                      default = nil)
  if valid_402658499 != nil:
    section.add "Port", valid_402658499
  var valid_402658500 = formData.getOrDefault("Engine")
  valid_402658500 = validateParameter(valid_402658500, JString,
                                      required = false, default = nil)
  if valid_402658500 != nil:
    section.add "Engine", valid_402658500
  var valid_402658501 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658501 = validateParameter(valid_402658501, JString,
                                      required = false, default = nil)
  if valid_402658501 != nil:
    section.add "DBSubnetGroupName", valid_402658501
  var valid_402658502 = formData.getOrDefault("PubliclyAccessible")
  valid_402658502 = validateParameter(valid_402658502, JBool, required = false,
                                      default = nil)
  if valid_402658502 != nil:
    section.add "PubliclyAccessible", valid_402658502
  var valid_402658503 = formData.getOrDefault("AvailabilityZone")
  valid_402658503 = validateParameter(valid_402658503, JString,
                                      required = false, default = nil)
  if valid_402658503 != nil:
    section.add "AvailabilityZone", valid_402658503
  var valid_402658504 = formData.getOrDefault("DBName")
  valid_402658504 = validateParameter(valid_402658504, JString,
                                      required = false, default = nil)
  if valid_402658504 != nil:
    section.add "DBName", valid_402658504
  var valid_402658505 = formData.getOrDefault("Tags")
  valid_402658505 = validateParameter(valid_402658505, JArray, required = false,
                                      default = nil)
  if valid_402658505 != nil:
    section.add "Tags", valid_402658505
  var valid_402658506 = formData.getOrDefault("Iops")
  valid_402658506 = validateParameter(valid_402658506, JInt, required = false,
                                      default = nil)
  if valid_402658506 != nil:
    section.add "Iops", valid_402658506
  var valid_402658507 = formData.getOrDefault("DBInstanceClass")
  valid_402658507 = validateParameter(valid_402658507, JString,
                                      required = false, default = nil)
  if valid_402658507 != nil:
    section.add "DBInstanceClass", valid_402658507
  var valid_402658508 = formData.getOrDefault("LicenseModel")
  valid_402658508 = validateParameter(valid_402658508, JString,
                                      required = false, default = nil)
  if valid_402658508 != nil:
    section.add "LicenseModel", valid_402658508
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658509 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658509 = validateParameter(valid_402658509, JString, required = true,
                                      default = nil)
  if valid_402658509 != nil:
    section.add "DBInstanceIdentifier", valid_402658509
  var valid_402658510 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402658510 = validateParameter(valid_402658510, JString, required = true,
                                      default = nil)
  if valid_402658510 != nil:
    section.add "DBSnapshotIdentifier", valid_402658510
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
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658513: Call_PostRestoreDBInstanceFromDBSnapshot_402658486;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658513.validator(path, query, header, formData, body, _)
  let scheme = call_402658513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658513.makeUrl(scheme.get, call_402658513.host, call_402658513.base,
                                   call_402658513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658513, uri, valid, _)

proc call*(call_402658514: Call_PostRestoreDBInstanceFromDBSnapshot_402658486;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           Engine: string = ""; DBSubnetGroupName: string = "";
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           DBName: string = ""; Tags: JsonNode = nil;
           Version: string = "2013-09-09"; Iops: int = 0;
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
  ##   Tags: JArray
  ##   Version: string (required)
  ##   Iops: int
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   MultiAZ: bool
  ##   OptionGroupName: string
  ##   Action: string (required)
  var query_402658515 = newJObject()
  var formData_402658516 = newJObject()
  add(formData_402658516, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658516, "Port", newJInt(Port))
  add(formData_402658516, "Engine", newJString(Engine))
  add(formData_402658516, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658516, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658516, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658516, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402658516.add "Tags", Tags
  add(query_402658515, "Version", newJString(Version))
  add(formData_402658516, "Iops", newJInt(Iops))
  add(formData_402658516, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658516, "LicenseModel", newJString(LicenseModel))
  add(formData_402658516, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658516, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402658516, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658516, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658515, "Action", newJString(Action))
  result = call_402658514.call(nil, query_402658515, nil, formData_402658516,
                               nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_402658486(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_402658487,
    base: "/", makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_402658488,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_402658456 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceFromDBSnapshot_402658458(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_402658457(path: JsonNode;
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
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Engine: JString
  ##   Port: JInt
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402658459 = query.getOrDefault("PubliclyAccessible")
  valid_402658459 = validateParameter(valid_402658459, JBool, required = false,
                                      default = nil)
  if valid_402658459 != nil:
    section.add "PubliclyAccessible", valid_402658459
  var valid_402658460 = query.getOrDefault("OptionGroupName")
  valid_402658460 = validateParameter(valid_402658460, JString,
                                      required = false, default = nil)
  if valid_402658460 != nil:
    section.add "OptionGroupName", valid_402658460
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658461 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658461 = validateParameter(valid_402658461, JString, required = true,
                                      default = nil)
  if valid_402658461 != nil:
    section.add "DBInstanceIdentifier", valid_402658461
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
  var valid_402658466 = query.getOrDefault("Version")
  valid_402658466 = validateParameter(valid_402658466, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658466 != nil:
    section.add "Version", valid_402658466
  var valid_402658467 = query.getOrDefault("Tags")
  valid_402658467 = validateParameter(valid_402658467, JArray, required = false,
                                      default = nil)
  if valid_402658467 != nil:
    section.add "Tags", valid_402658467
  var valid_402658468 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658468 = validateParameter(valid_402658468, JBool, required = false,
                                      default = nil)
  if valid_402658468 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658468
  var valid_402658469 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402658469 = validateParameter(valid_402658469, JString, required = true,
                                      default = nil)
  if valid_402658469 != nil:
    section.add "DBSnapshotIdentifier", valid_402658469
  var valid_402658470 = query.getOrDefault("DBName")
  valid_402658470 = validateParameter(valid_402658470, JString,
                                      required = false, default = nil)
  if valid_402658470 != nil:
    section.add "DBName", valid_402658470
  var valid_402658471 = query.getOrDefault("DBInstanceClass")
  valid_402658471 = validateParameter(valid_402658471, JString,
                                      required = false, default = nil)
  if valid_402658471 != nil:
    section.add "DBInstanceClass", valid_402658471
  var valid_402658472 = query.getOrDefault("Engine")
  valid_402658472 = validateParameter(valid_402658472, JString,
                                      required = false, default = nil)
  if valid_402658472 != nil:
    section.add "Engine", valid_402658472
  var valid_402658473 = query.getOrDefault("Port")
  valid_402658473 = validateParameter(valid_402658473, JInt, required = false,
                                      default = nil)
  if valid_402658473 != nil:
    section.add "Port", valid_402658473
  var valid_402658474 = query.getOrDefault("Action")
  valid_402658474 = validateParameter(valid_402658474, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658474 != nil:
    section.add "Action", valid_402658474
  var valid_402658475 = query.getOrDefault("LicenseModel")
  valid_402658475 = validateParameter(valid_402658475, JString,
                                      required = false, default = nil)
  if valid_402658475 != nil:
    section.add "LicenseModel", valid_402658475
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
  var valid_402658476 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658476 = validateParameter(valid_402658476, JString,
                                      required = false, default = nil)
  if valid_402658476 != nil:
    section.add "X-Amz-Security-Token", valid_402658476
  var valid_402658477 = header.getOrDefault("X-Amz-Signature")
  valid_402658477 = validateParameter(valid_402658477, JString,
                                      required = false, default = nil)
  if valid_402658477 != nil:
    section.add "X-Amz-Signature", valid_402658477
  var valid_402658478 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658478 = validateParameter(valid_402658478, JString,
                                      required = false, default = nil)
  if valid_402658478 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658478
  var valid_402658479 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658479 = validateParameter(valid_402658479, JString,
                                      required = false, default = nil)
  if valid_402658479 != nil:
    section.add "X-Amz-Algorithm", valid_402658479
  var valid_402658480 = header.getOrDefault("X-Amz-Date")
  valid_402658480 = validateParameter(valid_402658480, JString,
                                      required = false, default = nil)
  if valid_402658480 != nil:
    section.add "X-Amz-Date", valid_402658480
  var valid_402658481 = header.getOrDefault("X-Amz-Credential")
  valid_402658481 = validateParameter(valid_402658481, JString,
                                      required = false, default = nil)
  if valid_402658481 != nil:
    section.add "X-Amz-Credential", valid_402658481
  var valid_402658482 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658482 = validateParameter(valid_402658482, JString,
                                      required = false, default = nil)
  if valid_402658482 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658482
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658483: Call_GetRestoreDBInstanceFromDBSnapshot_402658456;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658483.validator(path, query, header, formData, body, _)
  let scheme = call_402658483.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658483.makeUrl(scheme.get, call_402658483.host, call_402658483.base,
                                   call_402658483.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658483, uri, valid, _)

proc call*(call_402658484: Call_GetRestoreDBInstanceFromDBSnapshot_402658456;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           DBSubnetGroupName: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; MultiAZ: bool = false;
           Version: string = "2013-09-09"; Tags: JsonNode = nil;
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
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Engine: string
  ##   Port: int
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402658485 = newJObject()
  add(query_402658485, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658485, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658485, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658485, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658485, "Iops", newJInt(Iops))
  add(query_402658485, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658485, "MultiAZ", newJBool(MultiAZ))
  add(query_402658485, "Version", newJString(Version))
  if Tags != nil:
    query_402658485.add "Tags", Tags
  add(query_402658485, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658485, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402658485, "DBName", newJString(DBName))
  add(query_402658485, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658485, "Engine", newJString(Engine))
  add(query_402658485, "Port", newJInt(Port))
  add(query_402658485, "Action", newJString(Action))
  add(query_402658485, "LicenseModel", newJString(LicenseModel))
  result = call_402658484.call(nil, query_402658485, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_402658456(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_402658457, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_402658458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_402658549 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceToPointInTime_402658551(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_402658550(path: JsonNode;
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
  var valid_402658552 = query.getOrDefault("Version")
  valid_402658552 = validateParameter(valid_402658552, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658552 != nil:
    section.add "Version", valid_402658552
  var valid_402658553 = query.getOrDefault("Action")
  valid_402658553 = validateParameter(valid_402658553, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658553 != nil:
    section.add "Action", valid_402658553
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
  var valid_402658554 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658554 = validateParameter(valid_402658554, JString,
                                      required = false, default = nil)
  if valid_402658554 != nil:
    section.add "X-Amz-Security-Token", valid_402658554
  var valid_402658555 = header.getOrDefault("X-Amz-Signature")
  valid_402658555 = validateParameter(valid_402658555, JString,
                                      required = false, default = nil)
  if valid_402658555 != nil:
    section.add "X-Amz-Signature", valid_402658555
  var valid_402658556 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658556 = validateParameter(valid_402658556, JString,
                                      required = false, default = nil)
  if valid_402658556 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658556
  var valid_402658557 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658557 = validateParameter(valid_402658557, JString,
                                      required = false, default = nil)
  if valid_402658557 != nil:
    section.add "X-Amz-Algorithm", valid_402658557
  var valid_402658558 = header.getOrDefault("X-Amz-Date")
  valid_402658558 = validateParameter(valid_402658558, JString,
                                      required = false, default = nil)
  if valid_402658558 != nil:
    section.add "X-Amz-Date", valid_402658558
  var valid_402658559 = header.getOrDefault("X-Amz-Credential")
  valid_402658559 = validateParameter(valid_402658559, JString,
                                      required = false, default = nil)
  if valid_402658559 != nil:
    section.add "X-Amz-Credential", valid_402658559
  var valid_402658560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658560 = validateParameter(valid_402658560, JString,
                                      required = false, default = nil)
  if valid_402658560 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658560
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
  ##   Tags: JArray
  ##   Iops: JInt
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   RestoreTime: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658561 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658561 = validateParameter(valid_402658561, JBool, required = false,
                                      default = nil)
  if valid_402658561 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658561
  var valid_402658562 = formData.getOrDefault("Port")
  valid_402658562 = validateParameter(valid_402658562, JInt, required = false,
                                      default = nil)
  if valid_402658562 != nil:
    section.add "Port", valid_402658562
  var valid_402658563 = formData.getOrDefault("UseLatestRestorableTime")
  valid_402658563 = validateParameter(valid_402658563, JBool, required = false,
                                      default = nil)
  if valid_402658563 != nil:
    section.add "UseLatestRestorableTime", valid_402658563
  var valid_402658564 = formData.getOrDefault("Engine")
  valid_402658564 = validateParameter(valid_402658564, JString,
                                      required = false, default = nil)
  if valid_402658564 != nil:
    section.add "Engine", valid_402658564
  var valid_402658565 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658565 = validateParameter(valid_402658565, JString,
                                      required = false, default = nil)
  if valid_402658565 != nil:
    section.add "DBSubnetGroupName", valid_402658565
  var valid_402658566 = formData.getOrDefault("PubliclyAccessible")
  valid_402658566 = validateParameter(valid_402658566, JBool, required = false,
                                      default = nil)
  if valid_402658566 != nil:
    section.add "PubliclyAccessible", valid_402658566
  var valid_402658567 = formData.getOrDefault("AvailabilityZone")
  valid_402658567 = validateParameter(valid_402658567, JString,
                                      required = false, default = nil)
  if valid_402658567 != nil:
    section.add "AvailabilityZone", valid_402658567
  var valid_402658568 = formData.getOrDefault("DBName")
  valid_402658568 = validateParameter(valid_402658568, JString,
                                      required = false, default = nil)
  if valid_402658568 != nil:
    section.add "DBName", valid_402658568
  var valid_402658569 = formData.getOrDefault("Tags")
  valid_402658569 = validateParameter(valid_402658569, JArray, required = false,
                                      default = nil)
  if valid_402658569 != nil:
    section.add "Tags", valid_402658569
  var valid_402658570 = formData.getOrDefault("Iops")
  valid_402658570 = validateParameter(valid_402658570, JInt, required = false,
                                      default = nil)
  if valid_402658570 != nil:
    section.add "Iops", valid_402658570
  var valid_402658571 = formData.getOrDefault("DBInstanceClass")
  valid_402658571 = validateParameter(valid_402658571, JString,
                                      required = false, default = nil)
  if valid_402658571 != nil:
    section.add "DBInstanceClass", valid_402658571
  var valid_402658572 = formData.getOrDefault("LicenseModel")
  valid_402658572 = validateParameter(valid_402658572, JString,
                                      required = false, default = nil)
  if valid_402658572 != nil:
    section.add "LicenseModel", valid_402658572
  var valid_402658573 = formData.getOrDefault("MultiAZ")
  valid_402658573 = validateParameter(valid_402658573, JBool, required = false,
                                      default = nil)
  if valid_402658573 != nil:
    section.add "MultiAZ", valid_402658573
  var valid_402658574 = formData.getOrDefault("OptionGroupName")
  valid_402658574 = validateParameter(valid_402658574, JString,
                                      required = false, default = nil)
  if valid_402658574 != nil:
    section.add "OptionGroupName", valid_402658574
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_402658575 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658575 = validateParameter(valid_402658575, JString, required = true,
                                      default = nil)
  if valid_402658575 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658575
  var valid_402658576 = formData.getOrDefault("RestoreTime")
  valid_402658576 = validateParameter(valid_402658576, JString,
                                      required = false, default = nil)
  if valid_402658576 != nil:
    section.add "RestoreTime", valid_402658576
  var valid_402658577 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658577 = validateParameter(valid_402658577, JString, required = true,
                                      default = nil)
  if valid_402658577 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658577
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658578: Call_PostRestoreDBInstanceToPointInTime_402658549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658578.validator(path, query, header, formData, body, _)
  let scheme = call_402658578.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658578.makeUrl(scheme.get, call_402658578.host, call_402658578.base,
                                   call_402658578.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658578, uri, valid, _)

proc call*(call_402658579: Call_PostRestoreDBInstanceToPointInTime_402658549;
           TargetDBInstanceIdentifier: string;
           SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           UseLatestRestorableTime: bool = false; Engine: string = "";
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; DBName: string = "";
           Tags: JsonNode = nil; Version: string = "2013-09-09"; Iops: int = 0;
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
  ##   Tags: JArray
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
  var query_402658580 = newJObject()
  var formData_402658581 = newJObject()
  add(formData_402658581, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658581, "Port", newJInt(Port))
  add(formData_402658581, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_402658581, "Engine", newJString(Engine))
  add(formData_402658581, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658581, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658581, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658581, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402658581.add "Tags", Tags
  add(query_402658580, "Version", newJString(Version))
  add(formData_402658581, "Iops", newJInt(Iops))
  add(formData_402658581, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658581, "LicenseModel", newJString(LicenseModel))
  add(formData_402658581, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658581, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658580, "Action", newJString(Action))
  add(formData_402658581, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_402658581, "RestoreTime", newJString(RestoreTime))
  add(formData_402658581, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402658579.call(nil, query_402658580, nil, formData_402658581,
                               nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_402658549(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_402658550, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_402658551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_402658517 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceToPointInTime_402658519(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_402658518(path: JsonNode;
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
  ##   Tags: JArray
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
  var valid_402658520 = query.getOrDefault("PubliclyAccessible")
  valid_402658520 = validateParameter(valid_402658520, JBool, required = false,
                                      default = nil)
  if valid_402658520 != nil:
    section.add "PubliclyAccessible", valid_402658520
  var valid_402658521 = query.getOrDefault("OptionGroupName")
  valid_402658521 = validateParameter(valid_402658521, JString,
                                      required = false, default = nil)
  if valid_402658521 != nil:
    section.add "OptionGroupName", valid_402658521
  var valid_402658522 = query.getOrDefault("DBSubnetGroupName")
  valid_402658522 = validateParameter(valid_402658522, JString,
                                      required = false, default = nil)
  if valid_402658522 != nil:
    section.add "DBSubnetGroupName", valid_402658522
  var valid_402658523 = query.getOrDefault("Iops")
  valid_402658523 = validateParameter(valid_402658523, JInt, required = false,
                                      default = nil)
  if valid_402658523 != nil:
    section.add "Iops", valid_402658523
  var valid_402658524 = query.getOrDefault("AvailabilityZone")
  valid_402658524 = validateParameter(valid_402658524, JString,
                                      required = false, default = nil)
  if valid_402658524 != nil:
    section.add "AvailabilityZone", valid_402658524
  var valid_402658525 = query.getOrDefault("MultiAZ")
  valid_402658525 = validateParameter(valid_402658525, JBool, required = false,
                                      default = nil)
  if valid_402658525 != nil:
    section.add "MultiAZ", valid_402658525
  var valid_402658526 = query.getOrDefault("RestoreTime")
  valid_402658526 = validateParameter(valid_402658526, JString,
                                      required = false, default = nil)
  if valid_402658526 != nil:
    section.add "RestoreTime", valid_402658526
  var valid_402658527 = query.getOrDefault("Version")
  valid_402658527 = validateParameter(valid_402658527, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658527 != nil:
    section.add "Version", valid_402658527
  var valid_402658528 = query.getOrDefault("Tags")
  valid_402658528 = validateParameter(valid_402658528, JArray, required = false,
                                      default = nil)
  if valid_402658528 != nil:
    section.add "Tags", valid_402658528
  var valid_402658529 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658529 = validateParameter(valid_402658529, JBool, required = false,
                                      default = nil)
  if valid_402658529 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658529
  var valid_402658530 = query.getOrDefault("UseLatestRestorableTime")
  valid_402658530 = validateParameter(valid_402658530, JBool, required = false,
                                      default = nil)
  if valid_402658530 != nil:
    section.add "UseLatestRestorableTime", valid_402658530
  var valid_402658531 = query.getOrDefault("DBName")
  valid_402658531 = validateParameter(valid_402658531, JString,
                                      required = false, default = nil)
  if valid_402658531 != nil:
    section.add "DBName", valid_402658531
  var valid_402658532 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658532 = validateParameter(valid_402658532, JString, required = true,
                                      default = nil)
  if valid_402658532 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658532
  var valid_402658533 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658533 = validateParameter(valid_402658533, JString, required = true,
                                      default = nil)
  if valid_402658533 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658533
  var valid_402658534 = query.getOrDefault("DBInstanceClass")
  valid_402658534 = validateParameter(valid_402658534, JString,
                                      required = false, default = nil)
  if valid_402658534 != nil:
    section.add "DBInstanceClass", valid_402658534
  var valid_402658535 = query.getOrDefault("Engine")
  valid_402658535 = validateParameter(valid_402658535, JString,
                                      required = false, default = nil)
  if valid_402658535 != nil:
    section.add "Engine", valid_402658535
  var valid_402658536 = query.getOrDefault("Port")
  valid_402658536 = validateParameter(valid_402658536, JInt, required = false,
                                      default = nil)
  if valid_402658536 != nil:
    section.add "Port", valid_402658536
  var valid_402658537 = query.getOrDefault("Action")
  valid_402658537 = validateParameter(valid_402658537, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658537 != nil:
    section.add "Action", valid_402658537
  var valid_402658538 = query.getOrDefault("LicenseModel")
  valid_402658538 = validateParameter(valid_402658538, JString,
                                      required = false, default = nil)
  if valid_402658538 != nil:
    section.add "LicenseModel", valid_402658538
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
  var valid_402658539 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658539 = validateParameter(valid_402658539, JString,
                                      required = false, default = nil)
  if valid_402658539 != nil:
    section.add "X-Amz-Security-Token", valid_402658539
  var valid_402658540 = header.getOrDefault("X-Amz-Signature")
  valid_402658540 = validateParameter(valid_402658540, JString,
                                      required = false, default = nil)
  if valid_402658540 != nil:
    section.add "X-Amz-Signature", valid_402658540
  var valid_402658541 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658541 = validateParameter(valid_402658541, JString,
                                      required = false, default = nil)
  if valid_402658541 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658541
  var valid_402658542 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658542 = validateParameter(valid_402658542, JString,
                                      required = false, default = nil)
  if valid_402658542 != nil:
    section.add "X-Amz-Algorithm", valid_402658542
  var valid_402658543 = header.getOrDefault("X-Amz-Date")
  valid_402658543 = validateParameter(valid_402658543, JString,
                                      required = false, default = nil)
  if valid_402658543 != nil:
    section.add "X-Amz-Date", valid_402658543
  var valid_402658544 = header.getOrDefault("X-Amz-Credential")
  valid_402658544 = validateParameter(valid_402658544, JString,
                                      required = false, default = nil)
  if valid_402658544 != nil:
    section.add "X-Amz-Credential", valid_402658544
  var valid_402658545 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658545 = validateParameter(valid_402658545, JString,
                                      required = false, default = nil)
  if valid_402658545 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658545
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658546: Call_GetRestoreDBInstanceToPointInTime_402658517;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658546.validator(path, query, header, formData, body, _)
  let scheme = call_402658546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658546.makeUrl(scheme.get, call_402658546.host, call_402658546.base,
                                   call_402658546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658546, uri, valid, _)

proc call*(call_402658547: Call_GetRestoreDBInstanceToPointInTime_402658517;
           SourceDBInstanceIdentifier: string;
           TargetDBInstanceIdentifier: string; PubliclyAccessible: bool = false;
           OptionGroupName: string = ""; DBSubnetGroupName: string = "";
           Iops: int = 0; AvailabilityZone: string = ""; MultiAZ: bool = false;
           RestoreTime: string = ""; Version: string = "2013-09-09";
           Tags: JsonNode = nil; AutoMinorVersionUpgrade: bool = false;
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
  ##   Tags: JArray
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
  var query_402658548 = newJObject()
  add(query_402658548, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658548, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658548, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658548, "Iops", newJInt(Iops))
  add(query_402658548, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658548, "MultiAZ", newJBool(MultiAZ))
  add(query_402658548, "RestoreTime", newJString(RestoreTime))
  add(query_402658548, "Version", newJString(Version))
  if Tags != nil:
    query_402658548.add "Tags", Tags
  add(query_402658548, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658548, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(query_402658548, "DBName", newJString(DBName))
  add(query_402658548, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402658548, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_402658548, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658548, "Engine", newJString(Engine))
  add(query_402658548, "Port", newJInt(Port))
  add(query_402658548, "Action", newJString(Action))
  add(query_402658548, "LicenseModel", newJString(LicenseModel))
  result = call_402658547.call(nil, query_402658548, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_402658517(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_402658518, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_402658519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_402658602 = ref object of OpenApiRestCall_402656035
proc url_PostRevokeDBSecurityGroupIngress_402658604(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_402658603(path: JsonNode;
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
  var valid_402658605 = query.getOrDefault("Version")
  valid_402658605 = validateParameter(valid_402658605, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658605 != nil:
    section.add "Version", valid_402658605
  var valid_402658606 = query.getOrDefault("Action")
  valid_402658606 = validateParameter(valid_402658606, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658606 != nil:
    section.add "Action", valid_402658606
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
  var valid_402658607 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658607 = validateParameter(valid_402658607, JString,
                                      required = false, default = nil)
  if valid_402658607 != nil:
    section.add "X-Amz-Security-Token", valid_402658607
  var valid_402658608 = header.getOrDefault("X-Amz-Signature")
  valid_402658608 = validateParameter(valid_402658608, JString,
                                      required = false, default = nil)
  if valid_402658608 != nil:
    section.add "X-Amz-Signature", valid_402658608
  var valid_402658609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658609 = validateParameter(valid_402658609, JString,
                                      required = false, default = nil)
  if valid_402658609 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658609
  var valid_402658610 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658610 = validateParameter(valid_402658610, JString,
                                      required = false, default = nil)
  if valid_402658610 != nil:
    section.add "X-Amz-Algorithm", valid_402658610
  var valid_402658611 = header.getOrDefault("X-Amz-Date")
  valid_402658611 = validateParameter(valid_402658611, JString,
                                      required = false, default = nil)
  if valid_402658611 != nil:
    section.add "X-Amz-Date", valid_402658611
  var valid_402658612 = header.getOrDefault("X-Amz-Credential")
  valid_402658612 = validateParameter(valid_402658612, JString,
                                      required = false, default = nil)
  if valid_402658612 != nil:
    section.add "X-Amz-Credential", valid_402658612
  var valid_402658613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658613 = validateParameter(valid_402658613, JString,
                                      required = false, default = nil)
  if valid_402658613 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658613
  result.add "header", section
  ## parameters in `formData` object:
  ##   EC2SecurityGroupName: JString
  ##   CIDRIP: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  section = newJObject()
  var valid_402658614 = formData.getOrDefault("EC2SecurityGroupName")
  valid_402658614 = validateParameter(valid_402658614, JString,
                                      required = false, default = nil)
  if valid_402658614 != nil:
    section.add "EC2SecurityGroupName", valid_402658614
  var valid_402658615 = formData.getOrDefault("CIDRIP")
  valid_402658615 = validateParameter(valid_402658615, JString,
                                      required = false, default = nil)
  if valid_402658615 != nil:
    section.add "CIDRIP", valid_402658615
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402658616 = formData.getOrDefault("DBSecurityGroupName")
  valid_402658616 = validateParameter(valid_402658616, JString, required = true,
                                      default = nil)
  if valid_402658616 != nil:
    section.add "DBSecurityGroupName", valid_402658616
  var valid_402658617 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658617 = validateParameter(valid_402658617, JString,
                                      required = false, default = nil)
  if valid_402658617 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658617
  var valid_402658618 = formData.getOrDefault("EC2SecurityGroupId")
  valid_402658618 = validateParameter(valid_402658618, JString,
                                      required = false, default = nil)
  if valid_402658618 != nil:
    section.add "EC2SecurityGroupId", valid_402658618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658619: Call_PostRevokeDBSecurityGroupIngress_402658602;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658619.validator(path, query, header, formData, body, _)
  let scheme = call_402658619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658619.makeUrl(scheme.get, call_402658619.host, call_402658619.base,
                                   call_402658619.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658619, uri, valid, _)

proc call*(call_402658620: Call_PostRevokeDBSecurityGroupIngress_402658602;
           DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
           CIDRIP: string = ""; Version: string = "2013-09-09";
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
  var query_402658621 = newJObject()
  var formData_402658622 = newJObject()
  add(formData_402658622, "EC2SecurityGroupName",
      newJString(EC2SecurityGroupName))
  add(formData_402658622, "CIDRIP", newJString(CIDRIP))
  add(query_402658621, "Version", newJString(Version))
  add(formData_402658622, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402658622, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658621, "Action", newJString(Action))
  add(formData_402658622, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  result = call_402658620.call(nil, query_402658621, nil, formData_402658622,
                               nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_402658602(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_402658603, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_402658604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_402658582 = ref object of OpenApiRestCall_402656035
proc url_GetRevokeDBSecurityGroupIngress_402658584(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_402658583(path: JsonNode;
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
  var valid_402658585 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658585 = validateParameter(valid_402658585, JString,
                                      required = false, default = nil)
  if valid_402658585 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658585
  var valid_402658586 = query.getOrDefault("EC2SecurityGroupId")
  valid_402658586 = validateParameter(valid_402658586, JString,
                                      required = false, default = nil)
  if valid_402658586 != nil:
    section.add "EC2SecurityGroupId", valid_402658586
  var valid_402658587 = query.getOrDefault("Version")
  valid_402658587 = validateParameter(valid_402658587, JString, required = true,
                                      default = newJString("2013-09-09"))
  if valid_402658587 != nil:
    section.add "Version", valid_402658587
  var valid_402658588 = query.getOrDefault("EC2SecurityGroupName")
  valid_402658588 = validateParameter(valid_402658588, JString,
                                      required = false, default = nil)
  if valid_402658588 != nil:
    section.add "EC2SecurityGroupName", valid_402658588
  var valid_402658589 = query.getOrDefault("Action")
  valid_402658589 = validateParameter(valid_402658589, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658589 != nil:
    section.add "Action", valid_402658589
  var valid_402658590 = query.getOrDefault("DBSecurityGroupName")
  valid_402658590 = validateParameter(valid_402658590, JString, required = true,
                                      default = nil)
  if valid_402658590 != nil:
    section.add "DBSecurityGroupName", valid_402658590
  var valid_402658591 = query.getOrDefault("CIDRIP")
  valid_402658591 = validateParameter(valid_402658591, JString,
                                      required = false, default = nil)
  if valid_402658591 != nil:
    section.add "CIDRIP", valid_402658591
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
  var valid_402658592 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658592 = validateParameter(valid_402658592, JString,
                                      required = false, default = nil)
  if valid_402658592 != nil:
    section.add "X-Amz-Security-Token", valid_402658592
  var valid_402658593 = header.getOrDefault("X-Amz-Signature")
  valid_402658593 = validateParameter(valid_402658593, JString,
                                      required = false, default = nil)
  if valid_402658593 != nil:
    section.add "X-Amz-Signature", valid_402658593
  var valid_402658594 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658594 = validateParameter(valid_402658594, JString,
                                      required = false, default = nil)
  if valid_402658594 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658594
  var valid_402658595 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658595 = validateParameter(valid_402658595, JString,
                                      required = false, default = nil)
  if valid_402658595 != nil:
    section.add "X-Amz-Algorithm", valid_402658595
  var valid_402658596 = header.getOrDefault("X-Amz-Date")
  valid_402658596 = validateParameter(valid_402658596, JString,
                                      required = false, default = nil)
  if valid_402658596 != nil:
    section.add "X-Amz-Date", valid_402658596
  var valid_402658597 = header.getOrDefault("X-Amz-Credential")
  valid_402658597 = validateParameter(valid_402658597, JString,
                                      required = false, default = nil)
  if valid_402658597 != nil:
    section.add "X-Amz-Credential", valid_402658597
  var valid_402658598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658598 = validateParameter(valid_402658598, JString,
                                      required = false, default = nil)
  if valid_402658598 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658598
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658599: Call_GetRevokeDBSecurityGroupIngress_402658582;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658599.validator(path, query, header, formData, body, _)
  let scheme = call_402658599.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658599.makeUrl(scheme.get, call_402658599.host, call_402658599.base,
                                   call_402658599.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658599, uri, valid, _)

proc call*(call_402658600: Call_GetRevokeDBSecurityGroupIngress_402658582;
           DBSecurityGroupName: string; EC2SecurityGroupOwnerId: string = "";
           EC2SecurityGroupId: string = ""; Version: string = "2013-09-09";
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
  var query_402658601 = newJObject()
  add(query_402658601, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658601, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_402658601, "Version", newJString(Version))
  add(query_402658601, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_402658601, "Action", newJString(Action))
  add(query_402658601, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402658601, "CIDRIP", newJString(CIDRIP))
  result = call_402658600.call(nil, query_402658601, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_402658582(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_402658583, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_402658584,
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
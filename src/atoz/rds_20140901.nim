
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Relational Database Service
## version: 2014-09-01
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
                                      default = newJString("2014-09-01"))
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
           Version: string = "2014-09-01";
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
                                      default = newJString("2014-09-01"))
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
           Version: string = "2014-09-01";
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
                                      default = newJString("2014-09-01"))
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
           ResourceName: string; Version: string = "2014-09-01";
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
                                      default = newJString("2014-09-01"))
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
           ResourceName: string; Version: string = "2014-09-01";
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
                                      default = newJString("2014-09-01"))
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
           CIDRIP: string = ""; Version: string = "2014-09-01";
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
                                      default = newJString("2014-09-01"))
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
           EC2SecurityGroupId: string = ""; Version: string = "2014-09-01";
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
  Call_PostCopyDBParameterGroup_402656595 = ref object of OpenApiRestCall_402656035
proc url_PostCopyDBParameterGroup_402656597(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBParameterGroup_402656596(path: JsonNode;
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
  var valid_402656598 = query.getOrDefault("Version")
  valid_402656598 = validateParameter(valid_402656598, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656598 != nil:
    section.add "Version", valid_402656598
  var valid_402656599 = query.getOrDefault("Action")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true, default = newJString(
      "CopyDBParameterGroup"))
  if valid_402656599 != nil:
    section.add "Action", valid_402656599
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
  var valid_402656600 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Security-Token", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Signature")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Signature", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Algorithm", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Date")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Date", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Credential")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Credential", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656606
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   
                                                           ## SourceDBParameterGroupIdentifier: JString (required)
  ##   
                                                                                                                  ## Tags: JArray
  ##   
                                                                                                                                 ## TargetDBParameterGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBParameterGroupIdentifier` field"
  var valid_402656607 = formData.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_402656607 = validateParameter(valid_402656607, JString, required = true,
                                      default = nil)
  if valid_402656607 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_402656607
  var valid_402656608 = formData.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_402656608
  var valid_402656609 = formData.getOrDefault("Tags")
  valid_402656609 = validateParameter(valid_402656609, JArray, required = false,
                                      default = nil)
  if valid_402656609 != nil:
    section.add "Tags", valid_402656609
  var valid_402656610 = formData.getOrDefault(
      "TargetDBParameterGroupDescription")
  valid_402656610 = validateParameter(valid_402656610, JString, required = true,
                                      default = nil)
  if valid_402656610 != nil:
    section.add "TargetDBParameterGroupDescription", valid_402656610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656611: Call_PostCopyDBParameterGroup_402656595;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656611.validator(path, query, header, formData, body, _)
  let scheme = call_402656611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656611.makeUrl(scheme.get, call_402656611.host, call_402656611.base,
                                   call_402656611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656611, uri, valid, _)

proc call*(call_402656612: Call_PostCopyDBParameterGroup_402656595;
           TargetDBParameterGroupIdentifier: string;
           SourceDBParameterGroupIdentifier: string;
           TargetDBParameterGroupDescription: string; Tags: JsonNode = nil;
           Version: string = "2014-09-01";
           Action: string = "CopyDBParameterGroup"): Recallable =
  ## postCopyDBParameterGroup
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   
                                                          ## SourceDBParameterGroupIdentifier: string (required)
  ##   
                                                                                                                ## Tags: JArray
  ##   
                                                                                                                               ## Version: string (required)
  ##   
                                                                                                                                                            ## Action: string (required)
  ##   
                                                                                                                                                                                        ## TargetDBParameterGroupDescription: string (required)
  var query_402656613 = newJObject()
  var formData_402656614 = newJObject()
  add(formData_402656614, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(formData_402656614, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  if Tags != nil:
    formData_402656614.add "Tags", Tags
  add(query_402656613, "Version", newJString(Version))
  add(query_402656613, "Action", newJString(Action))
  add(formData_402656614, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  result = call_402656612.call(nil, query_402656613, nil, formData_402656614,
                               nil)

var postCopyDBParameterGroup* = Call_PostCopyDBParameterGroup_402656595(
    name: "postCopyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_PostCopyDBParameterGroup_402656596, base: "/",
    makeUrl: url_PostCopyDBParameterGroup_402656597,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBParameterGroup_402656576 = ref object of OpenApiRestCall_402656035
proc url_GetCopyDBParameterGroup_402656578(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBParameterGroup_402656577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBParameterGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   TargetDBParameterGroupDescription: JString (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupIdentifier: JString (required)
  ##   Action: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBParameterGroupIdentifier` field"
  var valid_402656579 = query.getOrDefault("SourceDBParameterGroupIdentifier")
  valid_402656579 = validateParameter(valid_402656579, JString, required = true,
                                      default = nil)
  if valid_402656579 != nil:
    section.add "SourceDBParameterGroupIdentifier", valid_402656579
  var valid_402656580 = query.getOrDefault("Version")
  valid_402656580 = validateParameter(valid_402656580, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656580 != nil:
    section.add "Version", valid_402656580
  var valid_402656581 = query.getOrDefault("TargetDBParameterGroupDescription")
  valid_402656581 = validateParameter(valid_402656581, JString, required = true,
                                      default = nil)
  if valid_402656581 != nil:
    section.add "TargetDBParameterGroupDescription", valid_402656581
  var valid_402656582 = query.getOrDefault("Tags")
  valid_402656582 = validateParameter(valid_402656582, JArray, required = false,
                                      default = nil)
  if valid_402656582 != nil:
    section.add "Tags", valid_402656582
  var valid_402656583 = query.getOrDefault("TargetDBParameterGroupIdentifier")
  valid_402656583 = validateParameter(valid_402656583, JString, required = true,
                                      default = nil)
  if valid_402656583 != nil:
    section.add "TargetDBParameterGroupIdentifier", valid_402656583
  var valid_402656584 = query.getOrDefault("Action")
  valid_402656584 = validateParameter(valid_402656584, JString, required = true, default = newJString(
      "CopyDBParameterGroup"))
  if valid_402656584 != nil:
    section.add "Action", valid_402656584
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

proc call*(call_402656592: Call_GetCopyDBParameterGroup_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656592.validator(path, query, header, formData, body, _)
  let scheme = call_402656592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656592.makeUrl(scheme.get, call_402656592.host, call_402656592.base,
                                   call_402656592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656592, uri, valid, _)

proc call*(call_402656593: Call_GetCopyDBParameterGroup_402656576;
           SourceDBParameterGroupIdentifier: string;
           TargetDBParameterGroupDescription: string;
           TargetDBParameterGroupIdentifier: string;
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           Action: string = "CopyDBParameterGroup"): Recallable =
  ## getCopyDBParameterGroup
  ##   SourceDBParameterGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   TargetDBParameterGroupDescription: string (required)
  ##   Tags: JArray
  ##   TargetDBParameterGroupIdentifier: string (required)
  ##   Action: string (required)
  var query_402656594 = newJObject()
  add(query_402656594, "SourceDBParameterGroupIdentifier",
      newJString(SourceDBParameterGroupIdentifier))
  add(query_402656594, "Version", newJString(Version))
  add(query_402656594, "TargetDBParameterGroupDescription",
      newJString(TargetDBParameterGroupDescription))
  if Tags != nil:
    query_402656594.add "Tags", Tags
  add(query_402656594, "TargetDBParameterGroupIdentifier",
      newJString(TargetDBParameterGroupIdentifier))
  add(query_402656594, "Action", newJString(Action))
  result = call_402656593.call(nil, query_402656594, nil, nil, nil)

var getCopyDBParameterGroup* = Call_GetCopyDBParameterGroup_402656576(
    name: "getCopyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBParameterGroup",
    validator: validate_GetCopyDBParameterGroup_402656577, base: "/",
    makeUrl: url_GetCopyDBParameterGroup_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_402656633 = ref object of OpenApiRestCall_402656035
proc url_PostCopyDBSnapshot_402656635(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_402656634(path: JsonNode; query: JsonNode;
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
  var valid_402656636 = query.getOrDefault("Version")
  valid_402656636 = validateParameter(valid_402656636, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656636 != nil:
    section.add "Version", valid_402656636
  var valid_402656637 = query.getOrDefault("Action")
  valid_402656637 = validateParameter(valid_402656637, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656637 != nil:
    section.add "Action", valid_402656637
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
  var valid_402656638 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656638 = validateParameter(valid_402656638, JString,
                                      required = false, default = nil)
  if valid_402656638 != nil:
    section.add "X-Amz-Security-Token", valid_402656638
  var valid_402656639 = header.getOrDefault("X-Amz-Signature")
  valid_402656639 = validateParameter(valid_402656639, JString,
                                      required = false, default = nil)
  if valid_402656639 != nil:
    section.add "X-Amz-Signature", valid_402656639
  var valid_402656640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656640 = validateParameter(valid_402656640, JString,
                                      required = false, default = nil)
  if valid_402656640 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656640
  var valid_402656641 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "X-Amz-Algorithm", valid_402656641
  var valid_402656642 = header.getOrDefault("X-Amz-Date")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Date", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Credential")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Credential", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656644
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceDBSnapshotIdentifier` field"
  var valid_402656645 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_402656645 = validateParameter(valid_402656645, JString, required = true,
                                      default = nil)
  if valid_402656645 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_402656645
  var valid_402656646 = formData.getOrDefault("Tags")
  valid_402656646 = validateParameter(valid_402656646, JArray, required = false,
                                      default = nil)
  if valid_402656646 != nil:
    section.add "Tags", valid_402656646
  var valid_402656647 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_402656647 = validateParameter(valid_402656647, JString, required = true,
                                      default = nil)
  if valid_402656647 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_402656647
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656648: Call_PostCopyDBSnapshot_402656633;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656648.validator(path, query, header, formData, body, _)
  let scheme = call_402656648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656648.makeUrl(scheme.get, call_402656648.host, call_402656648.base,
                                   call_402656648.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656648, uri, valid, _)

proc call*(call_402656649: Call_PostCopyDBSnapshot_402656633;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Tags: JsonNode = nil;
           Version: string = "2014-09-01"; Action: string = "CopyDBSnapshot"): Recallable =
  ## postCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656650 = newJObject()
  var formData_402656651 = newJObject()
  add(formData_402656651, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  if Tags != nil:
    formData_402656651.add "Tags", Tags
  add(query_402656650, "Version", newJString(Version))
  add(formData_402656651, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656650, "Action", newJString(Action))
  result = call_402656649.call(nil, query_402656650, nil, formData_402656651,
                               nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_402656633(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_402656634, base: "/",
    makeUrl: url_PostCopyDBSnapshot_402656635,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_402656615 = ref object of OpenApiRestCall_402656035
proc url_GetCopyDBSnapshot_402656617(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_402656616(path: JsonNode; query: JsonNode;
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
  var valid_402656618 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_402656618 = validateParameter(valid_402656618, JString, required = true,
                                      default = nil)
  if valid_402656618 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_402656618
  var valid_402656619 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_402656619 = validateParameter(valid_402656619, JString, required = true,
                                      default = nil)
  if valid_402656619 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_402656619
  var valid_402656620 = query.getOrDefault("Version")
  valid_402656620 = validateParameter(valid_402656620, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656620 != nil:
    section.add "Version", valid_402656620
  var valid_402656621 = query.getOrDefault("Tags")
  valid_402656621 = validateParameter(valid_402656621, JArray, required = false,
                                      default = nil)
  if valid_402656621 != nil:
    section.add "Tags", valid_402656621
  var valid_402656622 = query.getOrDefault("Action")
  valid_402656622 = validateParameter(valid_402656622, JString, required = true,
                                      default = newJString("CopyDBSnapshot"))
  if valid_402656622 != nil:
    section.add "Action", valid_402656622
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
  var valid_402656623 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656623 = validateParameter(valid_402656623, JString,
                                      required = false, default = nil)
  if valid_402656623 != nil:
    section.add "X-Amz-Security-Token", valid_402656623
  var valid_402656624 = header.getOrDefault("X-Amz-Signature")
  valid_402656624 = validateParameter(valid_402656624, JString,
                                      required = false, default = nil)
  if valid_402656624 != nil:
    section.add "X-Amz-Signature", valid_402656624
  var valid_402656625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656625
  var valid_402656626 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Algorithm", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Date")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Date", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Credential")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Credential", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656629
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656630: Call_GetCopyDBSnapshot_402656615;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656630.validator(path, query, header, formData, body, _)
  let scheme = call_402656630.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656630.makeUrl(scheme.get, call_402656630.host, call_402656630.base,
                                   call_402656630.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656630, uri, valid, _)

proc call*(call_402656631: Call_GetCopyDBSnapshot_402656615;
           SourceDBSnapshotIdentifier: string;
           TargetDBSnapshotIdentifier: string; Version: string = "2014-09-01";
           Tags: JsonNode = nil; Action: string = "CopyDBSnapshot"): Recallable =
  ## getCopyDBSnapshot
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  var query_402656632 = newJObject()
  add(query_402656632, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_402656632, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_402656632, "Version", newJString(Version))
  if Tags != nil:
    query_402656632.add "Tags", Tags
  add(query_402656632, "Action", newJString(Action))
  result = call_402656631.call(nil, query_402656632, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_402656615(
    name: "getCopyDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_GetCopyDBSnapshot_402656616, base: "/",
    makeUrl: url_GetCopyDBSnapshot_402656617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyOptionGroup_402656671 = ref object of OpenApiRestCall_402656035
proc url_PostCopyOptionGroup_402656673(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyOptionGroup_402656672(path: JsonNode; query: JsonNode;
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
  var valid_402656674 = query.getOrDefault("Version")
  valid_402656674 = validateParameter(valid_402656674, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656674 != nil:
    section.add "Version", valid_402656674
  var valid_402656675 = query.getOrDefault("Action")
  valid_402656675 = validateParameter(valid_402656675, JString, required = true,
                                      default = newJString("CopyOptionGroup"))
  if valid_402656675 != nil:
    section.add "Action", valid_402656675
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
  var valid_402656676 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Security-Token", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Signature")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Signature", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Algorithm", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Date")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Date", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Credential")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Credential", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656682
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   
                                                      ## TargetOptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_402656683 = formData.getOrDefault("TargetOptionGroupIdentifier")
  valid_402656683 = validateParameter(valid_402656683, JString, required = true,
                                      default = nil)
  if valid_402656683 != nil:
    section.add "TargetOptionGroupIdentifier", valid_402656683
  var valid_402656684 = formData.getOrDefault("Tags")
  valid_402656684 = validateParameter(valid_402656684, JArray, required = false,
                                      default = nil)
  if valid_402656684 != nil:
    section.add "Tags", valid_402656684
  var valid_402656685 = formData.getOrDefault("SourceOptionGroupIdentifier")
  valid_402656685 = validateParameter(valid_402656685, JString, required = true,
                                      default = nil)
  if valid_402656685 != nil:
    section.add "SourceOptionGroupIdentifier", valid_402656685
  var valid_402656686 = formData.getOrDefault("TargetOptionGroupDescription")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "TargetOptionGroupDescription", valid_402656686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656687: Call_PostCopyOptionGroup_402656671;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656687.validator(path, query, header, formData, body, _)
  let scheme = call_402656687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656687.makeUrl(scheme.get, call_402656687.host, call_402656687.base,
                                   call_402656687.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656687, uri, valid, _)

proc call*(call_402656688: Call_PostCopyOptionGroup_402656671;
           TargetOptionGroupIdentifier: string;
           SourceOptionGroupIdentifier: string;
           TargetOptionGroupDescription: string; Tags: JsonNode = nil;
           Version: string = "2014-09-01"; Action: string = "CopyOptionGroup"): Recallable =
  ## postCopyOptionGroup
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  ##   Action: string (required)
  ##   TargetOptionGroupDescription: string (required)
  var query_402656689 = newJObject()
  var formData_402656690 = newJObject()
  add(formData_402656690, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  if Tags != nil:
    formData_402656690.add "Tags", Tags
  add(query_402656689, "Version", newJString(Version))
  add(formData_402656690, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_402656689, "Action", newJString(Action))
  add(formData_402656690, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  result = call_402656688.call(nil, query_402656689, nil, formData_402656690,
                               nil)

var postCopyOptionGroup* = Call_PostCopyOptionGroup_402656671(
    name: "postCopyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_PostCopyOptionGroup_402656672, base: "/",
    makeUrl: url_PostCopyOptionGroup_402656673,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyOptionGroup_402656652 = ref object of OpenApiRestCall_402656035
proc url_GetCopyOptionGroup_402656654(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyOptionGroup_402656653(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   TargetOptionGroupIdentifier: JString (required)
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   SourceOptionGroupIdentifier: JString (required)
  ##   
                                                      ## TargetOptionGroupDescription: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `TargetOptionGroupIdentifier` field"
  var valid_402656655 = query.getOrDefault("TargetOptionGroupIdentifier")
  valid_402656655 = validateParameter(valid_402656655, JString, required = true,
                                      default = nil)
  if valid_402656655 != nil:
    section.add "TargetOptionGroupIdentifier", valid_402656655
  var valid_402656656 = query.getOrDefault("Version")
  valid_402656656 = validateParameter(valid_402656656, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656656 != nil:
    section.add "Version", valid_402656656
  var valid_402656657 = query.getOrDefault("Tags")
  valid_402656657 = validateParameter(valid_402656657, JArray, required = false,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "Tags", valid_402656657
  var valid_402656658 = query.getOrDefault("Action")
  valid_402656658 = validateParameter(valid_402656658, JString, required = true,
                                      default = newJString("CopyOptionGroup"))
  if valid_402656658 != nil:
    section.add "Action", valid_402656658
  var valid_402656659 = query.getOrDefault("SourceOptionGroupIdentifier")
  valid_402656659 = validateParameter(valid_402656659, JString, required = true,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "SourceOptionGroupIdentifier", valid_402656659
  var valid_402656660 = query.getOrDefault("TargetOptionGroupDescription")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "TargetOptionGroupDescription", valid_402656660
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
  var valid_402656661 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Security-Token", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Signature")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Signature", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Algorithm", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Date")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Date", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Credential")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Credential", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656667
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656668: Call_GetCopyOptionGroup_402656652;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656668.validator(path, query, header, formData, body, _)
  let scheme = call_402656668.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656668.makeUrl(scheme.get, call_402656668.host, call_402656668.base,
                                   call_402656668.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656668, uri, valid, _)

proc call*(call_402656669: Call_GetCopyOptionGroup_402656652;
           TargetOptionGroupIdentifier: string;
           SourceOptionGroupIdentifier: string;
           TargetOptionGroupDescription: string; Version: string = "2014-09-01";
           Tags: JsonNode = nil; Action: string = "CopyOptionGroup"): Recallable =
  ## getCopyOptionGroup
  ##   TargetOptionGroupIdentifier: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceOptionGroupIdentifier: string (required)
  ##   
                                                     ## TargetOptionGroupDescription: string (required)
  var query_402656670 = newJObject()
  add(query_402656670, "TargetOptionGroupIdentifier",
      newJString(TargetOptionGroupIdentifier))
  add(query_402656670, "Version", newJString(Version))
  if Tags != nil:
    query_402656670.add "Tags", Tags
  add(query_402656670, "Action", newJString(Action))
  add(query_402656670, "SourceOptionGroupIdentifier",
      newJString(SourceOptionGroupIdentifier))
  add(query_402656670, "TargetOptionGroupDescription",
      newJString(TargetOptionGroupDescription))
  result = call_402656669.call(nil, query_402656670, nil, nil, nil)

var getCopyOptionGroup* = Call_GetCopyOptionGroup_402656652(
    name: "getCopyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CopyOptionGroup",
    validator: validate_GetCopyOptionGroup_402656653, base: "/",
    makeUrl: url_GetCopyOptionGroup_402656654,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_402656734 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstance_402656736(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_402656735(path: JsonNode; query: JsonNode;
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
  var valid_402656737 = query.getOrDefault("Version")
  valid_402656737 = validateParameter(valid_402656737, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656737 != nil:
    section.add "Version", valid_402656737
  var valid_402656738 = query.getOrDefault("Action")
  valid_402656738 = validateParameter(valid_402656738, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656738 != nil:
    section.add "Action", valid_402656738
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
  var valid_402656739 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-Security-Token", valid_402656739
  var valid_402656740 = header.getOrDefault("X-Amz-Signature")
  valid_402656740 = validateParameter(valid_402656740, JString,
                                      required = false, default = nil)
  if valid_402656740 != nil:
    section.add "X-Amz-Signature", valid_402656740
  var valid_402656741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656741 = validateParameter(valid_402656741, JString,
                                      required = false, default = nil)
  if valid_402656741 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656741
  var valid_402656742 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Algorithm", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Date")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Date", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Credential")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Credential", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656745
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   TdeCredentialArn: JString
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
  ##   TdeCredentialPassword: JString
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: JString
  ##   StorageType: JString
  ##   EngineVersion: JString
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402656746 = formData.getOrDefault("PreferredBackupWindow")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "PreferredBackupWindow", valid_402656746
  var valid_402656747 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656747 = validateParameter(valid_402656747, JBool, required = false,
                                      default = nil)
  if valid_402656747 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656747
  var valid_402656748 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402656748 = validateParameter(valid_402656748, JArray, required = false,
                                      default = nil)
  if valid_402656748 != nil:
    section.add "VpcSecurityGroupIds", valid_402656748
  var valid_402656749 = formData.getOrDefault("TdeCredentialArn")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "TdeCredentialArn", valid_402656749
  var valid_402656750 = formData.getOrDefault("Port")
  valid_402656750 = validateParameter(valid_402656750, JInt, required = false,
                                      default = nil)
  if valid_402656750 != nil:
    section.add "Port", valid_402656750
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402656751 = formData.getOrDefault("Engine")
  valid_402656751 = validateParameter(valid_402656751, JString, required = true,
                                      default = nil)
  if valid_402656751 != nil:
    section.add "Engine", valid_402656751
  var valid_402656752 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "DBSubnetGroupName", valid_402656752
  var valid_402656753 = formData.getOrDefault("AllocatedStorage")
  valid_402656753 = validateParameter(valid_402656753, JInt, required = true,
                                      default = nil)
  if valid_402656753 != nil:
    section.add "AllocatedStorage", valid_402656753
  var valid_402656754 = formData.getOrDefault("PubliclyAccessible")
  valid_402656754 = validateParameter(valid_402656754, JBool, required = false,
                                      default = nil)
  if valid_402656754 != nil:
    section.add "PubliclyAccessible", valid_402656754
  var valid_402656755 = formData.getOrDefault("AvailabilityZone")
  valid_402656755 = validateParameter(valid_402656755, JString,
                                      required = false, default = nil)
  if valid_402656755 != nil:
    section.add "AvailabilityZone", valid_402656755
  var valid_402656756 = formData.getOrDefault("MasterUserPassword")
  valid_402656756 = validateParameter(valid_402656756, JString, required = true,
                                      default = nil)
  if valid_402656756 != nil:
    section.add "MasterUserPassword", valid_402656756
  var valid_402656757 = formData.getOrDefault("CharacterSetName")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "CharacterSetName", valid_402656757
  var valid_402656758 = formData.getOrDefault("DBName")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "DBName", valid_402656758
  var valid_402656759 = formData.getOrDefault("Tags")
  valid_402656759 = validateParameter(valid_402656759, JArray, required = false,
                                      default = nil)
  if valid_402656759 != nil:
    section.add "Tags", valid_402656759
  var valid_402656760 = formData.getOrDefault("DBParameterGroupName")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "DBParameterGroupName", valid_402656760
  var valid_402656761 = formData.getOrDefault("Iops")
  valid_402656761 = validateParameter(valid_402656761, JInt, required = false,
                                      default = nil)
  if valid_402656761 != nil:
    section.add "Iops", valid_402656761
  var valid_402656762 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656762
  var valid_402656763 = formData.getOrDefault("DBInstanceClass")
  valid_402656763 = validateParameter(valid_402656763, JString, required = true,
                                      default = nil)
  if valid_402656763 != nil:
    section.add "DBInstanceClass", valid_402656763
  var valid_402656764 = formData.getOrDefault("LicenseModel")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "LicenseModel", valid_402656764
  var valid_402656765 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656765 = validateParameter(valid_402656765, JString, required = true,
                                      default = nil)
  if valid_402656765 != nil:
    section.add "DBInstanceIdentifier", valid_402656765
  var valid_402656766 = formData.getOrDefault("MasterUsername")
  valid_402656766 = validateParameter(valid_402656766, JString, required = true,
                                      default = nil)
  if valid_402656766 != nil:
    section.add "MasterUsername", valid_402656766
  var valid_402656767 = formData.getOrDefault("TdeCredentialPassword")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "TdeCredentialPassword", valid_402656767
  var valid_402656768 = formData.getOrDefault("MultiAZ")
  valid_402656768 = validateParameter(valid_402656768, JBool, required = false,
                                      default = nil)
  if valid_402656768 != nil:
    section.add "MultiAZ", valid_402656768
  var valid_402656769 = formData.getOrDefault("DBSecurityGroups")
  valid_402656769 = validateParameter(valid_402656769, JArray, required = false,
                                      default = nil)
  if valid_402656769 != nil:
    section.add "DBSecurityGroups", valid_402656769
  var valid_402656770 = formData.getOrDefault("OptionGroupName")
  valid_402656770 = validateParameter(valid_402656770, JString,
                                      required = false, default = nil)
  if valid_402656770 != nil:
    section.add "OptionGroupName", valid_402656770
  var valid_402656771 = formData.getOrDefault("StorageType")
  valid_402656771 = validateParameter(valid_402656771, JString,
                                      required = false, default = nil)
  if valid_402656771 != nil:
    section.add "StorageType", valid_402656771
  var valid_402656772 = formData.getOrDefault("EngineVersion")
  valid_402656772 = validateParameter(valid_402656772, JString,
                                      required = false, default = nil)
  if valid_402656772 != nil:
    section.add "EngineVersion", valid_402656772
  var valid_402656773 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402656773 = validateParameter(valid_402656773, JInt, required = false,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "BackupRetentionPeriod", valid_402656773
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656774: Call_PostCreateDBInstance_402656734;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656774.validator(path, query, header, formData, body, _)
  let scheme = call_402656774.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656774.makeUrl(scheme.get, call_402656774.host, call_402656774.base,
                                   call_402656774.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656774, uri, valid, _)

proc call*(call_402656775: Call_PostCreateDBInstance_402656734; Engine: string;
           AllocatedStorage: int; MasterUserPassword: string;
           DBInstanceClass: string; DBInstanceIdentifier: string;
           MasterUsername: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; TdeCredentialArn: string = "";
           Port: int = 0; DBSubnetGroupName: string = "";
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           CharacterSetName: string = ""; DBName: string = "";
           Tags: JsonNode = nil; Version: string = "2014-09-01";
           DBParameterGroupName: string = ""; Iops: int = 0;
           PreferredMaintenanceWindow: string = ""; LicenseModel: string = "";
           TdeCredentialPassword: string = ""; MultiAZ: bool = false;
           DBSecurityGroups: JsonNode = nil; OptionGroupName: string = "";
           Action: string = "CreateDBInstance"; StorageType: string = "";
           EngineVersion: string = ""; BackupRetentionPeriod: int = 0): Recallable =
  ## postCreateDBInstance
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   VpcSecurityGroupIds: JArray
  ##   TdeCredentialArn: string
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
  ##   TdeCredentialPassword: string
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   StorageType: string
  ##   EngineVersion: string
  ##   BackupRetentionPeriod: int
  var query_402656776 = newJObject()
  var formData_402656777 = newJObject()
  add(formData_402656777, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402656777, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402656777.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402656777, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_402656777, "Port", newJInt(Port))
  add(formData_402656777, "Engine", newJString(Engine))
  add(formData_402656777, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402656777, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402656777, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656777, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402656777, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402656777, "CharacterSetName", newJString(CharacterSetName))
  add(formData_402656777, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402656777.add "Tags", Tags
  add(query_402656776, "Version", newJString(Version))
  add(formData_402656777, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402656777, "Iops", newJInt(Iops))
  add(formData_402656777, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402656777, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656777, "LicenseModel", newJString(LicenseModel))
  add(formData_402656777, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656777, "MasterUsername", newJString(MasterUsername))
  add(formData_402656777, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_402656777, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402656777.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402656777, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656776, "Action", newJString(Action))
  add(formData_402656777, "StorageType", newJString(StorageType))
  add(formData_402656777, "EngineVersion", newJString(EngineVersion))
  add(formData_402656777, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402656775.call(nil, query_402656776, nil, formData_402656777,
                               nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_402656734(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_402656735, base: "/",
    makeUrl: url_PostCreateDBInstance_402656736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_402656691 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstance_402656693(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_402656692(path: JsonNode; query: JsonNode;
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
  ##   TdeCredentialPassword: JString
  ##   MasterUserPassword: JString (required)
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   StorageType: JString
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
  ##   TdeCredentialArn: JString
  ##   Action: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBSecurityGroups: JArray
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402656694 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402656694 = validateParameter(valid_402656694, JArray, required = false,
                                      default = nil)
  if valid_402656694 != nil:
    section.add "VpcSecurityGroupIds", valid_402656694
  var valid_402656695 = query.getOrDefault("PubliclyAccessible")
  valid_402656695 = validateParameter(valid_402656695, JBool, required = false,
                                      default = nil)
  if valid_402656695 != nil:
    section.add "PubliclyAccessible", valid_402656695
  var valid_402656696 = query.getOrDefault("OptionGroupName")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "OptionGroupName", valid_402656696
  var valid_402656697 = query.getOrDefault("PreferredBackupWindow")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "PreferredBackupWindow", valid_402656697
  var valid_402656698 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402656698 = validateParameter(valid_402656698, JString,
                                      required = false, default = nil)
  if valid_402656698 != nil:
    section.add "PreferredMaintenanceWindow", valid_402656698
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
  var valid_402656701 = query.getOrDefault("DBParameterGroupName")
  valid_402656701 = validateParameter(valid_402656701, JString,
                                      required = false, default = nil)
  if valid_402656701 != nil:
    section.add "DBParameterGroupName", valid_402656701
  var valid_402656702 = query.getOrDefault("TdeCredentialPassword")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "TdeCredentialPassword", valid_402656702
  var valid_402656703 = query.getOrDefault("MasterUserPassword")
  valid_402656703 = validateParameter(valid_402656703, JString, required = true,
                                      default = nil)
  if valid_402656703 != nil:
    section.add "MasterUserPassword", valid_402656703
  var valid_402656704 = query.getOrDefault("Iops")
  valid_402656704 = validateParameter(valid_402656704, JInt, required = false,
                                      default = nil)
  if valid_402656704 != nil:
    section.add "Iops", valid_402656704
  var valid_402656705 = query.getOrDefault("AvailabilityZone")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "AvailabilityZone", valid_402656705
  var valid_402656706 = query.getOrDefault("StorageType")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "StorageType", valid_402656706
  var valid_402656707 = query.getOrDefault("MultiAZ")
  valid_402656707 = validateParameter(valid_402656707, JBool, required = false,
                                      default = nil)
  if valid_402656707 != nil:
    section.add "MultiAZ", valid_402656707
  var valid_402656708 = query.getOrDefault("Version")
  valid_402656708 = validateParameter(valid_402656708, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656708 != nil:
    section.add "Version", valid_402656708
  var valid_402656709 = query.getOrDefault("EngineVersion")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "EngineVersion", valid_402656709
  var valid_402656710 = query.getOrDefault("Tags")
  valid_402656710 = validateParameter(valid_402656710, JArray, required = false,
                                      default = nil)
  if valid_402656710 != nil:
    section.add "Tags", valid_402656710
  var valid_402656711 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656711 = validateParameter(valid_402656711, JBool, required = false,
                                      default = nil)
  if valid_402656711 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656711
  var valid_402656712 = query.getOrDefault("DBName")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "DBName", valid_402656712
  var valid_402656713 = query.getOrDefault("AllocatedStorage")
  valid_402656713 = validateParameter(valid_402656713, JInt, required = true,
                                      default = nil)
  if valid_402656713 != nil:
    section.add "AllocatedStorage", valid_402656713
  var valid_402656714 = query.getOrDefault("MasterUsername")
  valid_402656714 = validateParameter(valid_402656714, JString, required = true,
                                      default = nil)
  if valid_402656714 != nil:
    section.add "MasterUsername", valid_402656714
  var valid_402656715 = query.getOrDefault("DBInstanceClass")
  valid_402656715 = validateParameter(valid_402656715, JString, required = true,
                                      default = nil)
  if valid_402656715 != nil:
    section.add "DBInstanceClass", valid_402656715
  var valid_402656716 = query.getOrDefault("Engine")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "Engine", valid_402656716
  var valid_402656717 = query.getOrDefault("Port")
  valid_402656717 = validateParameter(valid_402656717, JInt, required = false,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "Port", valid_402656717
  var valid_402656718 = query.getOrDefault("CharacterSetName")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "CharacterSetName", valid_402656718
  var valid_402656719 = query.getOrDefault("TdeCredentialArn")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "TdeCredentialArn", valid_402656719
  var valid_402656720 = query.getOrDefault("Action")
  valid_402656720 = validateParameter(valid_402656720, JString, required = true,
                                      default = newJString("CreateDBInstance"))
  if valid_402656720 != nil:
    section.add "Action", valid_402656720
  var valid_402656721 = query.getOrDefault("BackupRetentionPeriod")
  valid_402656721 = validateParameter(valid_402656721, JInt, required = false,
                                      default = nil)
  if valid_402656721 != nil:
    section.add "BackupRetentionPeriod", valid_402656721
  var valid_402656722 = query.getOrDefault("DBSecurityGroups")
  valid_402656722 = validateParameter(valid_402656722, JArray, required = false,
                                      default = nil)
  if valid_402656722 != nil:
    section.add "DBSecurityGroups", valid_402656722
  var valid_402656723 = query.getOrDefault("LicenseModel")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "LicenseModel", valid_402656723
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
  var valid_402656724 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-Security-Token", valid_402656724
  var valid_402656725 = header.getOrDefault("X-Amz-Signature")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Signature", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Algorithm", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Date")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Date", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Credential")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Credential", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656731: Call_GetCreateDBInstance_402656691;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656731.validator(path, query, header, formData, body, _)
  let scheme = call_402656731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656731.makeUrl(scheme.get, call_402656731.host, call_402656731.base,
                                   call_402656731.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656731, uri, valid, _)

proc call*(call_402656732: Call_GetCreateDBInstance_402656691;
           DBInstanceIdentifier: string; MasterUserPassword: string;
           AllocatedStorage: int; MasterUsername: string;
           DBInstanceClass: string; Engine: string;
           VpcSecurityGroupIds: JsonNode = nil;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBSubnetGroupName: string = ""; DBParameterGroupName: string = "";
           TdeCredentialPassword: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; StorageType: string = "";
           MultiAZ: bool = false; Version: string = "2014-09-01";
           EngineVersion: string = ""; Tags: JsonNode = nil;
           AutoMinorVersionUpgrade: bool = false; DBName: string = "";
           Port: int = 0; CharacterSetName: string = "";
           TdeCredentialArn: string = ""; Action: string = "CreateDBInstance";
           BackupRetentionPeriod: int = 0; DBSecurityGroups: JsonNode = nil;
           LicenseModel: string = ""): Recallable =
  ## getCreateDBInstance
  ##   VpcSecurityGroupIds: JArray
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   DBParameterGroupName: string
  ##   TdeCredentialPassword: string
  ##   MasterUserPassword: string (required)
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   StorageType: string
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
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBSecurityGroups: JArray
  ##   LicenseModel: string
  var query_402656733 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402656733.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402656733, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656733, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656733, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402656733, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402656733, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656733, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656733, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656733, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(query_402656733, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402656733, "Iops", newJInt(Iops))
  add(query_402656733, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656733, "StorageType", newJString(StorageType))
  add(query_402656733, "MultiAZ", newJBool(MultiAZ))
  add(query_402656733, "Version", newJString(Version))
  add(query_402656733, "EngineVersion", newJString(EngineVersion))
  if Tags != nil:
    query_402656733.add "Tags", Tags
  add(query_402656733, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656733, "DBName", newJString(DBName))
  add(query_402656733, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402656733, "MasterUsername", newJString(MasterUsername))
  add(query_402656733, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656733, "Engine", newJString(Engine))
  add(query_402656733, "Port", newJInt(Port))
  add(query_402656733, "CharacterSetName", newJString(CharacterSetName))
  add(query_402656733, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_402656733, "Action", newJString(Action))
  add(query_402656733, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402656733.add "DBSecurityGroups", DBSecurityGroups
  add(query_402656733, "LicenseModel", newJString(LicenseModel))
  result = call_402656732.call(nil, query_402656733, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_402656691(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_402656692, base: "/",
    makeUrl: url_GetCreateDBInstance_402656693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_402656805 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBInstanceReadReplica_402656807(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_402656806(path: JsonNode;
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
  var valid_402656808 = query.getOrDefault("Version")
  valid_402656808 = validateParameter(valid_402656808, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656808 != nil:
    section.add "Version", valid_402656808
  var valid_402656809 = query.getOrDefault("Action")
  valid_402656809 = validateParameter(valid_402656809, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656809 != nil:
    section.add "Action", valid_402656809
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
  var valid_402656810 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Security-Token", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Signature")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Signature", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Algorithm", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-Date")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-Date", valid_402656814
  var valid_402656815 = header.getOrDefault("X-Amz-Credential")
  valid_402656815 = validateParameter(valid_402656815, JString,
                                      required = false, default = nil)
  if valid_402656815 != nil:
    section.add "X-Amz-Credential", valid_402656815
  var valid_402656816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656816 = validateParameter(valid_402656816, JString,
                                      required = false, default = nil)
  if valid_402656816 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656816
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
  ##   StorageType: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402656817 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656817 = validateParameter(valid_402656817, JBool, required = false,
                                      default = nil)
  if valid_402656817 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656817
  var valid_402656818 = formData.getOrDefault("Port")
  valid_402656818 = validateParameter(valid_402656818, JInt, required = false,
                                      default = nil)
  if valid_402656818 != nil:
    section.add "Port", valid_402656818
  var valid_402656819 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656819 = validateParameter(valid_402656819, JString,
                                      required = false, default = nil)
  if valid_402656819 != nil:
    section.add "DBSubnetGroupName", valid_402656819
  var valid_402656820 = formData.getOrDefault("PubliclyAccessible")
  valid_402656820 = validateParameter(valid_402656820, JBool, required = false,
                                      default = nil)
  if valid_402656820 != nil:
    section.add "PubliclyAccessible", valid_402656820
  var valid_402656821 = formData.getOrDefault("AvailabilityZone")
  valid_402656821 = validateParameter(valid_402656821, JString,
                                      required = false, default = nil)
  if valid_402656821 != nil:
    section.add "AvailabilityZone", valid_402656821
  var valid_402656822 = formData.getOrDefault("Tags")
  valid_402656822 = validateParameter(valid_402656822, JArray, required = false,
                                      default = nil)
  if valid_402656822 != nil:
    section.add "Tags", valid_402656822
  var valid_402656823 = formData.getOrDefault("Iops")
  valid_402656823 = validateParameter(valid_402656823, JInt, required = false,
                                      default = nil)
  if valid_402656823 != nil:
    section.add "Iops", valid_402656823
  var valid_402656824 = formData.getOrDefault("DBInstanceClass")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "DBInstanceClass", valid_402656824
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656825 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656825 = validateParameter(valid_402656825, JString, required = true,
                                      default = nil)
  if valid_402656825 != nil:
    section.add "DBInstanceIdentifier", valid_402656825
  var valid_402656826 = formData.getOrDefault("OptionGroupName")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "OptionGroupName", valid_402656826
  var valid_402656827 = formData.getOrDefault("StorageType")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "StorageType", valid_402656827
  var valid_402656828 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656828 = validateParameter(valid_402656828, JString, required = true,
                                      default = nil)
  if valid_402656828 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656828
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656829: Call_PostCreateDBInstanceReadReplica_402656805;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656829.validator(path, query, header, formData, body, _)
  let scheme = call_402656829.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656829.makeUrl(scheme.get, call_402656829.host, call_402656829.base,
                                   call_402656829.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656829, uri, valid, _)

proc call*(call_402656830: Call_PostCreateDBInstanceReadReplica_402656805;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; Port: int = 0;
           DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
           AvailabilityZone: string = ""; Tags: JsonNode = nil;
           Version: string = "2014-09-01"; Iops: int = 0;
           DBInstanceClass: string = ""; OptionGroupName: string = "";
           Action: string = "CreateDBInstanceReadReplica";
           StorageType: string = ""): Recallable =
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
  ##   StorageType: string
  ##   SourceDBInstanceIdentifier: string (required)
  var query_402656831 = newJObject()
  var formData_402656832 = newJObject()
  add(formData_402656832, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402656832, "Port", newJInt(Port))
  add(formData_402656832, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402656832, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402656832, "AvailabilityZone", newJString(AvailabilityZone))
  if Tags != nil:
    formData_402656832.add "Tags", Tags
  add(query_402656831, "Version", newJString(Version))
  add(formData_402656832, "Iops", newJInt(Iops))
  add(formData_402656832, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402656832, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656832, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656831, "Action", newJString(Action))
  add(formData_402656832, "StorageType", newJString(StorageType))
  add(formData_402656832, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402656830.call(nil, query_402656831, nil, formData_402656832,
                               nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_402656805(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_402656806, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_402656807,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_402656778 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBInstanceReadReplica_402656780(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_402656779(path: JsonNode;
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
  ##   StorageType: JString
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: JBool
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   Port: JInt
  ##   Action: JString (required)
  section = newJObject()
  var valid_402656781 = query.getOrDefault("PubliclyAccessible")
  valid_402656781 = validateParameter(valid_402656781, JBool, required = false,
                                      default = nil)
  if valid_402656781 != nil:
    section.add "PubliclyAccessible", valid_402656781
  var valid_402656782 = query.getOrDefault("OptionGroupName")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "OptionGroupName", valid_402656782
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656783 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656783 = validateParameter(valid_402656783, JString, required = true,
                                      default = nil)
  if valid_402656783 != nil:
    section.add "DBInstanceIdentifier", valid_402656783
  var valid_402656784 = query.getOrDefault("DBSubnetGroupName")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "DBSubnetGroupName", valid_402656784
  var valid_402656785 = query.getOrDefault("Iops")
  valid_402656785 = validateParameter(valid_402656785, JInt, required = false,
                                      default = nil)
  if valid_402656785 != nil:
    section.add "Iops", valid_402656785
  var valid_402656786 = query.getOrDefault("AvailabilityZone")
  valid_402656786 = validateParameter(valid_402656786, JString,
                                      required = false, default = nil)
  if valid_402656786 != nil:
    section.add "AvailabilityZone", valid_402656786
  var valid_402656787 = query.getOrDefault("StorageType")
  valid_402656787 = validateParameter(valid_402656787, JString,
                                      required = false, default = nil)
  if valid_402656787 != nil:
    section.add "StorageType", valid_402656787
  var valid_402656788 = query.getOrDefault("Version")
  valid_402656788 = validateParameter(valid_402656788, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656788 != nil:
    section.add "Version", valid_402656788
  var valid_402656789 = query.getOrDefault("Tags")
  valid_402656789 = validateParameter(valid_402656789, JArray, required = false,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "Tags", valid_402656789
  var valid_402656790 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402656790 = validateParameter(valid_402656790, JBool, required = false,
                                      default = nil)
  if valid_402656790 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402656790
  var valid_402656791 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402656791 = validateParameter(valid_402656791, JString, required = true,
                                      default = nil)
  if valid_402656791 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402656791
  var valid_402656792 = query.getOrDefault("DBInstanceClass")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "DBInstanceClass", valid_402656792
  var valid_402656793 = query.getOrDefault("Port")
  valid_402656793 = validateParameter(valid_402656793, JInt, required = false,
                                      default = nil)
  if valid_402656793 != nil:
    section.add "Port", valid_402656793
  var valid_402656794 = query.getOrDefault("Action")
  valid_402656794 = validateParameter(valid_402656794, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_402656794 != nil:
    section.add "Action", valid_402656794
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
  var valid_402656795 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Security-Token", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Signature")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Signature", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Algorithm", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-Date")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-Date", valid_402656799
  var valid_402656800 = header.getOrDefault("X-Amz-Credential")
  valid_402656800 = validateParameter(valid_402656800, JString,
                                      required = false, default = nil)
  if valid_402656800 != nil:
    section.add "X-Amz-Credential", valid_402656800
  var valid_402656801 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656801 = validateParameter(valid_402656801, JString,
                                      required = false, default = nil)
  if valid_402656801 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656801
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656802: Call_GetCreateDBInstanceReadReplica_402656778;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656802.validator(path, query, header, formData, body, _)
  let scheme = call_402656802.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656802.makeUrl(scheme.get, call_402656802.host, call_402656802.base,
                                   call_402656802.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656802, uri, valid, _)

proc call*(call_402656803: Call_GetCreateDBInstanceReadReplica_402656778;
           DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           DBSubnetGroupName: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; StorageType: string = "";
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           AutoMinorVersionUpgrade: bool = false; DBInstanceClass: string = "";
           Port: int = 0; Action: string = "CreateDBInstanceReadReplica"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   StorageType: string
  ##   Version: string (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: bool
  ##   SourceDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   Port: int
  ##   Action: string (required)
  var query_402656804 = newJObject()
  add(query_402656804, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402656804, "OptionGroupName", newJString(OptionGroupName))
  add(query_402656804, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656804, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656804, "Iops", newJInt(Iops))
  add(query_402656804, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402656804, "StorageType", newJString(StorageType))
  add(query_402656804, "Version", newJString(Version))
  if Tags != nil:
    query_402656804.add "Tags", Tags
  add(query_402656804, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402656804, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402656804, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402656804, "Port", newJInt(Port))
  add(query_402656804, "Action", newJString(Action))
  result = call_402656803.call(nil, query_402656804, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_402656778(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_402656779, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_402656780,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_402656852 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBParameterGroup_402656854(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_402656853(path: JsonNode;
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
  var valid_402656855 = query.getOrDefault("Version")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656855 != nil:
    section.add "Version", valid_402656855
  var valid_402656856 = query.getOrDefault("Action")
  valid_402656856 = validateParameter(valid_402656856, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656856 != nil:
    section.add "Action", valid_402656856
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
  var valid_402656857 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Security-Token", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Signature")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Signature", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Algorithm", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Date")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Date", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-Credential")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-Credential", valid_402656862
  var valid_402656863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656863 = validateParameter(valid_402656863, JString,
                                      required = false, default = nil)
  if valid_402656863 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656863
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupFamily: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402656864 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402656864 = validateParameter(valid_402656864, JString, required = true,
                                      default = nil)
  if valid_402656864 != nil:
    section.add "DBParameterGroupFamily", valid_402656864
  var valid_402656865 = formData.getOrDefault("Tags")
  valid_402656865 = validateParameter(valid_402656865, JArray, required = false,
                                      default = nil)
  if valid_402656865 != nil:
    section.add "Tags", valid_402656865
  var valid_402656866 = formData.getOrDefault("DBParameterGroupName")
  valid_402656866 = validateParameter(valid_402656866, JString, required = true,
                                      default = nil)
  if valid_402656866 != nil:
    section.add "DBParameterGroupName", valid_402656866
  var valid_402656867 = formData.getOrDefault("Description")
  valid_402656867 = validateParameter(valid_402656867, JString, required = true,
                                      default = nil)
  if valid_402656867 != nil:
    section.add "Description", valid_402656867
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656868: Call_PostCreateDBParameterGroup_402656852;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656868.validator(path, query, header, formData, body, _)
  let scheme = call_402656868.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656868.makeUrl(scheme.get, call_402656868.host, call_402656868.base,
                                   call_402656868.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656868, uri, valid, _)

proc call*(call_402656869: Call_PostCreateDBParameterGroup_402656852;
           DBParameterGroupFamily: string; DBParameterGroupName: string;
           Description: string; Tags: JsonNode = nil;
           Version: string = "2014-09-01";
           Action: string = "CreateDBParameterGroup"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Description: string (required)
  var query_402656870 = newJObject()
  var formData_402656871 = newJObject()
  add(formData_402656871, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Tags != nil:
    formData_402656871.add "Tags", Tags
  add(query_402656870, "Version", newJString(Version))
  add(formData_402656871, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402656870, "Action", newJString(Action))
  add(formData_402656871, "Description", newJString(Description))
  result = call_402656869.call(nil, query_402656870, nil, formData_402656871,
                               nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_402656852(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_402656853, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_402656854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_402656833 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBParameterGroup_402656835(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_402656834(path: JsonNode;
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
  var valid_402656836 = query.getOrDefault("Description")
  valid_402656836 = validateParameter(valid_402656836, JString, required = true,
                                      default = nil)
  if valid_402656836 != nil:
    section.add "Description", valid_402656836
  var valid_402656837 = query.getOrDefault("DBParameterGroupName")
  valid_402656837 = validateParameter(valid_402656837, JString, required = true,
                                      default = nil)
  if valid_402656837 != nil:
    section.add "DBParameterGroupName", valid_402656837
  var valid_402656838 = query.getOrDefault("DBParameterGroupFamily")
  valid_402656838 = validateParameter(valid_402656838, JString, required = true,
                                      default = nil)
  if valid_402656838 != nil:
    section.add "DBParameterGroupFamily", valid_402656838
  var valid_402656839 = query.getOrDefault("Version")
  valid_402656839 = validateParameter(valid_402656839, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656839 != nil:
    section.add "Version", valid_402656839
  var valid_402656840 = query.getOrDefault("Tags")
  valid_402656840 = validateParameter(valid_402656840, JArray, required = false,
                                      default = nil)
  if valid_402656840 != nil:
    section.add "Tags", valid_402656840
  var valid_402656841 = query.getOrDefault("Action")
  valid_402656841 = validateParameter(valid_402656841, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_402656841 != nil:
    section.add "Action", valid_402656841
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
  var valid_402656842 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Security-Token", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Signature")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Signature", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Algorithm", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-Date")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-Date", valid_402656846
  var valid_402656847 = header.getOrDefault("X-Amz-Credential")
  valid_402656847 = validateParameter(valid_402656847, JString,
                                      required = false, default = nil)
  if valid_402656847 != nil:
    section.add "X-Amz-Credential", valid_402656847
  var valid_402656848 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656848 = validateParameter(valid_402656848, JString,
                                      required = false, default = nil)
  if valid_402656848 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656848
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656849: Call_GetCreateDBParameterGroup_402656833;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656849.validator(path, query, header, formData, body, _)
  let scheme = call_402656849.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656849.makeUrl(scheme.get, call_402656849.host, call_402656849.base,
                                   call_402656849.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656849, uri, valid, _)

proc call*(call_402656850: Call_GetCreateDBParameterGroup_402656833;
           Description: string; DBParameterGroupName: string;
           DBParameterGroupFamily: string; Version: string = "2014-09-01";
           Tags: JsonNode = nil; Action: string = "CreateDBParameterGroup"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupName: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  var query_402656851 = newJObject()
  add(query_402656851, "Description", newJString(Description))
  add(query_402656851, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402656851, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402656851, "Version", newJString(Version))
  if Tags != nil:
    query_402656851.add "Tags", Tags
  add(query_402656851, "Action", newJString(Action))
  result = call_402656850.call(nil, query_402656851, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_402656833(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_402656834, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_402656835,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_402656890 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSecurityGroup_402656892(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_402656891(path: JsonNode;
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
  var valid_402656893 = query.getOrDefault("Version")
  valid_402656893 = validateParameter(valid_402656893, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656893 != nil:
    section.add "Version", valid_402656893
  var valid_402656894 = query.getOrDefault("Action")
  valid_402656894 = validateParameter(valid_402656894, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656894 != nil:
    section.add "Action", valid_402656894
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
  var valid_402656895 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656895 = validateParameter(valid_402656895, JString,
                                      required = false, default = nil)
  if valid_402656895 != nil:
    section.add "X-Amz-Security-Token", valid_402656895
  var valid_402656896 = header.getOrDefault("X-Amz-Signature")
  valid_402656896 = validateParameter(valid_402656896, JString,
                                      required = false, default = nil)
  if valid_402656896 != nil:
    section.add "X-Amz-Signature", valid_402656896
  var valid_402656897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656897 = validateParameter(valid_402656897, JString,
                                      required = false, default = nil)
  if valid_402656897 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656897
  var valid_402656898 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656898 = validateParameter(valid_402656898, JString,
                                      required = false, default = nil)
  if valid_402656898 != nil:
    section.add "X-Amz-Algorithm", valid_402656898
  var valid_402656899 = header.getOrDefault("X-Amz-Date")
  valid_402656899 = validateParameter(valid_402656899, JString,
                                      required = false, default = nil)
  if valid_402656899 != nil:
    section.add "X-Amz-Date", valid_402656899
  var valid_402656900 = header.getOrDefault("X-Amz-Credential")
  valid_402656900 = validateParameter(valid_402656900, JString,
                                      required = false, default = nil)
  if valid_402656900 != nil:
    section.add "X-Amz-Credential", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656901
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupDescription: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupDescription` field"
  var valid_402656902 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_402656902 = validateParameter(valid_402656902, JString, required = true,
                                      default = nil)
  if valid_402656902 != nil:
    section.add "DBSecurityGroupDescription", valid_402656902
  var valid_402656903 = formData.getOrDefault("Tags")
  valid_402656903 = validateParameter(valid_402656903, JArray, required = false,
                                      default = nil)
  if valid_402656903 != nil:
    section.add "Tags", valid_402656903
  var valid_402656904 = formData.getOrDefault("DBSecurityGroupName")
  valid_402656904 = validateParameter(valid_402656904, JString, required = true,
                                      default = nil)
  if valid_402656904 != nil:
    section.add "DBSecurityGroupName", valid_402656904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656905: Call_PostCreateDBSecurityGroup_402656890;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656905.validator(path, query, header, formData, body, _)
  let scheme = call_402656905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656905.makeUrl(scheme.get, call_402656905.host, call_402656905.base,
                                   call_402656905.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656905, uri, valid, _)

proc call*(call_402656906: Call_PostCreateDBSecurityGroup_402656890;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Tags: JsonNode = nil; Version: string = "2014-09-01";
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402656907 = newJObject()
  var formData_402656908 = newJObject()
  add(formData_402656908, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    formData_402656908.add "Tags", Tags
  add(query_402656907, "Version", newJString(Version))
  add(formData_402656908, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402656907, "Action", newJString(Action))
  result = call_402656906.call(nil, query_402656907, nil, formData_402656908,
                               nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_402656890(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_402656891, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_402656892,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_402656872 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSecurityGroup_402656874(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_402656873(path: JsonNode;
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
  var valid_402656875 = query.getOrDefault("DBSecurityGroupDescription")
  valid_402656875 = validateParameter(valid_402656875, JString, required = true,
                                      default = nil)
  if valid_402656875 != nil:
    section.add "DBSecurityGroupDescription", valid_402656875
  var valid_402656876 = query.getOrDefault("Version")
  valid_402656876 = validateParameter(valid_402656876, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656876 != nil:
    section.add "Version", valid_402656876
  var valid_402656877 = query.getOrDefault("Tags")
  valid_402656877 = validateParameter(valid_402656877, JArray, required = false,
                                      default = nil)
  if valid_402656877 != nil:
    section.add "Tags", valid_402656877
  var valid_402656878 = query.getOrDefault("Action")
  valid_402656878 = validateParameter(valid_402656878, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_402656878 != nil:
    section.add "Action", valid_402656878
  var valid_402656879 = query.getOrDefault("DBSecurityGroupName")
  valid_402656879 = validateParameter(valid_402656879, JString, required = true,
                                      default = nil)
  if valid_402656879 != nil:
    section.add "DBSecurityGroupName", valid_402656879
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
  var valid_402656880 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656880 = validateParameter(valid_402656880, JString,
                                      required = false, default = nil)
  if valid_402656880 != nil:
    section.add "X-Amz-Security-Token", valid_402656880
  var valid_402656881 = header.getOrDefault("X-Amz-Signature")
  valid_402656881 = validateParameter(valid_402656881, JString,
                                      required = false, default = nil)
  if valid_402656881 != nil:
    section.add "X-Amz-Signature", valid_402656881
  var valid_402656882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656882 = validateParameter(valid_402656882, JString,
                                      required = false, default = nil)
  if valid_402656882 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656882
  var valid_402656883 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656883 = validateParameter(valid_402656883, JString,
                                      required = false, default = nil)
  if valid_402656883 != nil:
    section.add "X-Amz-Algorithm", valid_402656883
  var valid_402656884 = header.getOrDefault("X-Amz-Date")
  valid_402656884 = validateParameter(valid_402656884, JString,
                                      required = false, default = nil)
  if valid_402656884 != nil:
    section.add "X-Amz-Date", valid_402656884
  var valid_402656885 = header.getOrDefault("X-Amz-Credential")
  valid_402656885 = validateParameter(valid_402656885, JString,
                                      required = false, default = nil)
  if valid_402656885 != nil:
    section.add "X-Amz-Credential", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656886
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656887: Call_GetCreateDBSecurityGroup_402656872;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656887.validator(path, query, header, formData, body, _)
  let scheme = call_402656887.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656887.makeUrl(scheme.get, call_402656887.host, call_402656887.base,
                                   call_402656887.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656887, uri, valid, _)

proc call*(call_402656888: Call_GetCreateDBSecurityGroup_402656872;
           DBSecurityGroupDescription: string; DBSecurityGroupName: string;
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           Action: string = "CreateDBSecurityGroup"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402656889 = newJObject()
  add(query_402656889, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_402656889, "Version", newJString(Version))
  if Tags != nil:
    query_402656889.add "Tags", Tags
  add(query_402656889, "Action", newJString(Action))
  add(query_402656889, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402656888.call(nil, query_402656889, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_402656872(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_402656873, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_402656874,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_402656927 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSnapshot_402656929(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_402656928(path: JsonNode; query: JsonNode;
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
  var valid_402656930 = query.getOrDefault("Version")
  valid_402656930 = validateParameter(valid_402656930, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656930 != nil:
    section.add "Version", valid_402656930
  var valid_402656931 = query.getOrDefault("Action")
  valid_402656931 = validateParameter(valid_402656931, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656931 != nil:
    section.add "Action", valid_402656931
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
  var valid_402656932 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Security-Token", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Signature")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Signature", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Algorithm", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Date")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Date", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-Credential")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-Credential", valid_402656937
  var valid_402656938 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656938 = validateParameter(valid_402656938, JString,
                                      required = false, default = nil)
  if valid_402656938 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656938
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_402656939 = formData.getOrDefault("Tags")
  valid_402656939 = validateParameter(valid_402656939, JArray, required = false,
                                      default = nil)
  if valid_402656939 != nil:
    section.add "Tags", valid_402656939
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402656940 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402656940 = validateParameter(valid_402656940, JString, required = true,
                                      default = nil)
  if valid_402656940 != nil:
    section.add "DBInstanceIdentifier", valid_402656940
  var valid_402656941 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402656941 = validateParameter(valid_402656941, JString, required = true,
                                      default = nil)
  if valid_402656941 != nil:
    section.add "DBSnapshotIdentifier", valid_402656941
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656942: Call_PostCreateDBSnapshot_402656927;
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

proc call*(call_402656943: Call_PostCreateDBSnapshot_402656927;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Tags: JsonNode = nil; Version: string = "2014-09-01";
           Action: string = "CreateDBSnapshot"): Recallable =
  ## postCreateDBSnapshot
  ##   Tags: JArray
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656944 = newJObject()
  var formData_402656945 = newJObject()
  if Tags != nil:
    formData_402656945.add "Tags", Tags
  add(query_402656944, "Version", newJString(Version))
  add(formData_402656945, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402656945, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402656944, "Action", newJString(Action))
  result = call_402656943.call(nil, query_402656944, nil, formData_402656945,
                               nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_402656927(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_402656928, base: "/",
    makeUrl: url_PostCreateDBSnapshot_402656929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_402656909 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSnapshot_402656911(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_402656910(path: JsonNode; query: JsonNode;
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
  var valid_402656912 = query.getOrDefault("DBInstanceIdentifier")
  valid_402656912 = validateParameter(valid_402656912, JString, required = true,
                                      default = nil)
  if valid_402656912 != nil:
    section.add "DBInstanceIdentifier", valid_402656912
  var valid_402656913 = query.getOrDefault("Version")
  valid_402656913 = validateParameter(valid_402656913, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656913 != nil:
    section.add "Version", valid_402656913
  var valid_402656914 = query.getOrDefault("Tags")
  valid_402656914 = validateParameter(valid_402656914, JArray, required = false,
                                      default = nil)
  if valid_402656914 != nil:
    section.add "Tags", valid_402656914
  var valid_402656915 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402656915 = validateParameter(valid_402656915, JString, required = true,
                                      default = nil)
  if valid_402656915 != nil:
    section.add "DBSnapshotIdentifier", valid_402656915
  var valid_402656916 = query.getOrDefault("Action")
  valid_402656916 = validateParameter(valid_402656916, JString, required = true,
                                      default = newJString("CreateDBSnapshot"))
  if valid_402656916 != nil:
    section.add "Action", valid_402656916
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
  var valid_402656917 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Security-Token", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Signature")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Signature", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Algorithm", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Date")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Date", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-Credential")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-Credential", valid_402656922
  var valid_402656923 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656923 = validateParameter(valid_402656923, JString,
                                      required = false, default = nil)
  if valid_402656923 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656923
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656924: Call_GetCreateDBSnapshot_402656909;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656924.validator(path, query, header, formData, body, _)
  let scheme = call_402656924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656924.makeUrl(scheme.get, call_402656924.host, call_402656924.base,
                                   call_402656924.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656924, uri, valid, _)

proc call*(call_402656925: Call_GetCreateDBSnapshot_402656909;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           Action: string = "CreateDBSnapshot"): Recallable =
  ## getCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402656926 = newJObject()
  add(query_402656926, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402656926, "Version", newJString(Version))
  if Tags != nil:
    query_402656926.add "Tags", Tags
  add(query_402656926, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402656926, "Action", newJString(Action))
  result = call_402656925.call(nil, query_402656926, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_402656909(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_402656910, base: "/",
    makeUrl: url_GetCreateDBSnapshot_402656911,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_402656965 = ref object of OpenApiRestCall_402656035
proc url_PostCreateDBSubnetGroup_402656967(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_402656966(path: JsonNode; query: JsonNode;
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
  var valid_402656968 = query.getOrDefault("Version")
  valid_402656968 = validateParameter(valid_402656968, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656968 != nil:
    section.add "Version", valid_402656968
  var valid_402656969 = query.getOrDefault("Action")
  valid_402656969 = validateParameter(valid_402656969, JString, required = true, default = newJString(
      "CreateDBSubnetGroup"))
  if valid_402656969 != nil:
    section.add "Action", valid_402656969
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
  var valid_402656970 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656970 = validateParameter(valid_402656970, JString,
                                      required = false, default = nil)
  if valid_402656970 != nil:
    section.add "X-Amz-Security-Token", valid_402656970
  var valid_402656971 = header.getOrDefault("X-Amz-Signature")
  valid_402656971 = validateParameter(valid_402656971, JString,
                                      required = false, default = nil)
  if valid_402656971 != nil:
    section.add "X-Amz-Signature", valid_402656971
  var valid_402656972 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656972 = validateParameter(valid_402656972, JString,
                                      required = false, default = nil)
  if valid_402656972 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656972
  var valid_402656973 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656973 = validateParameter(valid_402656973, JString,
                                      required = false, default = nil)
  if valid_402656973 != nil:
    section.add "X-Amz-Algorithm", valid_402656973
  var valid_402656974 = header.getOrDefault("X-Amz-Date")
  valid_402656974 = validateParameter(valid_402656974, JString,
                                      required = false, default = nil)
  if valid_402656974 != nil:
    section.add "X-Amz-Date", valid_402656974
  var valid_402656975 = header.getOrDefault("X-Amz-Credential")
  valid_402656975 = validateParameter(valid_402656975, JString,
                                      required = false, default = nil)
  if valid_402656975 != nil:
    section.add "X-Amz-Credential", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656976
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402656977 = formData.getOrDefault("DBSubnetGroupName")
  valid_402656977 = validateParameter(valid_402656977, JString, required = true,
                                      default = nil)
  if valid_402656977 != nil:
    section.add "DBSubnetGroupName", valid_402656977
  var valid_402656978 = formData.getOrDefault("Tags")
  valid_402656978 = validateParameter(valid_402656978, JArray, required = false,
                                      default = nil)
  if valid_402656978 != nil:
    section.add "Tags", valid_402656978
  var valid_402656979 = formData.getOrDefault("SubnetIds")
  valid_402656979 = validateParameter(valid_402656979, JArray, required = true,
                                      default = nil)
  if valid_402656979 != nil:
    section.add "SubnetIds", valid_402656979
  var valid_402656980 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402656980 = validateParameter(valid_402656980, JString, required = true,
                                      default = nil)
  if valid_402656980 != nil:
    section.add "DBSubnetGroupDescription", valid_402656980
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656981: Call_PostCreateDBSubnetGroup_402656965;
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

proc call*(call_402656982: Call_PostCreateDBSubnetGroup_402656965;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string; Tags: JsonNode = nil;
           Version: string = "2014-09-01";
           Action: string = "CreateDBSubnetGroup"): Recallable =
  ## postCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Action: string (required)
  var query_402656983 = newJObject()
  var formData_402656984 = newJObject()
  add(formData_402656984, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if Tags != nil:
    formData_402656984.add "Tags", Tags
  add(query_402656983, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402656984.add "SubnetIds", SubnetIds
  add(formData_402656984, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656983, "Action", newJString(Action))
  result = call_402656982.call(nil, query_402656983, nil, formData_402656984,
                               nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_402656965(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_402656966, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_402656967,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_402656946 = ref object of OpenApiRestCall_402656035
proc url_GetCreateDBSubnetGroup_402656948(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_402656947(path: JsonNode; query: JsonNode;
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
  var valid_402656949 = query.getOrDefault("DBSubnetGroupName")
  valid_402656949 = validateParameter(valid_402656949, JString, required = true,
                                      default = nil)
  if valid_402656949 != nil:
    section.add "DBSubnetGroupName", valid_402656949
  var valid_402656950 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402656950 = validateParameter(valid_402656950, JString, required = true,
                                      default = nil)
  if valid_402656950 != nil:
    section.add "DBSubnetGroupDescription", valid_402656950
  var valid_402656951 = query.getOrDefault("Version")
  valid_402656951 = validateParameter(valid_402656951, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656951 != nil:
    section.add "Version", valid_402656951
  var valid_402656952 = query.getOrDefault("Tags")
  valid_402656952 = validateParameter(valid_402656952, JArray, required = false,
                                      default = nil)
  if valid_402656952 != nil:
    section.add "Tags", valid_402656952
  var valid_402656953 = query.getOrDefault("SubnetIds")
  valid_402656953 = validateParameter(valid_402656953, JArray, required = true,
                                      default = nil)
  if valid_402656953 != nil:
    section.add "SubnetIds", valid_402656953
  var valid_402656954 = query.getOrDefault("Action")
  valid_402656954 = validateParameter(valid_402656954, JString, required = true, default = newJString(
      "CreateDBSubnetGroup"))
  if valid_402656954 != nil:
    section.add "Action", valid_402656954
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
  var valid_402656955 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656955 = validateParameter(valid_402656955, JString,
                                      required = false, default = nil)
  if valid_402656955 != nil:
    section.add "X-Amz-Security-Token", valid_402656955
  var valid_402656956 = header.getOrDefault("X-Amz-Signature")
  valid_402656956 = validateParameter(valid_402656956, JString,
                                      required = false, default = nil)
  if valid_402656956 != nil:
    section.add "X-Amz-Signature", valid_402656956
  var valid_402656957 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656957 = validateParameter(valid_402656957, JString,
                                      required = false, default = nil)
  if valid_402656957 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656957
  var valid_402656958 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656958 = validateParameter(valid_402656958, JString,
                                      required = false, default = nil)
  if valid_402656958 != nil:
    section.add "X-Amz-Algorithm", valid_402656958
  var valid_402656959 = header.getOrDefault("X-Amz-Date")
  valid_402656959 = validateParameter(valid_402656959, JString,
                                      required = false, default = nil)
  if valid_402656959 != nil:
    section.add "X-Amz-Date", valid_402656959
  var valid_402656960 = header.getOrDefault("X-Amz-Credential")
  valid_402656960 = validateParameter(valid_402656960, JString,
                                      required = false, default = nil)
  if valid_402656960 != nil:
    section.add "X-Amz-Credential", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656961
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656962: Call_GetCreateDBSubnetGroup_402656946;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402656962.validator(path, query, header, formData, body, _)
  let scheme = call_402656962.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656962.makeUrl(scheme.get, call_402656962.host, call_402656962.base,
                                   call_402656962.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656962, uri, valid, _)

proc call*(call_402656963: Call_GetCreateDBSubnetGroup_402656946;
           DBSubnetGroupName: string; DBSubnetGroupDescription: string;
           SubnetIds: JsonNode; Version: string = "2014-09-01";
           Tags: JsonNode = nil; Action: string = "CreateDBSubnetGroup"): Recallable =
  ## getCreateDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402656964 = newJObject()
  add(query_402656964, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402656964, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402656964, "Version", newJString(Version))
  if Tags != nil:
    query_402656964.add "Tags", Tags
  if SubnetIds != nil:
    query_402656964.add "SubnetIds", SubnetIds
  add(query_402656964, "Action", newJString(Action))
  result = call_402656963.call(nil, query_402656964, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_402656946(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_402656947, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_402656948,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_402657007 = ref object of OpenApiRestCall_402656035
proc url_PostCreateEventSubscription_402657009(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_402657008(path: JsonNode;
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
  var valid_402657010 = query.getOrDefault("Version")
  valid_402657010 = validateParameter(valid_402657010, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657010 != nil:
    section.add "Version", valid_402657010
  var valid_402657011 = query.getOrDefault("Action")
  valid_402657011 = validateParameter(valid_402657011, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402657011 != nil:
    section.add "Action", valid_402657011
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
  var valid_402657012 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-Security-Token", valid_402657012
  var valid_402657013 = header.getOrDefault("X-Amz-Signature")
  valid_402657013 = validateParameter(valid_402657013, JString,
                                      required = false, default = nil)
  if valid_402657013 != nil:
    section.add "X-Amz-Signature", valid_402657013
  var valid_402657014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657014 = validateParameter(valid_402657014, JString,
                                      required = false, default = nil)
  if valid_402657014 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657014
  var valid_402657015 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657015 = validateParameter(valid_402657015, JString,
                                      required = false, default = nil)
  if valid_402657015 != nil:
    section.add "X-Amz-Algorithm", valid_402657015
  var valid_402657016 = header.getOrDefault("X-Amz-Date")
  valid_402657016 = validateParameter(valid_402657016, JString,
                                      required = false, default = nil)
  if valid_402657016 != nil:
    section.add "X-Amz-Date", valid_402657016
  var valid_402657017 = header.getOrDefault("X-Amz-Credential")
  valid_402657017 = validateParameter(valid_402657017, JString,
                                      required = false, default = nil)
  if valid_402657017 != nil:
    section.add "X-Amz-Credential", valid_402657017
  var valid_402657018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657018 = validateParameter(valid_402657018, JString,
                                      required = false, default = nil)
  if valid_402657018 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657018
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
  var valid_402657019 = formData.getOrDefault("SourceIds")
  valid_402657019 = validateParameter(valid_402657019, JArray, required = false,
                                      default = nil)
  if valid_402657019 != nil:
    section.add "SourceIds", valid_402657019
  var valid_402657020 = formData.getOrDefault("SourceType")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "SourceType", valid_402657020
  var valid_402657021 = formData.getOrDefault("Enabled")
  valid_402657021 = validateParameter(valid_402657021, JBool, required = false,
                                      default = nil)
  if valid_402657021 != nil:
    section.add "Enabled", valid_402657021
  var valid_402657022 = formData.getOrDefault("EventCategories")
  valid_402657022 = validateParameter(valid_402657022, JArray, required = false,
                                      default = nil)
  if valid_402657022 != nil:
    section.add "EventCategories", valid_402657022
  var valid_402657023 = formData.getOrDefault("Tags")
  valid_402657023 = validateParameter(valid_402657023, JArray, required = false,
                                      default = nil)
  if valid_402657023 != nil:
    section.add "Tags", valid_402657023
  assert formData != nil,
         "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_402657024 = formData.getOrDefault("SnsTopicArn")
  valid_402657024 = validateParameter(valid_402657024, JString, required = true,
                                      default = nil)
  if valid_402657024 != nil:
    section.add "SnsTopicArn", valid_402657024
  var valid_402657025 = formData.getOrDefault("SubscriptionName")
  valid_402657025 = validateParameter(valid_402657025, JString, required = true,
                                      default = nil)
  if valid_402657025 != nil:
    section.add "SubscriptionName", valid_402657025
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657026: Call_PostCreateEventSubscription_402657007;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657026.validator(path, query, header, formData, body, _)
  let scheme = call_402657026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657026.makeUrl(scheme.get, call_402657026.host, call_402657026.base,
                                   call_402657026.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657026, uri, valid, _)

proc call*(call_402657027: Call_PostCreateEventSubscription_402657007;
           SnsTopicArn: string; SubscriptionName: string;
           SourceIds: JsonNode = nil; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Tags: JsonNode = nil; Version: string = "2014-09-01";
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
  var query_402657028 = newJObject()
  var formData_402657029 = newJObject()
  if SourceIds != nil:
    formData_402657029.add "SourceIds", SourceIds
  add(formData_402657029, "SourceType", newJString(SourceType))
  add(formData_402657029, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402657029.add "EventCategories", EventCategories
  if Tags != nil:
    formData_402657029.add "Tags", Tags
  add(query_402657028, "Version", newJString(Version))
  add(formData_402657029, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402657028, "Action", newJString(Action))
  add(formData_402657029, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657027.call(nil, query_402657028, nil, formData_402657029,
                               nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_402657007(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_402657008, base: "/",
    makeUrl: url_PostCreateEventSubscription_402657009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_402656985 = ref object of OpenApiRestCall_402656035
proc url_GetCreateEventSubscription_402656987(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_402656986(path: JsonNode;
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
  var valid_402656988 = query.getOrDefault("SnsTopicArn")
  valid_402656988 = validateParameter(valid_402656988, JString, required = true,
                                      default = nil)
  if valid_402656988 != nil:
    section.add "SnsTopicArn", valid_402656988
  var valid_402656989 = query.getOrDefault("Enabled")
  valid_402656989 = validateParameter(valid_402656989, JBool, required = false,
                                      default = nil)
  if valid_402656989 != nil:
    section.add "Enabled", valid_402656989
  var valid_402656990 = query.getOrDefault("EventCategories")
  valid_402656990 = validateParameter(valid_402656990, JArray, required = false,
                                      default = nil)
  if valid_402656990 != nil:
    section.add "EventCategories", valid_402656990
  var valid_402656991 = query.getOrDefault("Version")
  valid_402656991 = validateParameter(valid_402656991, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402656991 != nil:
    section.add "Version", valid_402656991
  var valid_402656992 = query.getOrDefault("SubscriptionName")
  valid_402656992 = validateParameter(valid_402656992, JString, required = true,
                                      default = nil)
  if valid_402656992 != nil:
    section.add "SubscriptionName", valid_402656992
  var valid_402656993 = query.getOrDefault("Tags")
  valid_402656993 = validateParameter(valid_402656993, JArray, required = false,
                                      default = nil)
  if valid_402656993 != nil:
    section.add "Tags", valid_402656993
  var valid_402656994 = query.getOrDefault("SourceType")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "SourceType", valid_402656994
  var valid_402656995 = query.getOrDefault("SourceIds")
  valid_402656995 = validateParameter(valid_402656995, JArray, required = false,
                                      default = nil)
  if valid_402656995 != nil:
    section.add "SourceIds", valid_402656995
  var valid_402656996 = query.getOrDefault("Action")
  valid_402656996 = validateParameter(valid_402656996, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_402656996 != nil:
    section.add "Action", valid_402656996
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
  var valid_402656997 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-Security-Token", valid_402656997
  var valid_402656998 = header.getOrDefault("X-Amz-Signature")
  valid_402656998 = validateParameter(valid_402656998, JString,
                                      required = false, default = nil)
  if valid_402656998 != nil:
    section.add "X-Amz-Signature", valid_402656998
  var valid_402656999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656999 = validateParameter(valid_402656999, JString,
                                      required = false, default = nil)
  if valid_402656999 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656999
  var valid_402657000 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657000 = validateParameter(valid_402657000, JString,
                                      required = false, default = nil)
  if valid_402657000 != nil:
    section.add "X-Amz-Algorithm", valid_402657000
  var valid_402657001 = header.getOrDefault("X-Amz-Date")
  valid_402657001 = validateParameter(valid_402657001, JString,
                                      required = false, default = nil)
  if valid_402657001 != nil:
    section.add "X-Amz-Date", valid_402657001
  var valid_402657002 = header.getOrDefault("X-Amz-Credential")
  valid_402657002 = validateParameter(valid_402657002, JString,
                                      required = false, default = nil)
  if valid_402657002 != nil:
    section.add "X-Amz-Credential", valid_402657002
  var valid_402657003 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657003 = validateParameter(valid_402657003, JString,
                                      required = false, default = nil)
  if valid_402657003 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657004: Call_GetCreateEventSubscription_402656985;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657004.validator(path, query, header, formData, body, _)
  let scheme = call_402657004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657004.makeUrl(scheme.get, call_402657004.host, call_402657004.base,
                                   call_402657004.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657004, uri, valid, _)

proc call*(call_402657005: Call_GetCreateEventSubscription_402656985;
           SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
           EventCategories: JsonNode = nil; Version: string = "2014-09-01";
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
  var query_402657006 = newJObject()
  add(query_402657006, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402657006, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402657006.add "EventCategories", EventCategories
  add(query_402657006, "Version", newJString(Version))
  add(query_402657006, "SubscriptionName", newJString(SubscriptionName))
  if Tags != nil:
    query_402657006.add "Tags", Tags
  add(query_402657006, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_402657006.add "SourceIds", SourceIds
  add(query_402657006, "Action", newJString(Action))
  result = call_402657005.call(nil, query_402657006, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_402656985(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_402656986, base: "/",
    makeUrl: url_GetCreateEventSubscription_402656987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_402657050 = ref object of OpenApiRestCall_402656035
proc url_PostCreateOptionGroup_402657052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_402657051(path: JsonNode; query: JsonNode;
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
  var valid_402657053 = query.getOrDefault("Version")
  valid_402657053 = validateParameter(valid_402657053, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657053 != nil:
    section.add "Version", valid_402657053
  var valid_402657054 = query.getOrDefault("Action")
  valid_402657054 = validateParameter(valid_402657054, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402657054 != nil:
    section.add "Action", valid_402657054
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
  var valid_402657055 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Security-Token", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Signature")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Signature", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Algorithm", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Date")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Date", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-Credential")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-Credential", valid_402657060
  var valid_402657061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657061 = validateParameter(valid_402657061, JString,
                                      required = false, default = nil)
  if valid_402657061 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657061
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupDescription: JString (required)
  ##   EngineName: JString (required)
  ##   Tags: JArray
  ##   OptionGroupName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupDescription` field"
  var valid_402657062 = formData.getOrDefault("OptionGroupDescription")
  valid_402657062 = validateParameter(valid_402657062, JString, required = true,
                                      default = nil)
  if valid_402657062 != nil:
    section.add "OptionGroupDescription", valid_402657062
  var valid_402657063 = formData.getOrDefault("EngineName")
  valid_402657063 = validateParameter(valid_402657063, JString, required = true,
                                      default = nil)
  if valid_402657063 != nil:
    section.add "EngineName", valid_402657063
  var valid_402657064 = formData.getOrDefault("Tags")
  valid_402657064 = validateParameter(valid_402657064, JArray, required = false,
                                      default = nil)
  if valid_402657064 != nil:
    section.add "Tags", valid_402657064
  var valid_402657065 = formData.getOrDefault("OptionGroupName")
  valid_402657065 = validateParameter(valid_402657065, JString, required = true,
                                      default = nil)
  if valid_402657065 != nil:
    section.add "OptionGroupName", valid_402657065
  var valid_402657066 = formData.getOrDefault("MajorEngineVersion")
  valid_402657066 = validateParameter(valid_402657066, JString, required = true,
                                      default = nil)
  if valid_402657066 != nil:
    section.add "MajorEngineVersion", valid_402657066
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657067: Call_PostCreateOptionGroup_402657050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657067.validator(path, query, header, formData, body, _)
  let scheme = call_402657067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657067.makeUrl(scheme.get, call_402657067.host, call_402657067.base,
                                   call_402657067.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657067, uri, valid, _)

proc call*(call_402657068: Call_PostCreateOptionGroup_402657050;
           OptionGroupDescription: string; EngineName: string;
           OptionGroupName: string; MajorEngineVersion: string;
           Tags: JsonNode = nil; Version: string = "2014-09-01";
           Action: string = "CreateOptionGroup"): Recallable =
  ## postCreateOptionGroup
  ##   OptionGroupDescription: string (required)
  ##   EngineName: string (required)
  ##   Tags: JArray
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   MajorEngineVersion: string (required)
  var query_402657069 = newJObject()
  var formData_402657070 = newJObject()
  add(formData_402657070, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(formData_402657070, "EngineName", newJString(EngineName))
  if Tags != nil:
    formData_402657070.add "Tags", Tags
  add(query_402657069, "Version", newJString(Version))
  add(formData_402657070, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657069, "Action", newJString(Action))
  add(formData_402657070, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657068.call(nil, query_402657069, nil, formData_402657070,
                               nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_402657050(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_402657051, base: "/",
    makeUrl: url_PostCreateOptionGroup_402657052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_402657030 = ref object of OpenApiRestCall_402656035
proc url_GetCreateOptionGroup_402657032(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_402657031(path: JsonNode; query: JsonNode;
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
  var valid_402657033 = query.getOrDefault("OptionGroupName")
  valid_402657033 = validateParameter(valid_402657033, JString, required = true,
                                      default = nil)
  if valid_402657033 != nil:
    section.add "OptionGroupName", valid_402657033
  var valid_402657034 = query.getOrDefault("Version")
  valid_402657034 = validateParameter(valid_402657034, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657034 != nil:
    section.add "Version", valid_402657034
  var valid_402657035 = query.getOrDefault("Tags")
  valid_402657035 = validateParameter(valid_402657035, JArray, required = false,
                                      default = nil)
  if valid_402657035 != nil:
    section.add "Tags", valid_402657035
  var valid_402657036 = query.getOrDefault("Action")
  valid_402657036 = validateParameter(valid_402657036, JString, required = true,
                                      default = newJString("CreateOptionGroup"))
  if valid_402657036 != nil:
    section.add "Action", valid_402657036
  var valid_402657037 = query.getOrDefault("EngineName")
  valid_402657037 = validateParameter(valid_402657037, JString, required = true,
                                      default = nil)
  if valid_402657037 != nil:
    section.add "EngineName", valid_402657037
  var valid_402657038 = query.getOrDefault("MajorEngineVersion")
  valid_402657038 = validateParameter(valid_402657038, JString, required = true,
                                      default = nil)
  if valid_402657038 != nil:
    section.add "MajorEngineVersion", valid_402657038
  var valid_402657039 = query.getOrDefault("OptionGroupDescription")
  valid_402657039 = validateParameter(valid_402657039, JString, required = true,
                                      default = nil)
  if valid_402657039 != nil:
    section.add "OptionGroupDescription", valid_402657039
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
  var valid_402657040 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Security-Token", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Signature")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Signature", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Algorithm", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Date")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Date", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-Credential")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-Credential", valid_402657045
  var valid_402657046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657046 = validateParameter(valid_402657046, JString,
                                      required = false, default = nil)
  if valid_402657046 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657047: Call_GetCreateOptionGroup_402657030;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657047.validator(path, query, header, formData, body, _)
  let scheme = call_402657047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657047.makeUrl(scheme.get, call_402657047.host, call_402657047.base,
                                   call_402657047.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657047, uri, valid, _)

proc call*(call_402657048: Call_GetCreateOptionGroup_402657030;
           OptionGroupName: string; EngineName: string;
           MajorEngineVersion: string; OptionGroupDescription: string;
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           Action: string = "CreateOptionGroup"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupDescription: string (required)
  var query_402657049 = newJObject()
  add(query_402657049, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657049, "Version", newJString(Version))
  if Tags != nil:
    query_402657049.add "Tags", Tags
  add(query_402657049, "Action", newJString(Action))
  add(query_402657049, "EngineName", newJString(EngineName))
  add(query_402657049, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(query_402657049, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  result = call_402657048.call(nil, query_402657049, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_402657030(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_402657031, base: "/",
    makeUrl: url_GetCreateOptionGroup_402657032,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_402657089 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBInstance_402657091(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_402657090(path: JsonNode; query: JsonNode;
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
  var valid_402657092 = query.getOrDefault("Version")
  valid_402657092 = validateParameter(valid_402657092, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657092 != nil:
    section.add "Version", valid_402657092
  var valid_402657093 = query.getOrDefault("Action")
  valid_402657093 = validateParameter(valid_402657093, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
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
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   FinalDBSnapshotIdentifier: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657101 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657101 = validateParameter(valid_402657101, JString, required = true,
                                      default = nil)
  if valid_402657101 != nil:
    section.add "DBInstanceIdentifier", valid_402657101
  var valid_402657102 = formData.getOrDefault("SkipFinalSnapshot")
  valid_402657102 = validateParameter(valid_402657102, JBool, required = false,
                                      default = nil)
  if valid_402657102 != nil:
    section.add "SkipFinalSnapshot", valid_402657102
  var valid_402657103 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402657103
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657104: Call_PostDeleteDBInstance_402657089;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657104.validator(path, query, header, formData, body, _)
  let scheme = call_402657104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657104.makeUrl(scheme.get, call_402657104.host, call_402657104.base,
                                   call_402657104.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657104, uri, valid, _)

proc call*(call_402657105: Call_PostDeleteDBInstance_402657089;
           DBInstanceIdentifier: string; Version: string = "2014-09-01";
           SkipFinalSnapshot: bool = false; Action: string = "DeleteDBInstance";
           FinalDBSnapshotIdentifier: string = ""): Recallable =
  ## postDeleteDBInstance
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Action: string (required)
  ##   FinalDBSnapshotIdentifier: string
  var query_402657106 = newJObject()
  var formData_402657107 = newJObject()
  add(query_402657106, "Version", newJString(Version))
  add(formData_402657107, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657107, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_402657106, "Action", newJString(Action))
  add(formData_402657107, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  result = call_402657105.call(nil, query_402657106, nil, formData_402657107,
                               nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_402657089(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_402657090, base: "/",
    makeUrl: url_PostDeleteDBInstance_402657091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_402657071 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBInstance_402657073(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_402657072(path: JsonNode; query: JsonNode;
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
  var valid_402657074 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657074 = validateParameter(valid_402657074, JString, required = true,
                                      default = nil)
  if valid_402657074 != nil:
    section.add "DBInstanceIdentifier", valid_402657074
  var valid_402657075 = query.getOrDefault("Version")
  valid_402657075 = validateParameter(valid_402657075, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657075 != nil:
    section.add "Version", valid_402657075
  var valid_402657076 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_402657076 = validateParameter(valid_402657076, JString,
                                      required = false, default = nil)
  if valid_402657076 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_402657076
  var valid_402657077 = query.getOrDefault("Action")
  valid_402657077 = validateParameter(valid_402657077, JString, required = true,
                                      default = newJString("DeleteDBInstance"))
  if valid_402657077 != nil:
    section.add "Action", valid_402657077
  var valid_402657078 = query.getOrDefault("SkipFinalSnapshot")
  valid_402657078 = validateParameter(valid_402657078, JBool, required = false,
                                      default = nil)
  if valid_402657078 != nil:
    section.add "SkipFinalSnapshot", valid_402657078
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
  var valid_402657079 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657079 = validateParameter(valid_402657079, JString,
                                      required = false, default = nil)
  if valid_402657079 != nil:
    section.add "X-Amz-Security-Token", valid_402657079
  var valid_402657080 = header.getOrDefault("X-Amz-Signature")
  valid_402657080 = validateParameter(valid_402657080, JString,
                                      required = false, default = nil)
  if valid_402657080 != nil:
    section.add "X-Amz-Signature", valid_402657080
  var valid_402657081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657081 = validateParameter(valid_402657081, JString,
                                      required = false, default = nil)
  if valid_402657081 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657081
  var valid_402657082 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657082 = validateParameter(valid_402657082, JString,
                                      required = false, default = nil)
  if valid_402657082 != nil:
    section.add "X-Amz-Algorithm", valid_402657082
  var valid_402657083 = header.getOrDefault("X-Amz-Date")
  valid_402657083 = validateParameter(valid_402657083, JString,
                                      required = false, default = nil)
  if valid_402657083 != nil:
    section.add "X-Amz-Date", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Credential")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Credential", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657086: Call_GetDeleteDBInstance_402657071;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657086.validator(path, query, header, formData, body, _)
  let scheme = call_402657086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657086.makeUrl(scheme.get, call_402657086.host, call_402657086.base,
                                   call_402657086.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657086, uri, valid, _)

proc call*(call_402657087: Call_GetDeleteDBInstance_402657071;
           DBInstanceIdentifier: string; Version: string = "2014-09-01";
           FinalDBSnapshotIdentifier: string = "";
           Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false): Recallable =
  ## getDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  var query_402657088 = newJObject()
  add(query_402657088, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657088, "Version", newJString(Version))
  add(query_402657088, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_402657088, "Action", newJString(Action))
  add(query_402657088, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_402657087.call(nil, query_402657088, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_402657071(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_402657072, base: "/",
    makeUrl: url_GetDeleteDBInstance_402657073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_402657124 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBParameterGroup_402657126(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_402657125(path: JsonNode;
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
  var valid_402657127 = query.getOrDefault("Version")
  valid_402657127 = validateParameter(valid_402657127, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657127 != nil:
    section.add "Version", valid_402657127
  var valid_402657128 = query.getOrDefault("Action")
  valid_402657128 = validateParameter(valid_402657128, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657128 != nil:
    section.add "Action", valid_402657128
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
  var valid_402657129 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Security-Token", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-Signature")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Signature", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Algorithm", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Date")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Date", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Credential")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Credential", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657135
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657136 = formData.getOrDefault("DBParameterGroupName")
  valid_402657136 = validateParameter(valid_402657136, JString, required = true,
                                      default = nil)
  if valid_402657136 != nil:
    section.add "DBParameterGroupName", valid_402657136
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657137: Call_PostDeleteDBParameterGroup_402657124;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657137.validator(path, query, header, formData, body, _)
  let scheme = call_402657137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657137.makeUrl(scheme.get, call_402657137.host, call_402657137.base,
                                   call_402657137.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657137, uri, valid, _)

proc call*(call_402657138: Call_PostDeleteDBParameterGroup_402657124;
           DBParameterGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## postDeleteDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  var query_402657139 = newJObject()
  var formData_402657140 = newJObject()
  add(query_402657139, "Version", newJString(Version))
  add(formData_402657140, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402657139, "Action", newJString(Action))
  result = call_402657138.call(nil, query_402657139, nil, formData_402657140,
                               nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_402657124(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_402657125, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_402657126,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_402657108 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBParameterGroup_402657110(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_402657109(path: JsonNode;
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
  var valid_402657111 = query.getOrDefault("DBParameterGroupName")
  valid_402657111 = validateParameter(valid_402657111, JString, required = true,
                                      default = nil)
  if valid_402657111 != nil:
    section.add "DBParameterGroupName", valid_402657111
  var valid_402657112 = query.getOrDefault("Version")
  valid_402657112 = validateParameter(valid_402657112, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657112 != nil:
    section.add "Version", valid_402657112
  var valid_402657113 = query.getOrDefault("Action")
  valid_402657113 = validateParameter(valid_402657113, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_402657113 != nil:
    section.add "Action", valid_402657113
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
  var valid_402657114 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Security-Token", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Signature")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Signature", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Algorithm", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Date")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Date", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Credential")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Credential", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657121: Call_GetDeleteDBParameterGroup_402657108;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657121.validator(path, query, header, formData, body, _)
  let scheme = call_402657121.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657121.makeUrl(scheme.get, call_402657121.host, call_402657121.base,
                                   call_402657121.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657121, uri, valid, _)

proc call*(call_402657122: Call_GetDeleteDBParameterGroup_402657108;
           DBParameterGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBParameterGroup"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657123 = newJObject()
  add(query_402657123, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657123, "Version", newJString(Version))
  add(query_402657123, "Action", newJString(Action))
  result = call_402657122.call(nil, query_402657123, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_402657108(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_402657109, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_402657110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_402657157 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSecurityGroup_402657159(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_402657158(path: JsonNode;
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
  var valid_402657160 = query.getOrDefault("Version")
  valid_402657160 = validateParameter(valid_402657160, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657160 != nil:
    section.add "Version", valid_402657160
  var valid_402657161 = query.getOrDefault("Action")
  valid_402657161 = validateParameter(valid_402657161, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657161 != nil:
    section.add "Action", valid_402657161
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
  var valid_402657162 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-Security-Token", valid_402657162
  var valid_402657163 = header.getOrDefault("X-Amz-Signature")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "X-Amz-Signature", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-Algorithm", valid_402657165
  var valid_402657166 = header.getOrDefault("X-Amz-Date")
  valid_402657166 = validateParameter(valid_402657166, JString,
                                      required = false, default = nil)
  if valid_402657166 != nil:
    section.add "X-Amz-Date", valid_402657166
  var valid_402657167 = header.getOrDefault("X-Amz-Credential")
  valid_402657167 = validateParameter(valid_402657167, JString,
                                      required = false, default = nil)
  if valid_402657167 != nil:
    section.add "X-Amz-Credential", valid_402657167
  var valid_402657168 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657168 = validateParameter(valid_402657168, JString,
                                      required = false, default = nil)
  if valid_402657168 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657168
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402657169 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657169 = validateParameter(valid_402657169, JString, required = true,
                                      default = nil)
  if valid_402657169 != nil:
    section.add "DBSecurityGroupName", valid_402657169
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657170: Call_PostDeleteDBSecurityGroup_402657157;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657170.validator(path, query, header, formData, body, _)
  let scheme = call_402657170.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657170.makeUrl(scheme.get, call_402657170.host, call_402657170.base,
                                   call_402657170.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657170, uri, valid, _)

proc call*(call_402657171: Call_PostDeleteDBSecurityGroup_402657157;
           DBSecurityGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  var query_402657172 = newJObject()
  var formData_402657173 = newJObject()
  add(query_402657172, "Version", newJString(Version))
  add(formData_402657173, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402657172, "Action", newJString(Action))
  result = call_402657171.call(nil, query_402657172, nil, formData_402657173,
                               nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_402657157(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_402657158, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_402657159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_402657141 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSecurityGroup_402657143(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_402657142(path: JsonNode;
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
  var valid_402657144 = query.getOrDefault("Version")
  valid_402657144 = validateParameter(valid_402657144, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657144 != nil:
    section.add "Version", valid_402657144
  var valid_402657145 = query.getOrDefault("Action")
  valid_402657145 = validateParameter(valid_402657145, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_402657145 != nil:
    section.add "Action", valid_402657145
  var valid_402657146 = query.getOrDefault("DBSecurityGroupName")
  valid_402657146 = validateParameter(valid_402657146, JString, required = true,
                                      default = nil)
  if valid_402657146 != nil:
    section.add "DBSecurityGroupName", valid_402657146
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
  var valid_402657147 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Security-Token", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Signature")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Signature", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-Algorithm", valid_402657150
  var valid_402657151 = header.getOrDefault("X-Amz-Date")
  valid_402657151 = validateParameter(valid_402657151, JString,
                                      required = false, default = nil)
  if valid_402657151 != nil:
    section.add "X-Amz-Date", valid_402657151
  var valid_402657152 = header.getOrDefault("X-Amz-Credential")
  valid_402657152 = validateParameter(valid_402657152, JString,
                                      required = false, default = nil)
  if valid_402657152 != nil:
    section.add "X-Amz-Credential", valid_402657152
  var valid_402657153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657153 = validateParameter(valid_402657153, JString,
                                      required = false, default = nil)
  if valid_402657153 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657154: Call_GetDeleteDBSecurityGroup_402657141;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657154.validator(path, query, header, formData, body, _)
  let scheme = call_402657154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657154.makeUrl(scheme.get, call_402657154.host, call_402657154.base,
                                   call_402657154.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657154, uri, valid, _)

proc call*(call_402657155: Call_GetDeleteDBSecurityGroup_402657141;
           DBSecurityGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSecurityGroup"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string (required)
  var query_402657156 = newJObject()
  add(query_402657156, "Version", newJString(Version))
  add(query_402657156, "Action", newJString(Action))
  add(query_402657156, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657155.call(nil, query_402657156, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_402657141(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_402657142, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_402657143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_402657190 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSnapshot_402657192(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_402657191(path: JsonNode; query: JsonNode;
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
  var valid_402657193 = query.getOrDefault("Version")
  valid_402657193 = validateParameter(valid_402657193, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657193 != nil:
    section.add "Version", valid_402657193
  var valid_402657194 = query.getOrDefault("Action")
  valid_402657194 = validateParameter(valid_402657194, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657194 != nil:
    section.add "Action", valid_402657194
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
  var valid_402657195 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-Security-Token", valid_402657195
  var valid_402657196 = header.getOrDefault("X-Amz-Signature")
  valid_402657196 = validateParameter(valid_402657196, JString,
                                      required = false, default = nil)
  if valid_402657196 != nil:
    section.add "X-Amz-Signature", valid_402657196
  var valid_402657197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657197 = validateParameter(valid_402657197, JString,
                                      required = false, default = nil)
  if valid_402657197 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657197
  var valid_402657198 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657198 = validateParameter(valid_402657198, JString,
                                      required = false, default = nil)
  if valid_402657198 != nil:
    section.add "X-Amz-Algorithm", valid_402657198
  var valid_402657199 = header.getOrDefault("X-Amz-Date")
  valid_402657199 = validateParameter(valid_402657199, JString,
                                      required = false, default = nil)
  if valid_402657199 != nil:
    section.add "X-Amz-Date", valid_402657199
  var valid_402657200 = header.getOrDefault("X-Amz-Credential")
  valid_402657200 = validateParameter(valid_402657200, JString,
                                      required = false, default = nil)
  if valid_402657200 != nil:
    section.add "X-Amz-Credential", valid_402657200
  var valid_402657201 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657201 = validateParameter(valid_402657201, JString,
                                      required = false, default = nil)
  if valid_402657201 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657201
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_402657202 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657202 = validateParameter(valid_402657202, JString, required = true,
                                      default = nil)
  if valid_402657202 != nil:
    section.add "DBSnapshotIdentifier", valid_402657202
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657203: Call_PostDeleteDBSnapshot_402657190;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657203.validator(path, query, header, formData, body, _)
  let scheme = call_402657203.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657203.makeUrl(scheme.get, call_402657203.host, call_402657203.base,
                                   call_402657203.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657203, uri, valid, _)

proc call*(call_402657204: Call_PostDeleteDBSnapshot_402657190;
           DBSnapshotIdentifier: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## postDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657205 = newJObject()
  var formData_402657206 = newJObject()
  add(query_402657205, "Version", newJString(Version))
  add(formData_402657206, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(query_402657205, "Action", newJString(Action))
  result = call_402657204.call(nil, query_402657205, nil, formData_402657206,
                               nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_402657190(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_402657191, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_402657192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_402657174 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSnapshot_402657176(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_402657175(path: JsonNode; query: JsonNode;
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
  var valid_402657177 = query.getOrDefault("Version")
  valid_402657177 = validateParameter(valid_402657177, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657177 != nil:
    section.add "Version", valid_402657177
  var valid_402657178 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657178 = validateParameter(valid_402657178, JString, required = true,
                                      default = nil)
  if valid_402657178 != nil:
    section.add "DBSnapshotIdentifier", valid_402657178
  var valid_402657179 = query.getOrDefault("Action")
  valid_402657179 = validateParameter(valid_402657179, JString, required = true,
                                      default = newJString("DeleteDBSnapshot"))
  if valid_402657179 != nil:
    section.add "Action", valid_402657179
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
  var valid_402657180 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-Security-Token", valid_402657180
  var valid_402657181 = header.getOrDefault("X-Amz-Signature")
  valid_402657181 = validateParameter(valid_402657181, JString,
                                      required = false, default = nil)
  if valid_402657181 != nil:
    section.add "X-Amz-Signature", valid_402657181
  var valid_402657182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657182 = validateParameter(valid_402657182, JString,
                                      required = false, default = nil)
  if valid_402657182 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657182
  var valid_402657183 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657183 = validateParameter(valid_402657183, JString,
                                      required = false, default = nil)
  if valid_402657183 != nil:
    section.add "X-Amz-Algorithm", valid_402657183
  var valid_402657184 = header.getOrDefault("X-Amz-Date")
  valid_402657184 = validateParameter(valid_402657184, JString,
                                      required = false, default = nil)
  if valid_402657184 != nil:
    section.add "X-Amz-Date", valid_402657184
  var valid_402657185 = header.getOrDefault("X-Amz-Credential")
  valid_402657185 = validateParameter(valid_402657185, JString,
                                      required = false, default = nil)
  if valid_402657185 != nil:
    section.add "X-Amz-Credential", valid_402657185
  var valid_402657186 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657186 = validateParameter(valid_402657186, JString,
                                      required = false, default = nil)
  if valid_402657186 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657187: Call_GetDeleteDBSnapshot_402657174;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657187.validator(path, query, header, formData, body, _)
  let scheme = call_402657187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657187.makeUrl(scheme.get, call_402657187.host, call_402657187.base,
                                   call_402657187.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657187, uri, valid, _)

proc call*(call_402657188: Call_GetDeleteDBSnapshot_402657174;
           DBSnapshotIdentifier: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSnapshot"): Recallable =
  ## getDeleteDBSnapshot
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  var query_402657189 = newJObject()
  add(query_402657189, "Version", newJString(Version))
  add(query_402657189, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657189, "Action", newJString(Action))
  result = call_402657188.call(nil, query_402657189, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_402657174(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_402657175, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_402657176,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_402657223 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteDBSubnetGroup_402657225(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_402657224(path: JsonNode; query: JsonNode;
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
  var valid_402657226 = query.getOrDefault("Version")
  valid_402657226 = validateParameter(valid_402657226, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657226 != nil:
    section.add "Version", valid_402657226
  var valid_402657227 = query.getOrDefault("Action")
  valid_402657227 = validateParameter(valid_402657227, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657227 != nil:
    section.add "Action", valid_402657227
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
  var valid_402657228 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657228 = validateParameter(valid_402657228, JString,
                                      required = false, default = nil)
  if valid_402657228 != nil:
    section.add "X-Amz-Security-Token", valid_402657228
  var valid_402657229 = header.getOrDefault("X-Amz-Signature")
  valid_402657229 = validateParameter(valid_402657229, JString,
                                      required = false, default = nil)
  if valid_402657229 != nil:
    section.add "X-Amz-Signature", valid_402657229
  var valid_402657230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657230 = validateParameter(valid_402657230, JString,
                                      required = false, default = nil)
  if valid_402657230 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657230
  var valid_402657231 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657231 = validateParameter(valid_402657231, JString,
                                      required = false, default = nil)
  if valid_402657231 != nil:
    section.add "X-Amz-Algorithm", valid_402657231
  var valid_402657232 = header.getOrDefault("X-Amz-Date")
  valid_402657232 = validateParameter(valid_402657232, JString,
                                      required = false, default = nil)
  if valid_402657232 != nil:
    section.add "X-Amz-Date", valid_402657232
  var valid_402657233 = header.getOrDefault("X-Amz-Credential")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "X-Amz-Credential", valid_402657233
  var valid_402657234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657234
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402657235 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657235 = validateParameter(valid_402657235, JString, required = true,
                                      default = nil)
  if valid_402657235 != nil:
    section.add "DBSubnetGroupName", valid_402657235
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657236: Call_PostDeleteDBSubnetGroup_402657223;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657236.validator(path, query, header, formData, body, _)
  let scheme = call_402657236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657236.makeUrl(scheme.get, call_402657236.host, call_402657236.base,
                                   call_402657236.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657236, uri, valid, _)

proc call*(call_402657237: Call_PostDeleteDBSubnetGroup_402657223;
           DBSubnetGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657238 = newJObject()
  var formData_402657239 = newJObject()
  add(formData_402657239, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657238, "Version", newJString(Version))
  add(query_402657238, "Action", newJString(Action))
  result = call_402657237.call(nil, query_402657238, nil, formData_402657239,
                               nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_402657223(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_402657224, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_402657225,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_402657207 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteDBSubnetGroup_402657209(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_402657208(path: JsonNode; query: JsonNode;
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
  var valid_402657210 = query.getOrDefault("DBSubnetGroupName")
  valid_402657210 = validateParameter(valid_402657210, JString, required = true,
                                      default = nil)
  if valid_402657210 != nil:
    section.add "DBSubnetGroupName", valid_402657210
  var valid_402657211 = query.getOrDefault("Version")
  valid_402657211 = validateParameter(valid_402657211, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657211 != nil:
    section.add "Version", valid_402657211
  var valid_402657212 = query.getOrDefault("Action")
  valid_402657212 = validateParameter(valid_402657212, JString, required = true, default = newJString(
      "DeleteDBSubnetGroup"))
  if valid_402657212 != nil:
    section.add "Action", valid_402657212
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
  var valid_402657213 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657213 = validateParameter(valid_402657213, JString,
                                      required = false, default = nil)
  if valid_402657213 != nil:
    section.add "X-Amz-Security-Token", valid_402657213
  var valid_402657214 = header.getOrDefault("X-Amz-Signature")
  valid_402657214 = validateParameter(valid_402657214, JString,
                                      required = false, default = nil)
  if valid_402657214 != nil:
    section.add "X-Amz-Signature", valid_402657214
  var valid_402657215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657215 = validateParameter(valid_402657215, JString,
                                      required = false, default = nil)
  if valid_402657215 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657215
  var valid_402657216 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657216 = validateParameter(valid_402657216, JString,
                                      required = false, default = nil)
  if valid_402657216 != nil:
    section.add "X-Amz-Algorithm", valid_402657216
  var valid_402657217 = header.getOrDefault("X-Amz-Date")
  valid_402657217 = validateParameter(valid_402657217, JString,
                                      required = false, default = nil)
  if valid_402657217 != nil:
    section.add "X-Amz-Date", valid_402657217
  var valid_402657218 = header.getOrDefault("X-Amz-Credential")
  valid_402657218 = validateParameter(valid_402657218, JString,
                                      required = false, default = nil)
  if valid_402657218 != nil:
    section.add "X-Amz-Credential", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657220: Call_GetDeleteDBSubnetGroup_402657207;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657220.validator(path, query, header, formData, body, _)
  let scheme = call_402657220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657220.makeUrl(scheme.get, call_402657220.host, call_402657220.base,
                                   call_402657220.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657220, uri, valid, _)

proc call*(call_402657221: Call_GetDeleteDBSubnetGroup_402657207;
           DBSubnetGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteDBSubnetGroup"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657222 = newJObject()
  add(query_402657222, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657222, "Version", newJString(Version))
  add(query_402657222, "Action", newJString(Action))
  result = call_402657221.call(nil, query_402657222, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_402657207(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_402657208, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_402657209,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_402657256 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteEventSubscription_402657258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_402657257(path: JsonNode;
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
  var valid_402657259 = query.getOrDefault("Version")
  valid_402657259 = validateParameter(valid_402657259, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657259 != nil:
    section.add "Version", valid_402657259
  var valid_402657260 = query.getOrDefault("Action")
  valid_402657260 = validateParameter(valid_402657260, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657260 != nil:
    section.add "Action", valid_402657260
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
  var valid_402657261 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657261 = validateParameter(valid_402657261, JString,
                                      required = false, default = nil)
  if valid_402657261 != nil:
    section.add "X-Amz-Security-Token", valid_402657261
  var valid_402657262 = header.getOrDefault("X-Amz-Signature")
  valid_402657262 = validateParameter(valid_402657262, JString,
                                      required = false, default = nil)
  if valid_402657262 != nil:
    section.add "X-Amz-Signature", valid_402657262
  var valid_402657263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657263 = validateParameter(valid_402657263, JString,
                                      required = false, default = nil)
  if valid_402657263 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657263
  var valid_402657264 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657264 = validateParameter(valid_402657264, JString,
                                      required = false, default = nil)
  if valid_402657264 != nil:
    section.add "X-Amz-Algorithm", valid_402657264
  var valid_402657265 = header.getOrDefault("X-Amz-Date")
  valid_402657265 = validateParameter(valid_402657265, JString,
                                      required = false, default = nil)
  if valid_402657265 != nil:
    section.add "X-Amz-Date", valid_402657265
  var valid_402657266 = header.getOrDefault("X-Amz-Credential")
  valid_402657266 = validateParameter(valid_402657266, JString,
                                      required = false, default = nil)
  if valid_402657266 != nil:
    section.add "X-Amz-Credential", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657267
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402657268 = formData.getOrDefault("SubscriptionName")
  valid_402657268 = validateParameter(valid_402657268, JString, required = true,
                                      default = nil)
  if valid_402657268 != nil:
    section.add "SubscriptionName", valid_402657268
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657269: Call_PostDeleteEventSubscription_402657256;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657269.validator(path, query, header, formData, body, _)
  let scheme = call_402657269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657269.makeUrl(scheme.get, call_402657269.host, call_402657269.base,
                                   call_402657269.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657269, uri, valid, _)

proc call*(call_402657270: Call_PostDeleteEventSubscription_402657256;
           SubscriptionName: string; Version: string = "2014-09-01";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## postDeleteEventSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402657271 = newJObject()
  var formData_402657272 = newJObject()
  add(query_402657271, "Version", newJString(Version))
  add(query_402657271, "Action", newJString(Action))
  add(formData_402657272, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657270.call(nil, query_402657271, nil, formData_402657272,
                               nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_402657256(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_402657257, base: "/",
    makeUrl: url_PostDeleteEventSubscription_402657258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_402657240 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteEventSubscription_402657242(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_402657241(path: JsonNode;
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
  var valid_402657243 = query.getOrDefault("Version")
  valid_402657243 = validateParameter(valid_402657243, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657243 != nil:
    section.add "Version", valid_402657243
  var valid_402657244 = query.getOrDefault("SubscriptionName")
  valid_402657244 = validateParameter(valid_402657244, JString, required = true,
                                      default = nil)
  if valid_402657244 != nil:
    section.add "SubscriptionName", valid_402657244
  var valid_402657245 = query.getOrDefault("Action")
  valid_402657245 = validateParameter(valid_402657245, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_402657245 != nil:
    section.add "Action", valid_402657245
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
  var valid_402657246 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657246 = validateParameter(valid_402657246, JString,
                                      required = false, default = nil)
  if valid_402657246 != nil:
    section.add "X-Amz-Security-Token", valid_402657246
  var valid_402657247 = header.getOrDefault("X-Amz-Signature")
  valid_402657247 = validateParameter(valid_402657247, JString,
                                      required = false, default = nil)
  if valid_402657247 != nil:
    section.add "X-Amz-Signature", valid_402657247
  var valid_402657248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657248 = validateParameter(valid_402657248, JString,
                                      required = false, default = nil)
  if valid_402657248 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657248
  var valid_402657249 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657249 = validateParameter(valid_402657249, JString,
                                      required = false, default = nil)
  if valid_402657249 != nil:
    section.add "X-Amz-Algorithm", valid_402657249
  var valid_402657250 = header.getOrDefault("X-Amz-Date")
  valid_402657250 = validateParameter(valid_402657250, JString,
                                      required = false, default = nil)
  if valid_402657250 != nil:
    section.add "X-Amz-Date", valid_402657250
  var valid_402657251 = header.getOrDefault("X-Amz-Credential")
  valid_402657251 = validateParameter(valid_402657251, JString,
                                      required = false, default = nil)
  if valid_402657251 != nil:
    section.add "X-Amz-Credential", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657252
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657253: Call_GetDeleteEventSubscription_402657240;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657253.validator(path, query, header, formData, body, _)
  let scheme = call_402657253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657253.makeUrl(scheme.get, call_402657253.host, call_402657253.base,
                                   call_402657253.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657253, uri, valid, _)

proc call*(call_402657254: Call_GetDeleteEventSubscription_402657240;
           SubscriptionName: string; Version: string = "2014-09-01";
           Action: string = "DeleteEventSubscription"): Recallable =
  ## getDeleteEventSubscription
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402657255 = newJObject()
  add(query_402657255, "Version", newJString(Version))
  add(query_402657255, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657255, "Action", newJString(Action))
  result = call_402657254.call(nil, query_402657255, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_402657240(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_402657241, base: "/",
    makeUrl: url_GetDeleteEventSubscription_402657242,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_402657289 = ref object of OpenApiRestCall_402656035
proc url_PostDeleteOptionGroup_402657291(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_402657290(path: JsonNode; query: JsonNode;
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
  var valid_402657292 = query.getOrDefault("Version")
  valid_402657292 = validateParameter(valid_402657292, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657292 != nil:
    section.add "Version", valid_402657292
  var valid_402657293 = query.getOrDefault("Action")
  valid_402657293 = validateParameter(valid_402657293, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657293 != nil:
    section.add "Action", valid_402657293
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
  var valid_402657294 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657294 = validateParameter(valid_402657294, JString,
                                      required = false, default = nil)
  if valid_402657294 != nil:
    section.add "X-Amz-Security-Token", valid_402657294
  var valid_402657295 = header.getOrDefault("X-Amz-Signature")
  valid_402657295 = validateParameter(valid_402657295, JString,
                                      required = false, default = nil)
  if valid_402657295 != nil:
    section.add "X-Amz-Signature", valid_402657295
  var valid_402657296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657296 = validateParameter(valid_402657296, JString,
                                      required = false, default = nil)
  if valid_402657296 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Algorithm", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Date")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Date", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-Credential")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-Credential", valid_402657299
  var valid_402657300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657300 = validateParameter(valid_402657300, JString,
                                      required = false, default = nil)
  if valid_402657300 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657300
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402657301 = formData.getOrDefault("OptionGroupName")
  valid_402657301 = validateParameter(valid_402657301, JString, required = true,
                                      default = nil)
  if valid_402657301 != nil:
    section.add "OptionGroupName", valid_402657301
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657302: Call_PostDeleteOptionGroup_402657289;
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

proc call*(call_402657303: Call_PostDeleteOptionGroup_402657289;
           OptionGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## postDeleteOptionGroup
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402657304 = newJObject()
  var formData_402657305 = newJObject()
  add(query_402657304, "Version", newJString(Version))
  add(formData_402657305, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657304, "Action", newJString(Action))
  result = call_402657303.call(nil, query_402657304, nil, formData_402657305,
                               nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_402657289(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_402657290, base: "/",
    makeUrl: url_PostDeleteOptionGroup_402657291,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_402657273 = ref object of OpenApiRestCall_402656035
proc url_GetDeleteOptionGroup_402657275(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_402657274(path: JsonNode; query: JsonNode;
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
  var valid_402657276 = query.getOrDefault("OptionGroupName")
  valid_402657276 = validateParameter(valid_402657276, JString, required = true,
                                      default = nil)
  if valid_402657276 != nil:
    section.add "OptionGroupName", valid_402657276
  var valid_402657277 = query.getOrDefault("Version")
  valid_402657277 = validateParameter(valid_402657277, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657277 != nil:
    section.add "Version", valid_402657277
  var valid_402657278 = query.getOrDefault("Action")
  valid_402657278 = validateParameter(valid_402657278, JString, required = true,
                                      default = newJString("DeleteOptionGroup"))
  if valid_402657278 != nil:
    section.add "Action", valid_402657278
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
  var valid_402657279 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657279 = validateParameter(valid_402657279, JString,
                                      required = false, default = nil)
  if valid_402657279 != nil:
    section.add "X-Amz-Security-Token", valid_402657279
  var valid_402657280 = header.getOrDefault("X-Amz-Signature")
  valid_402657280 = validateParameter(valid_402657280, JString,
                                      required = false, default = nil)
  if valid_402657280 != nil:
    section.add "X-Amz-Signature", valid_402657280
  var valid_402657281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657281 = validateParameter(valid_402657281, JString,
                                      required = false, default = nil)
  if valid_402657281 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Algorithm", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-Date")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-Date", valid_402657283
  var valid_402657284 = header.getOrDefault("X-Amz-Credential")
  valid_402657284 = validateParameter(valid_402657284, JString,
                                      required = false, default = nil)
  if valid_402657284 != nil:
    section.add "X-Amz-Credential", valid_402657284
  var valid_402657285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657285 = validateParameter(valid_402657285, JString,
                                      required = false, default = nil)
  if valid_402657285 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657286: Call_GetDeleteOptionGroup_402657273;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657286.validator(path, query, header, formData, body, _)
  let scheme = call_402657286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657286.makeUrl(scheme.get, call_402657286.host, call_402657286.base,
                                   call_402657286.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657286, uri, valid, _)

proc call*(call_402657287: Call_GetDeleteOptionGroup_402657273;
           OptionGroupName: string; Version: string = "2014-09-01";
           Action: string = "DeleteOptionGroup"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657288 = newJObject()
  add(query_402657288, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657288, "Version", newJString(Version))
  add(query_402657288, "Action", newJString(Action))
  result = call_402657287.call(nil, query_402657288, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_402657273(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_402657274, base: "/",
    makeUrl: url_GetDeleteOptionGroup_402657275,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_402657329 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBEngineVersions_402657331(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_402657330(path: JsonNode;
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
  var valid_402657332 = query.getOrDefault("Version")
  valid_402657332 = validateParameter(valid_402657332, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657332 != nil:
    section.add "Version", valid_402657332
  var valid_402657333 = query.getOrDefault("Action")
  valid_402657333 = validateParameter(valid_402657333, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657333 != nil:
    section.add "Action", valid_402657333
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
  var valid_402657334 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657334 = validateParameter(valid_402657334, JString,
                                      required = false, default = nil)
  if valid_402657334 != nil:
    section.add "X-Amz-Security-Token", valid_402657334
  var valid_402657335 = header.getOrDefault("X-Amz-Signature")
  valid_402657335 = validateParameter(valid_402657335, JString,
                                      required = false, default = nil)
  if valid_402657335 != nil:
    section.add "X-Amz-Signature", valid_402657335
  var valid_402657336 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657336 = validateParameter(valid_402657336, JString,
                                      required = false, default = nil)
  if valid_402657336 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657336
  var valid_402657337 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657337 = validateParameter(valid_402657337, JString,
                                      required = false, default = nil)
  if valid_402657337 != nil:
    section.add "X-Amz-Algorithm", valid_402657337
  var valid_402657338 = header.getOrDefault("X-Amz-Date")
  valid_402657338 = validateParameter(valid_402657338, JString,
                                      required = false, default = nil)
  if valid_402657338 != nil:
    section.add "X-Amz-Date", valid_402657338
  var valid_402657339 = header.getOrDefault("X-Amz-Credential")
  valid_402657339 = validateParameter(valid_402657339, JString,
                                      required = false, default = nil)
  if valid_402657339 != nil:
    section.add "X-Amz-Credential", valid_402657339
  var valid_402657340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657340 = validateParameter(valid_402657340, JString,
                                      required = false, default = nil)
  if valid_402657340 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657340
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
  var valid_402657341 = formData.getOrDefault("Marker")
  valid_402657341 = validateParameter(valid_402657341, JString,
                                      required = false, default = nil)
  if valid_402657341 != nil:
    section.add "Marker", valid_402657341
  var valid_402657342 = formData.getOrDefault("DefaultOnly")
  valid_402657342 = validateParameter(valid_402657342, JBool, required = false,
                                      default = nil)
  if valid_402657342 != nil:
    section.add "DefaultOnly", valid_402657342
  var valid_402657343 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_402657343 = validateParameter(valid_402657343, JBool, required = false,
                                      default = nil)
  if valid_402657343 != nil:
    section.add "ListSupportedCharacterSets", valid_402657343
  var valid_402657344 = formData.getOrDefault("Engine")
  valid_402657344 = validateParameter(valid_402657344, JString,
                                      required = false, default = nil)
  if valid_402657344 != nil:
    section.add "Engine", valid_402657344
  var valid_402657345 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657345 = validateParameter(valid_402657345, JString,
                                      required = false, default = nil)
  if valid_402657345 != nil:
    section.add "DBParameterGroupFamily", valid_402657345
  var valid_402657346 = formData.getOrDefault("MaxRecords")
  valid_402657346 = validateParameter(valid_402657346, JInt, required = false,
                                      default = nil)
  if valid_402657346 != nil:
    section.add "MaxRecords", valid_402657346
  var valid_402657347 = formData.getOrDefault("Filters")
  valid_402657347 = validateParameter(valid_402657347, JArray, required = false,
                                      default = nil)
  if valid_402657347 != nil:
    section.add "Filters", valid_402657347
  var valid_402657348 = formData.getOrDefault("EngineVersion")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "EngineVersion", valid_402657348
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657349: Call_PostDescribeDBEngineVersions_402657329;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657349.validator(path, query, header, formData, body, _)
  let scheme = call_402657349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657349.makeUrl(scheme.get, call_402657349.host, call_402657349.base,
                                   call_402657349.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657349, uri, valid, _)

proc call*(call_402657350: Call_PostDescribeDBEngineVersions_402657329;
           Marker: string = ""; DefaultOnly: bool = false;
           ListSupportedCharacterSets: bool = false; Engine: string = "";
           DBParameterGroupFamily: string = ""; Version: string = "2014-09-01";
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
  var query_402657351 = newJObject()
  var formData_402657352 = newJObject()
  add(formData_402657352, "Marker", newJString(Marker))
  add(formData_402657352, "DefaultOnly", newJBool(DefaultOnly))
  add(formData_402657352, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_402657352, "Engine", newJString(Engine))
  add(formData_402657352, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657351, "Version", newJString(Version))
  add(formData_402657352, "MaxRecords", newJInt(MaxRecords))
  add(query_402657351, "Action", newJString(Action))
  if Filters != nil:
    formData_402657352.add "Filters", Filters
  add(formData_402657352, "EngineVersion", newJString(EngineVersion))
  result = call_402657350.call(nil, query_402657351, nil, formData_402657352,
                               nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_402657329(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_402657330, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_402657331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_402657306 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBEngineVersions_402657308(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_402657307(path: JsonNode;
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
  var valid_402657309 = query.getOrDefault("Filters")
  valid_402657309 = validateParameter(valid_402657309, JArray, required = false,
                                      default = nil)
  if valid_402657309 != nil:
    section.add "Filters", valid_402657309
  var valid_402657310 = query.getOrDefault("DefaultOnly")
  valid_402657310 = validateParameter(valid_402657310, JBool, required = false,
                                      default = nil)
  if valid_402657310 != nil:
    section.add "DefaultOnly", valid_402657310
  var valid_402657311 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657311 = validateParameter(valid_402657311, JString,
                                      required = false, default = nil)
  if valid_402657311 != nil:
    section.add "DBParameterGroupFamily", valid_402657311
  var valid_402657312 = query.getOrDefault("MaxRecords")
  valid_402657312 = validateParameter(valid_402657312, JInt, required = false,
                                      default = nil)
  if valid_402657312 != nil:
    section.add "MaxRecords", valid_402657312
  var valid_402657313 = query.getOrDefault("Marker")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "Marker", valid_402657313
  var valid_402657314 = query.getOrDefault("Version")
  valid_402657314 = validateParameter(valid_402657314, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657314 != nil:
    section.add "Version", valid_402657314
  var valid_402657315 = query.getOrDefault("EngineVersion")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "EngineVersion", valid_402657315
  var valid_402657316 = query.getOrDefault("Engine")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "Engine", valid_402657316
  var valid_402657317 = query.getOrDefault("Action")
  valid_402657317 = validateParameter(valid_402657317, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_402657317 != nil:
    section.add "Action", valid_402657317
  var valid_402657318 = query.getOrDefault("ListSupportedCharacterSets")
  valid_402657318 = validateParameter(valid_402657318, JBool, required = false,
                                      default = nil)
  if valid_402657318 != nil:
    section.add "ListSupportedCharacterSets", valid_402657318
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
  var valid_402657319 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657319 = validateParameter(valid_402657319, JString,
                                      required = false, default = nil)
  if valid_402657319 != nil:
    section.add "X-Amz-Security-Token", valid_402657319
  var valid_402657320 = header.getOrDefault("X-Amz-Signature")
  valid_402657320 = validateParameter(valid_402657320, JString,
                                      required = false, default = nil)
  if valid_402657320 != nil:
    section.add "X-Amz-Signature", valid_402657320
  var valid_402657321 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657321 = validateParameter(valid_402657321, JString,
                                      required = false, default = nil)
  if valid_402657321 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657321
  var valid_402657322 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657322 = validateParameter(valid_402657322, JString,
                                      required = false, default = nil)
  if valid_402657322 != nil:
    section.add "X-Amz-Algorithm", valid_402657322
  var valid_402657323 = header.getOrDefault("X-Amz-Date")
  valid_402657323 = validateParameter(valid_402657323, JString,
                                      required = false, default = nil)
  if valid_402657323 != nil:
    section.add "X-Amz-Date", valid_402657323
  var valid_402657324 = header.getOrDefault("X-Amz-Credential")
  valid_402657324 = validateParameter(valid_402657324, JString,
                                      required = false, default = nil)
  if valid_402657324 != nil:
    section.add "X-Amz-Credential", valid_402657324
  var valid_402657325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657325 = validateParameter(valid_402657325, JString,
                                      required = false, default = nil)
  if valid_402657325 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657325
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657326: Call_GetDescribeDBEngineVersions_402657306;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657326.validator(path, query, header, formData, body, _)
  let scheme = call_402657326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657326.makeUrl(scheme.get, call_402657326.host, call_402657326.base,
                                   call_402657326.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657326, uri, valid, _)

proc call*(call_402657327: Call_GetDescribeDBEngineVersions_402657306;
           Filters: JsonNode = nil; DefaultOnly: bool = false;
           DBParameterGroupFamily: string = ""; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2014-09-01";
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
  var query_402657328 = newJObject()
  if Filters != nil:
    query_402657328.add "Filters", Filters
  add(query_402657328, "DefaultOnly", newJBool(DefaultOnly))
  add(query_402657328, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657328, "MaxRecords", newJInt(MaxRecords))
  add(query_402657328, "Marker", newJString(Marker))
  add(query_402657328, "Version", newJString(Version))
  add(query_402657328, "EngineVersion", newJString(EngineVersion))
  add(query_402657328, "Engine", newJString(Engine))
  add(query_402657328, "Action", newJString(Action))
  add(query_402657328, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  result = call_402657327.call(nil, query_402657328, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_402657306(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_402657307, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_402657308,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_402657372 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBInstances_402657374(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_402657373(path: JsonNode; query: JsonNode;
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
  var valid_402657375 = query.getOrDefault("Version")
  valid_402657375 = validateParameter(valid_402657375, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657375 != nil:
    section.add "Version", valid_402657375
  var valid_402657376 = query.getOrDefault("Action")
  valid_402657376 = validateParameter(valid_402657376, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657376 != nil:
    section.add "Action", valid_402657376
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
  var valid_402657377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-Security-Token", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-Signature")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-Signature", valid_402657378
  var valid_402657379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657379 = validateParameter(valid_402657379, JString,
                                      required = false, default = nil)
  if valid_402657379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657379
  var valid_402657380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657380 = validateParameter(valid_402657380, JString,
                                      required = false, default = nil)
  if valid_402657380 != nil:
    section.add "X-Amz-Algorithm", valid_402657380
  var valid_402657381 = header.getOrDefault("X-Amz-Date")
  valid_402657381 = validateParameter(valid_402657381, JString,
                                      required = false, default = nil)
  if valid_402657381 != nil:
    section.add "X-Amz-Date", valid_402657381
  var valid_402657382 = header.getOrDefault("X-Amz-Credential")
  valid_402657382 = validateParameter(valid_402657382, JString,
                                      required = false, default = nil)
  if valid_402657382 != nil:
    section.add "X-Amz-Credential", valid_402657382
  var valid_402657383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657383 = validateParameter(valid_402657383, JString,
                                      required = false, default = nil)
  if valid_402657383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657383
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657384 = formData.getOrDefault("Marker")
  valid_402657384 = validateParameter(valid_402657384, JString,
                                      required = false, default = nil)
  if valid_402657384 != nil:
    section.add "Marker", valid_402657384
  var valid_402657385 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657385 = validateParameter(valid_402657385, JString,
                                      required = false, default = nil)
  if valid_402657385 != nil:
    section.add "DBInstanceIdentifier", valid_402657385
  var valid_402657386 = formData.getOrDefault("MaxRecords")
  valid_402657386 = validateParameter(valid_402657386, JInt, required = false,
                                      default = nil)
  if valid_402657386 != nil:
    section.add "MaxRecords", valid_402657386
  var valid_402657387 = formData.getOrDefault("Filters")
  valid_402657387 = validateParameter(valid_402657387, JArray, required = false,
                                      default = nil)
  if valid_402657387 != nil:
    section.add "Filters", valid_402657387
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657388: Call_PostDescribeDBInstances_402657372;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657388.validator(path, query, header, formData, body, _)
  let scheme = call_402657388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657388.makeUrl(scheme.get, call_402657388.host, call_402657388.base,
                                   call_402657388.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657388, uri, valid, _)

proc call*(call_402657389: Call_PostDescribeDBInstances_402657372;
           Marker: string = ""; Version: string = "2014-09-01";
           DBInstanceIdentifier: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBInstances"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBInstances
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657390 = newJObject()
  var formData_402657391 = newJObject()
  add(formData_402657391, "Marker", newJString(Marker))
  add(query_402657390, "Version", newJString(Version))
  add(formData_402657391, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657391, "MaxRecords", newJInt(MaxRecords))
  add(query_402657390, "Action", newJString(Action))
  if Filters != nil:
    formData_402657391.add "Filters", Filters
  result = call_402657389.call(nil, query_402657390, nil, formData_402657391,
                               nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_402657372(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_402657373, base: "/",
    makeUrl: url_PostDescribeDBInstances_402657374,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_402657353 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBInstances_402657355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_402657354(path: JsonNode; query: JsonNode;
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
  var valid_402657356 = query.getOrDefault("Filters")
  valid_402657356 = validateParameter(valid_402657356, JArray, required = false,
                                      default = nil)
  if valid_402657356 != nil:
    section.add "Filters", valid_402657356
  var valid_402657357 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "DBInstanceIdentifier", valid_402657357
  var valid_402657358 = query.getOrDefault("MaxRecords")
  valid_402657358 = validateParameter(valid_402657358, JInt, required = false,
                                      default = nil)
  if valid_402657358 != nil:
    section.add "MaxRecords", valid_402657358
  var valid_402657359 = query.getOrDefault("Marker")
  valid_402657359 = validateParameter(valid_402657359, JString,
                                      required = false, default = nil)
  if valid_402657359 != nil:
    section.add "Marker", valid_402657359
  var valid_402657360 = query.getOrDefault("Version")
  valid_402657360 = validateParameter(valid_402657360, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657360 != nil:
    section.add "Version", valid_402657360
  var valid_402657361 = query.getOrDefault("Action")
  valid_402657361 = validateParameter(valid_402657361, JString, required = true, default = newJString(
      "DescribeDBInstances"))
  if valid_402657361 != nil:
    section.add "Action", valid_402657361
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
  var valid_402657362 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657362 = validateParameter(valid_402657362, JString,
                                      required = false, default = nil)
  if valid_402657362 != nil:
    section.add "X-Amz-Security-Token", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-Signature")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-Signature", valid_402657363
  var valid_402657364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657364 = validateParameter(valid_402657364, JString,
                                      required = false, default = nil)
  if valid_402657364 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657364
  var valid_402657365 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657365 = validateParameter(valid_402657365, JString,
                                      required = false, default = nil)
  if valid_402657365 != nil:
    section.add "X-Amz-Algorithm", valid_402657365
  var valid_402657366 = header.getOrDefault("X-Amz-Date")
  valid_402657366 = validateParameter(valid_402657366, JString,
                                      required = false, default = nil)
  if valid_402657366 != nil:
    section.add "X-Amz-Date", valid_402657366
  var valid_402657367 = header.getOrDefault("X-Amz-Credential")
  valid_402657367 = validateParameter(valid_402657367, JString,
                                      required = false, default = nil)
  if valid_402657367 != nil:
    section.add "X-Amz-Credential", valid_402657367
  var valid_402657368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657368 = validateParameter(valid_402657368, JString,
                                      required = false, default = nil)
  if valid_402657368 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657368
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657369: Call_GetDescribeDBInstances_402657353;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657369.validator(path, query, header, formData, body, _)
  let scheme = call_402657369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657369.makeUrl(scheme.get, call_402657369.host, call_402657369.base,
                                   call_402657369.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657369, uri, valid, _)

proc call*(call_402657370: Call_GetDescribeDBInstances_402657353;
           Filters: JsonNode = nil; DBInstanceIdentifier: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeDBInstances"): Recallable =
  ## getDescribeDBInstances
  ##   Filters: JArray
  ##   DBInstanceIdentifier: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657371 = newJObject()
  if Filters != nil:
    query_402657371.add "Filters", Filters
  add(query_402657371, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657371, "MaxRecords", newJInt(MaxRecords))
  add(query_402657371, "Marker", newJString(Marker))
  add(query_402657371, "Version", newJString(Version))
  add(query_402657371, "Action", newJString(Action))
  result = call_402657370.call(nil, query_402657371, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_402657353(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_402657354, base: "/",
    makeUrl: url_GetDescribeDBInstances_402657355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_402657414 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBLogFiles_402657416(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_402657415(path: JsonNode; query: JsonNode;
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
  var valid_402657417 = query.getOrDefault("Version")
  valid_402657417 = validateParameter(valid_402657417, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657417 != nil:
    section.add "Version", valid_402657417
  var valid_402657418 = query.getOrDefault("Action")
  valid_402657418 = validateParameter(valid_402657418, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
  if valid_402657418 != nil:
    section.add "Action", valid_402657418
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
  var valid_402657419 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Security-Token", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Signature")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Signature", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Algorithm", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-Date")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-Date", valid_402657423
  var valid_402657424 = header.getOrDefault("X-Amz-Credential")
  valid_402657424 = validateParameter(valid_402657424, JString,
                                      required = false, default = nil)
  if valid_402657424 != nil:
    section.add "X-Amz-Credential", valid_402657424
  var valid_402657425 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657425 = validateParameter(valid_402657425, JString,
                                      required = false, default = nil)
  if valid_402657425 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657425
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
  var valid_402657426 = formData.getOrDefault("Marker")
  valid_402657426 = validateParameter(valid_402657426, JString,
                                      required = false, default = nil)
  if valid_402657426 != nil:
    section.add "Marker", valid_402657426
  var valid_402657427 = formData.getOrDefault("FilenameContains")
  valid_402657427 = validateParameter(valid_402657427, JString,
                                      required = false, default = nil)
  if valid_402657427 != nil:
    section.add "FilenameContains", valid_402657427
  var valid_402657428 = formData.getOrDefault("FileLastWritten")
  valid_402657428 = validateParameter(valid_402657428, JInt, required = false,
                                      default = nil)
  if valid_402657428 != nil:
    section.add "FileLastWritten", valid_402657428
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657429 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657429 = validateParameter(valid_402657429, JString, required = true,
                                      default = nil)
  if valid_402657429 != nil:
    section.add "DBInstanceIdentifier", valid_402657429
  var valid_402657430 = formData.getOrDefault("MaxRecords")
  valid_402657430 = validateParameter(valid_402657430, JInt, required = false,
                                      default = nil)
  if valid_402657430 != nil:
    section.add "MaxRecords", valid_402657430
  var valid_402657431 = formData.getOrDefault("FileSize")
  valid_402657431 = validateParameter(valid_402657431, JInt, required = false,
                                      default = nil)
  if valid_402657431 != nil:
    section.add "FileSize", valid_402657431
  var valid_402657432 = formData.getOrDefault("Filters")
  valid_402657432 = validateParameter(valid_402657432, JArray, required = false,
                                      default = nil)
  if valid_402657432 != nil:
    section.add "Filters", valid_402657432
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657433: Call_PostDescribeDBLogFiles_402657414;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657433.validator(path, query, header, formData, body, _)
  let scheme = call_402657433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657433.makeUrl(scheme.get, call_402657433.host, call_402657433.base,
                                   call_402657433.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657433, uri, valid, _)

proc call*(call_402657434: Call_PostDescribeDBLogFiles_402657414;
           DBInstanceIdentifier: string; Marker: string = "";
           FilenameContains: string = ""; FileLastWritten: int = 0;
           Version: string = "2014-09-01"; MaxRecords: int = 0;
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
  var query_402657435 = newJObject()
  var formData_402657436 = newJObject()
  add(formData_402657436, "Marker", newJString(Marker))
  add(formData_402657436, "FilenameContains", newJString(FilenameContains))
  add(formData_402657436, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657435, "Version", newJString(Version))
  add(formData_402657436, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657436, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657436, "FileSize", newJInt(FileSize))
  add(query_402657435, "Action", newJString(Action))
  if Filters != nil:
    formData_402657436.add "Filters", Filters
  result = call_402657434.call(nil, query_402657435, nil, formData_402657436,
                               nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_402657414(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_402657415, base: "/",
    makeUrl: url_PostDescribeDBLogFiles_402657416,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_402657392 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBLogFiles_402657394(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_402657393(path: JsonNode; query: JsonNode;
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
  var valid_402657395 = query.getOrDefault("Filters")
  valid_402657395 = validateParameter(valid_402657395, JArray, required = false,
                                      default = nil)
  if valid_402657395 != nil:
    section.add "Filters", valid_402657395
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402657396 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657396 = validateParameter(valid_402657396, JString, required = true,
                                      default = nil)
  if valid_402657396 != nil:
    section.add "DBInstanceIdentifier", valid_402657396
  var valid_402657397 = query.getOrDefault("MaxRecords")
  valid_402657397 = validateParameter(valid_402657397, JInt, required = false,
                                      default = nil)
  if valid_402657397 != nil:
    section.add "MaxRecords", valid_402657397
  var valid_402657398 = query.getOrDefault("FileLastWritten")
  valid_402657398 = validateParameter(valid_402657398, JInt, required = false,
                                      default = nil)
  if valid_402657398 != nil:
    section.add "FileLastWritten", valid_402657398
  var valid_402657399 = query.getOrDefault("FilenameContains")
  valid_402657399 = validateParameter(valid_402657399, JString,
                                      required = false, default = nil)
  if valid_402657399 != nil:
    section.add "FilenameContains", valid_402657399
  var valid_402657400 = query.getOrDefault("Marker")
  valid_402657400 = validateParameter(valid_402657400, JString,
                                      required = false, default = nil)
  if valid_402657400 != nil:
    section.add "Marker", valid_402657400
  var valid_402657401 = query.getOrDefault("FileSize")
  valid_402657401 = validateParameter(valid_402657401, JInt, required = false,
                                      default = nil)
  if valid_402657401 != nil:
    section.add "FileSize", valid_402657401
  var valid_402657402 = query.getOrDefault("Version")
  valid_402657402 = validateParameter(valid_402657402, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657402 != nil:
    section.add "Version", valid_402657402
  var valid_402657403 = query.getOrDefault("Action")
  valid_402657403 = validateParameter(valid_402657403, JString, required = true, default = newJString(
      "DescribeDBLogFiles"))
  if valid_402657403 != nil:
    section.add "Action", valid_402657403
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
  var valid_402657404 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Security-Token", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Signature")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Signature", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-Algorithm", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-Date")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-Date", valid_402657408
  var valid_402657409 = header.getOrDefault("X-Amz-Credential")
  valid_402657409 = validateParameter(valid_402657409, JString,
                                      required = false, default = nil)
  if valid_402657409 != nil:
    section.add "X-Amz-Credential", valid_402657409
  var valid_402657410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657410 = validateParameter(valid_402657410, JString,
                                      required = false, default = nil)
  if valid_402657410 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657410
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657411: Call_GetDescribeDBLogFiles_402657392;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657411.validator(path, query, header, formData, body, _)
  let scheme = call_402657411.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657411.makeUrl(scheme.get, call_402657411.host, call_402657411.base,
                                   call_402657411.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657411, uri, valid, _)

proc call*(call_402657412: Call_GetDescribeDBLogFiles_402657392;
           DBInstanceIdentifier: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; FileLastWritten: int = 0;
           FilenameContains: string = ""; Marker: string = "";
           FileSize: int = 0; Version: string = "2014-09-01";
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
  var query_402657413 = newJObject()
  if Filters != nil:
    query_402657413.add "Filters", Filters
  add(query_402657413, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657413, "MaxRecords", newJInt(MaxRecords))
  add(query_402657413, "FileLastWritten", newJInt(FileLastWritten))
  add(query_402657413, "FilenameContains", newJString(FilenameContains))
  add(query_402657413, "Marker", newJString(Marker))
  add(query_402657413, "FileSize", newJInt(FileSize))
  add(query_402657413, "Version", newJString(Version))
  add(query_402657413, "Action", newJString(Action))
  result = call_402657412.call(nil, query_402657413, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_402657392(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_402657393, base: "/",
    makeUrl: url_GetDescribeDBLogFiles_402657394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_402657456 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameterGroups_402657458(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_402657457(path: JsonNode;
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
  var valid_402657459 = query.getOrDefault("Version")
  valid_402657459 = validateParameter(valid_402657459, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657459 != nil:
    section.add "Version", valid_402657459
  var valid_402657460 = query.getOrDefault("Action")
  valid_402657460 = validateParameter(valid_402657460, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657460 != nil:
    section.add "Action", valid_402657460
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
  var valid_402657461 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657461 = validateParameter(valid_402657461, JString,
                                      required = false, default = nil)
  if valid_402657461 != nil:
    section.add "X-Amz-Security-Token", valid_402657461
  var valid_402657462 = header.getOrDefault("X-Amz-Signature")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "X-Amz-Signature", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Algorithm", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-Date")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Date", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Credential")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Credential", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657467
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657468 = formData.getOrDefault("Marker")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "Marker", valid_402657468
  var valid_402657469 = formData.getOrDefault("DBParameterGroupName")
  valid_402657469 = validateParameter(valid_402657469, JString,
                                      required = false, default = nil)
  if valid_402657469 != nil:
    section.add "DBParameterGroupName", valid_402657469
  var valid_402657470 = formData.getOrDefault("MaxRecords")
  valid_402657470 = validateParameter(valid_402657470, JInt, required = false,
                                      default = nil)
  if valid_402657470 != nil:
    section.add "MaxRecords", valid_402657470
  var valid_402657471 = formData.getOrDefault("Filters")
  valid_402657471 = validateParameter(valid_402657471, JArray, required = false,
                                      default = nil)
  if valid_402657471 != nil:
    section.add "Filters", valid_402657471
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657472: Call_PostDescribeDBParameterGroups_402657456;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657472.validator(path, query, header, formData, body, _)
  let scheme = call_402657472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657472.makeUrl(scheme.get, call_402657472.host, call_402657472.base,
                                   call_402657472.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657472, uri, valid, _)

proc call*(call_402657473: Call_PostDescribeDBParameterGroups_402657456;
           Marker: string = ""; Version: string = "2014-09-01";
           DBParameterGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBParameterGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657474 = newJObject()
  var formData_402657475 = newJObject()
  add(formData_402657475, "Marker", newJString(Marker))
  add(query_402657474, "Version", newJString(Version))
  add(formData_402657475, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657475, "MaxRecords", newJInt(MaxRecords))
  add(query_402657474, "Action", newJString(Action))
  if Filters != nil:
    formData_402657475.add "Filters", Filters
  result = call_402657473.call(nil, query_402657474, nil, formData_402657475,
                               nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_402657456(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_402657457, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_402657458,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_402657437 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameterGroups_402657439(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_402657438(path: JsonNode;
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
  var valid_402657440 = query.getOrDefault("Filters")
  valid_402657440 = validateParameter(valid_402657440, JArray, required = false,
                                      default = nil)
  if valid_402657440 != nil:
    section.add "Filters", valid_402657440
  var valid_402657441 = query.getOrDefault("DBParameterGroupName")
  valid_402657441 = validateParameter(valid_402657441, JString,
                                      required = false, default = nil)
  if valid_402657441 != nil:
    section.add "DBParameterGroupName", valid_402657441
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
                                      default = newJString("2014-09-01"))
  if valid_402657444 != nil:
    section.add "Version", valid_402657444
  var valid_402657445 = query.getOrDefault("Action")
  valid_402657445 = validateParameter(valid_402657445, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_402657445 != nil:
    section.add "Action", valid_402657445
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
  var valid_402657446 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657446 = validateParameter(valid_402657446, JString,
                                      required = false, default = nil)
  if valid_402657446 != nil:
    section.add "X-Amz-Security-Token", valid_402657446
  var valid_402657447 = header.getOrDefault("X-Amz-Signature")
  valid_402657447 = validateParameter(valid_402657447, JString,
                                      required = false, default = nil)
  if valid_402657447 != nil:
    section.add "X-Amz-Signature", valid_402657447
  var valid_402657448 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Algorithm", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Date")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Date", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Credential")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Credential", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657452
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657453: Call_GetDescribeDBParameterGroups_402657437;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657453.validator(path, query, header, formData, body, _)
  let scheme = call_402657453.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657453.makeUrl(scheme.get, call_402657453.host, call_402657453.base,
                                   call_402657453.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657453, uri, valid, _)

proc call*(call_402657454: Call_GetDescribeDBParameterGroups_402657437;
           Filters: JsonNode = nil; DBParameterGroupName: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeDBParameterGroups"): Recallable =
  ## getDescribeDBParameterGroups
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657455 = newJObject()
  if Filters != nil:
    query_402657455.add "Filters", Filters
  add(query_402657455, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657455, "MaxRecords", newJInt(MaxRecords))
  add(query_402657455, "Marker", newJString(Marker))
  add(query_402657455, "Version", newJString(Version))
  add(query_402657455, "Action", newJString(Action))
  result = call_402657454.call(nil, query_402657455, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_402657437(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_402657438, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_402657439,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_402657496 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBParameters_402657498(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_402657497(path: JsonNode;
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
  var valid_402657499 = query.getOrDefault("Version")
  valid_402657499 = validateParameter(valid_402657499, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657499 != nil:
    section.add "Version", valid_402657499
  var valid_402657500 = query.getOrDefault("Action")
  valid_402657500 = validateParameter(valid_402657500, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657500 != nil:
    section.add "Action", valid_402657500
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
  var valid_402657501 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657501 = validateParameter(valid_402657501, JString,
                                      required = false, default = nil)
  if valid_402657501 != nil:
    section.add "X-Amz-Security-Token", valid_402657501
  var valid_402657502 = header.getOrDefault("X-Amz-Signature")
  valid_402657502 = validateParameter(valid_402657502, JString,
                                      required = false, default = nil)
  if valid_402657502 != nil:
    section.add "X-Amz-Signature", valid_402657502
  var valid_402657503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657503 = validateParameter(valid_402657503, JString,
                                      required = false, default = nil)
  if valid_402657503 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657503
  var valid_402657504 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657504 = validateParameter(valid_402657504, JString,
                                      required = false, default = nil)
  if valid_402657504 != nil:
    section.add "X-Amz-Algorithm", valid_402657504
  var valid_402657505 = header.getOrDefault("X-Amz-Date")
  valid_402657505 = validateParameter(valid_402657505, JString,
                                      required = false, default = nil)
  if valid_402657505 != nil:
    section.add "X-Amz-Date", valid_402657505
  var valid_402657506 = header.getOrDefault("X-Amz-Credential")
  valid_402657506 = validateParameter(valid_402657506, JString,
                                      required = false, default = nil)
  if valid_402657506 != nil:
    section.add "X-Amz-Credential", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657507
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupName: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Source: JString
  section = newJObject()
  var valid_402657508 = formData.getOrDefault("Marker")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "Marker", valid_402657508
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657509 = formData.getOrDefault("DBParameterGroupName")
  valid_402657509 = validateParameter(valid_402657509, JString, required = true,
                                      default = nil)
  if valid_402657509 != nil:
    section.add "DBParameterGroupName", valid_402657509
  var valid_402657510 = formData.getOrDefault("MaxRecords")
  valid_402657510 = validateParameter(valid_402657510, JInt, required = false,
                                      default = nil)
  if valid_402657510 != nil:
    section.add "MaxRecords", valid_402657510
  var valid_402657511 = formData.getOrDefault("Filters")
  valid_402657511 = validateParameter(valid_402657511, JArray, required = false,
                                      default = nil)
  if valid_402657511 != nil:
    section.add "Filters", valid_402657511
  var valid_402657512 = formData.getOrDefault("Source")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "Source", valid_402657512
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657513: Call_PostDescribeDBParameters_402657496;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657513.validator(path, query, header, formData, body, _)
  let scheme = call_402657513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657513.makeUrl(scheme.get, call_402657513.host, call_402657513.base,
                                   call_402657513.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657513, uri, valid, _)

proc call*(call_402657514: Call_PostDescribeDBParameters_402657496;
           DBParameterGroupName: string; Marker: string = "";
           Version: string = "2014-09-01"; MaxRecords: int = 0;
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
  var query_402657515 = newJObject()
  var formData_402657516 = newJObject()
  add(formData_402657516, "Marker", newJString(Marker))
  add(query_402657515, "Version", newJString(Version))
  add(formData_402657516, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402657516, "MaxRecords", newJInt(MaxRecords))
  add(query_402657515, "Action", newJString(Action))
  if Filters != nil:
    formData_402657516.add "Filters", Filters
  add(formData_402657516, "Source", newJString(Source))
  result = call_402657514.call(nil, query_402657515, nil, formData_402657516,
                               nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_402657496(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_402657497, base: "/",
    makeUrl: url_PostDescribeDBParameters_402657498,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_402657476 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBParameters_402657478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_402657477(path: JsonNode; query: JsonNode;
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
  var valid_402657479 = query.getOrDefault("Filters")
  valid_402657479 = validateParameter(valid_402657479, JArray, required = false,
                                      default = nil)
  if valid_402657479 != nil:
    section.add "Filters", valid_402657479
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402657480 = query.getOrDefault("DBParameterGroupName")
  valid_402657480 = validateParameter(valid_402657480, JString, required = true,
                                      default = nil)
  if valid_402657480 != nil:
    section.add "DBParameterGroupName", valid_402657480
  var valid_402657481 = query.getOrDefault("MaxRecords")
  valid_402657481 = validateParameter(valid_402657481, JInt, required = false,
                                      default = nil)
  if valid_402657481 != nil:
    section.add "MaxRecords", valid_402657481
  var valid_402657482 = query.getOrDefault("Marker")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "Marker", valid_402657482
  var valid_402657483 = query.getOrDefault("Version")
  valid_402657483 = validateParameter(valid_402657483, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657483 != nil:
    section.add "Version", valid_402657483
  var valid_402657484 = query.getOrDefault("Action")
  valid_402657484 = validateParameter(valid_402657484, JString, required = true, default = newJString(
      "DescribeDBParameters"))
  if valid_402657484 != nil:
    section.add "Action", valid_402657484
  var valid_402657485 = query.getOrDefault("Source")
  valid_402657485 = validateParameter(valid_402657485, JString,
                                      required = false, default = nil)
  if valid_402657485 != nil:
    section.add "Source", valid_402657485
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
  var valid_402657486 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657486 = validateParameter(valid_402657486, JString,
                                      required = false, default = nil)
  if valid_402657486 != nil:
    section.add "X-Amz-Security-Token", valid_402657486
  var valid_402657487 = header.getOrDefault("X-Amz-Signature")
  valid_402657487 = validateParameter(valid_402657487, JString,
                                      required = false, default = nil)
  if valid_402657487 != nil:
    section.add "X-Amz-Signature", valid_402657487
  var valid_402657488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657488 = validateParameter(valid_402657488, JString,
                                      required = false, default = nil)
  if valid_402657488 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657488
  var valid_402657489 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657489 = validateParameter(valid_402657489, JString,
                                      required = false, default = nil)
  if valid_402657489 != nil:
    section.add "X-Amz-Algorithm", valid_402657489
  var valid_402657490 = header.getOrDefault("X-Amz-Date")
  valid_402657490 = validateParameter(valid_402657490, JString,
                                      required = false, default = nil)
  if valid_402657490 != nil:
    section.add "X-Amz-Date", valid_402657490
  var valid_402657491 = header.getOrDefault("X-Amz-Credential")
  valid_402657491 = validateParameter(valid_402657491, JString,
                                      required = false, default = nil)
  if valid_402657491 != nil:
    section.add "X-Amz-Credential", valid_402657491
  var valid_402657492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657493: Call_GetDescribeDBParameters_402657476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657493.validator(path, query, header, formData, body, _)
  let scheme = call_402657493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657493.makeUrl(scheme.get, call_402657493.host, call_402657493.base,
                                   call_402657493.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657493, uri, valid, _)

proc call*(call_402657494: Call_GetDescribeDBParameters_402657476;
           DBParameterGroupName: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeDBParameters"; Source: string = ""): Recallable =
  ## getDescribeDBParameters
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Source: string
  var query_402657495 = newJObject()
  if Filters != nil:
    query_402657495.add "Filters", Filters
  add(query_402657495, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402657495, "MaxRecords", newJInt(MaxRecords))
  add(query_402657495, "Marker", newJString(Marker))
  add(query_402657495, "Version", newJString(Version))
  add(query_402657495, "Action", newJString(Action))
  add(query_402657495, "Source", newJString(Source))
  result = call_402657494.call(nil, query_402657495, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_402657476(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_402657477, base: "/",
    makeUrl: url_GetDescribeDBParameters_402657478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_402657536 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSecurityGroups_402657538(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_402657537(path: JsonNode;
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
  var valid_402657539 = query.getOrDefault("Version")
  valid_402657539 = validateParameter(valid_402657539, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657539 != nil:
    section.add "Version", valid_402657539
  var valid_402657540 = query.getOrDefault("Action")
  valid_402657540 = validateParameter(valid_402657540, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657540 != nil:
    section.add "Action", valid_402657540
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
  var valid_402657541 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Security-Token", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Signature")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Signature", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657543
  var valid_402657544 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657544 = validateParameter(valid_402657544, JString,
                                      required = false, default = nil)
  if valid_402657544 != nil:
    section.add "X-Amz-Algorithm", valid_402657544
  var valid_402657545 = header.getOrDefault("X-Amz-Date")
  valid_402657545 = validateParameter(valid_402657545, JString,
                                      required = false, default = nil)
  if valid_402657545 != nil:
    section.add "X-Amz-Date", valid_402657545
  var valid_402657546 = header.getOrDefault("X-Amz-Credential")
  valid_402657546 = validateParameter(valid_402657546, JString,
                                      required = false, default = nil)
  if valid_402657546 != nil:
    section.add "X-Amz-Credential", valid_402657546
  var valid_402657547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657547 = validateParameter(valid_402657547, JString,
                                      required = false, default = nil)
  if valid_402657547 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657547
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSecurityGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657548 = formData.getOrDefault("Marker")
  valid_402657548 = validateParameter(valid_402657548, JString,
                                      required = false, default = nil)
  if valid_402657548 != nil:
    section.add "Marker", valid_402657548
  var valid_402657549 = formData.getOrDefault("DBSecurityGroupName")
  valid_402657549 = validateParameter(valid_402657549, JString,
                                      required = false, default = nil)
  if valid_402657549 != nil:
    section.add "DBSecurityGroupName", valid_402657549
  var valid_402657550 = formData.getOrDefault("MaxRecords")
  valid_402657550 = validateParameter(valid_402657550, JInt, required = false,
                                      default = nil)
  if valid_402657550 != nil:
    section.add "MaxRecords", valid_402657550
  var valid_402657551 = formData.getOrDefault("Filters")
  valid_402657551 = validateParameter(valid_402657551, JArray, required = false,
                                      default = nil)
  if valid_402657551 != nil:
    section.add "Filters", valid_402657551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657552: Call_PostDescribeDBSecurityGroups_402657536;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657552.validator(path, query, header, formData, body, _)
  let scheme = call_402657552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657552.makeUrl(scheme.get, call_402657552.host, call_402657552.base,
                                   call_402657552.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657552, uri, valid, _)

proc call*(call_402657553: Call_PostDescribeDBSecurityGroups_402657536;
           Marker: string = ""; Version: string = "2014-09-01";
           DBSecurityGroupName: string = ""; MaxRecords: int = 0;
           Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBSecurityGroups
  ##   Marker: string
  ##   Version: string (required)
  ##   DBSecurityGroupName: string
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657554 = newJObject()
  var formData_402657555 = newJObject()
  add(formData_402657555, "Marker", newJString(Marker))
  add(query_402657554, "Version", newJString(Version))
  add(formData_402657555, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402657555, "MaxRecords", newJInt(MaxRecords))
  add(query_402657554, "Action", newJString(Action))
  if Filters != nil:
    formData_402657555.add "Filters", Filters
  result = call_402657553.call(nil, query_402657554, nil, formData_402657555,
                               nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_402657536(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_402657537, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_402657538,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_402657517 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSecurityGroups_402657519(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_402657518(path: JsonNode;
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
  var valid_402657520 = query.getOrDefault("Filters")
  valid_402657520 = validateParameter(valid_402657520, JArray, required = false,
                                      default = nil)
  if valid_402657520 != nil:
    section.add "Filters", valid_402657520
  var valid_402657521 = query.getOrDefault("MaxRecords")
  valid_402657521 = validateParameter(valid_402657521, JInt, required = false,
                                      default = nil)
  if valid_402657521 != nil:
    section.add "MaxRecords", valid_402657521
  var valid_402657522 = query.getOrDefault("Marker")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "Marker", valid_402657522
  var valid_402657523 = query.getOrDefault("Version")
  valid_402657523 = validateParameter(valid_402657523, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657523 != nil:
    section.add "Version", valid_402657523
  var valid_402657524 = query.getOrDefault("Action")
  valid_402657524 = validateParameter(valid_402657524, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_402657524 != nil:
    section.add "Action", valid_402657524
  var valid_402657525 = query.getOrDefault("DBSecurityGroupName")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "DBSecurityGroupName", valid_402657525
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
  var valid_402657526 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Security-Token", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Signature")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Signature", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657528
  var valid_402657529 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657529 = validateParameter(valid_402657529, JString,
                                      required = false, default = nil)
  if valid_402657529 != nil:
    section.add "X-Amz-Algorithm", valid_402657529
  var valid_402657530 = header.getOrDefault("X-Amz-Date")
  valid_402657530 = validateParameter(valid_402657530, JString,
                                      required = false, default = nil)
  if valid_402657530 != nil:
    section.add "X-Amz-Date", valid_402657530
  var valid_402657531 = header.getOrDefault("X-Amz-Credential")
  valid_402657531 = validateParameter(valid_402657531, JString,
                                      required = false, default = nil)
  if valid_402657531 != nil:
    section.add "X-Amz-Credential", valid_402657531
  var valid_402657532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657532 = validateParameter(valid_402657532, JString,
                                      required = false, default = nil)
  if valid_402657532 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657532
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657533: Call_GetDescribeDBSecurityGroups_402657517;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657533.validator(path, query, header, formData, body, _)
  let scheme = call_402657533.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657533.makeUrl(scheme.get, call_402657533.host, call_402657533.base,
                                   call_402657533.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657533, uri, valid, _)

proc call*(call_402657534: Call_GetDescribeDBSecurityGroups_402657517;
           Filters: JsonNode = nil; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeDBSecurityGroups";
           DBSecurityGroupName: string = ""): Recallable =
  ## getDescribeDBSecurityGroups
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   DBSecurityGroupName: string
  var query_402657535 = newJObject()
  if Filters != nil:
    query_402657535.add "Filters", Filters
  add(query_402657535, "MaxRecords", newJInt(MaxRecords))
  add(query_402657535, "Marker", newJString(Marker))
  add(query_402657535, "Version", newJString(Version))
  add(query_402657535, "Action", newJString(Action))
  add(query_402657535, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  result = call_402657534.call(nil, query_402657535, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_402657517(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_402657518, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_402657519,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_402657577 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSnapshots_402657579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_402657578(path: JsonNode; query: JsonNode;
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
  var valid_402657580 = query.getOrDefault("Version")
  valid_402657580 = validateParameter(valid_402657580, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657580 != nil:
    section.add "Version", valid_402657580
  var valid_402657581 = query.getOrDefault("Action")
  valid_402657581 = validateParameter(valid_402657581, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657581 != nil:
    section.add "Action", valid_402657581
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
  var valid_402657582 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657582 = validateParameter(valid_402657582, JString,
                                      required = false, default = nil)
  if valid_402657582 != nil:
    section.add "X-Amz-Security-Token", valid_402657582
  var valid_402657583 = header.getOrDefault("X-Amz-Signature")
  valid_402657583 = validateParameter(valid_402657583, JString,
                                      required = false, default = nil)
  if valid_402657583 != nil:
    section.add "X-Amz-Signature", valid_402657583
  var valid_402657584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657584 = validateParameter(valid_402657584, JString,
                                      required = false, default = nil)
  if valid_402657584 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657584
  var valid_402657585 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657585 = validateParameter(valid_402657585, JString,
                                      required = false, default = nil)
  if valid_402657585 != nil:
    section.add "X-Amz-Algorithm", valid_402657585
  var valid_402657586 = header.getOrDefault("X-Amz-Date")
  valid_402657586 = validateParameter(valid_402657586, JString,
                                      required = false, default = nil)
  if valid_402657586 != nil:
    section.add "X-Amz-Date", valid_402657586
  var valid_402657587 = header.getOrDefault("X-Amz-Credential")
  valid_402657587 = validateParameter(valid_402657587, JString,
                                      required = false, default = nil)
  if valid_402657587 != nil:
    section.add "X-Amz-Credential", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657588
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBInstanceIdentifier: JString
  ##   MaxRecords: JInt
  ##   DBSnapshotIdentifier: JString
  ##   SnapshotType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_402657589 = formData.getOrDefault("Marker")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "Marker", valid_402657589
  var valid_402657590 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "DBInstanceIdentifier", valid_402657590
  var valid_402657591 = formData.getOrDefault("MaxRecords")
  valid_402657591 = validateParameter(valid_402657591, JInt, required = false,
                                      default = nil)
  if valid_402657591 != nil:
    section.add "MaxRecords", valid_402657591
  var valid_402657592 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402657592 = validateParameter(valid_402657592, JString,
                                      required = false, default = nil)
  if valid_402657592 != nil:
    section.add "DBSnapshotIdentifier", valid_402657592
  var valid_402657593 = formData.getOrDefault("SnapshotType")
  valid_402657593 = validateParameter(valid_402657593, JString,
                                      required = false, default = nil)
  if valid_402657593 != nil:
    section.add "SnapshotType", valid_402657593
  var valid_402657594 = formData.getOrDefault("Filters")
  valid_402657594 = validateParameter(valid_402657594, JArray, required = false,
                                      default = nil)
  if valid_402657594 != nil:
    section.add "Filters", valid_402657594
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657595: Call_PostDescribeDBSnapshots_402657577;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657595.validator(path, query, header, formData, body, _)
  let scheme = call_402657595.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657595.makeUrl(scheme.get, call_402657595.host, call_402657595.base,
                                   call_402657595.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657595, uri, valid, _)

proc call*(call_402657596: Call_PostDescribeDBSnapshots_402657577;
           Marker: string = ""; Version: string = "2014-09-01";
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
  var query_402657597 = newJObject()
  var formData_402657598 = newJObject()
  add(formData_402657598, "Marker", newJString(Marker))
  add(query_402657597, "Version", newJString(Version))
  add(formData_402657598, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402657598, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657598, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402657598, "SnapshotType", newJString(SnapshotType))
  add(query_402657597, "Action", newJString(Action))
  if Filters != nil:
    formData_402657598.add "Filters", Filters
  result = call_402657596.call(nil, query_402657597, nil, formData_402657598,
                               nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_402657577(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_402657578, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_402657579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_402657556 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSnapshots_402657558(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_402657557(path: JsonNode; query: JsonNode;
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
  var valid_402657559 = query.getOrDefault("Filters")
  valid_402657559 = validateParameter(valid_402657559, JArray, required = false,
                                      default = nil)
  if valid_402657559 != nil:
    section.add "Filters", valid_402657559
  var valid_402657560 = query.getOrDefault("DBInstanceIdentifier")
  valid_402657560 = validateParameter(valid_402657560, JString,
                                      required = false, default = nil)
  if valid_402657560 != nil:
    section.add "DBInstanceIdentifier", valid_402657560
  var valid_402657561 = query.getOrDefault("MaxRecords")
  valid_402657561 = validateParameter(valid_402657561, JInt, required = false,
                                      default = nil)
  if valid_402657561 != nil:
    section.add "MaxRecords", valid_402657561
  var valid_402657562 = query.getOrDefault("Marker")
  valid_402657562 = validateParameter(valid_402657562, JString,
                                      required = false, default = nil)
  if valid_402657562 != nil:
    section.add "Marker", valid_402657562
  var valid_402657563 = query.getOrDefault("Version")
  valid_402657563 = validateParameter(valid_402657563, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657563 != nil:
    section.add "Version", valid_402657563
  var valid_402657564 = query.getOrDefault("SnapshotType")
  valid_402657564 = validateParameter(valid_402657564, JString,
                                      required = false, default = nil)
  if valid_402657564 != nil:
    section.add "SnapshotType", valid_402657564
  var valid_402657565 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402657565 = validateParameter(valid_402657565, JString,
                                      required = false, default = nil)
  if valid_402657565 != nil:
    section.add "DBSnapshotIdentifier", valid_402657565
  var valid_402657566 = query.getOrDefault("Action")
  valid_402657566 = validateParameter(valid_402657566, JString, required = true, default = newJString(
      "DescribeDBSnapshots"))
  if valid_402657566 != nil:
    section.add "Action", valid_402657566
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
  var valid_402657567 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657567 = validateParameter(valid_402657567, JString,
                                      required = false, default = nil)
  if valid_402657567 != nil:
    section.add "X-Amz-Security-Token", valid_402657567
  var valid_402657568 = header.getOrDefault("X-Amz-Signature")
  valid_402657568 = validateParameter(valid_402657568, JString,
                                      required = false, default = nil)
  if valid_402657568 != nil:
    section.add "X-Amz-Signature", valid_402657568
  var valid_402657569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657569 = validateParameter(valid_402657569, JString,
                                      required = false, default = nil)
  if valid_402657569 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657569
  var valid_402657570 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657570 = validateParameter(valid_402657570, JString,
                                      required = false, default = nil)
  if valid_402657570 != nil:
    section.add "X-Amz-Algorithm", valid_402657570
  var valid_402657571 = header.getOrDefault("X-Amz-Date")
  valid_402657571 = validateParameter(valid_402657571, JString,
                                      required = false, default = nil)
  if valid_402657571 != nil:
    section.add "X-Amz-Date", valid_402657571
  var valid_402657572 = header.getOrDefault("X-Amz-Credential")
  valid_402657572 = validateParameter(valid_402657572, JString,
                                      required = false, default = nil)
  if valid_402657572 != nil:
    section.add "X-Amz-Credential", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657574: Call_GetDescribeDBSnapshots_402657556;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657574.validator(path, query, header, formData, body, _)
  let scheme = call_402657574.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657574.makeUrl(scheme.get, call_402657574.host, call_402657574.base,
                                   call_402657574.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657574, uri, valid, _)

proc call*(call_402657575: Call_GetDescribeDBSnapshots_402657556;
           Filters: JsonNode = nil; DBInstanceIdentifier: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01"; SnapshotType: string = "";
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
  var query_402657576 = newJObject()
  if Filters != nil:
    query_402657576.add "Filters", Filters
  add(query_402657576, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402657576, "MaxRecords", newJInt(MaxRecords))
  add(query_402657576, "Marker", newJString(Marker))
  add(query_402657576, "Version", newJString(Version))
  add(query_402657576, "SnapshotType", newJString(SnapshotType))
  add(query_402657576, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402657576, "Action", newJString(Action))
  result = call_402657575.call(nil, query_402657576, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_402657556(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_402657557, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_402657558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_402657618 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeDBSubnetGroups_402657620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_402657619(path: JsonNode;
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
  var valid_402657621 = query.getOrDefault("Version")
  valid_402657621 = validateParameter(valid_402657621, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657621 != nil:
    section.add "Version", valid_402657621
  var valid_402657622 = query.getOrDefault("Action")
  valid_402657622 = validateParameter(valid_402657622, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657622 != nil:
    section.add "Action", valid_402657622
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
  var valid_402657623 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-Security-Token", valid_402657623
  var valid_402657624 = header.getOrDefault("X-Amz-Signature")
  valid_402657624 = validateParameter(valid_402657624, JString,
                                      required = false, default = nil)
  if valid_402657624 != nil:
    section.add "X-Amz-Signature", valid_402657624
  var valid_402657625 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657625 = validateParameter(valid_402657625, JString,
                                      required = false, default = nil)
  if valid_402657625 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657625
  var valid_402657626 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657626 = validateParameter(valid_402657626, JString,
                                      required = false, default = nil)
  if valid_402657626 != nil:
    section.add "X-Amz-Algorithm", valid_402657626
  var valid_402657627 = header.getOrDefault("X-Amz-Date")
  valid_402657627 = validateParameter(valid_402657627, JString,
                                      required = false, default = nil)
  if valid_402657627 != nil:
    section.add "X-Amz-Date", valid_402657627
  var valid_402657628 = header.getOrDefault("X-Amz-Credential")
  valid_402657628 = validateParameter(valid_402657628, JString,
                                      required = false, default = nil)
  if valid_402657628 != nil:
    section.add "X-Amz-Credential", valid_402657628
  var valid_402657629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657629 = validateParameter(valid_402657629, JString,
                                      required = false, default = nil)
  if valid_402657629 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657629
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657630 = formData.getOrDefault("Marker")
  valid_402657630 = validateParameter(valid_402657630, JString,
                                      required = false, default = nil)
  if valid_402657630 != nil:
    section.add "Marker", valid_402657630
  var valid_402657631 = formData.getOrDefault("DBSubnetGroupName")
  valid_402657631 = validateParameter(valid_402657631, JString,
                                      required = false, default = nil)
  if valid_402657631 != nil:
    section.add "DBSubnetGroupName", valid_402657631
  var valid_402657632 = formData.getOrDefault("MaxRecords")
  valid_402657632 = validateParameter(valid_402657632, JInt, required = false,
                                      default = nil)
  if valid_402657632 != nil:
    section.add "MaxRecords", valid_402657632
  var valid_402657633 = formData.getOrDefault("Filters")
  valid_402657633 = validateParameter(valid_402657633, JArray, required = false,
                                      default = nil)
  if valid_402657633 != nil:
    section.add "Filters", valid_402657633
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657634: Call_PostDescribeDBSubnetGroups_402657618;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657634.validator(path, query, header, formData, body, _)
  let scheme = call_402657634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657634.makeUrl(scheme.get, call_402657634.host, call_402657634.base,
                                   call_402657634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657634, uri, valid, _)

proc call*(call_402657635: Call_PostDescribeDBSubnetGroups_402657618;
           Marker: string = ""; DBSubnetGroupName: string = "";
           Version: string = "2014-09-01"; MaxRecords: int = 0;
           Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil): Recallable =
  ## postDescribeDBSubnetGroups
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657636 = newJObject()
  var formData_402657637 = newJObject()
  add(formData_402657637, "Marker", newJString(Marker))
  add(formData_402657637, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657636, "Version", newJString(Version))
  add(formData_402657637, "MaxRecords", newJInt(MaxRecords))
  add(query_402657636, "Action", newJString(Action))
  if Filters != nil:
    formData_402657637.add "Filters", Filters
  result = call_402657635.call(nil, query_402657636, nil, formData_402657637,
                               nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_402657618(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_402657619, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_402657620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_402657599 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeDBSubnetGroups_402657601(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_402657600(path: JsonNode;
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
  var valid_402657602 = query.getOrDefault("Filters")
  valid_402657602 = validateParameter(valid_402657602, JArray, required = false,
                                      default = nil)
  if valid_402657602 != nil:
    section.add "Filters", valid_402657602
  var valid_402657603 = query.getOrDefault("DBSubnetGroupName")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "DBSubnetGroupName", valid_402657603
  var valid_402657604 = query.getOrDefault("MaxRecords")
  valid_402657604 = validateParameter(valid_402657604, JInt, required = false,
                                      default = nil)
  if valid_402657604 != nil:
    section.add "MaxRecords", valid_402657604
  var valid_402657605 = query.getOrDefault("Marker")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "Marker", valid_402657605
  var valid_402657606 = query.getOrDefault("Version")
  valid_402657606 = validateParameter(valid_402657606, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657606 != nil:
    section.add "Version", valid_402657606
  var valid_402657607 = query.getOrDefault("Action")
  valid_402657607 = validateParameter(valid_402657607, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_402657607 != nil:
    section.add "Action", valid_402657607
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
  var valid_402657608 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657608 = validateParameter(valid_402657608, JString,
                                      required = false, default = nil)
  if valid_402657608 != nil:
    section.add "X-Amz-Security-Token", valid_402657608
  var valid_402657609 = header.getOrDefault("X-Amz-Signature")
  valid_402657609 = validateParameter(valid_402657609, JString,
                                      required = false, default = nil)
  if valid_402657609 != nil:
    section.add "X-Amz-Signature", valid_402657609
  var valid_402657610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657610 = validateParameter(valid_402657610, JString,
                                      required = false, default = nil)
  if valid_402657610 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657610
  var valid_402657611 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657611 = validateParameter(valid_402657611, JString,
                                      required = false, default = nil)
  if valid_402657611 != nil:
    section.add "X-Amz-Algorithm", valid_402657611
  var valid_402657612 = header.getOrDefault("X-Amz-Date")
  valid_402657612 = validateParameter(valid_402657612, JString,
                                      required = false, default = nil)
  if valid_402657612 != nil:
    section.add "X-Amz-Date", valid_402657612
  var valid_402657613 = header.getOrDefault("X-Amz-Credential")
  valid_402657613 = validateParameter(valid_402657613, JString,
                                      required = false, default = nil)
  if valid_402657613 != nil:
    section.add "X-Amz-Credential", valid_402657613
  var valid_402657614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657615: Call_GetDescribeDBSubnetGroups_402657599;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657615.validator(path, query, header, formData, body, _)
  let scheme = call_402657615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657615.makeUrl(scheme.get, call_402657615.host, call_402657615.base,
                                   call_402657615.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657615, uri, valid, _)

proc call*(call_402657616: Call_GetDescribeDBSubnetGroups_402657599;
           Filters: JsonNode = nil; DBSubnetGroupName: string = "";
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeDBSubnetGroups"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   Filters: JArray
  ##   DBSubnetGroupName: string
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657617 = newJObject()
  if Filters != nil:
    query_402657617.add "Filters", Filters
  add(query_402657617, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402657617, "MaxRecords", newJInt(MaxRecords))
  add(query_402657617, "Marker", newJString(Marker))
  add(query_402657617, "Version", newJString(Version))
  add(query_402657617, "Action", newJString(Action))
  result = call_402657616.call(nil, query_402657617, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_402657599(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_402657600, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_402657601,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_402657657 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEngineDefaultParameters_402657659(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_402657658(path: JsonNode;
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
  var valid_402657660 = query.getOrDefault("Version")
  valid_402657660 = validateParameter(valid_402657660, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657660 != nil:
    section.add "Version", valid_402657660
  var valid_402657661 = query.getOrDefault("Action")
  valid_402657661 = validateParameter(valid_402657661, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657661 != nil:
    section.add "Action", valid_402657661
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
  var valid_402657662 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657662 = validateParameter(valid_402657662, JString,
                                      required = false, default = nil)
  if valid_402657662 != nil:
    section.add "X-Amz-Security-Token", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Signature")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Signature", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Algorithm", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-Date")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-Date", valid_402657666
  var valid_402657667 = header.getOrDefault("X-Amz-Credential")
  valid_402657667 = validateParameter(valid_402657667, JString,
                                      required = false, default = nil)
  if valid_402657667 != nil:
    section.add "X-Amz-Credential", valid_402657667
  var valid_402657668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657668 = validateParameter(valid_402657668, JString,
                                      required = false, default = nil)
  if valid_402657668 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657668
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  section = newJObject()
  var valid_402657669 = formData.getOrDefault("Marker")
  valid_402657669 = validateParameter(valid_402657669, JString,
                                      required = false, default = nil)
  if valid_402657669 != nil:
    section.add "Marker", valid_402657669
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657670 = formData.getOrDefault("DBParameterGroupFamily")
  valid_402657670 = validateParameter(valid_402657670, JString, required = true,
                                      default = nil)
  if valid_402657670 != nil:
    section.add "DBParameterGroupFamily", valid_402657670
  var valid_402657671 = formData.getOrDefault("MaxRecords")
  valid_402657671 = validateParameter(valid_402657671, JInt, required = false,
                                      default = nil)
  if valid_402657671 != nil:
    section.add "MaxRecords", valid_402657671
  var valid_402657672 = formData.getOrDefault("Filters")
  valid_402657672 = validateParameter(valid_402657672, JArray, required = false,
                                      default = nil)
  if valid_402657672 != nil:
    section.add "Filters", valid_402657672
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657673: Call_PostDescribeEngineDefaultParameters_402657657;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657673.validator(path, query, header, formData, body, _)
  let scheme = call_402657673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657673.makeUrl(scheme.get, call_402657673.host, call_402657673.base,
                                   call_402657673.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657673, uri, valid, _)

proc call*(call_402657674: Call_PostDescribeEngineDefaultParameters_402657657;
           DBParameterGroupFamily: string; Marker: string = "";
           Version: string = "2014-09-01"; MaxRecords: int = 0;
           Action: string = "DescribeEngineDefaultParameters";
           Filters: JsonNode = nil): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657675 = newJObject()
  var formData_402657676 = newJObject()
  add(formData_402657676, "Marker", newJString(Marker))
  add(formData_402657676, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657675, "Version", newJString(Version))
  add(formData_402657676, "MaxRecords", newJInt(MaxRecords))
  add(query_402657675, "Action", newJString(Action))
  if Filters != nil:
    formData_402657676.add "Filters", Filters
  result = call_402657674.call(nil, query_402657675, nil, formData_402657676,
                               nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_402657657(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_402657658,
    base: "/", makeUrl: url_PostDescribeEngineDefaultParameters_402657659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_402657638 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEngineDefaultParameters_402657640(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_402657639(path: JsonNode;
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
  var valid_402657641 = query.getOrDefault("Filters")
  valid_402657641 = validateParameter(valid_402657641, JArray, required = false,
                                      default = nil)
  if valid_402657641 != nil:
    section.add "Filters", valid_402657641
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_402657642 = query.getOrDefault("DBParameterGroupFamily")
  valid_402657642 = validateParameter(valid_402657642, JString, required = true,
                                      default = nil)
  if valid_402657642 != nil:
    section.add "DBParameterGroupFamily", valid_402657642
  var valid_402657643 = query.getOrDefault("MaxRecords")
  valid_402657643 = validateParameter(valid_402657643, JInt, required = false,
                                      default = nil)
  if valid_402657643 != nil:
    section.add "MaxRecords", valid_402657643
  var valid_402657644 = query.getOrDefault("Marker")
  valid_402657644 = validateParameter(valid_402657644, JString,
                                      required = false, default = nil)
  if valid_402657644 != nil:
    section.add "Marker", valid_402657644
  var valid_402657645 = query.getOrDefault("Version")
  valid_402657645 = validateParameter(valid_402657645, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657645 != nil:
    section.add "Version", valid_402657645
  var valid_402657646 = query.getOrDefault("Action")
  valid_402657646 = validateParameter(valid_402657646, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_402657646 != nil:
    section.add "Action", valid_402657646
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
  var valid_402657647 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657647 = validateParameter(valid_402657647, JString,
                                      required = false, default = nil)
  if valid_402657647 != nil:
    section.add "X-Amz-Security-Token", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Signature")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Signature", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-Algorithm", valid_402657650
  var valid_402657651 = header.getOrDefault("X-Amz-Date")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Date", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-Credential")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-Credential", valid_402657652
  var valid_402657653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657654: Call_GetDescribeEngineDefaultParameters_402657638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657654.validator(path, query, header, formData, body, _)
  let scheme = call_402657654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657654.makeUrl(scheme.get, call_402657654.host, call_402657654.base,
                                   call_402657654.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657654, uri, valid, _)

proc call*(call_402657655: Call_GetDescribeEngineDefaultParameters_402657638;
           DBParameterGroupFamily: string; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DescribeEngineDefaultParameters"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   Filters: JArray
  ##   DBParameterGroupFamily: string (required)
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402657656 = newJObject()
  if Filters != nil:
    query_402657656.add "Filters", Filters
  add(query_402657656, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_402657656, "MaxRecords", newJInt(MaxRecords))
  add(query_402657656, "Marker", newJString(Marker))
  add(query_402657656, "Version", newJString(Version))
  add(query_402657656, "Action", newJString(Action))
  result = call_402657655.call(nil, query_402657656, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_402657638(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_402657639, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_402657640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_402657694 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventCategories_402657696(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_402657695(path: JsonNode;
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
  var valid_402657697 = query.getOrDefault("Version")
  valid_402657697 = validateParameter(valid_402657697, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657697 != nil:
    section.add "Version", valid_402657697
  var valid_402657698 = query.getOrDefault("Action")
  valid_402657698 = validateParameter(valid_402657698, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657698 != nil:
    section.add "Action", valid_402657698
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
  var valid_402657699 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657699 = validateParameter(valid_402657699, JString,
                                      required = false, default = nil)
  if valid_402657699 != nil:
    section.add "X-Amz-Security-Token", valid_402657699
  var valid_402657700 = header.getOrDefault("X-Amz-Signature")
  valid_402657700 = validateParameter(valid_402657700, JString,
                                      required = false, default = nil)
  if valid_402657700 != nil:
    section.add "X-Amz-Signature", valid_402657700
  var valid_402657701 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657701 = validateParameter(valid_402657701, JString,
                                      required = false, default = nil)
  if valid_402657701 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657701
  var valid_402657702 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657702 = validateParameter(valid_402657702, JString,
                                      required = false, default = nil)
  if valid_402657702 != nil:
    section.add "X-Amz-Algorithm", valid_402657702
  var valid_402657703 = header.getOrDefault("X-Amz-Date")
  valid_402657703 = validateParameter(valid_402657703, JString,
                                      required = false, default = nil)
  if valid_402657703 != nil:
    section.add "X-Amz-Date", valid_402657703
  var valid_402657704 = header.getOrDefault("X-Amz-Credential")
  valid_402657704 = validateParameter(valid_402657704, JString,
                                      required = false, default = nil)
  if valid_402657704 != nil:
    section.add "X-Amz-Credential", valid_402657704
  var valid_402657705 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657705 = validateParameter(valid_402657705, JString,
                                      required = false, default = nil)
  if valid_402657705 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657705
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Filters: JArray
  section = newJObject()
  var valid_402657706 = formData.getOrDefault("SourceType")
  valid_402657706 = validateParameter(valid_402657706, JString,
                                      required = false, default = nil)
  if valid_402657706 != nil:
    section.add "SourceType", valid_402657706
  var valid_402657707 = formData.getOrDefault("Filters")
  valid_402657707 = validateParameter(valid_402657707, JArray, required = false,
                                      default = nil)
  if valid_402657707 != nil:
    section.add "Filters", valid_402657707
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657708: Call_PostDescribeEventCategories_402657694;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657708.validator(path, query, header, formData, body, _)
  let scheme = call_402657708.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657708.makeUrl(scheme.get, call_402657708.host, call_402657708.base,
                                   call_402657708.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657708, uri, valid, _)

proc call*(call_402657709: Call_PostDescribeEventCategories_402657694;
           SourceType: string = ""; Version: string = "2014-09-01";
           Action: string = "DescribeEventCategories"; Filters: JsonNode = nil): Recallable =
  ## postDescribeEventCategories
  ##   SourceType: string
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Filters: JArray
  var query_402657710 = newJObject()
  var formData_402657711 = newJObject()
  add(formData_402657711, "SourceType", newJString(SourceType))
  add(query_402657710, "Version", newJString(Version))
  add(query_402657710, "Action", newJString(Action))
  if Filters != nil:
    formData_402657711.add "Filters", Filters
  result = call_402657709.call(nil, query_402657710, nil, formData_402657711,
                               nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_402657694(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_402657695, base: "/",
    makeUrl: url_PostDescribeEventCategories_402657696,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_402657677 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventCategories_402657679(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_402657678(path: JsonNode;
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
  var valid_402657680 = query.getOrDefault("Filters")
  valid_402657680 = validateParameter(valid_402657680, JArray, required = false,
                                      default = nil)
  if valid_402657680 != nil:
    section.add "Filters", valid_402657680
  var valid_402657681 = query.getOrDefault("Version")
  valid_402657681 = validateParameter(valid_402657681, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657681 != nil:
    section.add "Version", valid_402657681
  var valid_402657682 = query.getOrDefault("SourceType")
  valid_402657682 = validateParameter(valid_402657682, JString,
                                      required = false, default = nil)
  if valid_402657682 != nil:
    section.add "SourceType", valid_402657682
  var valid_402657683 = query.getOrDefault("Action")
  valid_402657683 = validateParameter(valid_402657683, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_402657683 != nil:
    section.add "Action", valid_402657683
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
  var valid_402657684 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657684 = validateParameter(valid_402657684, JString,
                                      required = false, default = nil)
  if valid_402657684 != nil:
    section.add "X-Amz-Security-Token", valid_402657684
  var valid_402657685 = header.getOrDefault("X-Amz-Signature")
  valid_402657685 = validateParameter(valid_402657685, JString,
                                      required = false, default = nil)
  if valid_402657685 != nil:
    section.add "X-Amz-Signature", valid_402657685
  var valid_402657686 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657686 = validateParameter(valid_402657686, JString,
                                      required = false, default = nil)
  if valid_402657686 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657686
  var valid_402657687 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657687 = validateParameter(valid_402657687, JString,
                                      required = false, default = nil)
  if valid_402657687 != nil:
    section.add "X-Amz-Algorithm", valid_402657687
  var valid_402657688 = header.getOrDefault("X-Amz-Date")
  valid_402657688 = validateParameter(valid_402657688, JString,
                                      required = false, default = nil)
  if valid_402657688 != nil:
    section.add "X-Amz-Date", valid_402657688
  var valid_402657689 = header.getOrDefault("X-Amz-Credential")
  valid_402657689 = validateParameter(valid_402657689, JString,
                                      required = false, default = nil)
  if valid_402657689 != nil:
    section.add "X-Amz-Credential", valid_402657689
  var valid_402657690 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657690 = validateParameter(valid_402657690, JString,
                                      required = false, default = nil)
  if valid_402657690 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657690
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657691: Call_GetDescribeEventCategories_402657677;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657691.validator(path, query, header, formData, body, _)
  let scheme = call_402657691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657691.makeUrl(scheme.get, call_402657691.host, call_402657691.base,
                                   call_402657691.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657691, uri, valid, _)

proc call*(call_402657692: Call_GetDescribeEventCategories_402657677;
           Filters: JsonNode = nil; Version: string = "2014-09-01";
           SourceType: string = ""; Action: string = "DescribeEventCategories"): Recallable =
  ## getDescribeEventCategories
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402657693 = newJObject()
  if Filters != nil:
    query_402657693.add "Filters", Filters
  add(query_402657693, "Version", newJString(Version))
  add(query_402657693, "SourceType", newJString(SourceType))
  add(query_402657693, "Action", newJString(Action))
  result = call_402657692.call(nil, query_402657693, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_402657677(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_402657678, base: "/",
    makeUrl: url_GetDescribeEventCategories_402657679,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_402657731 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEventSubscriptions_402657733(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_402657732(path: JsonNode;
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
  var valid_402657734 = query.getOrDefault("Version")
  valid_402657734 = validateParameter(valid_402657734, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657734 != nil:
    section.add "Version", valid_402657734
  var valid_402657735 = query.getOrDefault("Action")
  valid_402657735 = validateParameter(valid_402657735, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657735 != nil:
    section.add "Action", valid_402657735
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
  var valid_402657736 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657736 = validateParameter(valid_402657736, JString,
                                      required = false, default = nil)
  if valid_402657736 != nil:
    section.add "X-Amz-Security-Token", valid_402657736
  var valid_402657737 = header.getOrDefault("X-Amz-Signature")
  valid_402657737 = validateParameter(valid_402657737, JString,
                                      required = false, default = nil)
  if valid_402657737 != nil:
    section.add "X-Amz-Signature", valid_402657737
  var valid_402657738 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657738 = validateParameter(valid_402657738, JString,
                                      required = false, default = nil)
  if valid_402657738 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657738
  var valid_402657739 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657739 = validateParameter(valid_402657739, JString,
                                      required = false, default = nil)
  if valid_402657739 != nil:
    section.add "X-Amz-Algorithm", valid_402657739
  var valid_402657740 = header.getOrDefault("X-Amz-Date")
  valid_402657740 = validateParameter(valid_402657740, JString,
                                      required = false, default = nil)
  if valid_402657740 != nil:
    section.add "X-Amz-Date", valid_402657740
  var valid_402657741 = header.getOrDefault("X-Amz-Credential")
  valid_402657741 = validateParameter(valid_402657741, JString,
                                      required = false, default = nil)
  if valid_402657741 != nil:
    section.add "X-Amz-Credential", valid_402657741
  var valid_402657742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657742 = validateParameter(valid_402657742, JString,
                                      required = false, default = nil)
  if valid_402657742 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657742
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   SubscriptionName: JString
  section = newJObject()
  var valid_402657743 = formData.getOrDefault("Marker")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "Marker", valid_402657743
  var valid_402657744 = formData.getOrDefault("MaxRecords")
  valid_402657744 = validateParameter(valid_402657744, JInt, required = false,
                                      default = nil)
  if valid_402657744 != nil:
    section.add "MaxRecords", valid_402657744
  var valid_402657745 = formData.getOrDefault("Filters")
  valid_402657745 = validateParameter(valid_402657745, JArray, required = false,
                                      default = nil)
  if valid_402657745 != nil:
    section.add "Filters", valid_402657745
  var valid_402657746 = formData.getOrDefault("SubscriptionName")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "SubscriptionName", valid_402657746
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657747: Call_PostDescribeEventSubscriptions_402657731;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657747.validator(path, query, header, formData, body, _)
  let scheme = call_402657747.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657747.makeUrl(scheme.get, call_402657747.host, call_402657747.base,
                                   call_402657747.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657747, uri, valid, _)

proc call*(call_402657748: Call_PostDescribeEventSubscriptions_402657731;
           Marker: string = ""; Version: string = "2014-09-01";
           MaxRecords: int = 0; Action: string = "DescribeEventSubscriptions";
           Filters: JsonNode = nil; SubscriptionName: string = ""): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   Version: string (required)
  ##   MaxRecords: int
  ##   Action: string (required)
  ##   Filters: JArray
  ##   SubscriptionName: string
  var query_402657749 = newJObject()
  var formData_402657750 = newJObject()
  add(formData_402657750, "Marker", newJString(Marker))
  add(query_402657749, "Version", newJString(Version))
  add(formData_402657750, "MaxRecords", newJInt(MaxRecords))
  add(query_402657749, "Action", newJString(Action))
  if Filters != nil:
    formData_402657750.add "Filters", Filters
  add(formData_402657750, "SubscriptionName", newJString(SubscriptionName))
  result = call_402657748.call(nil, query_402657749, nil, formData_402657750,
                               nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_402657731(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_402657732, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_402657733,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_402657712 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEventSubscriptions_402657714(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_402657713(path: JsonNode;
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
  var valid_402657715 = query.getOrDefault("Filters")
  valid_402657715 = validateParameter(valid_402657715, JArray, required = false,
                                      default = nil)
  if valid_402657715 != nil:
    section.add "Filters", valid_402657715
  var valid_402657716 = query.getOrDefault("MaxRecords")
  valid_402657716 = validateParameter(valid_402657716, JInt, required = false,
                                      default = nil)
  if valid_402657716 != nil:
    section.add "MaxRecords", valid_402657716
  var valid_402657717 = query.getOrDefault("Marker")
  valid_402657717 = validateParameter(valid_402657717, JString,
                                      required = false, default = nil)
  if valid_402657717 != nil:
    section.add "Marker", valid_402657717
  var valid_402657718 = query.getOrDefault("Version")
  valid_402657718 = validateParameter(valid_402657718, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657718 != nil:
    section.add "Version", valid_402657718
  var valid_402657719 = query.getOrDefault("SubscriptionName")
  valid_402657719 = validateParameter(valid_402657719, JString,
                                      required = false, default = nil)
  if valid_402657719 != nil:
    section.add "SubscriptionName", valid_402657719
  var valid_402657720 = query.getOrDefault("Action")
  valid_402657720 = validateParameter(valid_402657720, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_402657720 != nil:
    section.add "Action", valid_402657720
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
  var valid_402657721 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657721 = validateParameter(valid_402657721, JString,
                                      required = false, default = nil)
  if valid_402657721 != nil:
    section.add "X-Amz-Security-Token", valid_402657721
  var valid_402657722 = header.getOrDefault("X-Amz-Signature")
  valid_402657722 = validateParameter(valid_402657722, JString,
                                      required = false, default = nil)
  if valid_402657722 != nil:
    section.add "X-Amz-Signature", valid_402657722
  var valid_402657723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657723 = validateParameter(valid_402657723, JString,
                                      required = false, default = nil)
  if valid_402657723 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657723
  var valid_402657724 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657724 = validateParameter(valid_402657724, JString,
                                      required = false, default = nil)
  if valid_402657724 != nil:
    section.add "X-Amz-Algorithm", valid_402657724
  var valid_402657725 = header.getOrDefault("X-Amz-Date")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "X-Amz-Date", valid_402657725
  var valid_402657726 = header.getOrDefault("X-Amz-Credential")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "X-Amz-Credential", valid_402657726
  var valid_402657727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657727 = validateParameter(valid_402657727, JString,
                                      required = false, default = nil)
  if valid_402657727 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657727
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657728: Call_GetDescribeEventSubscriptions_402657712;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657728.validator(path, query, header, formData, body, _)
  let scheme = call_402657728.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657728.makeUrl(scheme.get, call_402657728.host, call_402657728.base,
                                   call_402657728.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657728, uri, valid, _)

proc call*(call_402657729: Call_GetDescribeEventSubscriptions_402657712;
           Filters: JsonNode = nil; MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01"; SubscriptionName: string = "";
           Action: string = "DescribeEventSubscriptions"): Recallable =
  ## getDescribeEventSubscriptions
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Marker: string
  ##   Version: string (required)
  ##   SubscriptionName: string
  ##   Action: string (required)
  var query_402657730 = newJObject()
  if Filters != nil:
    query_402657730.add "Filters", Filters
  add(query_402657730, "MaxRecords", newJInt(MaxRecords))
  add(query_402657730, "Marker", newJString(Marker))
  add(query_402657730, "Version", newJString(Version))
  add(query_402657730, "SubscriptionName", newJString(SubscriptionName))
  add(query_402657730, "Action", newJString(Action))
  result = call_402657729.call(nil, query_402657730, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_402657712(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_402657713, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_402657714,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_402657775 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeEvents_402657777(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_402657776(path: JsonNode; query: JsonNode;
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
  var valid_402657778 = query.getOrDefault("Version")
  valid_402657778 = validateParameter(valid_402657778, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657778 != nil:
    section.add "Version", valid_402657778
  var valid_402657779 = query.getOrDefault("Action")
  valid_402657779 = validateParameter(valid_402657779, JString, required = true,
                                      default = newJString("DescribeEvents"))
  if valid_402657779 != nil:
    section.add "Action", valid_402657779
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
  var valid_402657780 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657780 = validateParameter(valid_402657780, JString,
                                      required = false, default = nil)
  if valid_402657780 != nil:
    section.add "X-Amz-Security-Token", valid_402657780
  var valid_402657781 = header.getOrDefault("X-Amz-Signature")
  valid_402657781 = validateParameter(valid_402657781, JString,
                                      required = false, default = nil)
  if valid_402657781 != nil:
    section.add "X-Amz-Signature", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-Algorithm", valid_402657783
  var valid_402657784 = header.getOrDefault("X-Amz-Date")
  valid_402657784 = validateParameter(valid_402657784, JString,
                                      required = false, default = nil)
  if valid_402657784 != nil:
    section.add "X-Amz-Date", valid_402657784
  var valid_402657785 = header.getOrDefault("X-Amz-Credential")
  valid_402657785 = validateParameter(valid_402657785, JString,
                                      required = false, default = nil)
  if valid_402657785 != nil:
    section.add "X-Amz-Credential", valid_402657785
  var valid_402657786 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657786 = validateParameter(valid_402657786, JString,
                                      required = false, default = nil)
  if valid_402657786 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657786
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
  var valid_402657787 = formData.getOrDefault("Marker")
  valid_402657787 = validateParameter(valid_402657787, JString,
                                      required = false, default = nil)
  if valid_402657787 != nil:
    section.add "Marker", valid_402657787
  var valid_402657788 = formData.getOrDefault("SourceType")
  valid_402657788 = validateParameter(valid_402657788, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657788 != nil:
    section.add "SourceType", valid_402657788
  var valid_402657789 = formData.getOrDefault("EventCategories")
  valid_402657789 = validateParameter(valid_402657789, JArray, required = false,
                                      default = nil)
  if valid_402657789 != nil:
    section.add "EventCategories", valid_402657789
  var valid_402657790 = formData.getOrDefault("Duration")
  valid_402657790 = validateParameter(valid_402657790, JInt, required = false,
                                      default = nil)
  if valid_402657790 != nil:
    section.add "Duration", valid_402657790
  var valid_402657791 = formData.getOrDefault("EndTime")
  valid_402657791 = validateParameter(valid_402657791, JString,
                                      required = false, default = nil)
  if valid_402657791 != nil:
    section.add "EndTime", valid_402657791
  var valid_402657792 = formData.getOrDefault("StartTime")
  valid_402657792 = validateParameter(valid_402657792, JString,
                                      required = false, default = nil)
  if valid_402657792 != nil:
    section.add "StartTime", valid_402657792
  var valid_402657793 = formData.getOrDefault("MaxRecords")
  valid_402657793 = validateParameter(valid_402657793, JInt, required = false,
                                      default = nil)
  if valid_402657793 != nil:
    section.add "MaxRecords", valid_402657793
  var valid_402657794 = formData.getOrDefault("SourceIdentifier")
  valid_402657794 = validateParameter(valid_402657794, JString,
                                      required = false, default = nil)
  if valid_402657794 != nil:
    section.add "SourceIdentifier", valid_402657794
  var valid_402657795 = formData.getOrDefault("Filters")
  valid_402657795 = validateParameter(valid_402657795, JArray, required = false,
                                      default = nil)
  if valid_402657795 != nil:
    section.add "Filters", valid_402657795
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657796: Call_PostDescribeEvents_402657775;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657796.validator(path, query, header, formData, body, _)
  let scheme = call_402657796.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657796.makeUrl(scheme.get, call_402657796.host, call_402657796.base,
                                   call_402657796.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657796, uri, valid, _)

proc call*(call_402657797: Call_PostDescribeEvents_402657775;
           Marker: string = ""; SourceType: string = "db-instance";
           EventCategories: JsonNode = nil; Version: string = "2014-09-01";
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
  var query_402657798 = newJObject()
  var formData_402657799 = newJObject()
  add(formData_402657799, "Marker", newJString(Marker))
  add(formData_402657799, "SourceType", newJString(SourceType))
  if EventCategories != nil:
    formData_402657799.add "EventCategories", EventCategories
  add(query_402657798, "Version", newJString(Version))
  add(formData_402657799, "Duration", newJInt(Duration))
  add(formData_402657799, "EndTime", newJString(EndTime))
  add(formData_402657799, "StartTime", newJString(StartTime))
  add(formData_402657799, "MaxRecords", newJInt(MaxRecords))
  add(query_402657798, "Action", newJString(Action))
  add(formData_402657799, "SourceIdentifier", newJString(SourceIdentifier))
  if Filters != nil:
    formData_402657799.add "Filters", Filters
  result = call_402657797.call(nil, query_402657798, nil, formData_402657799,
                               nil)

var postDescribeEvents* = Call_PostDescribeEvents_402657775(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_402657776, base: "/",
    makeUrl: url_PostDescribeEvents_402657777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_402657751 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeEvents_402657753(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_402657752(path: JsonNode; query: JsonNode;
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
  var valid_402657754 = query.getOrDefault("EndTime")
  valid_402657754 = validateParameter(valid_402657754, JString,
                                      required = false, default = nil)
  if valid_402657754 != nil:
    section.add "EndTime", valid_402657754
  var valid_402657755 = query.getOrDefault("Filters")
  valid_402657755 = validateParameter(valid_402657755, JArray, required = false,
                                      default = nil)
  if valid_402657755 != nil:
    section.add "Filters", valid_402657755
  var valid_402657756 = query.getOrDefault("SourceIdentifier")
  valid_402657756 = validateParameter(valid_402657756, JString,
                                      required = false, default = nil)
  if valid_402657756 != nil:
    section.add "SourceIdentifier", valid_402657756
  var valid_402657757 = query.getOrDefault("MaxRecords")
  valid_402657757 = validateParameter(valid_402657757, JInt, required = false,
                                      default = nil)
  if valid_402657757 != nil:
    section.add "MaxRecords", valid_402657757
  var valid_402657758 = query.getOrDefault("Marker")
  valid_402657758 = validateParameter(valid_402657758, JString,
                                      required = false, default = nil)
  if valid_402657758 != nil:
    section.add "Marker", valid_402657758
  var valid_402657759 = query.getOrDefault("EventCategories")
  valid_402657759 = validateParameter(valid_402657759, JArray, required = false,
                                      default = nil)
  if valid_402657759 != nil:
    section.add "EventCategories", valid_402657759
  var valid_402657760 = query.getOrDefault("Version")
  valid_402657760 = validateParameter(valid_402657760, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657760 != nil:
    section.add "Version", valid_402657760
  var valid_402657761 = query.getOrDefault("Duration")
  valid_402657761 = validateParameter(valid_402657761, JInt, required = false,
                                      default = nil)
  if valid_402657761 != nil:
    section.add "Duration", valid_402657761
  var valid_402657762 = query.getOrDefault("StartTime")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "StartTime", valid_402657762
  var valid_402657763 = query.getOrDefault("SourceType")
  valid_402657763 = validateParameter(valid_402657763, JString,
                                      required = false,
                                      default = newJString("db-instance"))
  if valid_402657763 != nil:
    section.add "SourceType", valid_402657763
  var valid_402657764 = query.getOrDefault("Action")
  valid_402657764 = validateParameter(valid_402657764, JString, required = true,
                                      default = newJString("DescribeEvents"))
  if valid_402657764 != nil:
    section.add "Action", valid_402657764
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
  var valid_402657765 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "X-Amz-Security-Token", valid_402657765
  var valid_402657766 = header.getOrDefault("X-Amz-Signature")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Signature", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-Algorithm", valid_402657768
  var valid_402657769 = header.getOrDefault("X-Amz-Date")
  valid_402657769 = validateParameter(valid_402657769, JString,
                                      required = false, default = nil)
  if valid_402657769 != nil:
    section.add "X-Amz-Date", valid_402657769
  var valid_402657770 = header.getOrDefault("X-Amz-Credential")
  valid_402657770 = validateParameter(valid_402657770, JString,
                                      required = false, default = nil)
  if valid_402657770 != nil:
    section.add "X-Amz-Credential", valid_402657770
  var valid_402657771 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657771 = validateParameter(valid_402657771, JString,
                                      required = false, default = nil)
  if valid_402657771 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657771
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657772: Call_GetDescribeEvents_402657751;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657772.validator(path, query, header, formData, body, _)
  let scheme = call_402657772.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657772.makeUrl(scheme.get, call_402657772.host, call_402657772.base,
                                   call_402657772.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657772, uri, valid, _)

proc call*(call_402657773: Call_GetDescribeEvents_402657751;
           EndTime: string = ""; Filters: JsonNode = nil;
           SourceIdentifier: string = ""; MaxRecords: int = 0;
           Marker: string = ""; EventCategories: JsonNode = nil;
           Version: string = "2014-09-01"; Duration: int = 0;
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
  var query_402657774 = newJObject()
  add(query_402657774, "EndTime", newJString(EndTime))
  if Filters != nil:
    query_402657774.add "Filters", Filters
  add(query_402657774, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402657774, "MaxRecords", newJInt(MaxRecords))
  add(query_402657774, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_402657774.add "EventCategories", EventCategories
  add(query_402657774, "Version", newJString(Version))
  add(query_402657774, "Duration", newJInt(Duration))
  add(query_402657774, "StartTime", newJString(StartTime))
  add(query_402657774, "SourceType", newJString(SourceType))
  add(query_402657774, "Action", newJString(Action))
  result = call_402657773.call(nil, query_402657774, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_402657751(
    name: "getDescribeEvents", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_GetDescribeEvents_402657752, base: "/",
    makeUrl: url_GetDescribeEvents_402657753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_402657820 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroupOptions_402657822(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_402657821(path: JsonNode;
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
  var valid_402657823 = query.getOrDefault("Version")
  valid_402657823 = validateParameter(valid_402657823, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657823 != nil:
    section.add "Version", valid_402657823
  var valid_402657824 = query.getOrDefault("Action")
  valid_402657824 = validateParameter(valid_402657824, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657824 != nil:
    section.add "Action", valid_402657824
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
  var valid_402657825 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Security-Token", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-Signature")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Signature", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Algorithm", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Date")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Date", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-Credential")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-Credential", valid_402657830
  var valid_402657831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657831
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657832 = formData.getOrDefault("Marker")
  valid_402657832 = validateParameter(valid_402657832, JString,
                                      required = false, default = nil)
  if valid_402657832 != nil:
    section.add "Marker", valid_402657832
  assert formData != nil,
         "formData argument is necessary due to required `EngineName` field"
  var valid_402657833 = formData.getOrDefault("EngineName")
  valid_402657833 = validateParameter(valid_402657833, JString, required = true,
                                      default = nil)
  if valid_402657833 != nil:
    section.add "EngineName", valid_402657833
  var valid_402657834 = formData.getOrDefault("MaxRecords")
  valid_402657834 = validateParameter(valid_402657834, JInt, required = false,
                                      default = nil)
  if valid_402657834 != nil:
    section.add "MaxRecords", valid_402657834
  var valid_402657835 = formData.getOrDefault("Filters")
  valid_402657835 = validateParameter(valid_402657835, JArray, required = false,
                                      default = nil)
  if valid_402657835 != nil:
    section.add "Filters", valid_402657835
  var valid_402657836 = formData.getOrDefault("MajorEngineVersion")
  valid_402657836 = validateParameter(valid_402657836, JString,
                                      required = false, default = nil)
  if valid_402657836 != nil:
    section.add "MajorEngineVersion", valid_402657836
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657837: Call_PostDescribeOptionGroupOptions_402657820;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657837.validator(path, query, header, formData, body, _)
  let scheme = call_402657837.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657837.makeUrl(scheme.get, call_402657837.host, call_402657837.base,
                                   call_402657837.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657837, uri, valid, _)

proc call*(call_402657838: Call_PostDescribeOptionGroupOptions_402657820;
           EngineName: string; Marker: string = "";
           Version: string = "2014-09-01"; MaxRecords: int = 0;
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
  var query_402657839 = newJObject()
  var formData_402657840 = newJObject()
  add(formData_402657840, "Marker", newJString(Marker))
  add(formData_402657840, "EngineName", newJString(EngineName))
  add(query_402657839, "Version", newJString(Version))
  add(formData_402657840, "MaxRecords", newJInt(MaxRecords))
  add(query_402657839, "Action", newJString(Action))
  if Filters != nil:
    formData_402657840.add "Filters", Filters
  add(formData_402657840, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657838.call(nil, query_402657839, nil, formData_402657840,
                               nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_402657820(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_402657821, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_402657822,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_402657800 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroupOptions_402657802(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_402657801(path: JsonNode;
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
  var valid_402657803 = query.getOrDefault("Filters")
  valid_402657803 = validateParameter(valid_402657803, JArray, required = false,
                                      default = nil)
  if valid_402657803 != nil:
    section.add "Filters", valid_402657803
  var valid_402657804 = query.getOrDefault("MaxRecords")
  valid_402657804 = validateParameter(valid_402657804, JInt, required = false,
                                      default = nil)
  if valid_402657804 != nil:
    section.add "MaxRecords", valid_402657804
  var valid_402657805 = query.getOrDefault("Marker")
  valid_402657805 = validateParameter(valid_402657805, JString,
                                      required = false, default = nil)
  if valid_402657805 != nil:
    section.add "Marker", valid_402657805
  var valid_402657806 = query.getOrDefault("Version")
  valid_402657806 = validateParameter(valid_402657806, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657806 != nil:
    section.add "Version", valid_402657806
  var valid_402657807 = query.getOrDefault("Action")
  valid_402657807 = validateParameter(valid_402657807, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_402657807 != nil:
    section.add "Action", valid_402657807
  var valid_402657808 = query.getOrDefault("EngineName")
  valid_402657808 = validateParameter(valid_402657808, JString, required = true,
                                      default = nil)
  if valid_402657808 != nil:
    section.add "EngineName", valid_402657808
  var valid_402657809 = query.getOrDefault("MajorEngineVersion")
  valid_402657809 = validateParameter(valid_402657809, JString,
                                      required = false, default = nil)
  if valid_402657809 != nil:
    section.add "MajorEngineVersion", valid_402657809
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
  var valid_402657810 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-Security-Token", valid_402657810
  var valid_402657811 = header.getOrDefault("X-Amz-Signature")
  valid_402657811 = validateParameter(valid_402657811, JString,
                                      required = false, default = nil)
  if valid_402657811 != nil:
    section.add "X-Amz-Signature", valid_402657811
  var valid_402657812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657812 = validateParameter(valid_402657812, JString,
                                      required = false, default = nil)
  if valid_402657812 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Algorithm", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Date")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Date", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-Credential")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-Credential", valid_402657815
  var valid_402657816 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657816 = validateParameter(valid_402657816, JString,
                                      required = false, default = nil)
  if valid_402657816 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657816
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657817: Call_GetDescribeOptionGroupOptions_402657800;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657817.validator(path, query, header, formData, body, _)
  let scheme = call_402657817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657817.makeUrl(scheme.get, call_402657817.host, call_402657817.base,
                                   call_402657817.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657817, uri, valid, _)

proc call*(call_402657818: Call_GetDescribeOptionGroupOptions_402657800;
           EngineName: string; Filters: JsonNode = nil; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2014-09-01";
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
  var query_402657819 = newJObject()
  if Filters != nil:
    query_402657819.add "Filters", Filters
  add(query_402657819, "MaxRecords", newJInt(MaxRecords))
  add(query_402657819, "Marker", newJString(Marker))
  add(query_402657819, "Version", newJString(Version))
  add(query_402657819, "Action", newJString(Action))
  add(query_402657819, "EngineName", newJString(EngineName))
  add(query_402657819, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657818.call(nil, query_402657819, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_402657800(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_402657801, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_402657802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_402657862 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOptionGroups_402657864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_402657863(path: JsonNode;
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
  var valid_402657865 = query.getOrDefault("Version")
  valid_402657865 = validateParameter(valid_402657865, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657865 != nil:
    section.add "Version", valid_402657865
  var valid_402657866 = query.getOrDefault("Action")
  valid_402657866 = validateParameter(valid_402657866, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657866 != nil:
    section.add "Action", valid_402657866
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
  var valid_402657867 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657867 = validateParameter(valid_402657867, JString,
                                      required = false, default = nil)
  if valid_402657867 != nil:
    section.add "X-Amz-Security-Token", valid_402657867
  var valid_402657868 = header.getOrDefault("X-Amz-Signature")
  valid_402657868 = validateParameter(valid_402657868, JString,
                                      required = false, default = nil)
  if valid_402657868 != nil:
    section.add "X-Amz-Signature", valid_402657868
  var valid_402657869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657869 = validateParameter(valid_402657869, JString,
                                      required = false, default = nil)
  if valid_402657869 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657869
  var valid_402657870 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657870 = validateParameter(valid_402657870, JString,
                                      required = false, default = nil)
  if valid_402657870 != nil:
    section.add "X-Amz-Algorithm", valid_402657870
  var valid_402657871 = header.getOrDefault("X-Amz-Date")
  valid_402657871 = validateParameter(valid_402657871, JString,
                                      required = false, default = nil)
  if valid_402657871 != nil:
    section.add "X-Amz-Date", valid_402657871
  var valid_402657872 = header.getOrDefault("X-Amz-Credential")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "X-Amz-Credential", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657873
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   EngineName: JString
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Filters: JArray
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_402657874 = formData.getOrDefault("Marker")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "Marker", valid_402657874
  var valid_402657875 = formData.getOrDefault("EngineName")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "EngineName", valid_402657875
  var valid_402657876 = formData.getOrDefault("MaxRecords")
  valid_402657876 = validateParameter(valid_402657876, JInt, required = false,
                                      default = nil)
  if valid_402657876 != nil:
    section.add "MaxRecords", valid_402657876
  var valid_402657877 = formData.getOrDefault("OptionGroupName")
  valid_402657877 = validateParameter(valid_402657877, JString,
                                      required = false, default = nil)
  if valid_402657877 != nil:
    section.add "OptionGroupName", valid_402657877
  var valid_402657878 = formData.getOrDefault("Filters")
  valid_402657878 = validateParameter(valid_402657878, JArray, required = false,
                                      default = nil)
  if valid_402657878 != nil:
    section.add "Filters", valid_402657878
  var valid_402657879 = formData.getOrDefault("MajorEngineVersion")
  valid_402657879 = validateParameter(valid_402657879, JString,
                                      required = false, default = nil)
  if valid_402657879 != nil:
    section.add "MajorEngineVersion", valid_402657879
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657880: Call_PostDescribeOptionGroups_402657862;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657880.validator(path, query, header, formData, body, _)
  let scheme = call_402657880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657880.makeUrl(scheme.get, call_402657880.host, call_402657880.base,
                                   call_402657880.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657880, uri, valid, _)

proc call*(call_402657881: Call_PostDescribeOptionGroups_402657862;
           Marker: string = ""; EngineName: string = "";
           Version: string = "2014-09-01"; MaxRecords: int = 0;
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
  var query_402657882 = newJObject()
  var formData_402657883 = newJObject()
  add(formData_402657883, "Marker", newJString(Marker))
  add(formData_402657883, "EngineName", newJString(EngineName))
  add(query_402657882, "Version", newJString(Version))
  add(formData_402657883, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657883, "OptionGroupName", newJString(OptionGroupName))
  add(query_402657882, "Action", newJString(Action))
  if Filters != nil:
    formData_402657883.add "Filters", Filters
  add(formData_402657883, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657881.call(nil, query_402657882, nil, formData_402657883,
                               nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_402657862(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_402657863, base: "/",
    makeUrl: url_PostDescribeOptionGroups_402657864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_402657841 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOptionGroups_402657843(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_402657842(path: JsonNode; query: JsonNode;
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
  var valid_402657844 = query.getOrDefault("OptionGroupName")
  valid_402657844 = validateParameter(valid_402657844, JString,
                                      required = false, default = nil)
  if valid_402657844 != nil:
    section.add "OptionGroupName", valid_402657844
  var valid_402657845 = query.getOrDefault("Filters")
  valid_402657845 = validateParameter(valid_402657845, JArray, required = false,
                                      default = nil)
  if valid_402657845 != nil:
    section.add "Filters", valid_402657845
  var valid_402657846 = query.getOrDefault("MaxRecords")
  valid_402657846 = validateParameter(valid_402657846, JInt, required = false,
                                      default = nil)
  if valid_402657846 != nil:
    section.add "MaxRecords", valid_402657846
  var valid_402657847 = query.getOrDefault("Marker")
  valid_402657847 = validateParameter(valid_402657847, JString,
                                      required = false, default = nil)
  if valid_402657847 != nil:
    section.add "Marker", valid_402657847
  var valid_402657848 = query.getOrDefault("Version")
  valid_402657848 = validateParameter(valid_402657848, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657848 != nil:
    section.add "Version", valid_402657848
  var valid_402657849 = query.getOrDefault("Action")
  valid_402657849 = validateParameter(valid_402657849, JString, required = true, default = newJString(
      "DescribeOptionGroups"))
  if valid_402657849 != nil:
    section.add "Action", valid_402657849
  var valid_402657850 = query.getOrDefault("EngineName")
  valid_402657850 = validateParameter(valid_402657850, JString,
                                      required = false, default = nil)
  if valid_402657850 != nil:
    section.add "EngineName", valid_402657850
  var valid_402657851 = query.getOrDefault("MajorEngineVersion")
  valid_402657851 = validateParameter(valid_402657851, JString,
                                      required = false, default = nil)
  if valid_402657851 != nil:
    section.add "MajorEngineVersion", valid_402657851
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
  var valid_402657852 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657852 = validateParameter(valid_402657852, JString,
                                      required = false, default = nil)
  if valid_402657852 != nil:
    section.add "X-Amz-Security-Token", valid_402657852
  var valid_402657853 = header.getOrDefault("X-Amz-Signature")
  valid_402657853 = validateParameter(valid_402657853, JString,
                                      required = false, default = nil)
  if valid_402657853 != nil:
    section.add "X-Amz-Signature", valid_402657853
  var valid_402657854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657854 = validateParameter(valid_402657854, JString,
                                      required = false, default = nil)
  if valid_402657854 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657854
  var valid_402657855 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "X-Amz-Algorithm", valid_402657855
  var valid_402657856 = header.getOrDefault("X-Amz-Date")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "X-Amz-Date", valid_402657856
  var valid_402657857 = header.getOrDefault("X-Amz-Credential")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Credential", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657859: Call_GetDescribeOptionGroups_402657841;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657859.validator(path, query, header, formData, body, _)
  let scheme = call_402657859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657859.makeUrl(scheme.get, call_402657859.host, call_402657859.base,
                                   call_402657859.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657859, uri, valid, _)

proc call*(call_402657860: Call_GetDescribeOptionGroups_402657841;
           OptionGroupName: string = ""; Filters: JsonNode = nil;
           MaxRecords: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
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
  var query_402657861 = newJObject()
  add(query_402657861, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_402657861.add "Filters", Filters
  add(query_402657861, "MaxRecords", newJInt(MaxRecords))
  add(query_402657861, "Marker", newJString(Marker))
  add(query_402657861, "Version", newJString(Version))
  add(query_402657861, "Action", newJString(Action))
  add(query_402657861, "EngineName", newJString(EngineName))
  add(query_402657861, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_402657860.call(nil, query_402657861, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_402657841(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_402657842, base: "/",
    makeUrl: url_GetDescribeOptionGroups_402657843,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_402657907 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeOrderableDBInstanceOptions_402657909(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_402657908(path: JsonNode;
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
  var valid_402657910 = query.getOrDefault("Version")
  valid_402657910 = validateParameter(valid_402657910, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657910 != nil:
    section.add "Version", valid_402657910
  var valid_402657911 = query.getOrDefault("Action")
  valid_402657911 = validateParameter(valid_402657911, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657911 != nil:
    section.add "Action", valid_402657911
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
  var valid_402657912 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657912 = validateParameter(valid_402657912, JString,
                                      required = false, default = nil)
  if valid_402657912 != nil:
    section.add "X-Amz-Security-Token", valid_402657912
  var valid_402657913 = header.getOrDefault("X-Amz-Signature")
  valid_402657913 = validateParameter(valid_402657913, JString,
                                      required = false, default = nil)
  if valid_402657913 != nil:
    section.add "X-Amz-Signature", valid_402657913
  var valid_402657914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657914 = validateParameter(valid_402657914, JString,
                                      required = false, default = nil)
  if valid_402657914 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657914
  var valid_402657915 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-Algorithm", valid_402657915
  var valid_402657916 = header.getOrDefault("X-Amz-Date")
  valid_402657916 = validateParameter(valid_402657916, JString,
                                      required = false, default = nil)
  if valid_402657916 != nil:
    section.add "X-Amz-Date", valid_402657916
  var valid_402657917 = header.getOrDefault("X-Amz-Credential")
  valid_402657917 = validateParameter(valid_402657917, JString,
                                      required = false, default = nil)
  if valid_402657917 != nil:
    section.add "X-Amz-Credential", valid_402657917
  var valid_402657918 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657918 = validateParameter(valid_402657918, JString,
                                      required = false, default = nil)
  if valid_402657918 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657918
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
  var valid_402657919 = formData.getOrDefault("Marker")
  valid_402657919 = validateParameter(valid_402657919, JString,
                                      required = false, default = nil)
  if valid_402657919 != nil:
    section.add "Marker", valid_402657919
  var valid_402657920 = formData.getOrDefault("Vpc")
  valid_402657920 = validateParameter(valid_402657920, JBool, required = false,
                                      default = nil)
  if valid_402657920 != nil:
    section.add "Vpc", valid_402657920
  assert formData != nil,
         "formData argument is necessary due to required `Engine` field"
  var valid_402657921 = formData.getOrDefault("Engine")
  valid_402657921 = validateParameter(valid_402657921, JString, required = true,
                                      default = nil)
  if valid_402657921 != nil:
    section.add "Engine", valid_402657921
  var valid_402657922 = formData.getOrDefault("DBInstanceClass")
  valid_402657922 = validateParameter(valid_402657922, JString,
                                      required = false, default = nil)
  if valid_402657922 != nil:
    section.add "DBInstanceClass", valid_402657922
  var valid_402657923 = formData.getOrDefault("LicenseModel")
  valid_402657923 = validateParameter(valid_402657923, JString,
                                      required = false, default = nil)
  if valid_402657923 != nil:
    section.add "LicenseModel", valid_402657923
  var valid_402657924 = formData.getOrDefault("MaxRecords")
  valid_402657924 = validateParameter(valid_402657924, JInt, required = false,
                                      default = nil)
  if valid_402657924 != nil:
    section.add "MaxRecords", valid_402657924
  var valid_402657925 = formData.getOrDefault("Filters")
  valid_402657925 = validateParameter(valid_402657925, JArray, required = false,
                                      default = nil)
  if valid_402657925 != nil:
    section.add "Filters", valid_402657925
  var valid_402657926 = formData.getOrDefault("EngineVersion")
  valid_402657926 = validateParameter(valid_402657926, JString,
                                      required = false, default = nil)
  if valid_402657926 != nil:
    section.add "EngineVersion", valid_402657926
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657927: Call_PostDescribeOrderableDBInstanceOptions_402657907;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657927.validator(path, query, header, formData, body, _)
  let scheme = call_402657927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657927.makeUrl(scheme.get, call_402657927.host, call_402657927.base,
                                   call_402657927.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657927, uri, valid, _)

proc call*(call_402657928: Call_PostDescribeOrderableDBInstanceOptions_402657907;
           Engine: string; Marker: string = ""; Vpc: bool = false;
           Version: string = "2014-09-01"; DBInstanceClass: string = "";
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
  var query_402657929 = newJObject()
  var formData_402657930 = newJObject()
  add(formData_402657930, "Marker", newJString(Marker))
  add(formData_402657930, "Vpc", newJBool(Vpc))
  add(formData_402657930, "Engine", newJString(Engine))
  add(query_402657929, "Version", newJString(Version))
  add(formData_402657930, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657930, "LicenseModel", newJString(LicenseModel))
  add(formData_402657930, "MaxRecords", newJInt(MaxRecords))
  add(query_402657929, "Action", newJString(Action))
  if Filters != nil:
    formData_402657930.add "Filters", Filters
  add(formData_402657930, "EngineVersion", newJString(EngineVersion))
  result = call_402657928.call(nil, query_402657929, nil, formData_402657930,
                               nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_402657907(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_402657908,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_402657909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_402657884 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeOrderableDBInstanceOptions_402657886(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_402657885(path: JsonNode;
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
  var valid_402657887 = query.getOrDefault("Filters")
  valid_402657887 = validateParameter(valid_402657887, JArray, required = false,
                                      default = nil)
  if valid_402657887 != nil:
    section.add "Filters", valid_402657887
  var valid_402657888 = query.getOrDefault("MaxRecords")
  valid_402657888 = validateParameter(valid_402657888, JInt, required = false,
                                      default = nil)
  if valid_402657888 != nil:
    section.add "MaxRecords", valid_402657888
  var valid_402657889 = query.getOrDefault("Marker")
  valid_402657889 = validateParameter(valid_402657889, JString,
                                      required = false, default = nil)
  if valid_402657889 != nil:
    section.add "Marker", valid_402657889
  var valid_402657890 = query.getOrDefault("Version")
  valid_402657890 = validateParameter(valid_402657890, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657890 != nil:
    section.add "Version", valid_402657890
  var valid_402657891 = query.getOrDefault("EngineVersion")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "EngineVersion", valid_402657891
  var valid_402657892 = query.getOrDefault("Vpc")
  valid_402657892 = validateParameter(valid_402657892, JBool, required = false,
                                      default = nil)
  if valid_402657892 != nil:
    section.add "Vpc", valid_402657892
  var valid_402657893 = query.getOrDefault("Engine")
  valid_402657893 = validateParameter(valid_402657893, JString, required = true,
                                      default = nil)
  if valid_402657893 != nil:
    section.add "Engine", valid_402657893
  var valid_402657894 = query.getOrDefault("DBInstanceClass")
  valid_402657894 = validateParameter(valid_402657894, JString,
                                      required = false, default = nil)
  if valid_402657894 != nil:
    section.add "DBInstanceClass", valid_402657894
  var valid_402657895 = query.getOrDefault("Action")
  valid_402657895 = validateParameter(valid_402657895, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_402657895 != nil:
    section.add "Action", valid_402657895
  var valid_402657896 = query.getOrDefault("LicenseModel")
  valid_402657896 = validateParameter(valid_402657896, JString,
                                      required = false, default = nil)
  if valid_402657896 != nil:
    section.add "LicenseModel", valid_402657896
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
  var valid_402657897 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657897 = validateParameter(valid_402657897, JString,
                                      required = false, default = nil)
  if valid_402657897 != nil:
    section.add "X-Amz-Security-Token", valid_402657897
  var valid_402657898 = header.getOrDefault("X-Amz-Signature")
  valid_402657898 = validateParameter(valid_402657898, JString,
                                      required = false, default = nil)
  if valid_402657898 != nil:
    section.add "X-Amz-Signature", valid_402657898
  var valid_402657899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657899 = validateParameter(valid_402657899, JString,
                                      required = false, default = nil)
  if valid_402657899 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657899
  var valid_402657900 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657900 = validateParameter(valid_402657900, JString,
                                      required = false, default = nil)
  if valid_402657900 != nil:
    section.add "X-Amz-Algorithm", valid_402657900
  var valid_402657901 = header.getOrDefault("X-Amz-Date")
  valid_402657901 = validateParameter(valid_402657901, JString,
                                      required = false, default = nil)
  if valid_402657901 != nil:
    section.add "X-Amz-Date", valid_402657901
  var valid_402657902 = header.getOrDefault("X-Amz-Credential")
  valid_402657902 = validateParameter(valid_402657902, JString,
                                      required = false, default = nil)
  if valid_402657902 != nil:
    section.add "X-Amz-Credential", valid_402657902
  var valid_402657903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657903 = validateParameter(valid_402657903, JString,
                                      required = false, default = nil)
  if valid_402657903 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657904: Call_GetDescribeOrderableDBInstanceOptions_402657884;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657904.validator(path, query, header, formData, body, _)
  let scheme = call_402657904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657904.makeUrl(scheme.get, call_402657904.host, call_402657904.base,
                                   call_402657904.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657904, uri, valid, _)

proc call*(call_402657905: Call_GetDescribeOrderableDBInstanceOptions_402657884;
           Engine: string; Filters: JsonNode = nil; MaxRecords: int = 0;
           Marker: string = ""; Version: string = "2014-09-01";
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
  var query_402657906 = newJObject()
  if Filters != nil:
    query_402657906.add "Filters", Filters
  add(query_402657906, "MaxRecords", newJInt(MaxRecords))
  add(query_402657906, "Marker", newJString(Marker))
  add(query_402657906, "Version", newJString(Version))
  add(query_402657906, "EngineVersion", newJString(EngineVersion))
  add(query_402657906, "Vpc", newJBool(Vpc))
  add(query_402657906, "Engine", newJString(Engine))
  add(query_402657906, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657906, "Action", newJString(Action))
  add(query_402657906, "LicenseModel", newJString(LicenseModel))
  result = call_402657905.call(nil, query_402657906, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_402657884(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_402657885,
    base: "/", makeUrl: url_GetDescribeOrderableDBInstanceOptions_402657886,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_402657956 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstances_402657958(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_402657957(path: JsonNode;
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
  var valid_402657959 = query.getOrDefault("Version")
  valid_402657959 = validateParameter(valid_402657959, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657959 != nil:
    section.add "Version", valid_402657959
  var valid_402657960 = query.getOrDefault("Action")
  valid_402657960 = validateParameter(valid_402657960, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657960 != nil:
    section.add "Action", valid_402657960
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
  var valid_402657961 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657961 = validateParameter(valid_402657961, JString,
                                      required = false, default = nil)
  if valid_402657961 != nil:
    section.add "X-Amz-Security-Token", valid_402657961
  var valid_402657962 = header.getOrDefault("X-Amz-Signature")
  valid_402657962 = validateParameter(valid_402657962, JString,
                                      required = false, default = nil)
  if valid_402657962 != nil:
    section.add "X-Amz-Signature", valid_402657962
  var valid_402657963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657963 = validateParameter(valid_402657963, JString,
                                      required = false, default = nil)
  if valid_402657963 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657963
  var valid_402657964 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657964 = validateParameter(valid_402657964, JString,
                                      required = false, default = nil)
  if valid_402657964 != nil:
    section.add "X-Amz-Algorithm", valid_402657964
  var valid_402657965 = header.getOrDefault("X-Amz-Date")
  valid_402657965 = validateParameter(valid_402657965, JString,
                                      required = false, default = nil)
  if valid_402657965 != nil:
    section.add "X-Amz-Date", valid_402657965
  var valid_402657966 = header.getOrDefault("X-Amz-Credential")
  valid_402657966 = validateParameter(valid_402657966, JString,
                                      required = false, default = nil)
  if valid_402657966 != nil:
    section.add "X-Amz-Credential", valid_402657966
  var valid_402657967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657967 = validateParameter(valid_402657967, JString,
                                      required = false, default = nil)
  if valid_402657967 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657967
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
  var valid_402657968 = formData.getOrDefault("Marker")
  valid_402657968 = validateParameter(valid_402657968, JString,
                                      required = false, default = nil)
  if valid_402657968 != nil:
    section.add "Marker", valid_402657968
  var valid_402657969 = formData.getOrDefault("OfferingType")
  valid_402657969 = validateParameter(valid_402657969, JString,
                                      required = false, default = nil)
  if valid_402657969 != nil:
    section.add "OfferingType", valid_402657969
  var valid_402657970 = formData.getOrDefault("ProductDescription")
  valid_402657970 = validateParameter(valid_402657970, JString,
                                      required = false, default = nil)
  if valid_402657970 != nil:
    section.add "ProductDescription", valid_402657970
  var valid_402657971 = formData.getOrDefault("DBInstanceClass")
  valid_402657971 = validateParameter(valid_402657971, JString,
                                      required = false, default = nil)
  if valid_402657971 != nil:
    section.add "DBInstanceClass", valid_402657971
  var valid_402657972 = formData.getOrDefault("Duration")
  valid_402657972 = validateParameter(valid_402657972, JString,
                                      required = false, default = nil)
  if valid_402657972 != nil:
    section.add "Duration", valid_402657972
  var valid_402657973 = formData.getOrDefault("MaxRecords")
  valid_402657973 = validateParameter(valid_402657973, JInt, required = false,
                                      default = nil)
  if valid_402657973 != nil:
    section.add "MaxRecords", valid_402657973
  var valid_402657974 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657974 = validateParameter(valid_402657974, JString,
                                      required = false, default = nil)
  if valid_402657974 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657974
  var valid_402657975 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402657975 = validateParameter(valid_402657975, JString,
                                      required = false, default = nil)
  if valid_402657975 != nil:
    section.add "ReservedDBInstanceId", valid_402657975
  var valid_402657976 = formData.getOrDefault("MultiAZ")
  valid_402657976 = validateParameter(valid_402657976, JBool, required = false,
                                      default = nil)
  if valid_402657976 != nil:
    section.add "MultiAZ", valid_402657976
  var valid_402657977 = formData.getOrDefault("Filters")
  valid_402657977 = validateParameter(valid_402657977, JArray, required = false,
                                      default = nil)
  if valid_402657977 != nil:
    section.add "Filters", valid_402657977
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657978: Call_PostDescribeReservedDBInstances_402657956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657978.validator(path, query, header, formData, body, _)
  let scheme = call_402657978.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657978.makeUrl(scheme.get, call_402657978.host, call_402657978.base,
                                   call_402657978.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657978, uri, valid, _)

proc call*(call_402657979: Call_PostDescribeReservedDBInstances_402657956;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2014-09-01";
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
  var query_402657980 = newJObject()
  var formData_402657981 = newJObject()
  add(formData_402657981, "Marker", newJString(Marker))
  add(formData_402657981, "OfferingType", newJString(OfferingType))
  add(formData_402657981, "ProductDescription", newJString(ProductDescription))
  add(query_402657980, "Version", newJString(Version))
  add(formData_402657981, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402657981, "Duration", newJString(Duration))
  add(formData_402657981, "MaxRecords", newJInt(MaxRecords))
  add(formData_402657981, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402657981, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(formData_402657981, "MultiAZ", newJBool(MultiAZ))
  add(query_402657980, "Action", newJString(Action))
  if Filters != nil:
    formData_402657981.add "Filters", Filters
  result = call_402657979.call(nil, query_402657980, nil, formData_402657981,
                               nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_402657956(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_402657957, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_402657958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_402657931 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstances_402657933(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_402657932(path: JsonNode;
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
  var valid_402657934 = query.getOrDefault("ReservedDBInstanceId")
  valid_402657934 = validateParameter(valid_402657934, JString,
                                      required = false, default = nil)
  if valid_402657934 != nil:
    section.add "ReservedDBInstanceId", valid_402657934
  var valid_402657935 = query.getOrDefault("Filters")
  valid_402657935 = validateParameter(valid_402657935, JArray, required = false,
                                      default = nil)
  if valid_402657935 != nil:
    section.add "Filters", valid_402657935
  var valid_402657936 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657936
  var valid_402657937 = query.getOrDefault("MaxRecords")
  valid_402657937 = validateParameter(valid_402657937, JInt, required = false,
                                      default = nil)
  if valid_402657937 != nil:
    section.add "MaxRecords", valid_402657937
  var valid_402657938 = query.getOrDefault("Marker")
  valid_402657938 = validateParameter(valid_402657938, JString,
                                      required = false, default = nil)
  if valid_402657938 != nil:
    section.add "Marker", valid_402657938
  var valid_402657939 = query.getOrDefault("MultiAZ")
  valid_402657939 = validateParameter(valid_402657939, JBool, required = false,
                                      default = nil)
  if valid_402657939 != nil:
    section.add "MultiAZ", valid_402657939
  var valid_402657940 = query.getOrDefault("Version")
  valid_402657940 = validateParameter(valid_402657940, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657940 != nil:
    section.add "Version", valid_402657940
  var valid_402657941 = query.getOrDefault("Duration")
  valid_402657941 = validateParameter(valid_402657941, JString,
                                      required = false, default = nil)
  if valid_402657941 != nil:
    section.add "Duration", valid_402657941
  var valid_402657942 = query.getOrDefault("DBInstanceClass")
  valid_402657942 = validateParameter(valid_402657942, JString,
                                      required = false, default = nil)
  if valid_402657942 != nil:
    section.add "DBInstanceClass", valid_402657942
  var valid_402657943 = query.getOrDefault("OfferingType")
  valid_402657943 = validateParameter(valid_402657943, JString,
                                      required = false, default = nil)
  if valid_402657943 != nil:
    section.add "OfferingType", valid_402657943
  var valid_402657944 = query.getOrDefault("Action")
  valid_402657944 = validateParameter(valid_402657944, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_402657944 != nil:
    section.add "Action", valid_402657944
  var valid_402657945 = query.getOrDefault("ProductDescription")
  valid_402657945 = validateParameter(valid_402657945, JString,
                                      required = false, default = nil)
  if valid_402657945 != nil:
    section.add "ProductDescription", valid_402657945
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
  var valid_402657946 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657946 = validateParameter(valid_402657946, JString,
                                      required = false, default = nil)
  if valid_402657946 != nil:
    section.add "X-Amz-Security-Token", valid_402657946
  var valid_402657947 = header.getOrDefault("X-Amz-Signature")
  valid_402657947 = validateParameter(valid_402657947, JString,
                                      required = false, default = nil)
  if valid_402657947 != nil:
    section.add "X-Amz-Signature", valid_402657947
  var valid_402657948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657948 = validateParameter(valid_402657948, JString,
                                      required = false, default = nil)
  if valid_402657948 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657948
  var valid_402657949 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657949 = validateParameter(valid_402657949, JString,
                                      required = false, default = nil)
  if valid_402657949 != nil:
    section.add "X-Amz-Algorithm", valid_402657949
  var valid_402657950 = header.getOrDefault("X-Amz-Date")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "X-Amz-Date", valid_402657950
  var valid_402657951 = header.getOrDefault("X-Amz-Credential")
  valid_402657951 = validateParameter(valid_402657951, JString,
                                      required = false, default = nil)
  if valid_402657951 != nil:
    section.add "X-Amz-Credential", valid_402657951
  var valid_402657952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657952 = validateParameter(valid_402657952, JString,
                                      required = false, default = nil)
  if valid_402657952 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402657953: Call_GetDescribeReservedDBInstances_402657931;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402657953.validator(path, query, header, formData, body, _)
  let scheme = call_402657953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657953.makeUrl(scheme.get, call_402657953.host, call_402657953.base,
                                   call_402657953.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657953, uri, valid, _)

proc call*(call_402657954: Call_GetDescribeReservedDBInstances_402657931;
           ReservedDBInstanceId: string = ""; Filters: JsonNode = nil;
           ReservedDBInstancesOfferingId: string = ""; MaxRecords: int = 0;
           Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2014-09-01"; Duration: string = "";
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
  var query_402657955 = newJObject()
  add(query_402657955, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Filters != nil:
    query_402657955.add "Filters", Filters
  add(query_402657955, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402657955, "MaxRecords", newJInt(MaxRecords))
  add(query_402657955, "Marker", newJString(Marker))
  add(query_402657955, "MultiAZ", newJBool(MultiAZ))
  add(query_402657955, "Version", newJString(Version))
  add(query_402657955, "Duration", newJString(Duration))
  add(query_402657955, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402657955, "OfferingType", newJString(OfferingType))
  add(query_402657955, "Action", newJString(Action))
  add(query_402657955, "ProductDescription", newJString(ProductDescription))
  result = call_402657954.call(nil, query_402657955, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_402657931(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_402657932, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_402657933,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_402658006 = ref object of OpenApiRestCall_402656035
proc url_PostDescribeReservedDBInstancesOfferings_402658008(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_402658007(path: JsonNode;
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
  var valid_402658009 = query.getOrDefault("Version")
  valid_402658009 = validateParameter(valid_402658009, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658009 != nil:
    section.add "Version", valid_402658009
  var valid_402658010 = query.getOrDefault("Action")
  valid_402658010 = validateParameter(valid_402658010, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402658010 != nil:
    section.add "Action", valid_402658010
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
  var valid_402658011 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658011 = validateParameter(valid_402658011, JString,
                                      required = false, default = nil)
  if valid_402658011 != nil:
    section.add "X-Amz-Security-Token", valid_402658011
  var valid_402658012 = header.getOrDefault("X-Amz-Signature")
  valid_402658012 = validateParameter(valid_402658012, JString,
                                      required = false, default = nil)
  if valid_402658012 != nil:
    section.add "X-Amz-Signature", valid_402658012
  var valid_402658013 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658013 = validateParameter(valid_402658013, JString,
                                      required = false, default = nil)
  if valid_402658013 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658013
  var valid_402658014 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658014 = validateParameter(valid_402658014, JString,
                                      required = false, default = nil)
  if valid_402658014 != nil:
    section.add "X-Amz-Algorithm", valid_402658014
  var valid_402658015 = header.getOrDefault("X-Amz-Date")
  valid_402658015 = validateParameter(valid_402658015, JString,
                                      required = false, default = nil)
  if valid_402658015 != nil:
    section.add "X-Amz-Date", valid_402658015
  var valid_402658016 = header.getOrDefault("X-Amz-Credential")
  valid_402658016 = validateParameter(valid_402658016, JString,
                                      required = false, default = nil)
  if valid_402658016 != nil:
    section.add "X-Amz-Credential", valid_402658016
  var valid_402658017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658017 = validateParameter(valid_402658017, JString,
                                      required = false, default = nil)
  if valid_402658017 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658017
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
  var valid_402658018 = formData.getOrDefault("Marker")
  valid_402658018 = validateParameter(valid_402658018, JString,
                                      required = false, default = nil)
  if valid_402658018 != nil:
    section.add "Marker", valid_402658018
  var valid_402658019 = formData.getOrDefault("OfferingType")
  valid_402658019 = validateParameter(valid_402658019, JString,
                                      required = false, default = nil)
  if valid_402658019 != nil:
    section.add "OfferingType", valid_402658019
  var valid_402658020 = formData.getOrDefault("ProductDescription")
  valid_402658020 = validateParameter(valid_402658020, JString,
                                      required = false, default = nil)
  if valid_402658020 != nil:
    section.add "ProductDescription", valid_402658020
  var valid_402658021 = formData.getOrDefault("DBInstanceClass")
  valid_402658021 = validateParameter(valid_402658021, JString,
                                      required = false, default = nil)
  if valid_402658021 != nil:
    section.add "DBInstanceClass", valid_402658021
  var valid_402658022 = formData.getOrDefault("Duration")
  valid_402658022 = validateParameter(valid_402658022, JString,
                                      required = false, default = nil)
  if valid_402658022 != nil:
    section.add "Duration", valid_402658022
  var valid_402658023 = formData.getOrDefault("MaxRecords")
  valid_402658023 = validateParameter(valid_402658023, JInt, required = false,
                                      default = nil)
  if valid_402658023 != nil:
    section.add "MaxRecords", valid_402658023
  var valid_402658024 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658024 = validateParameter(valid_402658024, JString,
                                      required = false, default = nil)
  if valid_402658024 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658024
  var valid_402658025 = formData.getOrDefault("MultiAZ")
  valid_402658025 = validateParameter(valid_402658025, JBool, required = false,
                                      default = nil)
  if valid_402658025 != nil:
    section.add "MultiAZ", valid_402658025
  var valid_402658026 = formData.getOrDefault("Filters")
  valid_402658026 = validateParameter(valid_402658026, JArray, required = false,
                                      default = nil)
  if valid_402658026 != nil:
    section.add "Filters", valid_402658026
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658027: Call_PostDescribeReservedDBInstancesOfferings_402658006;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658027.validator(path, query, header, formData, body, _)
  let scheme = call_402658027.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658027.makeUrl(scheme.get, call_402658027.host, call_402658027.base,
                                   call_402658027.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658027, uri, valid, _)

proc call*(call_402658028: Call_PostDescribeReservedDBInstancesOfferings_402658006;
           Marker: string = ""; OfferingType: string = "";
           ProductDescription: string = ""; Version: string = "2014-09-01";
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
  var query_402658029 = newJObject()
  var formData_402658030 = newJObject()
  add(formData_402658030, "Marker", newJString(Marker))
  add(formData_402658030, "OfferingType", newJString(OfferingType))
  add(formData_402658030, "ProductDescription", newJString(ProductDescription))
  add(query_402658029, "Version", newJString(Version))
  add(formData_402658030, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658030, "Duration", newJString(Duration))
  add(formData_402658030, "MaxRecords", newJInt(MaxRecords))
  add(formData_402658030, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402658030, "MultiAZ", newJBool(MultiAZ))
  add(query_402658029, "Action", newJString(Action))
  if Filters != nil:
    formData_402658030.add "Filters", Filters
  result = call_402658028.call(nil, query_402658029, nil, formData_402658030,
                               nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_402658006(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_402658007,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_402658008,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_402657982 = ref object of OpenApiRestCall_402656035
proc url_GetDescribeReservedDBInstancesOfferings_402657984(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_402657983(path: JsonNode;
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
  var valid_402657985 = query.getOrDefault("Filters")
  valid_402657985 = validateParameter(valid_402657985, JArray, required = false,
                                      default = nil)
  if valid_402657985 != nil:
    section.add "Filters", valid_402657985
  var valid_402657986 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402657986 = validateParameter(valid_402657986, JString,
                                      required = false, default = nil)
  if valid_402657986 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402657986
  var valid_402657987 = query.getOrDefault("MaxRecords")
  valid_402657987 = validateParameter(valid_402657987, JInt, required = false,
                                      default = nil)
  if valid_402657987 != nil:
    section.add "MaxRecords", valid_402657987
  var valid_402657988 = query.getOrDefault("Marker")
  valid_402657988 = validateParameter(valid_402657988, JString,
                                      required = false, default = nil)
  if valid_402657988 != nil:
    section.add "Marker", valid_402657988
  var valid_402657989 = query.getOrDefault("MultiAZ")
  valid_402657989 = validateParameter(valid_402657989, JBool, required = false,
                                      default = nil)
  if valid_402657989 != nil:
    section.add "MultiAZ", valid_402657989
  var valid_402657990 = query.getOrDefault("Version")
  valid_402657990 = validateParameter(valid_402657990, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402657990 != nil:
    section.add "Version", valid_402657990
  var valid_402657991 = query.getOrDefault("Duration")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "Duration", valid_402657991
  var valid_402657992 = query.getOrDefault("DBInstanceClass")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "DBInstanceClass", valid_402657992
  var valid_402657993 = query.getOrDefault("OfferingType")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "OfferingType", valid_402657993
  var valid_402657994 = query.getOrDefault("Action")
  valid_402657994 = validateParameter(valid_402657994, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_402657994 != nil:
    section.add "Action", valid_402657994
  var valid_402657995 = query.getOrDefault("ProductDescription")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "ProductDescription", valid_402657995
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
  var valid_402657996 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "X-Amz-Security-Token", valid_402657996
  var valid_402657997 = header.getOrDefault("X-Amz-Signature")
  valid_402657997 = validateParameter(valid_402657997, JString,
                                      required = false, default = nil)
  if valid_402657997 != nil:
    section.add "X-Amz-Signature", valid_402657997
  var valid_402657998 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657998 = validateParameter(valid_402657998, JString,
                                      required = false, default = nil)
  if valid_402657998 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657998
  var valid_402657999 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657999 = validateParameter(valid_402657999, JString,
                                      required = false, default = nil)
  if valid_402657999 != nil:
    section.add "X-Amz-Algorithm", valid_402657999
  var valid_402658000 = header.getOrDefault("X-Amz-Date")
  valid_402658000 = validateParameter(valid_402658000, JString,
                                      required = false, default = nil)
  if valid_402658000 != nil:
    section.add "X-Amz-Date", valid_402658000
  var valid_402658001 = header.getOrDefault("X-Amz-Credential")
  valid_402658001 = validateParameter(valid_402658001, JString,
                                      required = false, default = nil)
  if valid_402658001 != nil:
    section.add "X-Amz-Credential", valid_402658001
  var valid_402658002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658002 = validateParameter(valid_402658002, JString,
                                      required = false, default = nil)
  if valid_402658002 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658002
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658003: Call_GetDescribeReservedDBInstancesOfferings_402657982;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658003.validator(path, query, header, formData, body, _)
  let scheme = call_402658003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658003.makeUrl(scheme.get, call_402658003.host, call_402658003.base,
                                   call_402658003.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658003, uri, valid, _)

proc call*(call_402658004: Call_GetDescribeReservedDBInstancesOfferings_402657982;
           Filters: JsonNode = nil; ReservedDBInstancesOfferingId: string = "";
           MaxRecords: int = 0; Marker: string = ""; MultiAZ: bool = false;
           Version: string = "2014-09-01"; Duration: string = "";
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
  var query_402658005 = newJObject()
  if Filters != nil:
    query_402658005.add "Filters", Filters
  add(query_402658005, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402658005, "MaxRecords", newJInt(MaxRecords))
  add(query_402658005, "Marker", newJString(Marker))
  add(query_402658005, "MultiAZ", newJBool(MultiAZ))
  add(query_402658005, "Version", newJString(Version))
  add(query_402658005, "Duration", newJString(Duration))
  add(query_402658005, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658005, "OfferingType", newJString(OfferingType))
  add(query_402658005, "Action", newJString(Action))
  add(query_402658005, "ProductDescription", newJString(ProductDescription))
  result = call_402658004.call(nil, query_402658005, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_402657982(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_402657983,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_402657984,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_402658050 = ref object of OpenApiRestCall_402656035
proc url_PostDownloadDBLogFilePortion_402658052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_402658051(path: JsonNode;
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
  var valid_402658053 = query.getOrDefault("Version")
  valid_402658053 = validateParameter(valid_402658053, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658053 != nil:
    section.add "Version", valid_402658053
  var valid_402658054 = query.getOrDefault("Action")
  valid_402658054 = validateParameter(valid_402658054, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402658054 != nil:
    section.add "Action", valid_402658054
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
  var valid_402658055 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658055 = validateParameter(valid_402658055, JString,
                                      required = false, default = nil)
  if valid_402658055 != nil:
    section.add "X-Amz-Security-Token", valid_402658055
  var valid_402658056 = header.getOrDefault("X-Amz-Signature")
  valid_402658056 = validateParameter(valid_402658056, JString,
                                      required = false, default = nil)
  if valid_402658056 != nil:
    section.add "X-Amz-Signature", valid_402658056
  var valid_402658057 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658057 = validateParameter(valid_402658057, JString,
                                      required = false, default = nil)
  if valid_402658057 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658057
  var valid_402658058 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658058 = validateParameter(valid_402658058, JString,
                                      required = false, default = nil)
  if valid_402658058 != nil:
    section.add "X-Amz-Algorithm", valid_402658058
  var valid_402658059 = header.getOrDefault("X-Amz-Date")
  valid_402658059 = validateParameter(valid_402658059, JString,
                                      required = false, default = nil)
  if valid_402658059 != nil:
    section.add "X-Amz-Date", valid_402658059
  var valid_402658060 = header.getOrDefault("X-Amz-Credential")
  valid_402658060 = validateParameter(valid_402658060, JString,
                                      required = false, default = nil)
  if valid_402658060 != nil:
    section.add "X-Amz-Credential", valid_402658060
  var valid_402658061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658061 = validateParameter(valid_402658061, JString,
                                      required = false, default = nil)
  if valid_402658061 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658061
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   LogFileName: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   NumberOfLines: JInt
  section = newJObject()
  var valid_402658062 = formData.getOrDefault("Marker")
  valid_402658062 = validateParameter(valid_402658062, JString,
                                      required = false, default = nil)
  if valid_402658062 != nil:
    section.add "Marker", valid_402658062
  assert formData != nil,
         "formData argument is necessary due to required `LogFileName` field"
  var valid_402658063 = formData.getOrDefault("LogFileName")
  valid_402658063 = validateParameter(valid_402658063, JString, required = true,
                                      default = nil)
  if valid_402658063 != nil:
    section.add "LogFileName", valid_402658063
  var valid_402658064 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658064 = validateParameter(valid_402658064, JString, required = true,
                                      default = nil)
  if valid_402658064 != nil:
    section.add "DBInstanceIdentifier", valid_402658064
  var valid_402658065 = formData.getOrDefault("NumberOfLines")
  valid_402658065 = validateParameter(valid_402658065, JInt, required = false,
                                      default = nil)
  if valid_402658065 != nil:
    section.add "NumberOfLines", valid_402658065
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658066: Call_PostDownloadDBLogFilePortion_402658050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658066.validator(path, query, header, formData, body, _)
  let scheme = call_402658066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658066.makeUrl(scheme.get, call_402658066.host, call_402658066.base,
                                   call_402658066.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658066, uri, valid, _)

proc call*(call_402658067: Call_PostDownloadDBLogFilePortion_402658050;
           LogFileName: string; DBInstanceIdentifier: string;
           Marker: string = ""; Version: string = "2014-09-01";
           NumberOfLines: int = 0; Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Action: string (required)
  var query_402658068 = newJObject()
  var formData_402658069 = newJObject()
  add(formData_402658069, "Marker", newJString(Marker))
  add(query_402658068, "Version", newJString(Version))
  add(formData_402658069, "LogFileName", newJString(LogFileName))
  add(formData_402658069, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658069, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402658068, "Action", newJString(Action))
  result = call_402658067.call(nil, query_402658068, nil, formData_402658069,
                               nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_402658050(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_402658051, base: "/",
    makeUrl: url_PostDownloadDBLogFilePortion_402658052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_402658031 = ref object of OpenApiRestCall_402656035
proc url_GetDownloadDBLogFilePortion_402658033(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_402658032(path: JsonNode;
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
  var valid_402658034 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658034 = validateParameter(valid_402658034, JString, required = true,
                                      default = nil)
  if valid_402658034 != nil:
    section.add "DBInstanceIdentifier", valid_402658034
  var valid_402658035 = query.getOrDefault("NumberOfLines")
  valid_402658035 = validateParameter(valid_402658035, JInt, required = false,
                                      default = nil)
  if valid_402658035 != nil:
    section.add "NumberOfLines", valid_402658035
  var valid_402658036 = query.getOrDefault("Marker")
  valid_402658036 = validateParameter(valid_402658036, JString,
                                      required = false, default = nil)
  if valid_402658036 != nil:
    section.add "Marker", valid_402658036
  var valid_402658037 = query.getOrDefault("Version")
  valid_402658037 = validateParameter(valid_402658037, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658037 != nil:
    section.add "Version", valid_402658037
  var valid_402658038 = query.getOrDefault("LogFileName")
  valid_402658038 = validateParameter(valid_402658038, JString, required = true,
                                      default = nil)
  if valid_402658038 != nil:
    section.add "LogFileName", valid_402658038
  var valid_402658039 = query.getOrDefault("Action")
  valid_402658039 = validateParameter(valid_402658039, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_402658039 != nil:
    section.add "Action", valid_402658039
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
  var valid_402658040 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658040 = validateParameter(valid_402658040, JString,
                                      required = false, default = nil)
  if valid_402658040 != nil:
    section.add "X-Amz-Security-Token", valid_402658040
  var valid_402658041 = header.getOrDefault("X-Amz-Signature")
  valid_402658041 = validateParameter(valid_402658041, JString,
                                      required = false, default = nil)
  if valid_402658041 != nil:
    section.add "X-Amz-Signature", valid_402658041
  var valid_402658042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658042 = validateParameter(valid_402658042, JString,
                                      required = false, default = nil)
  if valid_402658042 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658042
  var valid_402658043 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658043 = validateParameter(valid_402658043, JString,
                                      required = false, default = nil)
  if valid_402658043 != nil:
    section.add "X-Amz-Algorithm", valid_402658043
  var valid_402658044 = header.getOrDefault("X-Amz-Date")
  valid_402658044 = validateParameter(valid_402658044, JString,
                                      required = false, default = nil)
  if valid_402658044 != nil:
    section.add "X-Amz-Date", valid_402658044
  var valid_402658045 = header.getOrDefault("X-Amz-Credential")
  valid_402658045 = validateParameter(valid_402658045, JString,
                                      required = false, default = nil)
  if valid_402658045 != nil:
    section.add "X-Amz-Credential", valid_402658045
  var valid_402658046 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658046 = validateParameter(valid_402658046, JString,
                                      required = false, default = nil)
  if valid_402658046 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658046
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658047: Call_GetDownloadDBLogFilePortion_402658031;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658047.validator(path, query, header, formData, body, _)
  let scheme = call_402658047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658047.makeUrl(scheme.get, call_402658047.host, call_402658047.base,
                                   call_402658047.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658047, uri, valid, _)

proc call*(call_402658048: Call_GetDownloadDBLogFilePortion_402658031;
           DBInstanceIdentifier: string; LogFileName: string;
           NumberOfLines: int = 0; Marker: string = "";
           Version: string = "2014-09-01";
           Action: string = "DownloadDBLogFilePortion"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   DBInstanceIdentifier: string (required)
  ##   NumberOfLines: int
  ##   Marker: string
  ##   Version: string (required)
  ##   LogFileName: string (required)
  ##   Action: string (required)
  var query_402658049 = newJObject()
  add(query_402658049, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658049, "NumberOfLines", newJInt(NumberOfLines))
  add(query_402658049, "Marker", newJString(Marker))
  add(query_402658049, "Version", newJString(Version))
  add(query_402658049, "LogFileName", newJString(LogFileName))
  add(query_402658049, "Action", newJString(Action))
  result = call_402658048.call(nil, query_402658049, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_402658031(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_402658032, base: "/",
    makeUrl: url_GetDownloadDBLogFilePortion_402658033,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_402658087 = ref object of OpenApiRestCall_402656035
proc url_PostListTagsForResource_402658089(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_402658088(path: JsonNode; query: JsonNode;
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
  var valid_402658090 = query.getOrDefault("Version")
  valid_402658090 = validateParameter(valid_402658090, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658090 != nil:
    section.add "Version", valid_402658090
  var valid_402658091 = query.getOrDefault("Action")
  valid_402658091 = validateParameter(valid_402658091, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402658091 != nil:
    section.add "Action", valid_402658091
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
  var valid_402658092 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658092 = validateParameter(valid_402658092, JString,
                                      required = false, default = nil)
  if valid_402658092 != nil:
    section.add "X-Amz-Security-Token", valid_402658092
  var valid_402658093 = header.getOrDefault("X-Amz-Signature")
  valid_402658093 = validateParameter(valid_402658093, JString,
                                      required = false, default = nil)
  if valid_402658093 != nil:
    section.add "X-Amz-Signature", valid_402658093
  var valid_402658094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658094 = validateParameter(valid_402658094, JString,
                                      required = false, default = nil)
  if valid_402658094 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658094
  var valid_402658095 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658095 = validateParameter(valid_402658095, JString,
                                      required = false, default = nil)
  if valid_402658095 != nil:
    section.add "X-Amz-Algorithm", valid_402658095
  var valid_402658096 = header.getOrDefault("X-Amz-Date")
  valid_402658096 = validateParameter(valid_402658096, JString,
                                      required = false, default = nil)
  if valid_402658096 != nil:
    section.add "X-Amz-Date", valid_402658096
  var valid_402658097 = header.getOrDefault("X-Amz-Credential")
  valid_402658097 = validateParameter(valid_402658097, JString,
                                      required = false, default = nil)
  if valid_402658097 != nil:
    section.add "X-Amz-Credential", valid_402658097
  var valid_402658098 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658098 = validateParameter(valid_402658098, JString,
                                      required = false, default = nil)
  if valid_402658098 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658098
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_402658099 = formData.getOrDefault("Filters")
  valid_402658099 = validateParameter(valid_402658099, JArray, required = false,
                                      default = nil)
  if valid_402658099 != nil:
    section.add "Filters", valid_402658099
  assert formData != nil,
         "formData argument is necessary due to required `ResourceName` field"
  var valid_402658100 = formData.getOrDefault("ResourceName")
  valid_402658100 = validateParameter(valid_402658100, JString, required = true,
                                      default = nil)
  if valid_402658100 != nil:
    section.add "ResourceName", valid_402658100
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658101: Call_PostListTagsForResource_402658087;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658101.validator(path, query, header, formData, body, _)
  let scheme = call_402658101.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658101.makeUrl(scheme.get, call_402658101.host, call_402658101.base,
                                   call_402658101.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658101, uri, valid, _)

proc call*(call_402658102: Call_PostListTagsForResource_402658087;
           ResourceName: string; Version: string = "2014-09-01";
           Action: string = "ListTagsForResource"; Filters: JsonNode = nil): Recallable =
  ## postListTagsForResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  var query_402658103 = newJObject()
  var formData_402658104 = newJObject()
  add(query_402658103, "Version", newJString(Version))
  add(query_402658103, "Action", newJString(Action))
  if Filters != nil:
    formData_402658104.add "Filters", Filters
  add(formData_402658104, "ResourceName", newJString(ResourceName))
  result = call_402658102.call(nil, query_402658103, nil, formData_402658104,
                               nil)

var postListTagsForResource* = Call_PostListTagsForResource_402658087(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_402658088, base: "/",
    makeUrl: url_PostListTagsForResource_402658089,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_402658070 = ref object of OpenApiRestCall_402656035
proc url_GetListTagsForResource_402658072(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_402658071(path: JsonNode; query: JsonNode;
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
  var valid_402658073 = query.getOrDefault("Filters")
  valid_402658073 = validateParameter(valid_402658073, JArray, required = false,
                                      default = nil)
  if valid_402658073 != nil:
    section.add "Filters", valid_402658073
  var valid_402658074 = query.getOrDefault("Version")
  valid_402658074 = validateParameter(valid_402658074, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658074 != nil:
    section.add "Version", valid_402658074
  var valid_402658075 = query.getOrDefault("ResourceName")
  valid_402658075 = validateParameter(valid_402658075, JString, required = true,
                                      default = nil)
  if valid_402658075 != nil:
    section.add "ResourceName", valid_402658075
  var valid_402658076 = query.getOrDefault("Action")
  valid_402658076 = validateParameter(valid_402658076, JString, required = true, default = newJString(
      "ListTagsForResource"))
  if valid_402658076 != nil:
    section.add "Action", valid_402658076
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
  var valid_402658077 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658077 = validateParameter(valid_402658077, JString,
                                      required = false, default = nil)
  if valid_402658077 != nil:
    section.add "X-Amz-Security-Token", valid_402658077
  var valid_402658078 = header.getOrDefault("X-Amz-Signature")
  valid_402658078 = validateParameter(valid_402658078, JString,
                                      required = false, default = nil)
  if valid_402658078 != nil:
    section.add "X-Amz-Signature", valid_402658078
  var valid_402658079 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658079 = validateParameter(valid_402658079, JString,
                                      required = false, default = nil)
  if valid_402658079 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658079
  var valid_402658080 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658080 = validateParameter(valid_402658080, JString,
                                      required = false, default = nil)
  if valid_402658080 != nil:
    section.add "X-Amz-Algorithm", valid_402658080
  var valid_402658081 = header.getOrDefault("X-Amz-Date")
  valid_402658081 = validateParameter(valid_402658081, JString,
                                      required = false, default = nil)
  if valid_402658081 != nil:
    section.add "X-Amz-Date", valid_402658081
  var valid_402658082 = header.getOrDefault("X-Amz-Credential")
  valid_402658082 = validateParameter(valid_402658082, JString,
                                      required = false, default = nil)
  if valid_402658082 != nil:
    section.add "X-Amz-Credential", valid_402658082
  var valid_402658083 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658083 = validateParameter(valid_402658083, JString,
                                      required = false, default = nil)
  if valid_402658083 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658083
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658084: Call_GetListTagsForResource_402658070;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658084.validator(path, query, header, formData, body, _)
  let scheme = call_402658084.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658084.makeUrl(scheme.get, call_402658084.host, call_402658084.base,
                                   call_402658084.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658084, uri, valid, _)

proc call*(call_402658085: Call_GetListTagsForResource_402658070;
           ResourceName: string; Filters: JsonNode = nil;
           Version: string = "2014-09-01";
           Action: string = "ListTagsForResource"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402658086 = newJObject()
  if Filters != nil:
    query_402658086.add "Filters", Filters
  add(query_402658086, "Version", newJString(Version))
  add(query_402658086, "ResourceName", newJString(ResourceName))
  add(query_402658086, "Action", newJString(Action))
  result = call_402658085.call(nil, query_402658086, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_402658070(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_402658071, base: "/",
    makeUrl: url_GetListTagsForResource_402658072,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_402658141 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBInstance_402658143(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_402658142(path: JsonNode; query: JsonNode;
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
  var valid_402658144 = query.getOrDefault("Version")
  valid_402658144 = validateParameter(valid_402658144, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658144 != nil:
    section.add "Version", valid_402658144
  var valid_402658145 = query.getOrDefault("Action")
  valid_402658145 = validateParameter(valid_402658145, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402658145 != nil:
    section.add "Action", valid_402658145
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
  var valid_402658146 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658146 = validateParameter(valid_402658146, JString,
                                      required = false, default = nil)
  if valid_402658146 != nil:
    section.add "X-Amz-Security-Token", valid_402658146
  var valid_402658147 = header.getOrDefault("X-Amz-Signature")
  valid_402658147 = validateParameter(valid_402658147, JString,
                                      required = false, default = nil)
  if valid_402658147 != nil:
    section.add "X-Amz-Signature", valid_402658147
  var valid_402658148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658148 = validateParameter(valid_402658148, JString,
                                      required = false, default = nil)
  if valid_402658148 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658148
  var valid_402658149 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658149 = validateParameter(valid_402658149, JString,
                                      required = false, default = nil)
  if valid_402658149 != nil:
    section.add "X-Amz-Algorithm", valid_402658149
  var valid_402658150 = header.getOrDefault("X-Amz-Date")
  valid_402658150 = validateParameter(valid_402658150, JString,
                                      required = false, default = nil)
  if valid_402658150 != nil:
    section.add "X-Amz-Date", valid_402658150
  var valid_402658151 = header.getOrDefault("X-Amz-Credential")
  valid_402658151 = validateParameter(valid_402658151, JString,
                                      required = false, default = nil)
  if valid_402658151 != nil:
    section.add "X-Amz-Credential", valid_402658151
  var valid_402658152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658152 = validateParameter(valid_402658152, JString,
                                      required = false, default = nil)
  if valid_402658152 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658152
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   TdeCredentialArn: JString
  ##   AllocatedStorage: JInt
  ##   MasterUserPassword: JString
  ##   ApplyImmediately: JBool
  ##   DBParameterGroupName: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   PreferredMaintenanceWindow: JString
  ##   DBInstanceClass: JString
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   TdeCredentialPassword: JString
  ##   MultiAZ: JBool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: JString
  ##   NewDBInstanceIdentifier: JString
  ##   StorageType: JString
  ##   EngineVersion: JString
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658153 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658153 = validateParameter(valid_402658153, JString,
                                      required = false, default = nil)
  if valid_402658153 != nil:
    section.add "PreferredBackupWindow", valid_402658153
  var valid_402658154 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658154 = validateParameter(valid_402658154, JBool, required = false,
                                      default = nil)
  if valid_402658154 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658154
  var valid_402658155 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_402658155 = validateParameter(valid_402658155, JArray, required = false,
                                      default = nil)
  if valid_402658155 != nil:
    section.add "VpcSecurityGroupIds", valid_402658155
  var valid_402658156 = formData.getOrDefault("TdeCredentialArn")
  valid_402658156 = validateParameter(valid_402658156, JString,
                                      required = false, default = nil)
  if valid_402658156 != nil:
    section.add "TdeCredentialArn", valid_402658156
  var valid_402658157 = formData.getOrDefault("AllocatedStorage")
  valid_402658157 = validateParameter(valid_402658157, JInt, required = false,
                                      default = nil)
  if valid_402658157 != nil:
    section.add "AllocatedStorage", valid_402658157
  var valid_402658158 = formData.getOrDefault("MasterUserPassword")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "MasterUserPassword", valid_402658158
  var valid_402658159 = formData.getOrDefault("ApplyImmediately")
  valid_402658159 = validateParameter(valid_402658159, JBool, required = false,
                                      default = nil)
  if valid_402658159 != nil:
    section.add "ApplyImmediately", valid_402658159
  var valid_402658160 = formData.getOrDefault("DBParameterGroupName")
  valid_402658160 = validateParameter(valid_402658160, JString,
                                      required = false, default = nil)
  if valid_402658160 != nil:
    section.add "DBParameterGroupName", valid_402658160
  var valid_402658161 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_402658161 = validateParameter(valid_402658161, JBool, required = false,
                                      default = nil)
  if valid_402658161 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402658161
  var valid_402658162 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_402658162 = validateParameter(valid_402658162, JString,
                                      required = false, default = nil)
  if valid_402658162 != nil:
    section.add "PreferredMaintenanceWindow", valid_402658162
  var valid_402658163 = formData.getOrDefault("DBInstanceClass")
  valid_402658163 = validateParameter(valid_402658163, JString,
                                      required = false, default = nil)
  if valid_402658163 != nil:
    section.add "DBInstanceClass", valid_402658163
  var valid_402658164 = formData.getOrDefault("Iops")
  valid_402658164 = validateParameter(valid_402658164, JInt, required = false,
                                      default = nil)
  if valid_402658164 != nil:
    section.add "Iops", valid_402658164
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658165 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658165 = validateParameter(valid_402658165, JString, required = true,
                                      default = nil)
  if valid_402658165 != nil:
    section.add "DBInstanceIdentifier", valid_402658165
  var valid_402658166 = formData.getOrDefault("TdeCredentialPassword")
  valid_402658166 = validateParameter(valid_402658166, JString,
                                      required = false, default = nil)
  if valid_402658166 != nil:
    section.add "TdeCredentialPassword", valid_402658166
  var valid_402658167 = formData.getOrDefault("MultiAZ")
  valid_402658167 = validateParameter(valid_402658167, JBool, required = false,
                                      default = nil)
  if valid_402658167 != nil:
    section.add "MultiAZ", valid_402658167
  var valid_402658168 = formData.getOrDefault("DBSecurityGroups")
  valid_402658168 = validateParameter(valid_402658168, JArray, required = false,
                                      default = nil)
  if valid_402658168 != nil:
    section.add "DBSecurityGroups", valid_402658168
  var valid_402658169 = formData.getOrDefault("OptionGroupName")
  valid_402658169 = validateParameter(valid_402658169, JString,
                                      required = false, default = nil)
  if valid_402658169 != nil:
    section.add "OptionGroupName", valid_402658169
  var valid_402658170 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_402658170 = validateParameter(valid_402658170, JString,
                                      required = false, default = nil)
  if valid_402658170 != nil:
    section.add "NewDBInstanceIdentifier", valid_402658170
  var valid_402658171 = formData.getOrDefault("StorageType")
  valid_402658171 = validateParameter(valid_402658171, JString,
                                      required = false, default = nil)
  if valid_402658171 != nil:
    section.add "StorageType", valid_402658171
  var valid_402658172 = formData.getOrDefault("EngineVersion")
  valid_402658172 = validateParameter(valid_402658172, JString,
                                      required = false, default = nil)
  if valid_402658172 != nil:
    section.add "EngineVersion", valid_402658172
  var valid_402658173 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658173 = validateParameter(valid_402658173, JInt, required = false,
                                      default = nil)
  if valid_402658173 != nil:
    section.add "BackupRetentionPeriod", valid_402658173
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658174: Call_PostModifyDBInstance_402658141;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658174.validator(path, query, header, formData, body, _)
  let scheme = call_402658174.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658174.makeUrl(scheme.get, call_402658174.host, call_402658174.base,
                                   call_402658174.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658174, uri, valid, _)

proc call*(call_402658175: Call_PostModifyDBInstance_402658141;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           AutoMinorVersionUpgrade: bool = false;
           VpcSecurityGroupIds: JsonNode = nil; TdeCredentialArn: string = "";
           AllocatedStorage: int = 0; MasterUserPassword: string = "";
           ApplyImmediately: bool = false; Version: string = "2014-09-01";
           DBParameterGroupName: string = "";
           AllowMajorVersionUpgrade: bool = false;
           PreferredMaintenanceWindow: string = "";
           DBInstanceClass: string = ""; Iops: int = 0;
           TdeCredentialPassword: string = ""; MultiAZ: bool = false;
           DBSecurityGroups: JsonNode = nil; OptionGroupName: string = "";
           Action: string = "ModifyDBInstance";
           NewDBInstanceIdentifier: string = ""; StorageType: string = "";
           EngineVersion: string = ""; BackupRetentionPeriod: int = 0): Recallable =
  ## postModifyDBInstance
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   VpcSecurityGroupIds: JArray
  ##   TdeCredentialArn: string
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
  ##   TdeCredentialPassword: string
  ##   MultiAZ: bool
  ##   DBSecurityGroups: JArray
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   NewDBInstanceIdentifier: string
  ##   StorageType: string
  ##   EngineVersion: string
  ##   BackupRetentionPeriod: int
  var query_402658176 = newJObject()
  var formData_402658177 = newJObject()
  add(formData_402658177, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_402658177, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  if VpcSecurityGroupIds != nil:
    formData_402658177.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_402658177, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_402658177, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_402658177, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_402658177, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658176, "Version", newJString(Version))
  add(formData_402658177, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(formData_402658177, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(formData_402658177, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(formData_402658177, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658177, "Iops", newJInt(Iops))
  add(formData_402658177, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658177, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_402658177, "MultiAZ", newJBool(MultiAZ))
  if DBSecurityGroups != nil:
    formData_402658177.add "DBSecurityGroups", DBSecurityGroups
  add(formData_402658177, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658176, "Action", newJString(Action))
  add(formData_402658177, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_402658177, "StorageType", newJString(StorageType))
  add(formData_402658177, "EngineVersion", newJString(EngineVersion))
  add(formData_402658177, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658175.call(nil, query_402658176, nil, formData_402658177,
                               nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_402658141(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_402658142, base: "/",
    makeUrl: url_PostModifyDBInstance_402658143,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_402658105 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBInstance_402658107(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_402658106(path: JsonNode; query: JsonNode;
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
  ##   TdeCredentialPassword: JString
  ##   MasterUserPassword: JString
  ##   AllowMajorVersionUpgrade: JBool
  ##   Iops: JInt
  ##   StorageType: JString
  ##   ApplyImmediately: JBool
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   NewDBInstanceIdentifier: JString
  ##   EngineVersion: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   TdeCredentialArn: JString
  ##   Action: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBSecurityGroups: JArray
  section = newJObject()
  var valid_402658108 = query.getOrDefault("VpcSecurityGroupIds")
  valid_402658108 = validateParameter(valid_402658108, JArray, required = false,
                                      default = nil)
  if valid_402658108 != nil:
    section.add "VpcSecurityGroupIds", valid_402658108
  var valid_402658109 = query.getOrDefault("OptionGroupName")
  valid_402658109 = validateParameter(valid_402658109, JString,
                                      required = false, default = nil)
  if valid_402658109 != nil:
    section.add "OptionGroupName", valid_402658109
  var valid_402658110 = query.getOrDefault("PreferredBackupWindow")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "PreferredBackupWindow", valid_402658110
  var valid_402658111 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_402658111 = validateParameter(valid_402658111, JString,
                                      required = false, default = nil)
  if valid_402658111 != nil:
    section.add "PreferredMaintenanceWindow", valid_402658111
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658112 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658112 = validateParameter(valid_402658112, JString, required = true,
                                      default = nil)
  if valid_402658112 != nil:
    section.add "DBInstanceIdentifier", valid_402658112
  var valid_402658113 = query.getOrDefault("DBParameterGroupName")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "DBParameterGroupName", valid_402658113
  var valid_402658114 = query.getOrDefault("TdeCredentialPassword")
  valid_402658114 = validateParameter(valid_402658114, JString,
                                      required = false, default = nil)
  if valid_402658114 != nil:
    section.add "TdeCredentialPassword", valid_402658114
  var valid_402658115 = query.getOrDefault("MasterUserPassword")
  valid_402658115 = validateParameter(valid_402658115, JString,
                                      required = false, default = nil)
  if valid_402658115 != nil:
    section.add "MasterUserPassword", valid_402658115
  var valid_402658116 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_402658116 = validateParameter(valid_402658116, JBool, required = false,
                                      default = nil)
  if valid_402658116 != nil:
    section.add "AllowMajorVersionUpgrade", valid_402658116
  var valid_402658117 = query.getOrDefault("Iops")
  valid_402658117 = validateParameter(valid_402658117, JInt, required = false,
                                      default = nil)
  if valid_402658117 != nil:
    section.add "Iops", valid_402658117
  var valid_402658118 = query.getOrDefault("StorageType")
  valid_402658118 = validateParameter(valid_402658118, JString,
                                      required = false, default = nil)
  if valid_402658118 != nil:
    section.add "StorageType", valid_402658118
  var valid_402658119 = query.getOrDefault("ApplyImmediately")
  valid_402658119 = validateParameter(valid_402658119, JBool, required = false,
                                      default = nil)
  if valid_402658119 != nil:
    section.add "ApplyImmediately", valid_402658119
  var valid_402658120 = query.getOrDefault("MultiAZ")
  valid_402658120 = validateParameter(valid_402658120, JBool, required = false,
                                      default = nil)
  if valid_402658120 != nil:
    section.add "MultiAZ", valid_402658120
  var valid_402658121 = query.getOrDefault("Version")
  valid_402658121 = validateParameter(valid_402658121, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658121 != nil:
    section.add "Version", valid_402658121
  var valid_402658122 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_402658122 = validateParameter(valid_402658122, JString,
                                      required = false, default = nil)
  if valid_402658122 != nil:
    section.add "NewDBInstanceIdentifier", valid_402658122
  var valid_402658123 = query.getOrDefault("EngineVersion")
  valid_402658123 = validateParameter(valid_402658123, JString,
                                      required = false, default = nil)
  if valid_402658123 != nil:
    section.add "EngineVersion", valid_402658123
  var valid_402658124 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658124 = validateParameter(valid_402658124, JBool, required = false,
                                      default = nil)
  if valid_402658124 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658124
  var valid_402658125 = query.getOrDefault("AllocatedStorage")
  valid_402658125 = validateParameter(valid_402658125, JInt, required = false,
                                      default = nil)
  if valid_402658125 != nil:
    section.add "AllocatedStorage", valid_402658125
  var valid_402658126 = query.getOrDefault("DBInstanceClass")
  valid_402658126 = validateParameter(valid_402658126, JString,
                                      required = false, default = nil)
  if valid_402658126 != nil:
    section.add "DBInstanceClass", valid_402658126
  var valid_402658127 = query.getOrDefault("TdeCredentialArn")
  valid_402658127 = validateParameter(valid_402658127, JString,
                                      required = false, default = nil)
  if valid_402658127 != nil:
    section.add "TdeCredentialArn", valid_402658127
  var valid_402658128 = query.getOrDefault("Action")
  valid_402658128 = validateParameter(valid_402658128, JString, required = true,
                                      default = newJString("ModifyDBInstance"))
  if valid_402658128 != nil:
    section.add "Action", valid_402658128
  var valid_402658129 = query.getOrDefault("BackupRetentionPeriod")
  valid_402658129 = validateParameter(valid_402658129, JInt, required = false,
                                      default = nil)
  if valid_402658129 != nil:
    section.add "BackupRetentionPeriod", valid_402658129
  var valid_402658130 = query.getOrDefault("DBSecurityGroups")
  valid_402658130 = validateParameter(valid_402658130, JArray, required = false,
                                      default = nil)
  if valid_402658130 != nil:
    section.add "DBSecurityGroups", valid_402658130
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
  var valid_402658131 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658131 = validateParameter(valid_402658131, JString,
                                      required = false, default = nil)
  if valid_402658131 != nil:
    section.add "X-Amz-Security-Token", valid_402658131
  var valid_402658132 = header.getOrDefault("X-Amz-Signature")
  valid_402658132 = validateParameter(valid_402658132, JString,
                                      required = false, default = nil)
  if valid_402658132 != nil:
    section.add "X-Amz-Signature", valid_402658132
  var valid_402658133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658133 = validateParameter(valid_402658133, JString,
                                      required = false, default = nil)
  if valid_402658133 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658133
  var valid_402658134 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658134 = validateParameter(valid_402658134, JString,
                                      required = false, default = nil)
  if valid_402658134 != nil:
    section.add "X-Amz-Algorithm", valid_402658134
  var valid_402658135 = header.getOrDefault("X-Amz-Date")
  valid_402658135 = validateParameter(valid_402658135, JString,
                                      required = false, default = nil)
  if valid_402658135 != nil:
    section.add "X-Amz-Date", valid_402658135
  var valid_402658136 = header.getOrDefault("X-Amz-Credential")
  valid_402658136 = validateParameter(valid_402658136, JString,
                                      required = false, default = nil)
  if valid_402658136 != nil:
    section.add "X-Amz-Credential", valid_402658136
  var valid_402658137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658137 = validateParameter(valid_402658137, JString,
                                      required = false, default = nil)
  if valid_402658137 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658137
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658138: Call_GetModifyDBInstance_402658105;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658138.validator(path, query, header, formData, body, _)
  let scheme = call_402658138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658138.makeUrl(scheme.get, call_402658138.host, call_402658138.base,
                                   call_402658138.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658138, uri, valid, _)

proc call*(call_402658139: Call_GetModifyDBInstance_402658105;
           DBInstanceIdentifier: string; VpcSecurityGroupIds: JsonNode = nil;
           OptionGroupName: string = ""; PreferredBackupWindow: string = "";
           PreferredMaintenanceWindow: string = "";
           DBParameterGroupName: string = "";
           TdeCredentialPassword: string = ""; MasterUserPassword: string = "";
           AllowMajorVersionUpgrade: bool = false; Iops: int = 0;
           StorageType: string = ""; ApplyImmediately: bool = false;
           MultiAZ: bool = false; Version: string = "2014-09-01";
           NewDBInstanceIdentifier: string = ""; EngineVersion: string = "";
           AutoMinorVersionUpgrade: bool = false; AllocatedStorage: int = 0;
           DBInstanceClass: string = ""; TdeCredentialArn: string = "";
           Action: string = "ModifyDBInstance"; BackupRetentionPeriod: int = 0;
           DBSecurityGroups: JsonNode = nil): Recallable =
  ## getModifyDBInstance
  ##   VpcSecurityGroupIds: JArray
  ##   OptionGroupName: string
  ##   PreferredBackupWindow: string
  ##   PreferredMaintenanceWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBParameterGroupName: string
  ##   TdeCredentialPassword: string
  ##   MasterUserPassword: string
  ##   AllowMajorVersionUpgrade: bool
  ##   Iops: int
  ##   StorageType: string
  ##   ApplyImmediately: bool
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   NewDBInstanceIdentifier: string
  ##   EngineVersion: string
  ##   AutoMinorVersionUpgrade: bool
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBSecurityGroups: JArray
  var query_402658140 = newJObject()
  if VpcSecurityGroupIds != nil:
    query_402658140.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_402658140, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658140, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658140, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_402658140, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658140, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658140, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(query_402658140, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_402658140, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_402658140, "Iops", newJInt(Iops))
  add(query_402658140, "StorageType", newJString(StorageType))
  add(query_402658140, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658140, "MultiAZ", newJBool(MultiAZ))
  add(query_402658140, "Version", newJString(Version))
  add(query_402658140, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_402658140, "EngineVersion", newJString(EngineVersion))
  add(query_402658140, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658140, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_402658140, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658140, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_402658140, "Action", newJString(Action))
  add(query_402658140, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  if DBSecurityGroups != nil:
    query_402658140.add "DBSecurityGroups", DBSecurityGroups
  result = call_402658139.call(nil, query_402658140, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_402658105(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_402658106, base: "/",
    makeUrl: url_GetModifyDBInstance_402658107,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_402658195 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBParameterGroup_402658197(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_402658196(path: JsonNode;
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
  var valid_402658198 = query.getOrDefault("Version")
  valid_402658198 = validateParameter(valid_402658198, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658198 != nil:
    section.add "Version", valid_402658198
  var valid_402658199 = query.getOrDefault("Action")
  valid_402658199 = validateParameter(valid_402658199, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658199 != nil:
    section.add "Action", valid_402658199
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
  var valid_402658200 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658200 = validateParameter(valid_402658200, JString,
                                      required = false, default = nil)
  if valid_402658200 != nil:
    section.add "X-Amz-Security-Token", valid_402658200
  var valid_402658201 = header.getOrDefault("X-Amz-Signature")
  valid_402658201 = validateParameter(valid_402658201, JString,
                                      required = false, default = nil)
  if valid_402658201 != nil:
    section.add "X-Amz-Signature", valid_402658201
  var valid_402658202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658202 = validateParameter(valid_402658202, JString,
                                      required = false, default = nil)
  if valid_402658202 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658202
  var valid_402658203 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658203 = validateParameter(valid_402658203, JString,
                                      required = false, default = nil)
  if valid_402658203 != nil:
    section.add "X-Amz-Algorithm", valid_402658203
  var valid_402658204 = header.getOrDefault("X-Amz-Date")
  valid_402658204 = validateParameter(valid_402658204, JString,
                                      required = false, default = nil)
  if valid_402658204 != nil:
    section.add "X-Amz-Date", valid_402658204
  var valid_402658205 = header.getOrDefault("X-Amz-Credential")
  valid_402658205 = validateParameter(valid_402658205, JString,
                                      required = false, default = nil)
  if valid_402658205 != nil:
    section.add "X-Amz-Credential", valid_402658205
  var valid_402658206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658206 = validateParameter(valid_402658206, JString,
                                      required = false, default = nil)
  if valid_402658206 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658206
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658207 = formData.getOrDefault("DBParameterGroupName")
  valid_402658207 = validateParameter(valid_402658207, JString, required = true,
                                      default = nil)
  if valid_402658207 != nil:
    section.add "DBParameterGroupName", valid_402658207
  var valid_402658208 = formData.getOrDefault("Parameters")
  valid_402658208 = validateParameter(valid_402658208, JArray, required = true,
                                      default = nil)
  if valid_402658208 != nil:
    section.add "Parameters", valid_402658208
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658209: Call_PostModifyDBParameterGroup_402658195;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658209.validator(path, query, header, formData, body, _)
  let scheme = call_402658209.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658209.makeUrl(scheme.get, call_402658209.host, call_402658209.base,
                                   call_402658209.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658209, uri, valid, _)

proc call*(call_402658210: Call_PostModifyDBParameterGroup_402658195;
           DBParameterGroupName: string; Parameters: JsonNode;
           Version: string = "2014-09-01";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## postModifyDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray (required)
  var query_402658211 = newJObject()
  var formData_402658212 = newJObject()
  add(query_402658211, "Version", newJString(Version))
  add(formData_402658212, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658211, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658212.add "Parameters", Parameters
  result = call_402658210.call(nil, query_402658211, nil, formData_402658212,
                               nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_402658195(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_402658196, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_402658197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_402658178 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBParameterGroup_402658180(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_402658179(path: JsonNode;
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
  var valid_402658181 = query.getOrDefault("Parameters")
  valid_402658181 = validateParameter(valid_402658181, JArray, required = true,
                                      default = nil)
  if valid_402658181 != nil:
    section.add "Parameters", valid_402658181
  var valid_402658182 = query.getOrDefault("DBParameterGroupName")
  valid_402658182 = validateParameter(valid_402658182, JString, required = true,
                                      default = nil)
  if valid_402658182 != nil:
    section.add "DBParameterGroupName", valid_402658182
  var valid_402658183 = query.getOrDefault("Version")
  valid_402658183 = validateParameter(valid_402658183, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658183 != nil:
    section.add "Version", valid_402658183
  var valid_402658184 = query.getOrDefault("Action")
  valid_402658184 = validateParameter(valid_402658184, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_402658184 != nil:
    section.add "Action", valid_402658184
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
  var valid_402658185 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658185 = validateParameter(valid_402658185, JString,
                                      required = false, default = nil)
  if valid_402658185 != nil:
    section.add "X-Amz-Security-Token", valid_402658185
  var valid_402658186 = header.getOrDefault("X-Amz-Signature")
  valid_402658186 = validateParameter(valid_402658186, JString,
                                      required = false, default = nil)
  if valid_402658186 != nil:
    section.add "X-Amz-Signature", valid_402658186
  var valid_402658187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658187 = validateParameter(valid_402658187, JString,
                                      required = false, default = nil)
  if valid_402658187 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658187
  var valid_402658188 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658188 = validateParameter(valid_402658188, JString,
                                      required = false, default = nil)
  if valid_402658188 != nil:
    section.add "X-Amz-Algorithm", valid_402658188
  var valid_402658189 = header.getOrDefault("X-Amz-Date")
  valid_402658189 = validateParameter(valid_402658189, JString,
                                      required = false, default = nil)
  if valid_402658189 != nil:
    section.add "X-Amz-Date", valid_402658189
  var valid_402658190 = header.getOrDefault("X-Amz-Credential")
  valid_402658190 = validateParameter(valid_402658190, JString,
                                      required = false, default = nil)
  if valid_402658190 != nil:
    section.add "X-Amz-Credential", valid_402658190
  var valid_402658191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658191 = validateParameter(valid_402658191, JString,
                                      required = false, default = nil)
  if valid_402658191 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658192: Call_GetModifyDBParameterGroup_402658178;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658192.validator(path, query, header, formData, body, _)
  let scheme = call_402658192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658192.makeUrl(scheme.get, call_402658192.host, call_402658192.base,
                                   call_402658192.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658192, uri, valid, _)

proc call*(call_402658193: Call_GetModifyDBParameterGroup_402658178;
           Parameters: JsonNode; DBParameterGroupName: string;
           Version: string = "2014-09-01";
           Action: string = "ModifyDBParameterGroup"): Recallable =
  ## getModifyDBParameterGroup
  ##   Parameters: JArray (required)
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658194 = newJObject()
  if Parameters != nil:
    query_402658194.add "Parameters", Parameters
  add(query_402658194, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658194, "Version", newJString(Version))
  add(query_402658194, "Action", newJString(Action))
  result = call_402658193.call(nil, query_402658194, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_402658178(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_402658179, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_402658180,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_402658231 = ref object of OpenApiRestCall_402656035
proc url_PostModifyDBSubnetGroup_402658233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_402658232(path: JsonNode; query: JsonNode;
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
  var valid_402658234 = query.getOrDefault("Version")
  valid_402658234 = validateParameter(valid_402658234, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658234 != nil:
    section.add "Version", valid_402658234
  var valid_402658235 = query.getOrDefault("Action")
  valid_402658235 = validateParameter(valid_402658235, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658235 != nil:
    section.add "Action", valid_402658235
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
  var valid_402658236 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658236 = validateParameter(valid_402658236, JString,
                                      required = false, default = nil)
  if valid_402658236 != nil:
    section.add "X-Amz-Security-Token", valid_402658236
  var valid_402658237 = header.getOrDefault("X-Amz-Signature")
  valid_402658237 = validateParameter(valid_402658237, JString,
                                      required = false, default = nil)
  if valid_402658237 != nil:
    section.add "X-Amz-Signature", valid_402658237
  var valid_402658238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658238 = validateParameter(valid_402658238, JString,
                                      required = false, default = nil)
  if valid_402658238 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658238
  var valid_402658239 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658239 = validateParameter(valid_402658239, JString,
                                      required = false, default = nil)
  if valid_402658239 != nil:
    section.add "X-Amz-Algorithm", valid_402658239
  var valid_402658240 = header.getOrDefault("X-Amz-Date")
  valid_402658240 = validateParameter(valid_402658240, JString,
                                      required = false, default = nil)
  if valid_402658240 != nil:
    section.add "X-Amz-Date", valid_402658240
  var valid_402658241 = header.getOrDefault("X-Amz-Credential")
  valid_402658241 = validateParameter(valid_402658241, JString,
                                      required = false, default = nil)
  if valid_402658241 != nil:
    section.add "X-Amz-Credential", valid_402658241
  var valid_402658242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658242 = validateParameter(valid_402658242, JString,
                                      required = false, default = nil)
  if valid_402658242 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658242
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_402658243 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658243 = validateParameter(valid_402658243, JString, required = true,
                                      default = nil)
  if valid_402658243 != nil:
    section.add "DBSubnetGroupName", valid_402658243
  var valid_402658244 = formData.getOrDefault("SubnetIds")
  valid_402658244 = validateParameter(valid_402658244, JArray, required = true,
                                      default = nil)
  if valid_402658244 != nil:
    section.add "SubnetIds", valid_402658244
  var valid_402658245 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_402658245 = validateParameter(valid_402658245, JString,
                                      required = false, default = nil)
  if valid_402658245 != nil:
    section.add "DBSubnetGroupDescription", valid_402658245
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658246: Call_PostModifyDBSubnetGroup_402658231;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658246.validator(path, query, header, formData, body, _)
  let scheme = call_402658246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658246.makeUrl(scheme.get, call_402658246.host, call_402658246.base,
                                   call_402658246.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658246, uri, valid, _)

proc call*(call_402658247: Call_PostModifyDBSubnetGroup_402658231;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           Version: string = "2014-09-01";
           DBSubnetGroupDescription: string = "";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Action: string (required)
  var query_402658248 = newJObject()
  var formData_402658249 = newJObject()
  add(formData_402658249, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658248, "Version", newJString(Version))
  if SubnetIds != nil:
    formData_402658249.add "SubnetIds", SubnetIds
  add(formData_402658249, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658248, "Action", newJString(Action))
  result = call_402658247.call(nil, query_402658248, nil, formData_402658249,
                               nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_402658231(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_402658232, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_402658233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_402658213 = ref object of OpenApiRestCall_402656035
proc url_GetModifyDBSubnetGroup_402658215(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_402658214(path: JsonNode; query: JsonNode;
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
  var valid_402658216 = query.getOrDefault("DBSubnetGroupName")
  valid_402658216 = validateParameter(valid_402658216, JString, required = true,
                                      default = nil)
  if valid_402658216 != nil:
    section.add "DBSubnetGroupName", valid_402658216
  var valid_402658217 = query.getOrDefault("DBSubnetGroupDescription")
  valid_402658217 = validateParameter(valid_402658217, JString,
                                      required = false, default = nil)
  if valid_402658217 != nil:
    section.add "DBSubnetGroupDescription", valid_402658217
  var valid_402658218 = query.getOrDefault("Version")
  valid_402658218 = validateParameter(valid_402658218, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658218 != nil:
    section.add "Version", valid_402658218
  var valid_402658219 = query.getOrDefault("SubnetIds")
  valid_402658219 = validateParameter(valid_402658219, JArray, required = true,
                                      default = nil)
  if valid_402658219 != nil:
    section.add "SubnetIds", valid_402658219
  var valid_402658220 = query.getOrDefault("Action")
  valid_402658220 = validateParameter(valid_402658220, JString, required = true, default = newJString(
      "ModifyDBSubnetGroup"))
  if valid_402658220 != nil:
    section.add "Action", valid_402658220
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
  var valid_402658221 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658221 = validateParameter(valid_402658221, JString,
                                      required = false, default = nil)
  if valid_402658221 != nil:
    section.add "X-Amz-Security-Token", valid_402658221
  var valid_402658222 = header.getOrDefault("X-Amz-Signature")
  valid_402658222 = validateParameter(valid_402658222, JString,
                                      required = false, default = nil)
  if valid_402658222 != nil:
    section.add "X-Amz-Signature", valid_402658222
  var valid_402658223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658223 = validateParameter(valid_402658223, JString,
                                      required = false, default = nil)
  if valid_402658223 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658223
  var valid_402658224 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658224 = validateParameter(valid_402658224, JString,
                                      required = false, default = nil)
  if valid_402658224 != nil:
    section.add "X-Amz-Algorithm", valid_402658224
  var valid_402658225 = header.getOrDefault("X-Amz-Date")
  valid_402658225 = validateParameter(valid_402658225, JString,
                                      required = false, default = nil)
  if valid_402658225 != nil:
    section.add "X-Amz-Date", valid_402658225
  var valid_402658226 = header.getOrDefault("X-Amz-Credential")
  valid_402658226 = validateParameter(valid_402658226, JString,
                                      required = false, default = nil)
  if valid_402658226 != nil:
    section.add "X-Amz-Credential", valid_402658226
  var valid_402658227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658227 = validateParameter(valid_402658227, JString,
                                      required = false, default = nil)
  if valid_402658227 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658228: Call_GetModifyDBSubnetGroup_402658213;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658228.validator(path, query, header, formData, body, _)
  let scheme = call_402658228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658228.makeUrl(scheme.get, call_402658228.host, call_402658228.base,
                                   call_402658228.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658228, uri, valid, _)

proc call*(call_402658229: Call_GetModifyDBSubnetGroup_402658213;
           DBSubnetGroupName: string; SubnetIds: JsonNode;
           DBSubnetGroupDescription: string = "";
           Version: string = "2014-09-01";
           Action: string = "ModifyDBSubnetGroup"): Recallable =
  ## getModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  var query_402658230 = newJObject()
  add(query_402658230, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658230, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_402658230, "Version", newJString(Version))
  if SubnetIds != nil:
    query_402658230.add "SubnetIds", SubnetIds
  add(query_402658230, "Action", newJString(Action))
  result = call_402658229.call(nil, query_402658230, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_402658213(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_402658214, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_402658215,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_402658270 = ref object of OpenApiRestCall_402656035
proc url_PostModifyEventSubscription_402658272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_402658271(path: JsonNode;
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
  var valid_402658273 = query.getOrDefault("Version")
  valid_402658273 = validateParameter(valid_402658273, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658273 != nil:
    section.add "Version", valid_402658273
  var valid_402658274 = query.getOrDefault("Action")
  valid_402658274 = validateParameter(valid_402658274, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658274 != nil:
    section.add "Action", valid_402658274
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
  var valid_402658275 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658275 = validateParameter(valid_402658275, JString,
                                      required = false, default = nil)
  if valid_402658275 != nil:
    section.add "X-Amz-Security-Token", valid_402658275
  var valid_402658276 = header.getOrDefault("X-Amz-Signature")
  valid_402658276 = validateParameter(valid_402658276, JString,
                                      required = false, default = nil)
  if valid_402658276 != nil:
    section.add "X-Amz-Signature", valid_402658276
  var valid_402658277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658277 = validateParameter(valid_402658277, JString,
                                      required = false, default = nil)
  if valid_402658277 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658277
  var valid_402658278 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658278 = validateParameter(valid_402658278, JString,
                                      required = false, default = nil)
  if valid_402658278 != nil:
    section.add "X-Amz-Algorithm", valid_402658278
  var valid_402658279 = header.getOrDefault("X-Amz-Date")
  valid_402658279 = validateParameter(valid_402658279, JString,
                                      required = false, default = nil)
  if valid_402658279 != nil:
    section.add "X-Amz-Date", valid_402658279
  var valid_402658280 = header.getOrDefault("X-Amz-Credential")
  valid_402658280 = validateParameter(valid_402658280, JString,
                                      required = false, default = nil)
  if valid_402658280 != nil:
    section.add "X-Amz-Credential", valid_402658280
  var valid_402658281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658281 = validateParameter(valid_402658281, JString,
                                      required = false, default = nil)
  if valid_402658281 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658281
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  section = newJObject()
  var valid_402658282 = formData.getOrDefault("SourceType")
  valid_402658282 = validateParameter(valid_402658282, JString,
                                      required = false, default = nil)
  if valid_402658282 != nil:
    section.add "SourceType", valid_402658282
  var valid_402658283 = formData.getOrDefault("Enabled")
  valid_402658283 = validateParameter(valid_402658283, JBool, required = false,
                                      default = nil)
  if valid_402658283 != nil:
    section.add "Enabled", valid_402658283
  var valid_402658284 = formData.getOrDefault("EventCategories")
  valid_402658284 = validateParameter(valid_402658284, JArray, required = false,
                                      default = nil)
  if valid_402658284 != nil:
    section.add "EventCategories", valid_402658284
  var valid_402658285 = formData.getOrDefault("SnsTopicArn")
  valid_402658285 = validateParameter(valid_402658285, JString,
                                      required = false, default = nil)
  if valid_402658285 != nil:
    section.add "SnsTopicArn", valid_402658285
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_402658286 = formData.getOrDefault("SubscriptionName")
  valid_402658286 = validateParameter(valid_402658286, JString, required = true,
                                      default = nil)
  if valid_402658286 != nil:
    section.add "SubscriptionName", valid_402658286
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658287: Call_PostModifyEventSubscription_402658270;
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

proc call*(call_402658288: Call_PostModifyEventSubscription_402658270;
           SubscriptionName: string; SourceType: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2014-09-01"; SnsTopicArn: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## postModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SnsTopicArn: string
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  var query_402658289 = newJObject()
  var formData_402658290 = newJObject()
  add(formData_402658290, "SourceType", newJString(SourceType))
  add(formData_402658290, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_402658290.add "EventCategories", EventCategories
  add(query_402658289, "Version", newJString(Version))
  add(formData_402658290, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658289, "Action", newJString(Action))
  add(formData_402658290, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658288.call(nil, query_402658289, nil, formData_402658290,
                               nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_402658270(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_402658271, base: "/",
    makeUrl: url_PostModifyEventSubscription_402658272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_402658250 = ref object of OpenApiRestCall_402656035
proc url_GetModifyEventSubscription_402658252(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_402658251(path: JsonNode;
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
  var valid_402658253 = query.getOrDefault("SnsTopicArn")
  valid_402658253 = validateParameter(valid_402658253, JString,
                                      required = false, default = nil)
  if valid_402658253 != nil:
    section.add "SnsTopicArn", valid_402658253
  var valid_402658254 = query.getOrDefault("Enabled")
  valid_402658254 = validateParameter(valid_402658254, JBool, required = false,
                                      default = nil)
  if valid_402658254 != nil:
    section.add "Enabled", valid_402658254
  var valid_402658255 = query.getOrDefault("EventCategories")
  valid_402658255 = validateParameter(valid_402658255, JArray, required = false,
                                      default = nil)
  if valid_402658255 != nil:
    section.add "EventCategories", valid_402658255
  var valid_402658256 = query.getOrDefault("Version")
  valid_402658256 = validateParameter(valid_402658256, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658256 != nil:
    section.add "Version", valid_402658256
  var valid_402658257 = query.getOrDefault("SubscriptionName")
  valid_402658257 = validateParameter(valid_402658257, JString, required = true,
                                      default = nil)
  if valid_402658257 != nil:
    section.add "SubscriptionName", valid_402658257
  var valid_402658258 = query.getOrDefault("SourceType")
  valid_402658258 = validateParameter(valid_402658258, JString,
                                      required = false, default = nil)
  if valid_402658258 != nil:
    section.add "SourceType", valid_402658258
  var valid_402658259 = query.getOrDefault("Action")
  valid_402658259 = validateParameter(valid_402658259, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_402658259 != nil:
    section.add "Action", valid_402658259
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
  var valid_402658260 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658260 = validateParameter(valid_402658260, JString,
                                      required = false, default = nil)
  if valid_402658260 != nil:
    section.add "X-Amz-Security-Token", valid_402658260
  var valid_402658261 = header.getOrDefault("X-Amz-Signature")
  valid_402658261 = validateParameter(valid_402658261, JString,
                                      required = false, default = nil)
  if valid_402658261 != nil:
    section.add "X-Amz-Signature", valid_402658261
  var valid_402658262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658262 = validateParameter(valid_402658262, JString,
                                      required = false, default = nil)
  if valid_402658262 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658262
  var valid_402658263 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658263 = validateParameter(valid_402658263, JString,
                                      required = false, default = nil)
  if valid_402658263 != nil:
    section.add "X-Amz-Algorithm", valid_402658263
  var valid_402658264 = header.getOrDefault("X-Amz-Date")
  valid_402658264 = validateParameter(valid_402658264, JString,
                                      required = false, default = nil)
  if valid_402658264 != nil:
    section.add "X-Amz-Date", valid_402658264
  var valid_402658265 = header.getOrDefault("X-Amz-Credential")
  valid_402658265 = validateParameter(valid_402658265, JString,
                                      required = false, default = nil)
  if valid_402658265 != nil:
    section.add "X-Amz-Credential", valid_402658265
  var valid_402658266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658266 = validateParameter(valid_402658266, JString,
                                      required = false, default = nil)
  if valid_402658266 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658267: Call_GetModifyEventSubscription_402658250;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658267.validator(path, query, header, formData, body, _)
  let scheme = call_402658267.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658267.makeUrl(scheme.get, call_402658267.host, call_402658267.base,
                                   call_402658267.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658267, uri, valid, _)

proc call*(call_402658268: Call_GetModifyEventSubscription_402658250;
           SubscriptionName: string; SnsTopicArn: string = "";
           Enabled: bool = false; EventCategories: JsonNode = nil;
           Version: string = "2014-09-01"; SourceType: string = "";
           Action: string = "ModifyEventSubscription"): Recallable =
  ## getModifyEventSubscription
  ##   SnsTopicArn: string
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   SourceType: string
  ##   Action: string (required)
  var query_402658269 = newJObject()
  add(query_402658269, "SnsTopicArn", newJString(SnsTopicArn))
  add(query_402658269, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    query_402658269.add "EventCategories", EventCategories
  add(query_402658269, "Version", newJString(Version))
  add(query_402658269, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658269, "SourceType", newJString(SourceType))
  add(query_402658269, "Action", newJString(Action))
  result = call_402658268.call(nil, query_402658269, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_402658250(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_402658251, base: "/",
    makeUrl: url_GetModifyEventSubscription_402658252,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_402658310 = ref object of OpenApiRestCall_402656035
proc url_PostModifyOptionGroup_402658312(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_402658311(path: JsonNode; query: JsonNode;
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
  var valid_402658313 = query.getOrDefault("Version")
  valid_402658313 = validateParameter(valid_402658313, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658313 != nil:
    section.add "Version", valid_402658313
  var valid_402658314 = query.getOrDefault("Action")
  valid_402658314 = validateParameter(valid_402658314, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658314 != nil:
    section.add "Action", valid_402658314
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
  var valid_402658315 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658315 = validateParameter(valid_402658315, JString,
                                      required = false, default = nil)
  if valid_402658315 != nil:
    section.add "X-Amz-Security-Token", valid_402658315
  var valid_402658316 = header.getOrDefault("X-Amz-Signature")
  valid_402658316 = validateParameter(valid_402658316, JString,
                                      required = false, default = nil)
  if valid_402658316 != nil:
    section.add "X-Amz-Signature", valid_402658316
  var valid_402658317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658317 = validateParameter(valid_402658317, JString,
                                      required = false, default = nil)
  if valid_402658317 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658317
  var valid_402658318 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658318 = validateParameter(valid_402658318, JString,
                                      required = false, default = nil)
  if valid_402658318 != nil:
    section.add "X-Amz-Algorithm", valid_402658318
  var valid_402658319 = header.getOrDefault("X-Amz-Date")
  valid_402658319 = validateParameter(valid_402658319, JString,
                                      required = false, default = nil)
  if valid_402658319 != nil:
    section.add "X-Amz-Date", valid_402658319
  var valid_402658320 = header.getOrDefault("X-Amz-Credential")
  valid_402658320 = validateParameter(valid_402658320, JString,
                                      required = false, default = nil)
  if valid_402658320 != nil:
    section.add "X-Amz-Credential", valid_402658320
  var valid_402658321 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658321 = validateParameter(valid_402658321, JString,
                                      required = false, default = nil)
  if valid_402658321 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658321
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  section = newJObject()
  var valid_402658322 = formData.getOrDefault("OptionsToRemove")
  valid_402658322 = validateParameter(valid_402658322, JArray, required = false,
                                      default = nil)
  if valid_402658322 != nil:
    section.add "OptionsToRemove", valid_402658322
  var valid_402658323 = formData.getOrDefault("OptionsToInclude")
  valid_402658323 = validateParameter(valid_402658323, JArray, required = false,
                                      default = nil)
  if valid_402658323 != nil:
    section.add "OptionsToInclude", valid_402658323
  var valid_402658324 = formData.getOrDefault("ApplyImmediately")
  valid_402658324 = validateParameter(valid_402658324, JBool, required = false,
                                      default = nil)
  if valid_402658324 != nil:
    section.add "ApplyImmediately", valid_402658324
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_402658325 = formData.getOrDefault("OptionGroupName")
  valid_402658325 = validateParameter(valid_402658325, JString, required = true,
                                      default = nil)
  if valid_402658325 != nil:
    section.add "OptionGroupName", valid_402658325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658326: Call_PostModifyOptionGroup_402658310;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658326.validator(path, query, header, formData, body, _)
  let scheme = call_402658326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658326.makeUrl(scheme.get, call_402658326.host, call_402658326.base,
                                   call_402658326.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658326, uri, valid, _)

proc call*(call_402658327: Call_PostModifyOptionGroup_402658310;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2014-09-01"; Action: string = "ModifyOptionGroup"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  var query_402658328 = newJObject()
  var formData_402658329 = newJObject()
  if OptionsToRemove != nil:
    formData_402658329.add "OptionsToRemove", OptionsToRemove
  if OptionsToInclude != nil:
    formData_402658329.add "OptionsToInclude", OptionsToInclude
  add(formData_402658329, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658328, "Version", newJString(Version))
  add(formData_402658329, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658328, "Action", newJString(Action))
  result = call_402658327.call(nil, query_402658328, nil, formData_402658329,
                               nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_402658310(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_402658311, base: "/",
    makeUrl: url_PostModifyOptionGroup_402658312,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_402658291 = ref object of OpenApiRestCall_402656035
proc url_GetModifyOptionGroup_402658293(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_402658292(path: JsonNode; query: JsonNode;
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
  var valid_402658294 = query.getOrDefault("OptionsToRemove")
  valid_402658294 = validateParameter(valid_402658294, JArray, required = false,
                                      default = nil)
  if valid_402658294 != nil:
    section.add "OptionsToRemove", valid_402658294
  assert query != nil,
         "query argument is necessary due to required `OptionGroupName` field"
  var valid_402658295 = query.getOrDefault("OptionGroupName")
  valid_402658295 = validateParameter(valid_402658295, JString, required = true,
                                      default = nil)
  if valid_402658295 != nil:
    section.add "OptionGroupName", valid_402658295
  var valid_402658296 = query.getOrDefault("OptionsToInclude")
  valid_402658296 = validateParameter(valid_402658296, JArray, required = false,
                                      default = nil)
  if valid_402658296 != nil:
    section.add "OptionsToInclude", valid_402658296
  var valid_402658297 = query.getOrDefault("ApplyImmediately")
  valid_402658297 = validateParameter(valid_402658297, JBool, required = false,
                                      default = nil)
  if valid_402658297 != nil:
    section.add "ApplyImmediately", valid_402658297
  var valid_402658298 = query.getOrDefault("Version")
  valid_402658298 = validateParameter(valid_402658298, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658298 != nil:
    section.add "Version", valid_402658298
  var valid_402658299 = query.getOrDefault("Action")
  valid_402658299 = validateParameter(valid_402658299, JString, required = true,
                                      default = newJString("ModifyOptionGroup"))
  if valid_402658299 != nil:
    section.add "Action", valid_402658299
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
  var valid_402658300 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658300 = validateParameter(valid_402658300, JString,
                                      required = false, default = nil)
  if valid_402658300 != nil:
    section.add "X-Amz-Security-Token", valid_402658300
  var valid_402658301 = header.getOrDefault("X-Amz-Signature")
  valid_402658301 = validateParameter(valid_402658301, JString,
                                      required = false, default = nil)
  if valid_402658301 != nil:
    section.add "X-Amz-Signature", valid_402658301
  var valid_402658302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658302 = validateParameter(valid_402658302, JString,
                                      required = false, default = nil)
  if valid_402658302 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658302
  var valid_402658303 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658303 = validateParameter(valid_402658303, JString,
                                      required = false, default = nil)
  if valid_402658303 != nil:
    section.add "X-Amz-Algorithm", valid_402658303
  var valid_402658304 = header.getOrDefault("X-Amz-Date")
  valid_402658304 = validateParameter(valid_402658304, JString,
                                      required = false, default = nil)
  if valid_402658304 != nil:
    section.add "X-Amz-Date", valid_402658304
  var valid_402658305 = header.getOrDefault("X-Amz-Credential")
  valid_402658305 = validateParameter(valid_402658305, JString,
                                      required = false, default = nil)
  if valid_402658305 != nil:
    section.add "X-Amz-Credential", valid_402658305
  var valid_402658306 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658306 = validateParameter(valid_402658306, JString,
                                      required = false, default = nil)
  if valid_402658306 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658306
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658307: Call_GetModifyOptionGroup_402658291;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658307.validator(path, query, header, formData, body, _)
  let scheme = call_402658307.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658307.makeUrl(scheme.get, call_402658307.host, call_402658307.base,
                                   call_402658307.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658307, uri, valid, _)

proc call*(call_402658308: Call_GetModifyOptionGroup_402658291;
           OptionGroupName: string; OptionsToRemove: JsonNode = nil;
           OptionsToInclude: JsonNode = nil; ApplyImmediately: bool = false;
           Version: string = "2014-09-01"; Action: string = "ModifyOptionGroup"): Recallable =
  ## getModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   ApplyImmediately: bool
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658309 = newJObject()
  if OptionsToRemove != nil:
    query_402658309.add "OptionsToRemove", OptionsToRemove
  add(query_402658309, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    query_402658309.add "OptionsToInclude", OptionsToInclude
  add(query_402658309, "ApplyImmediately", newJBool(ApplyImmediately))
  add(query_402658309, "Version", newJString(Version))
  add(query_402658309, "Action", newJString(Action))
  result = call_402658308.call(nil, query_402658309, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_402658291(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_402658292, base: "/",
    makeUrl: url_GetModifyOptionGroup_402658293,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_402658348 = ref object of OpenApiRestCall_402656035
proc url_PostPromoteReadReplica_402658350(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_402658349(path: JsonNode; query: JsonNode;
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
  var valid_402658351 = query.getOrDefault("Version")
  valid_402658351 = validateParameter(valid_402658351, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658351 != nil:
    section.add "Version", valid_402658351
  var valid_402658352 = query.getOrDefault("Action")
  valid_402658352 = validateParameter(valid_402658352, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658352 != nil:
    section.add "Action", valid_402658352
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
  var valid_402658353 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658353 = validateParameter(valid_402658353, JString,
                                      required = false, default = nil)
  if valid_402658353 != nil:
    section.add "X-Amz-Security-Token", valid_402658353
  var valid_402658354 = header.getOrDefault("X-Amz-Signature")
  valid_402658354 = validateParameter(valid_402658354, JString,
                                      required = false, default = nil)
  if valid_402658354 != nil:
    section.add "X-Amz-Signature", valid_402658354
  var valid_402658355 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658355 = validateParameter(valid_402658355, JString,
                                      required = false, default = nil)
  if valid_402658355 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658355
  var valid_402658356 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658356 = validateParameter(valid_402658356, JString,
                                      required = false, default = nil)
  if valid_402658356 != nil:
    section.add "X-Amz-Algorithm", valid_402658356
  var valid_402658357 = header.getOrDefault("X-Amz-Date")
  valid_402658357 = validateParameter(valid_402658357, JString,
                                      required = false, default = nil)
  if valid_402658357 != nil:
    section.add "X-Amz-Date", valid_402658357
  var valid_402658358 = header.getOrDefault("X-Amz-Credential")
  valid_402658358 = validateParameter(valid_402658358, JString,
                                      required = false, default = nil)
  if valid_402658358 != nil:
    section.add "X-Amz-Credential", valid_402658358
  var valid_402658359 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658359 = validateParameter(valid_402658359, JString,
                                      required = false, default = nil)
  if valid_402658359 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658359
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredBackupWindow: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  section = newJObject()
  var valid_402658360 = formData.getOrDefault("PreferredBackupWindow")
  valid_402658360 = validateParameter(valid_402658360, JString,
                                      required = false, default = nil)
  if valid_402658360 != nil:
    section.add "PreferredBackupWindow", valid_402658360
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658361 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658361 = validateParameter(valid_402658361, JString, required = true,
                                      default = nil)
  if valid_402658361 != nil:
    section.add "DBInstanceIdentifier", valid_402658361
  var valid_402658362 = formData.getOrDefault("BackupRetentionPeriod")
  valid_402658362 = validateParameter(valid_402658362, JInt, required = false,
                                      default = nil)
  if valid_402658362 != nil:
    section.add "BackupRetentionPeriod", valid_402658362
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658363: Call_PostPromoteReadReplica_402658348;
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

proc call*(call_402658364: Call_PostPromoteReadReplica_402658348;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2014-09-01";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## postPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658365 = newJObject()
  var formData_402658366 = newJObject()
  add(formData_402658366, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658365, "Version", newJString(Version))
  add(formData_402658366, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658365, "Action", newJString(Action))
  add(formData_402658366, "BackupRetentionPeriod",
      newJInt(BackupRetentionPeriod))
  result = call_402658364.call(nil, query_402658365, nil, formData_402658366,
                               nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_402658348(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_402658349, base: "/",
    makeUrl: url_PostPromoteReadReplica_402658350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_402658330 = ref object of OpenApiRestCall_402656035
proc url_GetPromoteReadReplica_402658332(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_402658331(path: JsonNode; query: JsonNode;
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
  var valid_402658333 = query.getOrDefault("PreferredBackupWindow")
  valid_402658333 = validateParameter(valid_402658333, JString,
                                      required = false, default = nil)
  if valid_402658333 != nil:
    section.add "PreferredBackupWindow", valid_402658333
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658334 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658334 = validateParameter(valid_402658334, JString, required = true,
                                      default = nil)
  if valid_402658334 != nil:
    section.add "DBInstanceIdentifier", valid_402658334
  var valid_402658335 = query.getOrDefault("Version")
  valid_402658335 = validateParameter(valid_402658335, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658335 != nil:
    section.add "Version", valid_402658335
  var valid_402658336 = query.getOrDefault("Action")
  valid_402658336 = validateParameter(valid_402658336, JString, required = true, default = newJString(
      "PromoteReadReplica"))
  if valid_402658336 != nil:
    section.add "Action", valid_402658336
  var valid_402658337 = query.getOrDefault("BackupRetentionPeriod")
  valid_402658337 = validateParameter(valid_402658337, JInt, required = false,
                                      default = nil)
  if valid_402658337 != nil:
    section.add "BackupRetentionPeriod", valid_402658337
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
  var valid_402658338 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658338 = validateParameter(valid_402658338, JString,
                                      required = false, default = nil)
  if valid_402658338 != nil:
    section.add "X-Amz-Security-Token", valid_402658338
  var valid_402658339 = header.getOrDefault("X-Amz-Signature")
  valid_402658339 = validateParameter(valid_402658339, JString,
                                      required = false, default = nil)
  if valid_402658339 != nil:
    section.add "X-Amz-Signature", valid_402658339
  var valid_402658340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658340 = validateParameter(valid_402658340, JString,
                                      required = false, default = nil)
  if valid_402658340 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658340
  var valid_402658341 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658341 = validateParameter(valid_402658341, JString,
                                      required = false, default = nil)
  if valid_402658341 != nil:
    section.add "X-Amz-Algorithm", valid_402658341
  var valid_402658342 = header.getOrDefault("X-Amz-Date")
  valid_402658342 = validateParameter(valid_402658342, JString,
                                      required = false, default = nil)
  if valid_402658342 != nil:
    section.add "X-Amz-Date", valid_402658342
  var valid_402658343 = header.getOrDefault("X-Amz-Credential")
  valid_402658343 = validateParameter(valid_402658343, JString,
                                      required = false, default = nil)
  if valid_402658343 != nil:
    section.add "X-Amz-Credential", valid_402658343
  var valid_402658344 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658344 = validateParameter(valid_402658344, JString,
                                      required = false, default = nil)
  if valid_402658344 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658345: Call_GetPromoteReadReplica_402658330;
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

proc call*(call_402658346: Call_GetPromoteReadReplica_402658330;
           DBInstanceIdentifier: string; PreferredBackupWindow: string = "";
           Version: string = "2014-09-01";
           Action: string = "PromoteReadReplica"; BackupRetentionPeriod: int = 0): Recallable =
  ## getPromoteReadReplica
  ##   PreferredBackupWindow: string
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  ##   BackupRetentionPeriod: int
  var query_402658347 = newJObject()
  add(query_402658347, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_402658347, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658347, "Version", newJString(Version))
  add(query_402658347, "Action", newJString(Action))
  add(query_402658347, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  result = call_402658346.call(nil, query_402658347, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_402658330(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_402658331, base: "/",
    makeUrl: url_GetPromoteReadReplica_402658332,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_402658386 = ref object of OpenApiRestCall_402656035
proc url_PostPurchaseReservedDBInstancesOffering_402658388(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_402658387(path: JsonNode;
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
  var valid_402658389 = query.getOrDefault("Version")
  valid_402658389 = validateParameter(valid_402658389, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658389 != nil:
    section.add "Version", valid_402658389
  var valid_402658390 = query.getOrDefault("Action")
  valid_402658390 = validateParameter(valid_402658390, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
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
  ## parameters in `formData` object:
  ##   DBInstanceCount: JInt
  ##   Tags: JArray
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   ReservedDBInstanceId: JString
  section = newJObject()
  var valid_402658398 = formData.getOrDefault("DBInstanceCount")
  valid_402658398 = validateParameter(valid_402658398, JInt, required = false,
                                      default = nil)
  if valid_402658398 != nil:
    section.add "DBInstanceCount", valid_402658398
  var valid_402658399 = formData.getOrDefault("Tags")
  valid_402658399 = validateParameter(valid_402658399, JArray, required = false,
                                      default = nil)
  if valid_402658399 != nil:
    section.add "Tags", valid_402658399
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658400 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658400 = validateParameter(valid_402658400, JString, required = true,
                                      default = nil)
  if valid_402658400 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658400
  var valid_402658401 = formData.getOrDefault("ReservedDBInstanceId")
  valid_402658401 = validateParameter(valid_402658401, JString,
                                      required = false, default = nil)
  if valid_402658401 != nil:
    section.add "ReservedDBInstanceId", valid_402658401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658402: Call_PostPurchaseReservedDBInstancesOffering_402658386;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658402.validator(path, query, header, formData, body, _)
  let scheme = call_402658402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658402.makeUrl(scheme.get, call_402658402.host, call_402658402.base,
                                   call_402658402.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658402, uri, valid, _)

proc call*(call_402658403: Call_PostPurchaseReservedDBInstancesOffering_402658386;
           ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
           Tags: JsonNode = nil; Version: string = "2014-09-01";
           ReservedDBInstanceId: string = "";
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   Version: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   ReservedDBInstanceId: string
  ##   Action: string (required)
  var query_402658404 = newJObject()
  var formData_402658405 = newJObject()
  add(formData_402658405, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    formData_402658405.add "Tags", Tags
  add(query_402658404, "Version", newJString(Version))
  add(formData_402658405, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(formData_402658405, "ReservedDBInstanceId",
      newJString(ReservedDBInstanceId))
  add(query_402658404, "Action", newJString(Action))
  result = call_402658403.call(nil, query_402658404, nil, formData_402658405,
                               nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_402658386(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_402658387,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_402658388,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_402658367 = ref object of OpenApiRestCall_402656035
proc url_GetPurchaseReservedDBInstancesOffering_402658369(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_402658368(path: JsonNode;
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
  var valid_402658370 = query.getOrDefault("ReservedDBInstanceId")
  valid_402658370 = validateParameter(valid_402658370, JString,
                                      required = false, default = nil)
  if valid_402658370 != nil:
    section.add "ReservedDBInstanceId", valid_402658370
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_402658371 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_402658371 = validateParameter(valid_402658371, JString, required = true,
                                      default = nil)
  if valid_402658371 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_402658371
  var valid_402658372 = query.getOrDefault("Version")
  valid_402658372 = validateParameter(valid_402658372, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658372 != nil:
    section.add "Version", valid_402658372
  var valid_402658373 = query.getOrDefault("Tags")
  valid_402658373 = validateParameter(valid_402658373, JArray, required = false,
                                      default = nil)
  if valid_402658373 != nil:
    section.add "Tags", valid_402658373
  var valid_402658374 = query.getOrDefault("DBInstanceCount")
  valid_402658374 = validateParameter(valid_402658374, JInt, required = false,
                                      default = nil)
  if valid_402658374 != nil:
    section.add "DBInstanceCount", valid_402658374
  var valid_402658375 = query.getOrDefault("Action")
  valid_402658375 = validateParameter(valid_402658375, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_402658375 != nil:
    section.add "Action", valid_402658375
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
  var valid_402658376 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658376 = validateParameter(valid_402658376, JString,
                                      required = false, default = nil)
  if valid_402658376 != nil:
    section.add "X-Amz-Security-Token", valid_402658376
  var valid_402658377 = header.getOrDefault("X-Amz-Signature")
  valid_402658377 = validateParameter(valid_402658377, JString,
                                      required = false, default = nil)
  if valid_402658377 != nil:
    section.add "X-Amz-Signature", valid_402658377
  var valid_402658378 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658378 = validateParameter(valid_402658378, JString,
                                      required = false, default = nil)
  if valid_402658378 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658378
  var valid_402658379 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658379 = validateParameter(valid_402658379, JString,
                                      required = false, default = nil)
  if valid_402658379 != nil:
    section.add "X-Amz-Algorithm", valid_402658379
  var valid_402658380 = header.getOrDefault("X-Amz-Date")
  valid_402658380 = validateParameter(valid_402658380, JString,
                                      required = false, default = nil)
  if valid_402658380 != nil:
    section.add "X-Amz-Date", valid_402658380
  var valid_402658381 = header.getOrDefault("X-Amz-Credential")
  valid_402658381 = validateParameter(valid_402658381, JString,
                                      required = false, default = nil)
  if valid_402658381 != nil:
    section.add "X-Amz-Credential", valid_402658381
  var valid_402658382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658382 = validateParameter(valid_402658382, JString,
                                      required = false, default = nil)
  if valid_402658382 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658382
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658383: Call_GetPurchaseReservedDBInstancesOffering_402658367;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658383.validator(path, query, header, formData, body, _)
  let scheme = call_402658383.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658383.makeUrl(scheme.get, call_402658383.host, call_402658383.base,
                                   call_402658383.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658383, uri, valid, _)

proc call*(call_402658384: Call_GetPurchaseReservedDBInstancesOffering_402658367;
           ReservedDBInstancesOfferingId: string;
           ReservedDBInstanceId: string = ""; Version: string = "2014-09-01";
           Tags: JsonNode = nil; DBInstanceCount: int = 0;
           Action: string = "PurchaseReservedDBInstancesOffering"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  var query_402658385 = newJObject()
  add(query_402658385, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_402658385, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_402658385, "Version", newJString(Version))
  if Tags != nil:
    query_402658385.add "Tags", Tags
  add(query_402658385, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_402658385, "Action", newJString(Action))
  result = call_402658384.call(nil, query_402658385, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_402658367(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_402658368,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_402658369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_402658423 = ref object of OpenApiRestCall_402656035
proc url_PostRebootDBInstance_402658425(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_402658424(path: JsonNode; query: JsonNode;
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
  var valid_402658426 = query.getOrDefault("Version")
  valid_402658426 = validateParameter(valid_402658426, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658426 != nil:
    section.add "Version", valid_402658426
  var valid_402658427 = query.getOrDefault("Action")
  valid_402658427 = validateParameter(valid_402658427, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658427 != nil:
    section.add "Action", valid_402658427
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
  var valid_402658428 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658428 = validateParameter(valid_402658428, JString,
                                      required = false, default = nil)
  if valid_402658428 != nil:
    section.add "X-Amz-Security-Token", valid_402658428
  var valid_402658429 = header.getOrDefault("X-Amz-Signature")
  valid_402658429 = validateParameter(valid_402658429, JString,
                                      required = false, default = nil)
  if valid_402658429 != nil:
    section.add "X-Amz-Signature", valid_402658429
  var valid_402658430 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658430 = validateParameter(valid_402658430, JString,
                                      required = false, default = nil)
  if valid_402658430 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658430
  var valid_402658431 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658431 = validateParameter(valid_402658431, JString,
                                      required = false, default = nil)
  if valid_402658431 != nil:
    section.add "X-Amz-Algorithm", valid_402658431
  var valid_402658432 = header.getOrDefault("X-Amz-Date")
  valid_402658432 = validateParameter(valid_402658432, JString,
                                      required = false, default = nil)
  if valid_402658432 != nil:
    section.add "X-Amz-Date", valid_402658432
  var valid_402658433 = header.getOrDefault("X-Amz-Credential")
  valid_402658433 = validateParameter(valid_402658433, JString,
                                      required = false, default = nil)
  if valid_402658433 != nil:
    section.add "X-Amz-Credential", valid_402658433
  var valid_402658434 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658434 = validateParameter(valid_402658434, JString,
                                      required = false, default = nil)
  if valid_402658434 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658434
  result.add "header", section
  ## parameters in `formData` object:
  ##   ForceFailover: JBool
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658435 = formData.getOrDefault("ForceFailover")
  valid_402658435 = validateParameter(valid_402658435, JBool, required = false,
                                      default = nil)
  if valid_402658435 != nil:
    section.add "ForceFailover", valid_402658435
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658436 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658436 = validateParameter(valid_402658436, JString, required = true,
                                      default = nil)
  if valid_402658436 != nil:
    section.add "DBInstanceIdentifier", valid_402658436
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658437: Call_PostRebootDBInstance_402658423;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658437.validator(path, query, header, formData, body, _)
  let scheme = call_402658437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658437.makeUrl(scheme.get, call_402658437.host, call_402658437.base,
                                   call_402658437.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658437, uri, valid, _)

proc call*(call_402658438: Call_PostRebootDBInstance_402658423;
           DBInstanceIdentifier: string; Version: string = "2014-09-01";
           ForceFailover: bool = false; Action: string = "RebootDBInstance"): Recallable =
  ## postRebootDBInstance
  ##   Version: string (required)
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  var query_402658439 = newJObject()
  var formData_402658440 = newJObject()
  add(query_402658439, "Version", newJString(Version))
  add(formData_402658440, "ForceFailover", newJBool(ForceFailover))
  add(formData_402658440, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(query_402658439, "Action", newJString(Action))
  result = call_402658438.call(nil, query_402658439, nil, formData_402658440,
                               nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_402658423(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_402658424, base: "/",
    makeUrl: url_PostRebootDBInstance_402658425,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_402658406 = ref object of OpenApiRestCall_402656035
proc url_GetRebootDBInstance_402658408(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_402658407(path: JsonNode; query: JsonNode;
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
  var valid_402658409 = query.getOrDefault("ForceFailover")
  valid_402658409 = validateParameter(valid_402658409, JBool, required = false,
                                      default = nil)
  if valid_402658409 != nil:
    section.add "ForceFailover", valid_402658409
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658410 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658410 = validateParameter(valid_402658410, JString, required = true,
                                      default = nil)
  if valid_402658410 != nil:
    section.add "DBInstanceIdentifier", valid_402658410
  var valid_402658411 = query.getOrDefault("Version")
  valid_402658411 = validateParameter(valid_402658411, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658411 != nil:
    section.add "Version", valid_402658411
  var valid_402658412 = query.getOrDefault("Action")
  valid_402658412 = validateParameter(valid_402658412, JString, required = true,
                                      default = newJString("RebootDBInstance"))
  if valid_402658412 != nil:
    section.add "Action", valid_402658412
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
  var valid_402658413 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658413 = validateParameter(valid_402658413, JString,
                                      required = false, default = nil)
  if valid_402658413 != nil:
    section.add "X-Amz-Security-Token", valid_402658413
  var valid_402658414 = header.getOrDefault("X-Amz-Signature")
  valid_402658414 = validateParameter(valid_402658414, JString,
                                      required = false, default = nil)
  if valid_402658414 != nil:
    section.add "X-Amz-Signature", valid_402658414
  var valid_402658415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658415 = validateParameter(valid_402658415, JString,
                                      required = false, default = nil)
  if valid_402658415 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658415
  var valid_402658416 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658416 = validateParameter(valid_402658416, JString,
                                      required = false, default = nil)
  if valid_402658416 != nil:
    section.add "X-Amz-Algorithm", valid_402658416
  var valid_402658417 = header.getOrDefault("X-Amz-Date")
  valid_402658417 = validateParameter(valid_402658417, JString,
                                      required = false, default = nil)
  if valid_402658417 != nil:
    section.add "X-Amz-Date", valid_402658417
  var valid_402658418 = header.getOrDefault("X-Amz-Credential")
  valid_402658418 = validateParameter(valid_402658418, JString,
                                      required = false, default = nil)
  if valid_402658418 != nil:
    section.add "X-Amz-Credential", valid_402658418
  var valid_402658419 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658419 = validateParameter(valid_402658419, JString,
                                      required = false, default = nil)
  if valid_402658419 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658419
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658420: Call_GetRebootDBInstance_402658406;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658420.validator(path, query, header, formData, body, _)
  let scheme = call_402658420.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658420.makeUrl(scheme.get, call_402658420.host, call_402658420.base,
                                   call_402658420.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658420, uri, valid, _)

proc call*(call_402658421: Call_GetRebootDBInstance_402658406;
           DBInstanceIdentifier: string; ForceFailover: bool = false;
           Version: string = "2014-09-01"; Action: string = "RebootDBInstance"): Recallable =
  ## getRebootDBInstance
  ##   ForceFailover: bool
  ##   DBInstanceIdentifier: string (required)
  ##   Version: string (required)
  ##   Action: string (required)
  var query_402658422 = newJObject()
  add(query_402658422, "ForceFailover", newJBool(ForceFailover))
  add(query_402658422, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658422, "Version", newJString(Version))
  add(query_402658422, "Action", newJString(Action))
  result = call_402658421.call(nil, query_402658422, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_402658406(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_402658407, base: "/",
    makeUrl: url_GetRebootDBInstance_402658408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_402658458 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveSourceIdentifierFromSubscription_402658460(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_402658459(
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
  var valid_402658461 = query.getOrDefault("Version")
  valid_402658461 = validateParameter(valid_402658461, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658461 != nil:
    section.add "Version", valid_402658461
  var valid_402658462 = query.getOrDefault("Action")
  valid_402658462 = validateParameter(valid_402658462, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658462 != nil:
    section.add "Action", valid_402658462
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
  var valid_402658463 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658463 = validateParameter(valid_402658463, JString,
                                      required = false, default = nil)
  if valid_402658463 != nil:
    section.add "X-Amz-Security-Token", valid_402658463
  var valid_402658464 = header.getOrDefault("X-Amz-Signature")
  valid_402658464 = validateParameter(valid_402658464, JString,
                                      required = false, default = nil)
  if valid_402658464 != nil:
    section.add "X-Amz-Signature", valid_402658464
  var valid_402658465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658465 = validateParameter(valid_402658465, JString,
                                      required = false, default = nil)
  if valid_402658465 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658465
  var valid_402658466 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658466 = validateParameter(valid_402658466, JString,
                                      required = false, default = nil)
  if valid_402658466 != nil:
    section.add "X-Amz-Algorithm", valid_402658466
  var valid_402658467 = header.getOrDefault("X-Amz-Date")
  valid_402658467 = validateParameter(valid_402658467, JString,
                                      required = false, default = nil)
  if valid_402658467 != nil:
    section.add "X-Amz-Date", valid_402658467
  var valid_402658468 = header.getOrDefault("X-Amz-Credential")
  valid_402658468 = validateParameter(valid_402658468, JString,
                                      required = false, default = nil)
  if valid_402658468 != nil:
    section.add "X-Amz-Credential", valid_402658468
  var valid_402658469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658469 = validateParameter(valid_402658469, JString,
                                      required = false, default = nil)
  if valid_402658469 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658469
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_402658470 = formData.getOrDefault("SourceIdentifier")
  valid_402658470 = validateParameter(valid_402658470, JString, required = true,
                                      default = nil)
  if valid_402658470 != nil:
    section.add "SourceIdentifier", valid_402658470
  var valid_402658471 = formData.getOrDefault("SubscriptionName")
  valid_402658471 = validateParameter(valid_402658471, JString, required = true,
                                      default = nil)
  if valid_402658471 != nil:
    section.add "SubscriptionName", valid_402658471
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658472: Call_PostRemoveSourceIdentifierFromSubscription_402658458;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658472.validator(path, query, header, formData, body, _)
  let scheme = call_402658472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658472.makeUrl(scheme.get, call_402658472.host, call_402658472.base,
                                   call_402658472.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658472, uri, valid, _)

proc call*(call_402658473: Call_PostRemoveSourceIdentifierFromSubscription_402658458;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2014-09-01";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   Version: string (required)
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  var query_402658474 = newJObject()
  var formData_402658475 = newJObject()
  add(query_402658474, "Version", newJString(Version))
  add(query_402658474, "Action", newJString(Action))
  add(formData_402658475, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_402658475, "SubscriptionName", newJString(SubscriptionName))
  result = call_402658473.call(nil, query_402658474, nil, formData_402658475,
                               nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_402658458(
    name: "postRemoveSourceIdentifierFromSubscription",
    meth: HttpMethod.HttpPost, host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_402658459,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_402658460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_402658441 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveSourceIdentifierFromSubscription_402658443(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_402658442(
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
  var valid_402658444 = query.getOrDefault("SourceIdentifier")
  valid_402658444 = validateParameter(valid_402658444, JString, required = true,
                                      default = nil)
  if valid_402658444 != nil:
    section.add "SourceIdentifier", valid_402658444
  var valid_402658445 = query.getOrDefault("Version")
  valid_402658445 = validateParameter(valid_402658445, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658445 != nil:
    section.add "Version", valid_402658445
  var valid_402658446 = query.getOrDefault("SubscriptionName")
  valid_402658446 = validateParameter(valid_402658446, JString, required = true,
                                      default = nil)
  if valid_402658446 != nil:
    section.add "SubscriptionName", valid_402658446
  var valid_402658447 = query.getOrDefault("Action")
  valid_402658447 = validateParameter(valid_402658447, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_402658447 != nil:
    section.add "Action", valid_402658447
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
  var valid_402658448 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658448 = validateParameter(valid_402658448, JString,
                                      required = false, default = nil)
  if valid_402658448 != nil:
    section.add "X-Amz-Security-Token", valid_402658448
  var valid_402658449 = header.getOrDefault("X-Amz-Signature")
  valid_402658449 = validateParameter(valid_402658449, JString,
                                      required = false, default = nil)
  if valid_402658449 != nil:
    section.add "X-Amz-Signature", valid_402658449
  var valid_402658450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658450 = validateParameter(valid_402658450, JString,
                                      required = false, default = nil)
  if valid_402658450 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658450
  var valid_402658451 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658451 = validateParameter(valid_402658451, JString,
                                      required = false, default = nil)
  if valid_402658451 != nil:
    section.add "X-Amz-Algorithm", valid_402658451
  var valid_402658452 = header.getOrDefault("X-Amz-Date")
  valid_402658452 = validateParameter(valid_402658452, JString,
                                      required = false, default = nil)
  if valid_402658452 != nil:
    section.add "X-Amz-Date", valid_402658452
  var valid_402658453 = header.getOrDefault("X-Amz-Credential")
  valid_402658453 = validateParameter(valid_402658453, JString,
                                      required = false, default = nil)
  if valid_402658453 != nil:
    section.add "X-Amz-Credential", valid_402658453
  var valid_402658454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658454 = validateParameter(valid_402658454, JString,
                                      required = false, default = nil)
  if valid_402658454 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658455: Call_GetRemoveSourceIdentifierFromSubscription_402658441;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658455.validator(path, query, header, formData, body, _)
  let scheme = call_402658455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658455.makeUrl(scheme.get, call_402658455.host, call_402658455.base,
                                   call_402658455.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658455, uri, valid, _)

proc call*(call_402658456: Call_GetRemoveSourceIdentifierFromSubscription_402658441;
           SourceIdentifier: string; SubscriptionName: string;
           Version: string = "2014-09-01";
           Action: string = "RemoveSourceIdentifierFromSubscription"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   Version: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  var query_402658457 = newJObject()
  add(query_402658457, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_402658457, "Version", newJString(Version))
  add(query_402658457, "SubscriptionName", newJString(SubscriptionName))
  add(query_402658457, "Action", newJString(Action))
  result = call_402658456.call(nil, query_402658457, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_402658441(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_402658442,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_402658443,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_402658493 = ref object of OpenApiRestCall_402656035
proc url_PostRemoveTagsFromResource_402658495(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_402658494(path: JsonNode;
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
  var valid_402658496 = query.getOrDefault("Version")
  valid_402658496 = validateParameter(valid_402658496, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658496 != nil:
    section.add "Version", valid_402658496
  var valid_402658497 = query.getOrDefault("Action")
  valid_402658497 = validateParameter(valid_402658497, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658497 != nil:
    section.add "Action", valid_402658497
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
  var valid_402658498 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658498 = validateParameter(valid_402658498, JString,
                                      required = false, default = nil)
  if valid_402658498 != nil:
    section.add "X-Amz-Security-Token", valid_402658498
  var valid_402658499 = header.getOrDefault("X-Amz-Signature")
  valid_402658499 = validateParameter(valid_402658499, JString,
                                      required = false, default = nil)
  if valid_402658499 != nil:
    section.add "X-Amz-Signature", valid_402658499
  var valid_402658500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658500 = validateParameter(valid_402658500, JString,
                                      required = false, default = nil)
  if valid_402658500 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658500
  var valid_402658501 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658501 = validateParameter(valid_402658501, JString,
                                      required = false, default = nil)
  if valid_402658501 != nil:
    section.add "X-Amz-Algorithm", valid_402658501
  var valid_402658502 = header.getOrDefault("X-Amz-Date")
  valid_402658502 = validateParameter(valid_402658502, JString,
                                      required = false, default = nil)
  if valid_402658502 != nil:
    section.add "X-Amz-Date", valid_402658502
  var valid_402658503 = header.getOrDefault("X-Amz-Credential")
  valid_402658503 = validateParameter(valid_402658503, JString,
                                      required = false, default = nil)
  if valid_402658503 != nil:
    section.add "X-Amz-Credential", valid_402658503
  var valid_402658504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658504 = validateParameter(valid_402658504, JString,
                                      required = false, default = nil)
  if valid_402658504 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658504
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
         "formData argument is necessary due to required `TagKeys` field"
  var valid_402658505 = formData.getOrDefault("TagKeys")
  valid_402658505 = validateParameter(valid_402658505, JArray, required = true,
                                      default = nil)
  if valid_402658505 != nil:
    section.add "TagKeys", valid_402658505
  var valid_402658506 = formData.getOrDefault("ResourceName")
  valid_402658506 = validateParameter(valid_402658506, JString, required = true,
                                      default = nil)
  if valid_402658506 != nil:
    section.add "ResourceName", valid_402658506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658507: Call_PostRemoveTagsFromResource_402658493;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658507.validator(path, query, header, formData, body, _)
  let scheme = call_402658507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658507.makeUrl(scheme.get, call_402658507.host, call_402658507.base,
                                   call_402658507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658507, uri, valid, _)

proc call*(call_402658508: Call_PostRemoveTagsFromResource_402658493;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2014-09-01";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## postRemoveTagsFromResource
  ##   Version: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  var query_402658509 = newJObject()
  var formData_402658510 = newJObject()
  add(query_402658509, "Version", newJString(Version))
  add(query_402658509, "Action", newJString(Action))
  if TagKeys != nil:
    formData_402658510.add "TagKeys", TagKeys
  add(formData_402658510, "ResourceName", newJString(ResourceName))
  result = call_402658508.call(nil, query_402658509, nil, formData_402658510,
                               nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_402658493(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_402658494, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_402658495,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_402658476 = ref object of OpenApiRestCall_402656035
proc url_GetRemoveTagsFromResource_402658478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_402658477(path: JsonNode;
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
  var valid_402658479 = query.getOrDefault("TagKeys")
  valid_402658479 = validateParameter(valid_402658479, JArray, required = true,
                                      default = nil)
  if valid_402658479 != nil:
    section.add "TagKeys", valid_402658479
  var valid_402658480 = query.getOrDefault("Version")
  valid_402658480 = validateParameter(valid_402658480, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658480 != nil:
    section.add "Version", valid_402658480
  var valid_402658481 = query.getOrDefault("ResourceName")
  valid_402658481 = validateParameter(valid_402658481, JString, required = true,
                                      default = nil)
  if valid_402658481 != nil:
    section.add "ResourceName", valid_402658481
  var valid_402658482 = query.getOrDefault("Action")
  valid_402658482 = validateParameter(valid_402658482, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_402658482 != nil:
    section.add "Action", valid_402658482
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
  var valid_402658483 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658483 = validateParameter(valid_402658483, JString,
                                      required = false, default = nil)
  if valid_402658483 != nil:
    section.add "X-Amz-Security-Token", valid_402658483
  var valid_402658484 = header.getOrDefault("X-Amz-Signature")
  valid_402658484 = validateParameter(valid_402658484, JString,
                                      required = false, default = nil)
  if valid_402658484 != nil:
    section.add "X-Amz-Signature", valid_402658484
  var valid_402658485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658485 = validateParameter(valid_402658485, JString,
                                      required = false, default = nil)
  if valid_402658485 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658485
  var valid_402658486 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658486 = validateParameter(valid_402658486, JString,
                                      required = false, default = nil)
  if valid_402658486 != nil:
    section.add "X-Amz-Algorithm", valid_402658486
  var valid_402658487 = header.getOrDefault("X-Amz-Date")
  valid_402658487 = validateParameter(valid_402658487, JString,
                                      required = false, default = nil)
  if valid_402658487 != nil:
    section.add "X-Amz-Date", valid_402658487
  var valid_402658488 = header.getOrDefault("X-Amz-Credential")
  valid_402658488 = validateParameter(valid_402658488, JString,
                                      required = false, default = nil)
  if valid_402658488 != nil:
    section.add "X-Amz-Credential", valid_402658488
  var valid_402658489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658489 = validateParameter(valid_402658489, JString,
                                      required = false, default = nil)
  if valid_402658489 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658490: Call_GetRemoveTagsFromResource_402658476;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658490.validator(path, query, header, formData, body, _)
  let scheme = call_402658490.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658490.makeUrl(scheme.get, call_402658490.host, call_402658490.base,
                                   call_402658490.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658490, uri, valid, _)

proc call*(call_402658491: Call_GetRemoveTagsFromResource_402658476;
           TagKeys: JsonNode; ResourceName: string;
           Version: string = "2014-09-01";
           Action: string = "RemoveTagsFromResource"): Recallable =
  ## getRemoveTagsFromResource
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  var query_402658492 = newJObject()
  if TagKeys != nil:
    query_402658492.add "TagKeys", TagKeys
  add(query_402658492, "Version", newJString(Version))
  add(query_402658492, "ResourceName", newJString(ResourceName))
  add(query_402658492, "Action", newJString(Action))
  result = call_402658491.call(nil, query_402658492, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_402658476(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_402658477, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_402658478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_402658529 = ref object of OpenApiRestCall_402656035
proc url_PostResetDBParameterGroup_402658531(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_402658530(path: JsonNode;
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
  var valid_402658532 = query.getOrDefault("Version")
  valid_402658532 = validateParameter(valid_402658532, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658532 != nil:
    section.add "Version", valid_402658532
  var valid_402658533 = query.getOrDefault("Action")
  valid_402658533 = validateParameter(valid_402658533, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658533 != nil:
    section.add "Action", valid_402658533
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
  var valid_402658534 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658534 = validateParameter(valid_402658534, JString,
                                      required = false, default = nil)
  if valid_402658534 != nil:
    section.add "X-Amz-Security-Token", valid_402658534
  var valid_402658535 = header.getOrDefault("X-Amz-Signature")
  valid_402658535 = validateParameter(valid_402658535, JString,
                                      required = false, default = nil)
  if valid_402658535 != nil:
    section.add "X-Amz-Signature", valid_402658535
  var valid_402658536 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658536 = validateParameter(valid_402658536, JString,
                                      required = false, default = nil)
  if valid_402658536 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658536
  var valid_402658537 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658537 = validateParameter(valid_402658537, JString,
                                      required = false, default = nil)
  if valid_402658537 != nil:
    section.add "X-Amz-Algorithm", valid_402658537
  var valid_402658538 = header.getOrDefault("X-Amz-Date")
  valid_402658538 = validateParameter(valid_402658538, JString,
                                      required = false, default = nil)
  if valid_402658538 != nil:
    section.add "X-Amz-Date", valid_402658538
  var valid_402658539 = header.getOrDefault("X-Amz-Credential")
  valid_402658539 = validateParameter(valid_402658539, JString,
                                      required = false, default = nil)
  if valid_402658539 != nil:
    section.add "X-Amz-Credential", valid_402658539
  var valid_402658540 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658540 = validateParameter(valid_402658540, JString,
                                      required = false, default = nil)
  if valid_402658540 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658540
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658541 = formData.getOrDefault("DBParameterGroupName")
  valid_402658541 = validateParameter(valid_402658541, JString, required = true,
                                      default = nil)
  if valid_402658541 != nil:
    section.add "DBParameterGroupName", valid_402658541
  var valid_402658542 = formData.getOrDefault("Parameters")
  valid_402658542 = validateParameter(valid_402658542, JArray, required = false,
                                      default = nil)
  if valid_402658542 != nil:
    section.add "Parameters", valid_402658542
  var valid_402658543 = formData.getOrDefault("ResetAllParameters")
  valid_402658543 = validateParameter(valid_402658543, JBool, required = false,
                                      default = nil)
  if valid_402658543 != nil:
    section.add "ResetAllParameters", valid_402658543
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658544: Call_PostResetDBParameterGroup_402658529;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658544.validator(path, query, header, formData, body, _)
  let scheme = call_402658544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658544.makeUrl(scheme.get, call_402658544.host, call_402658544.base,
                                   call_402658544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658544, uri, valid, _)

proc call*(call_402658545: Call_PostResetDBParameterGroup_402658529;
           DBParameterGroupName: string; Version: string = "2014-09-01";
           Action: string = "ResetDBParameterGroup"; Parameters: JsonNode = nil;
           ResetAllParameters: bool = false): Recallable =
  ## postResetDBParameterGroup
  ##   Version: string (required)
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: bool
  var query_402658546 = newJObject()
  var formData_402658547 = newJObject()
  add(query_402658546, "Version", newJString(Version))
  add(formData_402658547, "DBParameterGroupName",
      newJString(DBParameterGroupName))
  add(query_402658546, "Action", newJString(Action))
  if Parameters != nil:
    formData_402658547.add "Parameters", Parameters
  add(formData_402658547, "ResetAllParameters", newJBool(ResetAllParameters))
  result = call_402658545.call(nil, query_402658546, nil, formData_402658547,
                               nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_402658529(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_402658530, base: "/",
    makeUrl: url_PostResetDBParameterGroup_402658531,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_402658511 = ref object of OpenApiRestCall_402656035
proc url_GetResetDBParameterGroup_402658513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_402658512(path: JsonNode;
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
  var valid_402658514 = query.getOrDefault("Parameters")
  valid_402658514 = validateParameter(valid_402658514, JArray, required = false,
                                      default = nil)
  if valid_402658514 != nil:
    section.add "Parameters", valid_402658514
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_402658515 = query.getOrDefault("DBParameterGroupName")
  valid_402658515 = validateParameter(valid_402658515, JString, required = true,
                                      default = nil)
  if valid_402658515 != nil:
    section.add "DBParameterGroupName", valid_402658515
  var valid_402658516 = query.getOrDefault("Version")
  valid_402658516 = validateParameter(valid_402658516, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658516 != nil:
    section.add "Version", valid_402658516
  var valid_402658517 = query.getOrDefault("ResetAllParameters")
  valid_402658517 = validateParameter(valid_402658517, JBool, required = false,
                                      default = nil)
  if valid_402658517 != nil:
    section.add "ResetAllParameters", valid_402658517
  var valid_402658518 = query.getOrDefault("Action")
  valid_402658518 = validateParameter(valid_402658518, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_402658518 != nil:
    section.add "Action", valid_402658518
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
  var valid_402658519 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658519 = validateParameter(valid_402658519, JString,
                                      required = false, default = nil)
  if valid_402658519 != nil:
    section.add "X-Amz-Security-Token", valid_402658519
  var valid_402658520 = header.getOrDefault("X-Amz-Signature")
  valid_402658520 = validateParameter(valid_402658520, JString,
                                      required = false, default = nil)
  if valid_402658520 != nil:
    section.add "X-Amz-Signature", valid_402658520
  var valid_402658521 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658521 = validateParameter(valid_402658521, JString,
                                      required = false, default = nil)
  if valid_402658521 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658521
  var valid_402658522 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658522 = validateParameter(valid_402658522, JString,
                                      required = false, default = nil)
  if valid_402658522 != nil:
    section.add "X-Amz-Algorithm", valid_402658522
  var valid_402658523 = header.getOrDefault("X-Amz-Date")
  valid_402658523 = validateParameter(valid_402658523, JString,
                                      required = false, default = nil)
  if valid_402658523 != nil:
    section.add "X-Amz-Date", valid_402658523
  var valid_402658524 = header.getOrDefault("X-Amz-Credential")
  valid_402658524 = validateParameter(valid_402658524, JString,
                                      required = false, default = nil)
  if valid_402658524 != nil:
    section.add "X-Amz-Credential", valid_402658524
  var valid_402658525 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658525 = validateParameter(valid_402658525, JString,
                                      required = false, default = nil)
  if valid_402658525 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658525
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658526: Call_GetResetDBParameterGroup_402658511;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658526.validator(path, query, header, formData, body, _)
  let scheme = call_402658526.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658526.makeUrl(scheme.get, call_402658526.host, call_402658526.base,
                                   call_402658526.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658526, uri, valid, _)

proc call*(call_402658527: Call_GetResetDBParameterGroup_402658511;
           DBParameterGroupName: string; Parameters: JsonNode = nil;
           Version: string = "2014-09-01"; ResetAllParameters: bool = false;
           Action: string = "ResetDBParameterGroup"): Recallable =
  ## getResetDBParameterGroup
  ##   Parameters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Version: string (required)
  ##   ResetAllParameters: bool
  ##   Action: string (required)
  var query_402658528 = newJObject()
  if Parameters != nil:
    query_402658528.add "Parameters", Parameters
  add(query_402658528, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_402658528, "Version", newJString(Version))
  add(query_402658528, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_402658528, "Action", newJString(Action))
  result = call_402658527.call(nil, query_402658528, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_402658511(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_402658512, base: "/",
    makeUrl: url_GetResetDBParameterGroup_402658513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_402658581 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceFromDBSnapshot_402658583(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_402658582(path: JsonNode;
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
  var valid_402658584 = query.getOrDefault("Version")
  valid_402658584 = validateParameter(valid_402658584, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658584 != nil:
    section.add "Version", valid_402658584
  var valid_402658585 = query.getOrDefault("Action")
  valid_402658585 = validateParameter(valid_402658585, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658585 != nil:
    section.add "Action", valid_402658585
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
  var valid_402658586 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658586 = validateParameter(valid_402658586, JString,
                                      required = false, default = nil)
  if valid_402658586 != nil:
    section.add "X-Amz-Security-Token", valid_402658586
  var valid_402658587 = header.getOrDefault("X-Amz-Signature")
  valid_402658587 = validateParameter(valid_402658587, JString,
                                      required = false, default = nil)
  if valid_402658587 != nil:
    section.add "X-Amz-Signature", valid_402658587
  var valid_402658588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658588 = validateParameter(valid_402658588, JString,
                                      required = false, default = nil)
  if valid_402658588 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658588
  var valid_402658589 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658589 = validateParameter(valid_402658589, JString,
                                      required = false, default = nil)
  if valid_402658589 != nil:
    section.add "X-Amz-Algorithm", valid_402658589
  var valid_402658590 = header.getOrDefault("X-Amz-Date")
  valid_402658590 = validateParameter(valid_402658590, JString,
                                      required = false, default = nil)
  if valid_402658590 != nil:
    section.add "X-Amz-Date", valid_402658590
  var valid_402658591 = header.getOrDefault("X-Amz-Credential")
  valid_402658591 = validateParameter(valid_402658591, JString,
                                      required = false, default = nil)
  if valid_402658591 != nil:
    section.add "X-Amz-Credential", valid_402658591
  var valid_402658592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658592 = validateParameter(valid_402658592, JString,
                                      required = false, default = nil)
  if valid_402658592 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658592
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialArn: JString
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
  ##   TdeCredentialPassword: JString
  ##   DBSnapshotIdentifier: JString (required)
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  ##   StorageType: JString
  section = newJObject()
  var valid_402658593 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658593 = validateParameter(valid_402658593, JBool, required = false,
                                      default = nil)
  if valid_402658593 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658593
  var valid_402658594 = formData.getOrDefault("TdeCredentialArn")
  valid_402658594 = validateParameter(valid_402658594, JString,
                                      required = false, default = nil)
  if valid_402658594 != nil:
    section.add "TdeCredentialArn", valid_402658594
  var valid_402658595 = formData.getOrDefault("Port")
  valid_402658595 = validateParameter(valid_402658595, JInt, required = false,
                                      default = nil)
  if valid_402658595 != nil:
    section.add "Port", valid_402658595
  var valid_402658596 = formData.getOrDefault("Engine")
  valid_402658596 = validateParameter(valid_402658596, JString,
                                      required = false, default = nil)
  if valid_402658596 != nil:
    section.add "Engine", valid_402658596
  var valid_402658597 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658597 = validateParameter(valid_402658597, JString,
                                      required = false, default = nil)
  if valid_402658597 != nil:
    section.add "DBSubnetGroupName", valid_402658597
  var valid_402658598 = formData.getOrDefault("PubliclyAccessible")
  valid_402658598 = validateParameter(valid_402658598, JBool, required = false,
                                      default = nil)
  if valid_402658598 != nil:
    section.add "PubliclyAccessible", valid_402658598
  var valid_402658599 = formData.getOrDefault("AvailabilityZone")
  valid_402658599 = validateParameter(valid_402658599, JString,
                                      required = false, default = nil)
  if valid_402658599 != nil:
    section.add "AvailabilityZone", valid_402658599
  var valid_402658600 = formData.getOrDefault("DBName")
  valid_402658600 = validateParameter(valid_402658600, JString,
                                      required = false, default = nil)
  if valid_402658600 != nil:
    section.add "DBName", valid_402658600
  var valid_402658601 = formData.getOrDefault("Tags")
  valid_402658601 = validateParameter(valid_402658601, JArray, required = false,
                                      default = nil)
  if valid_402658601 != nil:
    section.add "Tags", valid_402658601
  var valid_402658602 = formData.getOrDefault("Iops")
  valid_402658602 = validateParameter(valid_402658602, JInt, required = false,
                                      default = nil)
  if valid_402658602 != nil:
    section.add "Iops", valid_402658602
  var valid_402658603 = formData.getOrDefault("DBInstanceClass")
  valid_402658603 = validateParameter(valid_402658603, JString,
                                      required = false, default = nil)
  if valid_402658603 != nil:
    section.add "DBInstanceClass", valid_402658603
  var valid_402658604 = formData.getOrDefault("LicenseModel")
  valid_402658604 = validateParameter(valid_402658604, JString,
                                      required = false, default = nil)
  if valid_402658604 != nil:
    section.add "LicenseModel", valid_402658604
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658605 = formData.getOrDefault("DBInstanceIdentifier")
  valid_402658605 = validateParameter(valid_402658605, JString, required = true,
                                      default = nil)
  if valid_402658605 != nil:
    section.add "DBInstanceIdentifier", valid_402658605
  var valid_402658606 = formData.getOrDefault("TdeCredentialPassword")
  valid_402658606 = validateParameter(valid_402658606, JString,
                                      required = false, default = nil)
  if valid_402658606 != nil:
    section.add "TdeCredentialPassword", valid_402658606
  var valid_402658607 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_402658607 = validateParameter(valid_402658607, JString, required = true,
                                      default = nil)
  if valid_402658607 != nil:
    section.add "DBSnapshotIdentifier", valid_402658607
  var valid_402658608 = formData.getOrDefault("MultiAZ")
  valid_402658608 = validateParameter(valid_402658608, JBool, required = false,
                                      default = nil)
  if valid_402658608 != nil:
    section.add "MultiAZ", valid_402658608
  var valid_402658609 = formData.getOrDefault("OptionGroupName")
  valid_402658609 = validateParameter(valid_402658609, JString,
                                      required = false, default = nil)
  if valid_402658609 != nil:
    section.add "OptionGroupName", valid_402658609
  var valid_402658610 = formData.getOrDefault("StorageType")
  valid_402658610 = validateParameter(valid_402658610, JString,
                                      required = false, default = nil)
  if valid_402658610 != nil:
    section.add "StorageType", valid_402658610
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658611: Call_PostRestoreDBInstanceFromDBSnapshot_402658581;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658611.validator(path, query, header, formData, body, _)
  let scheme = call_402658611.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658611.makeUrl(scheme.get, call_402658611.host, call_402658611.base,
                                   call_402658611.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658611, uri, valid, _)

proc call*(call_402658612: Call_PostRestoreDBInstanceFromDBSnapshot_402658581;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; TdeCredentialArn: string = "";
           Port: int = 0; Engine: string = ""; DBSubnetGroupName: string = "";
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           DBName: string = ""; Tags: JsonNode = nil;
           Version: string = "2014-09-01"; Iops: int = 0;
           DBInstanceClass: string = ""; LicenseModel: string = "";
           TdeCredentialPassword: string = ""; MultiAZ: bool = false;
           OptionGroupName: string = "";
           Action: string = "RestoreDBInstanceFromDBSnapshot";
           StorageType: string = ""): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialArn: string
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
  ##   TdeCredentialPassword: string
  ##   DBSnapshotIdentifier: string (required)
  ##   MultiAZ: bool
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   StorageType: string
  var query_402658613 = newJObject()
  var formData_402658614 = newJObject()
  add(formData_402658614, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658614, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_402658614, "Port", newJInt(Port))
  add(formData_402658614, "Engine", newJString(Engine))
  add(formData_402658614, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658614, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658614, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658614, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402658614.add "Tags", Tags
  add(query_402658613, "Version", newJString(Version))
  add(formData_402658614, "Iops", newJInt(Iops))
  add(formData_402658614, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658614, "LicenseModel", newJString(LicenseModel))
  add(formData_402658614, "DBInstanceIdentifier",
      newJString(DBInstanceIdentifier))
  add(formData_402658614, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_402658614, "DBSnapshotIdentifier",
      newJString(DBSnapshotIdentifier))
  add(formData_402658614, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658614, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658613, "Action", newJString(Action))
  add(formData_402658614, "StorageType", newJString(StorageType))
  result = call_402658612.call(nil, query_402658613, nil, formData_402658614,
                               nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_402658581(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_402658582,
    base: "/", makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_402658583,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_402658548 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceFromDBSnapshot_402658550(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_402658549(path: JsonNode;
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
  ##   TdeCredentialPassword: JString
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   StorageType: JString
  ##   MultiAZ: JBool
  ##   Version: JString (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Engine: JString
  ##   Port: JInt
  ##   TdeCredentialArn: JString
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402658551 = query.getOrDefault("PubliclyAccessible")
  valid_402658551 = validateParameter(valid_402658551, JBool, required = false,
                                      default = nil)
  if valid_402658551 != nil:
    section.add "PubliclyAccessible", valid_402658551
  var valid_402658552 = query.getOrDefault("OptionGroupName")
  valid_402658552 = validateParameter(valid_402658552, JString,
                                      required = false, default = nil)
  if valid_402658552 != nil:
    section.add "OptionGroupName", valid_402658552
  assert query != nil, "query argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_402658553 = query.getOrDefault("DBInstanceIdentifier")
  valid_402658553 = validateParameter(valid_402658553, JString, required = true,
                                      default = nil)
  if valid_402658553 != nil:
    section.add "DBInstanceIdentifier", valid_402658553
  var valid_402658554 = query.getOrDefault("DBSubnetGroupName")
  valid_402658554 = validateParameter(valid_402658554, JString,
                                      required = false, default = nil)
  if valid_402658554 != nil:
    section.add "DBSubnetGroupName", valid_402658554
  var valid_402658555 = query.getOrDefault("TdeCredentialPassword")
  valid_402658555 = validateParameter(valid_402658555, JString,
                                      required = false, default = nil)
  if valid_402658555 != nil:
    section.add "TdeCredentialPassword", valid_402658555
  var valid_402658556 = query.getOrDefault("Iops")
  valid_402658556 = validateParameter(valid_402658556, JInt, required = false,
                                      default = nil)
  if valid_402658556 != nil:
    section.add "Iops", valid_402658556
  var valid_402658557 = query.getOrDefault("AvailabilityZone")
  valid_402658557 = validateParameter(valid_402658557, JString,
                                      required = false, default = nil)
  if valid_402658557 != nil:
    section.add "AvailabilityZone", valid_402658557
  var valid_402658558 = query.getOrDefault("StorageType")
  valid_402658558 = validateParameter(valid_402658558, JString,
                                      required = false, default = nil)
  if valid_402658558 != nil:
    section.add "StorageType", valid_402658558
  var valid_402658559 = query.getOrDefault("MultiAZ")
  valid_402658559 = validateParameter(valid_402658559, JBool, required = false,
                                      default = nil)
  if valid_402658559 != nil:
    section.add "MultiAZ", valid_402658559
  var valid_402658560 = query.getOrDefault("Version")
  valid_402658560 = validateParameter(valid_402658560, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658560 != nil:
    section.add "Version", valid_402658560
  var valid_402658561 = query.getOrDefault("Tags")
  valid_402658561 = validateParameter(valid_402658561, JArray, required = false,
                                      default = nil)
  if valid_402658561 != nil:
    section.add "Tags", valid_402658561
  var valid_402658562 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658562 = validateParameter(valid_402658562, JBool, required = false,
                                      default = nil)
  if valid_402658562 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658562
  var valid_402658563 = query.getOrDefault("DBSnapshotIdentifier")
  valid_402658563 = validateParameter(valid_402658563, JString, required = true,
                                      default = nil)
  if valid_402658563 != nil:
    section.add "DBSnapshotIdentifier", valid_402658563
  var valid_402658564 = query.getOrDefault("DBName")
  valid_402658564 = validateParameter(valid_402658564, JString,
                                      required = false, default = nil)
  if valid_402658564 != nil:
    section.add "DBName", valid_402658564
  var valid_402658565 = query.getOrDefault("DBInstanceClass")
  valid_402658565 = validateParameter(valid_402658565, JString,
                                      required = false, default = nil)
  if valid_402658565 != nil:
    section.add "DBInstanceClass", valid_402658565
  var valid_402658566 = query.getOrDefault("Engine")
  valid_402658566 = validateParameter(valid_402658566, JString,
                                      required = false, default = nil)
  if valid_402658566 != nil:
    section.add "Engine", valid_402658566
  var valid_402658567 = query.getOrDefault("Port")
  valid_402658567 = validateParameter(valid_402658567, JInt, required = false,
                                      default = nil)
  if valid_402658567 != nil:
    section.add "Port", valid_402658567
  var valid_402658568 = query.getOrDefault("TdeCredentialArn")
  valid_402658568 = validateParameter(valid_402658568, JString,
                                      required = false, default = nil)
  if valid_402658568 != nil:
    section.add "TdeCredentialArn", valid_402658568
  var valid_402658569 = query.getOrDefault("Action")
  valid_402658569 = validateParameter(valid_402658569, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_402658569 != nil:
    section.add "Action", valid_402658569
  var valid_402658570 = query.getOrDefault("LicenseModel")
  valid_402658570 = validateParameter(valid_402658570, JString,
                                      required = false, default = nil)
  if valid_402658570 != nil:
    section.add "LicenseModel", valid_402658570
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
  var valid_402658571 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658571 = validateParameter(valid_402658571, JString,
                                      required = false, default = nil)
  if valid_402658571 != nil:
    section.add "X-Amz-Security-Token", valid_402658571
  var valid_402658572 = header.getOrDefault("X-Amz-Signature")
  valid_402658572 = validateParameter(valid_402658572, JString,
                                      required = false, default = nil)
  if valid_402658572 != nil:
    section.add "X-Amz-Signature", valid_402658572
  var valid_402658573 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658573 = validateParameter(valid_402658573, JString,
                                      required = false, default = nil)
  if valid_402658573 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658573
  var valid_402658574 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658574 = validateParameter(valid_402658574, JString,
                                      required = false, default = nil)
  if valid_402658574 != nil:
    section.add "X-Amz-Algorithm", valid_402658574
  var valid_402658575 = header.getOrDefault("X-Amz-Date")
  valid_402658575 = validateParameter(valid_402658575, JString,
                                      required = false, default = nil)
  if valid_402658575 != nil:
    section.add "X-Amz-Date", valid_402658575
  var valid_402658576 = header.getOrDefault("X-Amz-Credential")
  valid_402658576 = validateParameter(valid_402658576, JString,
                                      required = false, default = nil)
  if valid_402658576 != nil:
    section.add "X-Amz-Credential", valid_402658576
  var valid_402658577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658577 = validateParameter(valid_402658577, JString,
                                      required = false, default = nil)
  if valid_402658577 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658578: Call_GetRestoreDBInstanceFromDBSnapshot_402658548;
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

proc call*(call_402658579: Call_GetRestoreDBInstanceFromDBSnapshot_402658548;
           DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
           PubliclyAccessible: bool = false; OptionGroupName: string = "";
           DBSubnetGroupName: string = ""; TdeCredentialPassword: string = "";
           Iops: int = 0; AvailabilityZone: string = "";
           StorageType: string = ""; MultiAZ: bool = false;
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           AutoMinorVersionUpgrade: bool = false; DBName: string = "";
           DBInstanceClass: string = ""; Engine: string = ""; Port: int = 0;
           TdeCredentialArn: string = "";
           Action: string = "RestoreDBInstanceFromDBSnapshot";
           LicenseModel: string = ""): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   DBInstanceIdentifier: string (required)
  ##   DBSubnetGroupName: string
  ##   TdeCredentialPassword: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   StorageType: string
  ##   MultiAZ: bool
  ##   Version: string (required)
  ##   Tags: JArray
  ##   AutoMinorVersionUpgrade: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Engine: string
  ##   Port: int
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402658580 = newJObject()
  add(query_402658580, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658580, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658580, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_402658580, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658580, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(query_402658580, "Iops", newJInt(Iops))
  add(query_402658580, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658580, "StorageType", newJString(StorageType))
  add(query_402658580, "MultiAZ", newJBool(MultiAZ))
  add(query_402658580, "Version", newJString(Version))
  if Tags != nil:
    query_402658580.add "Tags", Tags
  add(query_402658580, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658580, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_402658580, "DBName", newJString(DBName))
  add(query_402658580, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658580, "Engine", newJString(Engine))
  add(query_402658580, "Port", newJInt(Port))
  add(query_402658580, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_402658580, "Action", newJString(Action))
  add(query_402658580, "LicenseModel", newJString(LicenseModel))
  result = call_402658579.call(nil, query_402658580, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_402658548(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_402658549, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_402658550,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_402658650 = ref object of OpenApiRestCall_402656035
proc url_PostRestoreDBInstanceToPointInTime_402658652(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_402658651(path: JsonNode;
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
  var valid_402658653 = query.getOrDefault("Version")
  valid_402658653 = validateParameter(valid_402658653, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658653 != nil:
    section.add "Version", valid_402658653
  var valid_402658654 = query.getOrDefault("Action")
  valid_402658654 = validateParameter(valid_402658654, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658654 != nil:
    section.add "Action", valid_402658654
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
  var valid_402658655 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658655 = validateParameter(valid_402658655, JString,
                                      required = false, default = nil)
  if valid_402658655 != nil:
    section.add "X-Amz-Security-Token", valid_402658655
  var valid_402658656 = header.getOrDefault("X-Amz-Signature")
  valid_402658656 = validateParameter(valid_402658656, JString,
                                      required = false, default = nil)
  if valid_402658656 != nil:
    section.add "X-Amz-Signature", valid_402658656
  var valid_402658657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658657 = validateParameter(valid_402658657, JString,
                                      required = false, default = nil)
  if valid_402658657 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658657
  var valid_402658658 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658658 = validateParameter(valid_402658658, JString,
                                      required = false, default = nil)
  if valid_402658658 != nil:
    section.add "X-Amz-Algorithm", valid_402658658
  var valid_402658659 = header.getOrDefault("X-Amz-Date")
  valid_402658659 = validateParameter(valid_402658659, JString,
                                      required = false, default = nil)
  if valid_402658659 != nil:
    section.add "X-Amz-Date", valid_402658659
  var valid_402658660 = header.getOrDefault("X-Amz-Credential")
  valid_402658660 = validateParameter(valid_402658660, JString,
                                      required = false, default = nil)
  if valid_402658660 != nil:
    section.add "X-Amz-Credential", valid_402658660
  var valid_402658661 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658661 = validateParameter(valid_402658661, JString,
                                      required = false, default = nil)
  if valid_402658661 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658661
  result.add "header", section
  ## parameters in `formData` object:
  ##   AutoMinorVersionUpgrade: JBool
  ##   TdeCredentialArn: JString
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
  ##   TdeCredentialPassword: JString
  ##   MultiAZ: JBool
  ##   OptionGroupName: JString
  ##   StorageType: JString
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   RestoreTime: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_402658662 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658662 = validateParameter(valid_402658662, JBool, required = false,
                                      default = nil)
  if valid_402658662 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658662
  var valid_402658663 = formData.getOrDefault("TdeCredentialArn")
  valid_402658663 = validateParameter(valid_402658663, JString,
                                      required = false, default = nil)
  if valid_402658663 != nil:
    section.add "TdeCredentialArn", valid_402658663
  var valid_402658664 = formData.getOrDefault("Port")
  valid_402658664 = validateParameter(valid_402658664, JInt, required = false,
                                      default = nil)
  if valid_402658664 != nil:
    section.add "Port", valid_402658664
  var valid_402658665 = formData.getOrDefault("UseLatestRestorableTime")
  valid_402658665 = validateParameter(valid_402658665, JBool, required = false,
                                      default = nil)
  if valid_402658665 != nil:
    section.add "UseLatestRestorableTime", valid_402658665
  var valid_402658666 = formData.getOrDefault("Engine")
  valid_402658666 = validateParameter(valid_402658666, JString,
                                      required = false, default = nil)
  if valid_402658666 != nil:
    section.add "Engine", valid_402658666
  var valid_402658667 = formData.getOrDefault("DBSubnetGroupName")
  valid_402658667 = validateParameter(valid_402658667, JString,
                                      required = false, default = nil)
  if valid_402658667 != nil:
    section.add "DBSubnetGroupName", valid_402658667
  var valid_402658668 = formData.getOrDefault("PubliclyAccessible")
  valid_402658668 = validateParameter(valid_402658668, JBool, required = false,
                                      default = nil)
  if valid_402658668 != nil:
    section.add "PubliclyAccessible", valid_402658668
  var valid_402658669 = formData.getOrDefault("AvailabilityZone")
  valid_402658669 = validateParameter(valid_402658669, JString,
                                      required = false, default = nil)
  if valid_402658669 != nil:
    section.add "AvailabilityZone", valid_402658669
  var valid_402658670 = formData.getOrDefault("DBName")
  valid_402658670 = validateParameter(valid_402658670, JString,
                                      required = false, default = nil)
  if valid_402658670 != nil:
    section.add "DBName", valid_402658670
  var valid_402658671 = formData.getOrDefault("Tags")
  valid_402658671 = validateParameter(valid_402658671, JArray, required = false,
                                      default = nil)
  if valid_402658671 != nil:
    section.add "Tags", valid_402658671
  var valid_402658672 = formData.getOrDefault("Iops")
  valid_402658672 = validateParameter(valid_402658672, JInt, required = false,
                                      default = nil)
  if valid_402658672 != nil:
    section.add "Iops", valid_402658672
  var valid_402658673 = formData.getOrDefault("DBInstanceClass")
  valid_402658673 = validateParameter(valid_402658673, JString,
                                      required = false, default = nil)
  if valid_402658673 != nil:
    section.add "DBInstanceClass", valid_402658673
  var valid_402658674 = formData.getOrDefault("LicenseModel")
  valid_402658674 = validateParameter(valid_402658674, JString,
                                      required = false, default = nil)
  if valid_402658674 != nil:
    section.add "LicenseModel", valid_402658674
  var valid_402658675 = formData.getOrDefault("TdeCredentialPassword")
  valid_402658675 = validateParameter(valid_402658675, JString,
                                      required = false, default = nil)
  if valid_402658675 != nil:
    section.add "TdeCredentialPassword", valid_402658675
  var valid_402658676 = formData.getOrDefault("MultiAZ")
  valid_402658676 = validateParameter(valid_402658676, JBool, required = false,
                                      default = nil)
  if valid_402658676 != nil:
    section.add "MultiAZ", valid_402658676
  var valid_402658677 = formData.getOrDefault("OptionGroupName")
  valid_402658677 = validateParameter(valid_402658677, JString,
                                      required = false, default = nil)
  if valid_402658677 != nil:
    section.add "OptionGroupName", valid_402658677
  var valid_402658678 = formData.getOrDefault("StorageType")
  valid_402658678 = validateParameter(valid_402658678, JString,
                                      required = false, default = nil)
  if valid_402658678 != nil:
    section.add "StorageType", valid_402658678
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_402658679 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658679 = validateParameter(valid_402658679, JString, required = true,
                                      default = nil)
  if valid_402658679 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658679
  var valid_402658680 = formData.getOrDefault("RestoreTime")
  valid_402658680 = validateParameter(valid_402658680, JString,
                                      required = false, default = nil)
  if valid_402658680 != nil:
    section.add "RestoreTime", valid_402658680
  var valid_402658681 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658681 = validateParameter(valid_402658681, JString, required = true,
                                      default = nil)
  if valid_402658681 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658681
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658682: Call_PostRestoreDBInstanceToPointInTime_402658650;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658682.validator(path, query, header, formData, body, _)
  let scheme = call_402658682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658682.makeUrl(scheme.get, call_402658682.host, call_402658682.base,
                                   call_402658682.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658682, uri, valid, _)

proc call*(call_402658683: Call_PostRestoreDBInstanceToPointInTime_402658650;
           TargetDBInstanceIdentifier: string;
           SourceDBInstanceIdentifier: string;
           AutoMinorVersionUpgrade: bool = false; TdeCredentialArn: string = "";
           Port: int = 0; UseLatestRestorableTime: bool = false;
           Engine: string = ""; DBSubnetGroupName: string = "";
           PubliclyAccessible: bool = false; AvailabilityZone: string = "";
           DBName: string = ""; Tags: JsonNode = nil;
           Version: string = "2014-09-01"; Iops: int = 0;
           DBInstanceClass: string = ""; LicenseModel: string = "";
           TdeCredentialPassword: string = ""; MultiAZ: bool = false;
           OptionGroupName: string = "";
           Action: string = "RestoreDBInstanceToPointInTime";
           StorageType: string = ""; RestoreTime: string = ""): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   AutoMinorVersionUpgrade: bool
  ##   TdeCredentialArn: string
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
  ##   TdeCredentialPassword: string
  ##   MultiAZ: bool
  ##   OptionGroupName: string
  ##   Action: string (required)
  ##   StorageType: string
  ##   TargetDBInstanceIdentifier: string (required)
  ##   RestoreTime: string
  ##   SourceDBInstanceIdentifier: string (required)
  var query_402658684 = newJObject()
  var formData_402658685 = newJObject()
  add(formData_402658685, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_402658685, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(formData_402658685, "Port", newJInt(Port))
  add(formData_402658685, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_402658685, "Engine", newJString(Engine))
  add(formData_402658685, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_402658685, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_402658685, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_402658685, "DBName", newJString(DBName))
  if Tags != nil:
    formData_402658685.add "Tags", Tags
  add(query_402658684, "Version", newJString(Version))
  add(formData_402658685, "Iops", newJInt(Iops))
  add(formData_402658685, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_402658685, "LicenseModel", newJString(LicenseModel))
  add(formData_402658685, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(formData_402658685, "MultiAZ", newJBool(MultiAZ))
  add(formData_402658685, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658684, "Action", newJString(Action))
  add(formData_402658685, "StorageType", newJString(StorageType))
  add(formData_402658685, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_402658685, "RestoreTime", newJString(RestoreTime))
  add(formData_402658685, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  result = call_402658683.call(nil, query_402658684, nil, formData_402658685,
                               nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_402658650(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_402658651, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_402658652,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_402658615 = ref object of OpenApiRestCall_402656035
proc url_GetRestoreDBInstanceToPointInTime_402658617(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_402658616(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PubliclyAccessible: JBool
  ##   OptionGroupName: JString
  ##   TdeCredentialPassword: JString
  ##   DBSubnetGroupName: JString
  ##   Iops: JInt
  ##   AvailabilityZone: JString
  ##   StorageType: JString
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
  ##   TdeCredentialArn: JString
  ##   Action: JString (required)
  ##   LicenseModel: JString
  section = newJObject()
  var valid_402658618 = query.getOrDefault("PubliclyAccessible")
  valid_402658618 = validateParameter(valid_402658618, JBool, required = false,
                                      default = nil)
  if valid_402658618 != nil:
    section.add "PubliclyAccessible", valid_402658618
  var valid_402658619 = query.getOrDefault("OptionGroupName")
  valid_402658619 = validateParameter(valid_402658619, JString,
                                      required = false, default = nil)
  if valid_402658619 != nil:
    section.add "OptionGroupName", valid_402658619
  var valid_402658620 = query.getOrDefault("TdeCredentialPassword")
  valid_402658620 = validateParameter(valid_402658620, JString,
                                      required = false, default = nil)
  if valid_402658620 != nil:
    section.add "TdeCredentialPassword", valid_402658620
  var valid_402658621 = query.getOrDefault("DBSubnetGroupName")
  valid_402658621 = validateParameter(valid_402658621, JString,
                                      required = false, default = nil)
  if valid_402658621 != nil:
    section.add "DBSubnetGroupName", valid_402658621
  var valid_402658622 = query.getOrDefault("Iops")
  valid_402658622 = validateParameter(valid_402658622, JInt, required = false,
                                      default = nil)
  if valid_402658622 != nil:
    section.add "Iops", valid_402658622
  var valid_402658623 = query.getOrDefault("AvailabilityZone")
  valid_402658623 = validateParameter(valid_402658623, JString,
                                      required = false, default = nil)
  if valid_402658623 != nil:
    section.add "AvailabilityZone", valid_402658623
  var valid_402658624 = query.getOrDefault("StorageType")
  valid_402658624 = validateParameter(valid_402658624, JString,
                                      required = false, default = nil)
  if valid_402658624 != nil:
    section.add "StorageType", valid_402658624
  var valid_402658625 = query.getOrDefault("MultiAZ")
  valid_402658625 = validateParameter(valid_402658625, JBool, required = false,
                                      default = nil)
  if valid_402658625 != nil:
    section.add "MultiAZ", valid_402658625
  var valid_402658626 = query.getOrDefault("RestoreTime")
  valid_402658626 = validateParameter(valid_402658626, JString,
                                      required = false, default = nil)
  if valid_402658626 != nil:
    section.add "RestoreTime", valid_402658626
  var valid_402658627 = query.getOrDefault("Version")
  valid_402658627 = validateParameter(valid_402658627, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658627 != nil:
    section.add "Version", valid_402658627
  var valid_402658628 = query.getOrDefault("Tags")
  valid_402658628 = validateParameter(valid_402658628, JArray, required = false,
                                      default = nil)
  if valid_402658628 != nil:
    section.add "Tags", valid_402658628
  var valid_402658629 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_402658629 = validateParameter(valid_402658629, JBool, required = false,
                                      default = nil)
  if valid_402658629 != nil:
    section.add "AutoMinorVersionUpgrade", valid_402658629
  var valid_402658630 = query.getOrDefault("UseLatestRestorableTime")
  valid_402658630 = validateParameter(valid_402658630, JBool, required = false,
                                      default = nil)
  if valid_402658630 != nil:
    section.add "UseLatestRestorableTime", valid_402658630
  var valid_402658631 = query.getOrDefault("DBName")
  valid_402658631 = validateParameter(valid_402658631, JString,
                                      required = false, default = nil)
  if valid_402658631 != nil:
    section.add "DBName", valid_402658631
  var valid_402658632 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_402658632 = validateParameter(valid_402658632, JString, required = true,
                                      default = nil)
  if valid_402658632 != nil:
    section.add "SourceDBInstanceIdentifier", valid_402658632
  var valid_402658633 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_402658633 = validateParameter(valid_402658633, JString, required = true,
                                      default = nil)
  if valid_402658633 != nil:
    section.add "TargetDBInstanceIdentifier", valid_402658633
  var valid_402658634 = query.getOrDefault("DBInstanceClass")
  valid_402658634 = validateParameter(valid_402658634, JString,
                                      required = false, default = nil)
  if valid_402658634 != nil:
    section.add "DBInstanceClass", valid_402658634
  var valid_402658635 = query.getOrDefault("Engine")
  valid_402658635 = validateParameter(valid_402658635, JString,
                                      required = false, default = nil)
  if valid_402658635 != nil:
    section.add "Engine", valid_402658635
  var valid_402658636 = query.getOrDefault("Port")
  valid_402658636 = validateParameter(valid_402658636, JInt, required = false,
                                      default = nil)
  if valid_402658636 != nil:
    section.add "Port", valid_402658636
  var valid_402658637 = query.getOrDefault("TdeCredentialArn")
  valid_402658637 = validateParameter(valid_402658637, JString,
                                      required = false, default = nil)
  if valid_402658637 != nil:
    section.add "TdeCredentialArn", valid_402658637
  var valid_402658638 = query.getOrDefault("Action")
  valid_402658638 = validateParameter(valid_402658638, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_402658638 != nil:
    section.add "Action", valid_402658638
  var valid_402658639 = query.getOrDefault("LicenseModel")
  valid_402658639 = validateParameter(valid_402658639, JString,
                                      required = false, default = nil)
  if valid_402658639 != nil:
    section.add "LicenseModel", valid_402658639
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
  var valid_402658640 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658640 = validateParameter(valid_402658640, JString,
                                      required = false, default = nil)
  if valid_402658640 != nil:
    section.add "X-Amz-Security-Token", valid_402658640
  var valid_402658641 = header.getOrDefault("X-Amz-Signature")
  valid_402658641 = validateParameter(valid_402658641, JString,
                                      required = false, default = nil)
  if valid_402658641 != nil:
    section.add "X-Amz-Signature", valid_402658641
  var valid_402658642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658642 = validateParameter(valid_402658642, JString,
                                      required = false, default = nil)
  if valid_402658642 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658642
  var valid_402658643 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658643 = validateParameter(valid_402658643, JString,
                                      required = false, default = nil)
  if valid_402658643 != nil:
    section.add "X-Amz-Algorithm", valid_402658643
  var valid_402658644 = header.getOrDefault("X-Amz-Date")
  valid_402658644 = validateParameter(valid_402658644, JString,
                                      required = false, default = nil)
  if valid_402658644 != nil:
    section.add "X-Amz-Date", valid_402658644
  var valid_402658645 = header.getOrDefault("X-Amz-Credential")
  valid_402658645 = validateParameter(valid_402658645, JString,
                                      required = false, default = nil)
  if valid_402658645 != nil:
    section.add "X-Amz-Credential", valid_402658645
  var valid_402658646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658646 = validateParameter(valid_402658646, JString,
                                      required = false, default = nil)
  if valid_402658646 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658647: Call_GetRestoreDBInstanceToPointInTime_402658615;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658647.validator(path, query, header, formData, body, _)
  let scheme = call_402658647.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658647.makeUrl(scheme.get, call_402658647.host, call_402658647.base,
                                   call_402658647.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658647, uri, valid, _)

proc call*(call_402658648: Call_GetRestoreDBInstanceToPointInTime_402658615;
           SourceDBInstanceIdentifier: string;
           TargetDBInstanceIdentifier: string; PubliclyAccessible: bool = false;
           OptionGroupName: string = ""; TdeCredentialPassword: string = "";
           DBSubnetGroupName: string = ""; Iops: int = 0;
           AvailabilityZone: string = ""; StorageType: string = "";
           MultiAZ: bool = false; RestoreTime: string = "";
           Version: string = "2014-09-01"; Tags: JsonNode = nil;
           AutoMinorVersionUpgrade: bool = false;
           UseLatestRestorableTime: bool = false; DBName: string = "";
           DBInstanceClass: string = ""; Engine: string = ""; Port: int = 0;
           TdeCredentialArn: string = "";
           Action: string = "RestoreDBInstanceToPointInTime";
           LicenseModel: string = ""): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   PubliclyAccessible: bool
  ##   OptionGroupName: string
  ##   TdeCredentialPassword: string
  ##   DBSubnetGroupName: string
  ##   Iops: int
  ##   AvailabilityZone: string
  ##   StorageType: string
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
  ##   TdeCredentialArn: string
  ##   Action: string (required)
  ##   LicenseModel: string
  var query_402658649 = newJObject()
  add(query_402658649, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_402658649, "OptionGroupName", newJString(OptionGroupName))
  add(query_402658649, "TdeCredentialPassword",
      newJString(TdeCredentialPassword))
  add(query_402658649, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_402658649, "Iops", newJInt(Iops))
  add(query_402658649, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_402658649, "StorageType", newJString(StorageType))
  add(query_402658649, "MultiAZ", newJBool(MultiAZ))
  add(query_402658649, "RestoreTime", newJString(RestoreTime))
  add(query_402658649, "Version", newJString(Version))
  if Tags != nil:
    query_402658649.add "Tags", Tags
  add(query_402658649, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_402658649, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(query_402658649, "DBName", newJString(DBName))
  add(query_402658649, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_402658649, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_402658649, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_402658649, "Engine", newJString(Engine))
  add(query_402658649, "Port", newJInt(Port))
  add(query_402658649, "TdeCredentialArn", newJString(TdeCredentialArn))
  add(query_402658649, "Action", newJString(Action))
  add(query_402658649, "LicenseModel", newJString(LicenseModel))
  result = call_402658648.call(nil, query_402658649, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_402658615(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_402658616, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_402658617,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_402658706 = ref object of OpenApiRestCall_402656035
proc url_PostRevokeDBSecurityGroupIngress_402658708(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_402658707(path: JsonNode;
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
  var valid_402658709 = query.getOrDefault("Version")
  valid_402658709 = validateParameter(valid_402658709, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658709 != nil:
    section.add "Version", valid_402658709
  var valid_402658710 = query.getOrDefault("Action")
  valid_402658710 = validateParameter(valid_402658710, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658710 != nil:
    section.add "Action", valid_402658710
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
  var valid_402658711 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658711 = validateParameter(valid_402658711, JString,
                                      required = false, default = nil)
  if valid_402658711 != nil:
    section.add "X-Amz-Security-Token", valid_402658711
  var valid_402658712 = header.getOrDefault("X-Amz-Signature")
  valid_402658712 = validateParameter(valid_402658712, JString,
                                      required = false, default = nil)
  if valid_402658712 != nil:
    section.add "X-Amz-Signature", valid_402658712
  var valid_402658713 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658713 = validateParameter(valid_402658713, JString,
                                      required = false, default = nil)
  if valid_402658713 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658713
  var valid_402658714 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658714 = validateParameter(valid_402658714, JString,
                                      required = false, default = nil)
  if valid_402658714 != nil:
    section.add "X-Amz-Algorithm", valid_402658714
  var valid_402658715 = header.getOrDefault("X-Amz-Date")
  valid_402658715 = validateParameter(valid_402658715, JString,
                                      required = false, default = nil)
  if valid_402658715 != nil:
    section.add "X-Amz-Date", valid_402658715
  var valid_402658716 = header.getOrDefault("X-Amz-Credential")
  valid_402658716 = validateParameter(valid_402658716, JString,
                                      required = false, default = nil)
  if valid_402658716 != nil:
    section.add "X-Amz-Credential", valid_402658716
  var valid_402658717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658717 = validateParameter(valid_402658717, JString,
                                      required = false, default = nil)
  if valid_402658717 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658717
  result.add "header", section
  ## parameters in `formData` object:
  ##   EC2SecurityGroupName: JString
  ##   CIDRIP: JString
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupOwnerId: JString
  ##   EC2SecurityGroupId: JString
  section = newJObject()
  var valid_402658718 = formData.getOrDefault("EC2SecurityGroupName")
  valid_402658718 = validateParameter(valid_402658718, JString,
                                      required = false, default = nil)
  if valid_402658718 != nil:
    section.add "EC2SecurityGroupName", valid_402658718
  var valid_402658719 = formData.getOrDefault("CIDRIP")
  valid_402658719 = validateParameter(valid_402658719, JString,
                                      required = false, default = nil)
  if valid_402658719 != nil:
    section.add "CIDRIP", valid_402658719
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_402658720 = formData.getOrDefault("DBSecurityGroupName")
  valid_402658720 = validateParameter(valid_402658720, JString, required = true,
                                      default = nil)
  if valid_402658720 != nil:
    section.add "DBSecurityGroupName", valid_402658720
  var valid_402658721 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658721 = validateParameter(valid_402658721, JString,
                                      required = false, default = nil)
  if valid_402658721 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658721
  var valid_402658722 = formData.getOrDefault("EC2SecurityGroupId")
  valid_402658722 = validateParameter(valid_402658722, JString,
                                      required = false, default = nil)
  if valid_402658722 != nil:
    section.add "EC2SecurityGroupId", valid_402658722
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658723: Call_PostRevokeDBSecurityGroupIngress_402658706;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658723.validator(path, query, header, formData, body, _)
  let scheme = call_402658723.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658723.makeUrl(scheme.get, call_402658723.host, call_402658723.base,
                                   call_402658723.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658723, uri, valid, _)

proc call*(call_402658724: Call_PostRevokeDBSecurityGroupIngress_402658706;
           DBSecurityGroupName: string; EC2SecurityGroupName: string = "";
           CIDRIP: string = ""; Version: string = "2014-09-01";
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
  var query_402658725 = newJObject()
  var formData_402658726 = newJObject()
  add(formData_402658726, "EC2SecurityGroupName",
      newJString(EC2SecurityGroupName))
  add(formData_402658726, "CIDRIP", newJString(CIDRIP))
  add(query_402658725, "Version", newJString(Version))
  add(formData_402658726, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_402658726, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658725, "Action", newJString(Action))
  add(formData_402658726, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  result = call_402658724.call(nil, query_402658725, nil, formData_402658726,
                               nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_402658706(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_402658707, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_402658708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_402658686 = ref object of OpenApiRestCall_402656035
proc url_GetRevokeDBSecurityGroupIngress_402658688(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_402658687(path: JsonNode;
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
  var valid_402658689 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_402658689 = validateParameter(valid_402658689, JString,
                                      required = false, default = nil)
  if valid_402658689 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_402658689
  var valid_402658690 = query.getOrDefault("EC2SecurityGroupId")
  valid_402658690 = validateParameter(valid_402658690, JString,
                                      required = false, default = nil)
  if valid_402658690 != nil:
    section.add "EC2SecurityGroupId", valid_402658690
  var valid_402658691 = query.getOrDefault("Version")
  valid_402658691 = validateParameter(valid_402658691, JString, required = true,
                                      default = newJString("2014-09-01"))
  if valid_402658691 != nil:
    section.add "Version", valid_402658691
  var valid_402658692 = query.getOrDefault("EC2SecurityGroupName")
  valid_402658692 = validateParameter(valid_402658692, JString,
                                      required = false, default = nil)
  if valid_402658692 != nil:
    section.add "EC2SecurityGroupName", valid_402658692
  var valid_402658693 = query.getOrDefault("Action")
  valid_402658693 = validateParameter(valid_402658693, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_402658693 != nil:
    section.add "Action", valid_402658693
  var valid_402658694 = query.getOrDefault("DBSecurityGroupName")
  valid_402658694 = validateParameter(valid_402658694, JString, required = true,
                                      default = nil)
  if valid_402658694 != nil:
    section.add "DBSecurityGroupName", valid_402658694
  var valid_402658695 = query.getOrDefault("CIDRIP")
  valid_402658695 = validateParameter(valid_402658695, JString,
                                      required = false, default = nil)
  if valid_402658695 != nil:
    section.add "CIDRIP", valid_402658695
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
  var valid_402658696 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658696 = validateParameter(valid_402658696, JString,
                                      required = false, default = nil)
  if valid_402658696 != nil:
    section.add "X-Amz-Security-Token", valid_402658696
  var valid_402658697 = header.getOrDefault("X-Amz-Signature")
  valid_402658697 = validateParameter(valid_402658697, JString,
                                      required = false, default = nil)
  if valid_402658697 != nil:
    section.add "X-Amz-Signature", valid_402658697
  var valid_402658698 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658698 = validateParameter(valid_402658698, JString,
                                      required = false, default = nil)
  if valid_402658698 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658698
  var valid_402658699 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658699 = validateParameter(valid_402658699, JString,
                                      required = false, default = nil)
  if valid_402658699 != nil:
    section.add "X-Amz-Algorithm", valid_402658699
  var valid_402658700 = header.getOrDefault("X-Amz-Date")
  valid_402658700 = validateParameter(valid_402658700, JString,
                                      required = false, default = nil)
  if valid_402658700 != nil:
    section.add "X-Amz-Date", valid_402658700
  var valid_402658701 = header.getOrDefault("X-Amz-Credential")
  valid_402658701 = validateParameter(valid_402658701, JString,
                                      required = false, default = nil)
  if valid_402658701 != nil:
    section.add "X-Amz-Credential", valid_402658701
  var valid_402658702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658702 = validateParameter(valid_402658702, JString,
                                      required = false, default = nil)
  if valid_402658702 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658702
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402658703: Call_GetRevokeDBSecurityGroupIngress_402658686;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_402658703.validator(path, query, header, formData, body, _)
  let scheme = call_402658703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658703.makeUrl(scheme.get, call_402658703.host, call_402658703.base,
                                   call_402658703.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658703, uri, valid, _)

proc call*(call_402658704: Call_GetRevokeDBSecurityGroupIngress_402658686;
           DBSecurityGroupName: string; EC2SecurityGroupOwnerId: string = "";
           EC2SecurityGroupId: string = ""; Version: string = "2014-09-01";
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
  var query_402658705 = newJObject()
  add(query_402658705, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_402658705, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_402658705, "Version", newJString(Version))
  add(query_402658705, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_402658705, "Action", newJString(Action))
  add(query_402658705, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_402658705, "CIDRIP", newJString(CIDRIP))
  result = call_402658704.call(nil, query_402658705, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_402658686(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_402658687, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_402658688,
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
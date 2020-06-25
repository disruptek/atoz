
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  Scheme {.pure.} = enum
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

  OpenApiRestCall_21625418 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625418](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625418): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "rds.ap-northeast-1.amazonaws.com", "ap-southeast-1": "rds.ap-southeast-1.amazonaws.com",
                           "us-west-2": "rds.us-west-2.amazonaws.com",
                           "eu-west-2": "rds.eu-west-2.amazonaws.com", "ap-northeast-3": "rds.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "rds.eu-central-1.amazonaws.com",
                           "us-east-2": "rds.us-east-2.amazonaws.com",
                           "us-east-1": "rds.us-east-1.amazonaws.com", "cn-northwest-1": "rds.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "rds.ap-south-1.amazonaws.com",
                           "eu-north-1": "rds.eu-north-1.amazonaws.com", "ap-northeast-2": "rds.ap-northeast-2.amazonaws.com",
                           "us-west-1": "rds.us-west-1.amazonaws.com",
                           "us-gov-east-1": "rds.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "rds.eu-west-3.amazonaws.com",
                           "cn-north-1": "rds.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "rds.sa-east-1.amazonaws.com",
                           "eu-west-1": "rds.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "rds.us-gov-west-1.amazonaws.com", "ap-southeast-2": "rds.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "rds.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostAddSourceIdentifierToSubscription_21626018 = ref object of OpenApiRestCall_21625418
proc url_PostAddSourceIdentifierToSubscription_21626020(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddSourceIdentifierToSubscription_21626019(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626021 = query.getOrDefault("Action")
  valid_21626021 = validateParameter(valid_21626021, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_21626021 != nil:
    section.add "Action", valid_21626021
  var valid_21626022 = query.getOrDefault("Version")
  valid_21626022 = validateParameter(valid_21626022, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626022 != nil:
    section.add "Version", valid_21626022
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
  var valid_21626023 = header.getOrDefault("X-Amz-Date")
  valid_21626023 = validateParameter(valid_21626023, JString, required = false,
                                   default = nil)
  if valid_21626023 != nil:
    section.add "X-Amz-Date", valid_21626023
  var valid_21626024 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Security-Token", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Algorithm", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Signature")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Signature", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-Credential")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-Credential", valid_21626029
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_21626030 = formData.getOrDefault("SourceIdentifier")
  valid_21626030 = validateParameter(valid_21626030, JString, required = true,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "SourceIdentifier", valid_21626030
  var valid_21626031 = formData.getOrDefault("SubscriptionName")
  valid_21626031 = validateParameter(valid_21626031, JString, required = true,
                                   default = nil)
  if valid_21626031 != nil:
    section.add "SubscriptionName", valid_21626031
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626032: Call_PostAddSourceIdentifierToSubscription_21626018;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_PostAddSourceIdentifierToSubscription_21626018;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postAddSourceIdentifierToSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626034 = newJObject()
  var formData_21626035 = newJObject()
  add(formData_21626035, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_21626035, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626034, "Action", newJString(Action))
  add(query_21626034, "Version", newJString(Version))
  result = call_21626033.call(nil, query_21626034, nil, formData_21626035, nil)

var postAddSourceIdentifierToSubscription* = Call_PostAddSourceIdentifierToSubscription_21626018(
    name: "postAddSourceIdentifierToSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_PostAddSourceIdentifierToSubscription_21626019, base: "/",
    makeUrl: url_PostAddSourceIdentifierToSubscription_21626020,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddSourceIdentifierToSubscription_21625762 = ref object of OpenApiRestCall_21625418
proc url_GetAddSourceIdentifierToSubscription_21625764(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddSourceIdentifierToSubscription_21625763(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21625879 = query.getOrDefault("Action")
  valid_21625879 = validateParameter(valid_21625879, JString, required = true, default = newJString(
      "AddSourceIdentifierToSubscription"))
  if valid_21625879 != nil:
    section.add "Action", valid_21625879
  var valid_21625880 = query.getOrDefault("SourceIdentifier")
  valid_21625880 = validateParameter(valid_21625880, JString, required = true,
                                   default = nil)
  if valid_21625880 != nil:
    section.add "SourceIdentifier", valid_21625880
  var valid_21625881 = query.getOrDefault("SubscriptionName")
  valid_21625881 = validateParameter(valid_21625881, JString, required = true,
                                   default = nil)
  if valid_21625881 != nil:
    section.add "SubscriptionName", valid_21625881
  var valid_21625882 = query.getOrDefault("Version")
  valid_21625882 = validateParameter(valid_21625882, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21625882 != nil:
    section.add "Version", valid_21625882
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
  var valid_21625883 = header.getOrDefault("X-Amz-Date")
  valid_21625883 = validateParameter(valid_21625883, JString, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "X-Amz-Date", valid_21625883
  var valid_21625884 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "X-Amz-Security-Token", valid_21625884
  var valid_21625885 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625885
  var valid_21625886 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Algorithm", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Signature")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Signature", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Credential")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Credential", valid_21625889
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625914: Call_GetAddSourceIdentifierToSubscription_21625762;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21625914.validator(path, query, header, formData, body, _)
  let scheme = call_21625914.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625914.makeUrl(scheme.get, call_21625914.host, call_21625914.base,
                               call_21625914.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625914, uri, valid, _)

proc call*(call_21625977: Call_GetAddSourceIdentifierToSubscription_21625762;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "AddSourceIdentifierToSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getAddSourceIdentifierToSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21625979 = newJObject()
  add(query_21625979, "Action", newJString(Action))
  add(query_21625979, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21625979, "SubscriptionName", newJString(SubscriptionName))
  add(query_21625979, "Version", newJString(Version))
  result = call_21625977.call(nil, query_21625979, nil, nil, nil)

var getAddSourceIdentifierToSubscription* = Call_GetAddSourceIdentifierToSubscription_21625762(
    name: "getAddSourceIdentifierToSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=AddSourceIdentifierToSubscription",
    validator: validate_GetAddSourceIdentifierToSubscription_21625763, base: "/",
    makeUrl: url_GetAddSourceIdentifierToSubscription_21625764,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAddTagsToResource_21626053 = ref object of OpenApiRestCall_21625418
proc url_PostAddTagsToResource_21626055(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAddTagsToResource_21626054(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626056 = query.getOrDefault("Action")
  valid_21626056 = validateParameter(valid_21626056, JString, required = true,
                                   default = newJString("AddTagsToResource"))
  if valid_21626056 != nil:
    section.add "Action", valid_21626056
  var valid_21626057 = query.getOrDefault("Version")
  valid_21626057 = validateParameter(valid_21626057, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626057 != nil:
    section.add "Version", valid_21626057
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
  var valid_21626058 = header.getOrDefault("X-Amz-Date")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Date", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Security-Token", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Algorithm", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Signature")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Signature", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Credential")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Credential", valid_21626064
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Tags` field"
  var valid_21626065 = formData.getOrDefault("Tags")
  valid_21626065 = validateParameter(valid_21626065, JArray, required = true,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "Tags", valid_21626065
  var valid_21626066 = formData.getOrDefault("ResourceName")
  valid_21626066 = validateParameter(valid_21626066, JString, required = true,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "ResourceName", valid_21626066
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626067: Call_PostAddTagsToResource_21626053;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626067.validator(path, query, header, formData, body, _)
  let scheme = call_21626067.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626067.makeUrl(scheme.get, call_21626067.host, call_21626067.base,
                               call_21626067.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626067, uri, valid, _)

proc call*(call_21626068: Call_PostAddTagsToResource_21626053; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## postAddTagsToResource
  ##   Tags: JArray (required)
  ##   Action: string (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21626069 = newJObject()
  var formData_21626070 = newJObject()
  if Tags != nil:
    formData_21626070.add "Tags", Tags
  add(query_21626069, "Action", newJString(Action))
  add(formData_21626070, "ResourceName", newJString(ResourceName))
  add(query_21626069, "Version", newJString(Version))
  result = call_21626068.call(nil, query_21626069, nil, formData_21626070, nil)

var postAddTagsToResource* = Call_PostAddTagsToResource_21626053(
    name: "postAddTagsToResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_PostAddTagsToResource_21626054, base: "/",
    makeUrl: url_PostAddTagsToResource_21626055,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAddTagsToResource_21626036 = ref object of OpenApiRestCall_21625418
proc url_GetAddTagsToResource_21626038(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAddTagsToResource_21626037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray (required)
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Tags` field"
  var valid_21626039 = query.getOrDefault("Tags")
  valid_21626039 = validateParameter(valid_21626039, JArray, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "Tags", valid_21626039
  var valid_21626040 = query.getOrDefault("ResourceName")
  valid_21626040 = validateParameter(valid_21626040, JString, required = true,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "ResourceName", valid_21626040
  var valid_21626041 = query.getOrDefault("Action")
  valid_21626041 = validateParameter(valid_21626041, JString, required = true,
                                   default = newJString("AddTagsToResource"))
  if valid_21626041 != nil:
    section.add "Action", valid_21626041
  var valid_21626042 = query.getOrDefault("Version")
  valid_21626042 = validateParameter(valid_21626042, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626042 != nil:
    section.add "Version", valid_21626042
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
  var valid_21626043 = header.getOrDefault("X-Amz-Date")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Date", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Security-Token", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Algorithm", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Signature")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Signature", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-Credential")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-Credential", valid_21626049
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626050: Call_GetAddTagsToResource_21626036; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626050.validator(path, query, header, formData, body, _)
  let scheme = call_21626050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626050.makeUrl(scheme.get, call_21626050.host, call_21626050.base,
                               call_21626050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626050, uri, valid, _)

proc call*(call_21626051: Call_GetAddTagsToResource_21626036; Tags: JsonNode;
          ResourceName: string; Action: string = "AddTagsToResource";
          Version: string = "2013-09-09"): Recallable =
  ## getAddTagsToResource
  ##   Tags: JArray (required)
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626052 = newJObject()
  if Tags != nil:
    query_21626052.add "Tags", Tags
  add(query_21626052, "ResourceName", newJString(ResourceName))
  add(query_21626052, "Action", newJString(Action))
  add(query_21626052, "Version", newJString(Version))
  result = call_21626051.call(nil, query_21626052, nil, nil, nil)

var getAddTagsToResource* = Call_GetAddTagsToResource_21626036(
    name: "getAddTagsToResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AddTagsToResource",
    validator: validate_GetAddTagsToResource_21626037, base: "/",
    makeUrl: url_GetAddTagsToResource_21626038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostAuthorizeDBSecurityGroupIngress_21626092 = ref object of OpenApiRestCall_21625418
proc url_PostAuthorizeDBSecurityGroupIngress_21626094(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostAuthorizeDBSecurityGroupIngress_21626093(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626095 = query.getOrDefault("Action")
  valid_21626095 = validateParameter(valid_21626095, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_21626095 != nil:
    section.add "Action", valid_21626095
  var valid_21626096 = query.getOrDefault("Version")
  valid_21626096 = validateParameter(valid_21626096, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626096 != nil:
    section.add "Version", valid_21626096
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
  var valid_21626097 = header.getOrDefault("X-Amz-Date")
  valid_21626097 = validateParameter(valid_21626097, JString, required = false,
                                   default = nil)
  if valid_21626097 != nil:
    section.add "X-Amz-Date", valid_21626097
  var valid_21626098 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626098 = validateParameter(valid_21626098, JString, required = false,
                                   default = nil)
  if valid_21626098 != nil:
    section.add "X-Amz-Security-Token", valid_21626098
  var valid_21626099 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626099 = validateParameter(valid_21626099, JString, required = false,
                                   default = nil)
  if valid_21626099 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626099
  var valid_21626100 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "X-Amz-Algorithm", valid_21626100
  var valid_21626101 = header.getOrDefault("X-Amz-Signature")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "X-Amz-Signature", valid_21626101
  var valid_21626102 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Credential")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Credential", valid_21626103
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626104 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "DBSecurityGroupName", valid_21626104
  var valid_21626105 = formData.getOrDefault("EC2SecurityGroupName")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "EC2SecurityGroupName", valid_21626105
  var valid_21626106 = formData.getOrDefault("EC2SecurityGroupId")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "EC2SecurityGroupId", valid_21626106
  var valid_21626107 = formData.getOrDefault("CIDRIP")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "CIDRIP", valid_21626107
  var valid_21626108 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21626108
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626109: Call_PostAuthorizeDBSecurityGroupIngress_21626092;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626109.validator(path, query, header, formData, body, _)
  let scheme = call_21626109.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626109.makeUrl(scheme.get, call_21626109.host, call_21626109.base,
                               call_21626109.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626109, uri, valid, _)

proc call*(call_21626110: Call_PostAuthorizeDBSecurityGroupIngress_21626092;
          DBSecurityGroupName: string;
          Action: string = "AuthorizeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-09-09";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postAuthorizeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_21626111 = newJObject()
  var formData_21626112 = newJObject()
  add(formData_21626112, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626111, "Action", newJString(Action))
  add(formData_21626112, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_21626112, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_21626112, "CIDRIP", newJString(CIDRIP))
  add(query_21626111, "Version", newJString(Version))
  add(formData_21626112, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_21626110.call(nil, query_21626111, nil, formData_21626112, nil)

var postAuthorizeDBSecurityGroupIngress* = Call_PostAuthorizeDBSecurityGroupIngress_21626092(
    name: "postAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_PostAuthorizeDBSecurityGroupIngress_21626093, base: "/",
    makeUrl: url_PostAuthorizeDBSecurityGroupIngress_21626094,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAuthorizeDBSecurityGroupIngress_21626071 = ref object of OpenApiRestCall_21625418
proc url_GetAuthorizeDBSecurityGroupIngress_21626073(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAuthorizeDBSecurityGroupIngress_21626072(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   CIDRIP: JString
  ##   EC2SecurityGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626074 = query.getOrDefault("EC2SecurityGroupId")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "EC2SecurityGroupId", valid_21626074
  var valid_21626075 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21626075
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626076 = query.getOrDefault("DBSecurityGroupName")
  valid_21626076 = validateParameter(valid_21626076, JString, required = true,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "DBSecurityGroupName", valid_21626076
  var valid_21626077 = query.getOrDefault("Action")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true, default = newJString(
      "AuthorizeDBSecurityGroupIngress"))
  if valid_21626077 != nil:
    section.add "Action", valid_21626077
  var valid_21626078 = query.getOrDefault("CIDRIP")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "CIDRIP", valid_21626078
  var valid_21626079 = query.getOrDefault("EC2SecurityGroupName")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "EC2SecurityGroupName", valid_21626079
  var valid_21626080 = query.getOrDefault("Version")
  valid_21626080 = validateParameter(valid_21626080, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626080 != nil:
    section.add "Version", valid_21626080
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
  var valid_21626081 = header.getOrDefault("X-Amz-Date")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Date", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Security-Token", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-Algorithm", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Signature")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Signature", valid_21626085
  var valid_21626086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Credential")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Credential", valid_21626087
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626088: Call_GetAuthorizeDBSecurityGroupIngress_21626071;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626088.validator(path, query, header, formData, body, _)
  let scheme = call_21626088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626088.makeUrl(scheme.get, call_21626088.host, call_21626088.base,
                               call_21626088.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626088, uri, valid, _)

proc call*(call_21626089: Call_GetAuthorizeDBSecurityGroupIngress_21626071;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "AuthorizeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getAuthorizeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_21626090 = newJObject()
  add(query_21626090, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_21626090, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_21626090, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626090, "Action", newJString(Action))
  add(query_21626090, "CIDRIP", newJString(CIDRIP))
  add(query_21626090, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_21626090, "Version", newJString(Version))
  result = call_21626089.call(nil, query_21626090, nil, nil, nil)

var getAuthorizeDBSecurityGroupIngress* = Call_GetAuthorizeDBSecurityGroupIngress_21626071(
    name: "getAuthorizeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=AuthorizeDBSecurityGroupIngress",
    validator: validate_GetAuthorizeDBSecurityGroupIngress_21626072, base: "/",
    makeUrl: url_GetAuthorizeDBSecurityGroupIngress_21626073,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCopyDBSnapshot_21626131 = ref object of OpenApiRestCall_21625418
proc url_PostCopyDBSnapshot_21626133(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCopyDBSnapshot_21626132(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626134 = query.getOrDefault("Action")
  valid_21626134 = validateParameter(valid_21626134, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626134 != nil:
    section.add "Action", valid_21626134
  var valid_21626135 = query.getOrDefault("Version")
  valid_21626135 = validateParameter(valid_21626135, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626135 != nil:
    section.add "Version", valid_21626135
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
  var valid_21626136 = header.getOrDefault("X-Amz-Date")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Date", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Security-Token", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Algorithm", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-Signature")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Signature", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Credential")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Credential", valid_21626142
  result.add "header", section
  ## parameters in `formData` object:
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Tags: JArray
  ##   SourceDBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626143 = formData.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626143 = validateParameter(valid_21626143, JString, required = true,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626143
  var valid_21626144 = formData.getOrDefault("Tags")
  valid_21626144 = validateParameter(valid_21626144, JArray, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "Tags", valid_21626144
  var valid_21626145 = formData.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626145 = validateParameter(valid_21626145, JString, required = true,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626145
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626146: Call_PostCopyDBSnapshot_21626131; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626146.validator(path, query, header, formData, body, _)
  let scheme = call_21626146.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626146.makeUrl(scheme.get, call_21626146.host, call_21626146.base,
                               call_21626146.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626146, uri, valid, _)

proc call*(call_21626147: Call_PostCopyDBSnapshot_21626131;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCopyDBSnapshot
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626148 = newJObject()
  var formData_21626149 = newJObject()
  add(formData_21626149, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  if Tags != nil:
    formData_21626149.add "Tags", Tags
  add(query_21626148, "Action", newJString(Action))
  add(formData_21626149, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626148, "Version", newJString(Version))
  result = call_21626147.call(nil, query_21626148, nil, formData_21626149, nil)

var postCopyDBSnapshot* = Call_PostCopyDBSnapshot_21626131(
    name: "postCopyDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CopyDBSnapshot",
    validator: validate_PostCopyDBSnapshot_21626132, base: "/",
    makeUrl: url_PostCopyDBSnapshot_21626133, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCopyDBSnapshot_21626113 = ref object of OpenApiRestCall_21625418
proc url_GetCopyDBSnapshot_21626115(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCopyDBSnapshot_21626114(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: JString (required)
  ##   Action: JString (required)
  ##   SourceDBSnapshotIdentifier: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626116 = query.getOrDefault("Tags")
  valid_21626116 = validateParameter(valid_21626116, JArray, required = false,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "Tags", valid_21626116
  assert query != nil, "query argument is necessary due to required `TargetDBSnapshotIdentifier` field"
  var valid_21626117 = query.getOrDefault("TargetDBSnapshotIdentifier")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "TargetDBSnapshotIdentifier", valid_21626117
  var valid_21626118 = query.getOrDefault("Action")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = newJString("CopyDBSnapshot"))
  if valid_21626118 != nil:
    section.add "Action", valid_21626118
  var valid_21626119 = query.getOrDefault("SourceDBSnapshotIdentifier")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "SourceDBSnapshotIdentifier", valid_21626119
  var valid_21626120 = query.getOrDefault("Version")
  valid_21626120 = validateParameter(valid_21626120, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626120 != nil:
    section.add "Version", valid_21626120
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
  var valid_21626121 = header.getOrDefault("X-Amz-Date")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Date", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Security-Token", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Algorithm", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-Signature")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-Signature", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626126
  var valid_21626127 = header.getOrDefault("X-Amz-Credential")
  valid_21626127 = validateParameter(valid_21626127, JString, required = false,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "X-Amz-Credential", valid_21626127
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626128: Call_GetCopyDBSnapshot_21626113; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626128.validator(path, query, header, formData, body, _)
  let scheme = call_21626128.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626128.makeUrl(scheme.get, call_21626128.host, call_21626128.base,
                               call_21626128.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626128, uri, valid, _)

proc call*(call_21626129: Call_GetCopyDBSnapshot_21626113;
          TargetDBSnapshotIdentifier: string; SourceDBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CopyDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCopyDBSnapshot
  ##   Tags: JArray
  ##   TargetDBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   SourceDBSnapshotIdentifier: string (required)
  ##   Version: string (required)
  var query_21626130 = newJObject()
  if Tags != nil:
    query_21626130.add "Tags", Tags
  add(query_21626130, "TargetDBSnapshotIdentifier",
      newJString(TargetDBSnapshotIdentifier))
  add(query_21626130, "Action", newJString(Action))
  add(query_21626130, "SourceDBSnapshotIdentifier",
      newJString(SourceDBSnapshotIdentifier))
  add(query_21626130, "Version", newJString(Version))
  result = call_21626129.call(nil, query_21626130, nil, nil, nil)

var getCopyDBSnapshot* = Call_GetCopyDBSnapshot_21626113(name: "getCopyDBSnapshot",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=CopyDBSnapshot", validator: validate_GetCopyDBSnapshot_21626114,
    base: "/", makeUrl: url_GetCopyDBSnapshot_21626115,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstance_21626190 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstance_21626192(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstance_21626191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626193 = query.getOrDefault("Action")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626193 != nil:
    section.add "Action", valid_21626193
  var valid_21626194 = query.getOrDefault("Version")
  valid_21626194 = validateParameter(valid_21626194, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626194 != nil:
    section.add "Version", valid_21626194
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
  var valid_21626195 = header.getOrDefault("X-Amz-Date")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Date", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Security-Token", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Algorithm", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Signature")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Signature", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Credential")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Credential", valid_21626201
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroups: JArray
  ##   Port: JInt
  ##   Engine: JString (required)
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   MasterUserPassword: JString (required)
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt (required)
  ##   PubliclyAccessible: JBool
  ##   MasterUsername: JString (required)
  ##   DBInstanceClass: JString (required)
  ##   CharacterSetName: JString
  ##   PreferredBackupWindow: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredMaintenanceWindow: JString
  section = newJObject()
  var valid_21626202 = formData.getOrDefault("DBSecurityGroups")
  valid_21626202 = validateParameter(valid_21626202, JArray, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "DBSecurityGroups", valid_21626202
  var valid_21626203 = formData.getOrDefault("Port")
  valid_21626203 = validateParameter(valid_21626203, JInt, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "Port", valid_21626203
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21626204 = formData.getOrDefault("Engine")
  valid_21626204 = validateParameter(valid_21626204, JString, required = true,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "Engine", valid_21626204
  var valid_21626205 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21626205 = validateParameter(valid_21626205, JArray, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "VpcSecurityGroupIds", valid_21626205
  var valid_21626206 = formData.getOrDefault("Iops")
  valid_21626206 = validateParameter(valid_21626206, JInt, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "Iops", valid_21626206
  var valid_21626207 = formData.getOrDefault("DBName")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "DBName", valid_21626207
  var valid_21626208 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "DBInstanceIdentifier", valid_21626208
  var valid_21626209 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21626209 = validateParameter(valid_21626209, JInt, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "BackupRetentionPeriod", valid_21626209
  var valid_21626210 = formData.getOrDefault("DBParameterGroupName")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "DBParameterGroupName", valid_21626210
  var valid_21626211 = formData.getOrDefault("OptionGroupName")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "OptionGroupName", valid_21626211
  var valid_21626212 = formData.getOrDefault("Tags")
  valid_21626212 = validateParameter(valid_21626212, JArray, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "Tags", valid_21626212
  var valid_21626213 = formData.getOrDefault("MasterUserPassword")
  valid_21626213 = validateParameter(valid_21626213, JString, required = true,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "MasterUserPassword", valid_21626213
  var valid_21626214 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "DBSubnetGroupName", valid_21626214
  var valid_21626215 = formData.getOrDefault("AvailabilityZone")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "AvailabilityZone", valid_21626215
  var valid_21626216 = formData.getOrDefault("MultiAZ")
  valid_21626216 = validateParameter(valid_21626216, JBool, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "MultiAZ", valid_21626216
  var valid_21626217 = formData.getOrDefault("AllocatedStorage")
  valid_21626217 = validateParameter(valid_21626217, JInt, required = true,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "AllocatedStorage", valid_21626217
  var valid_21626218 = formData.getOrDefault("PubliclyAccessible")
  valid_21626218 = validateParameter(valid_21626218, JBool, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "PubliclyAccessible", valid_21626218
  var valid_21626219 = formData.getOrDefault("MasterUsername")
  valid_21626219 = validateParameter(valid_21626219, JString, required = true,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "MasterUsername", valid_21626219
  var valid_21626220 = formData.getOrDefault("DBInstanceClass")
  valid_21626220 = validateParameter(valid_21626220, JString, required = true,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "DBInstanceClass", valid_21626220
  var valid_21626221 = formData.getOrDefault("CharacterSetName")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "CharacterSetName", valid_21626221
  var valid_21626222 = formData.getOrDefault("PreferredBackupWindow")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "PreferredBackupWindow", valid_21626222
  var valid_21626223 = formData.getOrDefault("LicenseModel")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "LicenseModel", valid_21626223
  var valid_21626224 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626224 = validateParameter(valid_21626224, JBool, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626224
  var valid_21626225 = formData.getOrDefault("EngineVersion")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "EngineVersion", valid_21626225
  var valid_21626226 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626226
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626227: Call_PostCreateDBInstance_21626190; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626227.validator(path, query, header, formData, body, _)
  let scheme = call_21626227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626227.makeUrl(scheme.get, call_21626227.host, call_21626227.base,
                               call_21626227.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626227, uri, valid, _)

proc call*(call_21626228: Call_PostCreateDBInstance_21626190; Engine: string;
          DBInstanceIdentifier: string; MasterUserPassword: string;
          AllocatedStorage: int; MasterUsername: string; DBInstanceClass: string;
          DBSecurityGroups: JsonNode = nil; Port: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0; DBName: string = "";
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "CreateDBInstance";
          PubliclyAccessible: bool = false; CharacterSetName: string = "";
          PreferredBackupWindow: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-09-09"; PreferredMaintenanceWindow: string = ""): Recallable =
  ## postCreateDBInstance
  ##   DBSecurityGroups: JArray
  ##   Port: int
  ##   Engine: string (required)
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   MasterUserPassword: string (required)
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int (required)
  ##   PubliclyAccessible: bool
  ##   MasterUsername: string (required)
  ##   DBInstanceClass: string (required)
  ##   CharacterSetName: string
  ##   PreferredBackupWindow: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   PreferredMaintenanceWindow: string
  var query_21626229 = newJObject()
  var formData_21626230 = newJObject()
  if DBSecurityGroups != nil:
    formData_21626230.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21626230, "Port", newJInt(Port))
  add(formData_21626230, "Engine", newJString(Engine))
  if VpcSecurityGroupIds != nil:
    formData_21626230.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21626230, "Iops", newJInt(Iops))
  add(formData_21626230, "DBName", newJString(DBName))
  add(formData_21626230, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626230, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21626230, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626230, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626230.add "Tags", Tags
  add(formData_21626230, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21626230, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626230, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21626230, "MultiAZ", newJBool(MultiAZ))
  add(query_21626229, "Action", newJString(Action))
  add(formData_21626230, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21626230, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626230, "MasterUsername", newJString(MasterUsername))
  add(formData_21626230, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626230, "CharacterSetName", newJString(CharacterSetName))
  add(formData_21626230, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21626230, "LicenseModel", newJString(LicenseModel))
  add(formData_21626230, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21626230, "EngineVersion", newJString(EngineVersion))
  add(query_21626229, "Version", newJString(Version))
  add(formData_21626230, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  result = call_21626228.call(nil, query_21626229, nil, formData_21626230, nil)

var postCreateDBInstance* = Call_PostCreateDBInstance_21626190(
    name: "postCreateDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_PostCreateDBInstance_21626191, base: "/",
    makeUrl: url_PostCreateDBInstance_21626192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstance_21626150 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstance_21626152(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstance_21626151(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt (required)
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   BackupRetentionPeriod: JInt
  ##   DBName: JString
  ##   DBParameterGroupName: JString
  ##   Tags: JArray
  ##   DBInstanceClass: JString (required)
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   CharacterSetName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   Port: JInt
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   MasterUsername: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21626153 = query.getOrDefault("Engine")
  valid_21626153 = validateParameter(valid_21626153, JString, required = true,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "Engine", valid_21626153
  var valid_21626154 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "PreferredMaintenanceWindow", valid_21626154
  var valid_21626155 = query.getOrDefault("AllocatedStorage")
  valid_21626155 = validateParameter(valid_21626155, JInt, required = true,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "AllocatedStorage", valid_21626155
  var valid_21626156 = query.getOrDefault("OptionGroupName")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "OptionGroupName", valid_21626156
  var valid_21626157 = query.getOrDefault("DBSecurityGroups")
  valid_21626157 = validateParameter(valid_21626157, JArray, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "DBSecurityGroups", valid_21626157
  var valid_21626158 = query.getOrDefault("MasterUserPassword")
  valid_21626158 = validateParameter(valid_21626158, JString, required = true,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "MasterUserPassword", valid_21626158
  var valid_21626159 = query.getOrDefault("AvailabilityZone")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "AvailabilityZone", valid_21626159
  var valid_21626160 = query.getOrDefault("Iops")
  valid_21626160 = validateParameter(valid_21626160, JInt, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "Iops", valid_21626160
  var valid_21626161 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21626161 = validateParameter(valid_21626161, JArray, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "VpcSecurityGroupIds", valid_21626161
  var valid_21626162 = query.getOrDefault("MultiAZ")
  valid_21626162 = validateParameter(valid_21626162, JBool, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "MultiAZ", valid_21626162
  var valid_21626163 = query.getOrDefault("LicenseModel")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "LicenseModel", valid_21626163
  var valid_21626164 = query.getOrDefault("BackupRetentionPeriod")
  valid_21626164 = validateParameter(valid_21626164, JInt, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "BackupRetentionPeriod", valid_21626164
  var valid_21626165 = query.getOrDefault("DBName")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "DBName", valid_21626165
  var valid_21626166 = query.getOrDefault("DBParameterGroupName")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "DBParameterGroupName", valid_21626166
  var valid_21626167 = query.getOrDefault("Tags")
  valid_21626167 = validateParameter(valid_21626167, JArray, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "Tags", valid_21626167
  var valid_21626168 = query.getOrDefault("DBInstanceClass")
  valid_21626168 = validateParameter(valid_21626168, JString, required = true,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "DBInstanceClass", valid_21626168
  var valid_21626169 = query.getOrDefault("Action")
  valid_21626169 = validateParameter(valid_21626169, JString, required = true,
                                   default = newJString("CreateDBInstance"))
  if valid_21626169 != nil:
    section.add "Action", valid_21626169
  var valid_21626170 = query.getOrDefault("DBSubnetGroupName")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "DBSubnetGroupName", valid_21626170
  var valid_21626171 = query.getOrDefault("CharacterSetName")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "CharacterSetName", valid_21626171
  var valid_21626172 = query.getOrDefault("PubliclyAccessible")
  valid_21626172 = validateParameter(valid_21626172, JBool, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "PubliclyAccessible", valid_21626172
  var valid_21626173 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626173 = validateParameter(valid_21626173, JBool, required = false,
                                   default = nil)
  if valid_21626173 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626173
  var valid_21626174 = query.getOrDefault("EngineVersion")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "EngineVersion", valid_21626174
  var valid_21626175 = query.getOrDefault("Port")
  valid_21626175 = validateParameter(valid_21626175, JInt, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "Port", valid_21626175
  var valid_21626176 = query.getOrDefault("PreferredBackupWindow")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "PreferredBackupWindow", valid_21626176
  var valid_21626177 = query.getOrDefault("Version")
  valid_21626177 = validateParameter(valid_21626177, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626177 != nil:
    section.add "Version", valid_21626177
  var valid_21626178 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626178 = validateParameter(valid_21626178, JString, required = true,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "DBInstanceIdentifier", valid_21626178
  var valid_21626179 = query.getOrDefault("MasterUsername")
  valid_21626179 = validateParameter(valid_21626179, JString, required = true,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "MasterUsername", valid_21626179
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
  var valid_21626180 = header.getOrDefault("X-Amz-Date")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Date", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Security-Token", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Algorithm", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-Signature")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-Signature", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626185
  var valid_21626186 = header.getOrDefault("X-Amz-Credential")
  valid_21626186 = validateParameter(valid_21626186, JString, required = false,
                                   default = nil)
  if valid_21626186 != nil:
    section.add "X-Amz-Credential", valid_21626186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626187: Call_GetCreateDBInstance_21626150; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626187.validator(path, query, header, formData, body, _)
  let scheme = call_21626187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626187.makeUrl(scheme.get, call_21626187.host, call_21626187.base,
                               call_21626187.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626187, uri, valid, _)

proc call*(call_21626188: Call_GetCreateDBInstance_21626150; Engine: string;
          AllocatedStorage: int; MasterUserPassword: string;
          DBInstanceClass: string; DBInstanceIdentifier: string;
          MasterUsername: string; PreferredMaintenanceWindow: string = "";
          OptionGroupName: string = ""; DBSecurityGroups: JsonNode = nil;
          AvailabilityZone: string = ""; Iops: int = 0;
          VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          LicenseModel: string = ""; BackupRetentionPeriod: int = 0;
          DBName: string = ""; DBParameterGroupName: string = ""; Tags: JsonNode = nil;
          Action: string = "CreateDBInstance"; DBSubnetGroupName: string = "";
          CharacterSetName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Port: int = 0; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBInstance
  ##   Engine: string (required)
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int (required)
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   BackupRetentionPeriod: int
  ##   DBName: string
  ##   DBParameterGroupName: string
  ##   Tags: JArray
  ##   DBInstanceClass: string (required)
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   CharacterSetName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Port: int
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   MasterUsername: string (required)
  var query_21626189 = newJObject()
  add(query_21626189, "Engine", newJString(Engine))
  add(query_21626189, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21626189, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21626189, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21626189.add "DBSecurityGroups", DBSecurityGroups
  add(query_21626189, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21626189, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626189, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21626189.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21626189, "MultiAZ", newJBool(MultiAZ))
  add(query_21626189, "LicenseModel", newJString(LicenseModel))
  add(query_21626189, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21626189, "DBName", newJString(DBName))
  add(query_21626189, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    query_21626189.add "Tags", Tags
  add(query_21626189, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626189, "Action", newJString(Action))
  add(query_21626189, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626189, "CharacterSetName", newJString(CharacterSetName))
  add(query_21626189, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626189, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626189, "EngineVersion", newJString(EngineVersion))
  add(query_21626189, "Port", newJInt(Port))
  add(query_21626189, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21626189, "Version", newJString(Version))
  add(query_21626189, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626189, "MasterUsername", newJString(MasterUsername))
  result = call_21626188.call(nil, query_21626189, nil, nil, nil)

var getCreateDBInstance* = Call_GetCreateDBInstance_21626150(
    name: "getCreateDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstance",
    validator: validate_GetCreateDBInstance_21626151, base: "/",
    makeUrl: url_GetCreateDBInstance_21626152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBInstanceReadReplica_21626257 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBInstanceReadReplica_21626259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBInstanceReadReplica_21626258(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626260 = query.getOrDefault("Action")
  valid_21626260 = validateParameter(valid_21626260, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626260 != nil:
    section.add "Action", valid_21626260
  var valid_21626261 = query.getOrDefault("Version")
  valid_21626261 = validateParameter(valid_21626261, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626261 != nil:
    section.add "Version", valid_21626261
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
  var valid_21626262 = header.getOrDefault("X-Amz-Date")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Date", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Security-Token", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Algorithm", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Signature")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Signature", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Credential")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Credential", valid_21626268
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21626269 = formData.getOrDefault("Port")
  valid_21626269 = validateParameter(valid_21626269, JInt, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "Port", valid_21626269
  var valid_21626270 = formData.getOrDefault("Iops")
  valid_21626270 = validateParameter(valid_21626270, JInt, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "Iops", valid_21626270
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626271 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626271 = validateParameter(valid_21626271, JString, required = true,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "DBInstanceIdentifier", valid_21626271
  var valid_21626272 = formData.getOrDefault("OptionGroupName")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "OptionGroupName", valid_21626272
  var valid_21626273 = formData.getOrDefault("Tags")
  valid_21626273 = validateParameter(valid_21626273, JArray, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "Tags", valid_21626273
  var valid_21626274 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "DBSubnetGroupName", valid_21626274
  var valid_21626275 = formData.getOrDefault("AvailabilityZone")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "AvailabilityZone", valid_21626275
  var valid_21626276 = formData.getOrDefault("PubliclyAccessible")
  valid_21626276 = validateParameter(valid_21626276, JBool, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "PubliclyAccessible", valid_21626276
  var valid_21626277 = formData.getOrDefault("DBInstanceClass")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "DBInstanceClass", valid_21626277
  var valid_21626278 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626278 = validateParameter(valid_21626278, JString, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626278
  var valid_21626279 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626279 = validateParameter(valid_21626279, JBool, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626279
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626280: Call_PostCreateDBInstanceReadReplica_21626257;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626280.validator(path, query, header, formData, body, _)
  let scheme = call_21626280.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626280.makeUrl(scheme.get, call_21626280.host, call_21626280.base,
                               call_21626280.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626280, uri, valid, _)

proc call*(call_21626281: Call_PostCreateDBInstanceReadReplica_21626257;
          DBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          Port: int = 0; Iops: int = 0; OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBInstanceReadReplica
  ##   Port: int
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21626282 = newJObject()
  var formData_21626283 = newJObject()
  add(formData_21626283, "Port", newJInt(Port))
  add(formData_21626283, "Iops", newJInt(Iops))
  add(formData_21626283, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626283, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626283.add "Tags", Tags
  add(formData_21626283, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21626283, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626282, "Action", newJString(Action))
  add(formData_21626283, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21626283, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21626283, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21626283, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21626282, "Version", newJString(Version))
  result = call_21626281.call(nil, query_21626282, nil, formData_21626283, nil)

var postCreateDBInstanceReadReplica* = Call_PostCreateDBInstanceReadReplica_21626257(
    name: "postCreateDBInstanceReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_PostCreateDBInstanceReadReplica_21626258, base: "/",
    makeUrl: url_PostCreateDBInstanceReadReplica_21626259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBInstanceReadReplica_21626231 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBInstanceReadReplica_21626233(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBInstanceReadReplica_21626232(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   Tags: JArray
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_21626234 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21626234 = validateParameter(valid_21626234, JString, required = true,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21626234
  var valid_21626235 = query.getOrDefault("OptionGroupName")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "OptionGroupName", valid_21626235
  var valid_21626236 = query.getOrDefault("AvailabilityZone")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "AvailabilityZone", valid_21626236
  var valid_21626237 = query.getOrDefault("Iops")
  valid_21626237 = validateParameter(valid_21626237, JInt, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "Iops", valid_21626237
  var valid_21626238 = query.getOrDefault("Tags")
  valid_21626238 = validateParameter(valid_21626238, JArray, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "Tags", valid_21626238
  var valid_21626239 = query.getOrDefault("DBInstanceClass")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "DBInstanceClass", valid_21626239
  var valid_21626240 = query.getOrDefault("Action")
  valid_21626240 = validateParameter(valid_21626240, JString, required = true, default = newJString(
      "CreateDBInstanceReadReplica"))
  if valid_21626240 != nil:
    section.add "Action", valid_21626240
  var valid_21626241 = query.getOrDefault("DBSubnetGroupName")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "DBSubnetGroupName", valid_21626241
  var valid_21626242 = query.getOrDefault("PubliclyAccessible")
  valid_21626242 = validateParameter(valid_21626242, JBool, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "PubliclyAccessible", valid_21626242
  var valid_21626243 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21626243 = validateParameter(valid_21626243, JBool, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21626243
  var valid_21626244 = query.getOrDefault("Port")
  valid_21626244 = validateParameter(valid_21626244, JInt, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "Port", valid_21626244
  var valid_21626245 = query.getOrDefault("Version")
  valid_21626245 = validateParameter(valid_21626245, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626245 != nil:
    section.add "Version", valid_21626245
  var valid_21626246 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626246 = validateParameter(valid_21626246, JString, required = true,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "DBInstanceIdentifier", valid_21626246
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
  var valid_21626247 = header.getOrDefault("X-Amz-Date")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Date", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-Security-Token", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Algorithm", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Signature")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Signature", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Credential")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Credential", valid_21626253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626254: Call_GetCreateDBInstanceReadReplica_21626231;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626254.validator(path, query, header, formData, body, _)
  let scheme = call_21626254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626254.makeUrl(scheme.get, call_21626254.host, call_21626254.base,
                               call_21626254.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626254, uri, valid, _)

proc call*(call_21626255: Call_GetCreateDBInstanceReadReplica_21626231;
          SourceDBInstanceIdentifier: string; DBInstanceIdentifier: string;
          OptionGroupName: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          Tags: JsonNode = nil; DBInstanceClass: string = "";
          Action: string = "CreateDBInstanceReadReplica";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBInstanceReadReplica
  ##   SourceDBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   Tags: JArray
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626256 = newJObject()
  add(query_21626256, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21626256, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626256, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21626256, "Iops", newJInt(Iops))
  if Tags != nil:
    query_21626256.add "Tags", Tags
  add(query_21626256, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21626256, "Action", newJString(Action))
  add(query_21626256, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626256, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21626256, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21626256, "Port", newJInt(Port))
  add(query_21626256, "Version", newJString(Version))
  add(query_21626256, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626255.call(nil, query_21626256, nil, nil, nil)

var getCreateDBInstanceReadReplica* = Call_GetCreateDBInstanceReadReplica_21626231(
    name: "getCreateDBInstanceReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBInstanceReadReplica",
    validator: validate_GetCreateDBInstanceReadReplica_21626232, base: "/",
    makeUrl: url_GetCreateDBInstanceReadReplica_21626233,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBParameterGroup_21626303 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBParameterGroup_21626305(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBParameterGroup_21626304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626306 = query.getOrDefault("Action")
  valid_21626306 = validateParameter(valid_21626306, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626306 != nil:
    section.add "Action", valid_21626306
  var valid_21626307 = query.getOrDefault("Version")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626307 != nil:
    section.add "Version", valid_21626307
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
  var valid_21626308 = header.getOrDefault("X-Amz-Date")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-Date", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Security-Token", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Algorithm", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Signature")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Signature", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-Credential")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-Credential", valid_21626314
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupFamily: JString (required)
  ##   Description: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626315 = formData.getOrDefault("DBParameterGroupName")
  valid_21626315 = validateParameter(valid_21626315, JString, required = true,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "DBParameterGroupName", valid_21626315
  var valid_21626316 = formData.getOrDefault("Tags")
  valid_21626316 = validateParameter(valid_21626316, JArray, required = false,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "Tags", valid_21626316
  var valid_21626317 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626317 = validateParameter(valid_21626317, JString, required = true,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "DBParameterGroupFamily", valid_21626317
  var valid_21626318 = formData.getOrDefault("Description")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "Description", valid_21626318
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626319: Call_PostCreateDBParameterGroup_21626303;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626319.validator(path, query, header, formData, body, _)
  let scheme = call_21626319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626319.makeUrl(scheme.get, call_21626319.host, call_21626319.base,
                               call_21626319.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626319, uri, valid, _)

proc call*(call_21626320: Call_PostCreateDBParameterGroup_21626303;
          DBParameterGroupName: string; DBParameterGroupFamily: string;
          Description: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Version: string (required)
  ##   Description: string (required)
  var query_21626321 = newJObject()
  var formData_21626322 = newJObject()
  add(formData_21626322, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Tags != nil:
    formData_21626322.add "Tags", Tags
  add(query_21626321, "Action", newJString(Action))
  add(formData_21626322, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  add(query_21626321, "Version", newJString(Version))
  add(formData_21626322, "Description", newJString(Description))
  result = call_21626320.call(nil, query_21626321, nil, formData_21626322, nil)

var postCreateDBParameterGroup* = Call_PostCreateDBParameterGroup_21626303(
    name: "postCreateDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_PostCreateDBParameterGroup_21626304, base: "/",
    makeUrl: url_PostCreateDBParameterGroup_21626305,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBParameterGroup_21626284 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBParameterGroup_21626286(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBParameterGroup_21626285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Description: JString (required)
  ##   DBParameterGroupFamily: JString (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Description` field"
  var valid_21626287 = query.getOrDefault("Description")
  valid_21626287 = validateParameter(valid_21626287, JString, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "Description", valid_21626287
  var valid_21626288 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626288 = validateParameter(valid_21626288, JString, required = true,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "DBParameterGroupFamily", valid_21626288
  var valid_21626289 = query.getOrDefault("Tags")
  valid_21626289 = validateParameter(valid_21626289, JArray, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "Tags", valid_21626289
  var valid_21626290 = query.getOrDefault("DBParameterGroupName")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "DBParameterGroupName", valid_21626290
  var valid_21626291 = query.getOrDefault("Action")
  valid_21626291 = validateParameter(valid_21626291, JString, required = true, default = newJString(
      "CreateDBParameterGroup"))
  if valid_21626291 != nil:
    section.add "Action", valid_21626291
  var valid_21626292 = query.getOrDefault("Version")
  valid_21626292 = validateParameter(valid_21626292, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626292 != nil:
    section.add "Version", valid_21626292
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
  var valid_21626293 = header.getOrDefault("X-Amz-Date")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Date", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Security-Token", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-Algorithm", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Signature")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Signature", valid_21626297
  var valid_21626298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626298 = validateParameter(valid_21626298, JString, required = false,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626298
  var valid_21626299 = header.getOrDefault("X-Amz-Credential")
  valid_21626299 = validateParameter(valid_21626299, JString, required = false,
                                   default = nil)
  if valid_21626299 != nil:
    section.add "X-Amz-Credential", valid_21626299
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626300: Call_GetCreateDBParameterGroup_21626284;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626300.validator(path, query, header, formData, body, _)
  let scheme = call_21626300.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626300.makeUrl(scheme.get, call_21626300.host, call_21626300.base,
                               call_21626300.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626300, uri, valid, _)

proc call*(call_21626301: Call_GetCreateDBParameterGroup_21626284;
          Description: string; DBParameterGroupFamily: string;
          DBParameterGroupName: string; Tags: JsonNode = nil;
          Action: string = "CreateDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBParameterGroup
  ##   Description: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Tags: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626302 = newJObject()
  add(query_21626302, "Description", newJString(Description))
  add(query_21626302, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Tags != nil:
    query_21626302.add "Tags", Tags
  add(query_21626302, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626302, "Action", newJString(Action))
  add(query_21626302, "Version", newJString(Version))
  result = call_21626301.call(nil, query_21626302, nil, nil, nil)

var getCreateDBParameterGroup* = Call_GetCreateDBParameterGroup_21626284(
    name: "getCreateDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBParameterGroup",
    validator: validate_GetCreateDBParameterGroup_21626285, base: "/",
    makeUrl: url_GetCreateDBParameterGroup_21626286,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSecurityGroup_21626341 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSecurityGroup_21626343(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSecurityGroup_21626342(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626344 = query.getOrDefault("Action")
  valid_21626344 = validateParameter(valid_21626344, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626344 != nil:
    section.add "Action", valid_21626344
  var valid_21626345 = query.getOrDefault("Version")
  valid_21626345 = validateParameter(valid_21626345, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626345 != nil:
    section.add "Version", valid_21626345
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
  var valid_21626346 = header.getOrDefault("X-Amz-Date")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Date", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Security-Token", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Algorithm", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Signature")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Signature", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-Credential")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-Credential", valid_21626352
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Tags: JArray
  ##   DBSecurityGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626353 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626353 = validateParameter(valid_21626353, JString, required = true,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "DBSecurityGroupName", valid_21626353
  var valid_21626354 = formData.getOrDefault("Tags")
  valid_21626354 = validateParameter(valid_21626354, JArray, required = false,
                                   default = nil)
  if valid_21626354 != nil:
    section.add "Tags", valid_21626354
  var valid_21626355 = formData.getOrDefault("DBSecurityGroupDescription")
  valid_21626355 = validateParameter(valid_21626355, JString, required = true,
                                   default = nil)
  if valid_21626355 != nil:
    section.add "DBSecurityGroupDescription", valid_21626355
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626356: Call_PostCreateDBSecurityGroup_21626341;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626356.validator(path, query, header, formData, body, _)
  let scheme = call_21626356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626356.makeUrl(scheme.get, call_21626356.host, call_21626356.base,
                               call_21626356.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626356, uri, valid, _)

proc call*(call_21626357: Call_PostCreateDBSecurityGroup_21626341;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626358 = newJObject()
  var formData_21626359 = newJObject()
  add(formData_21626359, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Tags != nil:
    formData_21626359.add "Tags", Tags
  add(query_21626358, "Action", newJString(Action))
  add(formData_21626359, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  add(query_21626358, "Version", newJString(Version))
  result = call_21626357.call(nil, query_21626358, nil, formData_21626359, nil)

var postCreateDBSecurityGroup* = Call_PostCreateDBSecurityGroup_21626341(
    name: "postCreateDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_PostCreateDBSecurityGroup_21626342, base: "/",
    makeUrl: url_PostCreateDBSecurityGroup_21626343,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSecurityGroup_21626323 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSecurityGroup_21626325(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSecurityGroup_21626324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   DBSecurityGroupDescription: JString (required)
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626326 = query.getOrDefault("DBSecurityGroupName")
  valid_21626326 = validateParameter(valid_21626326, JString, required = true,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "DBSecurityGroupName", valid_21626326
  var valid_21626327 = query.getOrDefault("DBSecurityGroupDescription")
  valid_21626327 = validateParameter(valid_21626327, JString, required = true,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "DBSecurityGroupDescription", valid_21626327
  var valid_21626328 = query.getOrDefault("Tags")
  valid_21626328 = validateParameter(valid_21626328, JArray, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "Tags", valid_21626328
  var valid_21626329 = query.getOrDefault("Action")
  valid_21626329 = validateParameter(valid_21626329, JString, required = true, default = newJString(
      "CreateDBSecurityGroup"))
  if valid_21626329 != nil:
    section.add "Action", valid_21626329
  var valid_21626330 = query.getOrDefault("Version")
  valid_21626330 = validateParameter(valid_21626330, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626330 != nil:
    section.add "Version", valid_21626330
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
  var valid_21626331 = header.getOrDefault("X-Amz-Date")
  valid_21626331 = validateParameter(valid_21626331, JString, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "X-Amz-Date", valid_21626331
  var valid_21626332 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626332 = validateParameter(valid_21626332, JString, required = false,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "X-Amz-Security-Token", valid_21626332
  var valid_21626333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Algorithm", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Signature")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Signature", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Credential")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Credential", valid_21626337
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626338: Call_GetCreateDBSecurityGroup_21626323;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626338.validator(path, query, header, formData, body, _)
  let scheme = call_21626338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626338.makeUrl(scheme.get, call_21626338.host, call_21626338.base,
                               call_21626338.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626338, uri, valid, _)

proc call*(call_21626339: Call_GetCreateDBSecurityGroup_21626323;
          DBSecurityGroupName: string; DBSecurityGroupDescription: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   DBSecurityGroupDescription: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626340 = newJObject()
  add(query_21626340, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626340, "DBSecurityGroupDescription",
      newJString(DBSecurityGroupDescription))
  if Tags != nil:
    query_21626340.add "Tags", Tags
  add(query_21626340, "Action", newJString(Action))
  add(query_21626340, "Version", newJString(Version))
  result = call_21626339.call(nil, query_21626340, nil, nil, nil)

var getCreateDBSecurityGroup* = Call_GetCreateDBSecurityGroup_21626323(
    name: "getCreateDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSecurityGroup",
    validator: validate_GetCreateDBSecurityGroup_21626324, base: "/",
    makeUrl: url_GetCreateDBSecurityGroup_21626325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSnapshot_21626378 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSnapshot_21626380(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSnapshot_21626379(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626381 = query.getOrDefault("Action")
  valid_21626381 = validateParameter(valid_21626381, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626381 != nil:
    section.add "Action", valid_21626381
  var valid_21626382 = query.getOrDefault("Version")
  valid_21626382 = validateParameter(valid_21626382, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626382 != nil:
    section.add "Version", valid_21626382
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
  var valid_21626383 = header.getOrDefault("X-Amz-Date")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Date", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Security-Token", valid_21626384
  var valid_21626385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626385 = validateParameter(valid_21626385, JString, required = false,
                                   default = nil)
  if valid_21626385 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626385
  var valid_21626386 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626386 = validateParameter(valid_21626386, JString, required = false,
                                   default = nil)
  if valid_21626386 != nil:
    section.add "X-Amz-Algorithm", valid_21626386
  var valid_21626387 = header.getOrDefault("X-Amz-Signature")
  valid_21626387 = validateParameter(valid_21626387, JString, required = false,
                                   default = nil)
  if valid_21626387 != nil:
    section.add "X-Amz-Signature", valid_21626387
  var valid_21626388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626388 = validateParameter(valid_21626388, JString, required = false,
                                   default = nil)
  if valid_21626388 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626388
  var valid_21626389 = header.getOrDefault("X-Amz-Credential")
  valid_21626389 = validateParameter(valid_21626389, JString, required = false,
                                   default = nil)
  if valid_21626389 != nil:
    section.add "X-Amz-Credential", valid_21626389
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626390 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "DBInstanceIdentifier", valid_21626390
  var valid_21626391 = formData.getOrDefault("Tags")
  valid_21626391 = validateParameter(valid_21626391, JArray, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "Tags", valid_21626391
  var valid_21626392 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626392 = validateParameter(valid_21626392, JString, required = true,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "DBSnapshotIdentifier", valid_21626392
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626393: Call_PostCreateDBSnapshot_21626378; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626393.validator(path, query, header, formData, body, _)
  let scheme = call_21626393.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626393.makeUrl(scheme.get, call_21626393.host, call_21626393.base,
                               call_21626393.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626393, uri, valid, _)

proc call*(call_21626394: Call_PostCreateDBSnapshot_21626378;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSnapshot
  ##   DBInstanceIdentifier: string (required)
  ##   Tags: JArray
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626395 = newJObject()
  var formData_21626396 = newJObject()
  add(formData_21626396, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  if Tags != nil:
    formData_21626396.add "Tags", Tags
  add(formData_21626396, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626395, "Action", newJString(Action))
  add(query_21626395, "Version", newJString(Version))
  result = call_21626394.call(nil, query_21626395, nil, formData_21626396, nil)

var postCreateDBSnapshot* = Call_PostCreateDBSnapshot_21626378(
    name: "postCreateDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_PostCreateDBSnapshot_21626379, base: "/",
    makeUrl: url_PostCreateDBSnapshot_21626380,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSnapshot_21626360 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSnapshot_21626362(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSnapshot_21626361(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_21626363 = query.getOrDefault("Tags")
  valid_21626363 = validateParameter(valid_21626363, JArray, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "Tags", valid_21626363
  var valid_21626364 = query.getOrDefault("Action")
  valid_21626364 = validateParameter(valid_21626364, JString, required = true,
                                   default = newJString("CreateDBSnapshot"))
  if valid_21626364 != nil:
    section.add "Action", valid_21626364
  var valid_21626365 = query.getOrDefault("Version")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626365 != nil:
    section.add "Version", valid_21626365
  var valid_21626366 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626366 = validateParameter(valid_21626366, JString, required = true,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "DBInstanceIdentifier", valid_21626366
  var valid_21626367 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626367 = validateParameter(valid_21626367, JString, required = true,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "DBSnapshotIdentifier", valid_21626367
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
  var valid_21626368 = header.getOrDefault("X-Amz-Date")
  valid_21626368 = validateParameter(valid_21626368, JString, required = false,
                                   default = nil)
  if valid_21626368 != nil:
    section.add "X-Amz-Date", valid_21626368
  var valid_21626369 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626369 = validateParameter(valid_21626369, JString, required = false,
                                   default = nil)
  if valid_21626369 != nil:
    section.add "X-Amz-Security-Token", valid_21626369
  var valid_21626370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626370 = validateParameter(valid_21626370, JString, required = false,
                                   default = nil)
  if valid_21626370 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626370
  var valid_21626371 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626371 = validateParameter(valid_21626371, JString, required = false,
                                   default = nil)
  if valid_21626371 != nil:
    section.add "X-Amz-Algorithm", valid_21626371
  var valid_21626372 = header.getOrDefault("X-Amz-Signature")
  valid_21626372 = validateParameter(valid_21626372, JString, required = false,
                                   default = nil)
  if valid_21626372 != nil:
    section.add "X-Amz-Signature", valid_21626372
  var valid_21626373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626373 = validateParameter(valid_21626373, JString, required = false,
                                   default = nil)
  if valid_21626373 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626373
  var valid_21626374 = header.getOrDefault("X-Amz-Credential")
  valid_21626374 = validateParameter(valid_21626374, JString, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "X-Amz-Credential", valid_21626374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626375: Call_GetCreateDBSnapshot_21626360; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626375.validator(path, query, header, formData, body, _)
  let scheme = call_21626375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626375.makeUrl(scheme.get, call_21626375.host, call_21626375.base,
                               call_21626375.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626375, uri, valid, _)

proc call*(call_21626376: Call_GetCreateDBSnapshot_21626360;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Tags: JsonNode = nil; Action: string = "CreateDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSnapshot
  ##   Tags: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626377 = newJObject()
  if Tags != nil:
    query_21626377.add "Tags", Tags
  add(query_21626377, "Action", newJString(Action))
  add(query_21626377, "Version", newJString(Version))
  add(query_21626377, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21626377, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626376.call(nil, query_21626377, nil, nil, nil)

var getCreateDBSnapshot* = Call_GetCreateDBSnapshot_21626360(
    name: "getCreateDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSnapshot",
    validator: validate_GetCreateDBSnapshot_21626361, base: "/",
    makeUrl: url_GetCreateDBSnapshot_21626362,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateDBSubnetGroup_21626416 = ref object of OpenApiRestCall_21625418
proc url_PostCreateDBSubnetGroup_21626418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDBSubnetGroup_21626417(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626419 = query.getOrDefault("Action")
  valid_21626419 = validateParameter(valid_21626419, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626419 != nil:
    section.add "Action", valid_21626419
  var valid_21626420 = query.getOrDefault("Version")
  valid_21626420 = validateParameter(valid_21626420, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626420 != nil:
    section.add "Version", valid_21626420
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
  var valid_21626421 = header.getOrDefault("X-Amz-Date")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Date", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Security-Token", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Algorithm", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Signature")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Signature", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Credential")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Credential", valid_21626427
  result.add "header", section
  ## parameters in `formData` object:
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  section = newJObject()
  var valid_21626428 = formData.getOrDefault("Tags")
  valid_21626428 = validateParameter(valid_21626428, JArray, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "Tags", valid_21626428
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626429 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626429 = validateParameter(valid_21626429, JString, required = true,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "DBSubnetGroupName", valid_21626429
  var valid_21626430 = formData.getOrDefault("SubnetIds")
  valid_21626430 = validateParameter(valid_21626430, JArray, required = true,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "SubnetIds", valid_21626430
  var valid_21626431 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21626431 = validateParameter(valid_21626431, JString, required = true,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "DBSubnetGroupDescription", valid_21626431
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626432: Call_PostCreateDBSubnetGroup_21626416;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626432.validator(path, query, header, formData, body, _)
  let scheme = call_21626432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626432.makeUrl(scheme.get, call_21626432.host, call_21626432.base,
                               call_21626432.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626432, uri, valid, _)

proc call*(call_21626433: Call_PostCreateDBSubnetGroup_21626416;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateDBSubnetGroup
  ##   Tags: JArray
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626434 = newJObject()
  var formData_21626435 = newJObject()
  if Tags != nil:
    formData_21626435.add "Tags", Tags
  add(formData_21626435, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21626435.add "SubnetIds", SubnetIds
  add(query_21626434, "Action", newJString(Action))
  add(formData_21626435, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626434, "Version", newJString(Version))
  result = call_21626433.call(nil, query_21626434, nil, formData_21626435, nil)

var postCreateDBSubnetGroup* = Call_PostCreateDBSubnetGroup_21626416(
    name: "postCreateDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_PostCreateDBSubnetGroup_21626417, base: "/",
    makeUrl: url_PostCreateDBSubnetGroup_21626418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDBSubnetGroup_21626397 = ref object of OpenApiRestCall_21625418
proc url_GetCreateDBSubnetGroup_21626399(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDBSubnetGroup_21626398(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626400 = query.getOrDefault("Tags")
  valid_21626400 = validateParameter(valid_21626400, JArray, required = false,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "Tags", valid_21626400
  var valid_21626401 = query.getOrDefault("Action")
  valid_21626401 = validateParameter(valid_21626401, JString, required = true,
                                   default = newJString("CreateDBSubnetGroup"))
  if valid_21626401 != nil:
    section.add "Action", valid_21626401
  var valid_21626402 = query.getOrDefault("DBSubnetGroupName")
  valid_21626402 = validateParameter(valid_21626402, JString, required = true,
                                   default = nil)
  if valid_21626402 != nil:
    section.add "DBSubnetGroupName", valid_21626402
  var valid_21626403 = query.getOrDefault("SubnetIds")
  valid_21626403 = validateParameter(valid_21626403, JArray, required = true,
                                   default = nil)
  if valid_21626403 != nil:
    section.add "SubnetIds", valid_21626403
  var valid_21626404 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "DBSubnetGroupDescription", valid_21626404
  var valid_21626405 = query.getOrDefault("Version")
  valid_21626405 = validateParameter(valid_21626405, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626405 != nil:
    section.add "Version", valid_21626405
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
  var valid_21626406 = header.getOrDefault("X-Amz-Date")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Date", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Security-Token", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Algorithm", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-Signature")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-Signature", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626411
  var valid_21626412 = header.getOrDefault("X-Amz-Credential")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Credential", valid_21626412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626413: Call_GetCreateDBSubnetGroup_21626397;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626413.validator(path, query, header, formData, body, _)
  let scheme = call_21626413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626413.makeUrl(scheme.get, call_21626413.host, call_21626413.base,
                               call_21626413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626413, uri, valid, _)

proc call*(call_21626414: Call_GetCreateDBSubnetGroup_21626397;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          DBSubnetGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateDBSubnetGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateDBSubnetGroup
  ##   Tags: JArray
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626415 = newJObject()
  if Tags != nil:
    query_21626415.add "Tags", Tags
  add(query_21626415, "Action", newJString(Action))
  add(query_21626415, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21626415.add "SubnetIds", SubnetIds
  add(query_21626415, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21626415, "Version", newJString(Version))
  result = call_21626414.call(nil, query_21626415, nil, nil, nil)

var getCreateDBSubnetGroup* = Call_GetCreateDBSubnetGroup_21626397(
    name: "getCreateDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateDBSubnetGroup",
    validator: validate_GetCreateDBSubnetGroup_21626398, base: "/",
    makeUrl: url_GetCreateDBSubnetGroup_21626399,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateEventSubscription_21626458 = ref object of OpenApiRestCall_21625418
proc url_PostCreateEventSubscription_21626460(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateEventSubscription_21626459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626461 = query.getOrDefault("Action")
  valid_21626461 = validateParameter(valid_21626461, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626461 != nil:
    section.add "Action", valid_21626461
  var valid_21626462 = query.getOrDefault("Version")
  valid_21626462 = validateParameter(valid_21626462, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626462 != nil:
    section.add "Version", valid_21626462
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
  var valid_21626463 = header.getOrDefault("X-Amz-Date")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Date", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Security-Token", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Algorithm", valid_21626466
  var valid_21626467 = header.getOrDefault("X-Amz-Signature")
  valid_21626467 = validateParameter(valid_21626467, JString, required = false,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "X-Amz-Signature", valid_21626467
  var valid_21626468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Credential")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Credential", valid_21626469
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString (required)
  ##   SourceIds: JArray
  ##   Tags: JArray
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_21626470 = formData.getOrDefault("Enabled")
  valid_21626470 = validateParameter(valid_21626470, JBool, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "Enabled", valid_21626470
  var valid_21626471 = formData.getOrDefault("EventCategories")
  valid_21626471 = validateParameter(valid_21626471, JArray, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "EventCategories", valid_21626471
  assert formData != nil,
        "formData argument is necessary due to required `SnsTopicArn` field"
  var valid_21626472 = formData.getOrDefault("SnsTopicArn")
  valid_21626472 = validateParameter(valid_21626472, JString, required = true,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "SnsTopicArn", valid_21626472
  var valid_21626473 = formData.getOrDefault("SourceIds")
  valid_21626473 = validateParameter(valid_21626473, JArray, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "SourceIds", valid_21626473
  var valid_21626474 = formData.getOrDefault("Tags")
  valid_21626474 = validateParameter(valid_21626474, JArray, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "Tags", valid_21626474
  var valid_21626475 = formData.getOrDefault("SubscriptionName")
  valid_21626475 = validateParameter(valid_21626475, JString, required = true,
                                   default = nil)
  if valid_21626475 != nil:
    section.add "SubscriptionName", valid_21626475
  var valid_21626476 = formData.getOrDefault("SourceType")
  valid_21626476 = validateParameter(valid_21626476, JString, required = false,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "SourceType", valid_21626476
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626477: Call_PostCreateEventSubscription_21626458;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626477.validator(path, query, header, formData, body, _)
  let scheme = call_21626477.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626477.makeUrl(scheme.get, call_21626477.host, call_21626477.base,
                               call_21626477.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626477, uri, valid, _)

proc call*(call_21626478: Call_PostCreateEventSubscription_21626458;
          SnsTopicArn: string; SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SourceIds: JsonNode = nil;
          Tags: JsonNode = nil; Action: string = "CreateEventSubscription";
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postCreateEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string (required)
  ##   SourceIds: JArray
  ##   Tags: JArray
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21626479 = newJObject()
  var formData_21626480 = newJObject()
  add(formData_21626480, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21626480.add "EventCategories", EventCategories
  add(formData_21626480, "SnsTopicArn", newJString(SnsTopicArn))
  if SourceIds != nil:
    formData_21626480.add "SourceIds", SourceIds
  if Tags != nil:
    formData_21626480.add "Tags", Tags
  add(formData_21626480, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626479, "Action", newJString(Action))
  add(query_21626479, "Version", newJString(Version))
  add(formData_21626480, "SourceType", newJString(SourceType))
  result = call_21626478.call(nil, query_21626479, nil, formData_21626480, nil)

var postCreateEventSubscription* = Call_PostCreateEventSubscription_21626458(
    name: "postCreateEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_PostCreateEventSubscription_21626459, base: "/",
    makeUrl: url_PostCreateEventSubscription_21626460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateEventSubscription_21626436 = ref object of OpenApiRestCall_21625418
proc url_GetCreateEventSubscription_21626438(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateEventSubscription_21626437(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   SourceIds: JArray
  ##   Enabled: JBool
  ##   Tags: JArray
  ##   Action: JString (required)
  ##   SnsTopicArn: JString (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626439 = query.getOrDefault("SourceType")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "SourceType", valid_21626439
  var valid_21626440 = query.getOrDefault("SourceIds")
  valid_21626440 = validateParameter(valid_21626440, JArray, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "SourceIds", valid_21626440
  var valid_21626441 = query.getOrDefault("Enabled")
  valid_21626441 = validateParameter(valid_21626441, JBool, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "Enabled", valid_21626441
  var valid_21626442 = query.getOrDefault("Tags")
  valid_21626442 = validateParameter(valid_21626442, JArray, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "Tags", valid_21626442
  var valid_21626443 = query.getOrDefault("Action")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true, default = newJString(
      "CreateEventSubscription"))
  if valid_21626443 != nil:
    section.add "Action", valid_21626443
  var valid_21626444 = query.getOrDefault("SnsTopicArn")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true,
                                   default = nil)
  if valid_21626444 != nil:
    section.add "SnsTopicArn", valid_21626444
  var valid_21626445 = query.getOrDefault("EventCategories")
  valid_21626445 = validateParameter(valid_21626445, JArray, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "EventCategories", valid_21626445
  var valid_21626446 = query.getOrDefault("SubscriptionName")
  valid_21626446 = validateParameter(valid_21626446, JString, required = true,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "SubscriptionName", valid_21626446
  var valid_21626447 = query.getOrDefault("Version")
  valid_21626447 = validateParameter(valid_21626447, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626447 != nil:
    section.add "Version", valid_21626447
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
  var valid_21626448 = header.getOrDefault("X-Amz-Date")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Date", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Security-Token", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Algorithm", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Signature")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Signature", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Credential")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Credential", valid_21626454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626455: Call_GetCreateEventSubscription_21626436;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626455.validator(path, query, header, formData, body, _)
  let scheme = call_21626455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626455.makeUrl(scheme.get, call_21626455.host, call_21626455.base,
                               call_21626455.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626455, uri, valid, _)

proc call*(call_21626456: Call_GetCreateEventSubscription_21626436;
          SnsTopicArn: string; SubscriptionName: string; SourceType: string = "";
          SourceIds: JsonNode = nil; Enabled: bool = false; Tags: JsonNode = nil;
          Action: string = "CreateEventSubscription";
          EventCategories: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## getCreateEventSubscription
  ##   SourceType: string
  ##   SourceIds: JArray
  ##   Enabled: bool
  ##   Tags: JArray
  ##   Action: string (required)
  ##   SnsTopicArn: string (required)
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21626457 = newJObject()
  add(query_21626457, "SourceType", newJString(SourceType))
  if SourceIds != nil:
    query_21626457.add "SourceIds", SourceIds
  add(query_21626457, "Enabled", newJBool(Enabled))
  if Tags != nil:
    query_21626457.add "Tags", Tags
  add(query_21626457, "Action", newJString(Action))
  add(query_21626457, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21626457.add "EventCategories", EventCategories
  add(query_21626457, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626457, "Version", newJString(Version))
  result = call_21626456.call(nil, query_21626457, nil, nil, nil)

var getCreateEventSubscription* = Call_GetCreateEventSubscription_21626436(
    name: "getCreateEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateEventSubscription",
    validator: validate_GetCreateEventSubscription_21626437, base: "/",
    makeUrl: url_GetCreateEventSubscription_21626438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostCreateOptionGroup_21626501 = ref object of OpenApiRestCall_21625418
proc url_PostCreateOptionGroup_21626503(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateOptionGroup_21626502(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626504 = query.getOrDefault("Action")
  valid_21626504 = validateParameter(valid_21626504, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626504 != nil:
    section.add "Action", valid_21626504
  var valid_21626505 = query.getOrDefault("Version")
  valid_21626505 = validateParameter(valid_21626505, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626505 != nil:
    section.add "Version", valid_21626505
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
  var valid_21626506 = header.getOrDefault("X-Amz-Date")
  valid_21626506 = validateParameter(valid_21626506, JString, required = false,
                                   default = nil)
  if valid_21626506 != nil:
    section.add "X-Amz-Date", valid_21626506
  var valid_21626507 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626507 = validateParameter(valid_21626507, JString, required = false,
                                   default = nil)
  if valid_21626507 != nil:
    section.add "X-Amz-Security-Token", valid_21626507
  var valid_21626508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626508 = validateParameter(valid_21626508, JString, required = false,
                                   default = nil)
  if valid_21626508 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626508
  var valid_21626509 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626509 = validateParameter(valid_21626509, JString, required = false,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "X-Amz-Algorithm", valid_21626509
  var valid_21626510 = header.getOrDefault("X-Amz-Signature")
  valid_21626510 = validateParameter(valid_21626510, JString, required = false,
                                   default = nil)
  if valid_21626510 != nil:
    section.add "X-Amz-Signature", valid_21626510
  var valid_21626511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Credential")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Credential", valid_21626512
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString (required)
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   EngineName: JString (required)
  ##   OptionGroupDescription: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `MajorEngineVersion` field"
  var valid_21626513 = formData.getOrDefault("MajorEngineVersion")
  valid_21626513 = validateParameter(valid_21626513, JString, required = true,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "MajorEngineVersion", valid_21626513
  var valid_21626514 = formData.getOrDefault("OptionGroupName")
  valid_21626514 = validateParameter(valid_21626514, JString, required = true,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "OptionGroupName", valid_21626514
  var valid_21626515 = formData.getOrDefault("Tags")
  valid_21626515 = validateParameter(valid_21626515, JArray, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "Tags", valid_21626515
  var valid_21626516 = formData.getOrDefault("EngineName")
  valid_21626516 = validateParameter(valid_21626516, JString, required = true,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "EngineName", valid_21626516
  var valid_21626517 = formData.getOrDefault("OptionGroupDescription")
  valid_21626517 = validateParameter(valid_21626517, JString, required = true,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "OptionGroupDescription", valid_21626517
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626518: Call_PostCreateOptionGroup_21626501;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626518.validator(path, query, header, formData, body, _)
  let scheme = call_21626518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626518.makeUrl(scheme.get, call_21626518.host, call_21626518.base,
                               call_21626518.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626518, uri, valid, _)

proc call*(call_21626519: Call_PostCreateOptionGroup_21626501;
          MajorEngineVersion: string; OptionGroupName: string; EngineName: string;
          OptionGroupDescription: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postCreateOptionGroup
  ##   MajorEngineVersion: string (required)
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   OptionGroupDescription: string (required)
  ##   Version: string (required)
  var query_21626520 = newJObject()
  var formData_21626521 = newJObject()
  add(formData_21626521, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21626521, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21626521.add "Tags", Tags
  add(query_21626520, "Action", newJString(Action))
  add(formData_21626521, "EngineName", newJString(EngineName))
  add(formData_21626521, "OptionGroupDescription",
      newJString(OptionGroupDescription))
  add(query_21626520, "Version", newJString(Version))
  result = call_21626519.call(nil, query_21626520, nil, formData_21626521, nil)

var postCreateOptionGroup* = Call_PostCreateOptionGroup_21626501(
    name: "postCreateOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_PostCreateOptionGroup_21626502, base: "/",
    makeUrl: url_PostCreateOptionGroup_21626503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateOptionGroup_21626481 = ref object of OpenApiRestCall_21625418
proc url_GetCreateOptionGroup_21626483(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateOptionGroup_21626482(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_21626484 = query.getOrDefault("OptionGroupName")
  valid_21626484 = validateParameter(valid_21626484, JString, required = true,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "OptionGroupName", valid_21626484
  var valid_21626485 = query.getOrDefault("Tags")
  valid_21626485 = validateParameter(valid_21626485, JArray, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "Tags", valid_21626485
  var valid_21626486 = query.getOrDefault("OptionGroupDescription")
  valid_21626486 = validateParameter(valid_21626486, JString, required = true,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "OptionGroupDescription", valid_21626486
  var valid_21626487 = query.getOrDefault("Action")
  valid_21626487 = validateParameter(valid_21626487, JString, required = true,
                                   default = newJString("CreateOptionGroup"))
  if valid_21626487 != nil:
    section.add "Action", valid_21626487
  var valid_21626488 = query.getOrDefault("Version")
  valid_21626488 = validateParameter(valid_21626488, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626488 != nil:
    section.add "Version", valid_21626488
  var valid_21626489 = query.getOrDefault("EngineName")
  valid_21626489 = validateParameter(valid_21626489, JString, required = true,
                                   default = nil)
  if valid_21626489 != nil:
    section.add "EngineName", valid_21626489
  var valid_21626490 = query.getOrDefault("MajorEngineVersion")
  valid_21626490 = validateParameter(valid_21626490, JString, required = true,
                                   default = nil)
  if valid_21626490 != nil:
    section.add "MajorEngineVersion", valid_21626490
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
  var valid_21626491 = header.getOrDefault("X-Amz-Date")
  valid_21626491 = validateParameter(valid_21626491, JString, required = false,
                                   default = nil)
  if valid_21626491 != nil:
    section.add "X-Amz-Date", valid_21626491
  var valid_21626492 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626492 = validateParameter(valid_21626492, JString, required = false,
                                   default = nil)
  if valid_21626492 != nil:
    section.add "X-Amz-Security-Token", valid_21626492
  var valid_21626493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Algorithm", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Signature")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Signature", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Credential")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Credential", valid_21626497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626498: Call_GetCreateOptionGroup_21626481; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626498.validator(path, query, header, formData, body, _)
  let scheme = call_21626498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626498.makeUrl(scheme.get, call_21626498.host, call_21626498.base,
                               call_21626498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626498, uri, valid, _)

proc call*(call_21626499: Call_GetCreateOptionGroup_21626481;
          OptionGroupName: string; OptionGroupDescription: string;
          EngineName: string; MajorEngineVersion: string; Tags: JsonNode = nil;
          Action: string = "CreateOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## getCreateOptionGroup
  ##   OptionGroupName: string (required)
  ##   Tags: JArray
  ##   OptionGroupDescription: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string (required)
  var query_21626500 = newJObject()
  add(query_21626500, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    query_21626500.add "Tags", Tags
  add(query_21626500, "OptionGroupDescription", newJString(OptionGroupDescription))
  add(query_21626500, "Action", newJString(Action))
  add(query_21626500, "Version", newJString(Version))
  add(query_21626500, "EngineName", newJString(EngineName))
  add(query_21626500, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21626499.call(nil, query_21626500, nil, nil, nil)

var getCreateOptionGroup* = Call_GetCreateOptionGroup_21626481(
    name: "getCreateOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=CreateOptionGroup",
    validator: validate_GetCreateOptionGroup_21626482, base: "/",
    makeUrl: url_GetCreateOptionGroup_21626483,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBInstance_21626540 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBInstance_21626542(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBInstance_21626541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626543 = query.getOrDefault("Action")
  valid_21626543 = validateParameter(valid_21626543, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626543 != nil:
    section.add "Action", valid_21626543
  var valid_21626544 = query.getOrDefault("Version")
  valid_21626544 = validateParameter(valid_21626544, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626544 != nil:
    section.add "Version", valid_21626544
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
  var valid_21626545 = header.getOrDefault("X-Amz-Date")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Date", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Security-Token", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Algorithm", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-Signature")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-Signature", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626550
  var valid_21626551 = header.getOrDefault("X-Amz-Credential")
  valid_21626551 = validateParameter(valid_21626551, JString, required = false,
                                   default = nil)
  if valid_21626551 != nil:
    section.add "X-Amz-Credential", valid_21626551
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   FinalDBSnapshotIdentifier: JString
  ##   SkipFinalSnapshot: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626552 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626552 = validateParameter(valid_21626552, JString, required = true,
                                   default = nil)
  if valid_21626552 != nil:
    section.add "DBInstanceIdentifier", valid_21626552
  var valid_21626553 = formData.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626553 = validateParameter(valid_21626553, JString, required = false,
                                   default = nil)
  if valid_21626553 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626553
  var valid_21626554 = formData.getOrDefault("SkipFinalSnapshot")
  valid_21626554 = validateParameter(valid_21626554, JBool, required = false,
                                   default = nil)
  if valid_21626554 != nil:
    section.add "SkipFinalSnapshot", valid_21626554
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626555: Call_PostDeleteDBInstance_21626540; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626555.validator(path, query, header, formData, body, _)
  let scheme = call_21626555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626555.makeUrl(scheme.get, call_21626555.host, call_21626555.base,
                               call_21626555.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626555, uri, valid, _)

proc call*(call_21626556: Call_PostDeleteDBInstance_21626540;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; Version: string = "2013-09-09";
          SkipFinalSnapshot: bool = false): Recallable =
  ## postDeleteDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SkipFinalSnapshot: bool
  var query_21626557 = newJObject()
  var formData_21626558 = newJObject()
  add(formData_21626558, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626558, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626557, "Action", newJString(Action))
  add(query_21626557, "Version", newJString(Version))
  add(formData_21626558, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  result = call_21626556.call(nil, query_21626557, nil, formData_21626558, nil)

var postDeleteDBInstance* = Call_PostDeleteDBInstance_21626540(
    name: "postDeleteDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_PostDeleteDBInstance_21626541, base: "/",
    makeUrl: url_PostDeleteDBInstance_21626542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBInstance_21626522 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBInstance_21626524(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBInstance_21626523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FinalDBSnapshotIdentifier: JString
  ##   Action: JString (required)
  ##   SkipFinalSnapshot: JBool
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_21626525 = query.getOrDefault("FinalDBSnapshotIdentifier")
  valid_21626525 = validateParameter(valid_21626525, JString, required = false,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "FinalDBSnapshotIdentifier", valid_21626525
  var valid_21626526 = query.getOrDefault("Action")
  valid_21626526 = validateParameter(valid_21626526, JString, required = true,
                                   default = newJString("DeleteDBInstance"))
  if valid_21626526 != nil:
    section.add "Action", valid_21626526
  var valid_21626527 = query.getOrDefault("SkipFinalSnapshot")
  valid_21626527 = validateParameter(valid_21626527, JBool, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "SkipFinalSnapshot", valid_21626527
  var valid_21626528 = query.getOrDefault("Version")
  valid_21626528 = validateParameter(valid_21626528, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626528 != nil:
    section.add "Version", valid_21626528
  var valid_21626529 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626529 = validateParameter(valid_21626529, JString, required = true,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "DBInstanceIdentifier", valid_21626529
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
  var valid_21626530 = header.getOrDefault("X-Amz-Date")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Date", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Security-Token", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Algorithm", valid_21626533
  var valid_21626534 = header.getOrDefault("X-Amz-Signature")
  valid_21626534 = validateParameter(valid_21626534, JString, required = false,
                                   default = nil)
  if valid_21626534 != nil:
    section.add "X-Amz-Signature", valid_21626534
  var valid_21626535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626535 = validateParameter(valid_21626535, JString, required = false,
                                   default = nil)
  if valid_21626535 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626535
  var valid_21626536 = header.getOrDefault("X-Amz-Credential")
  valid_21626536 = validateParameter(valid_21626536, JString, required = false,
                                   default = nil)
  if valid_21626536 != nil:
    section.add "X-Amz-Credential", valid_21626536
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626537: Call_GetDeleteDBInstance_21626522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626537.validator(path, query, header, formData, body, _)
  let scheme = call_21626537.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626537.makeUrl(scheme.get, call_21626537.host, call_21626537.base,
                               call_21626537.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626537, uri, valid, _)

proc call*(call_21626538: Call_GetDeleteDBInstance_21626522;
          DBInstanceIdentifier: string; FinalDBSnapshotIdentifier: string = "";
          Action: string = "DeleteDBInstance"; SkipFinalSnapshot: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBInstance
  ##   FinalDBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   SkipFinalSnapshot: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626539 = newJObject()
  add(query_21626539, "FinalDBSnapshotIdentifier",
      newJString(FinalDBSnapshotIdentifier))
  add(query_21626539, "Action", newJString(Action))
  add(query_21626539, "SkipFinalSnapshot", newJBool(SkipFinalSnapshot))
  add(query_21626539, "Version", newJString(Version))
  add(query_21626539, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626538.call(nil, query_21626539, nil, nil, nil)

var getDeleteDBInstance* = Call_GetDeleteDBInstance_21626522(
    name: "getDeleteDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBInstance",
    validator: validate_GetDeleteDBInstance_21626523, base: "/",
    makeUrl: url_GetDeleteDBInstance_21626524,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBParameterGroup_21626575 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBParameterGroup_21626577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBParameterGroup_21626576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626578 = query.getOrDefault("Action")
  valid_21626578 = validateParameter(valid_21626578, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626578 != nil:
    section.add "Action", valid_21626578
  var valid_21626579 = query.getOrDefault("Version")
  valid_21626579 = validateParameter(valid_21626579, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626579 != nil:
    section.add "Version", valid_21626579
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
  var valid_21626580 = header.getOrDefault("X-Amz-Date")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Date", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Security-Token", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-Algorithm", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Signature")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Signature", valid_21626584
  var valid_21626585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626585
  var valid_21626586 = header.getOrDefault("X-Amz-Credential")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "X-Amz-Credential", valid_21626586
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626587 = formData.getOrDefault("DBParameterGroupName")
  valid_21626587 = validateParameter(valid_21626587, JString, required = true,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "DBParameterGroupName", valid_21626587
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626588: Call_PostDeleteDBParameterGroup_21626575;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626588.validator(path, query, header, formData, body, _)
  let scheme = call_21626588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626588.makeUrl(scheme.get, call_21626588.host, call_21626588.base,
                               call_21626588.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626588, uri, valid, _)

proc call*(call_21626589: Call_PostDeleteDBParameterGroup_21626575;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626590 = newJObject()
  var formData_21626591 = newJObject()
  add(formData_21626591, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626590, "Action", newJString(Action))
  add(query_21626590, "Version", newJString(Version))
  result = call_21626589.call(nil, query_21626590, nil, formData_21626591, nil)

var postDeleteDBParameterGroup* = Call_PostDeleteDBParameterGroup_21626575(
    name: "postDeleteDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_PostDeleteDBParameterGroup_21626576, base: "/",
    makeUrl: url_PostDeleteDBParameterGroup_21626577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBParameterGroup_21626559 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBParameterGroup_21626561(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBParameterGroup_21626560(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626562 = query.getOrDefault("DBParameterGroupName")
  valid_21626562 = validateParameter(valid_21626562, JString, required = true,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "DBParameterGroupName", valid_21626562
  var valid_21626563 = query.getOrDefault("Action")
  valid_21626563 = validateParameter(valid_21626563, JString, required = true, default = newJString(
      "DeleteDBParameterGroup"))
  if valid_21626563 != nil:
    section.add "Action", valid_21626563
  var valid_21626564 = query.getOrDefault("Version")
  valid_21626564 = validateParameter(valid_21626564, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626564 != nil:
    section.add "Version", valid_21626564
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
  var valid_21626565 = header.getOrDefault("X-Amz-Date")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Date", valid_21626565
  var valid_21626566 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "X-Amz-Security-Token", valid_21626566
  var valid_21626567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626567
  var valid_21626568 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "X-Amz-Algorithm", valid_21626568
  var valid_21626569 = header.getOrDefault("X-Amz-Signature")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Signature", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Credential")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Credential", valid_21626571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626572: Call_GetDeleteDBParameterGroup_21626559;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626572.validator(path, query, header, formData, body, _)
  let scheme = call_21626572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626572.makeUrl(scheme.get, call_21626572.host, call_21626572.base,
                               call_21626572.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626572, uri, valid, _)

proc call*(call_21626573: Call_GetDeleteDBParameterGroup_21626559;
          DBParameterGroupName: string; Action: string = "DeleteDBParameterGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626574 = newJObject()
  add(query_21626574, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626574, "Action", newJString(Action))
  add(query_21626574, "Version", newJString(Version))
  result = call_21626573.call(nil, query_21626574, nil, nil, nil)

var getDeleteDBParameterGroup* = Call_GetDeleteDBParameterGroup_21626559(
    name: "getDeleteDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBParameterGroup",
    validator: validate_GetDeleteDBParameterGroup_21626560, base: "/",
    makeUrl: url_GetDeleteDBParameterGroup_21626561,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSecurityGroup_21626608 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSecurityGroup_21626610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSecurityGroup_21626609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626611 = query.getOrDefault("Action")
  valid_21626611 = validateParameter(valid_21626611, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626611 != nil:
    section.add "Action", valid_21626611
  var valid_21626612 = query.getOrDefault("Version")
  valid_21626612 = validateParameter(valid_21626612, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626612 != nil:
    section.add "Version", valid_21626612
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
  var valid_21626613 = header.getOrDefault("X-Amz-Date")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Date", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Security-Token", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Algorithm", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Signature")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Signature", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Credential")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Credential", valid_21626619
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626620 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626620 = validateParameter(valid_21626620, JString, required = true,
                                   default = nil)
  if valid_21626620 != nil:
    section.add "DBSecurityGroupName", valid_21626620
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626621: Call_PostDeleteDBSecurityGroup_21626608;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626621.validator(path, query, header, formData, body, _)
  let scheme = call_21626621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626621.makeUrl(scheme.get, call_21626621.host, call_21626621.base,
                               call_21626621.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626621, uri, valid, _)

proc call*(call_21626622: Call_PostDeleteDBSecurityGroup_21626608;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626623 = newJObject()
  var formData_21626624 = newJObject()
  add(formData_21626624, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626623, "Action", newJString(Action))
  add(query_21626623, "Version", newJString(Version))
  result = call_21626622.call(nil, query_21626623, nil, formData_21626624, nil)

var postDeleteDBSecurityGroup* = Call_PostDeleteDBSecurityGroup_21626608(
    name: "postDeleteDBSecurityGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_PostDeleteDBSecurityGroup_21626609, base: "/",
    makeUrl: url_PostDeleteDBSecurityGroup_21626610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSecurityGroup_21626592 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSecurityGroup_21626594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSecurityGroup_21626593(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21626595 = query.getOrDefault("DBSecurityGroupName")
  valid_21626595 = validateParameter(valid_21626595, JString, required = true,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "DBSecurityGroupName", valid_21626595
  var valid_21626596 = query.getOrDefault("Action")
  valid_21626596 = validateParameter(valid_21626596, JString, required = true, default = newJString(
      "DeleteDBSecurityGroup"))
  if valid_21626596 != nil:
    section.add "Action", valid_21626596
  var valid_21626597 = query.getOrDefault("Version")
  valid_21626597 = validateParameter(valid_21626597, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626597 != nil:
    section.add "Version", valid_21626597
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
  var valid_21626598 = header.getOrDefault("X-Amz-Date")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Date", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Security-Token", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626600
  var valid_21626601 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626601 = validateParameter(valid_21626601, JString, required = false,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "X-Amz-Algorithm", valid_21626601
  var valid_21626602 = header.getOrDefault("X-Amz-Signature")
  valid_21626602 = validateParameter(valid_21626602, JString, required = false,
                                   default = nil)
  if valid_21626602 != nil:
    section.add "X-Amz-Signature", valid_21626602
  var valid_21626603 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626603 = validateParameter(valid_21626603, JString, required = false,
                                   default = nil)
  if valid_21626603 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626603
  var valid_21626604 = header.getOrDefault("X-Amz-Credential")
  valid_21626604 = validateParameter(valid_21626604, JString, required = false,
                                   default = nil)
  if valid_21626604 != nil:
    section.add "X-Amz-Credential", valid_21626604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626605: Call_GetDeleteDBSecurityGroup_21626592;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626605.validator(path, query, header, formData, body, _)
  let scheme = call_21626605.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626605.makeUrl(scheme.get, call_21626605.host, call_21626605.base,
                               call_21626605.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626605, uri, valid, _)

proc call*(call_21626606: Call_GetDeleteDBSecurityGroup_21626592;
          DBSecurityGroupName: string; Action: string = "DeleteDBSecurityGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSecurityGroup
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626607 = newJObject()
  add(query_21626607, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21626607, "Action", newJString(Action))
  add(query_21626607, "Version", newJString(Version))
  result = call_21626606.call(nil, query_21626607, nil, nil, nil)

var getDeleteDBSecurityGroup* = Call_GetDeleteDBSecurityGroup_21626592(
    name: "getDeleteDBSecurityGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSecurityGroup",
    validator: validate_GetDeleteDBSecurityGroup_21626593, base: "/",
    makeUrl: url_GetDeleteDBSecurityGroup_21626594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSnapshot_21626641 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSnapshot_21626643(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSnapshot_21626642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626644 = query.getOrDefault("Action")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626644 != nil:
    section.add "Action", valid_21626644
  var valid_21626645 = query.getOrDefault("Version")
  valid_21626645 = validateParameter(valid_21626645, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626645 != nil:
    section.add "Version", valid_21626645
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
  var valid_21626646 = header.getOrDefault("X-Amz-Date")
  valid_21626646 = validateParameter(valid_21626646, JString, required = false,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "X-Amz-Date", valid_21626646
  var valid_21626647 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626647 = validateParameter(valid_21626647, JString, required = false,
                                   default = nil)
  if valid_21626647 != nil:
    section.add "X-Amz-Security-Token", valid_21626647
  var valid_21626648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Algorithm", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Signature")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Signature", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Credential")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Credential", valid_21626652
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSnapshotIdentifier` field"
  var valid_21626653 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21626653 = validateParameter(valid_21626653, JString, required = true,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "DBSnapshotIdentifier", valid_21626653
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626654: Call_PostDeleteDBSnapshot_21626641; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626654.validator(path, query, header, formData, body, _)
  let scheme = call_21626654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626654.makeUrl(scheme.get, call_21626654.host, call_21626654.base,
                               call_21626654.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626654, uri, valid, _)

proc call*(call_21626655: Call_PostDeleteDBSnapshot_21626641;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSnapshot
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626656 = newJObject()
  var formData_21626657 = newJObject()
  add(formData_21626657, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21626656, "Action", newJString(Action))
  add(query_21626656, "Version", newJString(Version))
  result = call_21626655.call(nil, query_21626656, nil, formData_21626657, nil)

var postDeleteDBSnapshot* = Call_PostDeleteDBSnapshot_21626641(
    name: "postDeleteDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_PostDeleteDBSnapshot_21626642, base: "/",
    makeUrl: url_PostDeleteDBSnapshot_21626643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSnapshot_21626625 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSnapshot_21626627(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSnapshot_21626626(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_21626628 = query.getOrDefault("Action")
  valid_21626628 = validateParameter(valid_21626628, JString, required = true,
                                   default = newJString("DeleteDBSnapshot"))
  if valid_21626628 != nil:
    section.add "Action", valid_21626628
  var valid_21626629 = query.getOrDefault("Version")
  valid_21626629 = validateParameter(valid_21626629, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626629 != nil:
    section.add "Version", valid_21626629
  var valid_21626630 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21626630 = validateParameter(valid_21626630, JString, required = true,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "DBSnapshotIdentifier", valid_21626630
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
  var valid_21626631 = header.getOrDefault("X-Amz-Date")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Date", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Security-Token", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Algorithm", valid_21626634
  var valid_21626635 = header.getOrDefault("X-Amz-Signature")
  valid_21626635 = validateParameter(valid_21626635, JString, required = false,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "X-Amz-Signature", valid_21626635
  var valid_21626636 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626636 = validateParameter(valid_21626636, JString, required = false,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626636
  var valid_21626637 = header.getOrDefault("X-Amz-Credential")
  valid_21626637 = validateParameter(valid_21626637, JString, required = false,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "X-Amz-Credential", valid_21626637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626638: Call_GetDeleteDBSnapshot_21626625; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626638.validator(path, query, header, formData, body, _)
  let scheme = call_21626638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626638.makeUrl(scheme.get, call_21626638.host, call_21626638.base,
                               call_21626638.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626638, uri, valid, _)

proc call*(call_21626639: Call_GetDeleteDBSnapshot_21626625;
          DBSnapshotIdentifier: string; Action: string = "DeleteDBSnapshot";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSnapshot
  ##   Action: string (required)
  ##   Version: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21626640 = newJObject()
  add(query_21626640, "Action", newJString(Action))
  add(query_21626640, "Version", newJString(Version))
  add(query_21626640, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21626639.call(nil, query_21626640, nil, nil, nil)

var getDeleteDBSnapshot* = Call_GetDeleteDBSnapshot_21626625(
    name: "getDeleteDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSnapshot",
    validator: validate_GetDeleteDBSnapshot_21626626, base: "/",
    makeUrl: url_GetDeleteDBSnapshot_21626627,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDBSubnetGroup_21626674 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteDBSubnetGroup_21626676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDBSubnetGroup_21626675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626677 = query.getOrDefault("Action")
  valid_21626677 = validateParameter(valid_21626677, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626677 != nil:
    section.add "Action", valid_21626677
  var valid_21626678 = query.getOrDefault("Version")
  valid_21626678 = validateParameter(valid_21626678, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626678 != nil:
    section.add "Version", valid_21626678
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
  var valid_21626679 = header.getOrDefault("X-Amz-Date")
  valid_21626679 = validateParameter(valid_21626679, JString, required = false,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "X-Amz-Date", valid_21626679
  var valid_21626680 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Security-Token", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Algorithm", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Signature")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Signature", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Credential")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Credential", valid_21626685
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21626686 = formData.getOrDefault("DBSubnetGroupName")
  valid_21626686 = validateParameter(valid_21626686, JString, required = true,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "DBSubnetGroupName", valid_21626686
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626687: Call_PostDeleteDBSubnetGroup_21626674;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626687.validator(path, query, header, formData, body, _)
  let scheme = call_21626687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626687.makeUrl(scheme.get, call_21626687.host, call_21626687.base,
                               call_21626687.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626687, uri, valid, _)

proc call*(call_21626688: Call_PostDeleteDBSubnetGroup_21626674;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626689 = newJObject()
  var formData_21626690 = newJObject()
  add(formData_21626690, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626689, "Action", newJString(Action))
  add(query_21626689, "Version", newJString(Version))
  result = call_21626688.call(nil, query_21626689, nil, formData_21626690, nil)

var postDeleteDBSubnetGroup* = Call_PostDeleteDBSubnetGroup_21626674(
    name: "postDeleteDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_PostDeleteDBSubnetGroup_21626675, base: "/",
    makeUrl: url_PostDeleteDBSubnetGroup_21626676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDBSubnetGroup_21626658 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteDBSubnetGroup_21626660(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDBSubnetGroup_21626659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626661 = query.getOrDefault("Action")
  valid_21626661 = validateParameter(valid_21626661, JString, required = true,
                                   default = newJString("DeleteDBSubnetGroup"))
  if valid_21626661 != nil:
    section.add "Action", valid_21626661
  var valid_21626662 = query.getOrDefault("DBSubnetGroupName")
  valid_21626662 = validateParameter(valid_21626662, JString, required = true,
                                   default = nil)
  if valid_21626662 != nil:
    section.add "DBSubnetGroupName", valid_21626662
  var valid_21626663 = query.getOrDefault("Version")
  valid_21626663 = validateParameter(valid_21626663, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626663 != nil:
    section.add "Version", valid_21626663
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
  var valid_21626664 = header.getOrDefault("X-Amz-Date")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Date", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Security-Token", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Algorithm", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Signature")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Signature", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Credential")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Credential", valid_21626670
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626671: Call_GetDeleteDBSubnetGroup_21626658;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626671.validator(path, query, header, formData, body, _)
  let scheme = call_21626671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626671.makeUrl(scheme.get, call_21626671.host, call_21626671.base,
                               call_21626671.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626671, uri, valid, _)

proc call*(call_21626672: Call_GetDeleteDBSubnetGroup_21626658;
          DBSubnetGroupName: string; Action: string = "DeleteDBSubnetGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   Version: string (required)
  var query_21626673 = newJObject()
  add(query_21626673, "Action", newJString(Action))
  add(query_21626673, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21626673, "Version", newJString(Version))
  result = call_21626672.call(nil, query_21626673, nil, nil, nil)

var getDeleteDBSubnetGroup* = Call_GetDeleteDBSubnetGroup_21626658(
    name: "getDeleteDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteDBSubnetGroup",
    validator: validate_GetDeleteDBSubnetGroup_21626659, base: "/",
    makeUrl: url_GetDeleteDBSubnetGroup_21626660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteEventSubscription_21626707 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteEventSubscription_21626709(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteEventSubscription_21626708(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626710 = query.getOrDefault("Action")
  valid_21626710 = validateParameter(valid_21626710, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626710 != nil:
    section.add "Action", valid_21626710
  var valid_21626711 = query.getOrDefault("Version")
  valid_21626711 = validateParameter(valid_21626711, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626711 != nil:
    section.add "Version", valid_21626711
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
  var valid_21626712 = header.getOrDefault("X-Amz-Date")
  valid_21626712 = validateParameter(valid_21626712, JString, required = false,
                                   default = nil)
  if valid_21626712 != nil:
    section.add "X-Amz-Date", valid_21626712
  var valid_21626713 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626713 = validateParameter(valid_21626713, JString, required = false,
                                   default = nil)
  if valid_21626713 != nil:
    section.add "X-Amz-Security-Token", valid_21626713
  var valid_21626714 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626714 = validateParameter(valid_21626714, JString, required = false,
                                   default = nil)
  if valid_21626714 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626714
  var valid_21626715 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626715 = validateParameter(valid_21626715, JString, required = false,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "X-Amz-Algorithm", valid_21626715
  var valid_21626716 = header.getOrDefault("X-Amz-Signature")
  valid_21626716 = validateParameter(valid_21626716, JString, required = false,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "X-Amz-Signature", valid_21626716
  var valid_21626717 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626717 = validateParameter(valid_21626717, JString, required = false,
                                   default = nil)
  if valid_21626717 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626717
  var valid_21626718 = header.getOrDefault("X-Amz-Credential")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Credential", valid_21626718
  result.add "header", section
  ## parameters in `formData` object:
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21626719 = formData.getOrDefault("SubscriptionName")
  valid_21626719 = validateParameter(valid_21626719, JString, required = true,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "SubscriptionName", valid_21626719
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626720: Call_PostDeleteEventSubscription_21626707;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626720.validator(path, query, header, formData, body, _)
  let scheme = call_21626720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626720.makeUrl(scheme.get, call_21626720.host, call_21626720.base,
                               call_21626720.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626720, uri, valid, _)

proc call*(call_21626721: Call_PostDeleteEventSubscription_21626707;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteEventSubscription
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626722 = newJObject()
  var formData_21626723 = newJObject()
  add(formData_21626723, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626722, "Action", newJString(Action))
  add(query_21626722, "Version", newJString(Version))
  result = call_21626721.call(nil, query_21626722, nil, formData_21626723, nil)

var postDeleteEventSubscription* = Call_PostDeleteEventSubscription_21626707(
    name: "postDeleteEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_PostDeleteEventSubscription_21626708, base: "/",
    makeUrl: url_PostDeleteEventSubscription_21626709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteEventSubscription_21626691 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteEventSubscription_21626693(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteEventSubscription_21626692(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626694 = query.getOrDefault("Action")
  valid_21626694 = validateParameter(valid_21626694, JString, required = true, default = newJString(
      "DeleteEventSubscription"))
  if valid_21626694 != nil:
    section.add "Action", valid_21626694
  var valid_21626695 = query.getOrDefault("SubscriptionName")
  valid_21626695 = validateParameter(valid_21626695, JString, required = true,
                                   default = nil)
  if valid_21626695 != nil:
    section.add "SubscriptionName", valid_21626695
  var valid_21626696 = query.getOrDefault("Version")
  valid_21626696 = validateParameter(valid_21626696, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626696 != nil:
    section.add "Version", valid_21626696
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
  var valid_21626697 = header.getOrDefault("X-Amz-Date")
  valid_21626697 = validateParameter(valid_21626697, JString, required = false,
                                   default = nil)
  if valid_21626697 != nil:
    section.add "X-Amz-Date", valid_21626697
  var valid_21626698 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Security-Token", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Algorithm", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Signature")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Signature", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-Credential")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-Credential", valid_21626703
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626704: Call_GetDeleteEventSubscription_21626691;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626704.validator(path, query, header, formData, body, _)
  let scheme = call_21626704.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626704.makeUrl(scheme.get, call_21626704.host, call_21626704.base,
                               call_21626704.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626704, uri, valid, _)

proc call*(call_21626705: Call_GetDeleteEventSubscription_21626691;
          SubscriptionName: string; Action: string = "DeleteEventSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteEventSubscription
  ##   Action: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21626706 = newJObject()
  add(query_21626706, "Action", newJString(Action))
  add(query_21626706, "SubscriptionName", newJString(SubscriptionName))
  add(query_21626706, "Version", newJString(Version))
  result = call_21626705.call(nil, query_21626706, nil, nil, nil)

var getDeleteEventSubscription* = Call_GetDeleteEventSubscription_21626691(
    name: "getDeleteEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteEventSubscription",
    validator: validate_GetDeleteEventSubscription_21626692, base: "/",
    makeUrl: url_GetDeleteEventSubscription_21626693,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteOptionGroup_21626740 = ref object of OpenApiRestCall_21625418
proc url_PostDeleteOptionGroup_21626742(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteOptionGroup_21626741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626743 = query.getOrDefault("Action")
  valid_21626743 = validateParameter(valid_21626743, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626743 != nil:
    section.add "Action", valid_21626743
  var valid_21626744 = query.getOrDefault("Version")
  valid_21626744 = validateParameter(valid_21626744, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626744 != nil:
    section.add "Version", valid_21626744
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
  var valid_21626745 = header.getOrDefault("X-Amz-Date")
  valid_21626745 = validateParameter(valid_21626745, JString, required = false,
                                   default = nil)
  if valid_21626745 != nil:
    section.add "X-Amz-Date", valid_21626745
  var valid_21626746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626746 = validateParameter(valid_21626746, JString, required = false,
                                   default = nil)
  if valid_21626746 != nil:
    section.add "X-Amz-Security-Token", valid_21626746
  var valid_21626747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626747 = validateParameter(valid_21626747, JString, required = false,
                                   default = nil)
  if valid_21626747 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626747
  var valid_21626748 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626748 = validateParameter(valid_21626748, JString, required = false,
                                   default = nil)
  if valid_21626748 != nil:
    section.add "X-Amz-Algorithm", valid_21626748
  var valid_21626749 = header.getOrDefault("X-Amz-Signature")
  valid_21626749 = validateParameter(valid_21626749, JString, required = false,
                                   default = nil)
  if valid_21626749 != nil:
    section.add "X-Amz-Signature", valid_21626749
  var valid_21626750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626750 = validateParameter(valid_21626750, JString, required = false,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626750
  var valid_21626751 = header.getOrDefault("X-Amz-Credential")
  valid_21626751 = validateParameter(valid_21626751, JString, required = false,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "X-Amz-Credential", valid_21626751
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionGroupName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21626752 = formData.getOrDefault("OptionGroupName")
  valid_21626752 = validateParameter(valid_21626752, JString, required = true,
                                   default = nil)
  if valid_21626752 != nil:
    section.add "OptionGroupName", valid_21626752
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626753: Call_PostDeleteOptionGroup_21626740;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626753.validator(path, query, header, formData, body, _)
  let scheme = call_21626753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626753.makeUrl(scheme.get, call_21626753.host, call_21626753.base,
                               call_21626753.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626753, uri, valid, _)

proc call*(call_21626754: Call_PostDeleteOptionGroup_21626740;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## postDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626755 = newJObject()
  var formData_21626756 = newJObject()
  add(formData_21626756, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626755, "Action", newJString(Action))
  add(query_21626755, "Version", newJString(Version))
  result = call_21626754.call(nil, query_21626755, nil, formData_21626756, nil)

var postDeleteOptionGroup* = Call_PostDeleteOptionGroup_21626740(
    name: "postDeleteOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_PostDeleteOptionGroup_21626741, base: "/",
    makeUrl: url_PostDeleteOptionGroup_21626742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteOptionGroup_21626724 = ref object of OpenApiRestCall_21625418
proc url_GetDeleteOptionGroup_21626726(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteOptionGroup_21626725(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_21626727 = query.getOrDefault("OptionGroupName")
  valid_21626727 = validateParameter(valid_21626727, JString, required = true,
                                   default = nil)
  if valid_21626727 != nil:
    section.add "OptionGroupName", valid_21626727
  var valid_21626728 = query.getOrDefault("Action")
  valid_21626728 = validateParameter(valid_21626728, JString, required = true,
                                   default = newJString("DeleteOptionGroup"))
  if valid_21626728 != nil:
    section.add "Action", valid_21626728
  var valid_21626729 = query.getOrDefault("Version")
  valid_21626729 = validateParameter(valid_21626729, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626729 != nil:
    section.add "Version", valid_21626729
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
  var valid_21626730 = header.getOrDefault("X-Amz-Date")
  valid_21626730 = validateParameter(valid_21626730, JString, required = false,
                                   default = nil)
  if valid_21626730 != nil:
    section.add "X-Amz-Date", valid_21626730
  var valid_21626731 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626731 = validateParameter(valid_21626731, JString, required = false,
                                   default = nil)
  if valid_21626731 != nil:
    section.add "X-Amz-Security-Token", valid_21626731
  var valid_21626732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626732 = validateParameter(valid_21626732, JString, required = false,
                                   default = nil)
  if valid_21626732 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626732
  var valid_21626733 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Algorithm", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Signature")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Signature", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Credential")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Credential", valid_21626736
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626737: Call_GetDeleteOptionGroup_21626724; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626737.validator(path, query, header, formData, body, _)
  let scheme = call_21626737.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626737.makeUrl(scheme.get, call_21626737.host, call_21626737.base,
                               call_21626737.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626737, uri, valid, _)

proc call*(call_21626738: Call_GetDeleteOptionGroup_21626724;
          OptionGroupName: string; Action: string = "DeleteOptionGroup";
          Version: string = "2013-09-09"): Recallable =
  ## getDeleteOptionGroup
  ##   OptionGroupName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626739 = newJObject()
  add(query_21626739, "OptionGroupName", newJString(OptionGroupName))
  add(query_21626739, "Action", newJString(Action))
  add(query_21626739, "Version", newJString(Version))
  result = call_21626738.call(nil, query_21626739, nil, nil, nil)

var getDeleteOptionGroup* = Call_GetDeleteOptionGroup_21626724(
    name: "getDeleteOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DeleteOptionGroup",
    validator: validate_GetDeleteOptionGroup_21626725, base: "/",
    makeUrl: url_GetDeleteOptionGroup_21626726,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBEngineVersions_21626780 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBEngineVersions_21626782(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBEngineVersions_21626781(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626783 = query.getOrDefault("Action")
  valid_21626783 = validateParameter(valid_21626783, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626783 != nil:
    section.add "Action", valid_21626783
  var valid_21626784 = query.getOrDefault("Version")
  valid_21626784 = validateParameter(valid_21626784, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626784 != nil:
    section.add "Version", valid_21626784
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
  var valid_21626785 = header.getOrDefault("X-Amz-Date")
  valid_21626785 = validateParameter(valid_21626785, JString, required = false,
                                   default = nil)
  if valid_21626785 != nil:
    section.add "X-Amz-Date", valid_21626785
  var valid_21626786 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626786 = validateParameter(valid_21626786, JString, required = false,
                                   default = nil)
  if valid_21626786 != nil:
    section.add "X-Amz-Security-Token", valid_21626786
  var valid_21626787 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626787 = validateParameter(valid_21626787, JString, required = false,
                                   default = nil)
  if valid_21626787 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626787
  var valid_21626788 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626788 = validateParameter(valid_21626788, JString, required = false,
                                   default = nil)
  if valid_21626788 != nil:
    section.add "X-Amz-Algorithm", valid_21626788
  var valid_21626789 = header.getOrDefault("X-Amz-Signature")
  valid_21626789 = validateParameter(valid_21626789, JString, required = false,
                                   default = nil)
  if valid_21626789 != nil:
    section.add "X-Amz-Signature", valid_21626789
  var valid_21626790 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626790 = validateParameter(valid_21626790, JString, required = false,
                                   default = nil)
  if valid_21626790 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626790
  var valid_21626791 = header.getOrDefault("X-Amz-Credential")
  valid_21626791 = validateParameter(valid_21626791, JString, required = false,
                                   default = nil)
  if valid_21626791 != nil:
    section.add "X-Amz-Credential", valid_21626791
  result.add "header", section
  ## parameters in `formData` object:
  ##   ListSupportedCharacterSets: JBool
  ##   Engine: JString
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  section = newJObject()
  var valid_21626792 = formData.getOrDefault("ListSupportedCharacterSets")
  valid_21626792 = validateParameter(valid_21626792, JBool, required = false,
                                   default = nil)
  if valid_21626792 != nil:
    section.add "ListSupportedCharacterSets", valid_21626792
  var valid_21626793 = formData.getOrDefault("Engine")
  valid_21626793 = validateParameter(valid_21626793, JString, required = false,
                                   default = nil)
  if valid_21626793 != nil:
    section.add "Engine", valid_21626793
  var valid_21626794 = formData.getOrDefault("Marker")
  valid_21626794 = validateParameter(valid_21626794, JString, required = false,
                                   default = nil)
  if valid_21626794 != nil:
    section.add "Marker", valid_21626794
  var valid_21626795 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21626795 = validateParameter(valid_21626795, JString, required = false,
                                   default = nil)
  if valid_21626795 != nil:
    section.add "DBParameterGroupFamily", valid_21626795
  var valid_21626796 = formData.getOrDefault("Filters")
  valid_21626796 = validateParameter(valid_21626796, JArray, required = false,
                                   default = nil)
  if valid_21626796 != nil:
    section.add "Filters", valid_21626796
  var valid_21626797 = formData.getOrDefault("MaxRecords")
  valid_21626797 = validateParameter(valid_21626797, JInt, required = false,
                                   default = nil)
  if valid_21626797 != nil:
    section.add "MaxRecords", valid_21626797
  var valid_21626798 = formData.getOrDefault("EngineVersion")
  valid_21626798 = validateParameter(valid_21626798, JString, required = false,
                                   default = nil)
  if valid_21626798 != nil:
    section.add "EngineVersion", valid_21626798
  var valid_21626799 = formData.getOrDefault("DefaultOnly")
  valid_21626799 = validateParameter(valid_21626799, JBool, required = false,
                                   default = nil)
  if valid_21626799 != nil:
    section.add "DefaultOnly", valid_21626799
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626800: Call_PostDescribeDBEngineVersions_21626780;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626800.validator(path, query, header, formData, body, _)
  let scheme = call_21626800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626800.makeUrl(scheme.get, call_21626800.host, call_21626800.base,
                               call_21626800.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626800, uri, valid, _)

proc call*(call_21626801: Call_PostDescribeDBEngineVersions_21626780;
          ListSupportedCharacterSets: bool = false; Engine: string = "";
          Marker: string = ""; Action: string = "DescribeDBEngineVersions";
          DBParameterGroupFamily: string = ""; Filters: JsonNode = nil;
          MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2013-09-09"; DefaultOnly: bool = false): Recallable =
  ## postDescribeDBEngineVersions
  ##   ListSupportedCharacterSets: bool
  ##   Engine: string
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   DefaultOnly: bool
  var query_21626802 = newJObject()
  var formData_21626803 = newJObject()
  add(formData_21626803, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(formData_21626803, "Engine", newJString(Engine))
  add(formData_21626803, "Marker", newJString(Marker))
  add(query_21626802, "Action", newJString(Action))
  add(formData_21626803, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21626803.add "Filters", Filters
  add(formData_21626803, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626803, "EngineVersion", newJString(EngineVersion))
  add(query_21626802, "Version", newJString(Version))
  add(formData_21626803, "DefaultOnly", newJBool(DefaultOnly))
  result = call_21626801.call(nil, query_21626802, nil, formData_21626803, nil)

var postDescribeDBEngineVersions* = Call_PostDescribeDBEngineVersions_21626780(
    name: "postDescribeDBEngineVersions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_PostDescribeDBEngineVersions_21626781, base: "/",
    makeUrl: url_PostDescribeDBEngineVersions_21626782,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBEngineVersions_21626757 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBEngineVersions_21626759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBEngineVersions_21626758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   ListSupportedCharacterSets: JBool
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   DefaultOnly: JBool
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626760 = query.getOrDefault("Engine")
  valid_21626760 = validateParameter(valid_21626760, JString, required = false,
                                   default = nil)
  if valid_21626760 != nil:
    section.add "Engine", valid_21626760
  var valid_21626761 = query.getOrDefault("ListSupportedCharacterSets")
  valid_21626761 = validateParameter(valid_21626761, JBool, required = false,
                                   default = nil)
  if valid_21626761 != nil:
    section.add "ListSupportedCharacterSets", valid_21626761
  var valid_21626762 = query.getOrDefault("MaxRecords")
  valid_21626762 = validateParameter(valid_21626762, JInt, required = false,
                                   default = nil)
  if valid_21626762 != nil:
    section.add "MaxRecords", valid_21626762
  var valid_21626763 = query.getOrDefault("DBParameterGroupFamily")
  valid_21626763 = validateParameter(valid_21626763, JString, required = false,
                                   default = nil)
  if valid_21626763 != nil:
    section.add "DBParameterGroupFamily", valid_21626763
  var valid_21626764 = query.getOrDefault("Filters")
  valid_21626764 = validateParameter(valid_21626764, JArray, required = false,
                                   default = nil)
  if valid_21626764 != nil:
    section.add "Filters", valid_21626764
  var valid_21626765 = query.getOrDefault("Action")
  valid_21626765 = validateParameter(valid_21626765, JString, required = true, default = newJString(
      "DescribeDBEngineVersions"))
  if valid_21626765 != nil:
    section.add "Action", valid_21626765
  var valid_21626766 = query.getOrDefault("Marker")
  valid_21626766 = validateParameter(valid_21626766, JString, required = false,
                                   default = nil)
  if valid_21626766 != nil:
    section.add "Marker", valid_21626766
  var valid_21626767 = query.getOrDefault("EngineVersion")
  valid_21626767 = validateParameter(valid_21626767, JString, required = false,
                                   default = nil)
  if valid_21626767 != nil:
    section.add "EngineVersion", valid_21626767
  var valid_21626768 = query.getOrDefault("DefaultOnly")
  valid_21626768 = validateParameter(valid_21626768, JBool, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "DefaultOnly", valid_21626768
  var valid_21626769 = query.getOrDefault("Version")
  valid_21626769 = validateParameter(valid_21626769, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626769 != nil:
    section.add "Version", valid_21626769
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
  var valid_21626770 = header.getOrDefault("X-Amz-Date")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Date", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Security-Token", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-Algorithm", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Signature")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Signature", valid_21626774
  var valid_21626775 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626775 = validateParameter(valid_21626775, JString, required = false,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626775
  var valid_21626776 = header.getOrDefault("X-Amz-Credential")
  valid_21626776 = validateParameter(valid_21626776, JString, required = false,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "X-Amz-Credential", valid_21626776
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626777: Call_GetDescribeDBEngineVersions_21626757;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626777.validator(path, query, header, formData, body, _)
  let scheme = call_21626777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626777.makeUrl(scheme.get, call_21626777.host, call_21626777.base,
                               call_21626777.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626777, uri, valid, _)

proc call*(call_21626778: Call_GetDescribeDBEngineVersions_21626757;
          Engine: string = ""; ListSupportedCharacterSets: bool = false;
          MaxRecords: int = 0; DBParameterGroupFamily: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBEngineVersions";
          Marker: string = ""; EngineVersion: string = ""; DefaultOnly: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBEngineVersions
  ##   Engine: string
  ##   ListSupportedCharacterSets: bool
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   DefaultOnly: bool
  ##   Version: string (required)
  var query_21626779 = newJObject()
  add(query_21626779, "Engine", newJString(Engine))
  add(query_21626779, "ListSupportedCharacterSets",
      newJBool(ListSupportedCharacterSets))
  add(query_21626779, "MaxRecords", newJInt(MaxRecords))
  add(query_21626779, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21626779.add "Filters", Filters
  add(query_21626779, "Action", newJString(Action))
  add(query_21626779, "Marker", newJString(Marker))
  add(query_21626779, "EngineVersion", newJString(EngineVersion))
  add(query_21626779, "DefaultOnly", newJBool(DefaultOnly))
  add(query_21626779, "Version", newJString(Version))
  result = call_21626778.call(nil, query_21626779, nil, nil, nil)

var getDescribeDBEngineVersions* = Call_GetDescribeDBEngineVersions_21626757(
    name: "getDescribeDBEngineVersions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBEngineVersions",
    validator: validate_GetDescribeDBEngineVersions_21626758, base: "/",
    makeUrl: url_GetDescribeDBEngineVersions_21626759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBInstances_21626823 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBInstances_21626825(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBInstances_21626824(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626826 = query.getOrDefault("Action")
  valid_21626826 = validateParameter(valid_21626826, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626826 != nil:
    section.add "Action", valid_21626826
  var valid_21626827 = query.getOrDefault("Version")
  valid_21626827 = validateParameter(valid_21626827, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626827 != nil:
    section.add "Version", valid_21626827
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
  var valid_21626828 = header.getOrDefault("X-Amz-Date")
  valid_21626828 = validateParameter(valid_21626828, JString, required = false,
                                   default = nil)
  if valid_21626828 != nil:
    section.add "X-Amz-Date", valid_21626828
  var valid_21626829 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626829 = validateParameter(valid_21626829, JString, required = false,
                                   default = nil)
  if valid_21626829 != nil:
    section.add "X-Amz-Security-Token", valid_21626829
  var valid_21626830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626830 = validateParameter(valid_21626830, JString, required = false,
                                   default = nil)
  if valid_21626830 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626830
  var valid_21626831 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626831 = validateParameter(valid_21626831, JString, required = false,
                                   default = nil)
  if valid_21626831 != nil:
    section.add "X-Amz-Algorithm", valid_21626831
  var valid_21626832 = header.getOrDefault("X-Amz-Signature")
  valid_21626832 = validateParameter(valid_21626832, JString, required = false,
                                   default = nil)
  if valid_21626832 != nil:
    section.add "X-Amz-Signature", valid_21626832
  var valid_21626833 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626833 = validateParameter(valid_21626833, JString, required = false,
                                   default = nil)
  if valid_21626833 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626833
  var valid_21626834 = header.getOrDefault("X-Amz-Credential")
  valid_21626834 = validateParameter(valid_21626834, JString, required = false,
                                   default = nil)
  if valid_21626834 != nil:
    section.add "X-Amz-Credential", valid_21626834
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626835 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626835 = validateParameter(valid_21626835, JString, required = false,
                                   default = nil)
  if valid_21626835 != nil:
    section.add "DBInstanceIdentifier", valid_21626835
  var valid_21626836 = formData.getOrDefault("Marker")
  valid_21626836 = validateParameter(valid_21626836, JString, required = false,
                                   default = nil)
  if valid_21626836 != nil:
    section.add "Marker", valid_21626836
  var valid_21626837 = formData.getOrDefault("Filters")
  valid_21626837 = validateParameter(valid_21626837, JArray, required = false,
                                   default = nil)
  if valid_21626837 != nil:
    section.add "Filters", valid_21626837
  var valid_21626838 = formData.getOrDefault("MaxRecords")
  valid_21626838 = validateParameter(valid_21626838, JInt, required = false,
                                   default = nil)
  if valid_21626838 != nil:
    section.add "MaxRecords", valid_21626838
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626839: Call_PostDescribeDBInstances_21626823;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626839.validator(path, query, header, formData, body, _)
  let scheme = call_21626839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626839.makeUrl(scheme.get, call_21626839.host, call_21626839.base,
                               call_21626839.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626839, uri, valid, _)

proc call*(call_21626840: Call_PostDescribeDBInstances_21626823;
          DBInstanceIdentifier: string = ""; Marker: string = "";
          Action: string = "DescribeDBInstances"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBInstances
  ##   DBInstanceIdentifier: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626841 = newJObject()
  var formData_21626842 = newJObject()
  add(formData_21626842, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626842, "Marker", newJString(Marker))
  add(query_21626841, "Action", newJString(Action))
  if Filters != nil:
    formData_21626842.add "Filters", Filters
  add(formData_21626842, "MaxRecords", newJInt(MaxRecords))
  add(query_21626841, "Version", newJString(Version))
  result = call_21626840.call(nil, query_21626841, nil, formData_21626842, nil)

var postDescribeDBInstances* = Call_PostDescribeDBInstances_21626823(
    name: "postDescribeDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_PostDescribeDBInstances_21626824, base: "/",
    makeUrl: url_PostDescribeDBInstances_21626825,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBInstances_21626804 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBInstances_21626806(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBInstances_21626805(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  section = newJObject()
  var valid_21626807 = query.getOrDefault("MaxRecords")
  valid_21626807 = validateParameter(valid_21626807, JInt, required = false,
                                   default = nil)
  if valid_21626807 != nil:
    section.add "MaxRecords", valid_21626807
  var valid_21626808 = query.getOrDefault("Filters")
  valid_21626808 = validateParameter(valid_21626808, JArray, required = false,
                                   default = nil)
  if valid_21626808 != nil:
    section.add "Filters", valid_21626808
  var valid_21626809 = query.getOrDefault("Action")
  valid_21626809 = validateParameter(valid_21626809, JString, required = true,
                                   default = newJString("DescribeDBInstances"))
  if valid_21626809 != nil:
    section.add "Action", valid_21626809
  var valid_21626810 = query.getOrDefault("Marker")
  valid_21626810 = validateParameter(valid_21626810, JString, required = false,
                                   default = nil)
  if valid_21626810 != nil:
    section.add "Marker", valid_21626810
  var valid_21626811 = query.getOrDefault("Version")
  valid_21626811 = validateParameter(valid_21626811, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626811 != nil:
    section.add "Version", valid_21626811
  var valid_21626812 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626812 = validateParameter(valid_21626812, JString, required = false,
                                   default = nil)
  if valid_21626812 != nil:
    section.add "DBInstanceIdentifier", valid_21626812
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
  var valid_21626813 = header.getOrDefault("X-Amz-Date")
  valid_21626813 = validateParameter(valid_21626813, JString, required = false,
                                   default = nil)
  if valid_21626813 != nil:
    section.add "X-Amz-Date", valid_21626813
  var valid_21626814 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626814 = validateParameter(valid_21626814, JString, required = false,
                                   default = nil)
  if valid_21626814 != nil:
    section.add "X-Amz-Security-Token", valid_21626814
  var valid_21626815 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626815 = validateParameter(valid_21626815, JString, required = false,
                                   default = nil)
  if valid_21626815 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626815
  var valid_21626816 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626816 = validateParameter(valid_21626816, JString, required = false,
                                   default = nil)
  if valid_21626816 != nil:
    section.add "X-Amz-Algorithm", valid_21626816
  var valid_21626817 = header.getOrDefault("X-Amz-Signature")
  valid_21626817 = validateParameter(valid_21626817, JString, required = false,
                                   default = nil)
  if valid_21626817 != nil:
    section.add "X-Amz-Signature", valid_21626817
  var valid_21626818 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626818 = validateParameter(valid_21626818, JString, required = false,
                                   default = nil)
  if valid_21626818 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626818
  var valid_21626819 = header.getOrDefault("X-Amz-Credential")
  valid_21626819 = validateParameter(valid_21626819, JString, required = false,
                                   default = nil)
  if valid_21626819 != nil:
    section.add "X-Amz-Credential", valid_21626819
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626820: Call_GetDescribeDBInstances_21626804;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626820.validator(path, query, header, formData, body, _)
  let scheme = call_21626820.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626820.makeUrl(scheme.get, call_21626820.host, call_21626820.base,
                               call_21626820.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626820, uri, valid, _)

proc call*(call_21626821: Call_GetDescribeDBInstances_21626804;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBInstances"; Marker: string = "";
          Version: string = "2013-09-09"; DBInstanceIdentifier: string = ""): Recallable =
  ## getDescribeDBInstances
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  var query_21626822 = newJObject()
  add(query_21626822, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626822.add "Filters", Filters
  add(query_21626822, "Action", newJString(Action))
  add(query_21626822, "Marker", newJString(Marker))
  add(query_21626822, "Version", newJString(Version))
  add(query_21626822, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626821.call(nil, query_21626822, nil, nil, nil)

var getDescribeDBInstances* = Call_GetDescribeDBInstances_21626804(
    name: "getDescribeDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBInstances",
    validator: validate_GetDescribeDBInstances_21626805, base: "/",
    makeUrl: url_GetDescribeDBInstances_21626806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBLogFiles_21626865 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBLogFiles_21626867(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBLogFiles_21626866(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626868 = query.getOrDefault("Action")
  valid_21626868 = validateParameter(valid_21626868, JString, required = true,
                                   default = newJString("DescribeDBLogFiles"))
  if valid_21626868 != nil:
    section.add "Action", valid_21626868
  var valid_21626869 = query.getOrDefault("Version")
  valid_21626869 = validateParameter(valid_21626869, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626869 != nil:
    section.add "Version", valid_21626869
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
  var valid_21626870 = header.getOrDefault("X-Amz-Date")
  valid_21626870 = validateParameter(valid_21626870, JString, required = false,
                                   default = nil)
  if valid_21626870 != nil:
    section.add "X-Amz-Date", valid_21626870
  var valid_21626871 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626871 = validateParameter(valid_21626871, JString, required = false,
                                   default = nil)
  if valid_21626871 != nil:
    section.add "X-Amz-Security-Token", valid_21626871
  var valid_21626872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626872 = validateParameter(valid_21626872, JString, required = false,
                                   default = nil)
  if valid_21626872 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626872
  var valid_21626873 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626873 = validateParameter(valid_21626873, JString, required = false,
                                   default = nil)
  if valid_21626873 != nil:
    section.add "X-Amz-Algorithm", valid_21626873
  var valid_21626874 = header.getOrDefault("X-Amz-Signature")
  valid_21626874 = validateParameter(valid_21626874, JString, required = false,
                                   default = nil)
  if valid_21626874 != nil:
    section.add "X-Amz-Signature", valid_21626874
  var valid_21626875 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626875 = validateParameter(valid_21626875, JString, required = false,
                                   default = nil)
  if valid_21626875 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626875
  var valid_21626876 = header.getOrDefault("X-Amz-Credential")
  valid_21626876 = validateParameter(valid_21626876, JString, required = false,
                                   default = nil)
  if valid_21626876 != nil:
    section.add "X-Amz-Credential", valid_21626876
  result.add "header", section
  ## parameters in `formData` object:
  ##   FilenameContains: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   FileSize: JInt
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   FileLastWritten: JInt
  section = newJObject()
  var valid_21626877 = formData.getOrDefault("FilenameContains")
  valid_21626877 = validateParameter(valid_21626877, JString, required = false,
                                   default = nil)
  if valid_21626877 != nil:
    section.add "FilenameContains", valid_21626877
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21626878 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21626878 = validateParameter(valid_21626878, JString, required = true,
                                   default = nil)
  if valid_21626878 != nil:
    section.add "DBInstanceIdentifier", valid_21626878
  var valid_21626879 = formData.getOrDefault("FileSize")
  valid_21626879 = validateParameter(valid_21626879, JInt, required = false,
                                   default = nil)
  if valid_21626879 != nil:
    section.add "FileSize", valid_21626879
  var valid_21626880 = formData.getOrDefault("Marker")
  valid_21626880 = validateParameter(valid_21626880, JString, required = false,
                                   default = nil)
  if valid_21626880 != nil:
    section.add "Marker", valid_21626880
  var valid_21626881 = formData.getOrDefault("Filters")
  valid_21626881 = validateParameter(valid_21626881, JArray, required = false,
                                   default = nil)
  if valid_21626881 != nil:
    section.add "Filters", valid_21626881
  var valid_21626882 = formData.getOrDefault("MaxRecords")
  valid_21626882 = validateParameter(valid_21626882, JInt, required = false,
                                   default = nil)
  if valid_21626882 != nil:
    section.add "MaxRecords", valid_21626882
  var valid_21626883 = formData.getOrDefault("FileLastWritten")
  valid_21626883 = validateParameter(valid_21626883, JInt, required = false,
                                   default = nil)
  if valid_21626883 != nil:
    section.add "FileLastWritten", valid_21626883
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626884: Call_PostDescribeDBLogFiles_21626865;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626884.validator(path, query, header, formData, body, _)
  let scheme = call_21626884.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626884.makeUrl(scheme.get, call_21626884.host, call_21626884.base,
                               call_21626884.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626884, uri, valid, _)

proc call*(call_21626885: Call_PostDescribeDBLogFiles_21626865;
          DBInstanceIdentifier: string; FilenameContains: string = "";
          FileSize: int = 0; Marker: string = ""; Action: string = "DescribeDBLogFiles";
          Filters: JsonNode = nil; MaxRecords: int = 0; FileLastWritten: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBLogFiles
  ##   FilenameContains: string
  ##   DBInstanceIdentifier: string (required)
  ##   FileSize: int
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   FileLastWritten: int
  ##   Version: string (required)
  var query_21626886 = newJObject()
  var formData_21626887 = newJObject()
  add(formData_21626887, "FilenameContains", newJString(FilenameContains))
  add(formData_21626887, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21626887, "FileSize", newJInt(FileSize))
  add(formData_21626887, "Marker", newJString(Marker))
  add(query_21626886, "Action", newJString(Action))
  if Filters != nil:
    formData_21626887.add "Filters", Filters
  add(formData_21626887, "MaxRecords", newJInt(MaxRecords))
  add(formData_21626887, "FileLastWritten", newJInt(FileLastWritten))
  add(query_21626886, "Version", newJString(Version))
  result = call_21626885.call(nil, query_21626886, nil, formData_21626887, nil)

var postDescribeDBLogFiles* = Call_PostDescribeDBLogFiles_21626865(
    name: "postDescribeDBLogFiles", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_PostDescribeDBLogFiles_21626866, base: "/",
    makeUrl: url_PostDescribeDBLogFiles_21626867,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBLogFiles_21626843 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBLogFiles_21626845(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBLogFiles_21626844(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FileLastWritten: JInt
  ##   MaxRecords: JInt
  ##   FilenameContains: JString
  ##   FileSize: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_21626846 = query.getOrDefault("FileLastWritten")
  valid_21626846 = validateParameter(valid_21626846, JInt, required = false,
                                   default = nil)
  if valid_21626846 != nil:
    section.add "FileLastWritten", valid_21626846
  var valid_21626847 = query.getOrDefault("MaxRecords")
  valid_21626847 = validateParameter(valid_21626847, JInt, required = false,
                                   default = nil)
  if valid_21626847 != nil:
    section.add "MaxRecords", valid_21626847
  var valid_21626848 = query.getOrDefault("FilenameContains")
  valid_21626848 = validateParameter(valid_21626848, JString, required = false,
                                   default = nil)
  if valid_21626848 != nil:
    section.add "FilenameContains", valid_21626848
  var valid_21626849 = query.getOrDefault("FileSize")
  valid_21626849 = validateParameter(valid_21626849, JInt, required = false,
                                   default = nil)
  if valid_21626849 != nil:
    section.add "FileSize", valid_21626849
  var valid_21626850 = query.getOrDefault("Filters")
  valid_21626850 = validateParameter(valid_21626850, JArray, required = false,
                                   default = nil)
  if valid_21626850 != nil:
    section.add "Filters", valid_21626850
  var valid_21626851 = query.getOrDefault("Action")
  valid_21626851 = validateParameter(valid_21626851, JString, required = true,
                                   default = newJString("DescribeDBLogFiles"))
  if valid_21626851 != nil:
    section.add "Action", valid_21626851
  var valid_21626852 = query.getOrDefault("Marker")
  valid_21626852 = validateParameter(valid_21626852, JString, required = false,
                                   default = nil)
  if valid_21626852 != nil:
    section.add "Marker", valid_21626852
  var valid_21626853 = query.getOrDefault("Version")
  valid_21626853 = validateParameter(valid_21626853, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626853 != nil:
    section.add "Version", valid_21626853
  var valid_21626854 = query.getOrDefault("DBInstanceIdentifier")
  valid_21626854 = validateParameter(valid_21626854, JString, required = true,
                                   default = nil)
  if valid_21626854 != nil:
    section.add "DBInstanceIdentifier", valid_21626854
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
  var valid_21626855 = header.getOrDefault("X-Amz-Date")
  valid_21626855 = validateParameter(valid_21626855, JString, required = false,
                                   default = nil)
  if valid_21626855 != nil:
    section.add "X-Amz-Date", valid_21626855
  var valid_21626856 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626856 = validateParameter(valid_21626856, JString, required = false,
                                   default = nil)
  if valid_21626856 != nil:
    section.add "X-Amz-Security-Token", valid_21626856
  var valid_21626857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626857 = validateParameter(valid_21626857, JString, required = false,
                                   default = nil)
  if valid_21626857 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626857
  var valid_21626858 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626858 = validateParameter(valid_21626858, JString, required = false,
                                   default = nil)
  if valid_21626858 != nil:
    section.add "X-Amz-Algorithm", valid_21626858
  var valid_21626859 = header.getOrDefault("X-Amz-Signature")
  valid_21626859 = validateParameter(valid_21626859, JString, required = false,
                                   default = nil)
  if valid_21626859 != nil:
    section.add "X-Amz-Signature", valid_21626859
  var valid_21626860 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626860 = validateParameter(valid_21626860, JString, required = false,
                                   default = nil)
  if valid_21626860 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626860
  var valid_21626861 = header.getOrDefault("X-Amz-Credential")
  valid_21626861 = validateParameter(valid_21626861, JString, required = false,
                                   default = nil)
  if valid_21626861 != nil:
    section.add "X-Amz-Credential", valid_21626861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626862: Call_GetDescribeDBLogFiles_21626843;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626862.validator(path, query, header, formData, body, _)
  let scheme = call_21626862.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626862.makeUrl(scheme.get, call_21626862.host, call_21626862.base,
                               call_21626862.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626862, uri, valid, _)

proc call*(call_21626863: Call_GetDescribeDBLogFiles_21626843;
          DBInstanceIdentifier: string; FileLastWritten: int = 0; MaxRecords: int = 0;
          FilenameContains: string = ""; FileSize: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBLogFiles"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBLogFiles
  ##   FileLastWritten: int
  ##   MaxRecords: int
  ##   FilenameContains: string
  ##   FileSize: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21626864 = newJObject()
  add(query_21626864, "FileLastWritten", newJInt(FileLastWritten))
  add(query_21626864, "MaxRecords", newJInt(MaxRecords))
  add(query_21626864, "FilenameContains", newJString(FilenameContains))
  add(query_21626864, "FileSize", newJInt(FileSize))
  if Filters != nil:
    query_21626864.add "Filters", Filters
  add(query_21626864, "Action", newJString(Action))
  add(query_21626864, "Marker", newJString(Marker))
  add(query_21626864, "Version", newJString(Version))
  add(query_21626864, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21626863.call(nil, query_21626864, nil, nil, nil)

var getDescribeDBLogFiles* = Call_GetDescribeDBLogFiles_21626843(
    name: "getDescribeDBLogFiles", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBLogFiles",
    validator: validate_GetDescribeDBLogFiles_21626844, base: "/",
    makeUrl: url_GetDescribeDBLogFiles_21626845,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameterGroups_21626907 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameterGroups_21626909(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameterGroups_21626908(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626910 = query.getOrDefault("Action")
  valid_21626910 = validateParameter(valid_21626910, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626910 != nil:
    section.add "Action", valid_21626910
  var valid_21626911 = query.getOrDefault("Version")
  valid_21626911 = validateParameter(valid_21626911, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626911 != nil:
    section.add "Version", valid_21626911
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
  var valid_21626912 = header.getOrDefault("X-Amz-Date")
  valid_21626912 = validateParameter(valid_21626912, JString, required = false,
                                   default = nil)
  if valid_21626912 != nil:
    section.add "X-Amz-Date", valid_21626912
  var valid_21626913 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626913 = validateParameter(valid_21626913, JString, required = false,
                                   default = nil)
  if valid_21626913 != nil:
    section.add "X-Amz-Security-Token", valid_21626913
  var valid_21626914 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626914 = validateParameter(valid_21626914, JString, required = false,
                                   default = nil)
  if valid_21626914 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626914
  var valid_21626915 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626915 = validateParameter(valid_21626915, JString, required = false,
                                   default = nil)
  if valid_21626915 != nil:
    section.add "X-Amz-Algorithm", valid_21626915
  var valid_21626916 = header.getOrDefault("X-Amz-Signature")
  valid_21626916 = validateParameter(valid_21626916, JString, required = false,
                                   default = nil)
  if valid_21626916 != nil:
    section.add "X-Amz-Signature", valid_21626916
  var valid_21626917 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626917 = validateParameter(valid_21626917, JString, required = false,
                                   default = nil)
  if valid_21626917 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626917
  var valid_21626918 = header.getOrDefault("X-Amz-Credential")
  valid_21626918 = validateParameter(valid_21626918, JString, required = false,
                                   default = nil)
  if valid_21626918 != nil:
    section.add "X-Amz-Credential", valid_21626918
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626919 = formData.getOrDefault("DBParameterGroupName")
  valid_21626919 = validateParameter(valid_21626919, JString, required = false,
                                   default = nil)
  if valid_21626919 != nil:
    section.add "DBParameterGroupName", valid_21626919
  var valid_21626920 = formData.getOrDefault("Marker")
  valid_21626920 = validateParameter(valid_21626920, JString, required = false,
                                   default = nil)
  if valid_21626920 != nil:
    section.add "Marker", valid_21626920
  var valid_21626921 = formData.getOrDefault("Filters")
  valid_21626921 = validateParameter(valid_21626921, JArray, required = false,
                                   default = nil)
  if valid_21626921 != nil:
    section.add "Filters", valid_21626921
  var valid_21626922 = formData.getOrDefault("MaxRecords")
  valid_21626922 = validateParameter(valid_21626922, JInt, required = false,
                                   default = nil)
  if valid_21626922 != nil:
    section.add "MaxRecords", valid_21626922
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626923: Call_PostDescribeDBParameterGroups_21626907;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626923.validator(path, query, header, formData, body, _)
  let scheme = call_21626923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626923.makeUrl(scheme.get, call_21626923.host, call_21626923.base,
                               call_21626923.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626923, uri, valid, _)

proc call*(call_21626924: Call_PostDescribeDBParameterGroups_21626907;
          DBParameterGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBParameterGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBParameterGroups
  ##   DBParameterGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21626925 = newJObject()
  var formData_21626926 = newJObject()
  add(formData_21626926, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626926, "Marker", newJString(Marker))
  add(query_21626925, "Action", newJString(Action))
  if Filters != nil:
    formData_21626926.add "Filters", Filters
  add(formData_21626926, "MaxRecords", newJInt(MaxRecords))
  add(query_21626925, "Version", newJString(Version))
  result = call_21626924.call(nil, query_21626925, nil, formData_21626926, nil)

var postDescribeDBParameterGroups* = Call_PostDescribeDBParameterGroups_21626907(
    name: "postDescribeDBParameterGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_PostDescribeDBParameterGroups_21626908, base: "/",
    makeUrl: url_PostDescribeDBParameterGroups_21626909,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameterGroups_21626888 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameterGroups_21626890(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameterGroups_21626889(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   DBParameterGroupName: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626891 = query.getOrDefault("MaxRecords")
  valid_21626891 = validateParameter(valid_21626891, JInt, required = false,
                                   default = nil)
  if valid_21626891 != nil:
    section.add "MaxRecords", valid_21626891
  var valid_21626892 = query.getOrDefault("Filters")
  valid_21626892 = validateParameter(valid_21626892, JArray, required = false,
                                   default = nil)
  if valid_21626892 != nil:
    section.add "Filters", valid_21626892
  var valid_21626893 = query.getOrDefault("DBParameterGroupName")
  valid_21626893 = validateParameter(valid_21626893, JString, required = false,
                                   default = nil)
  if valid_21626893 != nil:
    section.add "DBParameterGroupName", valid_21626893
  var valid_21626894 = query.getOrDefault("Action")
  valid_21626894 = validateParameter(valid_21626894, JString, required = true, default = newJString(
      "DescribeDBParameterGroups"))
  if valid_21626894 != nil:
    section.add "Action", valid_21626894
  var valid_21626895 = query.getOrDefault("Marker")
  valid_21626895 = validateParameter(valid_21626895, JString, required = false,
                                   default = nil)
  if valid_21626895 != nil:
    section.add "Marker", valid_21626895
  var valid_21626896 = query.getOrDefault("Version")
  valid_21626896 = validateParameter(valid_21626896, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626896 != nil:
    section.add "Version", valid_21626896
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
  var valid_21626897 = header.getOrDefault("X-Amz-Date")
  valid_21626897 = validateParameter(valid_21626897, JString, required = false,
                                   default = nil)
  if valid_21626897 != nil:
    section.add "X-Amz-Date", valid_21626897
  var valid_21626898 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626898 = validateParameter(valid_21626898, JString, required = false,
                                   default = nil)
  if valid_21626898 != nil:
    section.add "X-Amz-Security-Token", valid_21626898
  var valid_21626899 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626899 = validateParameter(valid_21626899, JString, required = false,
                                   default = nil)
  if valid_21626899 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626899
  var valid_21626900 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626900 = validateParameter(valid_21626900, JString, required = false,
                                   default = nil)
  if valid_21626900 != nil:
    section.add "X-Amz-Algorithm", valid_21626900
  var valid_21626901 = header.getOrDefault("X-Amz-Signature")
  valid_21626901 = validateParameter(valid_21626901, JString, required = false,
                                   default = nil)
  if valid_21626901 != nil:
    section.add "X-Amz-Signature", valid_21626901
  var valid_21626902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626902 = validateParameter(valid_21626902, JString, required = false,
                                   default = nil)
  if valid_21626902 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626902
  var valid_21626903 = header.getOrDefault("X-Amz-Credential")
  valid_21626903 = validateParameter(valid_21626903, JString, required = false,
                                   default = nil)
  if valid_21626903 != nil:
    section.add "X-Amz-Credential", valid_21626903
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626904: Call_GetDescribeDBParameterGroups_21626888;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626904.validator(path, query, header, formData, body, _)
  let scheme = call_21626904.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626904.makeUrl(scheme.get, call_21626904.host, call_21626904.base,
                               call_21626904.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626904, uri, valid, _)

proc call*(call_21626905: Call_GetDescribeDBParameterGroups_21626888;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          DBParameterGroupName: string = "";
          Action: string = "DescribeDBParameterGroups"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBParameterGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21626906 = newJObject()
  add(query_21626906, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626906.add "Filters", Filters
  add(query_21626906, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626906, "Action", newJString(Action))
  add(query_21626906, "Marker", newJString(Marker))
  add(query_21626906, "Version", newJString(Version))
  result = call_21626905.call(nil, query_21626906, nil, nil, nil)

var getDescribeDBParameterGroups* = Call_GetDescribeDBParameterGroups_21626888(
    name: "getDescribeDBParameterGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameterGroups",
    validator: validate_GetDescribeDBParameterGroups_21626889, base: "/",
    makeUrl: url_GetDescribeDBParameterGroups_21626890,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBParameters_21626947 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBParameters_21626949(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBParameters_21626948(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626950 = query.getOrDefault("Action")
  valid_21626950 = validateParameter(valid_21626950, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21626950 != nil:
    section.add "Action", valid_21626950
  var valid_21626951 = query.getOrDefault("Version")
  valid_21626951 = validateParameter(valid_21626951, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626951 != nil:
    section.add "Version", valid_21626951
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
  var valid_21626952 = header.getOrDefault("X-Amz-Date")
  valid_21626952 = validateParameter(valid_21626952, JString, required = false,
                                   default = nil)
  if valid_21626952 != nil:
    section.add "X-Amz-Date", valid_21626952
  var valid_21626953 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626953 = validateParameter(valid_21626953, JString, required = false,
                                   default = nil)
  if valid_21626953 != nil:
    section.add "X-Amz-Security-Token", valid_21626953
  var valid_21626954 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626954 = validateParameter(valid_21626954, JString, required = false,
                                   default = nil)
  if valid_21626954 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626954
  var valid_21626955 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626955 = validateParameter(valid_21626955, JString, required = false,
                                   default = nil)
  if valid_21626955 != nil:
    section.add "X-Amz-Algorithm", valid_21626955
  var valid_21626956 = header.getOrDefault("X-Amz-Signature")
  valid_21626956 = validateParameter(valid_21626956, JString, required = false,
                                   default = nil)
  if valid_21626956 != nil:
    section.add "X-Amz-Signature", valid_21626956
  var valid_21626957 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626957 = validateParameter(valid_21626957, JString, required = false,
                                   default = nil)
  if valid_21626957 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626957
  var valid_21626958 = header.getOrDefault("X-Amz-Credential")
  valid_21626958 = validateParameter(valid_21626958, JString, required = false,
                                   default = nil)
  if valid_21626958 != nil:
    section.add "X-Amz-Credential", valid_21626958
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  ##   Source: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626959 = formData.getOrDefault("DBParameterGroupName")
  valid_21626959 = validateParameter(valid_21626959, JString, required = true,
                                   default = nil)
  if valid_21626959 != nil:
    section.add "DBParameterGroupName", valid_21626959
  var valid_21626960 = formData.getOrDefault("Marker")
  valid_21626960 = validateParameter(valid_21626960, JString, required = false,
                                   default = nil)
  if valid_21626960 != nil:
    section.add "Marker", valid_21626960
  var valid_21626961 = formData.getOrDefault("Filters")
  valid_21626961 = validateParameter(valid_21626961, JArray, required = false,
                                   default = nil)
  if valid_21626961 != nil:
    section.add "Filters", valid_21626961
  var valid_21626962 = formData.getOrDefault("MaxRecords")
  valid_21626962 = validateParameter(valid_21626962, JInt, required = false,
                                   default = nil)
  if valid_21626962 != nil:
    section.add "MaxRecords", valid_21626962
  var valid_21626963 = formData.getOrDefault("Source")
  valid_21626963 = validateParameter(valid_21626963, JString, required = false,
                                   default = nil)
  if valid_21626963 != nil:
    section.add "Source", valid_21626963
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626964: Call_PostDescribeDBParameters_21626947;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626964.validator(path, query, header, formData, body, _)
  let scheme = call_21626964.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626964.makeUrl(scheme.get, call_21626964.host, call_21626964.base,
                               call_21626964.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626964, uri, valid, _)

proc call*(call_21626965: Call_PostDescribeDBParameters_21626947;
          DBParameterGroupName: string; Marker: string = "";
          Action: string = "DescribeDBParameters"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"; Source: string = ""): Recallable =
  ## postDescribeDBParameters
  ##   DBParameterGroupName: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   Source: string
  var query_21626966 = newJObject()
  var formData_21626967 = newJObject()
  add(formData_21626967, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21626967, "Marker", newJString(Marker))
  add(query_21626966, "Action", newJString(Action))
  if Filters != nil:
    formData_21626967.add "Filters", Filters
  add(formData_21626967, "MaxRecords", newJInt(MaxRecords))
  add(query_21626966, "Version", newJString(Version))
  add(formData_21626967, "Source", newJString(Source))
  result = call_21626965.call(nil, query_21626966, nil, formData_21626967, nil)

var postDescribeDBParameters* = Call_PostDescribeDBParameters_21626947(
    name: "postDescribeDBParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_PostDescribeDBParameters_21626948, base: "/",
    makeUrl: url_PostDescribeDBParameters_21626949,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBParameters_21626927 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBParameters_21626929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBParameters_21626928(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   DBParameterGroupName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Source: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626930 = query.getOrDefault("MaxRecords")
  valid_21626930 = validateParameter(valid_21626930, JInt, required = false,
                                   default = nil)
  if valid_21626930 != nil:
    section.add "MaxRecords", valid_21626930
  var valid_21626931 = query.getOrDefault("Filters")
  valid_21626931 = validateParameter(valid_21626931, JArray, required = false,
                                   default = nil)
  if valid_21626931 != nil:
    section.add "Filters", valid_21626931
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21626932 = query.getOrDefault("DBParameterGroupName")
  valid_21626932 = validateParameter(valid_21626932, JString, required = true,
                                   default = nil)
  if valid_21626932 != nil:
    section.add "DBParameterGroupName", valid_21626932
  var valid_21626933 = query.getOrDefault("Action")
  valid_21626933 = validateParameter(valid_21626933, JString, required = true,
                                   default = newJString("DescribeDBParameters"))
  if valid_21626933 != nil:
    section.add "Action", valid_21626933
  var valid_21626934 = query.getOrDefault("Marker")
  valid_21626934 = validateParameter(valid_21626934, JString, required = false,
                                   default = nil)
  if valid_21626934 != nil:
    section.add "Marker", valid_21626934
  var valid_21626935 = query.getOrDefault("Source")
  valid_21626935 = validateParameter(valid_21626935, JString, required = false,
                                   default = nil)
  if valid_21626935 != nil:
    section.add "Source", valid_21626935
  var valid_21626936 = query.getOrDefault("Version")
  valid_21626936 = validateParameter(valid_21626936, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626936 != nil:
    section.add "Version", valid_21626936
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
  var valid_21626937 = header.getOrDefault("X-Amz-Date")
  valid_21626937 = validateParameter(valid_21626937, JString, required = false,
                                   default = nil)
  if valid_21626937 != nil:
    section.add "X-Amz-Date", valid_21626937
  var valid_21626938 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626938 = validateParameter(valid_21626938, JString, required = false,
                                   default = nil)
  if valid_21626938 != nil:
    section.add "X-Amz-Security-Token", valid_21626938
  var valid_21626939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626939 = validateParameter(valid_21626939, JString, required = false,
                                   default = nil)
  if valid_21626939 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626939
  var valid_21626940 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626940 = validateParameter(valid_21626940, JString, required = false,
                                   default = nil)
  if valid_21626940 != nil:
    section.add "X-Amz-Algorithm", valid_21626940
  var valid_21626941 = header.getOrDefault("X-Amz-Signature")
  valid_21626941 = validateParameter(valid_21626941, JString, required = false,
                                   default = nil)
  if valid_21626941 != nil:
    section.add "X-Amz-Signature", valid_21626941
  var valid_21626942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626942 = validateParameter(valid_21626942, JString, required = false,
                                   default = nil)
  if valid_21626942 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626942
  var valid_21626943 = header.getOrDefault("X-Amz-Credential")
  valid_21626943 = validateParameter(valid_21626943, JString, required = false,
                                   default = nil)
  if valid_21626943 != nil:
    section.add "X-Amz-Credential", valid_21626943
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626944: Call_GetDescribeDBParameters_21626927;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626944.validator(path, query, header, formData, body, _)
  let scheme = call_21626944.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626944.makeUrl(scheme.get, call_21626944.host, call_21626944.base,
                               call_21626944.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626944, uri, valid, _)

proc call*(call_21626945: Call_GetDescribeDBParameters_21626927;
          DBParameterGroupName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBParameters"; Marker: string = "";
          Source: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBParameters
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   DBParameterGroupName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Source: string
  ##   Version: string (required)
  var query_21626946 = newJObject()
  add(query_21626946, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21626946.add "Filters", Filters
  add(query_21626946, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21626946, "Action", newJString(Action))
  add(query_21626946, "Marker", newJString(Marker))
  add(query_21626946, "Source", newJString(Source))
  add(query_21626946, "Version", newJString(Version))
  result = call_21626945.call(nil, query_21626946, nil, nil, nil)

var getDescribeDBParameters* = Call_GetDescribeDBParameters_21626927(
    name: "getDescribeDBParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBParameters",
    validator: validate_GetDescribeDBParameters_21626928, base: "/",
    makeUrl: url_GetDescribeDBParameters_21626929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSecurityGroups_21626987 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSecurityGroups_21626989(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSecurityGroups_21626988(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626990 = query.getOrDefault("Action")
  valid_21626990 = validateParameter(valid_21626990, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21626990 != nil:
    section.add "Action", valid_21626990
  var valid_21626991 = query.getOrDefault("Version")
  valid_21626991 = validateParameter(valid_21626991, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626991 != nil:
    section.add "Version", valid_21626991
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
  var valid_21626992 = header.getOrDefault("X-Amz-Date")
  valid_21626992 = validateParameter(valid_21626992, JString, required = false,
                                   default = nil)
  if valid_21626992 != nil:
    section.add "X-Amz-Date", valid_21626992
  var valid_21626993 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626993 = validateParameter(valid_21626993, JString, required = false,
                                   default = nil)
  if valid_21626993 != nil:
    section.add "X-Amz-Security-Token", valid_21626993
  var valid_21626994 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626994 = validateParameter(valid_21626994, JString, required = false,
                                   default = nil)
  if valid_21626994 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626994
  var valid_21626995 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626995 = validateParameter(valid_21626995, JString, required = false,
                                   default = nil)
  if valid_21626995 != nil:
    section.add "X-Amz-Algorithm", valid_21626995
  var valid_21626996 = header.getOrDefault("X-Amz-Signature")
  valid_21626996 = validateParameter(valid_21626996, JString, required = false,
                                   default = nil)
  if valid_21626996 != nil:
    section.add "X-Amz-Signature", valid_21626996
  var valid_21626997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626997 = validateParameter(valid_21626997, JString, required = false,
                                   default = nil)
  if valid_21626997 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626997
  var valid_21626998 = header.getOrDefault("X-Amz-Credential")
  valid_21626998 = validateParameter(valid_21626998, JString, required = false,
                                   default = nil)
  if valid_21626998 != nil:
    section.add "X-Amz-Credential", valid_21626998
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21626999 = formData.getOrDefault("DBSecurityGroupName")
  valid_21626999 = validateParameter(valid_21626999, JString, required = false,
                                   default = nil)
  if valid_21626999 != nil:
    section.add "DBSecurityGroupName", valid_21626999
  var valid_21627000 = formData.getOrDefault("Marker")
  valid_21627000 = validateParameter(valid_21627000, JString, required = false,
                                   default = nil)
  if valid_21627000 != nil:
    section.add "Marker", valid_21627000
  var valid_21627001 = formData.getOrDefault("Filters")
  valid_21627001 = validateParameter(valid_21627001, JArray, required = false,
                                   default = nil)
  if valid_21627001 != nil:
    section.add "Filters", valid_21627001
  var valid_21627002 = formData.getOrDefault("MaxRecords")
  valid_21627002 = validateParameter(valid_21627002, JInt, required = false,
                                   default = nil)
  if valid_21627002 != nil:
    section.add "MaxRecords", valid_21627002
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627003: Call_PostDescribeDBSecurityGroups_21626987;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627003.validator(path, query, header, formData, body, _)
  let scheme = call_21627003.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627003.makeUrl(scheme.get, call_21627003.host, call_21627003.base,
                               call_21627003.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627003, uri, valid, _)

proc call*(call_21627004: Call_PostDescribeDBSecurityGroups_21626987;
          DBSecurityGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSecurityGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSecurityGroups
  ##   DBSecurityGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627005 = newJObject()
  var formData_21627006 = newJObject()
  add(formData_21627006, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(formData_21627006, "Marker", newJString(Marker))
  add(query_21627005, "Action", newJString(Action))
  if Filters != nil:
    formData_21627006.add "Filters", Filters
  add(formData_21627006, "MaxRecords", newJInt(MaxRecords))
  add(query_21627005, "Version", newJString(Version))
  result = call_21627004.call(nil, query_21627005, nil, formData_21627006, nil)

var postDescribeDBSecurityGroups* = Call_PostDescribeDBSecurityGroups_21626987(
    name: "postDescribeDBSecurityGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_PostDescribeDBSecurityGroups_21626988, base: "/",
    makeUrl: url_PostDescribeDBSecurityGroups_21626989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSecurityGroups_21626968 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSecurityGroups_21626970(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSecurityGroups_21626969(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBSecurityGroupName: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21626971 = query.getOrDefault("MaxRecords")
  valid_21626971 = validateParameter(valid_21626971, JInt, required = false,
                                   default = nil)
  if valid_21626971 != nil:
    section.add "MaxRecords", valid_21626971
  var valid_21626972 = query.getOrDefault("DBSecurityGroupName")
  valid_21626972 = validateParameter(valid_21626972, JString, required = false,
                                   default = nil)
  if valid_21626972 != nil:
    section.add "DBSecurityGroupName", valid_21626972
  var valid_21626973 = query.getOrDefault("Filters")
  valid_21626973 = validateParameter(valid_21626973, JArray, required = false,
                                   default = nil)
  if valid_21626973 != nil:
    section.add "Filters", valid_21626973
  var valid_21626974 = query.getOrDefault("Action")
  valid_21626974 = validateParameter(valid_21626974, JString, required = true, default = newJString(
      "DescribeDBSecurityGroups"))
  if valid_21626974 != nil:
    section.add "Action", valid_21626974
  var valid_21626975 = query.getOrDefault("Marker")
  valid_21626975 = validateParameter(valid_21626975, JString, required = false,
                                   default = nil)
  if valid_21626975 != nil:
    section.add "Marker", valid_21626975
  var valid_21626976 = query.getOrDefault("Version")
  valid_21626976 = validateParameter(valid_21626976, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21626976 != nil:
    section.add "Version", valid_21626976
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
  var valid_21626977 = header.getOrDefault("X-Amz-Date")
  valid_21626977 = validateParameter(valid_21626977, JString, required = false,
                                   default = nil)
  if valid_21626977 != nil:
    section.add "X-Amz-Date", valid_21626977
  var valid_21626978 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626978 = validateParameter(valid_21626978, JString, required = false,
                                   default = nil)
  if valid_21626978 != nil:
    section.add "X-Amz-Security-Token", valid_21626978
  var valid_21626979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626979 = validateParameter(valid_21626979, JString, required = false,
                                   default = nil)
  if valid_21626979 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626979
  var valid_21626980 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626980 = validateParameter(valid_21626980, JString, required = false,
                                   default = nil)
  if valid_21626980 != nil:
    section.add "X-Amz-Algorithm", valid_21626980
  var valid_21626981 = header.getOrDefault("X-Amz-Signature")
  valid_21626981 = validateParameter(valid_21626981, JString, required = false,
                                   default = nil)
  if valid_21626981 != nil:
    section.add "X-Amz-Signature", valid_21626981
  var valid_21626982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626982 = validateParameter(valid_21626982, JString, required = false,
                                   default = nil)
  if valid_21626982 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626982
  var valid_21626983 = header.getOrDefault("X-Amz-Credential")
  valid_21626983 = validateParameter(valid_21626983, JString, required = false,
                                   default = nil)
  if valid_21626983 != nil:
    section.add "X-Amz-Credential", valid_21626983
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626984: Call_GetDescribeDBSecurityGroups_21626968;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626984.validator(path, query, header, formData, body, _)
  let scheme = call_21626984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626984.makeUrl(scheme.get, call_21626984.host, call_21626984.base,
                               call_21626984.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626984, uri, valid, _)

proc call*(call_21626985: Call_GetDescribeDBSecurityGroups_21626968;
          MaxRecords: int = 0; DBSecurityGroupName: string = "";
          Filters: JsonNode = nil; Action: string = "DescribeDBSecurityGroups";
          Marker: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBSecurityGroups
  ##   MaxRecords: int
  ##   DBSecurityGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21626986 = newJObject()
  add(query_21626986, "MaxRecords", newJInt(MaxRecords))
  add(query_21626986, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  if Filters != nil:
    query_21626986.add "Filters", Filters
  add(query_21626986, "Action", newJString(Action))
  add(query_21626986, "Marker", newJString(Marker))
  add(query_21626986, "Version", newJString(Version))
  result = call_21626985.call(nil, query_21626986, nil, nil, nil)

var getDescribeDBSecurityGroups* = Call_GetDescribeDBSecurityGroups_21626968(
    name: "getDescribeDBSecurityGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSecurityGroups",
    validator: validate_GetDescribeDBSecurityGroups_21626969, base: "/",
    makeUrl: url_GetDescribeDBSecurityGroups_21626970,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSnapshots_21627028 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSnapshots_21627030(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSnapshots_21627029(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627031 = query.getOrDefault("Action")
  valid_21627031 = validateParameter(valid_21627031, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21627031 != nil:
    section.add "Action", valid_21627031
  var valid_21627032 = query.getOrDefault("Version")
  valid_21627032 = validateParameter(valid_21627032, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627032 != nil:
    section.add "Version", valid_21627032
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
  var valid_21627033 = header.getOrDefault("X-Amz-Date")
  valid_21627033 = validateParameter(valid_21627033, JString, required = false,
                                   default = nil)
  if valid_21627033 != nil:
    section.add "X-Amz-Date", valid_21627033
  var valid_21627034 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627034 = validateParameter(valid_21627034, JString, required = false,
                                   default = nil)
  if valid_21627034 != nil:
    section.add "X-Amz-Security-Token", valid_21627034
  var valid_21627035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627035 = validateParameter(valid_21627035, JString, required = false,
                                   default = nil)
  if valid_21627035 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627035
  var valid_21627036 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627036 = validateParameter(valid_21627036, JString, required = false,
                                   default = nil)
  if valid_21627036 != nil:
    section.add "X-Amz-Algorithm", valid_21627036
  var valid_21627037 = header.getOrDefault("X-Amz-Signature")
  valid_21627037 = validateParameter(valid_21627037, JString, required = false,
                                   default = nil)
  if valid_21627037 != nil:
    section.add "X-Amz-Signature", valid_21627037
  var valid_21627038 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627038 = validateParameter(valid_21627038, JString, required = false,
                                   default = nil)
  if valid_21627038 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627038
  var valid_21627039 = header.getOrDefault("X-Amz-Credential")
  valid_21627039 = validateParameter(valid_21627039, JString, required = false,
                                   default = nil)
  if valid_21627039 != nil:
    section.add "X-Amz-Credential", valid_21627039
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString
  ##   SnapshotType: JString
  ##   Marker: JString
  ##   DBSnapshotIdentifier: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627040 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627040 = validateParameter(valid_21627040, JString, required = false,
                                   default = nil)
  if valid_21627040 != nil:
    section.add "DBInstanceIdentifier", valid_21627040
  var valid_21627041 = formData.getOrDefault("SnapshotType")
  valid_21627041 = validateParameter(valid_21627041, JString, required = false,
                                   default = nil)
  if valid_21627041 != nil:
    section.add "SnapshotType", valid_21627041
  var valid_21627042 = formData.getOrDefault("Marker")
  valid_21627042 = validateParameter(valid_21627042, JString, required = false,
                                   default = nil)
  if valid_21627042 != nil:
    section.add "Marker", valid_21627042
  var valid_21627043 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21627043 = validateParameter(valid_21627043, JString, required = false,
                                   default = nil)
  if valid_21627043 != nil:
    section.add "DBSnapshotIdentifier", valid_21627043
  var valid_21627044 = formData.getOrDefault("Filters")
  valid_21627044 = validateParameter(valid_21627044, JArray, required = false,
                                   default = nil)
  if valid_21627044 != nil:
    section.add "Filters", valid_21627044
  var valid_21627045 = formData.getOrDefault("MaxRecords")
  valid_21627045 = validateParameter(valid_21627045, JInt, required = false,
                                   default = nil)
  if valid_21627045 != nil:
    section.add "MaxRecords", valid_21627045
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627046: Call_PostDescribeDBSnapshots_21627028;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627046.validator(path, query, header, formData, body, _)
  let scheme = call_21627046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627046.makeUrl(scheme.get, call_21627046.host, call_21627046.base,
                               call_21627046.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627046, uri, valid, _)

proc call*(call_21627047: Call_PostDescribeDBSnapshots_21627028;
          DBInstanceIdentifier: string = ""; SnapshotType: string = "";
          Marker: string = ""; DBSnapshotIdentifier: string = "";
          Action: string = "DescribeDBSnapshots"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSnapshots
  ##   DBInstanceIdentifier: string
  ##   SnapshotType: string
  ##   Marker: string
  ##   DBSnapshotIdentifier: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627048 = newJObject()
  var formData_21627049 = newJObject()
  add(formData_21627049, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627049, "SnapshotType", newJString(SnapshotType))
  add(formData_21627049, "Marker", newJString(Marker))
  add(formData_21627049, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21627048, "Action", newJString(Action))
  if Filters != nil:
    formData_21627049.add "Filters", Filters
  add(formData_21627049, "MaxRecords", newJInt(MaxRecords))
  add(query_21627048, "Version", newJString(Version))
  result = call_21627047.call(nil, query_21627048, nil, formData_21627049, nil)

var postDescribeDBSnapshots* = Call_PostDescribeDBSnapshots_21627028(
    name: "postDescribeDBSnapshots", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_PostDescribeDBSnapshots_21627029, base: "/",
    makeUrl: url_PostDescribeDBSnapshots_21627030,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSnapshots_21627007 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSnapshots_21627009(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSnapshots_21627008(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SnapshotType: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString
  ##   DBSnapshotIdentifier: JString
  section = newJObject()
  var valid_21627010 = query.getOrDefault("MaxRecords")
  valid_21627010 = validateParameter(valid_21627010, JInt, required = false,
                                   default = nil)
  if valid_21627010 != nil:
    section.add "MaxRecords", valid_21627010
  var valid_21627011 = query.getOrDefault("Filters")
  valid_21627011 = validateParameter(valid_21627011, JArray, required = false,
                                   default = nil)
  if valid_21627011 != nil:
    section.add "Filters", valid_21627011
  var valid_21627012 = query.getOrDefault("Action")
  valid_21627012 = validateParameter(valid_21627012, JString, required = true,
                                   default = newJString("DescribeDBSnapshots"))
  if valid_21627012 != nil:
    section.add "Action", valid_21627012
  var valid_21627013 = query.getOrDefault("Marker")
  valid_21627013 = validateParameter(valid_21627013, JString, required = false,
                                   default = nil)
  if valid_21627013 != nil:
    section.add "Marker", valid_21627013
  var valid_21627014 = query.getOrDefault("SnapshotType")
  valid_21627014 = validateParameter(valid_21627014, JString, required = false,
                                   default = nil)
  if valid_21627014 != nil:
    section.add "SnapshotType", valid_21627014
  var valid_21627015 = query.getOrDefault("Version")
  valid_21627015 = validateParameter(valid_21627015, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627015 != nil:
    section.add "Version", valid_21627015
  var valid_21627016 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627016 = validateParameter(valid_21627016, JString, required = false,
                                   default = nil)
  if valid_21627016 != nil:
    section.add "DBInstanceIdentifier", valid_21627016
  var valid_21627017 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21627017 = validateParameter(valid_21627017, JString, required = false,
                                   default = nil)
  if valid_21627017 != nil:
    section.add "DBSnapshotIdentifier", valid_21627017
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
  var valid_21627018 = header.getOrDefault("X-Amz-Date")
  valid_21627018 = validateParameter(valid_21627018, JString, required = false,
                                   default = nil)
  if valid_21627018 != nil:
    section.add "X-Amz-Date", valid_21627018
  var valid_21627019 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627019 = validateParameter(valid_21627019, JString, required = false,
                                   default = nil)
  if valid_21627019 != nil:
    section.add "X-Amz-Security-Token", valid_21627019
  var valid_21627020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627020 = validateParameter(valid_21627020, JString, required = false,
                                   default = nil)
  if valid_21627020 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627020
  var valid_21627021 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627021 = validateParameter(valid_21627021, JString, required = false,
                                   default = nil)
  if valid_21627021 != nil:
    section.add "X-Amz-Algorithm", valid_21627021
  var valid_21627022 = header.getOrDefault("X-Amz-Signature")
  valid_21627022 = validateParameter(valid_21627022, JString, required = false,
                                   default = nil)
  if valid_21627022 != nil:
    section.add "X-Amz-Signature", valid_21627022
  var valid_21627023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627023 = validateParameter(valid_21627023, JString, required = false,
                                   default = nil)
  if valid_21627023 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627023
  var valid_21627024 = header.getOrDefault("X-Amz-Credential")
  valid_21627024 = validateParameter(valid_21627024, JString, required = false,
                                   default = nil)
  if valid_21627024 != nil:
    section.add "X-Amz-Credential", valid_21627024
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627025: Call_GetDescribeDBSnapshots_21627007;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627025.validator(path, query, header, formData, body, _)
  let scheme = call_21627025.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627025.makeUrl(scheme.get, call_21627025.host, call_21627025.base,
                               call_21627025.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627025, uri, valid, _)

proc call*(call_21627026: Call_GetDescribeDBSnapshots_21627007;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBSnapshots"; Marker: string = "";
          SnapshotType: string = ""; Version: string = "2013-09-09";
          DBInstanceIdentifier: string = ""; DBSnapshotIdentifier: string = ""): Recallable =
  ## getDescribeDBSnapshots
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SnapshotType: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string
  ##   DBSnapshotIdentifier: string
  var query_21627027 = newJObject()
  add(query_21627027, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627027.add "Filters", Filters
  add(query_21627027, "Action", newJString(Action))
  add(query_21627027, "Marker", newJString(Marker))
  add(query_21627027, "SnapshotType", newJString(SnapshotType))
  add(query_21627027, "Version", newJString(Version))
  add(query_21627027, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627027, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21627026.call(nil, query_21627027, nil, nil, nil)

var getDescribeDBSnapshots* = Call_GetDescribeDBSnapshots_21627007(
    name: "getDescribeDBSnapshots", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSnapshots",
    validator: validate_GetDescribeDBSnapshots_21627008, base: "/",
    makeUrl: url_GetDescribeDBSnapshots_21627009,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDBSubnetGroups_21627069 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeDBSubnetGroups_21627071(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDBSubnetGroups_21627070(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627072 = query.getOrDefault("Action")
  valid_21627072 = validateParameter(valid_21627072, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21627072 != nil:
    section.add "Action", valid_21627072
  var valid_21627073 = query.getOrDefault("Version")
  valid_21627073 = validateParameter(valid_21627073, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627073 != nil:
    section.add "Version", valid_21627073
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
  var valid_21627074 = header.getOrDefault("X-Amz-Date")
  valid_21627074 = validateParameter(valid_21627074, JString, required = false,
                                   default = nil)
  if valid_21627074 != nil:
    section.add "X-Amz-Date", valid_21627074
  var valid_21627075 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627075 = validateParameter(valid_21627075, JString, required = false,
                                   default = nil)
  if valid_21627075 != nil:
    section.add "X-Amz-Security-Token", valid_21627075
  var valid_21627076 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627076 = validateParameter(valid_21627076, JString, required = false,
                                   default = nil)
  if valid_21627076 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627076
  var valid_21627077 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627077 = validateParameter(valid_21627077, JString, required = false,
                                   default = nil)
  if valid_21627077 != nil:
    section.add "X-Amz-Algorithm", valid_21627077
  var valid_21627078 = header.getOrDefault("X-Amz-Signature")
  valid_21627078 = validateParameter(valid_21627078, JString, required = false,
                                   default = nil)
  if valid_21627078 != nil:
    section.add "X-Amz-Signature", valid_21627078
  var valid_21627079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627079 = validateParameter(valid_21627079, JString, required = false,
                                   default = nil)
  if valid_21627079 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627079
  var valid_21627080 = header.getOrDefault("X-Amz-Credential")
  valid_21627080 = validateParameter(valid_21627080, JString, required = false,
                                   default = nil)
  if valid_21627080 != nil:
    section.add "X-Amz-Credential", valid_21627080
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString
  ##   Marker: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627081 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627081 = validateParameter(valid_21627081, JString, required = false,
                                   default = nil)
  if valid_21627081 != nil:
    section.add "DBSubnetGroupName", valid_21627081
  var valid_21627082 = formData.getOrDefault("Marker")
  valid_21627082 = validateParameter(valid_21627082, JString, required = false,
                                   default = nil)
  if valid_21627082 != nil:
    section.add "Marker", valid_21627082
  var valid_21627083 = formData.getOrDefault("Filters")
  valid_21627083 = validateParameter(valid_21627083, JArray, required = false,
                                   default = nil)
  if valid_21627083 != nil:
    section.add "Filters", valid_21627083
  var valid_21627084 = formData.getOrDefault("MaxRecords")
  valid_21627084 = validateParameter(valid_21627084, JInt, required = false,
                                   default = nil)
  if valid_21627084 != nil:
    section.add "MaxRecords", valid_21627084
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627085: Call_PostDescribeDBSubnetGroups_21627069;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627085.validator(path, query, header, formData, body, _)
  let scheme = call_21627085.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627085.makeUrl(scheme.get, call_21627085.host, call_21627085.base,
                               call_21627085.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627085, uri, valid, _)

proc call*(call_21627086: Call_PostDescribeDBSubnetGroups_21627069;
          DBSubnetGroupName: string = ""; Marker: string = "";
          Action: string = "DescribeDBSubnetGroups"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeDBSubnetGroups
  ##   DBSubnetGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627087 = newJObject()
  var formData_21627088 = newJObject()
  add(formData_21627088, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21627088, "Marker", newJString(Marker))
  add(query_21627087, "Action", newJString(Action))
  if Filters != nil:
    formData_21627088.add "Filters", Filters
  add(formData_21627088, "MaxRecords", newJInt(MaxRecords))
  add(query_21627087, "Version", newJString(Version))
  result = call_21627086.call(nil, query_21627087, nil, formData_21627088, nil)

var postDescribeDBSubnetGroups* = Call_PostDescribeDBSubnetGroups_21627069(
    name: "postDescribeDBSubnetGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_PostDescribeDBSubnetGroups_21627070, base: "/",
    makeUrl: url_PostDescribeDBSubnetGroups_21627071,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDBSubnetGroups_21627050 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeDBSubnetGroups_21627052(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDBSubnetGroups_21627051(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   DBSubnetGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627053 = query.getOrDefault("MaxRecords")
  valid_21627053 = validateParameter(valid_21627053, JInt, required = false,
                                   default = nil)
  if valid_21627053 != nil:
    section.add "MaxRecords", valid_21627053
  var valid_21627054 = query.getOrDefault("Filters")
  valid_21627054 = validateParameter(valid_21627054, JArray, required = false,
                                   default = nil)
  if valid_21627054 != nil:
    section.add "Filters", valid_21627054
  var valid_21627055 = query.getOrDefault("Action")
  valid_21627055 = validateParameter(valid_21627055, JString, required = true, default = newJString(
      "DescribeDBSubnetGroups"))
  if valid_21627055 != nil:
    section.add "Action", valid_21627055
  var valid_21627056 = query.getOrDefault("Marker")
  valid_21627056 = validateParameter(valid_21627056, JString, required = false,
                                   default = nil)
  if valid_21627056 != nil:
    section.add "Marker", valid_21627056
  var valid_21627057 = query.getOrDefault("DBSubnetGroupName")
  valid_21627057 = validateParameter(valid_21627057, JString, required = false,
                                   default = nil)
  if valid_21627057 != nil:
    section.add "DBSubnetGroupName", valid_21627057
  var valid_21627058 = query.getOrDefault("Version")
  valid_21627058 = validateParameter(valid_21627058, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627058 != nil:
    section.add "Version", valid_21627058
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
  var valid_21627059 = header.getOrDefault("X-Amz-Date")
  valid_21627059 = validateParameter(valid_21627059, JString, required = false,
                                   default = nil)
  if valid_21627059 != nil:
    section.add "X-Amz-Date", valid_21627059
  var valid_21627060 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627060 = validateParameter(valid_21627060, JString, required = false,
                                   default = nil)
  if valid_21627060 != nil:
    section.add "X-Amz-Security-Token", valid_21627060
  var valid_21627061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627061 = validateParameter(valid_21627061, JString, required = false,
                                   default = nil)
  if valid_21627061 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627061
  var valid_21627062 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627062 = validateParameter(valid_21627062, JString, required = false,
                                   default = nil)
  if valid_21627062 != nil:
    section.add "X-Amz-Algorithm", valid_21627062
  var valid_21627063 = header.getOrDefault("X-Amz-Signature")
  valid_21627063 = validateParameter(valid_21627063, JString, required = false,
                                   default = nil)
  if valid_21627063 != nil:
    section.add "X-Amz-Signature", valid_21627063
  var valid_21627064 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627064 = validateParameter(valid_21627064, JString, required = false,
                                   default = nil)
  if valid_21627064 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627064
  var valid_21627065 = header.getOrDefault("X-Amz-Credential")
  valid_21627065 = validateParameter(valid_21627065, JString, required = false,
                                   default = nil)
  if valid_21627065 != nil:
    section.add "X-Amz-Credential", valid_21627065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627066: Call_GetDescribeDBSubnetGroups_21627050;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627066.validator(path, query, header, formData, body, _)
  let scheme = call_21627066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627066.makeUrl(scheme.get, call_21627066.host, call_21627066.base,
                               call_21627066.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627066, uri, valid, _)

proc call*(call_21627067: Call_GetDescribeDBSubnetGroups_21627050;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeDBSubnetGroups"; Marker: string = "";
          DBSubnetGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeDBSubnetGroups
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   DBSubnetGroupName: string
  ##   Version: string (required)
  var query_21627068 = newJObject()
  add(query_21627068, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627068.add "Filters", Filters
  add(query_21627068, "Action", newJString(Action))
  add(query_21627068, "Marker", newJString(Marker))
  add(query_21627068, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21627068, "Version", newJString(Version))
  result = call_21627067.call(nil, query_21627068, nil, nil, nil)

var getDescribeDBSubnetGroups* = Call_GetDescribeDBSubnetGroups_21627050(
    name: "getDescribeDBSubnetGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeDBSubnetGroups",
    validator: validate_GetDescribeDBSubnetGroups_21627051, base: "/",
    makeUrl: url_GetDescribeDBSubnetGroups_21627052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEngineDefaultParameters_21627108 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEngineDefaultParameters_21627110(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEngineDefaultParameters_21627109(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627111 = query.getOrDefault("Action")
  valid_21627111 = validateParameter(valid_21627111, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627111 != nil:
    section.add "Action", valid_21627111
  var valid_21627112 = query.getOrDefault("Version")
  valid_21627112 = validateParameter(valid_21627112, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627112 != nil:
    section.add "Version", valid_21627112
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
  var valid_21627113 = header.getOrDefault("X-Amz-Date")
  valid_21627113 = validateParameter(valid_21627113, JString, required = false,
                                   default = nil)
  if valid_21627113 != nil:
    section.add "X-Amz-Date", valid_21627113
  var valid_21627114 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627114 = validateParameter(valid_21627114, JString, required = false,
                                   default = nil)
  if valid_21627114 != nil:
    section.add "X-Amz-Security-Token", valid_21627114
  var valid_21627115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627115 = validateParameter(valid_21627115, JString, required = false,
                                   default = nil)
  if valid_21627115 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627115
  var valid_21627116 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627116 = validateParameter(valid_21627116, JString, required = false,
                                   default = nil)
  if valid_21627116 != nil:
    section.add "X-Amz-Algorithm", valid_21627116
  var valid_21627117 = header.getOrDefault("X-Amz-Signature")
  valid_21627117 = validateParameter(valid_21627117, JString, required = false,
                                   default = nil)
  if valid_21627117 != nil:
    section.add "X-Amz-Signature", valid_21627117
  var valid_21627118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627118 = validateParameter(valid_21627118, JString, required = false,
                                   default = nil)
  if valid_21627118 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627118
  var valid_21627119 = header.getOrDefault("X-Amz-Credential")
  valid_21627119 = validateParameter(valid_21627119, JString, required = false,
                                   default = nil)
  if valid_21627119 != nil:
    section.add "X-Amz-Credential", valid_21627119
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627120 = formData.getOrDefault("Marker")
  valid_21627120 = validateParameter(valid_21627120, JString, required = false,
                                   default = nil)
  if valid_21627120 != nil:
    section.add "Marker", valid_21627120
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627121 = formData.getOrDefault("DBParameterGroupFamily")
  valid_21627121 = validateParameter(valid_21627121, JString, required = true,
                                   default = nil)
  if valid_21627121 != nil:
    section.add "DBParameterGroupFamily", valid_21627121
  var valid_21627122 = formData.getOrDefault("Filters")
  valid_21627122 = validateParameter(valid_21627122, JArray, required = false,
                                   default = nil)
  if valid_21627122 != nil:
    section.add "Filters", valid_21627122
  var valid_21627123 = formData.getOrDefault("MaxRecords")
  valid_21627123 = validateParameter(valid_21627123, JInt, required = false,
                                   default = nil)
  if valid_21627123 != nil:
    section.add "MaxRecords", valid_21627123
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627124: Call_PostDescribeEngineDefaultParameters_21627108;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627124.validator(path, query, header, formData, body, _)
  let scheme = call_21627124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627124.makeUrl(scheme.get, call_21627124.host, call_21627124.base,
                               call_21627124.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627124, uri, valid, _)

proc call*(call_21627125: Call_PostDescribeEngineDefaultParameters_21627108;
          DBParameterGroupFamily: string; Marker: string = "";
          Action: string = "DescribeEngineDefaultParameters";
          Filters: JsonNode = nil; MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEngineDefaultParameters
  ##   Marker: string
  ##   Action: string (required)
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627126 = newJObject()
  var formData_21627127 = newJObject()
  add(formData_21627127, "Marker", newJString(Marker))
  add(query_21627126, "Action", newJString(Action))
  add(formData_21627127, "DBParameterGroupFamily",
      newJString(DBParameterGroupFamily))
  if Filters != nil:
    formData_21627127.add "Filters", Filters
  add(formData_21627127, "MaxRecords", newJInt(MaxRecords))
  add(query_21627126, "Version", newJString(Version))
  result = call_21627125.call(nil, query_21627126, nil, formData_21627127, nil)

var postDescribeEngineDefaultParameters* = Call_PostDescribeEngineDefaultParameters_21627108(
    name: "postDescribeEngineDefaultParameters", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_PostDescribeEngineDefaultParameters_21627109, base: "/",
    makeUrl: url_PostDescribeEngineDefaultParameters_21627110,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEngineDefaultParameters_21627089 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEngineDefaultParameters_21627091(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEngineDefaultParameters_21627090(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   DBParameterGroupFamily: JString (required)
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627092 = query.getOrDefault("MaxRecords")
  valid_21627092 = validateParameter(valid_21627092, JInt, required = false,
                                   default = nil)
  if valid_21627092 != nil:
    section.add "MaxRecords", valid_21627092
  assert query != nil, "query argument is necessary due to required `DBParameterGroupFamily` field"
  var valid_21627093 = query.getOrDefault("DBParameterGroupFamily")
  valid_21627093 = validateParameter(valid_21627093, JString, required = true,
                                   default = nil)
  if valid_21627093 != nil:
    section.add "DBParameterGroupFamily", valid_21627093
  var valid_21627094 = query.getOrDefault("Filters")
  valid_21627094 = validateParameter(valid_21627094, JArray, required = false,
                                   default = nil)
  if valid_21627094 != nil:
    section.add "Filters", valid_21627094
  var valid_21627095 = query.getOrDefault("Action")
  valid_21627095 = validateParameter(valid_21627095, JString, required = true, default = newJString(
      "DescribeEngineDefaultParameters"))
  if valid_21627095 != nil:
    section.add "Action", valid_21627095
  var valid_21627096 = query.getOrDefault("Marker")
  valid_21627096 = validateParameter(valid_21627096, JString, required = false,
                                   default = nil)
  if valid_21627096 != nil:
    section.add "Marker", valid_21627096
  var valid_21627097 = query.getOrDefault("Version")
  valid_21627097 = validateParameter(valid_21627097, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627097 != nil:
    section.add "Version", valid_21627097
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
  var valid_21627098 = header.getOrDefault("X-Amz-Date")
  valid_21627098 = validateParameter(valid_21627098, JString, required = false,
                                   default = nil)
  if valid_21627098 != nil:
    section.add "X-Amz-Date", valid_21627098
  var valid_21627099 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627099 = validateParameter(valid_21627099, JString, required = false,
                                   default = nil)
  if valid_21627099 != nil:
    section.add "X-Amz-Security-Token", valid_21627099
  var valid_21627100 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627100 = validateParameter(valid_21627100, JString, required = false,
                                   default = nil)
  if valid_21627100 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627100
  var valid_21627101 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627101 = validateParameter(valid_21627101, JString, required = false,
                                   default = nil)
  if valid_21627101 != nil:
    section.add "X-Amz-Algorithm", valid_21627101
  var valid_21627102 = header.getOrDefault("X-Amz-Signature")
  valid_21627102 = validateParameter(valid_21627102, JString, required = false,
                                   default = nil)
  if valid_21627102 != nil:
    section.add "X-Amz-Signature", valid_21627102
  var valid_21627103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627103 = validateParameter(valid_21627103, JString, required = false,
                                   default = nil)
  if valid_21627103 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627103
  var valid_21627104 = header.getOrDefault("X-Amz-Credential")
  valid_21627104 = validateParameter(valid_21627104, JString, required = false,
                                   default = nil)
  if valid_21627104 != nil:
    section.add "X-Amz-Credential", valid_21627104
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627105: Call_GetDescribeEngineDefaultParameters_21627089;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627105.validator(path, query, header, formData, body, _)
  let scheme = call_21627105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627105.makeUrl(scheme.get, call_21627105.host, call_21627105.base,
                               call_21627105.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627105, uri, valid, _)

proc call*(call_21627106: Call_GetDescribeEngineDefaultParameters_21627089;
          DBParameterGroupFamily: string; MaxRecords: int = 0;
          Filters: JsonNode = nil;
          Action: string = "DescribeEngineDefaultParameters"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeEngineDefaultParameters
  ##   MaxRecords: int
  ##   DBParameterGroupFamily: string (required)
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  var query_21627107 = newJObject()
  add(query_21627107, "MaxRecords", newJInt(MaxRecords))
  add(query_21627107, "DBParameterGroupFamily", newJString(DBParameterGroupFamily))
  if Filters != nil:
    query_21627107.add "Filters", Filters
  add(query_21627107, "Action", newJString(Action))
  add(query_21627107, "Marker", newJString(Marker))
  add(query_21627107, "Version", newJString(Version))
  result = call_21627106.call(nil, query_21627107, nil, nil, nil)

var getDescribeEngineDefaultParameters* = Call_GetDescribeEngineDefaultParameters_21627089(
    name: "getDescribeEngineDefaultParameters", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEngineDefaultParameters",
    validator: validate_GetDescribeEngineDefaultParameters_21627090, base: "/",
    makeUrl: url_GetDescribeEngineDefaultParameters_21627091,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventCategories_21627145 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventCategories_21627147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventCategories_21627146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627148 = query.getOrDefault("Action")
  valid_21627148 = validateParameter(valid_21627148, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627148 != nil:
    section.add "Action", valid_21627148
  var valid_21627149 = query.getOrDefault("Version")
  valid_21627149 = validateParameter(valid_21627149, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627149 != nil:
    section.add "Version", valid_21627149
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
  var valid_21627150 = header.getOrDefault("X-Amz-Date")
  valid_21627150 = validateParameter(valid_21627150, JString, required = false,
                                   default = nil)
  if valid_21627150 != nil:
    section.add "X-Amz-Date", valid_21627150
  var valid_21627151 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627151 = validateParameter(valid_21627151, JString, required = false,
                                   default = nil)
  if valid_21627151 != nil:
    section.add "X-Amz-Security-Token", valid_21627151
  var valid_21627152 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627152 = validateParameter(valid_21627152, JString, required = false,
                                   default = nil)
  if valid_21627152 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627152
  var valid_21627153 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627153 = validateParameter(valid_21627153, JString, required = false,
                                   default = nil)
  if valid_21627153 != nil:
    section.add "X-Amz-Algorithm", valid_21627153
  var valid_21627154 = header.getOrDefault("X-Amz-Signature")
  valid_21627154 = validateParameter(valid_21627154, JString, required = false,
                                   default = nil)
  if valid_21627154 != nil:
    section.add "X-Amz-Signature", valid_21627154
  var valid_21627155 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627155 = validateParameter(valid_21627155, JString, required = false,
                                   default = nil)
  if valid_21627155 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627155
  var valid_21627156 = header.getOrDefault("X-Amz-Credential")
  valid_21627156 = validateParameter(valid_21627156, JString, required = false,
                                   default = nil)
  if valid_21627156 != nil:
    section.add "X-Amz-Credential", valid_21627156
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   SourceType: JString
  section = newJObject()
  var valid_21627157 = formData.getOrDefault("Filters")
  valid_21627157 = validateParameter(valid_21627157, JArray, required = false,
                                   default = nil)
  if valid_21627157 != nil:
    section.add "Filters", valid_21627157
  var valid_21627158 = formData.getOrDefault("SourceType")
  valid_21627158 = validateParameter(valid_21627158, JString, required = false,
                                   default = nil)
  if valid_21627158 != nil:
    section.add "SourceType", valid_21627158
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627159: Call_PostDescribeEventCategories_21627145;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627159.validator(path, query, header, formData, body, _)
  let scheme = call_21627159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627159.makeUrl(scheme.get, call_21627159.host, call_21627159.base,
                               call_21627159.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627159, uri, valid, _)

proc call*(call_21627160: Call_PostDescribeEventCategories_21627145;
          Action: string = "DescribeEventCategories"; Filters: JsonNode = nil;
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postDescribeEventCategories
  ##   Action: string (required)
  ##   Filters: JArray
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627161 = newJObject()
  var formData_21627162 = newJObject()
  add(query_21627161, "Action", newJString(Action))
  if Filters != nil:
    formData_21627162.add "Filters", Filters
  add(query_21627161, "Version", newJString(Version))
  add(formData_21627162, "SourceType", newJString(SourceType))
  result = call_21627160.call(nil, query_21627161, nil, formData_21627162, nil)

var postDescribeEventCategories* = Call_PostDescribeEventCategories_21627145(
    name: "postDescribeEventCategories", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_PostDescribeEventCategories_21627146, base: "/",
    makeUrl: url_PostDescribeEventCategories_21627147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventCategories_21627128 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventCategories_21627130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventCategories_21627129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627131 = query.getOrDefault("SourceType")
  valid_21627131 = validateParameter(valid_21627131, JString, required = false,
                                   default = nil)
  if valid_21627131 != nil:
    section.add "SourceType", valid_21627131
  var valid_21627132 = query.getOrDefault("Filters")
  valid_21627132 = validateParameter(valid_21627132, JArray, required = false,
                                   default = nil)
  if valid_21627132 != nil:
    section.add "Filters", valid_21627132
  var valid_21627133 = query.getOrDefault("Action")
  valid_21627133 = validateParameter(valid_21627133, JString, required = true, default = newJString(
      "DescribeEventCategories"))
  if valid_21627133 != nil:
    section.add "Action", valid_21627133
  var valid_21627134 = query.getOrDefault("Version")
  valid_21627134 = validateParameter(valid_21627134, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627134 != nil:
    section.add "Version", valid_21627134
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
  var valid_21627135 = header.getOrDefault("X-Amz-Date")
  valid_21627135 = validateParameter(valid_21627135, JString, required = false,
                                   default = nil)
  if valid_21627135 != nil:
    section.add "X-Amz-Date", valid_21627135
  var valid_21627136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627136 = validateParameter(valid_21627136, JString, required = false,
                                   default = nil)
  if valid_21627136 != nil:
    section.add "X-Amz-Security-Token", valid_21627136
  var valid_21627137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627137 = validateParameter(valid_21627137, JString, required = false,
                                   default = nil)
  if valid_21627137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627137
  var valid_21627138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627138 = validateParameter(valid_21627138, JString, required = false,
                                   default = nil)
  if valid_21627138 != nil:
    section.add "X-Amz-Algorithm", valid_21627138
  var valid_21627139 = header.getOrDefault("X-Amz-Signature")
  valid_21627139 = validateParameter(valid_21627139, JString, required = false,
                                   default = nil)
  if valid_21627139 != nil:
    section.add "X-Amz-Signature", valid_21627139
  var valid_21627140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627140 = validateParameter(valid_21627140, JString, required = false,
                                   default = nil)
  if valid_21627140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627140
  var valid_21627141 = header.getOrDefault("X-Amz-Credential")
  valid_21627141 = validateParameter(valid_21627141, JString, required = false,
                                   default = nil)
  if valid_21627141 != nil:
    section.add "X-Amz-Credential", valid_21627141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627142: Call_GetDescribeEventCategories_21627128;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627142.validator(path, query, header, formData, body, _)
  let scheme = call_21627142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627142.makeUrl(scheme.get, call_21627142.host, call_21627142.base,
                               call_21627142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627142, uri, valid, _)

proc call*(call_21627143: Call_GetDescribeEventCategories_21627128;
          SourceType: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEventCategories"; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventCategories
  ##   SourceType: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627144 = newJObject()
  add(query_21627144, "SourceType", newJString(SourceType))
  if Filters != nil:
    query_21627144.add "Filters", Filters
  add(query_21627144, "Action", newJString(Action))
  add(query_21627144, "Version", newJString(Version))
  result = call_21627143.call(nil, query_21627144, nil, nil, nil)

var getDescribeEventCategories* = Call_GetDescribeEventCategories_21627128(
    name: "getDescribeEventCategories", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventCategories",
    validator: validate_GetDescribeEventCategories_21627129, base: "/",
    makeUrl: url_GetDescribeEventCategories_21627130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEventSubscriptions_21627182 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEventSubscriptions_21627184(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEventSubscriptions_21627183(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627185 = query.getOrDefault("Action")
  valid_21627185 = validateParameter(valid_21627185, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627185 != nil:
    section.add "Action", valid_21627185
  var valid_21627186 = query.getOrDefault("Version")
  valid_21627186 = validateParameter(valid_21627186, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627186 != nil:
    section.add "Version", valid_21627186
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
  var valid_21627187 = header.getOrDefault("X-Amz-Date")
  valid_21627187 = validateParameter(valid_21627187, JString, required = false,
                                   default = nil)
  if valid_21627187 != nil:
    section.add "X-Amz-Date", valid_21627187
  var valid_21627188 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627188 = validateParameter(valid_21627188, JString, required = false,
                                   default = nil)
  if valid_21627188 != nil:
    section.add "X-Amz-Security-Token", valid_21627188
  var valid_21627189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627189 = validateParameter(valid_21627189, JString, required = false,
                                   default = nil)
  if valid_21627189 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627189
  var valid_21627190 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627190 = validateParameter(valid_21627190, JString, required = false,
                                   default = nil)
  if valid_21627190 != nil:
    section.add "X-Amz-Algorithm", valid_21627190
  var valid_21627191 = header.getOrDefault("X-Amz-Signature")
  valid_21627191 = validateParameter(valid_21627191, JString, required = false,
                                   default = nil)
  if valid_21627191 != nil:
    section.add "X-Amz-Signature", valid_21627191
  var valid_21627192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627192 = validateParameter(valid_21627192, JString, required = false,
                                   default = nil)
  if valid_21627192 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627192
  var valid_21627193 = header.getOrDefault("X-Amz-Credential")
  valid_21627193 = validateParameter(valid_21627193, JString, required = false,
                                   default = nil)
  if valid_21627193 != nil:
    section.add "X-Amz-Credential", valid_21627193
  result.add "header", section
  ## parameters in `formData` object:
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627194 = formData.getOrDefault("Marker")
  valid_21627194 = validateParameter(valid_21627194, JString, required = false,
                                   default = nil)
  if valid_21627194 != nil:
    section.add "Marker", valid_21627194
  var valid_21627195 = formData.getOrDefault("SubscriptionName")
  valid_21627195 = validateParameter(valid_21627195, JString, required = false,
                                   default = nil)
  if valid_21627195 != nil:
    section.add "SubscriptionName", valid_21627195
  var valid_21627196 = formData.getOrDefault("Filters")
  valid_21627196 = validateParameter(valid_21627196, JArray, required = false,
                                   default = nil)
  if valid_21627196 != nil:
    section.add "Filters", valid_21627196
  var valid_21627197 = formData.getOrDefault("MaxRecords")
  valid_21627197 = validateParameter(valid_21627197, JInt, required = false,
                                   default = nil)
  if valid_21627197 != nil:
    section.add "MaxRecords", valid_21627197
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627198: Call_PostDescribeEventSubscriptions_21627182;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627198.validator(path, query, header, formData, body, _)
  let scheme = call_21627198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627198.makeUrl(scheme.get, call_21627198.host, call_21627198.base,
                               call_21627198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627198, uri, valid, _)

proc call*(call_21627199: Call_PostDescribeEventSubscriptions_21627182;
          Marker: string = ""; SubscriptionName: string = "";
          Action: string = "DescribeEventSubscriptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeEventSubscriptions
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Action: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627200 = newJObject()
  var formData_21627201 = newJObject()
  add(formData_21627201, "Marker", newJString(Marker))
  add(formData_21627201, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627200, "Action", newJString(Action))
  if Filters != nil:
    formData_21627201.add "Filters", Filters
  add(formData_21627201, "MaxRecords", newJInt(MaxRecords))
  add(query_21627200, "Version", newJString(Version))
  result = call_21627199.call(nil, query_21627200, nil, formData_21627201, nil)

var postDescribeEventSubscriptions* = Call_PostDescribeEventSubscriptions_21627182(
    name: "postDescribeEventSubscriptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_PostDescribeEventSubscriptions_21627183, base: "/",
    makeUrl: url_PostDescribeEventSubscriptions_21627184,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEventSubscriptions_21627163 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEventSubscriptions_21627165(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEventSubscriptions_21627164(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   SubscriptionName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627166 = query.getOrDefault("MaxRecords")
  valid_21627166 = validateParameter(valid_21627166, JInt, required = false,
                                   default = nil)
  if valid_21627166 != nil:
    section.add "MaxRecords", valid_21627166
  var valid_21627167 = query.getOrDefault("Filters")
  valid_21627167 = validateParameter(valid_21627167, JArray, required = false,
                                   default = nil)
  if valid_21627167 != nil:
    section.add "Filters", valid_21627167
  var valid_21627168 = query.getOrDefault("Action")
  valid_21627168 = validateParameter(valid_21627168, JString, required = true, default = newJString(
      "DescribeEventSubscriptions"))
  if valid_21627168 != nil:
    section.add "Action", valid_21627168
  var valid_21627169 = query.getOrDefault("Marker")
  valid_21627169 = validateParameter(valid_21627169, JString, required = false,
                                   default = nil)
  if valid_21627169 != nil:
    section.add "Marker", valid_21627169
  var valid_21627170 = query.getOrDefault("SubscriptionName")
  valid_21627170 = validateParameter(valid_21627170, JString, required = false,
                                   default = nil)
  if valid_21627170 != nil:
    section.add "SubscriptionName", valid_21627170
  var valid_21627171 = query.getOrDefault("Version")
  valid_21627171 = validateParameter(valid_21627171, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627171 != nil:
    section.add "Version", valid_21627171
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
  var valid_21627172 = header.getOrDefault("X-Amz-Date")
  valid_21627172 = validateParameter(valid_21627172, JString, required = false,
                                   default = nil)
  if valid_21627172 != nil:
    section.add "X-Amz-Date", valid_21627172
  var valid_21627173 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627173 = validateParameter(valid_21627173, JString, required = false,
                                   default = nil)
  if valid_21627173 != nil:
    section.add "X-Amz-Security-Token", valid_21627173
  var valid_21627174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627174 = validateParameter(valid_21627174, JString, required = false,
                                   default = nil)
  if valid_21627174 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627174
  var valid_21627175 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627175 = validateParameter(valid_21627175, JString, required = false,
                                   default = nil)
  if valid_21627175 != nil:
    section.add "X-Amz-Algorithm", valid_21627175
  var valid_21627176 = header.getOrDefault("X-Amz-Signature")
  valid_21627176 = validateParameter(valid_21627176, JString, required = false,
                                   default = nil)
  if valid_21627176 != nil:
    section.add "X-Amz-Signature", valid_21627176
  var valid_21627177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627177 = validateParameter(valid_21627177, JString, required = false,
                                   default = nil)
  if valid_21627177 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627177
  var valid_21627178 = header.getOrDefault("X-Amz-Credential")
  valid_21627178 = validateParameter(valid_21627178, JString, required = false,
                                   default = nil)
  if valid_21627178 != nil:
    section.add "X-Amz-Credential", valid_21627178
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627179: Call_GetDescribeEventSubscriptions_21627163;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627179.validator(path, query, header, formData, body, _)
  let scheme = call_21627179.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627179.makeUrl(scheme.get, call_21627179.host, call_21627179.base,
                               call_21627179.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627179, uri, valid, _)

proc call*(call_21627180: Call_GetDescribeEventSubscriptions_21627163;
          MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeEventSubscriptions"; Marker: string = "";
          SubscriptionName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEventSubscriptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   SubscriptionName: string
  ##   Version: string (required)
  var query_21627181 = newJObject()
  add(query_21627181, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627181.add "Filters", Filters
  add(query_21627181, "Action", newJString(Action))
  add(query_21627181, "Marker", newJString(Marker))
  add(query_21627181, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627181, "Version", newJString(Version))
  result = call_21627180.call(nil, query_21627181, nil, nil, nil)

var getDescribeEventSubscriptions* = Call_GetDescribeEventSubscriptions_21627163(
    name: "getDescribeEventSubscriptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEventSubscriptions",
    validator: validate_GetDescribeEventSubscriptions_21627164, base: "/",
    makeUrl: url_GetDescribeEventSubscriptions_21627165,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeEvents_21627226 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeEvents_21627228(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeEvents_21627227(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627229 = query.getOrDefault("Action")
  valid_21627229 = validateParameter(valid_21627229, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627229 != nil:
    section.add "Action", valid_21627229
  var valid_21627230 = query.getOrDefault("Version")
  valid_21627230 = validateParameter(valid_21627230, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627230 != nil:
    section.add "Version", valid_21627230
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
  var valid_21627231 = header.getOrDefault("X-Amz-Date")
  valid_21627231 = validateParameter(valid_21627231, JString, required = false,
                                   default = nil)
  if valid_21627231 != nil:
    section.add "X-Amz-Date", valid_21627231
  var valid_21627232 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627232 = validateParameter(valid_21627232, JString, required = false,
                                   default = nil)
  if valid_21627232 != nil:
    section.add "X-Amz-Security-Token", valid_21627232
  var valid_21627233 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627233 = validateParameter(valid_21627233, JString, required = false,
                                   default = nil)
  if valid_21627233 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627233
  var valid_21627234 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627234 = validateParameter(valid_21627234, JString, required = false,
                                   default = nil)
  if valid_21627234 != nil:
    section.add "X-Amz-Algorithm", valid_21627234
  var valid_21627235 = header.getOrDefault("X-Amz-Signature")
  valid_21627235 = validateParameter(valid_21627235, JString, required = false,
                                   default = nil)
  if valid_21627235 != nil:
    section.add "X-Amz-Signature", valid_21627235
  var valid_21627236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627236 = validateParameter(valid_21627236, JString, required = false,
                                   default = nil)
  if valid_21627236 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627236
  var valid_21627237 = header.getOrDefault("X-Amz-Credential")
  valid_21627237 = validateParameter(valid_21627237, JString, required = false,
                                   default = nil)
  if valid_21627237 != nil:
    section.add "X-Amz-Credential", valid_21627237
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString
  ##   EventCategories: JArray
  ##   Marker: JString
  ##   StartTime: JString
  ##   Duration: JInt
  ##   Filters: JArray
  ##   EndTime: JString
  ##   MaxRecords: JInt
  ##   SourceType: JString
  section = newJObject()
  var valid_21627238 = formData.getOrDefault("SourceIdentifier")
  valid_21627238 = validateParameter(valid_21627238, JString, required = false,
                                   default = nil)
  if valid_21627238 != nil:
    section.add "SourceIdentifier", valid_21627238
  var valid_21627239 = formData.getOrDefault("EventCategories")
  valid_21627239 = validateParameter(valid_21627239, JArray, required = false,
                                   default = nil)
  if valid_21627239 != nil:
    section.add "EventCategories", valid_21627239
  var valid_21627240 = formData.getOrDefault("Marker")
  valid_21627240 = validateParameter(valid_21627240, JString, required = false,
                                   default = nil)
  if valid_21627240 != nil:
    section.add "Marker", valid_21627240
  var valid_21627241 = formData.getOrDefault("StartTime")
  valid_21627241 = validateParameter(valid_21627241, JString, required = false,
                                   default = nil)
  if valid_21627241 != nil:
    section.add "StartTime", valid_21627241
  var valid_21627242 = formData.getOrDefault("Duration")
  valid_21627242 = validateParameter(valid_21627242, JInt, required = false,
                                   default = nil)
  if valid_21627242 != nil:
    section.add "Duration", valid_21627242
  var valid_21627243 = formData.getOrDefault("Filters")
  valid_21627243 = validateParameter(valid_21627243, JArray, required = false,
                                   default = nil)
  if valid_21627243 != nil:
    section.add "Filters", valid_21627243
  var valid_21627244 = formData.getOrDefault("EndTime")
  valid_21627244 = validateParameter(valid_21627244, JString, required = false,
                                   default = nil)
  if valid_21627244 != nil:
    section.add "EndTime", valid_21627244
  var valid_21627245 = formData.getOrDefault("MaxRecords")
  valid_21627245 = validateParameter(valid_21627245, JInt, required = false,
                                   default = nil)
  if valid_21627245 != nil:
    section.add "MaxRecords", valid_21627245
  var valid_21627246 = formData.getOrDefault("SourceType")
  valid_21627246 = validateParameter(valid_21627246, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627246 != nil:
    section.add "SourceType", valid_21627246
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627247: Call_PostDescribeEvents_21627226; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627247.validator(path, query, header, formData, body, _)
  let scheme = call_21627247.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627247.makeUrl(scheme.get, call_21627247.host, call_21627247.base,
                               call_21627247.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627247, uri, valid, _)

proc call*(call_21627248: Call_PostDescribeEvents_21627226;
          SourceIdentifier: string = ""; EventCategories: JsonNode = nil;
          Marker: string = ""; StartTime: string = "";
          Action: string = "DescribeEvents"; Duration: int = 0; Filters: JsonNode = nil;
          EndTime: string = ""; MaxRecords: int = 0; Version: string = "2013-09-09";
          SourceType: string = "db-instance"): Recallable =
  ## postDescribeEvents
  ##   SourceIdentifier: string
  ##   EventCategories: JArray
  ##   Marker: string
  ##   StartTime: string
  ##   Action: string (required)
  ##   Duration: int
  ##   Filters: JArray
  ##   EndTime: string
  ##   MaxRecords: int
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627249 = newJObject()
  var formData_21627250 = newJObject()
  add(formData_21627250, "SourceIdentifier", newJString(SourceIdentifier))
  if EventCategories != nil:
    formData_21627250.add "EventCategories", EventCategories
  add(formData_21627250, "Marker", newJString(Marker))
  add(formData_21627250, "StartTime", newJString(StartTime))
  add(query_21627249, "Action", newJString(Action))
  add(formData_21627250, "Duration", newJInt(Duration))
  if Filters != nil:
    formData_21627250.add "Filters", Filters
  add(formData_21627250, "EndTime", newJString(EndTime))
  add(formData_21627250, "MaxRecords", newJInt(MaxRecords))
  add(query_21627249, "Version", newJString(Version))
  add(formData_21627250, "SourceType", newJString(SourceType))
  result = call_21627248.call(nil, query_21627249, nil, formData_21627250, nil)

var postDescribeEvents* = Call_PostDescribeEvents_21627226(
    name: "postDescribeEvents", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeEvents",
    validator: validate_PostDescribeEvents_21627227, base: "/",
    makeUrl: url_PostDescribeEvents_21627228, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeEvents_21627202 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeEvents_21627204(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeEvents_21627203(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   MaxRecords: JInt
  ##   StartTime: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   SourceIdentifier: JString
  ##   Marker: JString
  ##   EventCategories: JArray
  ##   Duration: JInt
  ##   EndTime: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627205 = query.getOrDefault("SourceType")
  valid_21627205 = validateParameter(valid_21627205, JString, required = false,
                                   default = newJString("db-instance"))
  if valid_21627205 != nil:
    section.add "SourceType", valid_21627205
  var valid_21627206 = query.getOrDefault("MaxRecords")
  valid_21627206 = validateParameter(valid_21627206, JInt, required = false,
                                   default = nil)
  if valid_21627206 != nil:
    section.add "MaxRecords", valid_21627206
  var valid_21627207 = query.getOrDefault("StartTime")
  valid_21627207 = validateParameter(valid_21627207, JString, required = false,
                                   default = nil)
  if valid_21627207 != nil:
    section.add "StartTime", valid_21627207
  var valid_21627208 = query.getOrDefault("Filters")
  valid_21627208 = validateParameter(valid_21627208, JArray, required = false,
                                   default = nil)
  if valid_21627208 != nil:
    section.add "Filters", valid_21627208
  var valid_21627209 = query.getOrDefault("Action")
  valid_21627209 = validateParameter(valid_21627209, JString, required = true,
                                   default = newJString("DescribeEvents"))
  if valid_21627209 != nil:
    section.add "Action", valid_21627209
  var valid_21627210 = query.getOrDefault("SourceIdentifier")
  valid_21627210 = validateParameter(valid_21627210, JString, required = false,
                                   default = nil)
  if valid_21627210 != nil:
    section.add "SourceIdentifier", valid_21627210
  var valid_21627211 = query.getOrDefault("Marker")
  valid_21627211 = validateParameter(valid_21627211, JString, required = false,
                                   default = nil)
  if valid_21627211 != nil:
    section.add "Marker", valid_21627211
  var valid_21627212 = query.getOrDefault("EventCategories")
  valid_21627212 = validateParameter(valid_21627212, JArray, required = false,
                                   default = nil)
  if valid_21627212 != nil:
    section.add "EventCategories", valid_21627212
  var valid_21627213 = query.getOrDefault("Duration")
  valid_21627213 = validateParameter(valid_21627213, JInt, required = false,
                                   default = nil)
  if valid_21627213 != nil:
    section.add "Duration", valid_21627213
  var valid_21627214 = query.getOrDefault("EndTime")
  valid_21627214 = validateParameter(valid_21627214, JString, required = false,
                                   default = nil)
  if valid_21627214 != nil:
    section.add "EndTime", valid_21627214
  var valid_21627215 = query.getOrDefault("Version")
  valid_21627215 = validateParameter(valid_21627215, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627215 != nil:
    section.add "Version", valid_21627215
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
  var valid_21627216 = header.getOrDefault("X-Amz-Date")
  valid_21627216 = validateParameter(valid_21627216, JString, required = false,
                                   default = nil)
  if valid_21627216 != nil:
    section.add "X-Amz-Date", valid_21627216
  var valid_21627217 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627217 = validateParameter(valid_21627217, JString, required = false,
                                   default = nil)
  if valid_21627217 != nil:
    section.add "X-Amz-Security-Token", valid_21627217
  var valid_21627218 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627218 = validateParameter(valid_21627218, JString, required = false,
                                   default = nil)
  if valid_21627218 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627218
  var valid_21627219 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627219 = validateParameter(valid_21627219, JString, required = false,
                                   default = nil)
  if valid_21627219 != nil:
    section.add "X-Amz-Algorithm", valid_21627219
  var valid_21627220 = header.getOrDefault("X-Amz-Signature")
  valid_21627220 = validateParameter(valid_21627220, JString, required = false,
                                   default = nil)
  if valid_21627220 != nil:
    section.add "X-Amz-Signature", valid_21627220
  var valid_21627221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627221 = validateParameter(valid_21627221, JString, required = false,
                                   default = nil)
  if valid_21627221 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627221
  var valid_21627222 = header.getOrDefault("X-Amz-Credential")
  valid_21627222 = validateParameter(valid_21627222, JString, required = false,
                                   default = nil)
  if valid_21627222 != nil:
    section.add "X-Amz-Credential", valid_21627222
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627223: Call_GetDescribeEvents_21627202; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627223.validator(path, query, header, formData, body, _)
  let scheme = call_21627223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627223.makeUrl(scheme.get, call_21627223.host, call_21627223.base,
                               call_21627223.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627223, uri, valid, _)

proc call*(call_21627224: Call_GetDescribeEvents_21627202;
          SourceType: string = "db-instance"; MaxRecords: int = 0;
          StartTime: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeEvents"; SourceIdentifier: string = "";
          Marker: string = ""; EventCategories: JsonNode = nil; Duration: int = 0;
          EndTime: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeEvents
  ##   SourceType: string
  ##   MaxRecords: int
  ##   StartTime: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   SourceIdentifier: string
  ##   Marker: string
  ##   EventCategories: JArray
  ##   Duration: int
  ##   EndTime: string
  ##   Version: string (required)
  var query_21627225 = newJObject()
  add(query_21627225, "SourceType", newJString(SourceType))
  add(query_21627225, "MaxRecords", newJInt(MaxRecords))
  add(query_21627225, "StartTime", newJString(StartTime))
  if Filters != nil:
    query_21627225.add "Filters", Filters
  add(query_21627225, "Action", newJString(Action))
  add(query_21627225, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627225, "Marker", newJString(Marker))
  if EventCategories != nil:
    query_21627225.add "EventCategories", EventCategories
  add(query_21627225, "Duration", newJInt(Duration))
  add(query_21627225, "EndTime", newJString(EndTime))
  add(query_21627225, "Version", newJString(Version))
  result = call_21627224.call(nil, query_21627225, nil, nil, nil)

var getDescribeEvents* = Call_GetDescribeEvents_21627202(name: "getDescribeEvents",
    meth: HttpMethod.HttpGet, host: "rds.amazonaws.com",
    route: "/#Action=DescribeEvents", validator: validate_GetDescribeEvents_21627203,
    base: "/", makeUrl: url_GetDescribeEvents_21627204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroupOptions_21627271 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroupOptions_21627273(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroupOptions_21627272(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627274 = query.getOrDefault("Action")
  valid_21627274 = validateParameter(valid_21627274, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627274 != nil:
    section.add "Action", valid_21627274
  var valid_21627275 = query.getOrDefault("Version")
  valid_21627275 = validateParameter(valid_21627275, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627275 != nil:
    section.add "Version", valid_21627275
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
  var valid_21627276 = header.getOrDefault("X-Amz-Date")
  valid_21627276 = validateParameter(valid_21627276, JString, required = false,
                                   default = nil)
  if valid_21627276 != nil:
    section.add "X-Amz-Date", valid_21627276
  var valid_21627277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627277 = validateParameter(valid_21627277, JString, required = false,
                                   default = nil)
  if valid_21627277 != nil:
    section.add "X-Amz-Security-Token", valid_21627277
  var valid_21627278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627278 = validateParameter(valid_21627278, JString, required = false,
                                   default = nil)
  if valid_21627278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627278
  var valid_21627279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627279 = validateParameter(valid_21627279, JString, required = false,
                                   default = nil)
  if valid_21627279 != nil:
    section.add "X-Amz-Algorithm", valid_21627279
  var valid_21627280 = header.getOrDefault("X-Amz-Signature")
  valid_21627280 = validateParameter(valid_21627280, JString, required = false,
                                   default = nil)
  if valid_21627280 != nil:
    section.add "X-Amz-Signature", valid_21627280
  var valid_21627281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627281 = validateParameter(valid_21627281, JString, required = false,
                                   default = nil)
  if valid_21627281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627281
  var valid_21627282 = header.getOrDefault("X-Amz-Credential")
  valid_21627282 = validateParameter(valid_21627282, JString, required = false,
                                   default = nil)
  if valid_21627282 != nil:
    section.add "X-Amz-Credential", valid_21627282
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   Marker: JString
  ##   EngineName: JString (required)
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627283 = formData.getOrDefault("MajorEngineVersion")
  valid_21627283 = validateParameter(valid_21627283, JString, required = false,
                                   default = nil)
  if valid_21627283 != nil:
    section.add "MajorEngineVersion", valid_21627283
  var valid_21627284 = formData.getOrDefault("Marker")
  valid_21627284 = validateParameter(valid_21627284, JString, required = false,
                                   default = nil)
  if valid_21627284 != nil:
    section.add "Marker", valid_21627284
  assert formData != nil,
        "formData argument is necessary due to required `EngineName` field"
  var valid_21627285 = formData.getOrDefault("EngineName")
  valid_21627285 = validateParameter(valid_21627285, JString, required = true,
                                   default = nil)
  if valid_21627285 != nil:
    section.add "EngineName", valid_21627285
  var valid_21627286 = formData.getOrDefault("Filters")
  valid_21627286 = validateParameter(valid_21627286, JArray, required = false,
                                   default = nil)
  if valid_21627286 != nil:
    section.add "Filters", valid_21627286
  var valid_21627287 = formData.getOrDefault("MaxRecords")
  valid_21627287 = validateParameter(valid_21627287, JInt, required = false,
                                   default = nil)
  if valid_21627287 != nil:
    section.add "MaxRecords", valid_21627287
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627288: Call_PostDescribeOptionGroupOptions_21627271;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627288.validator(path, query, header, formData, body, _)
  let scheme = call_21627288.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627288.makeUrl(scheme.get, call_21627288.host, call_21627288.base,
                               call_21627288.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627288, uri, valid, _)

proc call*(call_21627289: Call_PostDescribeOptionGroupOptions_21627271;
          EngineName: string; MajorEngineVersion: string = ""; Marker: string = "";
          Action: string = "DescribeOptionGroupOptions"; Filters: JsonNode = nil;
          MaxRecords: int = 0; Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroupOptions
  ##   MajorEngineVersion: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string (required)
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627290 = newJObject()
  var formData_21627291 = newJObject()
  add(formData_21627291, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627291, "Marker", newJString(Marker))
  add(query_21627290, "Action", newJString(Action))
  add(formData_21627291, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_21627291.add "Filters", Filters
  add(formData_21627291, "MaxRecords", newJInt(MaxRecords))
  add(query_21627290, "Version", newJString(Version))
  result = call_21627289.call(nil, query_21627290, nil, formData_21627291, nil)

var postDescribeOptionGroupOptions* = Call_PostDescribeOptionGroupOptions_21627271(
    name: "postDescribeOptionGroupOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_PostDescribeOptionGroupOptions_21627272, base: "/",
    makeUrl: url_PostDescribeOptionGroupOptions_21627273,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroupOptions_21627251 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroupOptions_21627253(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroupOptions_21627252(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString (required)
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_21627254 = query.getOrDefault("MaxRecords")
  valid_21627254 = validateParameter(valid_21627254, JInt, required = false,
                                   default = nil)
  if valid_21627254 != nil:
    section.add "MaxRecords", valid_21627254
  var valid_21627255 = query.getOrDefault("Filters")
  valid_21627255 = validateParameter(valid_21627255, JArray, required = false,
                                   default = nil)
  if valid_21627255 != nil:
    section.add "Filters", valid_21627255
  var valid_21627256 = query.getOrDefault("Action")
  valid_21627256 = validateParameter(valid_21627256, JString, required = true, default = newJString(
      "DescribeOptionGroupOptions"))
  if valid_21627256 != nil:
    section.add "Action", valid_21627256
  var valid_21627257 = query.getOrDefault("Marker")
  valid_21627257 = validateParameter(valid_21627257, JString, required = false,
                                   default = nil)
  if valid_21627257 != nil:
    section.add "Marker", valid_21627257
  var valid_21627258 = query.getOrDefault("Version")
  valid_21627258 = validateParameter(valid_21627258, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627258 != nil:
    section.add "Version", valid_21627258
  var valid_21627259 = query.getOrDefault("EngineName")
  valid_21627259 = validateParameter(valid_21627259, JString, required = true,
                                   default = nil)
  if valid_21627259 != nil:
    section.add "EngineName", valid_21627259
  var valid_21627260 = query.getOrDefault("MajorEngineVersion")
  valid_21627260 = validateParameter(valid_21627260, JString, required = false,
                                   default = nil)
  if valid_21627260 != nil:
    section.add "MajorEngineVersion", valid_21627260
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
  var valid_21627261 = header.getOrDefault("X-Amz-Date")
  valid_21627261 = validateParameter(valid_21627261, JString, required = false,
                                   default = nil)
  if valid_21627261 != nil:
    section.add "X-Amz-Date", valid_21627261
  var valid_21627262 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627262 = validateParameter(valid_21627262, JString, required = false,
                                   default = nil)
  if valid_21627262 != nil:
    section.add "X-Amz-Security-Token", valid_21627262
  var valid_21627263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627263 = validateParameter(valid_21627263, JString, required = false,
                                   default = nil)
  if valid_21627263 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627263
  var valid_21627264 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627264 = validateParameter(valid_21627264, JString, required = false,
                                   default = nil)
  if valid_21627264 != nil:
    section.add "X-Amz-Algorithm", valid_21627264
  var valid_21627265 = header.getOrDefault("X-Amz-Signature")
  valid_21627265 = validateParameter(valid_21627265, JString, required = false,
                                   default = nil)
  if valid_21627265 != nil:
    section.add "X-Amz-Signature", valid_21627265
  var valid_21627266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627266 = validateParameter(valid_21627266, JString, required = false,
                                   default = nil)
  if valid_21627266 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627266
  var valid_21627267 = header.getOrDefault("X-Amz-Credential")
  valid_21627267 = validateParameter(valid_21627267, JString, required = false,
                                   default = nil)
  if valid_21627267 != nil:
    section.add "X-Amz-Credential", valid_21627267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627268: Call_GetDescribeOptionGroupOptions_21627251;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627268.validator(path, query, header, formData, body, _)
  let scheme = call_21627268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627268.makeUrl(scheme.get, call_21627268.host, call_21627268.base,
                               call_21627268.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627268, uri, valid, _)

proc call*(call_21627269: Call_GetDescribeOptionGroupOptions_21627251;
          EngineName: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroupOptions"; Marker: string = "";
          Version: string = "2013-09-09"; MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroupOptions
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string (required)
  ##   MajorEngineVersion: string
  var query_21627270 = newJObject()
  add(query_21627270, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627270.add "Filters", Filters
  add(query_21627270, "Action", newJString(Action))
  add(query_21627270, "Marker", newJString(Marker))
  add(query_21627270, "Version", newJString(Version))
  add(query_21627270, "EngineName", newJString(EngineName))
  add(query_21627270, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627269.call(nil, query_21627270, nil, nil, nil)

var getDescribeOptionGroupOptions* = Call_GetDescribeOptionGroupOptions_21627251(
    name: "getDescribeOptionGroupOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroupOptions",
    validator: validate_GetDescribeOptionGroupOptions_21627252, base: "/",
    makeUrl: url_GetDescribeOptionGroupOptions_21627253,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOptionGroups_21627313 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOptionGroups_21627315(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOptionGroups_21627314(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627316 = query.getOrDefault("Action")
  valid_21627316 = validateParameter(valid_21627316, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627316 != nil:
    section.add "Action", valid_21627316
  var valid_21627317 = query.getOrDefault("Version")
  valid_21627317 = validateParameter(valid_21627317, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627317 != nil:
    section.add "Version", valid_21627317
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
  var valid_21627318 = header.getOrDefault("X-Amz-Date")
  valid_21627318 = validateParameter(valid_21627318, JString, required = false,
                                   default = nil)
  if valid_21627318 != nil:
    section.add "X-Amz-Date", valid_21627318
  var valid_21627319 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627319 = validateParameter(valid_21627319, JString, required = false,
                                   default = nil)
  if valid_21627319 != nil:
    section.add "X-Amz-Security-Token", valid_21627319
  var valid_21627320 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627320 = validateParameter(valid_21627320, JString, required = false,
                                   default = nil)
  if valid_21627320 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627320
  var valid_21627321 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627321 = validateParameter(valid_21627321, JString, required = false,
                                   default = nil)
  if valid_21627321 != nil:
    section.add "X-Amz-Algorithm", valid_21627321
  var valid_21627322 = header.getOrDefault("X-Amz-Signature")
  valid_21627322 = validateParameter(valid_21627322, JString, required = false,
                                   default = nil)
  if valid_21627322 != nil:
    section.add "X-Amz-Signature", valid_21627322
  var valid_21627323 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627323 = validateParameter(valid_21627323, JString, required = false,
                                   default = nil)
  if valid_21627323 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627323
  var valid_21627324 = header.getOrDefault("X-Amz-Credential")
  valid_21627324 = validateParameter(valid_21627324, JString, required = false,
                                   default = nil)
  if valid_21627324 != nil:
    section.add "X-Amz-Credential", valid_21627324
  result.add "header", section
  ## parameters in `formData` object:
  ##   MajorEngineVersion: JString
  ##   OptionGroupName: JString
  ##   Marker: JString
  ##   EngineName: JString
  ##   Filters: JArray
  ##   MaxRecords: JInt
  section = newJObject()
  var valid_21627325 = formData.getOrDefault("MajorEngineVersion")
  valid_21627325 = validateParameter(valid_21627325, JString, required = false,
                                   default = nil)
  if valid_21627325 != nil:
    section.add "MajorEngineVersion", valid_21627325
  var valid_21627326 = formData.getOrDefault("OptionGroupName")
  valid_21627326 = validateParameter(valid_21627326, JString, required = false,
                                   default = nil)
  if valid_21627326 != nil:
    section.add "OptionGroupName", valid_21627326
  var valid_21627327 = formData.getOrDefault("Marker")
  valid_21627327 = validateParameter(valid_21627327, JString, required = false,
                                   default = nil)
  if valid_21627327 != nil:
    section.add "Marker", valid_21627327
  var valid_21627328 = formData.getOrDefault("EngineName")
  valid_21627328 = validateParameter(valid_21627328, JString, required = false,
                                   default = nil)
  if valid_21627328 != nil:
    section.add "EngineName", valid_21627328
  var valid_21627329 = formData.getOrDefault("Filters")
  valid_21627329 = validateParameter(valid_21627329, JArray, required = false,
                                   default = nil)
  if valid_21627329 != nil:
    section.add "Filters", valid_21627329
  var valid_21627330 = formData.getOrDefault("MaxRecords")
  valid_21627330 = validateParameter(valid_21627330, JInt, required = false,
                                   default = nil)
  if valid_21627330 != nil:
    section.add "MaxRecords", valid_21627330
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627331: Call_PostDescribeOptionGroups_21627313;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627331.validator(path, query, header, formData, body, _)
  let scheme = call_21627331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627331.makeUrl(scheme.get, call_21627331.host, call_21627331.base,
                               call_21627331.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627331, uri, valid, _)

proc call*(call_21627332: Call_PostDescribeOptionGroups_21627313;
          MajorEngineVersion: string = ""; OptionGroupName: string = "";
          Marker: string = ""; Action: string = "DescribeOptionGroups";
          EngineName: string = ""; Filters: JsonNode = nil; MaxRecords: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOptionGroups
  ##   MajorEngineVersion: string
  ##   OptionGroupName: string
  ##   Marker: string
  ##   Action: string (required)
  ##   EngineName: string
  ##   Filters: JArray
  ##   MaxRecords: int
  ##   Version: string (required)
  var query_21627333 = newJObject()
  var formData_21627334 = newJObject()
  add(formData_21627334, "MajorEngineVersion", newJString(MajorEngineVersion))
  add(formData_21627334, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627334, "Marker", newJString(Marker))
  add(query_21627333, "Action", newJString(Action))
  add(formData_21627334, "EngineName", newJString(EngineName))
  if Filters != nil:
    formData_21627334.add "Filters", Filters
  add(formData_21627334, "MaxRecords", newJInt(MaxRecords))
  add(query_21627333, "Version", newJString(Version))
  result = call_21627332.call(nil, query_21627333, nil, formData_21627334, nil)

var postDescribeOptionGroups* = Call_PostDescribeOptionGroups_21627313(
    name: "postDescribeOptionGroups", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_PostDescribeOptionGroups_21627314, base: "/",
    makeUrl: url_PostDescribeOptionGroups_21627315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOptionGroups_21627292 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOptionGroups_21627294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOptionGroups_21627293(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxRecords: JInt
  ##   OptionGroupName: JString
  ##   Filters: JArray
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   EngineName: JString
  ##   MajorEngineVersion: JString
  section = newJObject()
  var valid_21627295 = query.getOrDefault("MaxRecords")
  valid_21627295 = validateParameter(valid_21627295, JInt, required = false,
                                   default = nil)
  if valid_21627295 != nil:
    section.add "MaxRecords", valid_21627295
  var valid_21627296 = query.getOrDefault("OptionGroupName")
  valid_21627296 = validateParameter(valid_21627296, JString, required = false,
                                   default = nil)
  if valid_21627296 != nil:
    section.add "OptionGroupName", valid_21627296
  var valid_21627297 = query.getOrDefault("Filters")
  valid_21627297 = validateParameter(valid_21627297, JArray, required = false,
                                   default = nil)
  if valid_21627297 != nil:
    section.add "Filters", valid_21627297
  var valid_21627298 = query.getOrDefault("Action")
  valid_21627298 = validateParameter(valid_21627298, JString, required = true,
                                   default = newJString("DescribeOptionGroups"))
  if valid_21627298 != nil:
    section.add "Action", valid_21627298
  var valid_21627299 = query.getOrDefault("Marker")
  valid_21627299 = validateParameter(valid_21627299, JString, required = false,
                                   default = nil)
  if valid_21627299 != nil:
    section.add "Marker", valid_21627299
  var valid_21627300 = query.getOrDefault("Version")
  valid_21627300 = validateParameter(valid_21627300, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627300 != nil:
    section.add "Version", valid_21627300
  var valid_21627301 = query.getOrDefault("EngineName")
  valid_21627301 = validateParameter(valid_21627301, JString, required = false,
                                   default = nil)
  if valid_21627301 != nil:
    section.add "EngineName", valid_21627301
  var valid_21627302 = query.getOrDefault("MajorEngineVersion")
  valid_21627302 = validateParameter(valid_21627302, JString, required = false,
                                   default = nil)
  if valid_21627302 != nil:
    section.add "MajorEngineVersion", valid_21627302
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
  var valid_21627303 = header.getOrDefault("X-Amz-Date")
  valid_21627303 = validateParameter(valid_21627303, JString, required = false,
                                   default = nil)
  if valid_21627303 != nil:
    section.add "X-Amz-Date", valid_21627303
  var valid_21627304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627304 = validateParameter(valid_21627304, JString, required = false,
                                   default = nil)
  if valid_21627304 != nil:
    section.add "X-Amz-Security-Token", valid_21627304
  var valid_21627305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627305 = validateParameter(valid_21627305, JString, required = false,
                                   default = nil)
  if valid_21627305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627305
  var valid_21627306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627306 = validateParameter(valid_21627306, JString, required = false,
                                   default = nil)
  if valid_21627306 != nil:
    section.add "X-Amz-Algorithm", valid_21627306
  var valid_21627307 = header.getOrDefault("X-Amz-Signature")
  valid_21627307 = validateParameter(valid_21627307, JString, required = false,
                                   default = nil)
  if valid_21627307 != nil:
    section.add "X-Amz-Signature", valid_21627307
  var valid_21627308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627308 = validateParameter(valid_21627308, JString, required = false,
                                   default = nil)
  if valid_21627308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627308
  var valid_21627309 = header.getOrDefault("X-Amz-Credential")
  valid_21627309 = validateParameter(valid_21627309, JString, required = false,
                                   default = nil)
  if valid_21627309 != nil:
    section.add "X-Amz-Credential", valid_21627309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627310: Call_GetDescribeOptionGroups_21627292;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627310.validator(path, query, header, formData, body, _)
  let scheme = call_21627310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627310.makeUrl(scheme.get, call_21627310.host, call_21627310.base,
                               call_21627310.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627310, uri, valid, _)

proc call*(call_21627311: Call_GetDescribeOptionGroups_21627292;
          MaxRecords: int = 0; OptionGroupName: string = ""; Filters: JsonNode = nil;
          Action: string = "DescribeOptionGroups"; Marker: string = "";
          Version: string = "2013-09-09"; EngineName: string = "";
          MajorEngineVersion: string = ""): Recallable =
  ## getDescribeOptionGroups
  ##   MaxRecords: int
  ##   OptionGroupName: string
  ##   Filters: JArray
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   EngineName: string
  ##   MajorEngineVersion: string
  var query_21627312 = newJObject()
  add(query_21627312, "MaxRecords", newJInt(MaxRecords))
  add(query_21627312, "OptionGroupName", newJString(OptionGroupName))
  if Filters != nil:
    query_21627312.add "Filters", Filters
  add(query_21627312, "Action", newJString(Action))
  add(query_21627312, "Marker", newJString(Marker))
  add(query_21627312, "Version", newJString(Version))
  add(query_21627312, "EngineName", newJString(EngineName))
  add(query_21627312, "MajorEngineVersion", newJString(MajorEngineVersion))
  result = call_21627311.call(nil, query_21627312, nil, nil, nil)

var getDescribeOptionGroups* = Call_GetDescribeOptionGroups_21627292(
    name: "getDescribeOptionGroups", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeOptionGroups",
    validator: validate_GetDescribeOptionGroups_21627293, base: "/",
    makeUrl: url_GetDescribeOptionGroups_21627294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeOrderableDBInstanceOptions_21627358 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeOrderableDBInstanceOptions_21627360(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeOrderableDBInstanceOptions_21627359(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627361 = query.getOrDefault("Action")
  valid_21627361 = validateParameter(valid_21627361, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627361 != nil:
    section.add "Action", valid_21627361
  var valid_21627362 = query.getOrDefault("Version")
  valid_21627362 = validateParameter(valid_21627362, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627362 != nil:
    section.add "Version", valid_21627362
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
  var valid_21627363 = header.getOrDefault("X-Amz-Date")
  valid_21627363 = validateParameter(valid_21627363, JString, required = false,
                                   default = nil)
  if valid_21627363 != nil:
    section.add "X-Amz-Date", valid_21627363
  var valid_21627364 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627364 = validateParameter(valid_21627364, JString, required = false,
                                   default = nil)
  if valid_21627364 != nil:
    section.add "X-Amz-Security-Token", valid_21627364
  var valid_21627365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627365 = validateParameter(valid_21627365, JString, required = false,
                                   default = nil)
  if valid_21627365 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627365
  var valid_21627366 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627366 = validateParameter(valid_21627366, JString, required = false,
                                   default = nil)
  if valid_21627366 != nil:
    section.add "X-Amz-Algorithm", valid_21627366
  var valid_21627367 = header.getOrDefault("X-Amz-Signature")
  valid_21627367 = validateParameter(valid_21627367, JString, required = false,
                                   default = nil)
  if valid_21627367 != nil:
    section.add "X-Amz-Signature", valid_21627367
  var valid_21627368 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627368 = validateParameter(valid_21627368, JString, required = false,
                                   default = nil)
  if valid_21627368 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627368
  var valid_21627369 = header.getOrDefault("X-Amz-Credential")
  valid_21627369 = validateParameter(valid_21627369, JString, required = false,
                                   default = nil)
  if valid_21627369 != nil:
    section.add "X-Amz-Credential", valid_21627369
  result.add "header", section
  ## parameters in `formData` object:
  ##   Engine: JString (required)
  ##   Marker: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   LicenseModel: JString
  ##   MaxRecords: JInt
  ##   EngineVersion: JString
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Engine` field"
  var valid_21627370 = formData.getOrDefault("Engine")
  valid_21627370 = validateParameter(valid_21627370, JString, required = true,
                                   default = nil)
  if valid_21627370 != nil:
    section.add "Engine", valid_21627370
  var valid_21627371 = formData.getOrDefault("Marker")
  valid_21627371 = validateParameter(valid_21627371, JString, required = false,
                                   default = nil)
  if valid_21627371 != nil:
    section.add "Marker", valid_21627371
  var valid_21627372 = formData.getOrDefault("Vpc")
  valid_21627372 = validateParameter(valid_21627372, JBool, required = false,
                                   default = nil)
  if valid_21627372 != nil:
    section.add "Vpc", valid_21627372
  var valid_21627373 = formData.getOrDefault("DBInstanceClass")
  valid_21627373 = validateParameter(valid_21627373, JString, required = false,
                                   default = nil)
  if valid_21627373 != nil:
    section.add "DBInstanceClass", valid_21627373
  var valid_21627374 = formData.getOrDefault("Filters")
  valid_21627374 = validateParameter(valid_21627374, JArray, required = false,
                                   default = nil)
  if valid_21627374 != nil:
    section.add "Filters", valid_21627374
  var valid_21627375 = formData.getOrDefault("LicenseModel")
  valid_21627375 = validateParameter(valid_21627375, JString, required = false,
                                   default = nil)
  if valid_21627375 != nil:
    section.add "LicenseModel", valid_21627375
  var valid_21627376 = formData.getOrDefault("MaxRecords")
  valid_21627376 = validateParameter(valid_21627376, JInt, required = false,
                                   default = nil)
  if valid_21627376 != nil:
    section.add "MaxRecords", valid_21627376
  var valid_21627377 = formData.getOrDefault("EngineVersion")
  valid_21627377 = validateParameter(valid_21627377, JString, required = false,
                                   default = nil)
  if valid_21627377 != nil:
    section.add "EngineVersion", valid_21627377
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627378: Call_PostDescribeOrderableDBInstanceOptions_21627358;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627378.validator(path, query, header, formData, body, _)
  let scheme = call_21627378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627378.makeUrl(scheme.get, call_21627378.host, call_21627378.base,
                               call_21627378.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627378, uri, valid, _)

proc call*(call_21627379: Call_PostDescribeOrderableDBInstanceOptions_21627358;
          Engine: string; Marker: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions"; Vpc: bool = false;
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          LicenseModel: string = ""; MaxRecords: int = 0; EngineVersion: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   LicenseModel: string
  ##   MaxRecords: int
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_21627380 = newJObject()
  var formData_21627381 = newJObject()
  add(formData_21627381, "Engine", newJString(Engine))
  add(formData_21627381, "Marker", newJString(Marker))
  add(query_21627380, "Action", newJString(Action))
  add(formData_21627381, "Vpc", newJBool(Vpc))
  add(formData_21627381, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627381.add "Filters", Filters
  add(formData_21627381, "LicenseModel", newJString(LicenseModel))
  add(formData_21627381, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627381, "EngineVersion", newJString(EngineVersion))
  add(query_21627380, "Version", newJString(Version))
  result = call_21627379.call(nil, query_21627380, nil, formData_21627381, nil)

var postDescribeOrderableDBInstanceOptions* = Call_PostDescribeOrderableDBInstanceOptions_21627358(
    name: "postDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_PostDescribeOrderableDBInstanceOptions_21627359,
    base: "/", makeUrl: url_PostDescribeOrderableDBInstanceOptions_21627360,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeOrderableDBInstanceOptions_21627335 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeOrderableDBInstanceOptions_21627337(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeOrderableDBInstanceOptions_21627336(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString (required)
  ##   MaxRecords: JInt
  ##   Filters: JArray
  ##   LicenseModel: JString
  ##   Vpc: JBool
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   EngineVersion: JString
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Engine` field"
  var valid_21627338 = query.getOrDefault("Engine")
  valid_21627338 = validateParameter(valid_21627338, JString, required = true,
                                   default = nil)
  if valid_21627338 != nil:
    section.add "Engine", valid_21627338
  var valid_21627339 = query.getOrDefault("MaxRecords")
  valid_21627339 = validateParameter(valid_21627339, JInt, required = false,
                                   default = nil)
  if valid_21627339 != nil:
    section.add "MaxRecords", valid_21627339
  var valid_21627340 = query.getOrDefault("Filters")
  valid_21627340 = validateParameter(valid_21627340, JArray, required = false,
                                   default = nil)
  if valid_21627340 != nil:
    section.add "Filters", valid_21627340
  var valid_21627341 = query.getOrDefault("LicenseModel")
  valid_21627341 = validateParameter(valid_21627341, JString, required = false,
                                   default = nil)
  if valid_21627341 != nil:
    section.add "LicenseModel", valid_21627341
  var valid_21627342 = query.getOrDefault("Vpc")
  valid_21627342 = validateParameter(valid_21627342, JBool, required = false,
                                   default = nil)
  if valid_21627342 != nil:
    section.add "Vpc", valid_21627342
  var valid_21627343 = query.getOrDefault("DBInstanceClass")
  valid_21627343 = validateParameter(valid_21627343, JString, required = false,
                                   default = nil)
  if valid_21627343 != nil:
    section.add "DBInstanceClass", valid_21627343
  var valid_21627344 = query.getOrDefault("Action")
  valid_21627344 = validateParameter(valid_21627344, JString, required = true, default = newJString(
      "DescribeOrderableDBInstanceOptions"))
  if valid_21627344 != nil:
    section.add "Action", valid_21627344
  var valid_21627345 = query.getOrDefault("Marker")
  valid_21627345 = validateParameter(valid_21627345, JString, required = false,
                                   default = nil)
  if valid_21627345 != nil:
    section.add "Marker", valid_21627345
  var valid_21627346 = query.getOrDefault("EngineVersion")
  valid_21627346 = validateParameter(valid_21627346, JString, required = false,
                                   default = nil)
  if valid_21627346 != nil:
    section.add "EngineVersion", valid_21627346
  var valid_21627347 = query.getOrDefault("Version")
  valid_21627347 = validateParameter(valid_21627347, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627347 != nil:
    section.add "Version", valid_21627347
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
  var valid_21627348 = header.getOrDefault("X-Amz-Date")
  valid_21627348 = validateParameter(valid_21627348, JString, required = false,
                                   default = nil)
  if valid_21627348 != nil:
    section.add "X-Amz-Date", valid_21627348
  var valid_21627349 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627349 = validateParameter(valid_21627349, JString, required = false,
                                   default = nil)
  if valid_21627349 != nil:
    section.add "X-Amz-Security-Token", valid_21627349
  var valid_21627350 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627350 = validateParameter(valid_21627350, JString, required = false,
                                   default = nil)
  if valid_21627350 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627350
  var valid_21627351 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627351 = validateParameter(valid_21627351, JString, required = false,
                                   default = nil)
  if valid_21627351 != nil:
    section.add "X-Amz-Algorithm", valid_21627351
  var valid_21627352 = header.getOrDefault("X-Amz-Signature")
  valid_21627352 = validateParameter(valid_21627352, JString, required = false,
                                   default = nil)
  if valid_21627352 != nil:
    section.add "X-Amz-Signature", valid_21627352
  var valid_21627353 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627353 = validateParameter(valid_21627353, JString, required = false,
                                   default = nil)
  if valid_21627353 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627353
  var valid_21627354 = header.getOrDefault("X-Amz-Credential")
  valid_21627354 = validateParameter(valid_21627354, JString, required = false,
                                   default = nil)
  if valid_21627354 != nil:
    section.add "X-Amz-Credential", valid_21627354
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627355: Call_GetDescribeOrderableDBInstanceOptions_21627335;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627355.validator(path, query, header, formData, body, _)
  let scheme = call_21627355.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627355.makeUrl(scheme.get, call_21627355.host, call_21627355.base,
                               call_21627355.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627355, uri, valid, _)

proc call*(call_21627356: Call_GetDescribeOrderableDBInstanceOptions_21627335;
          Engine: string; MaxRecords: int = 0; Filters: JsonNode = nil;
          LicenseModel: string = ""; Vpc: bool = false; DBInstanceClass: string = "";
          Action: string = "DescribeOrderableDBInstanceOptions";
          Marker: string = ""; EngineVersion: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDescribeOrderableDBInstanceOptions
  ##   Engine: string (required)
  ##   MaxRecords: int
  ##   Filters: JArray
  ##   LicenseModel: string
  ##   Vpc: bool
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   EngineVersion: string
  ##   Version: string (required)
  var query_21627357 = newJObject()
  add(query_21627357, "Engine", newJString(Engine))
  add(query_21627357, "MaxRecords", newJInt(MaxRecords))
  if Filters != nil:
    query_21627357.add "Filters", Filters
  add(query_21627357, "LicenseModel", newJString(LicenseModel))
  add(query_21627357, "Vpc", newJBool(Vpc))
  add(query_21627357, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627357, "Action", newJString(Action))
  add(query_21627357, "Marker", newJString(Marker))
  add(query_21627357, "EngineVersion", newJString(EngineVersion))
  add(query_21627357, "Version", newJString(Version))
  result = call_21627356.call(nil, query_21627357, nil, nil, nil)

var getDescribeOrderableDBInstanceOptions* = Call_GetDescribeOrderableDBInstanceOptions_21627335(
    name: "getDescribeOrderableDBInstanceOptions", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeOrderableDBInstanceOptions",
    validator: validate_GetDescribeOrderableDBInstanceOptions_21627336, base: "/",
    makeUrl: url_GetDescribeOrderableDBInstanceOptions_21627337,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstances_21627407 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstances_21627409(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstances_21627408(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627410 = query.getOrDefault("Action")
  valid_21627410 = validateParameter(valid_21627410, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627410 != nil:
    section.add "Action", valid_21627410
  var valid_21627411 = query.getOrDefault("Version")
  valid_21627411 = validateParameter(valid_21627411, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627411 != nil:
    section.add "Version", valid_21627411
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
  var valid_21627412 = header.getOrDefault("X-Amz-Date")
  valid_21627412 = validateParameter(valid_21627412, JString, required = false,
                                   default = nil)
  if valid_21627412 != nil:
    section.add "X-Amz-Date", valid_21627412
  var valid_21627413 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627413 = validateParameter(valid_21627413, JString, required = false,
                                   default = nil)
  if valid_21627413 != nil:
    section.add "X-Amz-Security-Token", valid_21627413
  var valid_21627414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627414 = validateParameter(valid_21627414, JString, required = false,
                                   default = nil)
  if valid_21627414 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627414
  var valid_21627415 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627415 = validateParameter(valid_21627415, JString, required = false,
                                   default = nil)
  if valid_21627415 != nil:
    section.add "X-Amz-Algorithm", valid_21627415
  var valid_21627416 = header.getOrDefault("X-Amz-Signature")
  valid_21627416 = validateParameter(valid_21627416, JString, required = false,
                                   default = nil)
  if valid_21627416 != nil:
    section.add "X-Amz-Signature", valid_21627416
  var valid_21627417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627417 = validateParameter(valid_21627417, JString, required = false,
                                   default = nil)
  if valid_21627417 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627417
  var valid_21627418 = header.getOrDefault("X-Amz-Credential")
  valid_21627418 = validateParameter(valid_21627418, JString, required = false,
                                   default = nil)
  if valid_21627418 != nil:
    section.add "X-Amz-Credential", valid_21627418
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   ReservedDBInstanceId: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_21627419 = formData.getOrDefault("OfferingType")
  valid_21627419 = validateParameter(valid_21627419, JString, required = false,
                                   default = nil)
  if valid_21627419 != nil:
    section.add "OfferingType", valid_21627419
  var valid_21627420 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627420 = validateParameter(valid_21627420, JString, required = false,
                                   default = nil)
  if valid_21627420 != nil:
    section.add "ReservedDBInstanceId", valid_21627420
  var valid_21627421 = formData.getOrDefault("Marker")
  valid_21627421 = validateParameter(valid_21627421, JString, required = false,
                                   default = nil)
  if valid_21627421 != nil:
    section.add "Marker", valid_21627421
  var valid_21627422 = formData.getOrDefault("MultiAZ")
  valid_21627422 = validateParameter(valid_21627422, JBool, required = false,
                                   default = nil)
  if valid_21627422 != nil:
    section.add "MultiAZ", valid_21627422
  var valid_21627423 = formData.getOrDefault("Duration")
  valid_21627423 = validateParameter(valid_21627423, JString, required = false,
                                   default = nil)
  if valid_21627423 != nil:
    section.add "Duration", valid_21627423
  var valid_21627424 = formData.getOrDefault("DBInstanceClass")
  valid_21627424 = validateParameter(valid_21627424, JString, required = false,
                                   default = nil)
  if valid_21627424 != nil:
    section.add "DBInstanceClass", valid_21627424
  var valid_21627425 = formData.getOrDefault("Filters")
  valid_21627425 = validateParameter(valid_21627425, JArray, required = false,
                                   default = nil)
  if valid_21627425 != nil:
    section.add "Filters", valid_21627425
  var valid_21627426 = formData.getOrDefault("ProductDescription")
  valid_21627426 = validateParameter(valid_21627426, JString, required = false,
                                   default = nil)
  if valid_21627426 != nil:
    section.add "ProductDescription", valid_21627426
  var valid_21627427 = formData.getOrDefault("MaxRecords")
  valid_21627427 = validateParameter(valid_21627427, JInt, required = false,
                                   default = nil)
  if valid_21627427 != nil:
    section.add "MaxRecords", valid_21627427
  var valid_21627428 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627428 = validateParameter(valid_21627428, JString, required = false,
                                   default = nil)
  if valid_21627428 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627429: Call_PostDescribeReservedDBInstances_21627407;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627429.validator(path, query, header, formData, body, _)
  let scheme = call_21627429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627429.makeUrl(scheme.get, call_21627429.host, call_21627429.base,
                               call_21627429.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627429, uri, valid, _)

proc call*(call_21627430: Call_PostDescribeReservedDBInstances_21627407;
          OfferingType: string = ""; ReservedDBInstanceId: string = "";
          Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstances"; Duration: string = "";
          DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstances
  ##   OfferingType: string
  ##   ReservedDBInstanceId: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_21627431 = newJObject()
  var formData_21627432 = newJObject()
  add(formData_21627432, "OfferingType", newJString(OfferingType))
  add(formData_21627432, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(formData_21627432, "Marker", newJString(Marker))
  add(formData_21627432, "MultiAZ", newJBool(MultiAZ))
  add(query_21627431, "Action", newJString(Action))
  add(formData_21627432, "Duration", newJString(Duration))
  add(formData_21627432, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627432.add "Filters", Filters
  add(formData_21627432, "ProductDescription", newJString(ProductDescription))
  add(formData_21627432, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627432, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627431, "Version", newJString(Version))
  result = call_21627430.call(nil, query_21627431, nil, formData_21627432, nil)

var postDescribeReservedDBInstances* = Call_PostDescribeReservedDBInstances_21627407(
    name: "postDescribeReservedDBInstances", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_PostDescribeReservedDBInstances_21627408, base: "/",
    makeUrl: url_PostDescribeReservedDBInstances_21627409,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstances_21627382 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstances_21627384(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstances_21627383(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   Filters: JArray
  ##   MultiAZ: JBool
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627385 = query.getOrDefault("ProductDescription")
  valid_21627385 = validateParameter(valid_21627385, JString, required = false,
                                   default = nil)
  if valid_21627385 != nil:
    section.add "ProductDescription", valid_21627385
  var valid_21627386 = query.getOrDefault("MaxRecords")
  valid_21627386 = validateParameter(valid_21627386, JInt, required = false,
                                   default = nil)
  if valid_21627386 != nil:
    section.add "MaxRecords", valid_21627386
  var valid_21627387 = query.getOrDefault("OfferingType")
  valid_21627387 = validateParameter(valid_21627387, JString, required = false,
                                   default = nil)
  if valid_21627387 != nil:
    section.add "OfferingType", valid_21627387
  var valid_21627388 = query.getOrDefault("Filters")
  valid_21627388 = validateParameter(valid_21627388, JArray, required = false,
                                   default = nil)
  if valid_21627388 != nil:
    section.add "Filters", valid_21627388
  var valid_21627389 = query.getOrDefault("MultiAZ")
  valid_21627389 = validateParameter(valid_21627389, JBool, required = false,
                                   default = nil)
  if valid_21627389 != nil:
    section.add "MultiAZ", valid_21627389
  var valid_21627390 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627390 = validateParameter(valid_21627390, JString, required = false,
                                   default = nil)
  if valid_21627390 != nil:
    section.add "ReservedDBInstanceId", valid_21627390
  var valid_21627391 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627391 = validateParameter(valid_21627391, JString, required = false,
                                   default = nil)
  if valid_21627391 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627391
  var valid_21627392 = query.getOrDefault("DBInstanceClass")
  valid_21627392 = validateParameter(valid_21627392, JString, required = false,
                                   default = nil)
  if valid_21627392 != nil:
    section.add "DBInstanceClass", valid_21627392
  var valid_21627393 = query.getOrDefault("Action")
  valid_21627393 = validateParameter(valid_21627393, JString, required = true, default = newJString(
      "DescribeReservedDBInstances"))
  if valid_21627393 != nil:
    section.add "Action", valid_21627393
  var valid_21627394 = query.getOrDefault("Marker")
  valid_21627394 = validateParameter(valid_21627394, JString, required = false,
                                   default = nil)
  if valid_21627394 != nil:
    section.add "Marker", valid_21627394
  var valid_21627395 = query.getOrDefault("Duration")
  valid_21627395 = validateParameter(valid_21627395, JString, required = false,
                                   default = nil)
  if valid_21627395 != nil:
    section.add "Duration", valid_21627395
  var valid_21627396 = query.getOrDefault("Version")
  valid_21627396 = validateParameter(valid_21627396, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627396 != nil:
    section.add "Version", valid_21627396
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
  var valid_21627397 = header.getOrDefault("X-Amz-Date")
  valid_21627397 = validateParameter(valid_21627397, JString, required = false,
                                   default = nil)
  if valid_21627397 != nil:
    section.add "X-Amz-Date", valid_21627397
  var valid_21627398 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627398 = validateParameter(valid_21627398, JString, required = false,
                                   default = nil)
  if valid_21627398 != nil:
    section.add "X-Amz-Security-Token", valid_21627398
  var valid_21627399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627399 = validateParameter(valid_21627399, JString, required = false,
                                   default = nil)
  if valid_21627399 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627399
  var valid_21627400 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627400 = validateParameter(valid_21627400, JString, required = false,
                                   default = nil)
  if valid_21627400 != nil:
    section.add "X-Amz-Algorithm", valid_21627400
  var valid_21627401 = header.getOrDefault("X-Amz-Signature")
  valid_21627401 = validateParameter(valid_21627401, JString, required = false,
                                   default = nil)
  if valid_21627401 != nil:
    section.add "X-Amz-Signature", valid_21627401
  var valid_21627402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627402 = validateParameter(valid_21627402, JString, required = false,
                                   default = nil)
  if valid_21627402 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627402
  var valid_21627403 = header.getOrDefault("X-Amz-Credential")
  valid_21627403 = validateParameter(valid_21627403, JString, required = false,
                                   default = nil)
  if valid_21627403 != nil:
    section.add "X-Amz-Credential", valid_21627403
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627404: Call_GetDescribeReservedDBInstances_21627382;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627404.validator(path, query, header, formData, body, _)
  let scheme = call_21627404.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627404.makeUrl(scheme.get, call_21627404.host, call_21627404.base,
                               call_21627404.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627404, uri, valid, _)

proc call*(call_21627405: Call_GetDescribeReservedDBInstances_21627382;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstanceId: string = "";
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstances"; Marker: string = "";
          Duration: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeReservedDBInstances
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   Filters: JArray
  ##   MultiAZ: bool
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_21627406 = newJObject()
  add(query_21627406, "ProductDescription", newJString(ProductDescription))
  add(query_21627406, "MaxRecords", newJInt(MaxRecords))
  add(query_21627406, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_21627406.add "Filters", Filters
  add(query_21627406, "MultiAZ", newJBool(MultiAZ))
  add(query_21627406, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627406, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627406, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627406, "Action", newJString(Action))
  add(query_21627406, "Marker", newJString(Marker))
  add(query_21627406, "Duration", newJString(Duration))
  add(query_21627406, "Version", newJString(Version))
  result = call_21627405.call(nil, query_21627406, nil, nil, nil)

var getDescribeReservedDBInstances* = Call_GetDescribeReservedDBInstances_21627382(
    name: "getDescribeReservedDBInstances", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DescribeReservedDBInstances",
    validator: validate_GetDescribeReservedDBInstances_21627383, base: "/",
    makeUrl: url_GetDescribeReservedDBInstances_21627384,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeReservedDBInstancesOfferings_21627457 = ref object of OpenApiRestCall_21625418
proc url_PostDescribeReservedDBInstancesOfferings_21627459(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeReservedDBInstancesOfferings_21627458(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627460 = query.getOrDefault("Action")
  valid_21627460 = validateParameter(valid_21627460, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627460 != nil:
    section.add "Action", valid_21627460
  var valid_21627461 = query.getOrDefault("Version")
  valid_21627461 = validateParameter(valid_21627461, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627461 != nil:
    section.add "Version", valid_21627461
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
  var valid_21627462 = header.getOrDefault("X-Amz-Date")
  valid_21627462 = validateParameter(valid_21627462, JString, required = false,
                                   default = nil)
  if valid_21627462 != nil:
    section.add "X-Amz-Date", valid_21627462
  var valid_21627463 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627463 = validateParameter(valid_21627463, JString, required = false,
                                   default = nil)
  if valid_21627463 != nil:
    section.add "X-Amz-Security-Token", valid_21627463
  var valid_21627464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627464 = validateParameter(valid_21627464, JString, required = false,
                                   default = nil)
  if valid_21627464 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627464
  var valid_21627465 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627465 = validateParameter(valid_21627465, JString, required = false,
                                   default = nil)
  if valid_21627465 != nil:
    section.add "X-Amz-Algorithm", valid_21627465
  var valid_21627466 = header.getOrDefault("X-Amz-Signature")
  valid_21627466 = validateParameter(valid_21627466, JString, required = false,
                                   default = nil)
  if valid_21627466 != nil:
    section.add "X-Amz-Signature", valid_21627466
  var valid_21627467 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627467 = validateParameter(valid_21627467, JString, required = false,
                                   default = nil)
  if valid_21627467 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627467
  var valid_21627468 = header.getOrDefault("X-Amz-Credential")
  valid_21627468 = validateParameter(valid_21627468, JString, required = false,
                                   default = nil)
  if valid_21627468 != nil:
    section.add "X-Amz-Credential", valid_21627468
  result.add "header", section
  ## parameters in `formData` object:
  ##   OfferingType: JString
  ##   Marker: JString
  ##   MultiAZ: JBool
  ##   Duration: JString
  ##   DBInstanceClass: JString
  ##   Filters: JArray
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   ReservedDBInstancesOfferingId: JString
  section = newJObject()
  var valid_21627469 = formData.getOrDefault("OfferingType")
  valid_21627469 = validateParameter(valid_21627469, JString, required = false,
                                   default = nil)
  if valid_21627469 != nil:
    section.add "OfferingType", valid_21627469
  var valid_21627470 = formData.getOrDefault("Marker")
  valid_21627470 = validateParameter(valid_21627470, JString, required = false,
                                   default = nil)
  if valid_21627470 != nil:
    section.add "Marker", valid_21627470
  var valid_21627471 = formData.getOrDefault("MultiAZ")
  valid_21627471 = validateParameter(valid_21627471, JBool, required = false,
                                   default = nil)
  if valid_21627471 != nil:
    section.add "MultiAZ", valid_21627471
  var valid_21627472 = formData.getOrDefault("Duration")
  valid_21627472 = validateParameter(valid_21627472, JString, required = false,
                                   default = nil)
  if valid_21627472 != nil:
    section.add "Duration", valid_21627472
  var valid_21627473 = formData.getOrDefault("DBInstanceClass")
  valid_21627473 = validateParameter(valid_21627473, JString, required = false,
                                   default = nil)
  if valid_21627473 != nil:
    section.add "DBInstanceClass", valid_21627473
  var valid_21627474 = formData.getOrDefault("Filters")
  valid_21627474 = validateParameter(valid_21627474, JArray, required = false,
                                   default = nil)
  if valid_21627474 != nil:
    section.add "Filters", valid_21627474
  var valid_21627475 = formData.getOrDefault("ProductDescription")
  valid_21627475 = validateParameter(valid_21627475, JString, required = false,
                                   default = nil)
  if valid_21627475 != nil:
    section.add "ProductDescription", valid_21627475
  var valid_21627476 = formData.getOrDefault("MaxRecords")
  valid_21627476 = validateParameter(valid_21627476, JInt, required = false,
                                   default = nil)
  if valid_21627476 != nil:
    section.add "MaxRecords", valid_21627476
  var valid_21627477 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627477 = validateParameter(valid_21627477, JString, required = false,
                                   default = nil)
  if valid_21627477 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627477
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627478: Call_PostDescribeReservedDBInstancesOfferings_21627457;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627478.validator(path, query, header, formData, body, _)
  let scheme = call_21627478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627478.makeUrl(scheme.get, call_21627478.host, call_21627478.base,
                               call_21627478.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627478, uri, valid, _)

proc call*(call_21627479: Call_PostDescribeReservedDBInstancesOfferings_21627457;
          OfferingType: string = ""; Marker: string = ""; MultiAZ: bool = false;
          Action: string = "DescribeReservedDBInstancesOfferings";
          Duration: string = ""; DBInstanceClass: string = ""; Filters: JsonNode = nil;
          ProductDescription: string = ""; MaxRecords: int = 0;
          ReservedDBInstancesOfferingId: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postDescribeReservedDBInstancesOfferings
  ##   OfferingType: string
  ##   Marker: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   Duration: string
  ##   DBInstanceClass: string
  ##   Filters: JArray
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   ReservedDBInstancesOfferingId: string
  ##   Version: string (required)
  var query_21627480 = newJObject()
  var formData_21627481 = newJObject()
  add(formData_21627481, "OfferingType", newJString(OfferingType))
  add(formData_21627481, "Marker", newJString(Marker))
  add(formData_21627481, "MultiAZ", newJBool(MultiAZ))
  add(query_21627480, "Action", newJString(Action))
  add(formData_21627481, "Duration", newJString(Duration))
  add(formData_21627481, "DBInstanceClass", newJString(DBInstanceClass))
  if Filters != nil:
    formData_21627481.add "Filters", Filters
  add(formData_21627481, "ProductDescription", newJString(ProductDescription))
  add(formData_21627481, "MaxRecords", newJInt(MaxRecords))
  add(formData_21627481, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627480, "Version", newJString(Version))
  result = call_21627479.call(nil, query_21627480, nil, formData_21627481, nil)

var postDescribeReservedDBInstancesOfferings* = Call_PostDescribeReservedDBInstancesOfferings_21627457(
    name: "postDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_PostDescribeReservedDBInstancesOfferings_21627458,
    base: "/", makeUrl: url_PostDescribeReservedDBInstancesOfferings_21627459,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeReservedDBInstancesOfferings_21627433 = ref object of OpenApiRestCall_21625418
proc url_GetDescribeReservedDBInstancesOfferings_21627435(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeReservedDBInstancesOfferings_21627434(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ProductDescription: JString
  ##   MaxRecords: JInt
  ##   OfferingType: JString
  ##   Filters: JArray
  ##   MultiAZ: JBool
  ##   ReservedDBInstancesOfferingId: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Duration: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627436 = query.getOrDefault("ProductDescription")
  valid_21627436 = validateParameter(valid_21627436, JString, required = false,
                                   default = nil)
  if valid_21627436 != nil:
    section.add "ProductDescription", valid_21627436
  var valid_21627437 = query.getOrDefault("MaxRecords")
  valid_21627437 = validateParameter(valid_21627437, JInt, required = false,
                                   default = nil)
  if valid_21627437 != nil:
    section.add "MaxRecords", valid_21627437
  var valid_21627438 = query.getOrDefault("OfferingType")
  valid_21627438 = validateParameter(valid_21627438, JString, required = false,
                                   default = nil)
  if valid_21627438 != nil:
    section.add "OfferingType", valid_21627438
  var valid_21627439 = query.getOrDefault("Filters")
  valid_21627439 = validateParameter(valid_21627439, JArray, required = false,
                                   default = nil)
  if valid_21627439 != nil:
    section.add "Filters", valid_21627439
  var valid_21627440 = query.getOrDefault("MultiAZ")
  valid_21627440 = validateParameter(valid_21627440, JBool, required = false,
                                   default = nil)
  if valid_21627440 != nil:
    section.add "MultiAZ", valid_21627440
  var valid_21627441 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627441 = validateParameter(valid_21627441, JString, required = false,
                                   default = nil)
  if valid_21627441 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627441
  var valid_21627442 = query.getOrDefault("DBInstanceClass")
  valid_21627442 = validateParameter(valid_21627442, JString, required = false,
                                   default = nil)
  if valid_21627442 != nil:
    section.add "DBInstanceClass", valid_21627442
  var valid_21627443 = query.getOrDefault("Action")
  valid_21627443 = validateParameter(valid_21627443, JString, required = true, default = newJString(
      "DescribeReservedDBInstancesOfferings"))
  if valid_21627443 != nil:
    section.add "Action", valid_21627443
  var valid_21627444 = query.getOrDefault("Marker")
  valid_21627444 = validateParameter(valid_21627444, JString, required = false,
                                   default = nil)
  if valid_21627444 != nil:
    section.add "Marker", valid_21627444
  var valid_21627445 = query.getOrDefault("Duration")
  valid_21627445 = validateParameter(valid_21627445, JString, required = false,
                                   default = nil)
  if valid_21627445 != nil:
    section.add "Duration", valid_21627445
  var valid_21627446 = query.getOrDefault("Version")
  valid_21627446 = validateParameter(valid_21627446, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627446 != nil:
    section.add "Version", valid_21627446
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
  var valid_21627447 = header.getOrDefault("X-Amz-Date")
  valid_21627447 = validateParameter(valid_21627447, JString, required = false,
                                   default = nil)
  if valid_21627447 != nil:
    section.add "X-Amz-Date", valid_21627447
  var valid_21627448 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627448 = validateParameter(valid_21627448, JString, required = false,
                                   default = nil)
  if valid_21627448 != nil:
    section.add "X-Amz-Security-Token", valid_21627448
  var valid_21627449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627449 = validateParameter(valid_21627449, JString, required = false,
                                   default = nil)
  if valid_21627449 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627449
  var valid_21627450 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627450 = validateParameter(valid_21627450, JString, required = false,
                                   default = nil)
  if valid_21627450 != nil:
    section.add "X-Amz-Algorithm", valid_21627450
  var valid_21627451 = header.getOrDefault("X-Amz-Signature")
  valid_21627451 = validateParameter(valid_21627451, JString, required = false,
                                   default = nil)
  if valid_21627451 != nil:
    section.add "X-Amz-Signature", valid_21627451
  var valid_21627452 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627452 = validateParameter(valid_21627452, JString, required = false,
                                   default = nil)
  if valid_21627452 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627452
  var valid_21627453 = header.getOrDefault("X-Amz-Credential")
  valid_21627453 = validateParameter(valid_21627453, JString, required = false,
                                   default = nil)
  if valid_21627453 != nil:
    section.add "X-Amz-Credential", valid_21627453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627454: Call_GetDescribeReservedDBInstancesOfferings_21627433;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627454.validator(path, query, header, formData, body, _)
  let scheme = call_21627454.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627454.makeUrl(scheme.get, call_21627454.host, call_21627454.base,
                               call_21627454.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627454, uri, valid, _)

proc call*(call_21627455: Call_GetDescribeReservedDBInstancesOfferings_21627433;
          ProductDescription: string = ""; MaxRecords: int = 0;
          OfferingType: string = ""; Filters: JsonNode = nil; MultiAZ: bool = false;
          ReservedDBInstancesOfferingId: string = ""; DBInstanceClass: string = "";
          Action: string = "DescribeReservedDBInstancesOfferings";
          Marker: string = ""; Duration: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getDescribeReservedDBInstancesOfferings
  ##   ProductDescription: string
  ##   MaxRecords: int
  ##   OfferingType: string
  ##   Filters: JArray
  ##   MultiAZ: bool
  ##   ReservedDBInstancesOfferingId: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   Marker: string
  ##   Duration: string
  ##   Version: string (required)
  var query_21627456 = newJObject()
  add(query_21627456, "ProductDescription", newJString(ProductDescription))
  add(query_21627456, "MaxRecords", newJInt(MaxRecords))
  add(query_21627456, "OfferingType", newJString(OfferingType))
  if Filters != nil:
    query_21627456.add "Filters", Filters
  add(query_21627456, "MultiAZ", newJBool(MultiAZ))
  add(query_21627456, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627456, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627456, "Action", newJString(Action))
  add(query_21627456, "Marker", newJString(Marker))
  add(query_21627456, "Duration", newJString(Duration))
  add(query_21627456, "Version", newJString(Version))
  result = call_21627455.call(nil, query_21627456, nil, nil, nil)

var getDescribeReservedDBInstancesOfferings* = Call_GetDescribeReservedDBInstancesOfferings_21627433(
    name: "getDescribeReservedDBInstancesOfferings", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=DescribeReservedDBInstancesOfferings",
    validator: validate_GetDescribeReservedDBInstancesOfferings_21627434,
    base: "/", makeUrl: url_GetDescribeReservedDBInstancesOfferings_21627435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDownloadDBLogFilePortion_21627501 = ref object of OpenApiRestCall_21625418
proc url_PostDownloadDBLogFilePortion_21627503(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDownloadDBLogFilePortion_21627502(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627504 = query.getOrDefault("Action")
  valid_21627504 = validateParameter(valid_21627504, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_21627504 != nil:
    section.add "Action", valid_21627504
  var valid_21627505 = query.getOrDefault("Version")
  valid_21627505 = validateParameter(valid_21627505, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627505 != nil:
    section.add "Version", valid_21627505
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
  var valid_21627506 = header.getOrDefault("X-Amz-Date")
  valid_21627506 = validateParameter(valid_21627506, JString, required = false,
                                   default = nil)
  if valid_21627506 != nil:
    section.add "X-Amz-Date", valid_21627506
  var valid_21627507 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627507 = validateParameter(valid_21627507, JString, required = false,
                                   default = nil)
  if valid_21627507 != nil:
    section.add "X-Amz-Security-Token", valid_21627507
  var valid_21627508 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627508 = validateParameter(valid_21627508, JString, required = false,
                                   default = nil)
  if valid_21627508 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627508
  var valid_21627509 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627509 = validateParameter(valid_21627509, JString, required = false,
                                   default = nil)
  if valid_21627509 != nil:
    section.add "X-Amz-Algorithm", valid_21627509
  var valid_21627510 = header.getOrDefault("X-Amz-Signature")
  valid_21627510 = validateParameter(valid_21627510, JString, required = false,
                                   default = nil)
  if valid_21627510 != nil:
    section.add "X-Amz-Signature", valid_21627510
  var valid_21627511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627511 = validateParameter(valid_21627511, JString, required = false,
                                   default = nil)
  if valid_21627511 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627511
  var valid_21627512 = header.getOrDefault("X-Amz-Credential")
  valid_21627512 = validateParameter(valid_21627512, JString, required = false,
                                   default = nil)
  if valid_21627512 != nil:
    section.add "X-Amz-Credential", valid_21627512
  result.add "header", section
  ## parameters in `formData` object:
  ##   NumberOfLines: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   Marker: JString
  ##   LogFileName: JString (required)
  section = newJObject()
  var valid_21627513 = formData.getOrDefault("NumberOfLines")
  valid_21627513 = validateParameter(valid_21627513, JInt, required = false,
                                   default = nil)
  if valid_21627513 != nil:
    section.add "NumberOfLines", valid_21627513
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627514 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627514 = validateParameter(valid_21627514, JString, required = true,
                                   default = nil)
  if valid_21627514 != nil:
    section.add "DBInstanceIdentifier", valid_21627514
  var valid_21627515 = formData.getOrDefault("Marker")
  valid_21627515 = validateParameter(valid_21627515, JString, required = false,
                                   default = nil)
  if valid_21627515 != nil:
    section.add "Marker", valid_21627515
  var valid_21627516 = formData.getOrDefault("LogFileName")
  valid_21627516 = validateParameter(valid_21627516, JString, required = true,
                                   default = nil)
  if valid_21627516 != nil:
    section.add "LogFileName", valid_21627516
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627517: Call_PostDownloadDBLogFilePortion_21627501;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627517.validator(path, query, header, formData, body, _)
  let scheme = call_21627517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627517.makeUrl(scheme.get, call_21627517.host, call_21627517.base,
                               call_21627517.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627517, uri, valid, _)

proc call*(call_21627518: Call_PostDownloadDBLogFilePortion_21627501;
          DBInstanceIdentifier: string; LogFileName: string; NumberOfLines: int = 0;
          Marker: string = ""; Action: string = "DownloadDBLogFilePortion";
          Version: string = "2013-09-09"): Recallable =
  ## postDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   DBInstanceIdentifier: string (required)
  ##   Marker: string
  ##   Action: string (required)
  ##   LogFileName: string (required)
  ##   Version: string (required)
  var query_21627519 = newJObject()
  var formData_21627520 = newJObject()
  add(formData_21627520, "NumberOfLines", newJInt(NumberOfLines))
  add(formData_21627520, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627520, "Marker", newJString(Marker))
  add(query_21627519, "Action", newJString(Action))
  add(formData_21627520, "LogFileName", newJString(LogFileName))
  add(query_21627519, "Version", newJString(Version))
  result = call_21627518.call(nil, query_21627519, nil, formData_21627520, nil)

var postDownloadDBLogFilePortion* = Call_PostDownloadDBLogFilePortion_21627501(
    name: "postDownloadDBLogFilePortion", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_PostDownloadDBLogFilePortion_21627502, base: "/",
    makeUrl: url_PostDownloadDBLogFilePortion_21627503,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDownloadDBLogFilePortion_21627482 = ref object of OpenApiRestCall_21625418
proc url_GetDownloadDBLogFilePortion_21627484(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDownloadDBLogFilePortion_21627483(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NumberOfLines: JInt
  ##   LogFileName: JString (required)
  ##   Action: JString (required)
  ##   Marker: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_21627485 = query.getOrDefault("NumberOfLines")
  valid_21627485 = validateParameter(valid_21627485, JInt, required = false,
                                   default = nil)
  if valid_21627485 != nil:
    section.add "NumberOfLines", valid_21627485
  assert query != nil,
        "query argument is necessary due to required `LogFileName` field"
  var valid_21627486 = query.getOrDefault("LogFileName")
  valid_21627486 = validateParameter(valid_21627486, JString, required = true,
                                   default = nil)
  if valid_21627486 != nil:
    section.add "LogFileName", valid_21627486
  var valid_21627487 = query.getOrDefault("Action")
  valid_21627487 = validateParameter(valid_21627487, JString, required = true, default = newJString(
      "DownloadDBLogFilePortion"))
  if valid_21627487 != nil:
    section.add "Action", valid_21627487
  var valid_21627488 = query.getOrDefault("Marker")
  valid_21627488 = validateParameter(valid_21627488, JString, required = false,
                                   default = nil)
  if valid_21627488 != nil:
    section.add "Marker", valid_21627488
  var valid_21627489 = query.getOrDefault("Version")
  valid_21627489 = validateParameter(valid_21627489, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627489 != nil:
    section.add "Version", valid_21627489
  var valid_21627490 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627490 = validateParameter(valid_21627490, JString, required = true,
                                   default = nil)
  if valid_21627490 != nil:
    section.add "DBInstanceIdentifier", valid_21627490
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
  var valid_21627491 = header.getOrDefault("X-Amz-Date")
  valid_21627491 = validateParameter(valid_21627491, JString, required = false,
                                   default = nil)
  if valid_21627491 != nil:
    section.add "X-Amz-Date", valid_21627491
  var valid_21627492 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627492 = validateParameter(valid_21627492, JString, required = false,
                                   default = nil)
  if valid_21627492 != nil:
    section.add "X-Amz-Security-Token", valid_21627492
  var valid_21627493 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627493 = validateParameter(valid_21627493, JString, required = false,
                                   default = nil)
  if valid_21627493 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627493
  var valid_21627494 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627494 = validateParameter(valid_21627494, JString, required = false,
                                   default = nil)
  if valid_21627494 != nil:
    section.add "X-Amz-Algorithm", valid_21627494
  var valid_21627495 = header.getOrDefault("X-Amz-Signature")
  valid_21627495 = validateParameter(valid_21627495, JString, required = false,
                                   default = nil)
  if valid_21627495 != nil:
    section.add "X-Amz-Signature", valid_21627495
  var valid_21627496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627496 = validateParameter(valid_21627496, JString, required = false,
                                   default = nil)
  if valid_21627496 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627496
  var valid_21627497 = header.getOrDefault("X-Amz-Credential")
  valid_21627497 = validateParameter(valid_21627497, JString, required = false,
                                   default = nil)
  if valid_21627497 != nil:
    section.add "X-Amz-Credential", valid_21627497
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627498: Call_GetDownloadDBLogFilePortion_21627482;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627498.validator(path, query, header, formData, body, _)
  let scheme = call_21627498.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627498.makeUrl(scheme.get, call_21627498.host, call_21627498.base,
                               call_21627498.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627498, uri, valid, _)

proc call*(call_21627499: Call_GetDownloadDBLogFilePortion_21627482;
          LogFileName: string; DBInstanceIdentifier: string; NumberOfLines: int = 0;
          Action: string = "DownloadDBLogFilePortion"; Marker: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getDownloadDBLogFilePortion
  ##   NumberOfLines: int
  ##   LogFileName: string (required)
  ##   Action: string (required)
  ##   Marker: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627500 = newJObject()
  add(query_21627500, "NumberOfLines", newJInt(NumberOfLines))
  add(query_21627500, "LogFileName", newJString(LogFileName))
  add(query_21627500, "Action", newJString(Action))
  add(query_21627500, "Marker", newJString(Marker))
  add(query_21627500, "Version", newJString(Version))
  add(query_21627500, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627499.call(nil, query_21627500, nil, nil, nil)

var getDownloadDBLogFilePortion* = Call_GetDownloadDBLogFilePortion_21627482(
    name: "getDownloadDBLogFilePortion", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=DownloadDBLogFilePortion",
    validator: validate_GetDownloadDBLogFilePortion_21627483, base: "/",
    makeUrl: url_GetDownloadDBLogFilePortion_21627484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostListTagsForResource_21627538 = ref object of OpenApiRestCall_21625418
proc url_PostListTagsForResource_21627540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostListTagsForResource_21627539(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627541 = query.getOrDefault("Action")
  valid_21627541 = validateParameter(valid_21627541, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627541 != nil:
    section.add "Action", valid_21627541
  var valid_21627542 = query.getOrDefault("Version")
  valid_21627542 = validateParameter(valid_21627542, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627542 != nil:
    section.add "Version", valid_21627542
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
  var valid_21627543 = header.getOrDefault("X-Amz-Date")
  valid_21627543 = validateParameter(valid_21627543, JString, required = false,
                                   default = nil)
  if valid_21627543 != nil:
    section.add "X-Amz-Date", valid_21627543
  var valid_21627544 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627544 = validateParameter(valid_21627544, JString, required = false,
                                   default = nil)
  if valid_21627544 != nil:
    section.add "X-Amz-Security-Token", valid_21627544
  var valid_21627545 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627545 = validateParameter(valid_21627545, JString, required = false,
                                   default = nil)
  if valid_21627545 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627545
  var valid_21627546 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627546 = validateParameter(valid_21627546, JString, required = false,
                                   default = nil)
  if valid_21627546 != nil:
    section.add "X-Amz-Algorithm", valid_21627546
  var valid_21627547 = header.getOrDefault("X-Amz-Signature")
  valid_21627547 = validateParameter(valid_21627547, JString, required = false,
                                   default = nil)
  if valid_21627547 != nil:
    section.add "X-Amz-Signature", valid_21627547
  var valid_21627548 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627548 = validateParameter(valid_21627548, JString, required = false,
                                   default = nil)
  if valid_21627548 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627548
  var valid_21627549 = header.getOrDefault("X-Amz-Credential")
  valid_21627549 = validateParameter(valid_21627549, JString, required = false,
                                   default = nil)
  if valid_21627549 != nil:
    section.add "X-Amz-Credential", valid_21627549
  result.add "header", section
  ## parameters in `formData` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  section = newJObject()
  var valid_21627550 = formData.getOrDefault("Filters")
  valid_21627550 = validateParameter(valid_21627550, JArray, required = false,
                                   default = nil)
  if valid_21627550 != nil:
    section.add "Filters", valid_21627550
  assert formData != nil,
        "formData argument is necessary due to required `ResourceName` field"
  var valid_21627551 = formData.getOrDefault("ResourceName")
  valid_21627551 = validateParameter(valid_21627551, JString, required = true,
                                   default = nil)
  if valid_21627551 != nil:
    section.add "ResourceName", valid_21627551
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627552: Call_PostListTagsForResource_21627538;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627552.validator(path, query, header, formData, body, _)
  let scheme = call_21627552.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627552.makeUrl(scheme.get, call_21627552.host, call_21627552.base,
                               call_21627552.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627552, uri, valid, _)

proc call*(call_21627553: Call_PostListTagsForResource_21627538;
          ResourceName: string; Action: string = "ListTagsForResource";
          Filters: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## postListTagsForResource
  ##   Action: string (required)
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21627554 = newJObject()
  var formData_21627555 = newJObject()
  add(query_21627554, "Action", newJString(Action))
  if Filters != nil:
    formData_21627555.add "Filters", Filters
  add(formData_21627555, "ResourceName", newJString(ResourceName))
  add(query_21627554, "Version", newJString(Version))
  result = call_21627553.call(nil, query_21627554, nil, formData_21627555, nil)

var postListTagsForResource* = Call_PostListTagsForResource_21627538(
    name: "postListTagsForResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_PostListTagsForResource_21627539, base: "/",
    makeUrl: url_PostListTagsForResource_21627540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetListTagsForResource_21627521 = ref object of OpenApiRestCall_21625418
proc url_GetListTagsForResource_21627523(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetListTagsForResource_21627522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Filters: JArray
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627524 = query.getOrDefault("Filters")
  valid_21627524 = validateParameter(valid_21627524, JArray, required = false,
                                   default = nil)
  if valid_21627524 != nil:
    section.add "Filters", valid_21627524
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_21627525 = query.getOrDefault("ResourceName")
  valid_21627525 = validateParameter(valid_21627525, JString, required = true,
                                   default = nil)
  if valid_21627525 != nil:
    section.add "ResourceName", valid_21627525
  var valid_21627526 = query.getOrDefault("Action")
  valid_21627526 = validateParameter(valid_21627526, JString, required = true,
                                   default = newJString("ListTagsForResource"))
  if valid_21627526 != nil:
    section.add "Action", valid_21627526
  var valid_21627527 = query.getOrDefault("Version")
  valid_21627527 = validateParameter(valid_21627527, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627527 != nil:
    section.add "Version", valid_21627527
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
  var valid_21627528 = header.getOrDefault("X-Amz-Date")
  valid_21627528 = validateParameter(valid_21627528, JString, required = false,
                                   default = nil)
  if valid_21627528 != nil:
    section.add "X-Amz-Date", valid_21627528
  var valid_21627529 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627529 = validateParameter(valid_21627529, JString, required = false,
                                   default = nil)
  if valid_21627529 != nil:
    section.add "X-Amz-Security-Token", valid_21627529
  var valid_21627530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627530 = validateParameter(valid_21627530, JString, required = false,
                                   default = nil)
  if valid_21627530 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627530
  var valid_21627531 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627531 = validateParameter(valid_21627531, JString, required = false,
                                   default = nil)
  if valid_21627531 != nil:
    section.add "X-Amz-Algorithm", valid_21627531
  var valid_21627532 = header.getOrDefault("X-Amz-Signature")
  valid_21627532 = validateParameter(valid_21627532, JString, required = false,
                                   default = nil)
  if valid_21627532 != nil:
    section.add "X-Amz-Signature", valid_21627532
  var valid_21627533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627533 = validateParameter(valid_21627533, JString, required = false,
                                   default = nil)
  if valid_21627533 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627533
  var valid_21627534 = header.getOrDefault("X-Amz-Credential")
  valid_21627534 = validateParameter(valid_21627534, JString, required = false,
                                   default = nil)
  if valid_21627534 != nil:
    section.add "X-Amz-Credential", valid_21627534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627535: Call_GetListTagsForResource_21627521;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627535.validator(path, query, header, formData, body, _)
  let scheme = call_21627535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627535.makeUrl(scheme.get, call_21627535.host, call_21627535.base,
                               call_21627535.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627535, uri, valid, _)

proc call*(call_21627536: Call_GetListTagsForResource_21627521;
          ResourceName: string; Filters: JsonNode = nil;
          Action: string = "ListTagsForResource"; Version: string = "2013-09-09"): Recallable =
  ## getListTagsForResource
  ##   Filters: JArray
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627537 = newJObject()
  if Filters != nil:
    query_21627537.add "Filters", Filters
  add(query_21627537, "ResourceName", newJString(ResourceName))
  add(query_21627537, "Action", newJString(Action))
  add(query_21627537, "Version", newJString(Version))
  result = call_21627536.call(nil, query_21627537, nil, nil, nil)

var getListTagsForResource* = Call_GetListTagsForResource_21627521(
    name: "getListTagsForResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ListTagsForResource",
    validator: validate_GetListTagsForResource_21627522, base: "/",
    makeUrl: url_GetListTagsForResource_21627523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBInstance_21627589 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBInstance_21627591(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBInstance_21627590(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627592 = query.getOrDefault("Action")
  valid_21627592 = validateParameter(valid_21627592, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627592 != nil:
    section.add "Action", valid_21627592
  var valid_21627593 = query.getOrDefault("Version")
  valid_21627593 = validateParameter(valid_21627593, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627593 != nil:
    section.add "Version", valid_21627593
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
  var valid_21627594 = header.getOrDefault("X-Amz-Date")
  valid_21627594 = validateParameter(valid_21627594, JString, required = false,
                                   default = nil)
  if valid_21627594 != nil:
    section.add "X-Amz-Date", valid_21627594
  var valid_21627595 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627595 = validateParameter(valid_21627595, JString, required = false,
                                   default = nil)
  if valid_21627595 != nil:
    section.add "X-Amz-Security-Token", valid_21627595
  var valid_21627596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627596 = validateParameter(valid_21627596, JString, required = false,
                                   default = nil)
  if valid_21627596 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627596
  var valid_21627597 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627597 = validateParameter(valid_21627597, JString, required = false,
                                   default = nil)
  if valid_21627597 != nil:
    section.add "X-Amz-Algorithm", valid_21627597
  var valid_21627598 = header.getOrDefault("X-Amz-Signature")
  valid_21627598 = validateParameter(valid_21627598, JString, required = false,
                                   default = nil)
  if valid_21627598 != nil:
    section.add "X-Amz-Signature", valid_21627598
  var valid_21627599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627599 = validateParameter(valid_21627599, JString, required = false,
                                   default = nil)
  if valid_21627599 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627599
  var valid_21627600 = header.getOrDefault("X-Amz-Credential")
  valid_21627600 = validateParameter(valid_21627600, JString, required = false,
                                   default = nil)
  if valid_21627600 != nil:
    section.add "X-Amz-Credential", valid_21627600
  result.add "header", section
  ## parameters in `formData` object:
  ##   PreferredMaintenanceWindow: JString
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: JBool
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: JInt
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   OptionGroupName: JString
  ##   MasterUserPassword: JString
  ##   NewDBInstanceIdentifier: JString
  ##   MultiAZ: JBool
  ##   AllocatedStorage: JInt
  ##   DBInstanceClass: JString
  ##   PreferredBackupWindow: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   AllowMajorVersionUpgrade: JBool
  section = newJObject()
  var valid_21627601 = formData.getOrDefault("PreferredMaintenanceWindow")
  valid_21627601 = validateParameter(valid_21627601, JString, required = false,
                                   default = nil)
  if valid_21627601 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627601
  var valid_21627602 = formData.getOrDefault("DBSecurityGroups")
  valid_21627602 = validateParameter(valid_21627602, JArray, required = false,
                                   default = nil)
  if valid_21627602 != nil:
    section.add "DBSecurityGroups", valid_21627602
  var valid_21627603 = formData.getOrDefault("ApplyImmediately")
  valid_21627603 = validateParameter(valid_21627603, JBool, required = false,
                                   default = nil)
  if valid_21627603 != nil:
    section.add "ApplyImmediately", valid_21627603
  var valid_21627604 = formData.getOrDefault("VpcSecurityGroupIds")
  valid_21627604 = validateParameter(valid_21627604, JArray, required = false,
                                   default = nil)
  if valid_21627604 != nil:
    section.add "VpcSecurityGroupIds", valid_21627604
  var valid_21627605 = formData.getOrDefault("Iops")
  valid_21627605 = validateParameter(valid_21627605, JInt, required = false,
                                   default = nil)
  if valid_21627605 != nil:
    section.add "Iops", valid_21627605
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627606 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627606 = validateParameter(valid_21627606, JString, required = true,
                                   default = nil)
  if valid_21627606 != nil:
    section.add "DBInstanceIdentifier", valid_21627606
  var valid_21627607 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627607 = validateParameter(valid_21627607, JInt, required = false,
                                   default = nil)
  if valid_21627607 != nil:
    section.add "BackupRetentionPeriod", valid_21627607
  var valid_21627608 = formData.getOrDefault("DBParameterGroupName")
  valid_21627608 = validateParameter(valid_21627608, JString, required = false,
                                   default = nil)
  if valid_21627608 != nil:
    section.add "DBParameterGroupName", valid_21627608
  var valid_21627609 = formData.getOrDefault("OptionGroupName")
  valid_21627609 = validateParameter(valid_21627609, JString, required = false,
                                   default = nil)
  if valid_21627609 != nil:
    section.add "OptionGroupName", valid_21627609
  var valid_21627610 = formData.getOrDefault("MasterUserPassword")
  valid_21627610 = validateParameter(valid_21627610, JString, required = false,
                                   default = nil)
  if valid_21627610 != nil:
    section.add "MasterUserPassword", valid_21627610
  var valid_21627611 = formData.getOrDefault("NewDBInstanceIdentifier")
  valid_21627611 = validateParameter(valid_21627611, JString, required = false,
                                   default = nil)
  if valid_21627611 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627611
  var valid_21627612 = formData.getOrDefault("MultiAZ")
  valid_21627612 = validateParameter(valid_21627612, JBool, required = false,
                                   default = nil)
  if valid_21627612 != nil:
    section.add "MultiAZ", valid_21627612
  var valid_21627613 = formData.getOrDefault("AllocatedStorage")
  valid_21627613 = validateParameter(valid_21627613, JInt, required = false,
                                   default = nil)
  if valid_21627613 != nil:
    section.add "AllocatedStorage", valid_21627613
  var valid_21627614 = formData.getOrDefault("DBInstanceClass")
  valid_21627614 = validateParameter(valid_21627614, JString, required = false,
                                   default = nil)
  if valid_21627614 != nil:
    section.add "DBInstanceClass", valid_21627614
  var valid_21627615 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627615 = validateParameter(valid_21627615, JString, required = false,
                                   default = nil)
  if valid_21627615 != nil:
    section.add "PreferredBackupWindow", valid_21627615
  var valid_21627616 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627616 = validateParameter(valid_21627616, JBool, required = false,
                                   default = nil)
  if valid_21627616 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627616
  var valid_21627617 = formData.getOrDefault("EngineVersion")
  valid_21627617 = validateParameter(valid_21627617, JString, required = false,
                                   default = nil)
  if valid_21627617 != nil:
    section.add "EngineVersion", valid_21627617
  var valid_21627618 = formData.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627618 = validateParameter(valid_21627618, JBool, required = false,
                                   default = nil)
  if valid_21627618 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627618
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627619: Call_PostModifyDBInstance_21627589; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627619.validator(path, query, header, formData, body, _)
  let scheme = call_21627619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627619.makeUrl(scheme.get, call_21627619.host, call_21627619.base,
                               call_21627619.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627619, uri, valid, _)

proc call*(call_21627620: Call_PostModifyDBInstance_21627589;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          DBSecurityGroups: JsonNode = nil; ApplyImmediately: bool = false;
          VpcSecurityGroupIds: JsonNode = nil; Iops: int = 0;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          OptionGroupName: string = ""; MasterUserPassword: string = "";
          NewDBInstanceIdentifier: string = ""; MultiAZ: bool = false;
          Action: string = "ModifyDBInstance"; AllocatedStorage: int = 0;
          DBInstanceClass: string = ""; PreferredBackupWindow: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          Version: string = "2013-09-09"; AllowMajorVersionUpgrade: bool = false): Recallable =
  ## postModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   DBSecurityGroups: JArray
  ##   ApplyImmediately: bool
  ##   VpcSecurityGroupIds: JArray
  ##   Iops: int
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   OptionGroupName: string
  ##   MasterUserPassword: string
  ##   NewDBInstanceIdentifier: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   AllocatedStorage: int
  ##   DBInstanceClass: string
  ##   PreferredBackupWindow: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   Version: string (required)
  ##   AllowMajorVersionUpgrade: bool
  var query_21627621 = newJObject()
  var formData_21627622 = newJObject()
  add(formData_21627622, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  if DBSecurityGroups != nil:
    formData_21627622.add "DBSecurityGroups", DBSecurityGroups
  add(formData_21627622, "ApplyImmediately", newJBool(ApplyImmediately))
  if VpcSecurityGroupIds != nil:
    formData_21627622.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(formData_21627622, "Iops", newJInt(Iops))
  add(formData_21627622, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627622, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(formData_21627622, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(formData_21627622, "OptionGroupName", newJString(OptionGroupName))
  add(formData_21627622, "MasterUserPassword", newJString(MasterUserPassword))
  add(formData_21627622, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(formData_21627622, "MultiAZ", newJBool(MultiAZ))
  add(query_21627621, "Action", newJString(Action))
  add(formData_21627622, "AllocatedStorage", newJInt(AllocatedStorage))
  add(formData_21627622, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21627622, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(formData_21627622, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(formData_21627622, "EngineVersion", newJString(EngineVersion))
  add(query_21627621, "Version", newJString(Version))
  add(formData_21627622, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  result = call_21627620.call(nil, query_21627621, nil, formData_21627622, nil)

var postModifyDBInstance* = Call_PostModifyDBInstance_21627589(
    name: "postModifyDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_PostModifyDBInstance_21627590, base: "/",
    makeUrl: url_PostModifyDBInstance_21627591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBInstance_21627556 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBInstance_21627558(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBInstance_21627557(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   PreferredMaintenanceWindow: JString
  ##   AllocatedStorage: JInt
  ##   OptionGroupName: JString
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: JString
  ##   Iops: JInt
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: JBool
  ##   BackupRetentionPeriod: JInt
  ##   DBParameterGroupName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   AllowMajorVersionUpgrade: JBool
  ##   NewDBInstanceIdentifier: JString
  ##   AutoMinorVersionUpgrade: JBool
  ##   EngineVersion: JString
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   ApplyImmediately: JBool
  section = newJObject()
  var valid_21627559 = query.getOrDefault("PreferredMaintenanceWindow")
  valid_21627559 = validateParameter(valid_21627559, JString, required = false,
                                   default = nil)
  if valid_21627559 != nil:
    section.add "PreferredMaintenanceWindow", valid_21627559
  var valid_21627560 = query.getOrDefault("AllocatedStorage")
  valid_21627560 = validateParameter(valid_21627560, JInt, required = false,
                                   default = nil)
  if valid_21627560 != nil:
    section.add "AllocatedStorage", valid_21627560
  var valid_21627561 = query.getOrDefault("OptionGroupName")
  valid_21627561 = validateParameter(valid_21627561, JString, required = false,
                                   default = nil)
  if valid_21627561 != nil:
    section.add "OptionGroupName", valid_21627561
  var valid_21627562 = query.getOrDefault("DBSecurityGroups")
  valid_21627562 = validateParameter(valid_21627562, JArray, required = false,
                                   default = nil)
  if valid_21627562 != nil:
    section.add "DBSecurityGroups", valid_21627562
  var valid_21627563 = query.getOrDefault("MasterUserPassword")
  valid_21627563 = validateParameter(valid_21627563, JString, required = false,
                                   default = nil)
  if valid_21627563 != nil:
    section.add "MasterUserPassword", valid_21627563
  var valid_21627564 = query.getOrDefault("Iops")
  valid_21627564 = validateParameter(valid_21627564, JInt, required = false,
                                   default = nil)
  if valid_21627564 != nil:
    section.add "Iops", valid_21627564
  var valid_21627565 = query.getOrDefault("VpcSecurityGroupIds")
  valid_21627565 = validateParameter(valid_21627565, JArray, required = false,
                                   default = nil)
  if valid_21627565 != nil:
    section.add "VpcSecurityGroupIds", valid_21627565
  var valid_21627566 = query.getOrDefault("MultiAZ")
  valid_21627566 = validateParameter(valid_21627566, JBool, required = false,
                                   default = nil)
  if valid_21627566 != nil:
    section.add "MultiAZ", valid_21627566
  var valid_21627567 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627567 = validateParameter(valid_21627567, JInt, required = false,
                                   default = nil)
  if valid_21627567 != nil:
    section.add "BackupRetentionPeriod", valid_21627567
  var valid_21627568 = query.getOrDefault("DBParameterGroupName")
  valid_21627568 = validateParameter(valid_21627568, JString, required = false,
                                   default = nil)
  if valid_21627568 != nil:
    section.add "DBParameterGroupName", valid_21627568
  var valid_21627569 = query.getOrDefault("DBInstanceClass")
  valid_21627569 = validateParameter(valid_21627569, JString, required = false,
                                   default = nil)
  if valid_21627569 != nil:
    section.add "DBInstanceClass", valid_21627569
  var valid_21627570 = query.getOrDefault("Action")
  valid_21627570 = validateParameter(valid_21627570, JString, required = true,
                                   default = newJString("ModifyDBInstance"))
  if valid_21627570 != nil:
    section.add "Action", valid_21627570
  var valid_21627571 = query.getOrDefault("AllowMajorVersionUpgrade")
  valid_21627571 = validateParameter(valid_21627571, JBool, required = false,
                                   default = nil)
  if valid_21627571 != nil:
    section.add "AllowMajorVersionUpgrade", valid_21627571
  var valid_21627572 = query.getOrDefault("NewDBInstanceIdentifier")
  valid_21627572 = validateParameter(valid_21627572, JString, required = false,
                                   default = nil)
  if valid_21627572 != nil:
    section.add "NewDBInstanceIdentifier", valid_21627572
  var valid_21627573 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21627573 = validateParameter(valid_21627573, JBool, required = false,
                                   default = nil)
  if valid_21627573 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21627573
  var valid_21627574 = query.getOrDefault("EngineVersion")
  valid_21627574 = validateParameter(valid_21627574, JString, required = false,
                                   default = nil)
  if valid_21627574 != nil:
    section.add "EngineVersion", valid_21627574
  var valid_21627575 = query.getOrDefault("PreferredBackupWindow")
  valid_21627575 = validateParameter(valid_21627575, JString, required = false,
                                   default = nil)
  if valid_21627575 != nil:
    section.add "PreferredBackupWindow", valid_21627575
  var valid_21627576 = query.getOrDefault("Version")
  valid_21627576 = validateParameter(valid_21627576, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627576 != nil:
    section.add "Version", valid_21627576
  var valid_21627577 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627577 = validateParameter(valid_21627577, JString, required = true,
                                   default = nil)
  if valid_21627577 != nil:
    section.add "DBInstanceIdentifier", valid_21627577
  var valid_21627578 = query.getOrDefault("ApplyImmediately")
  valid_21627578 = validateParameter(valid_21627578, JBool, required = false,
                                   default = nil)
  if valid_21627578 != nil:
    section.add "ApplyImmediately", valid_21627578
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
  var valid_21627579 = header.getOrDefault("X-Amz-Date")
  valid_21627579 = validateParameter(valid_21627579, JString, required = false,
                                   default = nil)
  if valid_21627579 != nil:
    section.add "X-Amz-Date", valid_21627579
  var valid_21627580 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627580 = validateParameter(valid_21627580, JString, required = false,
                                   default = nil)
  if valid_21627580 != nil:
    section.add "X-Amz-Security-Token", valid_21627580
  var valid_21627581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627581 = validateParameter(valid_21627581, JString, required = false,
                                   default = nil)
  if valid_21627581 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627581
  var valid_21627582 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627582 = validateParameter(valid_21627582, JString, required = false,
                                   default = nil)
  if valid_21627582 != nil:
    section.add "X-Amz-Algorithm", valid_21627582
  var valid_21627583 = header.getOrDefault("X-Amz-Signature")
  valid_21627583 = validateParameter(valid_21627583, JString, required = false,
                                   default = nil)
  if valid_21627583 != nil:
    section.add "X-Amz-Signature", valid_21627583
  var valid_21627584 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627584 = validateParameter(valid_21627584, JString, required = false,
                                   default = nil)
  if valid_21627584 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627584
  var valid_21627585 = header.getOrDefault("X-Amz-Credential")
  valid_21627585 = validateParameter(valid_21627585, JString, required = false,
                                   default = nil)
  if valid_21627585 != nil:
    section.add "X-Amz-Credential", valid_21627585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627586: Call_GetModifyDBInstance_21627556; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627586.validator(path, query, header, formData, body, _)
  let scheme = call_21627586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627586.makeUrl(scheme.get, call_21627586.host, call_21627586.base,
                               call_21627586.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627586, uri, valid, _)

proc call*(call_21627587: Call_GetModifyDBInstance_21627556;
          DBInstanceIdentifier: string; PreferredMaintenanceWindow: string = "";
          AllocatedStorage: int = 0; OptionGroupName: string = "";
          DBSecurityGroups: JsonNode = nil; MasterUserPassword: string = "";
          Iops: int = 0; VpcSecurityGroupIds: JsonNode = nil; MultiAZ: bool = false;
          BackupRetentionPeriod: int = 0; DBParameterGroupName: string = "";
          DBInstanceClass: string = ""; Action: string = "ModifyDBInstance";
          AllowMajorVersionUpgrade: bool = false;
          NewDBInstanceIdentifier: string = "";
          AutoMinorVersionUpgrade: bool = false; EngineVersion: string = "";
          PreferredBackupWindow: string = ""; Version: string = "2013-09-09";
          ApplyImmediately: bool = false): Recallable =
  ## getModifyDBInstance
  ##   PreferredMaintenanceWindow: string
  ##   AllocatedStorage: int
  ##   OptionGroupName: string
  ##   DBSecurityGroups: JArray
  ##   MasterUserPassword: string
  ##   Iops: int
  ##   VpcSecurityGroupIds: JArray
  ##   MultiAZ: bool
  ##   BackupRetentionPeriod: int
  ##   DBParameterGroupName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   AllowMajorVersionUpgrade: bool
  ##   NewDBInstanceIdentifier: string
  ##   AutoMinorVersionUpgrade: bool
  ##   EngineVersion: string
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   ApplyImmediately: bool
  var query_21627588 = newJObject()
  add(query_21627588, "PreferredMaintenanceWindow",
      newJString(PreferredMaintenanceWindow))
  add(query_21627588, "AllocatedStorage", newJInt(AllocatedStorage))
  add(query_21627588, "OptionGroupName", newJString(OptionGroupName))
  if DBSecurityGroups != nil:
    query_21627588.add "DBSecurityGroups", DBSecurityGroups
  add(query_21627588, "MasterUserPassword", newJString(MasterUserPassword))
  add(query_21627588, "Iops", newJInt(Iops))
  if VpcSecurityGroupIds != nil:
    query_21627588.add "VpcSecurityGroupIds", VpcSecurityGroupIds
  add(query_21627588, "MultiAZ", newJBool(MultiAZ))
  add(query_21627588, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627588, "DBParameterGroupName", newJString(DBParameterGroupName))
  add(query_21627588, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21627588, "Action", newJString(Action))
  add(query_21627588, "AllowMajorVersionUpgrade",
      newJBool(AllowMajorVersionUpgrade))
  add(query_21627588, "NewDBInstanceIdentifier",
      newJString(NewDBInstanceIdentifier))
  add(query_21627588, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21627588, "EngineVersion", newJString(EngineVersion))
  add(query_21627588, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627588, "Version", newJString(Version))
  add(query_21627588, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627588, "ApplyImmediately", newJBool(ApplyImmediately))
  result = call_21627587.call(nil, query_21627588, nil, nil, nil)

var getModifyDBInstance* = Call_GetModifyDBInstance_21627556(
    name: "getModifyDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBInstance",
    validator: validate_GetModifyDBInstance_21627557, base: "/",
    makeUrl: url_GetModifyDBInstance_21627558,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBParameterGroup_21627640 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBParameterGroup_21627642(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBParameterGroup_21627641(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627643 = query.getOrDefault("Action")
  valid_21627643 = validateParameter(valid_21627643, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627643 != nil:
    section.add "Action", valid_21627643
  var valid_21627644 = query.getOrDefault("Version")
  valid_21627644 = validateParameter(valid_21627644, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627644 != nil:
    section.add "Version", valid_21627644
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
  var valid_21627645 = header.getOrDefault("X-Amz-Date")
  valid_21627645 = validateParameter(valid_21627645, JString, required = false,
                                   default = nil)
  if valid_21627645 != nil:
    section.add "X-Amz-Date", valid_21627645
  var valid_21627646 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627646 = validateParameter(valid_21627646, JString, required = false,
                                   default = nil)
  if valid_21627646 != nil:
    section.add "X-Amz-Security-Token", valid_21627646
  var valid_21627647 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627647 = validateParameter(valid_21627647, JString, required = false,
                                   default = nil)
  if valid_21627647 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627647
  var valid_21627648 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627648 = validateParameter(valid_21627648, JString, required = false,
                                   default = nil)
  if valid_21627648 != nil:
    section.add "X-Amz-Algorithm", valid_21627648
  var valid_21627649 = header.getOrDefault("X-Amz-Signature")
  valid_21627649 = validateParameter(valid_21627649, JString, required = false,
                                   default = nil)
  if valid_21627649 != nil:
    section.add "X-Amz-Signature", valid_21627649
  var valid_21627650 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627650 = validateParameter(valid_21627650, JString, required = false,
                                   default = nil)
  if valid_21627650 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627650
  var valid_21627651 = header.getOrDefault("X-Amz-Credential")
  valid_21627651 = validateParameter(valid_21627651, JString, required = false,
                                   default = nil)
  if valid_21627651 != nil:
    section.add "X-Amz-Credential", valid_21627651
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627652 = formData.getOrDefault("DBParameterGroupName")
  valid_21627652 = validateParameter(valid_21627652, JString, required = true,
                                   default = nil)
  if valid_21627652 != nil:
    section.add "DBParameterGroupName", valid_21627652
  var valid_21627653 = formData.getOrDefault("Parameters")
  valid_21627653 = validateParameter(valid_21627653, JArray, required = true,
                                   default = nil)
  if valid_21627653 != nil:
    section.add "Parameters", valid_21627653
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627654: Call_PostModifyDBParameterGroup_21627640;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627654.validator(path, query, header, formData, body, _)
  let scheme = call_21627654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627654.makeUrl(scheme.get, call_21627654.host, call_21627654.base,
                               call_21627654.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627654, uri, valid, _)

proc call*(call_21627655: Call_PostModifyDBParameterGroup_21627640;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627656 = newJObject()
  var formData_21627657 = newJObject()
  add(formData_21627657, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21627657.add "Parameters", Parameters
  add(query_21627656, "Action", newJString(Action))
  add(query_21627656, "Version", newJString(Version))
  result = call_21627655.call(nil, query_21627656, nil, formData_21627657, nil)

var postModifyDBParameterGroup* = Call_PostModifyDBParameterGroup_21627640(
    name: "postModifyDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_PostModifyDBParameterGroup_21627641, base: "/",
    makeUrl: url_PostModifyDBParameterGroup_21627642,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBParameterGroup_21627623 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBParameterGroup_21627625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBParameterGroup_21627624(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627626 = query.getOrDefault("DBParameterGroupName")
  valid_21627626 = validateParameter(valid_21627626, JString, required = true,
                                   default = nil)
  if valid_21627626 != nil:
    section.add "DBParameterGroupName", valid_21627626
  var valid_21627627 = query.getOrDefault("Parameters")
  valid_21627627 = validateParameter(valid_21627627, JArray, required = true,
                                   default = nil)
  if valid_21627627 != nil:
    section.add "Parameters", valid_21627627
  var valid_21627628 = query.getOrDefault("Action")
  valid_21627628 = validateParameter(valid_21627628, JString, required = true, default = newJString(
      "ModifyDBParameterGroup"))
  if valid_21627628 != nil:
    section.add "Action", valid_21627628
  var valid_21627629 = query.getOrDefault("Version")
  valid_21627629 = validateParameter(valid_21627629, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627629 != nil:
    section.add "Version", valid_21627629
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
  var valid_21627630 = header.getOrDefault("X-Amz-Date")
  valid_21627630 = validateParameter(valid_21627630, JString, required = false,
                                   default = nil)
  if valid_21627630 != nil:
    section.add "X-Amz-Date", valid_21627630
  var valid_21627631 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627631 = validateParameter(valid_21627631, JString, required = false,
                                   default = nil)
  if valid_21627631 != nil:
    section.add "X-Amz-Security-Token", valid_21627631
  var valid_21627632 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627632 = validateParameter(valid_21627632, JString, required = false,
                                   default = nil)
  if valid_21627632 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627632
  var valid_21627633 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627633 = validateParameter(valid_21627633, JString, required = false,
                                   default = nil)
  if valid_21627633 != nil:
    section.add "X-Amz-Algorithm", valid_21627633
  var valid_21627634 = header.getOrDefault("X-Amz-Signature")
  valid_21627634 = validateParameter(valid_21627634, JString, required = false,
                                   default = nil)
  if valid_21627634 != nil:
    section.add "X-Amz-Signature", valid_21627634
  var valid_21627635 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627635 = validateParameter(valid_21627635, JString, required = false,
                                   default = nil)
  if valid_21627635 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627635
  var valid_21627636 = header.getOrDefault("X-Amz-Credential")
  valid_21627636 = validateParameter(valid_21627636, JString, required = false,
                                   default = nil)
  if valid_21627636 != nil:
    section.add "X-Amz-Credential", valid_21627636
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627637: Call_GetModifyDBParameterGroup_21627623;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627637.validator(path, query, header, formData, body, _)
  let scheme = call_21627637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627637.makeUrl(scheme.get, call_21627637.host, call_21627637.base,
                               call_21627637.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627637, uri, valid, _)

proc call*(call_21627638: Call_GetModifyDBParameterGroup_21627623;
          DBParameterGroupName: string; Parameters: JsonNode;
          Action: string = "ModifyDBParameterGroup"; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627639 = newJObject()
  add(query_21627639, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21627639.add "Parameters", Parameters
  add(query_21627639, "Action", newJString(Action))
  add(query_21627639, "Version", newJString(Version))
  result = call_21627638.call(nil, query_21627639, nil, nil, nil)

var getModifyDBParameterGroup* = Call_GetModifyDBParameterGroup_21627623(
    name: "getModifyDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBParameterGroup",
    validator: validate_GetModifyDBParameterGroup_21627624, base: "/",
    makeUrl: url_GetModifyDBParameterGroup_21627625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyDBSubnetGroup_21627676 = ref object of OpenApiRestCall_21625418
proc url_PostModifyDBSubnetGroup_21627678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyDBSubnetGroup_21627677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627679 = query.getOrDefault("Action")
  valid_21627679 = validateParameter(valid_21627679, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627679 != nil:
    section.add "Action", valid_21627679
  var valid_21627680 = query.getOrDefault("Version")
  valid_21627680 = validateParameter(valid_21627680, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627680 != nil:
    section.add "Version", valid_21627680
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
  var valid_21627681 = header.getOrDefault("X-Amz-Date")
  valid_21627681 = validateParameter(valid_21627681, JString, required = false,
                                   default = nil)
  if valid_21627681 != nil:
    section.add "X-Amz-Date", valid_21627681
  var valid_21627682 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627682 = validateParameter(valid_21627682, JString, required = false,
                                   default = nil)
  if valid_21627682 != nil:
    section.add "X-Amz-Security-Token", valid_21627682
  var valid_21627683 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627683 = validateParameter(valid_21627683, JString, required = false,
                                   default = nil)
  if valid_21627683 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627683
  var valid_21627684 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627684 = validateParameter(valid_21627684, JString, required = false,
                                   default = nil)
  if valid_21627684 != nil:
    section.add "X-Amz-Algorithm", valid_21627684
  var valid_21627685 = header.getOrDefault("X-Amz-Signature")
  valid_21627685 = validateParameter(valid_21627685, JString, required = false,
                                   default = nil)
  if valid_21627685 != nil:
    section.add "X-Amz-Signature", valid_21627685
  var valid_21627686 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627686 = validateParameter(valid_21627686, JString, required = false,
                                   default = nil)
  if valid_21627686 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627686
  var valid_21627687 = header.getOrDefault("X-Amz-Credential")
  valid_21627687 = validateParameter(valid_21627687, JString, required = false,
                                   default = nil)
  if valid_21627687 != nil:
    section.add "X-Amz-Credential", valid_21627687
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSubnetGroupName` field"
  var valid_21627688 = formData.getOrDefault("DBSubnetGroupName")
  valid_21627688 = validateParameter(valid_21627688, JString, required = true,
                                   default = nil)
  if valid_21627688 != nil:
    section.add "DBSubnetGroupName", valid_21627688
  var valid_21627689 = formData.getOrDefault("SubnetIds")
  valid_21627689 = validateParameter(valid_21627689, JArray, required = true,
                                   default = nil)
  if valid_21627689 != nil:
    section.add "SubnetIds", valid_21627689
  var valid_21627690 = formData.getOrDefault("DBSubnetGroupDescription")
  valid_21627690 = validateParameter(valid_21627690, JString, required = false,
                                   default = nil)
  if valid_21627690 != nil:
    section.add "DBSubnetGroupDescription", valid_21627690
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627691: Call_PostModifyDBSubnetGroup_21627676;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627691.validator(path, query, header, formData, body, _)
  let scheme = call_21627691.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627691.makeUrl(scheme.get, call_21627691.host, call_21627691.base,
                               call_21627691.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627691, uri, valid, _)

proc call*(call_21627692: Call_PostModifyDBSubnetGroup_21627676;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## postModifyDBSubnetGroup
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   Action: string (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627693 = newJObject()
  var formData_21627694 = newJObject()
  add(formData_21627694, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    formData_21627694.add "SubnetIds", SubnetIds
  add(query_21627693, "Action", newJString(Action))
  add(formData_21627694, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627693, "Version", newJString(Version))
  result = call_21627692.call(nil, query_21627693, nil, formData_21627694, nil)

var postModifyDBSubnetGroup* = Call_PostModifyDBSubnetGroup_21627676(
    name: "postModifyDBSubnetGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_PostModifyDBSubnetGroup_21627677, base: "/",
    makeUrl: url_PostModifyDBSubnetGroup_21627678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyDBSubnetGroup_21627658 = ref object of OpenApiRestCall_21625418
proc url_GetModifyDBSubnetGroup_21627660(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyDBSubnetGroup_21627659(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627661 = query.getOrDefault("Action")
  valid_21627661 = validateParameter(valid_21627661, JString, required = true,
                                   default = newJString("ModifyDBSubnetGroup"))
  if valid_21627661 != nil:
    section.add "Action", valid_21627661
  var valid_21627662 = query.getOrDefault("DBSubnetGroupName")
  valid_21627662 = validateParameter(valid_21627662, JString, required = true,
                                   default = nil)
  if valid_21627662 != nil:
    section.add "DBSubnetGroupName", valid_21627662
  var valid_21627663 = query.getOrDefault("SubnetIds")
  valid_21627663 = validateParameter(valid_21627663, JArray, required = true,
                                   default = nil)
  if valid_21627663 != nil:
    section.add "SubnetIds", valid_21627663
  var valid_21627664 = query.getOrDefault("DBSubnetGroupDescription")
  valid_21627664 = validateParameter(valid_21627664, JString, required = false,
                                   default = nil)
  if valid_21627664 != nil:
    section.add "DBSubnetGroupDescription", valid_21627664
  var valid_21627665 = query.getOrDefault("Version")
  valid_21627665 = validateParameter(valid_21627665, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627665 != nil:
    section.add "Version", valid_21627665
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
  var valid_21627666 = header.getOrDefault("X-Amz-Date")
  valid_21627666 = validateParameter(valid_21627666, JString, required = false,
                                   default = nil)
  if valid_21627666 != nil:
    section.add "X-Amz-Date", valid_21627666
  var valid_21627667 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627667 = validateParameter(valid_21627667, JString, required = false,
                                   default = nil)
  if valid_21627667 != nil:
    section.add "X-Amz-Security-Token", valid_21627667
  var valid_21627668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627668 = validateParameter(valid_21627668, JString, required = false,
                                   default = nil)
  if valid_21627668 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627668
  var valid_21627669 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627669 = validateParameter(valid_21627669, JString, required = false,
                                   default = nil)
  if valid_21627669 != nil:
    section.add "X-Amz-Algorithm", valid_21627669
  var valid_21627670 = header.getOrDefault("X-Amz-Signature")
  valid_21627670 = validateParameter(valid_21627670, JString, required = false,
                                   default = nil)
  if valid_21627670 != nil:
    section.add "X-Amz-Signature", valid_21627670
  var valid_21627671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627671 = validateParameter(valid_21627671, JString, required = false,
                                   default = nil)
  if valid_21627671 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627671
  var valid_21627672 = header.getOrDefault("X-Amz-Credential")
  valid_21627672 = validateParameter(valid_21627672, JString, required = false,
                                   default = nil)
  if valid_21627672 != nil:
    section.add "X-Amz-Credential", valid_21627672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627673: Call_GetModifyDBSubnetGroup_21627658;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627673.validator(path, query, header, formData, body, _)
  let scheme = call_21627673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627673.makeUrl(scheme.get, call_21627673.host, call_21627673.base,
                               call_21627673.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627673, uri, valid, _)

proc call*(call_21627674: Call_GetModifyDBSubnetGroup_21627658;
          DBSubnetGroupName: string; SubnetIds: JsonNode;
          Action: string = "ModifyDBSubnetGroup";
          DBSubnetGroupDescription: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getModifyDBSubnetGroup
  ##   Action: string (required)
  ##   DBSubnetGroupName: string (required)
  ##   SubnetIds: JArray (required)
  ##   DBSubnetGroupDescription: string
  ##   Version: string (required)
  var query_21627675 = newJObject()
  add(query_21627675, "Action", newJString(Action))
  add(query_21627675, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  if SubnetIds != nil:
    query_21627675.add "SubnetIds", SubnetIds
  add(query_21627675, "DBSubnetGroupDescription",
      newJString(DBSubnetGroupDescription))
  add(query_21627675, "Version", newJString(Version))
  result = call_21627674.call(nil, query_21627675, nil, nil, nil)

var getModifyDBSubnetGroup* = Call_GetModifyDBSubnetGroup_21627658(
    name: "getModifyDBSubnetGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyDBSubnetGroup",
    validator: validate_GetModifyDBSubnetGroup_21627659, base: "/",
    makeUrl: url_GetModifyDBSubnetGroup_21627660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyEventSubscription_21627715 = ref object of OpenApiRestCall_21625418
proc url_PostModifyEventSubscription_21627717(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyEventSubscription_21627716(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627718 = query.getOrDefault("Action")
  valid_21627718 = validateParameter(valid_21627718, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627718 != nil:
    section.add "Action", valid_21627718
  var valid_21627719 = query.getOrDefault("Version")
  valid_21627719 = validateParameter(valid_21627719, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627719 != nil:
    section.add "Version", valid_21627719
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
  var valid_21627720 = header.getOrDefault("X-Amz-Date")
  valid_21627720 = validateParameter(valid_21627720, JString, required = false,
                                   default = nil)
  if valid_21627720 != nil:
    section.add "X-Amz-Date", valid_21627720
  var valid_21627721 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627721 = validateParameter(valid_21627721, JString, required = false,
                                   default = nil)
  if valid_21627721 != nil:
    section.add "X-Amz-Security-Token", valid_21627721
  var valid_21627722 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627722 = validateParameter(valid_21627722, JString, required = false,
                                   default = nil)
  if valid_21627722 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627722
  var valid_21627723 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627723 = validateParameter(valid_21627723, JString, required = false,
                                   default = nil)
  if valid_21627723 != nil:
    section.add "X-Amz-Algorithm", valid_21627723
  var valid_21627724 = header.getOrDefault("X-Amz-Signature")
  valid_21627724 = validateParameter(valid_21627724, JString, required = false,
                                   default = nil)
  if valid_21627724 != nil:
    section.add "X-Amz-Signature", valid_21627724
  var valid_21627725 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627725 = validateParameter(valid_21627725, JString, required = false,
                                   default = nil)
  if valid_21627725 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627725
  var valid_21627726 = header.getOrDefault("X-Amz-Credential")
  valid_21627726 = validateParameter(valid_21627726, JString, required = false,
                                   default = nil)
  if valid_21627726 != nil:
    section.add "X-Amz-Credential", valid_21627726
  result.add "header", section
  ## parameters in `formData` object:
  ##   Enabled: JBool
  ##   EventCategories: JArray
  ##   SnsTopicArn: JString
  ##   SubscriptionName: JString (required)
  ##   SourceType: JString
  section = newJObject()
  var valid_21627727 = formData.getOrDefault("Enabled")
  valid_21627727 = validateParameter(valid_21627727, JBool, required = false,
                                   default = nil)
  if valid_21627727 != nil:
    section.add "Enabled", valid_21627727
  var valid_21627728 = formData.getOrDefault("EventCategories")
  valid_21627728 = validateParameter(valid_21627728, JArray, required = false,
                                   default = nil)
  if valid_21627728 != nil:
    section.add "EventCategories", valid_21627728
  var valid_21627729 = formData.getOrDefault("SnsTopicArn")
  valid_21627729 = validateParameter(valid_21627729, JString, required = false,
                                   default = nil)
  if valid_21627729 != nil:
    section.add "SnsTopicArn", valid_21627729
  assert formData != nil, "formData argument is necessary due to required `SubscriptionName` field"
  var valid_21627730 = formData.getOrDefault("SubscriptionName")
  valid_21627730 = validateParameter(valid_21627730, JString, required = true,
                                   default = nil)
  if valid_21627730 != nil:
    section.add "SubscriptionName", valid_21627730
  var valid_21627731 = formData.getOrDefault("SourceType")
  valid_21627731 = validateParameter(valid_21627731, JString, required = false,
                                   default = nil)
  if valid_21627731 != nil:
    section.add "SourceType", valid_21627731
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627732: Call_PostModifyEventSubscription_21627715;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627732.validator(path, query, header, formData, body, _)
  let scheme = call_21627732.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627732.makeUrl(scheme.get, call_21627732.host, call_21627732.base,
                               call_21627732.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627732, uri, valid, _)

proc call*(call_21627733: Call_PostModifyEventSubscription_21627715;
          SubscriptionName: string; Enabled: bool = false;
          EventCategories: JsonNode = nil; SnsTopicArn: string = "";
          Action: string = "ModifyEventSubscription";
          Version: string = "2013-09-09"; SourceType: string = ""): Recallable =
  ## postModifyEventSubscription
  ##   Enabled: bool
  ##   EventCategories: JArray
  ##   SnsTopicArn: string
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  ##   SourceType: string
  var query_21627734 = newJObject()
  var formData_21627735 = newJObject()
  add(formData_21627735, "Enabled", newJBool(Enabled))
  if EventCategories != nil:
    formData_21627735.add "EventCategories", EventCategories
  add(formData_21627735, "SnsTopicArn", newJString(SnsTopicArn))
  add(formData_21627735, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627734, "Action", newJString(Action))
  add(query_21627734, "Version", newJString(Version))
  add(formData_21627735, "SourceType", newJString(SourceType))
  result = call_21627733.call(nil, query_21627734, nil, formData_21627735, nil)

var postModifyEventSubscription* = Call_PostModifyEventSubscription_21627715(
    name: "postModifyEventSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_PostModifyEventSubscription_21627716, base: "/",
    makeUrl: url_PostModifyEventSubscription_21627717,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyEventSubscription_21627695 = ref object of OpenApiRestCall_21625418
proc url_GetModifyEventSubscription_21627697(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyEventSubscription_21627696(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   SourceType: JString
  ##   Enabled: JBool
  ##   Action: JString (required)
  ##   SnsTopicArn: JString
  ##   EventCategories: JArray
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627698 = query.getOrDefault("SourceType")
  valid_21627698 = validateParameter(valid_21627698, JString, required = false,
                                   default = nil)
  if valid_21627698 != nil:
    section.add "SourceType", valid_21627698
  var valid_21627699 = query.getOrDefault("Enabled")
  valid_21627699 = validateParameter(valid_21627699, JBool, required = false,
                                   default = nil)
  if valid_21627699 != nil:
    section.add "Enabled", valid_21627699
  var valid_21627700 = query.getOrDefault("Action")
  valid_21627700 = validateParameter(valid_21627700, JString, required = true, default = newJString(
      "ModifyEventSubscription"))
  if valid_21627700 != nil:
    section.add "Action", valid_21627700
  var valid_21627701 = query.getOrDefault("SnsTopicArn")
  valid_21627701 = validateParameter(valid_21627701, JString, required = false,
                                   default = nil)
  if valid_21627701 != nil:
    section.add "SnsTopicArn", valid_21627701
  var valid_21627702 = query.getOrDefault("EventCategories")
  valid_21627702 = validateParameter(valid_21627702, JArray, required = false,
                                   default = nil)
  if valid_21627702 != nil:
    section.add "EventCategories", valid_21627702
  var valid_21627703 = query.getOrDefault("SubscriptionName")
  valid_21627703 = validateParameter(valid_21627703, JString, required = true,
                                   default = nil)
  if valid_21627703 != nil:
    section.add "SubscriptionName", valid_21627703
  var valid_21627704 = query.getOrDefault("Version")
  valid_21627704 = validateParameter(valid_21627704, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627704 != nil:
    section.add "Version", valid_21627704
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
  var valid_21627705 = header.getOrDefault("X-Amz-Date")
  valid_21627705 = validateParameter(valid_21627705, JString, required = false,
                                   default = nil)
  if valid_21627705 != nil:
    section.add "X-Amz-Date", valid_21627705
  var valid_21627706 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627706 = validateParameter(valid_21627706, JString, required = false,
                                   default = nil)
  if valid_21627706 != nil:
    section.add "X-Amz-Security-Token", valid_21627706
  var valid_21627707 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627707 = validateParameter(valid_21627707, JString, required = false,
                                   default = nil)
  if valid_21627707 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627707
  var valid_21627708 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627708 = validateParameter(valid_21627708, JString, required = false,
                                   default = nil)
  if valid_21627708 != nil:
    section.add "X-Amz-Algorithm", valid_21627708
  var valid_21627709 = header.getOrDefault("X-Amz-Signature")
  valid_21627709 = validateParameter(valid_21627709, JString, required = false,
                                   default = nil)
  if valid_21627709 != nil:
    section.add "X-Amz-Signature", valid_21627709
  var valid_21627710 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627710 = validateParameter(valid_21627710, JString, required = false,
                                   default = nil)
  if valid_21627710 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627710
  var valid_21627711 = header.getOrDefault("X-Amz-Credential")
  valid_21627711 = validateParameter(valid_21627711, JString, required = false,
                                   default = nil)
  if valid_21627711 != nil:
    section.add "X-Amz-Credential", valid_21627711
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627712: Call_GetModifyEventSubscription_21627695;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627712.validator(path, query, header, formData, body, _)
  let scheme = call_21627712.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627712.makeUrl(scheme.get, call_21627712.host, call_21627712.base,
                               call_21627712.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627712, uri, valid, _)

proc call*(call_21627713: Call_GetModifyEventSubscription_21627695;
          SubscriptionName: string; SourceType: string = ""; Enabled: bool = false;
          Action: string = "ModifyEventSubscription"; SnsTopicArn: string = "";
          EventCategories: JsonNode = nil; Version: string = "2013-09-09"): Recallable =
  ## getModifyEventSubscription
  ##   SourceType: string
  ##   Enabled: bool
  ##   Action: string (required)
  ##   SnsTopicArn: string
  ##   EventCategories: JArray
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627714 = newJObject()
  add(query_21627714, "SourceType", newJString(SourceType))
  add(query_21627714, "Enabled", newJBool(Enabled))
  add(query_21627714, "Action", newJString(Action))
  add(query_21627714, "SnsTopicArn", newJString(SnsTopicArn))
  if EventCategories != nil:
    query_21627714.add "EventCategories", EventCategories
  add(query_21627714, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627714, "Version", newJString(Version))
  result = call_21627713.call(nil, query_21627714, nil, nil, nil)

var getModifyEventSubscription* = Call_GetModifyEventSubscription_21627695(
    name: "getModifyEventSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyEventSubscription",
    validator: validate_GetModifyEventSubscription_21627696, base: "/",
    makeUrl: url_GetModifyEventSubscription_21627697,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostModifyOptionGroup_21627755 = ref object of OpenApiRestCall_21625418
proc url_PostModifyOptionGroup_21627757(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostModifyOptionGroup_21627756(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627758 = query.getOrDefault("Action")
  valid_21627758 = validateParameter(valid_21627758, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627758 != nil:
    section.add "Action", valid_21627758
  var valid_21627759 = query.getOrDefault("Version")
  valid_21627759 = validateParameter(valid_21627759, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627759 != nil:
    section.add "Version", valid_21627759
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
  var valid_21627760 = header.getOrDefault("X-Amz-Date")
  valid_21627760 = validateParameter(valid_21627760, JString, required = false,
                                   default = nil)
  if valid_21627760 != nil:
    section.add "X-Amz-Date", valid_21627760
  var valid_21627761 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627761 = validateParameter(valid_21627761, JString, required = false,
                                   default = nil)
  if valid_21627761 != nil:
    section.add "X-Amz-Security-Token", valid_21627761
  var valid_21627762 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627762 = validateParameter(valid_21627762, JString, required = false,
                                   default = nil)
  if valid_21627762 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627762
  var valid_21627763 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627763 = validateParameter(valid_21627763, JString, required = false,
                                   default = nil)
  if valid_21627763 != nil:
    section.add "X-Amz-Algorithm", valid_21627763
  var valid_21627764 = header.getOrDefault("X-Amz-Signature")
  valid_21627764 = validateParameter(valid_21627764, JString, required = false,
                                   default = nil)
  if valid_21627764 != nil:
    section.add "X-Amz-Signature", valid_21627764
  var valid_21627765 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627765 = validateParameter(valid_21627765, JString, required = false,
                                   default = nil)
  if valid_21627765 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627765
  var valid_21627766 = header.getOrDefault("X-Amz-Credential")
  valid_21627766 = validateParameter(valid_21627766, JString, required = false,
                                   default = nil)
  if valid_21627766 != nil:
    section.add "X-Amz-Credential", valid_21627766
  result.add "header", section
  ## parameters in `formData` object:
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: JBool
  ##   OptionGroupName: JString (required)
  ##   OptionsToInclude: JArray
  section = newJObject()
  var valid_21627767 = formData.getOrDefault("OptionsToRemove")
  valid_21627767 = validateParameter(valid_21627767, JArray, required = false,
                                   default = nil)
  if valid_21627767 != nil:
    section.add "OptionsToRemove", valid_21627767
  var valid_21627768 = formData.getOrDefault("ApplyImmediately")
  valid_21627768 = validateParameter(valid_21627768, JBool, required = false,
                                   default = nil)
  if valid_21627768 != nil:
    section.add "ApplyImmediately", valid_21627768
  assert formData != nil, "formData argument is necessary due to required `OptionGroupName` field"
  var valid_21627769 = formData.getOrDefault("OptionGroupName")
  valid_21627769 = validateParameter(valid_21627769, JString, required = true,
                                   default = nil)
  if valid_21627769 != nil:
    section.add "OptionGroupName", valid_21627769
  var valid_21627770 = formData.getOrDefault("OptionsToInclude")
  valid_21627770 = validateParameter(valid_21627770, JArray, required = false,
                                   default = nil)
  if valid_21627770 != nil:
    section.add "OptionsToInclude", valid_21627770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627771: Call_PostModifyOptionGroup_21627755;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627771.validator(path, query, header, formData, body, _)
  let scheme = call_21627771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627771.makeUrl(scheme.get, call_21627771.host, call_21627771.base,
                               call_21627771.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627771, uri, valid, _)

proc call*(call_21627772: Call_PostModifyOptionGroup_21627755;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2013-09-09"): Recallable =
  ## postModifyOptionGroup
  ##   OptionsToRemove: JArray
  ##   ApplyImmediately: bool
  ##   OptionGroupName: string (required)
  ##   OptionsToInclude: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627773 = newJObject()
  var formData_21627774 = newJObject()
  if OptionsToRemove != nil:
    formData_21627774.add "OptionsToRemove", OptionsToRemove
  add(formData_21627774, "ApplyImmediately", newJBool(ApplyImmediately))
  add(formData_21627774, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToInclude != nil:
    formData_21627774.add "OptionsToInclude", OptionsToInclude
  add(query_21627773, "Action", newJString(Action))
  add(query_21627773, "Version", newJString(Version))
  result = call_21627772.call(nil, query_21627773, nil, formData_21627774, nil)

var postModifyOptionGroup* = Call_PostModifyOptionGroup_21627755(
    name: "postModifyOptionGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_PostModifyOptionGroup_21627756, base: "/",
    makeUrl: url_PostModifyOptionGroup_21627757,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetModifyOptionGroup_21627736 = ref object of OpenApiRestCall_21625418
proc url_GetModifyOptionGroup_21627738(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetModifyOptionGroup_21627737(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   OptionGroupName: JString (required)
  ##   OptionsToRemove: JArray
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   ApplyImmediately: JBool
  ##   OptionsToInclude: JArray
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `OptionGroupName` field"
  var valid_21627739 = query.getOrDefault("OptionGroupName")
  valid_21627739 = validateParameter(valid_21627739, JString, required = true,
                                   default = nil)
  if valid_21627739 != nil:
    section.add "OptionGroupName", valid_21627739
  var valid_21627740 = query.getOrDefault("OptionsToRemove")
  valid_21627740 = validateParameter(valid_21627740, JArray, required = false,
                                   default = nil)
  if valid_21627740 != nil:
    section.add "OptionsToRemove", valid_21627740
  var valid_21627741 = query.getOrDefault("Action")
  valid_21627741 = validateParameter(valid_21627741, JString, required = true,
                                   default = newJString("ModifyOptionGroup"))
  if valid_21627741 != nil:
    section.add "Action", valid_21627741
  var valid_21627742 = query.getOrDefault("Version")
  valid_21627742 = validateParameter(valid_21627742, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627742 != nil:
    section.add "Version", valid_21627742
  var valid_21627743 = query.getOrDefault("ApplyImmediately")
  valid_21627743 = validateParameter(valid_21627743, JBool, required = false,
                                   default = nil)
  if valid_21627743 != nil:
    section.add "ApplyImmediately", valid_21627743
  var valid_21627744 = query.getOrDefault("OptionsToInclude")
  valid_21627744 = validateParameter(valid_21627744, JArray, required = false,
                                   default = nil)
  if valid_21627744 != nil:
    section.add "OptionsToInclude", valid_21627744
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
  var valid_21627745 = header.getOrDefault("X-Amz-Date")
  valid_21627745 = validateParameter(valid_21627745, JString, required = false,
                                   default = nil)
  if valid_21627745 != nil:
    section.add "X-Amz-Date", valid_21627745
  var valid_21627746 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627746 = validateParameter(valid_21627746, JString, required = false,
                                   default = nil)
  if valid_21627746 != nil:
    section.add "X-Amz-Security-Token", valid_21627746
  var valid_21627747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627747 = validateParameter(valid_21627747, JString, required = false,
                                   default = nil)
  if valid_21627747 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627747
  var valid_21627748 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627748 = validateParameter(valid_21627748, JString, required = false,
                                   default = nil)
  if valid_21627748 != nil:
    section.add "X-Amz-Algorithm", valid_21627748
  var valid_21627749 = header.getOrDefault("X-Amz-Signature")
  valid_21627749 = validateParameter(valid_21627749, JString, required = false,
                                   default = nil)
  if valid_21627749 != nil:
    section.add "X-Amz-Signature", valid_21627749
  var valid_21627750 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627750 = validateParameter(valid_21627750, JString, required = false,
                                   default = nil)
  if valid_21627750 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627750
  var valid_21627751 = header.getOrDefault("X-Amz-Credential")
  valid_21627751 = validateParameter(valid_21627751, JString, required = false,
                                   default = nil)
  if valid_21627751 != nil:
    section.add "X-Amz-Credential", valid_21627751
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627752: Call_GetModifyOptionGroup_21627736; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627752.validator(path, query, header, formData, body, _)
  let scheme = call_21627752.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627752.makeUrl(scheme.get, call_21627752.host, call_21627752.base,
                               call_21627752.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627752, uri, valid, _)

proc call*(call_21627753: Call_GetModifyOptionGroup_21627736;
          OptionGroupName: string; OptionsToRemove: JsonNode = nil;
          Action: string = "ModifyOptionGroup"; Version: string = "2013-09-09";
          ApplyImmediately: bool = false; OptionsToInclude: JsonNode = nil): Recallable =
  ## getModifyOptionGroup
  ##   OptionGroupName: string (required)
  ##   OptionsToRemove: JArray
  ##   Action: string (required)
  ##   Version: string (required)
  ##   ApplyImmediately: bool
  ##   OptionsToInclude: JArray
  var query_21627754 = newJObject()
  add(query_21627754, "OptionGroupName", newJString(OptionGroupName))
  if OptionsToRemove != nil:
    query_21627754.add "OptionsToRemove", OptionsToRemove
  add(query_21627754, "Action", newJString(Action))
  add(query_21627754, "Version", newJString(Version))
  add(query_21627754, "ApplyImmediately", newJBool(ApplyImmediately))
  if OptionsToInclude != nil:
    query_21627754.add "OptionsToInclude", OptionsToInclude
  result = call_21627753.call(nil, query_21627754, nil, nil, nil)

var getModifyOptionGroup* = Call_GetModifyOptionGroup_21627736(
    name: "getModifyOptionGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ModifyOptionGroup",
    validator: validate_GetModifyOptionGroup_21627737, base: "/",
    makeUrl: url_GetModifyOptionGroup_21627738,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPromoteReadReplica_21627793 = ref object of OpenApiRestCall_21625418
proc url_PostPromoteReadReplica_21627795(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPromoteReadReplica_21627794(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627796 = query.getOrDefault("Action")
  valid_21627796 = validateParameter(valid_21627796, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627796 != nil:
    section.add "Action", valid_21627796
  var valid_21627797 = query.getOrDefault("Version")
  valid_21627797 = validateParameter(valid_21627797, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627797 != nil:
    section.add "Version", valid_21627797
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
  var valid_21627798 = header.getOrDefault("X-Amz-Date")
  valid_21627798 = validateParameter(valid_21627798, JString, required = false,
                                   default = nil)
  if valid_21627798 != nil:
    section.add "X-Amz-Date", valid_21627798
  var valid_21627799 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627799 = validateParameter(valid_21627799, JString, required = false,
                                   default = nil)
  if valid_21627799 != nil:
    section.add "X-Amz-Security-Token", valid_21627799
  var valid_21627800 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627800 = validateParameter(valid_21627800, JString, required = false,
                                   default = nil)
  if valid_21627800 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627800
  var valid_21627801 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627801 = validateParameter(valid_21627801, JString, required = false,
                                   default = nil)
  if valid_21627801 != nil:
    section.add "X-Amz-Algorithm", valid_21627801
  var valid_21627802 = header.getOrDefault("X-Amz-Signature")
  valid_21627802 = validateParameter(valid_21627802, JString, required = false,
                                   default = nil)
  if valid_21627802 != nil:
    section.add "X-Amz-Signature", valid_21627802
  var valid_21627803 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627803 = validateParameter(valid_21627803, JString, required = false,
                                   default = nil)
  if valid_21627803 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627803
  var valid_21627804 = header.getOrDefault("X-Amz-Credential")
  valid_21627804 = validateParameter(valid_21627804, JString, required = false,
                                   default = nil)
  if valid_21627804 != nil:
    section.add "X-Amz-Credential", valid_21627804
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   BackupRetentionPeriod: JInt
  ##   PreferredBackupWindow: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627805 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627805 = validateParameter(valid_21627805, JString, required = true,
                                   default = nil)
  if valid_21627805 != nil:
    section.add "DBInstanceIdentifier", valid_21627805
  var valid_21627806 = formData.getOrDefault("BackupRetentionPeriod")
  valid_21627806 = validateParameter(valid_21627806, JInt, required = false,
                                   default = nil)
  if valid_21627806 != nil:
    section.add "BackupRetentionPeriod", valid_21627806
  var valid_21627807 = formData.getOrDefault("PreferredBackupWindow")
  valid_21627807 = validateParameter(valid_21627807, JString, required = false,
                                   default = nil)
  if valid_21627807 != nil:
    section.add "PreferredBackupWindow", valid_21627807
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627808: Call_PostPromoteReadReplica_21627793;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627808.validator(path, query, header, formData, body, _)
  let scheme = call_21627808.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627808.makeUrl(scheme.get, call_21627808.host, call_21627808.base,
                               call_21627808.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627808, uri, valid, _)

proc call*(call_21627809: Call_PostPromoteReadReplica_21627793;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## postPromoteReadReplica
  ##   DBInstanceIdentifier: string (required)
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  var query_21627810 = newJObject()
  var formData_21627811 = newJObject()
  add(formData_21627811, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21627811, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627810, "Action", newJString(Action))
  add(formData_21627811, "PreferredBackupWindow",
      newJString(PreferredBackupWindow))
  add(query_21627810, "Version", newJString(Version))
  result = call_21627809.call(nil, query_21627810, nil, formData_21627811, nil)

var postPromoteReadReplica* = Call_PostPromoteReadReplica_21627793(
    name: "postPromoteReadReplica", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_PostPromoteReadReplica_21627794, base: "/",
    makeUrl: url_PostPromoteReadReplica_21627795,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPromoteReadReplica_21627775 = ref object of OpenApiRestCall_21625418
proc url_GetPromoteReadReplica_21627777(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPromoteReadReplica_21627776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   BackupRetentionPeriod: JInt
  ##   Action: JString (required)
  ##   PreferredBackupWindow: JString
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_21627778 = query.getOrDefault("BackupRetentionPeriod")
  valid_21627778 = validateParameter(valid_21627778, JInt, required = false,
                                   default = nil)
  if valid_21627778 != nil:
    section.add "BackupRetentionPeriod", valid_21627778
  var valid_21627779 = query.getOrDefault("Action")
  valid_21627779 = validateParameter(valid_21627779, JString, required = true,
                                   default = newJString("PromoteReadReplica"))
  if valid_21627779 != nil:
    section.add "Action", valid_21627779
  var valid_21627780 = query.getOrDefault("PreferredBackupWindow")
  valid_21627780 = validateParameter(valid_21627780, JString, required = false,
                                   default = nil)
  if valid_21627780 != nil:
    section.add "PreferredBackupWindow", valid_21627780
  var valid_21627781 = query.getOrDefault("Version")
  valid_21627781 = validateParameter(valid_21627781, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627781 != nil:
    section.add "Version", valid_21627781
  var valid_21627782 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627782 = validateParameter(valid_21627782, JString, required = true,
                                   default = nil)
  if valid_21627782 != nil:
    section.add "DBInstanceIdentifier", valid_21627782
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
  var valid_21627783 = header.getOrDefault("X-Amz-Date")
  valid_21627783 = validateParameter(valid_21627783, JString, required = false,
                                   default = nil)
  if valid_21627783 != nil:
    section.add "X-Amz-Date", valid_21627783
  var valid_21627784 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627784 = validateParameter(valid_21627784, JString, required = false,
                                   default = nil)
  if valid_21627784 != nil:
    section.add "X-Amz-Security-Token", valid_21627784
  var valid_21627785 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627785 = validateParameter(valid_21627785, JString, required = false,
                                   default = nil)
  if valid_21627785 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627785
  var valid_21627786 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627786 = validateParameter(valid_21627786, JString, required = false,
                                   default = nil)
  if valid_21627786 != nil:
    section.add "X-Amz-Algorithm", valid_21627786
  var valid_21627787 = header.getOrDefault("X-Amz-Signature")
  valid_21627787 = validateParameter(valid_21627787, JString, required = false,
                                   default = nil)
  if valid_21627787 != nil:
    section.add "X-Amz-Signature", valid_21627787
  var valid_21627788 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627788 = validateParameter(valid_21627788, JString, required = false,
                                   default = nil)
  if valid_21627788 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627788
  var valid_21627789 = header.getOrDefault("X-Amz-Credential")
  valid_21627789 = validateParameter(valid_21627789, JString, required = false,
                                   default = nil)
  if valid_21627789 != nil:
    section.add "X-Amz-Credential", valid_21627789
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627790: Call_GetPromoteReadReplica_21627775;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627790.validator(path, query, header, formData, body, _)
  let scheme = call_21627790.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627790.makeUrl(scheme.get, call_21627790.host, call_21627790.base,
                               call_21627790.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627790, uri, valid, _)

proc call*(call_21627791: Call_GetPromoteReadReplica_21627775;
          DBInstanceIdentifier: string; BackupRetentionPeriod: int = 0;
          Action: string = "PromoteReadReplica"; PreferredBackupWindow: string = "";
          Version: string = "2013-09-09"): Recallable =
  ## getPromoteReadReplica
  ##   BackupRetentionPeriod: int
  ##   Action: string (required)
  ##   PreferredBackupWindow: string
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627792 = newJObject()
  add(query_21627792, "BackupRetentionPeriod", newJInt(BackupRetentionPeriod))
  add(query_21627792, "Action", newJString(Action))
  add(query_21627792, "PreferredBackupWindow", newJString(PreferredBackupWindow))
  add(query_21627792, "Version", newJString(Version))
  add(query_21627792, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627791.call(nil, query_21627792, nil, nil, nil)

var getPromoteReadReplica* = Call_GetPromoteReadReplica_21627775(
    name: "getPromoteReadReplica", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=PromoteReadReplica",
    validator: validate_GetPromoteReadReplica_21627776, base: "/",
    makeUrl: url_GetPromoteReadReplica_21627777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostPurchaseReservedDBInstancesOffering_21627831 = ref object of OpenApiRestCall_21625418
proc url_PostPurchaseReservedDBInstancesOffering_21627833(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostPurchaseReservedDBInstancesOffering_21627832(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627834 = query.getOrDefault("Action")
  valid_21627834 = validateParameter(valid_21627834, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627834 != nil:
    section.add "Action", valid_21627834
  var valid_21627835 = query.getOrDefault("Version")
  valid_21627835 = validateParameter(valid_21627835, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627835 != nil:
    section.add "Version", valid_21627835
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
  var valid_21627836 = header.getOrDefault("X-Amz-Date")
  valid_21627836 = validateParameter(valid_21627836, JString, required = false,
                                   default = nil)
  if valid_21627836 != nil:
    section.add "X-Amz-Date", valid_21627836
  var valid_21627837 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627837 = validateParameter(valid_21627837, JString, required = false,
                                   default = nil)
  if valid_21627837 != nil:
    section.add "X-Amz-Security-Token", valid_21627837
  var valid_21627838 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627838 = validateParameter(valid_21627838, JString, required = false,
                                   default = nil)
  if valid_21627838 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627838
  var valid_21627839 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627839 = validateParameter(valid_21627839, JString, required = false,
                                   default = nil)
  if valid_21627839 != nil:
    section.add "X-Amz-Algorithm", valid_21627839
  var valid_21627840 = header.getOrDefault("X-Amz-Signature")
  valid_21627840 = validateParameter(valid_21627840, JString, required = false,
                                   default = nil)
  if valid_21627840 != nil:
    section.add "X-Amz-Signature", valid_21627840
  var valid_21627841 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627841 = validateParameter(valid_21627841, JString, required = false,
                                   default = nil)
  if valid_21627841 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627841
  var valid_21627842 = header.getOrDefault("X-Amz-Credential")
  valid_21627842 = validateParameter(valid_21627842, JString, required = false,
                                   default = nil)
  if valid_21627842 != nil:
    section.add "X-Amz-Credential", valid_21627842
  result.add "header", section
  ## parameters in `formData` object:
  ##   ReservedDBInstanceId: JString
  ##   Tags: JArray
  ##   DBInstanceCount: JInt
  ##   ReservedDBInstancesOfferingId: JString (required)
  section = newJObject()
  var valid_21627843 = formData.getOrDefault("ReservedDBInstanceId")
  valid_21627843 = validateParameter(valid_21627843, JString, required = false,
                                   default = nil)
  if valid_21627843 != nil:
    section.add "ReservedDBInstanceId", valid_21627843
  var valid_21627844 = formData.getOrDefault("Tags")
  valid_21627844 = validateParameter(valid_21627844, JArray, required = false,
                                   default = nil)
  if valid_21627844 != nil:
    section.add "Tags", valid_21627844
  var valid_21627845 = formData.getOrDefault("DBInstanceCount")
  valid_21627845 = validateParameter(valid_21627845, JInt, required = false,
                                   default = nil)
  if valid_21627845 != nil:
    section.add "DBInstanceCount", valid_21627845
  assert formData != nil, "formData argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627846 = formData.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627846 = validateParameter(valid_21627846, JString, required = true,
                                   default = nil)
  if valid_21627846 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627846
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627847: Call_PostPurchaseReservedDBInstancesOffering_21627831;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627847.validator(path, query, header, formData, body, _)
  let scheme = call_21627847.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627847.makeUrl(scheme.get, call_21627847.host, call_21627847.base,
                               call_21627847.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627847, uri, valid, _)

proc call*(call_21627848: Call_PostPurchaseReservedDBInstancesOffering_21627831;
          ReservedDBInstancesOfferingId: string;
          ReservedDBInstanceId: string = ""; Tags: JsonNode = nil;
          DBInstanceCount: int = 0;
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## postPurchaseReservedDBInstancesOffering
  ##   ReservedDBInstanceId: string
  ##   Tags: JArray
  ##   DBInstanceCount: int
  ##   Action: string (required)
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Version: string (required)
  var query_21627849 = newJObject()
  var formData_21627850 = newJObject()
  add(formData_21627850, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  if Tags != nil:
    formData_21627850.add "Tags", Tags
  add(formData_21627850, "DBInstanceCount", newJInt(DBInstanceCount))
  add(query_21627849, "Action", newJString(Action))
  add(formData_21627850, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627849, "Version", newJString(Version))
  result = call_21627848.call(nil, query_21627849, nil, formData_21627850, nil)

var postPurchaseReservedDBInstancesOffering* = Call_PostPurchaseReservedDBInstancesOffering_21627831(
    name: "postPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_PostPurchaseReservedDBInstancesOffering_21627832,
    base: "/", makeUrl: url_PostPurchaseReservedDBInstancesOffering_21627833,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPurchaseReservedDBInstancesOffering_21627812 = ref object of OpenApiRestCall_21625418
proc url_GetPurchaseReservedDBInstancesOffering_21627814(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPurchaseReservedDBInstancesOffering_21627813(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBInstanceCount: JInt
  ##   Tags: JArray
  ##   ReservedDBInstanceId: JString
  ##   ReservedDBInstancesOfferingId: JString (required)
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627815 = query.getOrDefault("DBInstanceCount")
  valid_21627815 = validateParameter(valid_21627815, JInt, required = false,
                                   default = nil)
  if valid_21627815 != nil:
    section.add "DBInstanceCount", valid_21627815
  var valid_21627816 = query.getOrDefault("Tags")
  valid_21627816 = validateParameter(valid_21627816, JArray, required = false,
                                   default = nil)
  if valid_21627816 != nil:
    section.add "Tags", valid_21627816
  var valid_21627817 = query.getOrDefault("ReservedDBInstanceId")
  valid_21627817 = validateParameter(valid_21627817, JString, required = false,
                                   default = nil)
  if valid_21627817 != nil:
    section.add "ReservedDBInstanceId", valid_21627817
  assert query != nil, "query argument is necessary due to required `ReservedDBInstancesOfferingId` field"
  var valid_21627818 = query.getOrDefault("ReservedDBInstancesOfferingId")
  valid_21627818 = validateParameter(valid_21627818, JString, required = true,
                                   default = nil)
  if valid_21627818 != nil:
    section.add "ReservedDBInstancesOfferingId", valid_21627818
  var valid_21627819 = query.getOrDefault("Action")
  valid_21627819 = validateParameter(valid_21627819, JString, required = true, default = newJString(
      "PurchaseReservedDBInstancesOffering"))
  if valid_21627819 != nil:
    section.add "Action", valid_21627819
  var valid_21627820 = query.getOrDefault("Version")
  valid_21627820 = validateParameter(valid_21627820, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627820 != nil:
    section.add "Version", valid_21627820
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
  var valid_21627821 = header.getOrDefault("X-Amz-Date")
  valid_21627821 = validateParameter(valid_21627821, JString, required = false,
                                   default = nil)
  if valid_21627821 != nil:
    section.add "X-Amz-Date", valid_21627821
  var valid_21627822 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627822 = validateParameter(valid_21627822, JString, required = false,
                                   default = nil)
  if valid_21627822 != nil:
    section.add "X-Amz-Security-Token", valid_21627822
  var valid_21627823 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627823 = validateParameter(valid_21627823, JString, required = false,
                                   default = nil)
  if valid_21627823 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627823
  var valid_21627824 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627824 = validateParameter(valid_21627824, JString, required = false,
                                   default = nil)
  if valid_21627824 != nil:
    section.add "X-Amz-Algorithm", valid_21627824
  var valid_21627825 = header.getOrDefault("X-Amz-Signature")
  valid_21627825 = validateParameter(valid_21627825, JString, required = false,
                                   default = nil)
  if valid_21627825 != nil:
    section.add "X-Amz-Signature", valid_21627825
  var valid_21627826 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627826 = validateParameter(valid_21627826, JString, required = false,
                                   default = nil)
  if valid_21627826 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627826
  var valid_21627827 = header.getOrDefault("X-Amz-Credential")
  valid_21627827 = validateParameter(valid_21627827, JString, required = false,
                                   default = nil)
  if valid_21627827 != nil:
    section.add "X-Amz-Credential", valid_21627827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627828: Call_GetPurchaseReservedDBInstancesOffering_21627812;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627828.validator(path, query, header, formData, body, _)
  let scheme = call_21627828.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627828.makeUrl(scheme.get, call_21627828.host, call_21627828.base,
                               call_21627828.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627828, uri, valid, _)

proc call*(call_21627829: Call_GetPurchaseReservedDBInstancesOffering_21627812;
          ReservedDBInstancesOfferingId: string; DBInstanceCount: int = 0;
          Tags: JsonNode = nil; ReservedDBInstanceId: string = "";
          Action: string = "PurchaseReservedDBInstancesOffering";
          Version: string = "2013-09-09"): Recallable =
  ## getPurchaseReservedDBInstancesOffering
  ##   DBInstanceCount: int
  ##   Tags: JArray
  ##   ReservedDBInstanceId: string
  ##   ReservedDBInstancesOfferingId: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627830 = newJObject()
  add(query_21627830, "DBInstanceCount", newJInt(DBInstanceCount))
  if Tags != nil:
    query_21627830.add "Tags", Tags
  add(query_21627830, "ReservedDBInstanceId", newJString(ReservedDBInstanceId))
  add(query_21627830, "ReservedDBInstancesOfferingId",
      newJString(ReservedDBInstancesOfferingId))
  add(query_21627830, "Action", newJString(Action))
  add(query_21627830, "Version", newJString(Version))
  result = call_21627829.call(nil, query_21627830, nil, nil, nil)

var getPurchaseReservedDBInstancesOffering* = Call_GetPurchaseReservedDBInstancesOffering_21627812(
    name: "getPurchaseReservedDBInstancesOffering", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=PurchaseReservedDBInstancesOffering",
    validator: validate_GetPurchaseReservedDBInstancesOffering_21627813,
    base: "/", makeUrl: url_GetPurchaseReservedDBInstancesOffering_21627814,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRebootDBInstance_21627868 = ref object of OpenApiRestCall_21625418
proc url_PostRebootDBInstance_21627870(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRebootDBInstance_21627869(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627871 = query.getOrDefault("Action")
  valid_21627871 = validateParameter(valid_21627871, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627871 != nil:
    section.add "Action", valid_21627871
  var valid_21627872 = query.getOrDefault("Version")
  valid_21627872 = validateParameter(valid_21627872, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627872 != nil:
    section.add "Version", valid_21627872
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
  var valid_21627873 = header.getOrDefault("X-Amz-Date")
  valid_21627873 = validateParameter(valid_21627873, JString, required = false,
                                   default = nil)
  if valid_21627873 != nil:
    section.add "X-Amz-Date", valid_21627873
  var valid_21627874 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627874 = validateParameter(valid_21627874, JString, required = false,
                                   default = nil)
  if valid_21627874 != nil:
    section.add "X-Amz-Security-Token", valid_21627874
  var valid_21627875 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627875 = validateParameter(valid_21627875, JString, required = false,
                                   default = nil)
  if valid_21627875 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627875
  var valid_21627876 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627876 = validateParameter(valid_21627876, JString, required = false,
                                   default = nil)
  if valid_21627876 != nil:
    section.add "X-Amz-Algorithm", valid_21627876
  var valid_21627877 = header.getOrDefault("X-Amz-Signature")
  valid_21627877 = validateParameter(valid_21627877, JString, required = false,
                                   default = nil)
  if valid_21627877 != nil:
    section.add "X-Amz-Signature", valid_21627877
  var valid_21627878 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627878 = validateParameter(valid_21627878, JString, required = false,
                                   default = nil)
  if valid_21627878 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627878
  var valid_21627879 = header.getOrDefault("X-Amz-Credential")
  valid_21627879 = validateParameter(valid_21627879, JString, required = false,
                                   default = nil)
  if valid_21627879 != nil:
    section.add "X-Amz-Credential", valid_21627879
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBInstanceIdentifier: JString (required)
  ##   ForceFailover: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21627880 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21627880 = validateParameter(valid_21627880, JString, required = true,
                                   default = nil)
  if valid_21627880 != nil:
    section.add "DBInstanceIdentifier", valid_21627880
  var valid_21627881 = formData.getOrDefault("ForceFailover")
  valid_21627881 = validateParameter(valid_21627881, JBool, required = false,
                                   default = nil)
  if valid_21627881 != nil:
    section.add "ForceFailover", valid_21627881
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627882: Call_PostRebootDBInstance_21627868; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627882.validator(path, query, header, formData, body, _)
  let scheme = call_21627882.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627882.makeUrl(scheme.get, call_21627882.host, call_21627882.base,
                               call_21627882.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627882, uri, valid, _)

proc call*(call_21627883: Call_PostRebootDBInstance_21627868;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRebootDBInstance
  ##   DBInstanceIdentifier: string (required)
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  var query_21627884 = newJObject()
  var formData_21627885 = newJObject()
  add(formData_21627885, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21627884, "Action", newJString(Action))
  add(formData_21627885, "ForceFailover", newJBool(ForceFailover))
  add(query_21627884, "Version", newJString(Version))
  result = call_21627883.call(nil, query_21627884, nil, formData_21627885, nil)

var postRebootDBInstance* = Call_PostRebootDBInstance_21627868(
    name: "postRebootDBInstance", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_PostRebootDBInstance_21627869, base: "/",
    makeUrl: url_PostRebootDBInstance_21627870,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRebootDBInstance_21627851 = ref object of OpenApiRestCall_21625418
proc url_GetRebootDBInstance_21627853(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRebootDBInstance_21627852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   ForceFailover: JBool
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  section = newJObject()
  var valid_21627854 = query.getOrDefault("Action")
  valid_21627854 = validateParameter(valid_21627854, JString, required = true,
                                   default = newJString("RebootDBInstance"))
  if valid_21627854 != nil:
    section.add "Action", valid_21627854
  var valid_21627855 = query.getOrDefault("ForceFailover")
  valid_21627855 = validateParameter(valid_21627855, JBool, required = false,
                                   default = nil)
  if valid_21627855 != nil:
    section.add "ForceFailover", valid_21627855
  var valid_21627856 = query.getOrDefault("Version")
  valid_21627856 = validateParameter(valid_21627856, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627856 != nil:
    section.add "Version", valid_21627856
  var valid_21627857 = query.getOrDefault("DBInstanceIdentifier")
  valid_21627857 = validateParameter(valid_21627857, JString, required = true,
                                   default = nil)
  if valid_21627857 != nil:
    section.add "DBInstanceIdentifier", valid_21627857
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
  var valid_21627858 = header.getOrDefault("X-Amz-Date")
  valid_21627858 = validateParameter(valid_21627858, JString, required = false,
                                   default = nil)
  if valid_21627858 != nil:
    section.add "X-Amz-Date", valid_21627858
  var valid_21627859 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627859 = validateParameter(valid_21627859, JString, required = false,
                                   default = nil)
  if valid_21627859 != nil:
    section.add "X-Amz-Security-Token", valid_21627859
  var valid_21627860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627860 = validateParameter(valid_21627860, JString, required = false,
                                   default = nil)
  if valid_21627860 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627860
  var valid_21627861 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627861 = validateParameter(valid_21627861, JString, required = false,
                                   default = nil)
  if valid_21627861 != nil:
    section.add "X-Amz-Algorithm", valid_21627861
  var valid_21627862 = header.getOrDefault("X-Amz-Signature")
  valid_21627862 = validateParameter(valid_21627862, JString, required = false,
                                   default = nil)
  if valid_21627862 != nil:
    section.add "X-Amz-Signature", valid_21627862
  var valid_21627863 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627863 = validateParameter(valid_21627863, JString, required = false,
                                   default = nil)
  if valid_21627863 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627863
  var valid_21627864 = header.getOrDefault("X-Amz-Credential")
  valid_21627864 = validateParameter(valid_21627864, JString, required = false,
                                   default = nil)
  if valid_21627864 != nil:
    section.add "X-Amz-Credential", valid_21627864
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627865: Call_GetRebootDBInstance_21627851; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627865.validator(path, query, header, formData, body, _)
  let scheme = call_21627865.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627865.makeUrl(scheme.get, call_21627865.host, call_21627865.base,
                               call_21627865.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627865, uri, valid, _)

proc call*(call_21627866: Call_GetRebootDBInstance_21627851;
          DBInstanceIdentifier: string; Action: string = "RebootDBInstance";
          ForceFailover: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getRebootDBInstance
  ##   Action: string (required)
  ##   ForceFailover: bool
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  var query_21627867 = newJObject()
  add(query_21627867, "Action", newJString(Action))
  add(query_21627867, "ForceFailover", newJBool(ForceFailover))
  add(query_21627867, "Version", newJString(Version))
  add(query_21627867, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  result = call_21627866.call(nil, query_21627867, nil, nil, nil)

var getRebootDBInstance* = Call_GetRebootDBInstance_21627851(
    name: "getRebootDBInstance", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RebootDBInstance",
    validator: validate_GetRebootDBInstance_21627852, base: "/",
    makeUrl: url_GetRebootDBInstance_21627853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveSourceIdentifierFromSubscription_21627903 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveSourceIdentifierFromSubscription_21627905(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveSourceIdentifierFromSubscription_21627904(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627906 = query.getOrDefault("Action")
  valid_21627906 = validateParameter(valid_21627906, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627906 != nil:
    section.add "Action", valid_21627906
  var valid_21627907 = query.getOrDefault("Version")
  valid_21627907 = validateParameter(valid_21627907, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627907 != nil:
    section.add "Version", valid_21627907
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
  var valid_21627908 = header.getOrDefault("X-Amz-Date")
  valid_21627908 = validateParameter(valid_21627908, JString, required = false,
                                   default = nil)
  if valid_21627908 != nil:
    section.add "X-Amz-Date", valid_21627908
  var valid_21627909 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627909 = validateParameter(valid_21627909, JString, required = false,
                                   default = nil)
  if valid_21627909 != nil:
    section.add "X-Amz-Security-Token", valid_21627909
  var valid_21627910 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627910 = validateParameter(valid_21627910, JString, required = false,
                                   default = nil)
  if valid_21627910 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627910
  var valid_21627911 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627911 = validateParameter(valid_21627911, JString, required = false,
                                   default = nil)
  if valid_21627911 != nil:
    section.add "X-Amz-Algorithm", valid_21627911
  var valid_21627912 = header.getOrDefault("X-Amz-Signature")
  valid_21627912 = validateParameter(valid_21627912, JString, required = false,
                                   default = nil)
  if valid_21627912 != nil:
    section.add "X-Amz-Signature", valid_21627912
  var valid_21627913 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627913 = validateParameter(valid_21627913, JString, required = false,
                                   default = nil)
  if valid_21627913 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627913
  var valid_21627914 = header.getOrDefault("X-Amz-Credential")
  valid_21627914 = validateParameter(valid_21627914, JString, required = false,
                                   default = nil)
  if valid_21627914 != nil:
    section.add "X-Amz-Credential", valid_21627914
  result.add "header", section
  ## parameters in `formData` object:
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `SourceIdentifier` field"
  var valid_21627915 = formData.getOrDefault("SourceIdentifier")
  valid_21627915 = validateParameter(valid_21627915, JString, required = true,
                                   default = nil)
  if valid_21627915 != nil:
    section.add "SourceIdentifier", valid_21627915
  var valid_21627916 = formData.getOrDefault("SubscriptionName")
  valid_21627916 = validateParameter(valid_21627916, JString, required = true,
                                   default = nil)
  if valid_21627916 != nil:
    section.add "SubscriptionName", valid_21627916
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627917: Call_PostRemoveSourceIdentifierFromSubscription_21627903;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627917.validator(path, query, header, formData, body, _)
  let scheme = call_21627917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627917.makeUrl(scheme.get, call_21627917.host, call_21627917.base,
                               call_21627917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627917, uri, valid, _)

proc call*(call_21627918: Call_PostRemoveSourceIdentifierFromSubscription_21627903;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## postRemoveSourceIdentifierFromSubscription
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21627919 = newJObject()
  var formData_21627920 = newJObject()
  add(formData_21627920, "SourceIdentifier", newJString(SourceIdentifier))
  add(formData_21627920, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627919, "Action", newJString(Action))
  add(query_21627919, "Version", newJString(Version))
  result = call_21627918.call(nil, query_21627919, nil, formData_21627920, nil)

var postRemoveSourceIdentifierFromSubscription* = Call_PostRemoveSourceIdentifierFromSubscription_21627903(
    name: "postRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_PostRemoveSourceIdentifierFromSubscription_21627904,
    base: "/", makeUrl: url_PostRemoveSourceIdentifierFromSubscription_21627905,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveSourceIdentifierFromSubscription_21627886 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveSourceIdentifierFromSubscription_21627888(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveSourceIdentifierFromSubscription_21627887(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   SourceIdentifier: JString (required)
  ##   SubscriptionName: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627889 = query.getOrDefault("Action")
  valid_21627889 = validateParameter(valid_21627889, JString, required = true, default = newJString(
      "RemoveSourceIdentifierFromSubscription"))
  if valid_21627889 != nil:
    section.add "Action", valid_21627889
  var valid_21627890 = query.getOrDefault("SourceIdentifier")
  valid_21627890 = validateParameter(valid_21627890, JString, required = true,
                                   default = nil)
  if valid_21627890 != nil:
    section.add "SourceIdentifier", valid_21627890
  var valid_21627891 = query.getOrDefault("SubscriptionName")
  valid_21627891 = validateParameter(valid_21627891, JString, required = true,
                                   default = nil)
  if valid_21627891 != nil:
    section.add "SubscriptionName", valid_21627891
  var valid_21627892 = query.getOrDefault("Version")
  valid_21627892 = validateParameter(valid_21627892, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627892 != nil:
    section.add "Version", valid_21627892
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
  var valid_21627893 = header.getOrDefault("X-Amz-Date")
  valid_21627893 = validateParameter(valid_21627893, JString, required = false,
                                   default = nil)
  if valid_21627893 != nil:
    section.add "X-Amz-Date", valid_21627893
  var valid_21627894 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627894 = validateParameter(valid_21627894, JString, required = false,
                                   default = nil)
  if valid_21627894 != nil:
    section.add "X-Amz-Security-Token", valid_21627894
  var valid_21627895 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627895 = validateParameter(valid_21627895, JString, required = false,
                                   default = nil)
  if valid_21627895 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627895
  var valid_21627896 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627896 = validateParameter(valid_21627896, JString, required = false,
                                   default = nil)
  if valid_21627896 != nil:
    section.add "X-Amz-Algorithm", valid_21627896
  var valid_21627897 = header.getOrDefault("X-Amz-Signature")
  valid_21627897 = validateParameter(valid_21627897, JString, required = false,
                                   default = nil)
  if valid_21627897 != nil:
    section.add "X-Amz-Signature", valid_21627897
  var valid_21627898 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627898 = validateParameter(valid_21627898, JString, required = false,
                                   default = nil)
  if valid_21627898 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627898
  var valid_21627899 = header.getOrDefault("X-Amz-Credential")
  valid_21627899 = validateParameter(valid_21627899, JString, required = false,
                                   default = nil)
  if valid_21627899 != nil:
    section.add "X-Amz-Credential", valid_21627899
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627900: Call_GetRemoveSourceIdentifierFromSubscription_21627886;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627900.validator(path, query, header, formData, body, _)
  let scheme = call_21627900.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627900.makeUrl(scheme.get, call_21627900.host, call_21627900.base,
                               call_21627900.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627900, uri, valid, _)

proc call*(call_21627901: Call_GetRemoveSourceIdentifierFromSubscription_21627886;
          SourceIdentifier: string; SubscriptionName: string;
          Action: string = "RemoveSourceIdentifierFromSubscription";
          Version: string = "2013-09-09"): Recallable =
  ## getRemoveSourceIdentifierFromSubscription
  ##   Action: string (required)
  ##   SourceIdentifier: string (required)
  ##   SubscriptionName: string (required)
  ##   Version: string (required)
  var query_21627902 = newJObject()
  add(query_21627902, "Action", newJString(Action))
  add(query_21627902, "SourceIdentifier", newJString(SourceIdentifier))
  add(query_21627902, "SubscriptionName", newJString(SubscriptionName))
  add(query_21627902, "Version", newJString(Version))
  result = call_21627901.call(nil, query_21627902, nil, nil, nil)

var getRemoveSourceIdentifierFromSubscription* = Call_GetRemoveSourceIdentifierFromSubscription_21627886(
    name: "getRemoveSourceIdentifierFromSubscription", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com",
    route: "/#Action=RemoveSourceIdentifierFromSubscription",
    validator: validate_GetRemoveSourceIdentifierFromSubscription_21627887,
    base: "/", makeUrl: url_GetRemoveSourceIdentifierFromSubscription_21627888,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRemoveTagsFromResource_21627938 = ref object of OpenApiRestCall_21625418
proc url_PostRemoveTagsFromResource_21627940(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRemoveTagsFromResource_21627939(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627941 = query.getOrDefault("Action")
  valid_21627941 = validateParameter(valid_21627941, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627941 != nil:
    section.add "Action", valid_21627941
  var valid_21627942 = query.getOrDefault("Version")
  valid_21627942 = validateParameter(valid_21627942, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627942 != nil:
    section.add "Version", valid_21627942
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
  var valid_21627943 = header.getOrDefault("X-Amz-Date")
  valid_21627943 = validateParameter(valid_21627943, JString, required = false,
                                   default = nil)
  if valid_21627943 != nil:
    section.add "X-Amz-Date", valid_21627943
  var valid_21627944 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627944 = validateParameter(valid_21627944, JString, required = false,
                                   default = nil)
  if valid_21627944 != nil:
    section.add "X-Amz-Security-Token", valid_21627944
  var valid_21627945 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627945 = validateParameter(valid_21627945, JString, required = false,
                                   default = nil)
  if valid_21627945 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627945
  var valid_21627946 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627946 = validateParameter(valid_21627946, JString, required = false,
                                   default = nil)
  if valid_21627946 != nil:
    section.add "X-Amz-Algorithm", valid_21627946
  var valid_21627947 = header.getOrDefault("X-Amz-Signature")
  valid_21627947 = validateParameter(valid_21627947, JString, required = false,
                                   default = nil)
  if valid_21627947 != nil:
    section.add "X-Amz-Signature", valid_21627947
  var valid_21627948 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627948 = validateParameter(valid_21627948, JString, required = false,
                                   default = nil)
  if valid_21627948 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627948
  var valid_21627949 = header.getOrDefault("X-Amz-Credential")
  valid_21627949 = validateParameter(valid_21627949, JString, required = false,
                                   default = nil)
  if valid_21627949 != nil:
    section.add "X-Amz-Credential", valid_21627949
  result.add "header", section
  ## parameters in `formData` object:
  ##   TagKeys: JArray (required)
  ##   ResourceName: JString (required)
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `TagKeys` field"
  var valid_21627950 = formData.getOrDefault("TagKeys")
  valid_21627950 = validateParameter(valid_21627950, JArray, required = true,
                                   default = nil)
  if valid_21627950 != nil:
    section.add "TagKeys", valid_21627950
  var valid_21627951 = formData.getOrDefault("ResourceName")
  valid_21627951 = validateParameter(valid_21627951, JString, required = true,
                                   default = nil)
  if valid_21627951 != nil:
    section.add "ResourceName", valid_21627951
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627952: Call_PostRemoveTagsFromResource_21627938;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627952.validator(path, query, header, formData, body, _)
  let scheme = call_21627952.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627952.makeUrl(scheme.get, call_21627952.host, call_21627952.base,
                               call_21627952.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627952, uri, valid, _)

proc call*(call_21627953: Call_PostRemoveTagsFromResource_21627938;
          TagKeys: JsonNode; ResourceName: string;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## postRemoveTagsFromResource
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   ResourceName: string (required)
  ##   Version: string (required)
  var query_21627954 = newJObject()
  var formData_21627955 = newJObject()
  add(query_21627954, "Action", newJString(Action))
  if TagKeys != nil:
    formData_21627955.add "TagKeys", TagKeys
  add(formData_21627955, "ResourceName", newJString(ResourceName))
  add(query_21627954, "Version", newJString(Version))
  result = call_21627953.call(nil, query_21627954, nil, formData_21627955, nil)

var postRemoveTagsFromResource* = Call_PostRemoveTagsFromResource_21627938(
    name: "postRemoveTagsFromResource", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_PostRemoveTagsFromResource_21627939, base: "/",
    makeUrl: url_PostRemoveTagsFromResource_21627940,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRemoveTagsFromResource_21627921 = ref object of OpenApiRestCall_21625418
proc url_GetRemoveTagsFromResource_21627923(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRemoveTagsFromResource_21627922(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   ResourceName: JString (required)
  ##   Action: JString (required)
  ##   TagKeys: JArray (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `ResourceName` field"
  var valid_21627924 = query.getOrDefault("ResourceName")
  valid_21627924 = validateParameter(valid_21627924, JString, required = true,
                                   default = nil)
  if valid_21627924 != nil:
    section.add "ResourceName", valid_21627924
  var valid_21627925 = query.getOrDefault("Action")
  valid_21627925 = validateParameter(valid_21627925, JString, required = true, default = newJString(
      "RemoveTagsFromResource"))
  if valid_21627925 != nil:
    section.add "Action", valid_21627925
  var valid_21627926 = query.getOrDefault("TagKeys")
  valid_21627926 = validateParameter(valid_21627926, JArray, required = true,
                                   default = nil)
  if valid_21627926 != nil:
    section.add "TagKeys", valid_21627926
  var valid_21627927 = query.getOrDefault("Version")
  valid_21627927 = validateParameter(valid_21627927, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627927 != nil:
    section.add "Version", valid_21627927
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
  var valid_21627928 = header.getOrDefault("X-Amz-Date")
  valid_21627928 = validateParameter(valid_21627928, JString, required = false,
                                   default = nil)
  if valid_21627928 != nil:
    section.add "X-Amz-Date", valid_21627928
  var valid_21627929 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627929 = validateParameter(valid_21627929, JString, required = false,
                                   default = nil)
  if valid_21627929 != nil:
    section.add "X-Amz-Security-Token", valid_21627929
  var valid_21627930 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627930 = validateParameter(valid_21627930, JString, required = false,
                                   default = nil)
  if valid_21627930 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627930
  var valid_21627931 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627931 = validateParameter(valid_21627931, JString, required = false,
                                   default = nil)
  if valid_21627931 != nil:
    section.add "X-Amz-Algorithm", valid_21627931
  var valid_21627932 = header.getOrDefault("X-Amz-Signature")
  valid_21627932 = validateParameter(valid_21627932, JString, required = false,
                                   default = nil)
  if valid_21627932 != nil:
    section.add "X-Amz-Signature", valid_21627932
  var valid_21627933 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627933 = validateParameter(valid_21627933, JString, required = false,
                                   default = nil)
  if valid_21627933 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627933
  var valid_21627934 = header.getOrDefault("X-Amz-Credential")
  valid_21627934 = validateParameter(valid_21627934, JString, required = false,
                                   default = nil)
  if valid_21627934 != nil:
    section.add "X-Amz-Credential", valid_21627934
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627935: Call_GetRemoveTagsFromResource_21627921;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627935.validator(path, query, header, formData, body, _)
  let scheme = call_21627935.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627935.makeUrl(scheme.get, call_21627935.host, call_21627935.base,
                               call_21627935.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627935, uri, valid, _)

proc call*(call_21627936: Call_GetRemoveTagsFromResource_21627921;
          ResourceName: string; TagKeys: JsonNode;
          Action: string = "RemoveTagsFromResource"; Version: string = "2013-09-09"): Recallable =
  ## getRemoveTagsFromResource
  ##   ResourceName: string (required)
  ##   Action: string (required)
  ##   TagKeys: JArray (required)
  ##   Version: string (required)
  var query_21627937 = newJObject()
  add(query_21627937, "ResourceName", newJString(ResourceName))
  add(query_21627937, "Action", newJString(Action))
  if TagKeys != nil:
    query_21627937.add "TagKeys", TagKeys
  add(query_21627937, "Version", newJString(Version))
  result = call_21627936.call(nil, query_21627937, nil, nil, nil)

var getRemoveTagsFromResource* = Call_GetRemoveTagsFromResource_21627921(
    name: "getRemoveTagsFromResource", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RemoveTagsFromResource",
    validator: validate_GetRemoveTagsFromResource_21627922, base: "/",
    makeUrl: url_GetRemoveTagsFromResource_21627923,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostResetDBParameterGroup_21627974 = ref object of OpenApiRestCall_21625418
proc url_PostResetDBParameterGroup_21627976(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostResetDBParameterGroup_21627975(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21627977 = query.getOrDefault("Action")
  valid_21627977 = validateParameter(valid_21627977, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21627977 != nil:
    section.add "Action", valid_21627977
  var valid_21627978 = query.getOrDefault("Version")
  valid_21627978 = validateParameter(valid_21627978, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627978 != nil:
    section.add "Version", valid_21627978
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
  var valid_21627979 = header.getOrDefault("X-Amz-Date")
  valid_21627979 = validateParameter(valid_21627979, JString, required = false,
                                   default = nil)
  if valid_21627979 != nil:
    section.add "X-Amz-Date", valid_21627979
  var valid_21627980 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627980 = validateParameter(valid_21627980, JString, required = false,
                                   default = nil)
  if valid_21627980 != nil:
    section.add "X-Amz-Security-Token", valid_21627980
  var valid_21627981 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627981 = validateParameter(valid_21627981, JString, required = false,
                                   default = nil)
  if valid_21627981 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627981
  var valid_21627982 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627982 = validateParameter(valid_21627982, JString, required = false,
                                   default = nil)
  if valid_21627982 != nil:
    section.add "X-Amz-Algorithm", valid_21627982
  var valid_21627983 = header.getOrDefault("X-Amz-Signature")
  valid_21627983 = validateParameter(valid_21627983, JString, required = false,
                                   default = nil)
  if valid_21627983 != nil:
    section.add "X-Amz-Signature", valid_21627983
  var valid_21627984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627984 = validateParameter(valid_21627984, JString, required = false,
                                   default = nil)
  if valid_21627984 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627984
  var valid_21627985 = header.getOrDefault("X-Amz-Credential")
  valid_21627985 = validateParameter(valid_21627985, JString, required = false,
                                   default = nil)
  if valid_21627985 != nil:
    section.add "X-Amz-Credential", valid_21627985
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   ResetAllParameters: JBool
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627986 = formData.getOrDefault("DBParameterGroupName")
  valid_21627986 = validateParameter(valid_21627986, JString, required = true,
                                   default = nil)
  if valid_21627986 != nil:
    section.add "DBParameterGroupName", valid_21627986
  var valid_21627987 = formData.getOrDefault("Parameters")
  valid_21627987 = validateParameter(valid_21627987, JArray, required = false,
                                   default = nil)
  if valid_21627987 != nil:
    section.add "Parameters", valid_21627987
  var valid_21627988 = formData.getOrDefault("ResetAllParameters")
  valid_21627988 = validateParameter(valid_21627988, JBool, required = false,
                                   default = nil)
  if valid_21627988 != nil:
    section.add "ResetAllParameters", valid_21627988
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627989: Call_PostResetDBParameterGroup_21627974;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627989.validator(path, query, header, formData, body, _)
  let scheme = call_21627989.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627989.makeUrl(scheme.get, call_21627989.host, call_21627989.base,
                               call_21627989.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627989, uri, valid, _)

proc call*(call_21627990: Call_PostResetDBParameterGroup_21627974;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21627991 = newJObject()
  var formData_21627992 = newJObject()
  add(formData_21627992, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    formData_21627992.add "Parameters", Parameters
  add(query_21627991, "Action", newJString(Action))
  add(formData_21627992, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627991, "Version", newJString(Version))
  result = call_21627990.call(nil, query_21627991, nil, formData_21627992, nil)

var postResetDBParameterGroup* = Call_PostResetDBParameterGroup_21627974(
    name: "postResetDBParameterGroup", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_PostResetDBParameterGroup_21627975, base: "/",
    makeUrl: url_PostResetDBParameterGroup_21627976,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetResetDBParameterGroup_21627956 = ref object of OpenApiRestCall_21625418
proc url_GetResetDBParameterGroup_21627958(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetResetDBParameterGroup_21627957(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DBParameterGroupName: JString (required)
  ##   Parameters: JArray
  ##   Action: JString (required)
  ##   ResetAllParameters: JBool
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `DBParameterGroupName` field"
  var valid_21627959 = query.getOrDefault("DBParameterGroupName")
  valid_21627959 = validateParameter(valid_21627959, JString, required = true,
                                   default = nil)
  if valid_21627959 != nil:
    section.add "DBParameterGroupName", valid_21627959
  var valid_21627960 = query.getOrDefault("Parameters")
  valid_21627960 = validateParameter(valid_21627960, JArray, required = false,
                                   default = nil)
  if valid_21627960 != nil:
    section.add "Parameters", valid_21627960
  var valid_21627961 = query.getOrDefault("Action")
  valid_21627961 = validateParameter(valid_21627961, JString, required = true, default = newJString(
      "ResetDBParameterGroup"))
  if valid_21627961 != nil:
    section.add "Action", valid_21627961
  var valid_21627962 = query.getOrDefault("ResetAllParameters")
  valid_21627962 = validateParameter(valid_21627962, JBool, required = false,
                                   default = nil)
  if valid_21627962 != nil:
    section.add "ResetAllParameters", valid_21627962
  var valid_21627963 = query.getOrDefault("Version")
  valid_21627963 = validateParameter(valid_21627963, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21627963 != nil:
    section.add "Version", valid_21627963
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
  var valid_21627964 = header.getOrDefault("X-Amz-Date")
  valid_21627964 = validateParameter(valid_21627964, JString, required = false,
                                   default = nil)
  if valid_21627964 != nil:
    section.add "X-Amz-Date", valid_21627964
  var valid_21627965 = header.getOrDefault("X-Amz-Security-Token")
  valid_21627965 = validateParameter(valid_21627965, JString, required = false,
                                   default = nil)
  if valid_21627965 != nil:
    section.add "X-Amz-Security-Token", valid_21627965
  var valid_21627966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21627966 = validateParameter(valid_21627966, JString, required = false,
                                   default = nil)
  if valid_21627966 != nil:
    section.add "X-Amz-Content-Sha256", valid_21627966
  var valid_21627967 = header.getOrDefault("X-Amz-Algorithm")
  valid_21627967 = validateParameter(valid_21627967, JString, required = false,
                                   default = nil)
  if valid_21627967 != nil:
    section.add "X-Amz-Algorithm", valid_21627967
  var valid_21627968 = header.getOrDefault("X-Amz-Signature")
  valid_21627968 = validateParameter(valid_21627968, JString, required = false,
                                   default = nil)
  if valid_21627968 != nil:
    section.add "X-Amz-Signature", valid_21627968
  var valid_21627969 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21627969 = validateParameter(valid_21627969, JString, required = false,
                                   default = nil)
  if valid_21627969 != nil:
    section.add "X-Amz-SignedHeaders", valid_21627969
  var valid_21627970 = header.getOrDefault("X-Amz-Credential")
  valid_21627970 = validateParameter(valid_21627970, JString, required = false,
                                   default = nil)
  if valid_21627970 != nil:
    section.add "X-Amz-Credential", valid_21627970
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21627971: Call_GetResetDBParameterGroup_21627956;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21627971.validator(path, query, header, formData, body, _)
  let scheme = call_21627971.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21627971.makeUrl(scheme.get, call_21627971.host, call_21627971.base,
                               call_21627971.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21627971, uri, valid, _)

proc call*(call_21627972: Call_GetResetDBParameterGroup_21627956;
          DBParameterGroupName: string; Parameters: JsonNode = nil;
          Action: string = "ResetDBParameterGroup";
          ResetAllParameters: bool = false; Version: string = "2013-09-09"): Recallable =
  ## getResetDBParameterGroup
  ##   DBParameterGroupName: string (required)
  ##   Parameters: JArray
  ##   Action: string (required)
  ##   ResetAllParameters: bool
  ##   Version: string (required)
  var query_21627973 = newJObject()
  add(query_21627973, "DBParameterGroupName", newJString(DBParameterGroupName))
  if Parameters != nil:
    query_21627973.add "Parameters", Parameters
  add(query_21627973, "Action", newJString(Action))
  add(query_21627973, "ResetAllParameters", newJBool(ResetAllParameters))
  add(query_21627973, "Version", newJString(Version))
  result = call_21627972.call(nil, query_21627973, nil, nil, nil)

var getResetDBParameterGroup* = Call_GetResetDBParameterGroup_21627956(
    name: "getResetDBParameterGroup", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=ResetDBParameterGroup",
    validator: validate_GetResetDBParameterGroup_21627957, base: "/",
    makeUrl: url_GetResetDBParameterGroup_21627958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceFromDBSnapshot_21628023 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceFromDBSnapshot_21628025(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceFromDBSnapshot_21628024(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628026 = query.getOrDefault("Action")
  valid_21628026 = validateParameter(valid_21628026, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21628026 != nil:
    section.add "Action", valid_21628026
  var valid_21628027 = query.getOrDefault("Version")
  valid_21628027 = validateParameter(valid_21628027, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628027 != nil:
    section.add "Version", valid_21628027
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
  var valid_21628028 = header.getOrDefault("X-Amz-Date")
  valid_21628028 = validateParameter(valid_21628028, JString, required = false,
                                   default = nil)
  if valid_21628028 != nil:
    section.add "X-Amz-Date", valid_21628028
  var valid_21628029 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628029 = validateParameter(valid_21628029, JString, required = false,
                                   default = nil)
  if valid_21628029 != nil:
    section.add "X-Amz-Security-Token", valid_21628029
  var valid_21628030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628030 = validateParameter(valid_21628030, JString, required = false,
                                   default = nil)
  if valid_21628030 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628030
  var valid_21628031 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628031 = validateParameter(valid_21628031, JString, required = false,
                                   default = nil)
  if valid_21628031 != nil:
    section.add "X-Amz-Algorithm", valid_21628031
  var valid_21628032 = header.getOrDefault("X-Amz-Signature")
  valid_21628032 = validateParameter(valid_21628032, JString, required = false,
                                   default = nil)
  if valid_21628032 != nil:
    section.add "X-Amz-Signature", valid_21628032
  var valid_21628033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628033 = validateParameter(valid_21628033, JString, required = false,
                                   default = nil)
  if valid_21628033 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628033
  var valid_21628034 = header.getOrDefault("X-Amz-Credential")
  valid_21628034 = validateParameter(valid_21628034, JString, required = false,
                                   default = nil)
  if valid_21628034 != nil:
    section.add "X-Amz-Credential", valid_21628034
  result.add "header", section
  ## parameters in `formData` object:
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   DBInstanceIdentifier: JString (required)
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   DBSnapshotIdentifier: JString (required)
  ##   PubliclyAccessible: JBool
  ##   DBInstanceClass: JString
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21628035 = formData.getOrDefault("Port")
  valid_21628035 = validateParameter(valid_21628035, JInt, required = false,
                                   default = nil)
  if valid_21628035 != nil:
    section.add "Port", valid_21628035
  var valid_21628036 = formData.getOrDefault("Engine")
  valid_21628036 = validateParameter(valid_21628036, JString, required = false,
                                   default = nil)
  if valid_21628036 != nil:
    section.add "Engine", valid_21628036
  var valid_21628037 = formData.getOrDefault("Iops")
  valid_21628037 = validateParameter(valid_21628037, JInt, required = false,
                                   default = nil)
  if valid_21628037 != nil:
    section.add "Iops", valid_21628037
  var valid_21628038 = formData.getOrDefault("DBName")
  valid_21628038 = validateParameter(valid_21628038, JString, required = false,
                                   default = nil)
  if valid_21628038 != nil:
    section.add "DBName", valid_21628038
  assert formData != nil, "formData argument is necessary due to required `DBInstanceIdentifier` field"
  var valid_21628039 = formData.getOrDefault("DBInstanceIdentifier")
  valid_21628039 = validateParameter(valid_21628039, JString, required = true,
                                   default = nil)
  if valid_21628039 != nil:
    section.add "DBInstanceIdentifier", valid_21628039
  var valid_21628040 = formData.getOrDefault("OptionGroupName")
  valid_21628040 = validateParameter(valid_21628040, JString, required = false,
                                   default = nil)
  if valid_21628040 != nil:
    section.add "OptionGroupName", valid_21628040
  var valid_21628041 = formData.getOrDefault("Tags")
  valid_21628041 = validateParameter(valid_21628041, JArray, required = false,
                                   default = nil)
  if valid_21628041 != nil:
    section.add "Tags", valid_21628041
  var valid_21628042 = formData.getOrDefault("DBSubnetGroupName")
  valid_21628042 = validateParameter(valid_21628042, JString, required = false,
                                   default = nil)
  if valid_21628042 != nil:
    section.add "DBSubnetGroupName", valid_21628042
  var valid_21628043 = formData.getOrDefault("AvailabilityZone")
  valid_21628043 = validateParameter(valid_21628043, JString, required = false,
                                   default = nil)
  if valid_21628043 != nil:
    section.add "AvailabilityZone", valid_21628043
  var valid_21628044 = formData.getOrDefault("MultiAZ")
  valid_21628044 = validateParameter(valid_21628044, JBool, required = false,
                                   default = nil)
  if valid_21628044 != nil:
    section.add "MultiAZ", valid_21628044
  var valid_21628045 = formData.getOrDefault("DBSnapshotIdentifier")
  valid_21628045 = validateParameter(valid_21628045, JString, required = true,
                                   default = nil)
  if valid_21628045 != nil:
    section.add "DBSnapshotIdentifier", valid_21628045
  var valid_21628046 = formData.getOrDefault("PubliclyAccessible")
  valid_21628046 = validateParameter(valid_21628046, JBool, required = false,
                                   default = nil)
  if valid_21628046 != nil:
    section.add "PubliclyAccessible", valid_21628046
  var valid_21628047 = formData.getOrDefault("DBInstanceClass")
  valid_21628047 = validateParameter(valid_21628047, JString, required = false,
                                   default = nil)
  if valid_21628047 != nil:
    section.add "DBInstanceClass", valid_21628047
  var valid_21628048 = formData.getOrDefault("LicenseModel")
  valid_21628048 = validateParameter(valid_21628048, JString, required = false,
                                   default = nil)
  if valid_21628048 != nil:
    section.add "LicenseModel", valid_21628048
  var valid_21628049 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628049 = validateParameter(valid_21628049, JBool, required = false,
                                   default = nil)
  if valid_21628049 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628049
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628050: Call_PostRestoreDBInstanceFromDBSnapshot_21628023;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628050.validator(path, query, header, formData, body, _)
  let scheme = call_21628050.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628050.makeUrl(scheme.get, call_21628050.host, call_21628050.base,
                               call_21628050.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628050, uri, valid, _)

proc call*(call_21628051: Call_PostRestoreDBInstanceFromDBSnapshot_21628023;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string; Port: int = 0;
          Engine: string = ""; Iops: int = 0; DBName: string = "";
          OptionGroupName: string = ""; Tags: JsonNode = nil;
          DBSubnetGroupName: string = ""; AvailabilityZone: string = "";
          MultiAZ: bool = false; Action: string = "RestoreDBInstanceFromDBSnapshot";
          PubliclyAccessible: bool = false; DBInstanceClass: string = "";
          LicenseModel: string = ""; AutoMinorVersionUpgrade: bool = false;
          Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceFromDBSnapshot
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   DBInstanceIdentifier: string (required)
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   DBSnapshotIdentifier: string (required)
  ##   Action: string (required)
  ##   PubliclyAccessible: bool
  ##   DBInstanceClass: string
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21628052 = newJObject()
  var formData_21628053 = newJObject()
  add(formData_21628053, "Port", newJInt(Port))
  add(formData_21628053, "Engine", newJString(Engine))
  add(formData_21628053, "Iops", newJInt(Iops))
  add(formData_21628053, "DBName", newJString(DBName))
  add(formData_21628053, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(formData_21628053, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21628053.add "Tags", Tags
  add(formData_21628053, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21628053, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21628053, "MultiAZ", newJBool(MultiAZ))
  add(formData_21628053, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  add(query_21628052, "Action", newJString(Action))
  add(formData_21628053, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21628053, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21628053, "LicenseModel", newJString(LicenseModel))
  add(formData_21628053, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21628052, "Version", newJString(Version))
  result = call_21628051.call(nil, query_21628052, nil, formData_21628053, nil)

var postRestoreDBInstanceFromDBSnapshot* = Call_PostRestoreDBInstanceFromDBSnapshot_21628023(
    name: "postRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_PostRestoreDBInstanceFromDBSnapshot_21628024, base: "/",
    makeUrl: url_PostRestoreDBInstanceFromDBSnapshot_21628025,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceFromDBSnapshot_21627993 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceFromDBSnapshot_21627995(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceFromDBSnapshot_21627994(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   OptionGroupName: JString
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  ##   DBInstanceIdentifier: JString (required)
  ##   DBSnapshotIdentifier: JString (required)
  section = newJObject()
  var valid_21627996 = query.getOrDefault("Engine")
  valid_21627996 = validateParameter(valid_21627996, JString, required = false,
                                   default = nil)
  if valid_21627996 != nil:
    section.add "Engine", valid_21627996
  var valid_21627997 = query.getOrDefault("OptionGroupName")
  valid_21627997 = validateParameter(valid_21627997, JString, required = false,
                                   default = nil)
  if valid_21627997 != nil:
    section.add "OptionGroupName", valid_21627997
  var valid_21627998 = query.getOrDefault("AvailabilityZone")
  valid_21627998 = validateParameter(valid_21627998, JString, required = false,
                                   default = nil)
  if valid_21627998 != nil:
    section.add "AvailabilityZone", valid_21627998
  var valid_21627999 = query.getOrDefault("Iops")
  valid_21627999 = validateParameter(valid_21627999, JInt, required = false,
                                   default = nil)
  if valid_21627999 != nil:
    section.add "Iops", valid_21627999
  var valid_21628000 = query.getOrDefault("MultiAZ")
  valid_21628000 = validateParameter(valid_21628000, JBool, required = false,
                                   default = nil)
  if valid_21628000 != nil:
    section.add "MultiAZ", valid_21628000
  var valid_21628001 = query.getOrDefault("LicenseModel")
  valid_21628001 = validateParameter(valid_21628001, JString, required = false,
                                   default = nil)
  if valid_21628001 != nil:
    section.add "LicenseModel", valid_21628001
  var valid_21628002 = query.getOrDefault("Tags")
  valid_21628002 = validateParameter(valid_21628002, JArray, required = false,
                                   default = nil)
  if valid_21628002 != nil:
    section.add "Tags", valid_21628002
  var valid_21628003 = query.getOrDefault("DBName")
  valid_21628003 = validateParameter(valid_21628003, JString, required = false,
                                   default = nil)
  if valid_21628003 != nil:
    section.add "DBName", valid_21628003
  var valid_21628004 = query.getOrDefault("DBInstanceClass")
  valid_21628004 = validateParameter(valid_21628004, JString, required = false,
                                   default = nil)
  if valid_21628004 != nil:
    section.add "DBInstanceClass", valid_21628004
  var valid_21628005 = query.getOrDefault("Action")
  valid_21628005 = validateParameter(valid_21628005, JString, required = true, default = newJString(
      "RestoreDBInstanceFromDBSnapshot"))
  if valid_21628005 != nil:
    section.add "Action", valid_21628005
  var valid_21628006 = query.getOrDefault("DBSubnetGroupName")
  valid_21628006 = validateParameter(valid_21628006, JString, required = false,
                                   default = nil)
  if valid_21628006 != nil:
    section.add "DBSubnetGroupName", valid_21628006
  var valid_21628007 = query.getOrDefault("PubliclyAccessible")
  valid_21628007 = validateParameter(valid_21628007, JBool, required = false,
                                   default = nil)
  if valid_21628007 != nil:
    section.add "PubliclyAccessible", valid_21628007
  var valid_21628008 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628008 = validateParameter(valid_21628008, JBool, required = false,
                                   default = nil)
  if valid_21628008 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628008
  var valid_21628009 = query.getOrDefault("Port")
  valid_21628009 = validateParameter(valid_21628009, JInt, required = false,
                                   default = nil)
  if valid_21628009 != nil:
    section.add "Port", valid_21628009
  var valid_21628010 = query.getOrDefault("Version")
  valid_21628010 = validateParameter(valid_21628010, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628010 != nil:
    section.add "Version", valid_21628010
  var valid_21628011 = query.getOrDefault("DBInstanceIdentifier")
  valid_21628011 = validateParameter(valid_21628011, JString, required = true,
                                   default = nil)
  if valid_21628011 != nil:
    section.add "DBInstanceIdentifier", valid_21628011
  var valid_21628012 = query.getOrDefault("DBSnapshotIdentifier")
  valid_21628012 = validateParameter(valid_21628012, JString, required = true,
                                   default = nil)
  if valid_21628012 != nil:
    section.add "DBSnapshotIdentifier", valid_21628012
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
  var valid_21628013 = header.getOrDefault("X-Amz-Date")
  valid_21628013 = validateParameter(valid_21628013, JString, required = false,
                                   default = nil)
  if valid_21628013 != nil:
    section.add "X-Amz-Date", valid_21628013
  var valid_21628014 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628014 = validateParameter(valid_21628014, JString, required = false,
                                   default = nil)
  if valid_21628014 != nil:
    section.add "X-Amz-Security-Token", valid_21628014
  var valid_21628015 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628015 = validateParameter(valid_21628015, JString, required = false,
                                   default = nil)
  if valid_21628015 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628015
  var valid_21628016 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628016 = validateParameter(valid_21628016, JString, required = false,
                                   default = nil)
  if valid_21628016 != nil:
    section.add "X-Amz-Algorithm", valid_21628016
  var valid_21628017 = header.getOrDefault("X-Amz-Signature")
  valid_21628017 = validateParameter(valid_21628017, JString, required = false,
                                   default = nil)
  if valid_21628017 != nil:
    section.add "X-Amz-Signature", valid_21628017
  var valid_21628018 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628018 = validateParameter(valid_21628018, JString, required = false,
                                   default = nil)
  if valid_21628018 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628018
  var valid_21628019 = header.getOrDefault("X-Amz-Credential")
  valid_21628019 = validateParameter(valid_21628019, JString, required = false,
                                   default = nil)
  if valid_21628019 != nil:
    section.add "X-Amz-Credential", valid_21628019
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628020: Call_GetRestoreDBInstanceFromDBSnapshot_21627993;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628020.validator(path, query, header, formData, body, _)
  let scheme = call_21628020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628020.makeUrl(scheme.get, call_21628020.host, call_21628020.base,
                               call_21628020.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628020, uri, valid, _)

proc call*(call_21628021: Call_GetRestoreDBInstanceFromDBSnapshot_21627993;
          DBInstanceIdentifier: string; DBSnapshotIdentifier: string;
          Engine: string = ""; OptionGroupName: string = "";
          AvailabilityZone: string = ""; Iops: int = 0; MultiAZ: bool = false;
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceFromDBSnapshot";
          DBSubnetGroupName: string = ""; PubliclyAccessible: bool = false;
          AutoMinorVersionUpgrade: bool = false; Port: int = 0;
          Version: string = "2013-09-09"): Recallable =
  ## getRestoreDBInstanceFromDBSnapshot
  ##   Engine: string
  ##   OptionGroupName: string
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  ##   DBInstanceIdentifier: string (required)
  ##   DBSnapshotIdentifier: string (required)
  var query_21628022 = newJObject()
  add(query_21628022, "Engine", newJString(Engine))
  add(query_21628022, "OptionGroupName", newJString(OptionGroupName))
  add(query_21628022, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21628022, "Iops", newJInt(Iops))
  add(query_21628022, "MultiAZ", newJBool(MultiAZ))
  add(query_21628022, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_21628022.add "Tags", Tags
  add(query_21628022, "DBName", newJString(DBName))
  add(query_21628022, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21628022, "Action", newJString(Action))
  add(query_21628022, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21628022, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21628022, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21628022, "Port", newJInt(Port))
  add(query_21628022, "Version", newJString(Version))
  add(query_21628022, "DBInstanceIdentifier", newJString(DBInstanceIdentifier))
  add(query_21628022, "DBSnapshotIdentifier", newJString(DBSnapshotIdentifier))
  result = call_21628021.call(nil, query_21628022, nil, nil, nil)

var getRestoreDBInstanceFromDBSnapshot* = Call_GetRestoreDBInstanceFromDBSnapshot_21627993(
    name: "getRestoreDBInstanceFromDBSnapshot", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceFromDBSnapshot",
    validator: validate_GetRestoreDBInstanceFromDBSnapshot_21627994, base: "/",
    makeUrl: url_GetRestoreDBInstanceFromDBSnapshot_21627995,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRestoreDBInstanceToPointInTime_21628086 = ref object of OpenApiRestCall_21625418
proc url_PostRestoreDBInstanceToPointInTime_21628088(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRestoreDBInstanceToPointInTime_21628087(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628089 = query.getOrDefault("Action")
  valid_21628089 = validateParameter(valid_21628089, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21628089 != nil:
    section.add "Action", valid_21628089
  var valid_21628090 = query.getOrDefault("Version")
  valid_21628090 = validateParameter(valid_21628090, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628090 != nil:
    section.add "Version", valid_21628090
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
  var valid_21628091 = header.getOrDefault("X-Amz-Date")
  valid_21628091 = validateParameter(valid_21628091, JString, required = false,
                                   default = nil)
  if valid_21628091 != nil:
    section.add "X-Amz-Date", valid_21628091
  var valid_21628092 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628092 = validateParameter(valid_21628092, JString, required = false,
                                   default = nil)
  if valid_21628092 != nil:
    section.add "X-Amz-Security-Token", valid_21628092
  var valid_21628093 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628093 = validateParameter(valid_21628093, JString, required = false,
                                   default = nil)
  if valid_21628093 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628093
  var valid_21628094 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628094 = validateParameter(valid_21628094, JString, required = false,
                                   default = nil)
  if valid_21628094 != nil:
    section.add "X-Amz-Algorithm", valid_21628094
  var valid_21628095 = header.getOrDefault("X-Amz-Signature")
  valid_21628095 = validateParameter(valid_21628095, JString, required = false,
                                   default = nil)
  if valid_21628095 != nil:
    section.add "X-Amz-Signature", valid_21628095
  var valid_21628096 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628096 = validateParameter(valid_21628096, JString, required = false,
                                   default = nil)
  if valid_21628096 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628096
  var valid_21628097 = header.getOrDefault("X-Amz-Credential")
  valid_21628097 = validateParameter(valid_21628097, JString, required = false,
                                   default = nil)
  if valid_21628097 != nil:
    section.add "X-Amz-Credential", valid_21628097
  result.add "header", section
  ## parameters in `formData` object:
  ##   UseLatestRestorableTime: JBool
  ##   Port: JInt
  ##   Engine: JString
  ##   Iops: JInt
  ##   DBName: JString
  ##   OptionGroupName: JString
  ##   Tags: JArray
  ##   DBSubnetGroupName: JString
  ##   AvailabilityZone: JString
  ##   MultiAZ: JBool
  ##   RestoreTime: JString
  ##   PubliclyAccessible: JBool
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   DBInstanceClass: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   LicenseModel: JString
  ##   AutoMinorVersionUpgrade: JBool
  section = newJObject()
  var valid_21628098 = formData.getOrDefault("UseLatestRestorableTime")
  valid_21628098 = validateParameter(valid_21628098, JBool, required = false,
                                   default = nil)
  if valid_21628098 != nil:
    section.add "UseLatestRestorableTime", valid_21628098
  var valid_21628099 = formData.getOrDefault("Port")
  valid_21628099 = validateParameter(valid_21628099, JInt, required = false,
                                   default = nil)
  if valid_21628099 != nil:
    section.add "Port", valid_21628099
  var valid_21628100 = formData.getOrDefault("Engine")
  valid_21628100 = validateParameter(valid_21628100, JString, required = false,
                                   default = nil)
  if valid_21628100 != nil:
    section.add "Engine", valid_21628100
  var valid_21628101 = formData.getOrDefault("Iops")
  valid_21628101 = validateParameter(valid_21628101, JInt, required = false,
                                   default = nil)
  if valid_21628101 != nil:
    section.add "Iops", valid_21628101
  var valid_21628102 = formData.getOrDefault("DBName")
  valid_21628102 = validateParameter(valid_21628102, JString, required = false,
                                   default = nil)
  if valid_21628102 != nil:
    section.add "DBName", valid_21628102
  var valid_21628103 = formData.getOrDefault("OptionGroupName")
  valid_21628103 = validateParameter(valid_21628103, JString, required = false,
                                   default = nil)
  if valid_21628103 != nil:
    section.add "OptionGroupName", valid_21628103
  var valid_21628104 = formData.getOrDefault("Tags")
  valid_21628104 = validateParameter(valid_21628104, JArray, required = false,
                                   default = nil)
  if valid_21628104 != nil:
    section.add "Tags", valid_21628104
  var valid_21628105 = formData.getOrDefault("DBSubnetGroupName")
  valid_21628105 = validateParameter(valid_21628105, JString, required = false,
                                   default = nil)
  if valid_21628105 != nil:
    section.add "DBSubnetGroupName", valid_21628105
  var valid_21628106 = formData.getOrDefault("AvailabilityZone")
  valid_21628106 = validateParameter(valid_21628106, JString, required = false,
                                   default = nil)
  if valid_21628106 != nil:
    section.add "AvailabilityZone", valid_21628106
  var valid_21628107 = formData.getOrDefault("MultiAZ")
  valid_21628107 = validateParameter(valid_21628107, JBool, required = false,
                                   default = nil)
  if valid_21628107 != nil:
    section.add "MultiAZ", valid_21628107
  var valid_21628108 = formData.getOrDefault("RestoreTime")
  valid_21628108 = validateParameter(valid_21628108, JString, required = false,
                                   default = nil)
  if valid_21628108 != nil:
    section.add "RestoreTime", valid_21628108
  var valid_21628109 = formData.getOrDefault("PubliclyAccessible")
  valid_21628109 = validateParameter(valid_21628109, JBool, required = false,
                                   default = nil)
  if valid_21628109 != nil:
    section.add "PubliclyAccessible", valid_21628109
  assert formData != nil, "formData argument is necessary due to required `TargetDBInstanceIdentifier` field"
  var valid_21628110 = formData.getOrDefault("TargetDBInstanceIdentifier")
  valid_21628110 = validateParameter(valid_21628110, JString, required = true,
                                   default = nil)
  if valid_21628110 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21628110
  var valid_21628111 = formData.getOrDefault("DBInstanceClass")
  valid_21628111 = validateParameter(valid_21628111, JString, required = false,
                                   default = nil)
  if valid_21628111 != nil:
    section.add "DBInstanceClass", valid_21628111
  var valid_21628112 = formData.getOrDefault("SourceDBInstanceIdentifier")
  valid_21628112 = validateParameter(valid_21628112, JString, required = true,
                                   default = nil)
  if valid_21628112 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21628112
  var valid_21628113 = formData.getOrDefault("LicenseModel")
  valid_21628113 = validateParameter(valid_21628113, JString, required = false,
                                   default = nil)
  if valid_21628113 != nil:
    section.add "LicenseModel", valid_21628113
  var valid_21628114 = formData.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628114 = validateParameter(valid_21628114, JBool, required = false,
                                   default = nil)
  if valid_21628114 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628114
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628115: Call_PostRestoreDBInstanceToPointInTime_21628086;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628115.validator(path, query, header, formData, body, _)
  let scheme = call_21628115.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628115.makeUrl(scheme.get, call_21628115.host, call_21628115.base,
                               call_21628115.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628115, uri, valid, _)

proc call*(call_21628116: Call_PostRestoreDBInstanceToPointInTime_21628086;
          TargetDBInstanceIdentifier: string; SourceDBInstanceIdentifier: string;
          UseLatestRestorableTime: bool = false; Port: int = 0; Engine: string = "";
          Iops: int = 0; DBName: string = ""; OptionGroupName: string = "";
          Tags: JsonNode = nil; DBSubnetGroupName: string = "";
          AvailabilityZone: string = ""; MultiAZ: bool = false;
          Action: string = "RestoreDBInstanceToPointInTime";
          RestoreTime: string = ""; PubliclyAccessible: bool = false;
          DBInstanceClass: string = ""; LicenseModel: string = "";
          AutoMinorVersionUpgrade: bool = false; Version: string = "2013-09-09"): Recallable =
  ## postRestoreDBInstanceToPointInTime
  ##   UseLatestRestorableTime: bool
  ##   Port: int
  ##   Engine: string
  ##   Iops: int
  ##   DBName: string
  ##   OptionGroupName: string
  ##   Tags: JArray
  ##   DBSubnetGroupName: string
  ##   AvailabilityZone: string
  ##   MultiAZ: bool
  ##   Action: string (required)
  ##   RestoreTime: string
  ##   PubliclyAccessible: bool
  ##   TargetDBInstanceIdentifier: string (required)
  ##   DBInstanceClass: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   LicenseModel: string
  ##   AutoMinorVersionUpgrade: bool
  ##   Version: string (required)
  var query_21628117 = newJObject()
  var formData_21628118 = newJObject()
  add(formData_21628118, "UseLatestRestorableTime",
      newJBool(UseLatestRestorableTime))
  add(formData_21628118, "Port", newJInt(Port))
  add(formData_21628118, "Engine", newJString(Engine))
  add(formData_21628118, "Iops", newJInt(Iops))
  add(formData_21628118, "DBName", newJString(DBName))
  add(formData_21628118, "OptionGroupName", newJString(OptionGroupName))
  if Tags != nil:
    formData_21628118.add "Tags", Tags
  add(formData_21628118, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(formData_21628118, "AvailabilityZone", newJString(AvailabilityZone))
  add(formData_21628118, "MultiAZ", newJBool(MultiAZ))
  add(query_21628117, "Action", newJString(Action))
  add(formData_21628118, "RestoreTime", newJString(RestoreTime))
  add(formData_21628118, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(formData_21628118, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(formData_21628118, "DBInstanceClass", newJString(DBInstanceClass))
  add(formData_21628118, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(formData_21628118, "LicenseModel", newJString(LicenseModel))
  add(formData_21628118, "AutoMinorVersionUpgrade",
      newJBool(AutoMinorVersionUpgrade))
  add(query_21628117, "Version", newJString(Version))
  result = call_21628116.call(nil, query_21628117, nil, formData_21628118, nil)

var postRestoreDBInstanceToPointInTime* = Call_PostRestoreDBInstanceToPointInTime_21628086(
    name: "postRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_PostRestoreDBInstanceToPointInTime_21628087, base: "/",
    makeUrl: url_PostRestoreDBInstanceToPointInTime_21628088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRestoreDBInstanceToPointInTime_21628054 = ref object of OpenApiRestCall_21625418
proc url_GetRestoreDBInstanceToPointInTime_21628056(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRestoreDBInstanceToPointInTime_21628055(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Engine: JString
  ##   SourceDBInstanceIdentifier: JString (required)
  ##   TargetDBInstanceIdentifier: JString (required)
  ##   AvailabilityZone: JString
  ##   Iops: JInt
  ##   OptionGroupName: JString
  ##   RestoreTime: JString
  ##   MultiAZ: JBool
  ##   LicenseModel: JString
  ##   Tags: JArray
  ##   DBName: JString
  ##   DBInstanceClass: JString
  ##   Action: JString (required)
  ##   UseLatestRestorableTime: JBool
  ##   DBSubnetGroupName: JString
  ##   PubliclyAccessible: JBool
  ##   AutoMinorVersionUpgrade: JBool
  ##   Port: JInt
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628057 = query.getOrDefault("Engine")
  valid_21628057 = validateParameter(valid_21628057, JString, required = false,
                                   default = nil)
  if valid_21628057 != nil:
    section.add "Engine", valid_21628057
  assert query != nil, "query argument is necessary due to required `SourceDBInstanceIdentifier` field"
  var valid_21628058 = query.getOrDefault("SourceDBInstanceIdentifier")
  valid_21628058 = validateParameter(valid_21628058, JString, required = true,
                                   default = nil)
  if valid_21628058 != nil:
    section.add "SourceDBInstanceIdentifier", valid_21628058
  var valid_21628059 = query.getOrDefault("TargetDBInstanceIdentifier")
  valid_21628059 = validateParameter(valid_21628059, JString, required = true,
                                   default = nil)
  if valid_21628059 != nil:
    section.add "TargetDBInstanceIdentifier", valid_21628059
  var valid_21628060 = query.getOrDefault("AvailabilityZone")
  valid_21628060 = validateParameter(valid_21628060, JString, required = false,
                                   default = nil)
  if valid_21628060 != nil:
    section.add "AvailabilityZone", valid_21628060
  var valid_21628061 = query.getOrDefault("Iops")
  valid_21628061 = validateParameter(valid_21628061, JInt, required = false,
                                   default = nil)
  if valid_21628061 != nil:
    section.add "Iops", valid_21628061
  var valid_21628062 = query.getOrDefault("OptionGroupName")
  valid_21628062 = validateParameter(valid_21628062, JString, required = false,
                                   default = nil)
  if valid_21628062 != nil:
    section.add "OptionGroupName", valid_21628062
  var valid_21628063 = query.getOrDefault("RestoreTime")
  valid_21628063 = validateParameter(valid_21628063, JString, required = false,
                                   default = nil)
  if valid_21628063 != nil:
    section.add "RestoreTime", valid_21628063
  var valid_21628064 = query.getOrDefault("MultiAZ")
  valid_21628064 = validateParameter(valid_21628064, JBool, required = false,
                                   default = nil)
  if valid_21628064 != nil:
    section.add "MultiAZ", valid_21628064
  var valid_21628065 = query.getOrDefault("LicenseModel")
  valid_21628065 = validateParameter(valid_21628065, JString, required = false,
                                   default = nil)
  if valid_21628065 != nil:
    section.add "LicenseModel", valid_21628065
  var valid_21628066 = query.getOrDefault("Tags")
  valid_21628066 = validateParameter(valid_21628066, JArray, required = false,
                                   default = nil)
  if valid_21628066 != nil:
    section.add "Tags", valid_21628066
  var valid_21628067 = query.getOrDefault("DBName")
  valid_21628067 = validateParameter(valid_21628067, JString, required = false,
                                   default = nil)
  if valid_21628067 != nil:
    section.add "DBName", valid_21628067
  var valid_21628068 = query.getOrDefault("DBInstanceClass")
  valid_21628068 = validateParameter(valid_21628068, JString, required = false,
                                   default = nil)
  if valid_21628068 != nil:
    section.add "DBInstanceClass", valid_21628068
  var valid_21628069 = query.getOrDefault("Action")
  valid_21628069 = validateParameter(valid_21628069, JString, required = true, default = newJString(
      "RestoreDBInstanceToPointInTime"))
  if valid_21628069 != nil:
    section.add "Action", valid_21628069
  var valid_21628070 = query.getOrDefault("UseLatestRestorableTime")
  valid_21628070 = validateParameter(valid_21628070, JBool, required = false,
                                   default = nil)
  if valid_21628070 != nil:
    section.add "UseLatestRestorableTime", valid_21628070
  var valid_21628071 = query.getOrDefault("DBSubnetGroupName")
  valid_21628071 = validateParameter(valid_21628071, JString, required = false,
                                   default = nil)
  if valid_21628071 != nil:
    section.add "DBSubnetGroupName", valid_21628071
  var valid_21628072 = query.getOrDefault("PubliclyAccessible")
  valid_21628072 = validateParameter(valid_21628072, JBool, required = false,
                                   default = nil)
  if valid_21628072 != nil:
    section.add "PubliclyAccessible", valid_21628072
  var valid_21628073 = query.getOrDefault("AutoMinorVersionUpgrade")
  valid_21628073 = validateParameter(valid_21628073, JBool, required = false,
                                   default = nil)
  if valid_21628073 != nil:
    section.add "AutoMinorVersionUpgrade", valid_21628073
  var valid_21628074 = query.getOrDefault("Port")
  valid_21628074 = validateParameter(valid_21628074, JInt, required = false,
                                   default = nil)
  if valid_21628074 != nil:
    section.add "Port", valid_21628074
  var valid_21628075 = query.getOrDefault("Version")
  valid_21628075 = validateParameter(valid_21628075, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628075 != nil:
    section.add "Version", valid_21628075
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
  var valid_21628076 = header.getOrDefault("X-Amz-Date")
  valid_21628076 = validateParameter(valid_21628076, JString, required = false,
                                   default = nil)
  if valid_21628076 != nil:
    section.add "X-Amz-Date", valid_21628076
  var valid_21628077 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628077 = validateParameter(valid_21628077, JString, required = false,
                                   default = nil)
  if valid_21628077 != nil:
    section.add "X-Amz-Security-Token", valid_21628077
  var valid_21628078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628078 = validateParameter(valid_21628078, JString, required = false,
                                   default = nil)
  if valid_21628078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628078
  var valid_21628079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628079 = validateParameter(valid_21628079, JString, required = false,
                                   default = nil)
  if valid_21628079 != nil:
    section.add "X-Amz-Algorithm", valid_21628079
  var valid_21628080 = header.getOrDefault("X-Amz-Signature")
  valid_21628080 = validateParameter(valid_21628080, JString, required = false,
                                   default = nil)
  if valid_21628080 != nil:
    section.add "X-Amz-Signature", valid_21628080
  var valid_21628081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628081 = validateParameter(valid_21628081, JString, required = false,
                                   default = nil)
  if valid_21628081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628081
  var valid_21628082 = header.getOrDefault("X-Amz-Credential")
  valid_21628082 = validateParameter(valid_21628082, JString, required = false,
                                   default = nil)
  if valid_21628082 != nil:
    section.add "X-Amz-Credential", valid_21628082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628083: Call_GetRestoreDBInstanceToPointInTime_21628054;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628083.validator(path, query, header, formData, body, _)
  let scheme = call_21628083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628083.makeUrl(scheme.get, call_21628083.host, call_21628083.base,
                               call_21628083.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628083, uri, valid, _)

proc call*(call_21628084: Call_GetRestoreDBInstanceToPointInTime_21628054;
          SourceDBInstanceIdentifier: string; TargetDBInstanceIdentifier: string;
          Engine: string = ""; AvailabilityZone: string = ""; Iops: int = 0;
          OptionGroupName: string = ""; RestoreTime: string = ""; MultiAZ: bool = false;
          LicenseModel: string = ""; Tags: JsonNode = nil; DBName: string = "";
          DBInstanceClass: string = "";
          Action: string = "RestoreDBInstanceToPointInTime";
          UseLatestRestorableTime: bool = false; DBSubnetGroupName: string = "";
          PubliclyAccessible: bool = false; AutoMinorVersionUpgrade: bool = false;
          Port: int = 0; Version: string = "2013-09-09"): Recallable =
  ## getRestoreDBInstanceToPointInTime
  ##   Engine: string
  ##   SourceDBInstanceIdentifier: string (required)
  ##   TargetDBInstanceIdentifier: string (required)
  ##   AvailabilityZone: string
  ##   Iops: int
  ##   OptionGroupName: string
  ##   RestoreTime: string
  ##   MultiAZ: bool
  ##   LicenseModel: string
  ##   Tags: JArray
  ##   DBName: string
  ##   DBInstanceClass: string
  ##   Action: string (required)
  ##   UseLatestRestorableTime: bool
  ##   DBSubnetGroupName: string
  ##   PubliclyAccessible: bool
  ##   AutoMinorVersionUpgrade: bool
  ##   Port: int
  ##   Version: string (required)
  var query_21628085 = newJObject()
  add(query_21628085, "Engine", newJString(Engine))
  add(query_21628085, "SourceDBInstanceIdentifier",
      newJString(SourceDBInstanceIdentifier))
  add(query_21628085, "TargetDBInstanceIdentifier",
      newJString(TargetDBInstanceIdentifier))
  add(query_21628085, "AvailabilityZone", newJString(AvailabilityZone))
  add(query_21628085, "Iops", newJInt(Iops))
  add(query_21628085, "OptionGroupName", newJString(OptionGroupName))
  add(query_21628085, "RestoreTime", newJString(RestoreTime))
  add(query_21628085, "MultiAZ", newJBool(MultiAZ))
  add(query_21628085, "LicenseModel", newJString(LicenseModel))
  if Tags != nil:
    query_21628085.add "Tags", Tags
  add(query_21628085, "DBName", newJString(DBName))
  add(query_21628085, "DBInstanceClass", newJString(DBInstanceClass))
  add(query_21628085, "Action", newJString(Action))
  add(query_21628085, "UseLatestRestorableTime", newJBool(UseLatestRestorableTime))
  add(query_21628085, "DBSubnetGroupName", newJString(DBSubnetGroupName))
  add(query_21628085, "PubliclyAccessible", newJBool(PubliclyAccessible))
  add(query_21628085, "AutoMinorVersionUpgrade", newJBool(AutoMinorVersionUpgrade))
  add(query_21628085, "Port", newJInt(Port))
  add(query_21628085, "Version", newJString(Version))
  result = call_21628084.call(nil, query_21628085, nil, nil, nil)

var getRestoreDBInstanceToPointInTime* = Call_GetRestoreDBInstanceToPointInTime_21628054(
    name: "getRestoreDBInstanceToPointInTime", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RestoreDBInstanceToPointInTime",
    validator: validate_GetRestoreDBInstanceToPointInTime_21628055, base: "/",
    makeUrl: url_GetRestoreDBInstanceToPointInTime_21628056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostRevokeDBSecurityGroupIngress_21628139 = ref object of OpenApiRestCall_21625418
proc url_PostRevokeDBSecurityGroupIngress_21628141(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostRevokeDBSecurityGroupIngress_21628140(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628142 = query.getOrDefault("Action")
  valid_21628142 = validateParameter(valid_21628142, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21628142 != nil:
    section.add "Action", valid_21628142
  var valid_21628143 = query.getOrDefault("Version")
  valid_21628143 = validateParameter(valid_21628143, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628143 != nil:
    section.add "Version", valid_21628143
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
  var valid_21628144 = header.getOrDefault("X-Amz-Date")
  valid_21628144 = validateParameter(valid_21628144, JString, required = false,
                                   default = nil)
  if valid_21628144 != nil:
    section.add "X-Amz-Date", valid_21628144
  var valid_21628145 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628145 = validateParameter(valid_21628145, JString, required = false,
                                   default = nil)
  if valid_21628145 != nil:
    section.add "X-Amz-Security-Token", valid_21628145
  var valid_21628146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628146 = validateParameter(valid_21628146, JString, required = false,
                                   default = nil)
  if valid_21628146 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628146
  var valid_21628147 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628147 = validateParameter(valid_21628147, JString, required = false,
                                   default = nil)
  if valid_21628147 != nil:
    section.add "X-Amz-Algorithm", valid_21628147
  var valid_21628148 = header.getOrDefault("X-Amz-Signature")
  valid_21628148 = validateParameter(valid_21628148, JString, required = false,
                                   default = nil)
  if valid_21628148 != nil:
    section.add "X-Amz-Signature", valid_21628148
  var valid_21628149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628149 = validateParameter(valid_21628149, JString, required = false,
                                   default = nil)
  if valid_21628149 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628149
  var valid_21628150 = header.getOrDefault("X-Amz-Credential")
  valid_21628150 = validateParameter(valid_21628150, JString, required = false,
                                   default = nil)
  if valid_21628150 != nil:
    section.add "X-Amz-Credential", valid_21628150
  result.add "header", section
  ## parameters in `formData` object:
  ##   DBSecurityGroupName: JString (required)
  ##   EC2SecurityGroupName: JString
  ##   EC2SecurityGroupId: JString
  ##   CIDRIP: JString
  ##   EC2SecurityGroupOwnerId: JString
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21628151 = formData.getOrDefault("DBSecurityGroupName")
  valid_21628151 = validateParameter(valid_21628151, JString, required = true,
                                   default = nil)
  if valid_21628151 != nil:
    section.add "DBSecurityGroupName", valid_21628151
  var valid_21628152 = formData.getOrDefault("EC2SecurityGroupName")
  valid_21628152 = validateParameter(valid_21628152, JString, required = false,
                                   default = nil)
  if valid_21628152 != nil:
    section.add "EC2SecurityGroupName", valid_21628152
  var valid_21628153 = formData.getOrDefault("EC2SecurityGroupId")
  valid_21628153 = validateParameter(valid_21628153, JString, required = false,
                                   default = nil)
  if valid_21628153 != nil:
    section.add "EC2SecurityGroupId", valid_21628153
  var valid_21628154 = formData.getOrDefault("CIDRIP")
  valid_21628154 = validateParameter(valid_21628154, JString, required = false,
                                   default = nil)
  if valid_21628154 != nil:
    section.add "CIDRIP", valid_21628154
  var valid_21628155 = formData.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21628155 = validateParameter(valid_21628155, JString, required = false,
                                   default = nil)
  if valid_21628155 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21628155
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628156: Call_PostRevokeDBSecurityGroupIngress_21628139;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628156.validator(path, query, header, formData, body, _)
  let scheme = call_21628156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628156.makeUrl(scheme.get, call_21628156.host, call_21628156.base,
                               call_21628156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628156, uri, valid, _)

proc call*(call_21628157: Call_PostRevokeDBSecurityGroupIngress_21628139;
          DBSecurityGroupName: string;
          Action: string = "RevokeDBSecurityGroupIngress";
          EC2SecurityGroupName: string = ""; EC2SecurityGroupId: string = "";
          CIDRIP: string = ""; Version: string = "2013-09-09";
          EC2SecurityGroupOwnerId: string = ""): Recallable =
  ## postRevokeDBSecurityGroupIngress
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   EC2SecurityGroupName: string
  ##   EC2SecurityGroupId: string
  ##   CIDRIP: string
  ##   Version: string (required)
  ##   EC2SecurityGroupOwnerId: string
  var query_21628158 = newJObject()
  var formData_21628159 = newJObject()
  add(formData_21628159, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21628158, "Action", newJString(Action))
  add(formData_21628159, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(formData_21628159, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(formData_21628159, "CIDRIP", newJString(CIDRIP))
  add(query_21628158, "Version", newJString(Version))
  add(formData_21628159, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  result = call_21628157.call(nil, query_21628158, nil, formData_21628159, nil)

var postRevokeDBSecurityGroupIngress* = Call_PostRevokeDBSecurityGroupIngress_21628139(
    name: "postRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpPost,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_PostRevokeDBSecurityGroupIngress_21628140, base: "/",
    makeUrl: url_PostRevokeDBSecurityGroupIngress_21628141,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetRevokeDBSecurityGroupIngress_21628119 = ref object of OpenApiRestCall_21625418
proc url_GetRevokeDBSecurityGroupIngress_21628121(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetRevokeDBSecurityGroupIngress_21628120(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   EC2SecurityGroupId: JString
  ##   EC2SecurityGroupOwnerId: JString
  ##   DBSecurityGroupName: JString (required)
  ##   Action: JString (required)
  ##   CIDRIP: JString
  ##   EC2SecurityGroupName: JString
  ##   Version: JString (required)
  section = newJObject()
  var valid_21628122 = query.getOrDefault("EC2SecurityGroupId")
  valid_21628122 = validateParameter(valid_21628122, JString, required = false,
                                   default = nil)
  if valid_21628122 != nil:
    section.add "EC2SecurityGroupId", valid_21628122
  var valid_21628123 = query.getOrDefault("EC2SecurityGroupOwnerId")
  valid_21628123 = validateParameter(valid_21628123, JString, required = false,
                                   default = nil)
  if valid_21628123 != nil:
    section.add "EC2SecurityGroupOwnerId", valid_21628123
  assert query != nil, "query argument is necessary due to required `DBSecurityGroupName` field"
  var valid_21628124 = query.getOrDefault("DBSecurityGroupName")
  valid_21628124 = validateParameter(valid_21628124, JString, required = true,
                                   default = nil)
  if valid_21628124 != nil:
    section.add "DBSecurityGroupName", valid_21628124
  var valid_21628125 = query.getOrDefault("Action")
  valid_21628125 = validateParameter(valid_21628125, JString, required = true, default = newJString(
      "RevokeDBSecurityGroupIngress"))
  if valid_21628125 != nil:
    section.add "Action", valid_21628125
  var valid_21628126 = query.getOrDefault("CIDRIP")
  valid_21628126 = validateParameter(valid_21628126, JString, required = false,
                                   default = nil)
  if valid_21628126 != nil:
    section.add "CIDRIP", valid_21628126
  var valid_21628127 = query.getOrDefault("EC2SecurityGroupName")
  valid_21628127 = validateParameter(valid_21628127, JString, required = false,
                                   default = nil)
  if valid_21628127 != nil:
    section.add "EC2SecurityGroupName", valid_21628127
  var valid_21628128 = query.getOrDefault("Version")
  valid_21628128 = validateParameter(valid_21628128, JString, required = true,
                                   default = newJString("2013-09-09"))
  if valid_21628128 != nil:
    section.add "Version", valid_21628128
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
  var valid_21628129 = header.getOrDefault("X-Amz-Date")
  valid_21628129 = validateParameter(valid_21628129, JString, required = false,
                                   default = nil)
  if valid_21628129 != nil:
    section.add "X-Amz-Date", valid_21628129
  var valid_21628130 = header.getOrDefault("X-Amz-Security-Token")
  valid_21628130 = validateParameter(valid_21628130, JString, required = false,
                                   default = nil)
  if valid_21628130 != nil:
    section.add "X-Amz-Security-Token", valid_21628130
  var valid_21628131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21628131 = validateParameter(valid_21628131, JString, required = false,
                                   default = nil)
  if valid_21628131 != nil:
    section.add "X-Amz-Content-Sha256", valid_21628131
  var valid_21628132 = header.getOrDefault("X-Amz-Algorithm")
  valid_21628132 = validateParameter(valid_21628132, JString, required = false,
                                   default = nil)
  if valid_21628132 != nil:
    section.add "X-Amz-Algorithm", valid_21628132
  var valid_21628133 = header.getOrDefault("X-Amz-Signature")
  valid_21628133 = validateParameter(valid_21628133, JString, required = false,
                                   default = nil)
  if valid_21628133 != nil:
    section.add "X-Amz-Signature", valid_21628133
  var valid_21628134 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21628134 = validateParameter(valid_21628134, JString, required = false,
                                   default = nil)
  if valid_21628134 != nil:
    section.add "X-Amz-SignedHeaders", valid_21628134
  var valid_21628135 = header.getOrDefault("X-Amz-Credential")
  valid_21628135 = validateParameter(valid_21628135, JString, required = false,
                                   default = nil)
  if valid_21628135 != nil:
    section.add "X-Amz-Credential", valid_21628135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21628136: Call_GetRevokeDBSecurityGroupIngress_21628119;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21628136.validator(path, query, header, formData, body, _)
  let scheme = call_21628136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21628136.makeUrl(scheme.get, call_21628136.host, call_21628136.base,
                               call_21628136.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21628136, uri, valid, _)

proc call*(call_21628137: Call_GetRevokeDBSecurityGroupIngress_21628119;
          DBSecurityGroupName: string; EC2SecurityGroupId: string = "";
          EC2SecurityGroupOwnerId: string = "";
          Action: string = "RevokeDBSecurityGroupIngress"; CIDRIP: string = "";
          EC2SecurityGroupName: string = ""; Version: string = "2013-09-09"): Recallable =
  ## getRevokeDBSecurityGroupIngress
  ##   EC2SecurityGroupId: string
  ##   EC2SecurityGroupOwnerId: string
  ##   DBSecurityGroupName: string (required)
  ##   Action: string (required)
  ##   CIDRIP: string
  ##   EC2SecurityGroupName: string
  ##   Version: string (required)
  var query_21628138 = newJObject()
  add(query_21628138, "EC2SecurityGroupId", newJString(EC2SecurityGroupId))
  add(query_21628138, "EC2SecurityGroupOwnerId",
      newJString(EC2SecurityGroupOwnerId))
  add(query_21628138, "DBSecurityGroupName", newJString(DBSecurityGroupName))
  add(query_21628138, "Action", newJString(Action))
  add(query_21628138, "CIDRIP", newJString(CIDRIP))
  add(query_21628138, "EC2SecurityGroupName", newJString(EC2SecurityGroupName))
  add(query_21628138, "Version", newJString(Version))
  result = call_21628137.call(nil, query_21628138, nil, nil, nil)

var getRevokeDBSecurityGroupIngress* = Call_GetRevokeDBSecurityGroupIngress_21628119(
    name: "getRevokeDBSecurityGroupIngress", meth: HttpMethod.HttpGet,
    host: "rds.amazonaws.com", route: "/#Action=RevokeDBSecurityGroupIngress",
    validator: validate_GetRevokeDBSecurityGroupIngress_21628120, base: "/",
    makeUrl: url_GetRevokeDBSecurityGroupIngress_21628121,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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